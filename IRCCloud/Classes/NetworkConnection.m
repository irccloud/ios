//
//  NetworkConnection.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "NetworkConnection.h"
#import "HandshakeHeader.h"
#import "IRCCloudJSONObject.h"
#import "UIColor+IRCCloud.h"
#import "ImageCache.h"
#import "TrustKit.h"
@import Firebase;
@import FirebasePerformance;

NSURL *__logfile;
NSOperationQueue *__logQueue;

void FirebaseLog(NSString *format, ...) {
    if (!format) {
        return;
    }

    va_list args;
#ifdef CRASHLYTICS_TOKEN
    va_start(args, format);
    [[FIRCrashlytics crashlytics] logWithFormat:format arguments:args];
    va_end(args);
#endif
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    [__logQueue addOperationWithBlock:^{
        if(__logfile) {
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:__logfile.path];
            if(!fileHandle) {
                [[NSFileManager defaultManager] createFileAtPath:__logfile.path contents:nil attributes:nil];
                fileHandle = [NSFileHandle fileHandleForWritingAtPath:__logfile.path];
            }
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }

        NSLog(@"%@", s);
    }];
}

NSString *_userAgent = nil;
NSString *kIRCCloudConnectivityNotification = @"com.irccloud.notification.connectivity";
NSString *kIRCCloudEventNotification = @"com.irccloud.notification.event";
NSString *kIRCCloudBacklogStartedNotification = @"com.irccloud.notification.backlog.start";
NSString *kIRCCloudBacklogFailedNotification = @"com.irccloud.notification.backlog.failed";
NSString *kIRCCloudBacklogCompletedNotification = @"com.irccloud.notification.backlog.completed";
NSString *kIRCCloudBacklogProgressNotification = @"com.irccloud.notification.backlog.progress";
NSString *kIRCCloudEventKey = @"com.irccloud.event";

#if defined(BRAND_HOST)
NSString *IRCCLOUD_HOST = @BRAND_HOST
#elif defined(ENTERPRISE)
NSString *IRCCLOUD_HOST = @"";
#else
NSString *IRCCLOUD_HOST = @"www.irccloud.com";
#endif
NSString *IRCCLOUD_PATH = @"/";

#define TYPE_UNKNOWN 0
#define TYPE_WIFI 1
#define TYPE_WWAN 2

NSLock *__serializeLock = nil;
NSLock *__userInfoLock = nil;
volatile BOOL __socketPaused = NO;

@interface NetworkConnection (Firebase) {
}
@property FIRHTTPMetric *httpMetric;
@end

@interface OOBFetcher : NSObject<NSURLSessionDataDelegate> {
    SBJson5Parser *_parser;
    NSString *_url;
    BOOL _cancelled;
    BOOL _running;
    NSURLSessionDataTask *_task;
    int _bid;
    void (^_completionHandler)(BOOL);
}
@property (readonly) NSString *url;
@property int bid;
@property (nonatomic, copy) void (^completionHandler)(BOOL);
-(id)initWithURL:(NSString *)URL;
-(void)cancel;
-(void)start;
@end

@implementation OOBFetcher

-(id)initWithURL:(NSString *)URL {
    self = [super init];
    if(self) {
        NetworkConnection *conn = [NetworkConnection sharedInstance];
        self->_url = URL;
        self->_bid = -1;
        self->_parser = [SBJson5Parser unwrapRootArrayParserWithBlock:^(id item, BOOL *stop) {
            if(self->_cancelled)
                *stop = YES;
            else
                [conn parse:item backlog:YES];
        } errorHandler:^(NSError *error) {
            CLS_LOG(@"OOB JSON ERROR: %@", error);
        }];
        self->_cancelled = NO;
        self->_running = NO;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self->_url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        [request setHTTPShouldHandleCookies:NO];
        [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
        [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.ephemeralSessionConfiguration delegate:self delegateQueue:[NetworkConnection sharedInstance].queue];
        self->_task = [session dataTaskWithRequest:request];
    }
    return self;
}
-(void)cancel {
    CLS_LOG(@"Cancelled OOB fetcher for URL: %@", _url);
    self->_cancelled = YES;
    self->_running = NO;
    [self->_task cancel];
}
-(void)start {
    if(self->_cancelled || _running) {
        CLS_LOG(@"Not starting cancelled OOB fetcher");
        return;
    }
    
    if(self->_task) {
        CLS_LOG(@"Fetching backlog");
        self->_running = YES;
        [self->_task resume];
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:self];
    } else {
        CLS_LOG(@"Failed to create NSURLConnection");
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
        if(self->_completionHandler)
            self->_completionHandler(NO);
    }
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        if(self->_cancelled) {
            CLS_LOG(@"Request failed for cancelled OOB fetcher, ignoring");
            return;
        }
        CLS_LOG(@"Request failed: %@", error);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
            if(self->_completionHandler)
                self->_completionHandler(NO);
        }];
        self->_cancelled = YES;
    } else {
        if(self->_cancelled) {
            CLS_LOG(@"Connection finished loading for cancelled OOB fetcher, ignoring");
            return;
        }
        CLS_LOG(@"Backlog download completed");
        if(!self->_cancelled) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:self];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if(self->_completionHandler)
                    self->_completionHandler(YES);
            }];
        }
    }
    self->_running = NO;
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    if(!self->_cancelled && ((NSHTTPURLResponse *)response).statusCode != 200) {
        CLS_LOG(@"HTTP status code: %li", (long)((NSHTTPURLResponse *)response).statusCode);
		CLS_LOG(@"HTTP headers: %@", [((NSHTTPURLResponse *)response) allHeaderFields]);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
            if(self->_completionHandler)
                self->_completionHandler(NO);
        }];
        self->_cancelled = YES;
        completionHandler(NSURLSessionResponseCancel);
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if(!self->_cancelled) {
#ifndef EXTENSION
        FIRTrace *trace;
        if([FIROptions defaultOptions])
            trace = [FIRPerformance startTraceWithName:@"parseOOB"];
#endif
        [self->_parser parse:data];
#ifndef EXTENSION
        [trace stop];
#endif
    } else {
        CLS_LOG(@"Ignoring data for cancelled OOB fetcher");
    }
}

@end

@implementation NetworkConnection

+(NetworkConnection *)sharedInstance {
    static NetworkConnection *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[NetworkConnection alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

+(void)sync:(NSURL *)file1 with:(NSURL *)file2 {
    NSDictionary *a1 = [[NSFileManager defaultManager] attributesOfItemAtPath:file1.path error:nil];
    NSDictionary *a2 = [[NSFileManager defaultManager] attributesOfItemAtPath:file2.path error:nil];

    if(a1) {
        if(a2 == nil || [[a2 fileModificationDate] compare:[a1 fileModificationDate]] == NSOrderedAscending) {
            [[NSFileManager defaultManager] copyItemAtURL:file1 toURL:file2 error:NULL];
        }
    }
    
    if(a2) {
        if(a1 == nil || [[a1 fileModificationDate] compare:[a2 fileModificationDate]] == NSOrderedAscending) {
            [[NSFileManager defaultManager] copyItemAtURL:file2 toURL:file1 error:NULL];
        }
    }

    [file1 setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
    [file2 setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
}

+(void)sync {
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    if(sharedcontainer) {
        NSURL *caches = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
        
        [NetworkConnection sync:[caches URLByAppendingPathComponent:@"servers"] with:[sharedcontainer URLByAppendingPathComponent:@"servers"]];
        [NetworkConnection sync:[caches URLByAppendingPathComponent:@"buffers"] with:[sharedcontainer URLByAppendingPathComponent:@"buffers"]];
        [NetworkConnection sync:[caches URLByAppendingPathComponent:@"channels"] with:[sharedcontainer URLByAppendingPathComponent:@"channels"]];
        [NetworkConnection sync:[caches URLByAppendingPathComponent:@"stream"] with:[sharedcontainer URLByAppendingPathComponent:@"stream"]];
    }
}

-(id)init {
    self = [super init];
#ifdef ENTERPRISE
    IRCCLOUD_HOST = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
#endif
    if(self) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        config.waitsForConnectivity = NO;
        _urlSession = [NSURLSession sessionWithConfiguration:config delegate:nil delegateQueue:NSOperationQueue.mainQueue];
        
        [TrustKit initializeWithConfiguration:@{
                                                kTSKSwizzleNetworkDelegates: @YES,
                                                kTSKPinnedDomains : @{
                                                        @"irccloud.com" : @{
                                                                kTSKExpirationDate: @"2020-10-09",
                                                                kTSKPublicKeyAlgorithms : @[kTSKAlgorithmRsa2048,kTSKAlgorithmEcDsaSecp256r1],
                                                                kTSKPublicKeyHashes : @[
                                                                        @"5kJvNEMw0KjrCAu7eXY5HZdvyCS13BbA0VJG1RSP91w=",
                                                                        @"Y9mvm0exBk1JoQ57f9Vm28jKo5lFm/woKcVxrYxu80o=",
                                                                        @"47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU="
                                                                        ],
                                                                kTSKIncludeSubdomains : @YES
                                                                }
                                                        }}];
    __serializeLock = [[NSLock alloc] init];
    __userInfoLock = [[NSLock alloc] init];
    __logQueue = [[NSOperationQueue alloc] init];
    [__logQueue setMaxConcurrentOperationCount:1];
    self->_queue = [[NSOperationQueue alloc] init];
    self->_servers = [ServersDataSource sharedInstance];
    self->_buffers = [BuffersDataSource sharedInstance];
    self->_channels = [ChannelsDataSource sharedInstance];
    self->_users = [UsersDataSource sharedInstance];
    self->_events = [EventsDataSource sharedInstance];
    self->_notifications = [NotificationsDataSource sharedInstance];
    self->_state = kIRCCloudStateDisconnected;
    self->_oobQueue = [[NSMutableArray alloc] init];
    self->_awayOverride = nil;
    self->_lastReqId = 1;
    self->_idleInterval = 20;
    self->_reconnectTimestamp = -1;
    self->_failCount = 0;
    self->_notifier = NO;
    [self _createJSONParser];
    self->_writer = [[SBJson5Writer alloc] init];
    self->_reachabilityValid = NO;
    self->_reachability = nil;
    self->_resultHandlers = [[NSMutableDictionary alloc] init];
    self->_pendingEdits = [[NSMutableArray alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogStarted:) name:kIRCCloudBacklogStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogFailed:) name:kIRCCloudBacklogFailedNotification object:nil];
#ifdef APPSTORE
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#else
    NSString *version = [NSString stringWithFormat:@"%@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
#endif
#ifdef EXTENSION
    NSString *app = @"ShareExtension";
#else
#ifdef ENTERPRISE
    NSString *app = @"IRCEnterprise";
#else
    NSString *app = @"IRCCloud";
#endif
#endif
    _userAgent = [NSString stringWithFormat:@"%@/%@ (%@; %@; %@ %@)", app, version, [UIDevice currentDevice].model, [[[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"] objectAtIndex:0], [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
    
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"stream"];
    [__userInfoLock lock];
    self->_userInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
    [__userInfoLock unlock];
    if(self.userInfo) {
        self->_config = [self.userInfo objectForKey:@"config"];
        [self _configLoaded];
    }
    
    CLS_LOG(@"%@", _userAgent);
        
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    void (^ignored)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
    };
    
    void (^alert)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        if(!backlog && !self->_resuming)
            [self postObject:object forEvent:kIRCEventAlert];
    };
    
    void (^makeserver)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        Server *server = [self->_servers getServer:object.cid];
        if(!server) {
            server = [[Server alloc] init];
            [self->_servers addServer:server];
        }
        server.cid = object.cid;
        server.name = [object objectForKey:@"name"];
        server.hostname = [object objectForKey:@"hostname"];
        server.port = [[object objectForKey:@"port"] intValue];
        server.nick = [object objectForKey:@"nick"];
        server.status = [object objectForKey:@"status"];
        server.ssl = [[object objectForKey:@"ssl"] intValue];
        server.realname = [object objectForKey:@"realname"];
        if([[object objectForKey:@"server_realname"] isKindOfClass:[NSString class]])
            server.server_realname = [object objectForKey:@"server_realname"];
        server.server_pass = [object objectForKey:@"server_pass"];
        server.nickserv_pass = [object objectForKey:@"nickserv_pass"];
        server.join_commands = [object objectForKey:@"join_commands"];
        server.fail_info = [object objectForKey:@"fail_info"];
        server.caps = [object objectForKey:@"caps"];
        server.usermask = [object objectForKey:@"usermask"];
        server.away = (backlog && [self->_awayOverride objectForKey:@(object.cid)])?@"":[object objectForKey:@"away"];
        if([[self.userInfo objectForKey:@"autoaway"] intValue] && [server.away isEqualToString:@"Auto-away"])
            server.away = @"";
        server.ignores = [object objectForKey:@"ignores"];
        if([[object objectForKey:@"order"] isKindOfClass:[NSNumber class]])
            server.order = [[object objectForKey:@"order"] intValue];
        else
            server.order = 0;
        if([[object objectForKey:@"deferred_archives"] isKindOfClass:[NSNumber class]])
            server.deferred_archives = [[object objectForKey:@"deferred_archives"] intValue];
        else
            server.deferred_archives = 0;
        if([[object objectForKey:@"ircserver"] isKindOfClass:[NSString class]])
            server.ircserver = [object objectForKey:@"ircserver"];
        else
            server.ircserver = nil;
        if([[object objectForKey:@"orgid"] isKindOfClass:[NSNumber class]])
            server.orgId = [[object objectForKey:@"orgid"] intValue];
        else
            server.orgId = 0;
        if([[object objectForKey:@"avatar"] isKindOfClass:[NSString class]])
            server.avatar = [object objectForKey:@"avatar"];
        else
            server.avatar = nil;
        if([[object objectForKey:@"avatar_url"] isKindOfClass:[NSString class]])
            server.avatarURL = [object objectForKey:@"avatar_url"];
        else
            server.avatarURL = nil;
        if([[object objectForKey:@"avatars_supported"] isKindOfClass:[NSNumber class]])
            server.avatars_supported = [[object objectForKey:@"avatars_supported"] intValue];
        else
            server.avatars_supported = 0;
        if([[object objectForKey:@"slack"] isKindOfClass:[NSNumber class]])
            server.slack = [[object objectForKey:@"slack"] intValue];
        else
            server.slack = 0;
        if(!backlog && !self->_resuming)
            [self postObject:server forEvent:kIRCEventMakeServer];
    };
    
    void (^msg)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        Buffer *b = [self->_buffers getBuffer:object.bid];
        if(b) {
            Event *event = [self->_events addJSONObject:object];
            if(event.eid == -1) {
                alert(object,backlog);
            } else {
                if((!backlog || self->_resuming || [[self->_oobQueue firstObject] bid] == -1) && event.eid > self->_highestEID) {
                    self->_highestEID = event.eid;
                }
                if([event isImportant:b.type]) {
                    User *u = [self->_users getUser:event.from cid:event.cid bid:event.bid];
                    if(u) {
                        if(u.lastMessage < event.eid)
                            u.lastMessage = event.eid;
                        if(event.isHighlight && u.lastMention < event.eid)
                            u.lastMention = event.eid;
                    }
                    if(event.eid > b.last_seen_eid && (event.isHighlight || [b.type isEqualToString:@"conversation"])) {
                        BOOL show = YES;
                        if([[self->_servers getServer:event.cid].ignore match:event.ignoreMask] || [[[[self prefs] objectForKey:@"buffer-disableTrackUnread"] objectForKey:@(b.bid)] integerValue]) {
                            show = NO;
                        }
                        
                        if(show && ![self->_notifications getNotification:event.eid bid:event.bid]) {
                            [self->_notifications notify:[NSString stringWithFormat:@"<%@> %@",event.from,event.msg] category:event.type cid:event.cid bid:event.bid eid:event.eid];
                            if(!backlog)
                                [self->_notifications updateBadgeCount];
                        }
                    }
                }
                if((!backlog && !self->_resuming) || event.reqId > 0) {
                    [self postObject:event forEvent:kIRCEventBufferMsg];
                    event.entities = [object objectForKey:@"entities"];
                    
                    NSTimeInterval entity_eid = event.eid;
                    for(int i = 0; i < [[event.entities objectForKey:@"files"] count]; i++) {
                        entity_eid += 1;
                        [self postObject:[self->_events event:entity_eid buffer:event.bid] forEvent:kIRCEventBufferMsg];
                    }
                }
            }
        }
    };
    
    void (^joined_channel)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        [self->_events addJSONObject:object];
        if(!backlog) {
            User *user = [self->_users getUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if(!user) {
                user = [[User alloc] init];
                user.cid = object.cid;
                user.bid = object.bid;
                user.nick = [object objectForKey:@"nick"];
                [self->_users addUser:user];
            }
            if(user.nick)
                user.old_nick = user.nick;
            user.hostmask = [object objectForKey:@"hostmask"];
            user.mode = @"";
            user.away = 0;
            user.away_msg = @"";
            user.ircserver = [object objectForKey:@"ircserver"];
            if([[object objectForKey:@"display_name"] isKindOfClass:NSString.class])
                user.display_name = [object objectForKey:@"display_name"];
            else
                user.display_name = nil;
            if(!self->_resuming)
                [self postObject:object forEvent:kIRCEventJoin];
        }
    };
    
    void (^parted_channel)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        [self->_events addJSONObject:object];
        if(!backlog) {
            [self->_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_parted_channel"]) {
                [self->_channels removeChannelForBuffer:object.bid];
                [self->_users removeUsersForBuffer:object.bid];
            }
            if(!self->_resuming)
                [self postObject:object forEvent:kIRCEventPart];
        }
    };
    
    void (^kicked_channel)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        [self->_events addJSONObject:object];
        if(!backlog) {
            [self->_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_kicked_channel"]) {
                [self->_channels removeChannelForBuffer:object.bid];
                [self->_users removeUsersForBuffer:object.bid];
            }
            if(!self->_resuming)
                [self postObject:object forEvent:kIRCEventKick];
        }
    };
    
    void (^nickchange)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
        [self->_events addJSONObject:object];
        if(!backlog) {
            [self->_users updateNick:[object objectForKey:@"newnick"] oldNick:[object objectForKey:@"oldnick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_nickchange"])
                [self->_servers updateNick:[object objectForKey:@"newnick"] server:object.cid];
            if(!self->_resuming)
                [self postObject:object forEvent:kIRCEventNickChange];
        }
    };
    
    NSMutableDictionary *parserMap = @{
                   @"idle":ignored, @"end_of_backlog":ignored, @"oob_skipped":ignored, @"num_invites":ignored, @"user_account":ignored, @"twitch_hosttarget_start":ignored, @"twitch_hosttarget_stop":ignored, @"twitch_usernotice":ignored,
                   @"header": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       self->_state = kIRCCloudStateConnected;
                       [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
                       self->_idleInterval = ([[object objectForKey:@"idle_interval"] doubleValue] / 1000.0) + 10;
                       self->_clockOffset = [[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"time"] doubleValue];
                       self->_streamId = [object objectForKey:@"streamid"];
                       self->_accrued = [[object objectForKey:@"accrued"] intValue];
                       self->_currentCount = 0;
                       self->_resuming = [[object objectForKey:@"resumed"] boolValue];
                       CLS_LOG(@"idle interval: %f clock offset: %f stream id: %@ resumed: %i", self->_idleInterval, self->_clockOffset, self->_streamId, self->_resuming);
                       if(self->_accrued > 0) {
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:nil];
                           }];
                       }
                       if(self->_highestEID > 0 && !self->_resuming) {
                           CLS_LOG(@"Unable to resume socket, requesting a full OOB load");
                           [self->_events clear];
                           self->_highestEID = 0;
                           self->_streamId = nil;
                           self->_pendingEdits = [[NSMutableArray alloc] init];
                           [self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
                           self->_state = kIRCCloudStateDisconnected;
                           [self performSelectorOnMainThread:@selector(fail) withObject:nil waitUntilDone:NO];
                       }
                   },
                   @"backlog_cache_init": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events removeEventsBefore:object.eid buffer:object.bid];
                   },
                   @"global_system_message": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!self->_resuming && !backlog && [object objectForKey:@"system_message_type"] && ![[object objectForKey:@"system_message_type"] isEqualToString:@"eval"] && ![[object objectForKey:@"system_message_type"] isEqualToString:@"refresh"]) {
                           self->_globalMsg = [object objectForKey:@"msg"];
                           [self postObject:object forEvent:kIRCEventGlobalMsg];
                       }
                   },
                   @"oob_include": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       __socketPaused = YES;
                       self->_awayOverride = [[NSMutableDictionary alloc] init];
                       self->_reconnectTimestamp = -1;
                       CLS_LOG(@"oob_include, invalidating BIDs");
                       [self->_buffers invalidate];
                       [self->_channels invalidate];
                       [self fetchOOB:[NSString stringWithFormat:@"https://%@%@", IRCCLOUD_HOST, [object objectForKey:@"url"]]];
                   },
                   @"oob_timeout": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       CLS_LOG(@"OOB timed out");
                       [self clearOOB];
                       self->_highestEID = 0;
                       self->_streamId = nil;
                       [self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
                       self->_state = kIRCCloudStateDisconnected;
                       [self performSelectorOnMainThread:@selector(fail) withObject:nil waitUntilDone:NO];
                   },
                   @"stat_user": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [__userInfoLock lock];
                       self->_userInfo = object.dictionary;
                       [__userInfoLock unlock];
                       if([[self.userInfo objectForKey:@"uploads_disabled"] intValue] == 1 && [[self.userInfo objectForKey:@"id"] intValue] != 11694)
                           [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"uploadsAvailable"];
                       else
                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"uploadsAvailable"];
#ifdef ENTERPRISE
                       NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
                       NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
                       [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
                       [d synchronize];

                       self->_prefs = nil;
#ifndef EXTENSION
#ifdef DEBUG
                       if(![[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
#endif
                       NSDictionary *p = [self prefs];
                       if([p objectForKey:@"theme"] && ![[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]) {
                           dispatch_sync(dispatch_get_main_queue(), ^{
                               [UIColor setTheme:[p objectForKey:@"theme"]];
                           });
                           [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"theme"] forKey:@"theme"];
                       }
                       if([p objectForKey:@"time-left"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"time-left"])
                               [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"time-left"] forKey:@"time-left"];
                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"greeting_3.0"];
                       }
                       if([p objectForKey:@"avatars-off"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"avatars-off"])
                               [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"avatars-off"] forKey:@"avatars-off"];
                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"greeting_3.0"];
                       }
                       if([p objectForKey:@"chat-oneline"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"chat-oneline"])
                               [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"chat-oneline"] forKey:@"chat-oneline"];
                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"greeting_3.0"];
                       }
                       if([p objectForKey:@"chat-norealname"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"chat-norealname"])
                               [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"chat-norealname"] forKey:@"chat-norealname"];
                           [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"greeting_3.0"];
                       }
                       if([[p objectForKey:@"labs"] objectForKey:@"avatars"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"avatarImages"])
                               [[NSUserDefaults standardUserDefaults] setObject:[[p objectForKey:@"labs"] objectForKey:@"avatars"] forKey:@"avatarImages"];
                       }
                       if([p objectForKey:@"hiddenMembers"]) {
                           if(![[NSUserDefaults standardUserDefaults] objectForKey:@"hiddenMembers"])
                               [[NSUserDefaults standardUserDefaults] setObject:[p objectForKey:@"hiddenMembers"] forKey:@"hiddenMembers"];
                       }
                       if([object objectForKey:@"id"]) {
                           [[NSUserDefaults standardUserDefaults] setObject:[object objectForKey:@"id"] forKey:@"last_uid"];
                       }
                       [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef DEBUG
                       }
#endif
                       [self->_events reformat];
#endif
                       [[FIRCrashlytics crashlytics] setUserID:[NSString stringWithFormat:@"uid%@",[self.userInfo objectForKey:@"id"]]];
                       CLS_LOG(@"Prefs: %@", [self prefs]);
                       [self _serializeUserInfo];
                       [self postObject:object forEvent:kIRCEventUserInfo];
                   },
                   @"backlog_starts": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if([object objectForKey:@"numbuffers"]) {
                           CLS_LOG(@"I currently have %lu servers with %lu buffers", (unsigned long)[self->_servers count], (unsigned long)[self->_buffers count]);
                           self->_numBuffers = [[object objectForKey:@"numbuffers"] intValue];
                           self->_totalBuffers = 0;
                           CLS_LOG(@"OOB includes has %i buffers", self->_numBuffers);
                       }
                   },
                   @"makeserver": makeserver,
                   @"server_details_changed": makeserver,
                   @"makebuffer": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Buffer *buffer = [self->_buffers getBuffer:object.bid];
                       if(!buffer) {
                           buffer = [[Buffer alloc] init];
                           buffer.bid = object.bid;
                           buffer.scrolledUpFrom = -1;
                           buffer.savedScrollOffset = -1;
                           [self->_buffers addBuffer:buffer];
                       }
                       buffer.bid = object.bid;
                       buffer.cid = object.cid;
                       buffer.created = [[object objectForKey:@"created"] doubleValue];
                       buffer.min_eid = [[object objectForKey:@"min_eid"] doubleValue];
                       buffer.last_seen_eid = [[object objectForKey:@"last_seen_eid"] doubleValue];
                       buffer.name = [object objectForKey:@"name"];
                       buffer.type = [object objectForKey:@"buffer_type"];
                       buffer.archived = [[object objectForKey:@"archived"] intValue];
                       buffer.deferred = [[object objectForKey:@"deferred"] intValue];
                       buffer.timeout = [[object objectForKey:@"timeout"] intValue];
                       buffer.valid = YES;
                       Server *server = [[ServersDataSource sharedInstance] getServer:buffer.cid];
                       buffer.serverIsSlack = server.isSlack;
                       if(buffer.timeout)
                           [[EventsDataSource sharedInstance] removeEventsForBuffer:buffer.bid];
                       if(backlog && buffer.archived) {
                           if(server.deferred_archives)
                               server.deferred_archives--;
                       }
                       [self->_notifications removeNotificationsForBID:buffer.bid olderThan:buffer.last_seen_eid];
                       if(!backlog && !self->_resuming)
                           [self postObject:buffer forEvent:kIRCEventMakeBuffer];
                       if(self->_numBuffers > 0) {
                           self->_totalBuffers++;
                           [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@((float)self->_totalBuffers / (float)self->_numBuffers) waitUntilDone:YES];
                       }
                   },
                   @"backlog_complete": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog && self->_oobQueue.count == 0) {
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               CLS_LOG(@"backlog_complete from websocket");
                               [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:nil];
                           }];
                       }
                   },
                   @"who_response": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog && !self->_resuming) {
                           Buffer *b = [self->_buffers getBufferWithName:[object objectForKey:@"subject"] server:[[object objectForKey:@"cid"] intValue]];
                           if(b) {
                               for(NSDictionary *user in [object objectForKey:@"users"]) {
                                   [self->_users updateHostmask:[user objectForKey:@"usermask"] nick:[user objectForKey:@"nick"] cid:b.cid bid:b.bid];
                                   [self->_users updateAway:[[user objectForKey:@"away"] intValue] nick:[user objectForKey:@"nick"] cid:b.cid];
                               }
                           }
                           [self postObject:object forEvent:kIRCEventWhoList];
                       }
                   },
                   @"connection_deleted": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_servers removeAllDataForServer:object.cid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventConnectionDeleted];
                   },
                   @"delete_buffer": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_buffers removeAllDataForBuffer:object.bid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventDeleteBuffer];
                   },
                   @"buffer_archived": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_buffers updateArchived:1 buffer:object.bid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventBufferArchived];
                   },
                   @"buffer_unarchived": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_buffers updateArchived:0 buffer:object.bid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventBufferUnarchived];
                   },
                   @"rename_conversation": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_buffers updateName:[object objectForKey:@"new_name"] buffer:object.bid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventRenameConversation];
                   },
                   @"rename_channel": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_buffers updateName:[object objectForKey:@"new_name"] buffer:object.bid];
                       Channel *c = [self->_channels channelForBuffer:object.bid];
                       if(c)
                           c.name = [object objectForKey:@"new_name"];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventRenameConversation];
                   },
                   @"status_changed": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       CLS_LOG(@"cid%i changed to status %@ (backlog: %i resuming: %i)", object.cid, [object objectForKey:@"new_status"], backlog, self->_resuming);
                       [self->_servers updateStatus:[object objectForKey:@"new_status"] failInfo:[object objectForKey:@"fail_info"] server:object.cid];
                       if(!backlog) {
                           if([[object objectForKey:@"new_status"] isEqualToString:@"disconnected"]) {
                               NSArray *channels = [self->_channels channelsForServer:object.cid];
                               for(Channel *c in channels) {
                                   [self->_channels removeChannelForBuffer:c.bid];
                               }
                           }
                           [self postObject:object forEvent:kIRCEventStatusChanged];
                       }
                   },
                   @"time": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Event *event = [self->_events addJSONObject:object];
                       if(!backlog && !self->_resuming) {
                           [self postObject:object forEvent:kIRCEventAlert];
                           [self postObject:event forEvent:kIRCEventBufferMsg];
                       }
                   },
                   @"link_channel": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventLinkChannel];
                   },
                   @"channel_init": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Channel *channel = [self->_channels channelForBuffer:object.bid];
                       if(!channel) {
                           channel = [[Channel alloc] init];
                           [self->_channels addChannel:channel];
                       }
                       channel.cid = object.cid;
                       channel.bid = object.bid;
                       channel.name = [object objectForKey:@"chan"];
                       channel.type = [object objectForKey:@"channel_type"];
                       channel.timestamp = [[object objectForKey:@"timestamp"] doubleValue];
                       channel.topic_text = [[object objectForKey:@"topic"] objectForKey:@"text"];
                       channel.topic_author = [[[object objectForKey:@"topic"] objectForKey:@"nick"] length]?[[object objectForKey:@"topic"] objectForKey:@"nick"]:[[object objectForKey:@"topic"] objectForKey:@"server"];
                       channel.topic_time = [[[object objectForKey:@"topic"] objectForKey:@"time"] doubleValue];
                       channel.mode = @"";
                       channel.modes = [[NSMutableArray alloc] init];
                       channel.url = [object objectForKey:@"url"];
                       channel.valid = YES;
                       channel.key = NO;
                       [self->_channels updateMode:[object objectForKey:@"mode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                       [self->_users removeUsersForBuffer:object.bid];
                       for(NSDictionary *member in [object objectForKey:@"members"]) {
                           User *user = [[User alloc] init];
                           user.cid = object.cid;
                           user.bid = object.bid;
                           user.nick = [member objectForKey:@"nick"];
                           user.hostmask = [member objectForKey:@"usermask"];
                           user.mode = [member objectForKey:@"mode"];
                           user.away = [[member objectForKey:@"away"] intValue];
                           user.ircserver = [member objectForKey:@"ircserver"];
                           if([[member objectForKey:@"display_name"] isKindOfClass:NSString.class])
                               user.display_name = [member objectForKey:@"display_name"];
                           else
                               user.display_name = nil;
                           [self->_users addUser:user];
                       }
                       if(!backlog && !self->_resuming)
                           [self postObject:channel forEvent:kIRCEventChannelInit];
                   },
                   @"channel_topic": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_channels updateTopic:[object objectForKey:@"topic"] time:object.eid/1000000 author:[[object objectForKey:@"author"] length]?[object objectForKey:@"author"]:[object objectForKey:@"server"] buffer:object.bid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventChannelTopic];
                       }
                   },
                   @"channel_topic_is": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog) {
                           Buffer *b = [self->_buffers getBufferWithName:[object objectForKey:@"chan"] server:object.cid];
                           if(b) {
                               [self->_channels updateTopic:[object objectForKey:@"text"] time:[[object objectForKey:@"time"] longValue] author:[object objectForKey:@"author"] buffer:b.bid];
                           }
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventChannelTopicIs];
                       }
                   },
                   @"channel_url": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog)
                           [self->_channels updateURL:[object objectForKey:@"url"] buffer:object.bid];
                   },
                   @"channel_mode": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_channels updateMode:[object objectForKey:@"newmode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventChannelMode];
                       }
                   },
                   @"channel_mode_is": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_channels updateMode:[object objectForKey:@"newmode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventChannelMode];
                       }
                   },
                   @"channel_timestamp": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog) {
                           [self->_channels updateTimestamp:[[object objectForKey:@"timestamp"] doubleValue] buffer:object.bid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventChannelTimestamp];
                       }
                   },
                   @"joined_channel":joined_channel, @"you_joined_channel":joined_channel,
                   @"parted_channel":parted_channel, @"you_parted_channel":parted_channel,
                   @"kicked_channel":kicked_channel, @"you_kicked_channel":kicked_channel,
                   @"nickchange":nickchange, @"you_nickchange":nickchange,
                   @"quit": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventQuit];
                       }
                   },
                   @"quit_server": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventQuit];
                   },
                   @"user_channel_mode": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_users updateMode:[object objectForKey:@"newmode"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventUserChannelMode];
                       }
                   },
                   @"member_updates": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       NSDictionary *updates = [object objectForKey:@"updates"];
                       NSEnumerator *keys = updates.keyEnumerator;
                       NSString *nick;
                       while((nick = (NSString *)(keys.nextObject))) {
                           NSDictionary *update = [updates objectForKey:nick];
                           [self->_users updateAway:[[update objectForKey:@"away"] intValue] nick:nick cid:object.cid];
                           [self->_users updateHostmask:[update objectForKey:@"usermask"] nick:nick cid:object.cid bid:object.bid];
                       }
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventMemberUpdates];
                   },
                   @"user_away": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Buffer *b = [self->_buffers getBuffer:object.bid];
                       if([b.type isEqualToString:@"console"]) {
                           [self->_users updateAway:1 msg:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] cid:object.cid];
                           [self->_buffers updateAway:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] server:object.cid];
                           if(!backlog && !self->_resuming)
                               [self postObject:object forEvent:kIRCEventAway];
                       }
                   },
                   @"away": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Buffer *b = [self->_buffers getBuffer:object.bid];
                       if([b.type isEqualToString:@"console"]) {
                           [self->_users updateAway:1 msg:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] cid:object.cid];
                           [self->_buffers updateAway:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] server:object.cid];
                           if(!backlog && !self->_resuming)
                               [self postObject:object forEvent:kIRCEventAway];
                       }
                   },
                   @"user_back": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Buffer *b = [self->_buffers getBuffer:object.bid];
                       if([b.type isEqualToString:@"console"]) {
                           [self->_users updateAway:0 msg:@"" nick:[object objectForKey:@"nick"] cid:object.cid];
                           [self->_buffers updateAway:@"" nick:[object objectForKey:@"nick"] server:object.cid];
                           if(!backlog && !self->_resuming)
                               [self postObject:object forEvent:kIRCEventAway];
                       }
                   },
                   @"self_away": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!self->_resuming) {
                           [self->_users updateAway:1 msg:[object objectForKey:@"away_msg"] nick:[object objectForKey:@"nick"] cid:object.cid];
                           [self->_servers updateAway:[object objectForKey:@"away_msg"] server:object.cid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventAway];
                       }
                   },
                   @"self_back": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_awayOverride setObject:@YES forKey:@(object.cid)];
                       [self->_users updateAway:0 msg:@"" nick:[object objectForKey:@"nick"] cid:object.cid];
                       [self->_servers updateAway:@"" server:object.cid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventSelfBack];
                   },
                   @"self_details": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       Event *e = [self->_events addJSONObject:object];
                       Server *s = [self->_servers getServer:e.cid];
                       if([[object objectForKey:@"server_realname"] isKindOfClass:[NSString class]])
                           s.server_realname = [object objectForKey:@"server_realname"];
                       s.usermask = [object objectForKey:@"usermask"];
                       if(!backlog && !self->_resuming) {
                           [self postObject:e forEvent:kIRCEventSelfDetails];
                           e = [self->_events event:e.eid + 1 buffer:e.bid];
                           if(e)
                               [self postObject:e forEvent:kIRCEventSelfDetails];
                       }
                   },
                   @"user_mode": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_events addJSONObject:object];
                       if(!backlog) {
                           [self->_servers updateMode:[object objectForKey:@"newmode"] server:object.cid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventUserMode];
                       }
                   },
                   @"isupport_params": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_servers updateIsupport:[object objectForKey:@"params"] server:object.cid];
                       [self->_servers updateUserModes:[object objectForKey:@"usermodes"] server:object.cid];
                   },
                   @"set_ignores": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_servers updateIgnores:[object objectForKey:@"masks"] server:object.cid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventSetIgnores];
                   },
                   @"ignore_list": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self->_servers updateIgnores:[object objectForKey:@"masks"] server:object.cid];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventSetIgnores];
                   },
                   @"heartbeat_echo": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       NSDictionary *seenEids = [object objectForKey:@"seenEids"];
                       for(NSNumber *cid in seenEids.allKeys) {
                           NSDictionary *eids = [seenEids objectForKey:cid];
                           for(id bid in eids.allKeys) {
                               if([[eids objectForKey:bid] isKindOfClass:NSNumber.class]) {
                                   NSTimeInterval eid = [[eids objectForKey:bid] doubleValue];
                                   Buffer *buffer = [self->_buffers getBuffer:[bid intValue]];
                                   if(buffer) {
                                       buffer.last_seen_eid = eid;
                                       buffer.extraHighlights = 0;
                                   }
                                   [self->_notifications removeNotificationsForBID:[bid intValue] olderThan:eid];
                               }
                           }
                       }
                       [self->_notifications updateBadgeCount];
                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventHeartbeatEcho];
                   },
                   @"reorder_connections": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       NSArray *order = [object objectForKey:@"order"];
                       
                       for(int i = 0; i < order.count; i++) {
                           Server *s = [self->_servers getServer:[[order objectAtIndex:i] intValue]];
                           s.order = i + 1;
                       }

                       if(!backlog && !self->_resuming)
                           [self postObject:object forEvent:kIRCEventReorderConnections];
                   },
                   @"session_deleted": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       [self logout];
                       [self postObject:object forEvent:kIRCEventSessionDeleted];
                   },
                   @"display_name_change": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog) {
                           [self->_users updateDisplayName:[object objectForKey:@"display_name"] nick:[object objectForKey:@"nick"] cid:object.cid];
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventNickChange];
                       }
                   },
                   @"avatar_change": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       if(!backlog && [[object objectForKey:@"self"] boolValue]) {
                           Server *s = [self->_servers getServer:object.cid];
                           if(s) {
                               s.avatar = [[object objectForKey:@"avatar"] isKindOfClass:NSString.class] ? [object objectForKey:@"avatar"] : nil;
                               s.avatarURL = [[object objectForKey:@"avatar_url"] isKindOfClass:NSString.class] ? [object objectForKey:@"avatar_url"] : nil;
                           }
                           
                           if(!self->_resuming)
                               [self postObject:object forEvent:kIRCEventAvatarChange];
                       }
                   },
                   @"empty_msg": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       @synchronized (self) {
                           [self->_pendingEdits addObject:object];
                       }
                       [self _processPendingEdits:backlog];
                   },
                   @"watch_status": ^(IRCCloudJSONObject *object, BOOL backlog) {
                       NSMutableDictionary *d = object.dictionary.mutableCopy;
                       [d setObject:@([[NSDate date] timeIntervalSince1970] * 1000000) forKey:@"eid"];
                       Event *e = [self->_events addJSONObject:[[IRCCloudJSONObject alloc] initWithDictionary:d]];
                       if(!backlog && !self->_resuming)
                           [self postObject:e forEvent:kIRCEventBufferMsg];
                   },
               }.mutableCopy;
        
        for(NSString *type in @[@"buffer_msg", @"buffer_me_msg", @"wait", @"banned", @"kill", @"connectingself->_cancelled",
                                @"target_callerid", @"notice", @"server_motdstart", @"server_welcome", @"server_motd", @"server_endofmotd",
                                @"server_nomotd", @"server_luserclient", @"server_luserop", @"server_luserconns", @"server_luserme", @"server_n_local",
                                @"server_luserchannels", @"server_n_global", @"server_yourhost",@"server_created", @"server_luserunknown",
                                @"services_down", @"your_unique_id", @"callerid", @"target_notified", @"myinfo", @"hidden_host_set", @"unhandled_line",
                                @"unparsed_line", @"connecting_failed", @"nickname_in_use", @"channel_invite", @"motd_response", @"socket_closed",
                                @"channel_mode_list_change", @"msg_services", @"stats", @"statslinkinfo", @"statscommands", @"statscline",
                                @"statsnline", @"statsiline", @"statskline", @"statsqline", @"statsyline", @"statsbline", @"statsgline", @"statstline",
                                @"statseline", @"statsvline", @"statslline", @"statsuptime", @"statsoline", @"statshline", @"statssline", @"statsuline",
                                @"statsdebug", @"spamfilter", @"endofstats", @"inviting_to_channel", @"error", @"too_fast", @"no_bots",
                                @"wallops", @"logged_in_as", @"sasl_fail", @"sasl_too_long", @"sasl_aborted", @"sasl_already",
                                @"you_are_operator", @"btn_metadata_set", @"sasl_success", @"version", @"channel_name_change",
                                @"cap_ls", @"cap_list", @"cap_new", @"cap_del", @"cap_req",@"cap_ack",@"cap_nak",@"cap_raw",@"cap_invalid",
                                @"newsflash", @"invited", @"server_snomask", @"codepage", @"logged_out", @"nick_locked", @"info_response", @"generic_server_info",
                                @"unknown_umode", @"bad_ping", @"cap_raw", @"rehashed_config", @"knock", @"bad_channel_mask", @"kill_deny",
                                @"chan_own_priv_needed", @"not_for_halfops", @"chan_forbidden", @"starircd_welcome", @"zurna_motd",
                                @"ambiguous_error_message", @"list_usage", @"list_syntax", @"who_syntax", @"text", @"admin_info",
                                @"sqline_nick", @"user_chghost", @"loaded_module", @"unloaded_module", @"invite_notify", @"help"]) {
            [parserMap setObject:msg forKey:type];
        }
        
        for(NSString *type in @[@"too_many_channels", @"no_such_channel", @"bad_channel_name",
                                @"no_such_nick", @"invalid_nick_change", @"chan_privs_needed",
                                @"accept_exists", @"banned_from_channel", @"oper_only",
                                @"no_nick_change", @"no_messages_from_non_registered", @"not_registered",
                                @"already_registered", @"too_many_targets", @"no_such_server",
                                @"unknown_command", @"help_not_found", @"accept_full",
                                @"accept_not", @"nick_collision", @"nick_too_fast", @"need_registered_nick",
                                @"save_nick", @"unknown_mode", @"user_not_in_channel",
                                @"need_more_params", @"users_dont_match", @"users_disabled",
                                @"invalid_operator_password", @"flood_warning", @"privs_needed",
                                @"operator_fail", @"not_on_channel", @"ban_on_chan",
                                @"cannot_send_to_chan", @"user_on_channel", @"no_nick_given",
                                @"no_text_to_send", @"no_origin", @"only_servers_can_change_mode",
                                @"silence", @"no_channel_topic", @"invite_only_chan", @"channel_full", @"channel_key_set",
                                @"blocked_channel",@"unknown_error",@"channame_in_use",@"pong",
                                @"monitor_full",@"mlock_restricted",@"cannot_do_cmd",@"secure_only_chan",
                                @"cannot_change_chan_mode",@"knock_delivered",@"too_many_knocks",
                                @"chan_open",@"knock_on_chan",@"knock_disabled",@"cannotknock",@"ownmode",
                                @"nossl",@"redirect_error",@"invalid_flood",@"join_flood",@"metadata_limit",
                                @"metadata_targetinvalid",@"metadata_nomatchingkey",@"metadata_keyinvalid",
                                @"metadata_keynotset",@"metadata_keynopermission",@"metadata_toomanysubs",@"invalid_nick"]) {
            [parserMap setObject:alert forKey:type];
        }
        
        NSDictionary *broadcastMap = @{    @"bad_channel_key":@(kIRCEventBadChannelKey),
                                           @"channel_query":@(kIRCEventChannelQuery),
                                           @"open_buffer":@(kIRCEventOpenBuffer),
                                           @"ban_list":@(kIRCEventBanList),
                                           @"accept_list":@(kIRCEventAcceptList),
                                           @"quiet_list":@(kIRCEventQuietList),
                                           @"ban_exception_list":@(kIRCEventBanExceptionList),
                                           @"invite_list":@(kIRCEventInviteList),
                                           @"names_reply":@(kIRCEventNamesList),
                                           @"whois_response":@(kIRCEventWhois),
                                           @"list_response_fetching":@(kIRCEventListResponseFetching),
                                           @"list_response_toomany":@(kIRCEventListResponseTooManyChannels),
                                           @"list_response":@(kIRCEventListResponse),
                                           @"map_list":@(kIRCEventServerMap),
                                           @"who_special_response":@(kIRCEventWhoSpecialResponse),
                                           @"modules_list":@(kIRCEventModulesList),
                                           @"links_response":@(kIRCEventLinksResponse),
                                           @"whowas_response":@(kIRCEventWhoWas),
                                           @"trace_response":@(kIRCEventTraceResponse),
                                           @"export_finished":@(kIRCEventLogExportFinished),
                                           @"chanfilter_list":@(kIRCEventChanFilterList),
                                           @"text":@(kIRCEventTextList)
                                           };
        void (^broadcast)(IRCCloudJSONObject *object, BOOL backlog) = ^(IRCCloudJSONObject *object, BOOL backlog) {
            if(!backlog && !self->_resuming)
                [self postObject:object forEvent:[[broadcastMap objectForKey:object.type] intValue]];
        };

        for(NSString *type in broadcastMap.allKeys) {
            [parserMap setObject:broadcast forKey:type];
        }
        
        self->_parserMap = parserMap;
    }
    return self;
}

-(void)_processPendingEdits:(BOOL)backlog {
    NSArray *pending;
    @synchronized (self) {
        pending = self->_pendingEdits;
        self->_pendingEdits = [[NSMutableArray alloc] init];
    }
    for(IRCCloudJSONObject *object in pending) {
        NSDictionary *entities = [object objectForKey:@"entities"];
        //NSLog(@"empty_msg entities: %@", entities);
        if([entities objectForKey:@"delete"]) {
            BOOL found = NO;
            NSString *msgId = [entities objectForKey:@"delete"];
            if(msgId.length) {
                Event *e = [[EventsDataSource sharedInstance] message:msgId buffer:object.bid];
                if(e) {
                    [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                    found = YES;
                }
            }
            if(found) {
                if(!backlog && !self->_resuming)
                    [self postObject:object forEvent:kIRCEventMessageChanged];
            } else {
                [self->_pendingEdits addObject:object];
            }
        } else if([entities objectForKey:@"edit"]) {
            BOOL found = NO;
            NSString *msgId = [entities objectForKey:@"edit"];
            if(msgId.length) {
                Event *e = [[EventsDataSource sharedInstance] message:msgId buffer:object.bid];
                if(e) {
                    if(object.eid >= e.lastEditEID) {
                        if([[entities objectForKey:@"edit_text"] isKindOfClass:NSString.class]) {
                            e.msg = [entities objectForKey:@"edit_text"];
                            e.edited = YES;
                            NSMutableDictionary *d = e.entities.mutableCopy;
                            [d removeObjectForKey:@"mentions"];
                            [d removeObjectForKey:@"mention_data"];
                            e.entities = d;
                        }
                        NSMutableDictionary *d = e.entities.mutableCopy;
                        [d setValuesForKeysWithDictionary:entities];
                        e.entities = d;
                        e.lastEditEID = object.eid;
                        e.formatted = nil;
                        e.formattedMsg = nil;
                    }
                    found = YES;
                }
            }
            if(found) {
                if(!backlog && !self->_resuming)
                    [self postObject:object forEvent:kIRCEventMessageChanged];
            } else {
                [self->_pendingEdits addObject:object];
            }
        }
    }
    CLS_LOG(@"Queued pending edits: %lu", (unsigned long)self->_pendingEdits.count);
}

//Adapted from http://stackoverflow.com/a/17057553/1406639
-(kIRCCloudReachability)reachable {
    SCNetworkReachabilityFlags flags;
    if(self->_reachabilityValid && SCNetworkReachabilityGetFlags(self->_reachability, &flags)) {
        if((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
            // if target host is not reachable
            return kIRCCloudUnreachable;
        }
        
        if((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            // if target host is reachable and no connection is required
            return kIRCCloudReachable;
        }
        
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
            // ... and the connection is on-demand (or on-traffic) if the
            //     calling application is using the CFSocketStream or higher APIs
            
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                // ... and no [user] intervention is needed
                return kIRCCloudReachable;
            }
        }
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
            // ... but WWAN connections are OK if the calling application
            //     is using the CFNetwork (CFSocketStream?) APIs.
            return kIRCCloudReachable;
        }
        return kIRCCloudUnreachable;
    }
    return kIRCCloudUnknown;
}

-(BOOL)isWifi {
    SCNetworkReachabilityFlags flags;
    if(self->_reachabilityValid && SCNetworkReachabilityGetFlags(self->_reachability, &flags)) {
        return (flags & kSCNetworkReachabilityFlagsIsWWAN) != kSCNetworkReachabilityFlagsIsWWAN;
    }
    return NO;
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    static BOOL firstTime = YES;
    static int lastType = TYPE_UNKNOWN;
    int type = TYPE_UNKNOWN;
    [NetworkConnection sharedInstance].reachabilityValid = YES;
    kIRCCloudReachability reachable = [[NetworkConnection sharedInstance] reachable];
    kIRCCloudState state = [NetworkConnection sharedInstance].state;
    CLS_LOG(@"IRCCloud state: %i Reconnect timestamp: %f Reachable: %i lastType: %i", state, [NetworkConnection sharedInstance].reconnectTimestamp, reachable, lastType);
    
    if(flags & kSCNetworkReachabilityFlagsIsWWAN)
        type = TYPE_WWAN;
    else if (flags & kSCNetworkReachabilityFlagsReachable)
        type = TYPE_WIFI;
    else
        type = TYPE_UNKNOWN;

    if(!firstTime && type != lastType && state != kIRCCloudStateDisconnected) {
        CLS_LOG(@"IRCCloud became unreachable, disconnecting websocket");
        SCNetworkReachabilityRef r = [NetworkConnection sharedInstance].reachability;
        [NetworkConnection sharedInstance].reachability = nil;
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
        [NetworkConnection sharedInstance].reachability = r;
        [NetworkConnection sharedInstance].reconnectTimestamp = -1;
        state = kIRCCloudStateDisconnected;
        [[NetworkConnection sharedInstance] performSelectorInBackground:@selector(serialize) withObject:nil];
    }
    
    lastType = type;
    firstTime = NO;
    
    if(reachable == kIRCCloudReachable && state == kIRCCloudStateDisconnected && [NetworkConnection sharedInstance].reconnectTimestamp != 0 && [[NetworkConnection sharedInstance].session length]) {
        CLS_LOG(@"IRCCloud server became reachable, connecting");
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(_connect) withObject:nil waitUntilDone:YES];
    } else if(reachable == kIRCCloudUnreachable && state == kIRCCloudStateConnected) {
        CLS_LOG(@"IRCCloud server became unreachable, disconnecting");
        SCNetworkReachabilityRef r = [NetworkConnection sharedInstance].reachability;
        [NetworkConnection sharedInstance].reachability = nil;
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
        [NetworkConnection sharedInstance].reachability = r;
        [[NetworkConnection sharedInstance] performSelectorInBackground:@selector(serialize) withObject:nil];
    }
    if(reachable == kIRCCloudUnreachable) {
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
        [NetworkConnection sharedInstance].reconnectTimestamp = -1;
    }
    [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
}

-(void)_connect {
    [self connect:self->_notifier];
}

-(void)login:(NSString *)email password:(NSString *)password token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler {
    [self _postRequest:@"/chat/login" args:@{@"email":email, @"password":password, @"token":token} handler:handler];
}

-(void)login:(NSURL *)accessLink handler:(IRCCloudAPIResultHandler)handler {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:accessLink];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    
    [self _performDataTaskRequest:request handler:handler];
}

-(void)signup:(NSString *)email password:(NSString *)password realname:(NSString *)realname token:(NSString *)token impression:(NSString *)impression handler:(IRCCloudAPIResultHandler)handler {
    [self _postRequest:@"/chat/signup" args:@{@"realname":realname, @"email":email, @"password":password, @"token":token, @"ios_impression":impression} handler:handler];
}

-(void)requestPassword:(NSString *)email token:(NSString *)token handler:(IRCCloudAPIResultHandler)handler {
    return [self _postRequest:@"/chat/request-access-link" args:@{@"email":email, @"mobile":@"1", @"token":token} handler:handler];
}

//From: http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string
-(NSString *)dataToHex:(NSData *)data {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02x", (unsigned int)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

-(void)registerAPNs:(NSData *)token fcm:(NSString *)fcm handler:(IRCCloudAPIResultHandler)handler {
#if !defined(DEBUG) && !defined(EXTENSION)
    [self _postRequest:@"/apn-register" args:@{@"device_id":[self dataToHex:token], @"fcm_token":fcm} handler:handler];
#endif
}

-(void)unregisterAPNs:(NSData *)token fcm:(NSString *)fcm session:(NSString *)session handler:(IRCCloudAPIResultHandler)handler {
#ifndef EXTENSION
    [self _postRequest:@"/apn-unregister" args:@{@"device_id":[self dataToHex:token], @"fcm_token":fcm, @"session":session} handler:handler];
#endif
}

-(void)impression:(NSString *)idfa referrer:(NSString *)referrer handler:(IRCCloudAPIResultHandler)handler {
#ifndef EXTENSION
    return [self _postRequest:@"/chat/ios-impressions" args:@{@"idfa":idfa, @"referrer":referrer} handler:handler];
#endif
}

-(void)requestAuthTokenWithHandler:(IRCCloudAPIResultHandler)handler {
    [self _postRequest:@"/chat/auth-formtoken" args:@{} handler:handler];
}

-(void)_performDataTaskRequest:(NSURLRequest *)request handler:(IRCCloudAPIResultHandler)resultHandler {
    NSURLSessionDataTask* task = [_urlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(resultHandler) {
            if(!error && data) {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                if(dict)
                    resultHandler([[IRCCloudJSONObject alloc] initWithDictionary:dict]);
                else
                    resultHandler(nil);
            } else {
                CLS_LOG(@"Request to %@ failed with error: %@", request.URL, error);
                resultHandler(nil);
            }
        }
    }];
    [task resume];
}

-(void)_get:(NSURL *)url handler:(IRCCloudAPIResultHandler)resultHandler {
    if(![NSThread isMainThread]) {
        CLS_LOG(@"*** _get called on wrong thread");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self _get:url handler:resultHandler];
        }];
    } else {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPShouldHandleCookies:NO];
        [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
        if(self.session.length > 1 && [url.scheme isEqualToString:@"https"] && [url.host isEqualToString:IRCCLOUD_HOST])
            [request setValue:[NSString stringWithFormat:@"session=%@",self.session] forHTTPHeaderField:@"Cookie"];
        
        [self _performDataTaskRequest:request handler:resultHandler];
    }
}

-(void)requestConfigurationWithHandler:(IRCCloudAPIResultHandler)handler {
    [self _get:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/config", IRCCLOUD_HOST]] handler:^(IRCCloudJSONObject *object) {
        if(object) {
            self->_config = object.dictionary;
        }
        
        [self _configLoaded];
        
        if(handler)
            handler(object);
    }];
}

-(void)_configLoaded {
#ifdef ENTERPRISE
    if(![[self->_config objectForKey:@"enterprise"] isKindOfClass:[NSDictionary class]])
        self->_globalMsg = [NSString stringWithFormat:@"Some features, such as push notifications, may not work as expected. Please download the standard IRCCloud app from the App Store: %@", [self->_config objectForKey:@"ios_app"]];
#endif
    
    if(self->_config) {
        self.fileURITemplate = [CSURITemplate URITemplateWithString:[self->_config objectForKey:@"file_uri_template"] error:nil];
        self.pasteURITemplate = [CSURITemplate URITemplateWithString:[self->_config objectForKey:@"pastebin_uri_template"] error:nil];
        self.avatarURITemplate = [CSURITemplate URITemplateWithString:[self->_config objectForKey:@"avatar_uri_template"] error:nil];
        self.avatarRedirectURITemplate = [CSURITemplate URITemplateWithString:[self->_config objectForKey:@"avatar_redirect_uri_template"] error:nil];
        
        IRCCLOUD_HOST = [self->_config objectForKey:@"api_host"];
        if([IRCCLOUD_HOST hasPrefix:@"http://"])
            IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:7];
        if([IRCCLOUD_HOST hasPrefix:@"https://"])
            IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:8];
        if([IRCCLOUD_HOST hasSuffix:@"/"])
            IRCCLOUD_HOST = [IRCCLOUD_HOST substringToIndex:IRCCLOUD_HOST.length - 1];
        
        [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_HOST forKey:@"host"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void)propertiesForFile:(NSString *)fileID handler:(IRCCloudAPIResultHandler)handler {
    [self _get:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/file/json/%@", IRCCLOUD_HOST, fileID]] handler:handler];
}

-(void)getFiles:(int)page handler:(IRCCloudAPIResultHandler)handler {
    [self _get:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/files?page=%i", IRCCLOUD_HOST, page]] handler:handler];
}

-(void)getPastebins:(int)page handler:(IRCCloudAPIResultHandler)handler {
    [self _get:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/pastebins?page=%i", IRCCLOUD_HOST, page]] handler:handler];
}

-(void)getLogExportsWithHandler:(IRCCloudAPIResultHandler)handler {
    [self _get:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/log-exports", IRCCLOUD_HOST]] handler:handler];
}

-(int)_sendRequest:(NSString *)method args:(NSDictionary *)args handler:(IRCCloudAPIResultHandler)resultHandler {
    @synchronized(self->_writer) {
        if(self->_state == kIRCCloudStateConnected || [method isEqualToString:@"auth"]) {
            NSMutableDictionary *dict = args?[[NSMutableDictionary alloc] initWithDictionary:args]:[[NSMutableDictionary alloc] init];
            [dict setObject:method forKey:@"_method"];
            if(![method isEqualToString:@"auth"])
                [dict setObject:@(++_lastReqId) forKey:@"_reqid"];
            [self->_socket sendText:[self->_writer stringWithObject:dict]];
            if(resultHandler)
                [self->_resultHandlers setObject:resultHandler forKey:@(self->_lastReqId)];
            return _lastReqId;
        } else {
            CLS_LOG(@"Discarding request '%@' on disconnected socket", method);
            return -1;
        }
    }
}

-(void)_postRequest:(NSString *)path args:(NSDictionary *)args handler:(IRCCloudAPIResultHandler)resultHandler {
    if(![NSThread isMainThread]) {
        CLS_LOG(@"*** _postRequest called on wrong thread");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self _postRequest:path args:args handler:resultHandler];
        }];
    } else {
        NSMutableString *body = [[NSMutableString alloc] init];
        
        for (NSString *key in args.allKeys) {
            if(body.length)
                [body appendString:@"&"];
            [body appendFormat:@"%@=%@",key,[[args objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"\"#%<>[\\]^`{|}+"].invertedSet]];
        }
        
        if(self.session.length > 1 && ![args objectForKey:@"session"])
            [body appendFormat:@"&session=%@", self.session];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@%@", IRCCLOUD_HOST, path]]];
        [request setHTTPShouldHandleCookies:NO];
        [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
        if([args objectForKey:@"token"])
            [request setValue:[args objectForKey:@"token"] forHTTPHeaderField:@"x-auth-formtoken"];
        if([args objectForKey:@"session"])
            [request setValue:[NSString stringWithFormat:@"session=%@",[args objectForKey:@"session"]] forHTTPHeaderField:@"Cookie"];
        else if(self.session.length > 1)
            [request setValue:[NSString stringWithFormat:@"session=%@",self.session] forHTTPHeaderField:@"Cookie"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

        [self _performDataTaskRequest:request handler:resultHandler];
    }
}

-(void)POSTsay:(NSString *)message to:(NSString *)to cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(to)
        [self _postRequest:@"/chat/say" args:@{@"msg":message, @"to":to, @"cid":[@(cid) stringValue]} handler:resultHandler];
    else
        [self _postRequest:@"/chat/say" args:@{@"msg":message, @"to":@"*", @"cid":[@(cid) stringValue]} handler:resultHandler];
}

-(int)say:(NSString *)message to:(NSString *)to cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(!message)
        message = @"";
    if(to)
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message, @"to":to} handler:resultHandler];
    else
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message, @"to":@"*"} handler:resultHandler];
}

-(void)POSTreply:(NSString *)message to:(NSString *)to cid:(int)cid msgid:(NSString *)msgid handler:(IRCCloudAPIResultHandler)handler {
    if(!message)
        message = @"";
    [self _postRequest:@"/chat/reply" args:@{@"cid":[@(cid) stringValue], @"reply":message, @"to":to, @"msgid":msgid} handler:handler];
}

-(int)reply:(NSString *)message to:(NSString *)to cid:(int)cid msgid:(NSString *)msgid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(!message)
        message = @"";
    return [self _sendRequest:@"reply" args:@{@"cid":@(cid), @"reply":message, @"to":to, @"msgid":msgid} handler:resultHandler];
}

-(int)heartbeat:(int)selectedBuffer cids:(NSArray *)cids bids:(NSArray *)bids lastSeenEids:(NSArray *)lastSeenEids handler:(IRCCloudAPIResultHandler)resultHandler {
    @synchronized(self->_writer) {
        NSMutableDictionary *heartbeat = [[NSMutableDictionary alloc] init];
        for(int i = 0; i < cids.count; i++) {
            NSMutableDictionary *d = [heartbeat objectForKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            if(!d) {
                d = [[NSMutableDictionary alloc] init];
                [heartbeat setObject:d forKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            }
            [d setObject:[lastSeenEids objectAtIndex:i] forKey:[NSString stringWithFormat:@"%@",[bids objectAtIndex:i]]];
        }
        NSString *seenEids = [self->_writer stringWithObject:heartbeat];
        [__userInfoLock lock];
        NSMutableDictionary *d = self->_userInfo.mutableCopy;
        [d setObject:@(selectedBuffer) forKey:@"last_selected_bid"];
        self->_userInfo = d;
        [__userInfoLock unlock];
        return [self _sendRequest:@"heartbeat" args:@{@"selectedBuffer":@(selectedBuffer), @"seenEids":seenEids} handler:resultHandler];
    }
}
-(int)heartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self heartbeat:selectedBuffer cids:@[@(cid)] bids:@[@(bid)] lastSeenEids:@[@(lastSeenEid)] handler:resultHandler];
}

-(void)POSTheartbeat:(int)selectedBuffer cids:(NSArray *)cids bids:(NSArray *)bids lastSeenEids:(NSArray *)lastSeenEids handler:(IRCCloudAPIResultHandler)handler {
    @synchronized(self->_writer) {
        NSMutableDictionary *heartbeat = [[NSMutableDictionary alloc] init];
        for(int i = 0; i < cids.count; i++) {
            NSMutableDictionary *d = [heartbeat objectForKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            if(!d) {
                d = [[NSMutableDictionary alloc] init];
                [heartbeat setObject:d forKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            }
            [d setObject:[lastSeenEids objectAtIndex:i] forKey:[NSString stringWithFormat:@"%@",[bids objectAtIndex:i]]];
        }
        NSString *seenEids = [self->_writer stringWithObject:heartbeat];
        [self _postRequest:@"/chat/heartbeat" args:@{@"selectedBuffer":[@(selectedBuffer) stringValue], @"seenEids":seenEids} handler:handler];
    }
}

-(void)POSTheartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid handler:(IRCCloudAPIResultHandler)handler {
    [self POSTheartbeat:selectedBuffer cids:@[@(cid)] bids:@[@(bid)] lastSeenEids:@[@(lastSeenEid)] handler:handler];
}

-(int)join:(NSString *)channel key:(NSString *)key cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(key.length) {
        return [self _sendRequest:@"join" args:@{@"cid":@(cid), @"channel":channel, @"key":key} handler:resultHandler];
    } else {
        return [self _sendRequest:@"join" args:@{@"cid":@(cid), @"channel":channel} handler:resultHandler];
    }
}

-(int)part:(NSString *)channel msg:(NSString *)msg cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(msg.length) {
        return [self _sendRequest:@"part" args:@{@"cid":@(cid), @"channel":channel, @"msg":msg} handler:resultHandler];
    } else {
        return [self _sendRequest:@"part" args:@{@"cid":@(cid), @"channel":channel} handler:resultHandler];
    }
}

-(int)kick:(NSString *)nick chan:(NSString *)chan msg:(NSString *)msg cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self say:[NSString stringWithFormat:@"/kick %@ %@",nick,(msg.length)?msg:@""] to:chan cid:cid handler:resultHandler];
}

-(int)mode:(NSString *)mode chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self say:[NSString stringWithFormat:@"/mode %@ %@",chan,mode] to:chan cid:cid handler:resultHandler];
}

-(int)invite:(NSString *)nick chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self say:[NSString stringWithFormat:@"/invite %@ %@",nick,chan] to:chan cid:cid handler:resultHandler];
}

-(int)archiveBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"archive-buffer" args:@{@"cid":@(cid),@"id":@(bid)} handler:resultHandler];
}

-(int)unarchiveBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"unarchive-buffer" args:@{@"cid":@(cid),@"id":@(bid)} handler:resultHandler];
}

-(int)deleteBuffer:(int)bid cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-buffer" args:@{@"cid":@(cid),@"id":@(bid)} handler:resultHandler];
}

-(int)deleteServer:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-connection" args:@{@"cid":@(cid)} handler:(IRCCloudAPIResultHandler)resultHandler];
}

-(int)changePassword:(NSString *)password newPassword:(NSString *)newPassword handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"change-password" args:@{@"password":password,@"newPassword":newPassword} handler:resultHandler];
}

-(int)deleteAccount:(NSString *)password handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-account" args:@{@"password":password} handler:resultHandler];
}


-(int)addServer:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands channels:(NSString *)channels handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"add-server" args:@{
                                                   @"hostname":hostname?hostname:@"",
                                                   @"port":@(port),
                                                   @"ssl":[NSString stringWithFormat:@"%i",ssl],
                                                   @"netname":netname?netname:@"",
                                                   @"nickname":nick?nick:@"",
                                                   @"realname":realname?realname:@"",
                                                   @"server_pass":serverPass?serverPass:@"",
                                                   @"nspass":nickservPass?nickservPass:@"",
                                                   @"joincommands":joinCommands?joinCommands:@"",
                                                   @"channels":channels?channels:@""} handler:resultHandler];
}

-(int)editServer:(int)cid hostname:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"edit-server" args:@{
                                                    @"hostname":hostname?hostname:@"",
                                                    @"port":@(port),
                                                    @"ssl":[NSString stringWithFormat:@"%i",ssl],
                                                    @"netname":netname?netname:@"",
                                                    @"nickname":nick?nick:@"",
                                                    @"realname":realname?realname:@"",
                                                    @"server_pass":serverPass?serverPass:@"",
                                                    @"nspass":nickservPass?nickservPass:@"",
                                                    @"joincommands":joinCommands?joinCommands:@"",
                                                    @"cid":@(cid)} handler:resultHandler];
}

-(int)ignore:(NSString *)mask cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"ignore" args:@{@"cid":@(cid),@"mask":mask} handler:resultHandler];
}

-(int)unignore:(NSString *)mask cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"unignore" args:@{@"cid":@(cid),@"mask":mask} handler:resultHandler];
}

-(int)setPrefs:(NSString *)prefs handler:(IRCCloudAPIResultHandler)resultHandler {
#ifdef DEBUG
if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
    self->_prefs = [NSJSONSerialization JSONObjectWithData:[prefs dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    [self postObject:nil forEvent:kIRCEventUserInfo];
    resultHandler([[IRCCloudJSONObject alloc] initWithDictionary:@{@"success":@YES}]);
    return 1;
} else {
#endif
    self->_prefs = nil;
    return [self _sendRequest:@"set-prefs" args:@{@"prefs":prefs} handler:resultHandler];
#ifdef DEBUG
}
#endif
}

-(int)setRealname:(NSString *)realname highlights:(NSString *)highlights autoaway:(BOOL)autoaway handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"user-settings" args:@{
                                                      @"realname":realname,
                                                      @"hwords":highlights,
                                                      @"autoaway":autoaway?@"1":@"0"} handler:resultHandler];
}

-(int)changeEmail:(NSString *)email password:(NSString *)password handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"change-password" args:@{
                                                      @"email":email,
                                                      @"password":password} handler:resultHandler];
}

-(int)ns_help_register:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"ns-help-register" args:@{@"cid":@(cid)} handler:resultHandler];
}

-(int)setNickservPass:(NSString *)nspass cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"set-nspass" args:@{@"cid":@(cid),@"nspass":nspass} handler:resultHandler];
}

-(int)whois:(NSString *)nick server:(NSString *)server cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(server.length) {
        return [self _sendRequest:@"whois" args:@{@"cid":@(cid), @"nick":nick, @"server":server} handler:resultHandler];
    } else {
        return [self _sendRequest:@"whois" args:@{@"cid":@(cid), @"nick":nick} handler:resultHandler];
    }
}

-(int)topic:(NSString *)topic chan:(NSString *)chan cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"topic" args:@{@"cid":@(cid),@"channel":chan,@"topic":topic} handler:resultHandler];
}

-(int)back:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"back" args:@{@"cid":@(cid)} handler:resultHandler];
}

-(int)resendVerifyEmailWithHandler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"resend-verify-email" args:nil handler:resultHandler];
}

-(int)disconnect:(int)cid msg:(NSString *)msg handler:(IRCCloudAPIResultHandler)resultHandler {
    CLS_LOG(@"Disconnecting cid%i", cid);
    if(msg.length)
        return [self _sendRequest:@"disconnect" args:@{@"cid":@(cid), @"msg":msg} handler:resultHandler];
    else
        return [self _sendRequest:@"disconnect" args:@{@"cid":@(cid)} handler:resultHandler];
}

-(int)reconnect:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    CLS_LOG(@"Reconnecting cid%i", cid);
    int reqid = [self _sendRequest:@"reconnect" args:@{@"cid":@(cid)} handler:resultHandler];
    if(reqid > 0) {
        Server *s = [self->_servers getServer:cid];
        if(s) {
            s.status = @"queued";
            [self postObject:@{@"cid":@(cid)} forEvent:kIRCEventConnectionLag];
        }
    }
    return reqid;
}

-(int)reorderConnections:(NSString *)cids handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"reorder-connections" args:@{@"cids":cids} handler:resultHandler];
}

-(void)finalizeUpload:(NSString *)uploadID filename:(NSString *)filename originalFilename:(NSString *)originalFilename avatar:(BOOL)avatar orgId:(int)orgId cid:(int)cid handler:(IRCCloudAPIResultHandler)handler {
    if(avatar) {
        if(cid) {
            [self _postRequest:@"/chat/upload-finalise" args:@{@"id":uploadID, @"filename":filename, @"original_filename":originalFilename, @"type":@"avatar", @"cid":[NSString stringWithFormat:@"%i", cid]} handler:handler];
        } else if(orgId == -1) {
            [self _postRequest:@"/chat/upload-finalise" args:@{@"id":uploadID, @"filename":filename, @"original_filename":originalFilename, @"type":@"avatar", @"primary":@"1"} handler:handler];
        } else {
            [self _postRequest:@"/chat/upload-finalise" args:@{@"id":uploadID, @"filename":filename, @"original_filename":originalFilename, @"type":@"avatar", @"org":[NSString stringWithFormat:@"%i", orgId]} handler:handler];
        }
    } else {
        [self _postRequest:@"/chat/upload-finalise" args:@{@"id":uploadID, @"filename":filename, @"original_filename":originalFilename} handler:handler];
    }
}

-(int)deleteFile:(NSString *)fileID handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-file" args:@{@"file":fileID} handler:resultHandler];
}

-(int)deleteMessage:(NSString *)msgId cid:(int)cid to:(NSString *)to handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-message" args:@{@"cid":@(cid), @"to":to, @"msgid":msgId} handler:resultHandler];
}

-(int)editMessage:(NSString *)msgId cid:(int)cid to:(NSString *)to msg:(NSString *)msg handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"edit-message" args:@{@"cid":@(cid), @"to":to, @"msgid":msgId, @"edit":msg} handler:resultHandler];
}

-(int)paste:(NSString *)name contents:(NSString *)contents extension:(NSString *)extension handler:(IRCCloudAPIResultHandler)resultHandler {
    if(name.length) {
        return [self _sendRequest:@"paste" args:@{@"name":name, @"contents":contents, @"extension":extension} handler:resultHandler];
    } else {
        return [self _sendRequest:@"paste" args:@{@"contents":contents, @"extension":extension} handler:resultHandler];
    }
}

-(int)deletePaste:(NSString *)pasteID handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"delete-pastebin" args:@{@"id":pasteID} handler:resultHandler];
}

-(int)editPaste:(NSString *)pasteID name:(NSString *)name contents:(NSString *)contents extension:(NSString *)extension handler:(IRCCloudAPIResultHandler)resultHandler {
    if(name.length) {
        return [self _sendRequest:@"edit-pastebin" args:@{@"id":pasteID, @"name":name, @"body":contents, @"extension":extension} handler:resultHandler];
    } else {
        return [self _sendRequest:@"edit-pastebin" args:@{@"id":pasteID, @"body":contents, @"extension":extension} handler:resultHandler];
    }
}

-(int)exportLog:(NSString *)timezone cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(cid > 0) {
        if(bid > 0) {
            return [self _sendRequest:@"export-log" args:@{@"cid":@(cid), @"bid":@(bid), @"timezone":timezone} handler:resultHandler];
        } else {
            return [self _sendRequest:@"export-log" args:@{@"cid":@(cid), @"timezone":timezone} handler:resultHandler];
        }
    } else {
        return [self _sendRequest:@"export-log" args:@{@"timezone":timezone} handler:resultHandler];
    }
}

-(int)renameChannel:(NSString *)name cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"rename-channel" args:@{@"cid":@(cid), @"id":@(bid), @"name":name} handler:resultHandler];
}

-(int)renameConversation:(NSString *)name cid:(int)cid bid:(int)bid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"rename-conversation" args:@{@"cid":@(cid), @"id":@(bid), @"name":name} handler:resultHandler];
}

-(int)setAvatar:(NSString *)avatarId orgId:(int)orgId handler:(IRCCloudAPIResultHandler)resultHandler {
    if(orgId == -1) {
        if(avatarId)
            return [self _sendRequest:@"set-avatar" args:@{@"id":avatarId, @"primary":@"1"} handler:resultHandler];
        else
            return [self _sendRequest:@"set-avatar" args:@{@"clear":@"1", @"primary":@"1"} handler:resultHandler];
    } else {
        if(avatarId)
            return [self _sendRequest:@"set-avatar" args:@{@"id":avatarId, @"org":@(orgId)} handler:resultHandler];
        else
            return [self _sendRequest:@"set-avatar" args:@{@"clear":@"1", @"org":@(orgId)} handler:resultHandler];
    }
}

-(int)setAvatar:(NSString *)avatarId cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    if(avatarId)
        return [self _sendRequest:@"set-avatar" args:@{@"id":avatarId, @"cid":@(cid)} handler:resultHandler];
    else
        return [self _sendRequest:@"set-avatar" args:@{@"clear":@"1", @"cid":@(cid)} handler:resultHandler];
}

-(int)setNetworkName:(NSString *)name cid:(int)cid handler:(IRCCloudAPIResultHandler)resultHandler {
    return [self _sendRequest:@"set-netname" args:@{@"cid":@(cid), @"netname":name} handler:resultHandler];
}

-(void)_createJSONParser {
    self->_parser = [SBJson5Parser multiRootParserWithBlock:^(id item, BOOL *stop) {
        [self parse:item backlog:NO];
    } errorHandler:^(NSError *error) {
        CLS_LOG(@"JSON ERROR: %@", error);
        self->_streamId = nil;
        self->_highestEID = 0;
    }];
}

-(void)connect:(BOOL)notifier {
    @synchronized(self) {
        if(self->_mock) {
            self->_reconnectTimestamp = -1;
            self->_state = kIRCCloudStateConnected;
            self->_ready = YES;
            return;
        }
        
        if(IRCCLOUD_HOST == nil || IRCCLOUD_HOST.length < 1) {
            CLS_LOG(@"Not connecting, no host");
            return;
        }
        
        if(_session.length < 1) {
            CLS_LOG(@"Not connecting, no session");
            return;
        }
        
        [self->_idleTimer invalidate];
        self->_idleTimer = nil;

        if(self->_socket) {
            CLS_LOG(@"Discarding previous socket");
            WebSocket *s = self->_socket;
            self->_socket = nil;
            s.delegate = nil;
            [s close];
        }
        
        if(!_reachability || !_reachabilityValid) {
            if(self->_reachability)
                CFRelease(self->_reachability);
            self->_reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [IRCCLOUD_HOST cStringUsingEncoding:NSUTF8StringEncoding]);
            SCNetworkReachabilitySetCallback(self->_reachability, ReachabilityCallback, NULL);
            SCNetworkReachabilityScheduleWithRunLoop(self->_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        } else {
            kIRCCloudReachability reachability = [self reachable];
            if(self->_reachabilityValid && reachability != kIRCCloudReachable) {
                CLS_LOG(@"IRCCloud is unreachable");
                self->_reconnectTimestamp = -1;
                self->_state = kIRCCloudStateDisconnected;
                if(reachability == kIRCCloudUnreachable)
                    [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
                self->_ready = YES;
                return;
            }
        }
        
        if(self->_oobQueue.count) {
            CLS_LOG(@"Cancelling pending OOB requests");
            for(OOBFetcher *fetcher in _oobQueue) {
                [fetcher cancel];
            }
            [self->_oobQueue removeAllObjects];
            self->_streamId = nil;
            self->_highestEID = 0;
        }
        
        self->_notifier = notifier;
        self->_state = kIRCCloudStateConnecting;
        self->_idleInterval = 20;
        self->_accrued = 0;
        self->_currentCount = 0;
        self->_totalCount = 0;
        self->_reconnectTimestamp = -1;
        self->_resuming = NO;
        self->_ready = NO;
        self->_firstEID = 0;
        __socketPaused = NO;
        self->_lastReqId = 1;
        [self->_resultHandlers removeAllObjects];
        
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
        
        [self requestConfigurationWithHandler:^(IRCCloudJSONObject *result) {
            if(result) {
                NSString *url = [NSString stringWithFormat:@"wss://%@%@",[result objectForKey:@"socket_host"],IRCCLOUD_PATH];
                if(self->_highestEID > 0 && self->_streamId.length) {
                    url = [url stringByAppendingFormat:@"?since_id=%.0lf&stream_id=%@", self->_highestEID, self->_streamId];
                }
                if(notifier) {
                    if([url rangeOfString:@"?"].location == NSNotFound)
                        url = [url stringByAppendingFormat:@"?notifier=1"];
                    else
                        url = [url stringByAppendingFormat:@"&notifier=1"];
                }
                if([url rangeOfString:@"?"].location == NSNotFound)
                    url = [url stringByAppendingFormat:@"?exclude_archives=1"];
                else
                    url = [url stringByAppendingFormat:@"&exclude_archives=1"];

                SCNetworkReachabilityFlags flags;
                BOOL success = SCNetworkReachabilityGetFlags(self->_reachability, &flags);
                if(success && flags & kSCNetworkReachabilityFlagsIsWWAN) {
                    CTTelephonyNetworkInfo *telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
                    int limit = 50;
                    if([telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyGPRS] || [telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyEdge]) {
                        limit = 25;
                    } else if ([telephonyInfo.currentRadioAccessTechnology isEqualToString:CTRadioAccessTechnologyLTE]) {
                        limit = 100;
                    }
                    if([url rangeOfString:@"?"].location == NSNotFound)
                        url = [url stringByAppendingFormat:@"?limit=%i", limit];
                    else
                        url = [url stringByAppendingFormat:@"&limit=%i", limit];
                }
                
                CLS_LOG(@"Connecting: %@", url);
                self.httpMetric = [[FIRHTTPMetric alloc] initWithURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"wss://" withString:@"https://"]] HTTPMethod:FIRHTTPMethodGET];
                WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:url origin:[NSString stringWithFormat:@"https://%@", [result objectForKey:@"socket_host"]] protocols:nil
                                                                                 tlsSettings:[@{
                                                                                 (NSString *)kCFStreamSSLPeerName: [result objectForKey:@"socket_host"],
                                                                                 (NSString *)GCDAsyncSocketSSLProtocolVersionMin:@(kTLSProtocol1)
                                                                                                } mutableCopy]
                                                                                     headers:[@[[HandshakeHeader headerWithValue:_userAgent forKey:@"User-Agent"]] mutableCopy]
                                                                           verifySecurityKey:YES extensions:@[@"x-webkit-deflate-frame"]];
                self->_socket = [WebSocket webSocketWithConfig:config delegate:self];
                [self.httpMetric start];
                [self->_socket open];
            } else {
                CLS_LOG(@"Unable to load configuration");
                [self fail];
            }
        }];
    }
}

-(void)cancelPendingBacklogRequests {
    for(OOBFetcher *fetcher in _oobQueue.copy) {
        if(fetcher.bid > 0) {
            [fetcher cancel];
            [self->_oobQueue removeObject:fetcher];
        }
    }
}

-(void)disconnect {
    CLS_LOG(@"Closing websocket");
    if(self->_reachability) {
        CFRelease(self->_reachability);
        self->_reachability = nil;
        self->_reachabilityValid = NO;
    }
    if(self->_oobQueue.count) {
        for(OOBFetcher *fetcher in _oobQueue) {
            [fetcher cancel];
        }
        [self->_oobQueue removeAllObjects];
        self->_streamId = nil;
        self->_highestEID = 0;
    }
    self->_reconnectTimestamp = 0;
    [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
    self->_state = kIRCCloudStateDisconnected;
    [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    [self->_socket close];
    self->_socket = nil;
    for(Buffer *b in [self->_buffers getBuffers]) {
        if(!b.scrolledUp && [self->_events highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self->_events pruneEventsForBuffer:b.bid maxSize:50];
            });
        }
    }
}

-(void)clearPrefs {
    self->_prefs = nil;
    [__userInfoLock lock];
    self->_userInfo = nil;
    [__userInfoLock unlock];
}

-(void)webSocketDidOpen:(WebSocket *)socket {
    if(socket == self->_socket) {
        CLS_LOG(@"Socket connected");
        self->_idleInterval = 20;
        self->_reconnectTimestamp = -1;
        [self _sendRequest:@"auth" args:@{@"cookie":self.session} handler:nil];
        [self.httpMetric setResponseCode:200];
        [self.httpMetric stop];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self _postConnectivityChange];
        }];
    } else {
        CLS_LOG(@"Socket connected, but it wasn't the active socket");
    }
}

-(void)fail {
    if(self->_session) {
        [self clearOOB];
        self->_failCount++;
        if(self->_failCount < 4)
            self->_idleInterval = self->_failCount;
        else if(self->_failCount < 10)
            self->_idleInterval = 10;
        else
            self->_idleInterval = 30;
        self->_reconnectTimestamp = -1;
        CLS_LOG(@"Fail count: %i will reconnect in %f seconds", _failCount, _idleInterval);
        [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:YES];
    }
}

-(void)webSocket:(WebSocket *)socket didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError {
    if(socket == self->_socket) {
        CLS_LOG(@"Status Code: %lu", (unsigned long)aStatusCode);
        CLS_LOG(@"Close Message: %@", aMessage);
        CLS_LOG(@"Error: errorDesc=%@, failureReason=%@, code=%li, domain=%@", [aError localizedDescription], [aError localizedFailureReason], (long)aError.code, aError.domain);
        self->_state = kIRCCloudStateDisconnected;
        __socketPaused = NO;
        if(aStatusCode == WebSocketCloseStatusProtocolError) {
            self->_streamId = nil;
            self->_highestEID = 0;
        }
        if([aError.domain isEqualToString:@"kCFStreamErrorDomainNetDB"])
            _reconnectTimestamp = 0;
        if(_reconnectTimestamp != 0) {
            [self fail];
        } else {
            CLS_LOG(@"reconnecting is disabled");
            [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
            [self serialize];
        }
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    } else {
        CLS_LOG(@"Socket closed, but it wasn't the active socket");
    }
}

-(void)webSocket:(WebSocket *)socket didReceiveError: (NSError*) aError {
    if(socket == self->_socket) {
        CLS_LOG(@"Error: errorDesc=%@, failureReason=%@, code=%li, domain=%@", [aError localizedDescription], [aError localizedFailureReason], (long)aError.code, aError.domain);
        self->_state = kIRCCloudStateDisconnected;
        __socketPaused = NO;
        if([self reachable] && _reconnectTimestamp != 0) {
            [self fail];
        }
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    } else {
        CLS_LOG(@"Socket received error, but it wasn't the active socket");
    }
}

-(void)webSocket:(WebSocket *)socket didReceiveTextMessage:(NSString*)aMessage {
    if(socket == self->_socket) {
        if(aMessage) {
            while(__socketPaused) { //GCD uses a thread pool and can't guarantee NSLock will be locked and unlocked on the same thread, so here's an ugly hack instead
                [NSThread sleepForTimeInterval:0.05];
            }
            [self->_parser parse:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
        }
    } else {
        CLS_LOG(@"Got event for inactive socket");
    }
}

- (void)webSocket:(WebSocket *)socket didReceiveBinaryMessage: (NSData*) aMessage {
    if(socket == self->_socket) {
        if(aMessage) {
            while(__socketPaused) {
                [NSThread sleepForTimeInterval:0.05];
            }
            [self->_parser parse:aMessage];
        }
    } else {
        CLS_LOG(@"Got event for inactive socket");
    }
}

-(void)postObject:(id)object forEvent:(kIRCEvent)event {
    if(self->_accrued == 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:object userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:event]}];
        }];
    }
}

-(void)_postLoadingProgress:(NSNumber *)progress {
    static NSNumber *lastProgress = nil;
    if(!lastProgress || (int)(lastProgress.floatValue * 100) != (int)(progress.floatValue * 100))
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogProgressNotification object:progress];
    lastProgress = progress;
}

-(void)_postConnectivityChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:nil userInfo:nil];
}

-(NSDictionary *)prefs {
    @synchronized(self) {
        if(!_prefs && self.userInfo && [[self.userInfo objectForKey:@"prefs"] isKindOfClass:[NSString class]] && [[self.userInfo objectForKey:@"prefs"] length]) {
            NSError *error;
            self->_prefs = [NSJSONSerialization JSONObjectWithData:[[self.userInfo objectForKey:@"prefs"] dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:&error];
            if(error) {
                CLS_LOG(@"Prefs parse error: %@", error);
                CLS_LOG(@"JSON string: %@", [self.userInfo objectForKey:@"prefs"]);
            }
        }
        return _prefs;
    }
}

-(void)parse:(NSDictionary *)dict backlog:(BOOL)backlog {
    if(![dict isKindOfClass:[NSDictionary class]])
        return;
    @synchronized(self->_parserMap) {
        NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
        if(backlog)
            self->_totalCount++;
        if([NSThread currentThread].isMainThread)
            CLS_LOG(@"WARNING: Parsing on main thread");
        [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
        if(self->_accrued > 0) {
            [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@(((float)_totalCount++ / (float)_accrued)) waitUntilDone:NO];
        }
        IRCCloudJSONObject *object = [[IRCCloudJSONObject alloc] initWithDictionary:dict];
        if(object.type) {
            //NSLog(@"New event (backlog: %i resuming: %i highestEID: %f) (%@) %@", backlog, _resuming, _highestEID, object.type, object);
            if((backlog || _accrued > 0) && object.bid > -1 && object.bid != self->_currentBid && object.eid > 0) {
                if(!backlog) {
                    if(self->_firstEID == 0) {
                        self->_firstEID = object.eid;
                        if(object.eid > _highestEID) {
                            CLS_LOG(@"Backlog gap detected, purging cache");
                            [self->_events clear];
                            self->_highestEID = 0;
                            self->_streamId = nil;
                            self->_pendingEdits = [[NSMutableArray alloc] init];
                            [self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
                            self->_state = kIRCCloudStateDisconnected;
                            [self performSelectorOnMainThread:@selector(fail) withObject:nil waitUntilDone:NO];
                            return;
                        } else {
                            CLS_LOG(@"First EID matched");
                        }
                    }
                }
                self->_currentBid = object.bid;
                self->_currentCount = 0;
            }
            void (^block)(IRCCloudJSONObject *o, BOOL backlog) = [self->_parserMap objectForKey:object.type];
            if(block != nil) {
                block(object,backlog);
            } else {
                CLS_LOG(@"Unhandled type: %@", object.type);
            }
            if(backlog || _accrued > 0) {
                if(self->_numBuffers > 1 && (object.bid > -1 || [object.type isEqualToString:@"backlog_complete"]) && ![object.type isEqualToString:@"makebuffer"] && ![object.type isEqualToString:@"channel_init"]) {
                    if(object.bid != self->_currentBid) {
                        self->_currentBid = object.bid;
                        self->_currentCount = 0;
                    }
                    [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@(((float)_totalBuffers + (float)_currentCount/100.0f)/ (float)_numBuffers) waitUntilDone:NO];
                    self->_currentCount++;
                }
            }
            if(!backlog && [object objectForKey:@"reqid"]) {
                IRCCloudAPIResultHandler handler = [self->_resultHandlers objectForKey:@([[object objectForKey:@"reqid"] intValue])];
                if(handler) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        handler(object);
                    }];
                }
            }
            if([NSDate timeIntervalSinceReferenceDate] - start > _longestEventTime) {
                self->_longestEventTime = [NSDate timeIntervalSinceReferenceDate] - start;
                self->_longestEventType = object.type;
            }
        } else {
            if([object objectForKey:@"success"] && ![[object objectForKey:@"success"] boolValue] && [object objectForKey:@"message"]) {
                CLS_LOG(@"Failure: %@", object);
                if([[object objectForKey:@"message"] isEqualToString:@"invalid_nick"]) {
                    [self postObject:object forEvent:kIRCEventAlert];
                } else if([[object objectForKey:@"message"] isEqualToString:@"auth"]) {
                    [self postObject:object forEvent:kIRCEventAuthFailure];
                    if([[object objectForKey:@"_reqid"] intValue] == 0)
                        [self logout];
                } else if([[object objectForKey:@"message"] isEqualToString:@"set_shard"]) {
                    if([object objectForKey:@"websocket_path"])
                        IRCCLOUD_PATH = [object objectForKey:@"websocket_path"];
                    [self setSession:[object objectForKey:@"cookie"]];
                    [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef ENTERPRISE
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
                    [d setObject:IRCCLOUD_HOST forKey:@"host"];
                    [d setObject:IRCCLOUD_PATH forKey:@"path"];
                    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
                    [d synchronize];
                    [self connect:NO];
                } else if([self->_resultHandlers objectForKey:@([[object objectForKey:@"_reqid"] intValue])]) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        ((IRCCloudAPIResultHandler)[self->_resultHandlers objectForKey:@([[object objectForKey:@"_reqid"] intValue])])(object);
                    }];
                }
            } else if([object objectForKey:@"success"]) {
                if([self->_resultHandlers objectForKey:@([[object objectForKey:@"_reqid"] intValue])])
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        ((IRCCloudAPIResultHandler)[self->_resultHandlers objectForKey:@([[object objectForKey:@"_reqid"] intValue])])(object);
                    }];
            }
        }
        if(!backlog && _reconnectTimestamp != 0)
            [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:YES];
    }
}

-(void)cancelIdleTimer {
    if(![NSThread currentThread].isMainThread)
        CLS_LOG(@"WARNING: cancel idle timer called outside of main thread");
    
    [self->_idleTimer invalidate];
    self->_idleTimer = nil;
    self->_reconnectTimestamp = -1;
}

-(void)scheduleIdleTimer {
    if(![NSThread currentThread].isMainThread)
        CLS_LOG(@"WARNING: schedule idle timer called outside of main thread");
    [self->_idleTimer invalidate];
    self->_idleTimer = nil;
    if(self->_reconnectTimestamp == 0)
        return;
    
    if(self->_idleInterval > 0) {
        self->_idleTimer = [NSTimer scheduledTimerWithTimeInterval:self->_idleInterval target:self selector:@selector(_idle) userInfo:nil repeats:NO];
        self->_reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
    }
}

-(void)_idle {
    self->_reconnectTimestamp = 0;
    self->_idleTimer = nil;
    [self->_socket close];
    self->_state = kIRCCloudStateDisconnected;
#ifndef EXTENSION
    if([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        CLS_LOG(@"Websocket idle time exceeded, reconnecting...");
        [self connect:self->_notifier];
    } else {
        CLS_LOG(@"Websocket idle time exceeded in the background...");
    }
#endif
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid completion:(void (^)(BOOL))completionHandler {
    [self requestBacklogForBuffer:bid server:cid beforeId:-1 completion:completionHandler];
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid completion:(void (^)(BOOL))completionHandler {
    NSString *URL = nil;
    if(eid > 0)
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i&beforeid=%.0lf", IRCCLOUD_HOST, cid, bid, eid];
    else
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i", IRCCLOUD_HOST, cid, bid];
    OOBFetcher *fetcher = [self fetchOOB:URL];
    fetcher.bid = bid;
    fetcher.completionHandler = completionHandler;
}

-(void)requestArchives:(int)cid {
  OOBFetcher *fetcher = [self fetchOOB:[NSString stringWithFormat:@"https://%@/chat/archives?cid=%i", IRCCLOUD_HOST, cid]];
  fetcher.bid = -1;
}

-(OOBFetcher *)fetchOOB:(NSString *)url {
    @synchronized(self->_oobQueue) {
        NSArray *fetchers = self->_oobQueue.copy;
        for(OOBFetcher *fetcher in fetchers) {
            if([fetcher.url isEqualToString:url]) {
                CLS_LOG(@"Cancelling previous OOB request");
                [fetcher cancel];
                [self->_oobQueue removeObject:fetcher];
            }
        }
        OOBFetcher *fetcher = [[OOBFetcher alloc] initWithURL:url];
        [self->_oobQueue addObject:fetcher];
        if(self->_oobQueue.count == 1) {
            [self->_queue addOperationWithBlock:^{
                @autoreleasepool {
                    CLS_LOG(@"Starting OOB fetcher");
                    [fetcher start];
                }
            }];
        } else {
            CLS_LOG(@"OOB Request has been queued");
        }
        return fetcher;
    }
}

-(void)clearOOB {
    @synchronized(self->_oobQueue) {
        NSMutableArray *oldQueue = self->_oobQueue;
        self->_oobQueue = [[NSMutableArray alloc] init];
        for(OOBFetcher *fetcher in oldQueue) {
            [fetcher cancel];
        }
    }
}

-(void)_backlogStarted:(NSNotification *)notification {
    self->_OOBStartTime = [NSDate timeIntervalSinceReferenceDate];
    self->_longestEventTime = 0;
    self->_longestEventType = nil;
    if(self->_awayOverride.count)
        CLS_LOG(@"Caught %lu self_back events", (unsigned long)_awayOverride.count);
    self->_currentBid = -1;
    self->_currentCount = 0;
    self->_totalCount = 0;
}

-(void)_backlogCompleted:(NSNotification *)notification {
    if(self->_OOBStartTime) {
        NSTimeInterval total = [NSDate timeIntervalSinceReferenceDate] - _OOBStartTime;
        CLS_LOG(@"OOB processed %i events in %f seconds (%f seconds / event)", _totalCount, total, total / (double)_totalCount);
        CLS_LOG(@"Longest event: %@ (%f seconds)", _longestEventType, _longestEventTime);
        self->_OOBStartTime = 0;
        self->_longestEventTime = 0;
        self->_longestEventType = nil;
    }
    self->_failCount = 0;
    self->_accrued = 0;
    self->_resuming = NO;
    self->_awayOverride = nil;
    self->_reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
    [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
    OOBFetcher *fetcher = notification.object;
    CLS_LOG(@"Backlog finished for bid: %i", fetcher.bid);
    if(fetcher.bid > 0) {
        [self->_buffers getBuffer:fetcher.bid].deferred = 0;
        [self->_buffers updateTimeout:0 buffer:fetcher.bid];
    } else {
        self->_ready = YES;
        CLS_LOG(@"I now have %lu servers with %lu buffers", (unsigned long)[self->_servers count], (unsigned long)[self->_buffers count]);
        if(fetcher.bid == -1) {
            [self->_buffers purgeInvalidBIDs];
            [self->_channels purgeInvalidChannels];
            CLS_LOG(@"I now have %lu servers with %lu buffers", (unsigned long)[self->_servers count], (unsigned long)[self->_buffers count]);
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            for(Buffer *b in [self->_buffers getBuffers]) {
                if(!b.scrolledUp && [self->_events highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0) {
                        [self->_events pruneEventsForBuffer:b.bid maxSize:101];
                }
                [self->_notifications removeNotificationsForBID:b.bid olderThan:b.last_seen_eid];
            }
            [NetworkConnection sync];
        });
        self->_numBuffers = 0;
        __socketPaused = NO;
    }
    CLS_LOG(@"I downloaded %i events", _totalCount);
    [self->_oobQueue removeObject:fetcher];
    [self->_notifications updateBadgeCount];
    [self _processPendingEdits:NO];
    if([self->_servers count]) {
        [self performSelectorOnMainThread:@selector(_scheduleTimedoutBuffers) withObject:nil waitUntilDone:YES];
    }
    [self _serializeSoon];
}

-(void)_serializeUserInfo {
    [__serializeLock lock];
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"stream"];
    [__userInfoLock lock];
    NSMutableDictionary *stream = [self->_userInfo mutableCopy];
    if(self->_streamId)
        [stream setObject:self->_streamId forKey:@"streamId"];
    else
        [stream removeObjectForKey:@"streamId"];
    if(self->_config)
        [stream setObject:self->_config forKey:@"config"];
    else
        [stream removeObjectForKey:@"config"];
    [stream setObject:@(self->_highestEID) forKey:@"highestEID"];
    [NSKeyedArchiver archiveRootObject:stream toFile:cacheFile];
    [__userInfoLock unlock];
    [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
    [__serializeLock unlock];
}

-(void)_serializeSoon {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(self->_serializeTimer)
            [self->_serializeTimer invalidate];
        
        self->_serializeTimer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(serialize) userInfo:nil repeats:NO];
    }];
}

-(void)serialize {
    [__serializeLock lock];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self->_servers serialize];
    [self->_buffers serialize];
    [self->_channels serialize];
    [self->_users serialize];
    [self->_events serialize];
    [self->_notifications serialize];
#ifndef EXTENSION
    [__serializeLock unlock];
    [self _serializeUserInfo];
    [__serializeLock lock];
#endif
    [[NSUserDefaults standardUserDefaults] setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"cacheVersion"];
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] forKey:@"cacheVersion"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize"] forKey:@"fontSize"];
    [d synchronize];
    [NetworkConnection sync];
    [_serializeTimer invalidate];
    _serializeTimer = nil;
    [__serializeLock unlock];
}

-(void)_backlogFailed:(NSNotification *)notification {
    self->_accrued = 0;
    self->_awayOverride = nil;
    self->_reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
    [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
    [self->_oobQueue removeObject:notification.object];
    if([(OOBFetcher *)notification.object bid] > 0) {
        CLS_LOG(@"Backlog download failed, rescheduling timed out buffers");
        [self _scheduleTimedoutBuffers];
    } else {
        CLS_LOG(@"Initial backlog download failed");
        [self disconnect];
        __socketPaused = NO;
        self->_state = kIRCCloudStateDisconnected;
        self->_streamId = nil;
        self->_highestEID = 0;
        [self fail];
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    }
}

-(void)_scheduleTimedoutBuffers {
    [self->_queue addOperationWithBlock:^{
        for(Buffer *buffer in [self->_buffers getBuffers]) {
            if(buffer.timeout > 0) {
                if([buffer.type isEqualToString:@"channel"] && buffer.timeout == 0) {
                    if(![self->_channels channelForBuffer:buffer.bid])
                        continue;
                }
                CLS_LOG(@"Requesting backlog for buffer: %@", buffer.name);
                [self requestBacklogForBuffer:buffer.bid server:buffer.cid completion:nil];
            }
        }
        if(self->_oobQueue.count > 0) {
            [self->_queue addOperationWithBlock:^{
                if(self->_oobQueue.count > 0 && ((OOBFetcher *)[self->_oobQueue objectAtIndex:0]).bid > 0) {
                    CLS_LOG(@"Starting fetcher for timed-out bid%i", ((OOBFetcher *)[self->_oobQueue objectAtIndex:0]).bid);
                    [(OOBFetcher *)[self->_oobQueue objectAtIndex:0] start];
                }
            }];
        }
    }];
}

-(void)_logout:(NSString *)session {
#ifndef EXTENSION
    [[FIRInstanceID instanceID] instanceIDWithHandler:^(FIRInstanceIDResult * _Nullable result, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Error fetching remote instance ID: %@", error);
        } else if([[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"]) {
            NSLog(@"Remote instance ID token: %@", result.token);
            [self unregisterAPNs:[[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"] fcm:result.token session:session handler:^(IRCCloudJSONObject *result) {
                CLS_LOG(@"Unregister result: %@", result);
            }];
        }
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"APNs"];
        [[FIRInstanceID instanceID] deleteIDWithHandler:^(NSError *error) {
            if(error)
                CLS_LOG(@"Unable to delete Firebase ID: %@", error);
        }];
        IRCCLOUD_HOST = @"www.irccloud.com";
        [self _postRequest:@"/chat/logout" args:@{@"session":session} handler:nil];
    }];
#endif
}

-(void)logout {
    CLS_LOG(@"Logging out");
    self->_reconnectTimestamp = 0;
    self->_streamId = nil;
    [__userInfoLock lock];
    self->_userInfo = @{};
    [__userInfoLock unlock];
    self->_highestEID = 0;
    NSString *s = self.session;
    SecItemDelete((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, [NSBundle mainBundle].bundleIdentifier, kSecAttrService, nil]);
    self->_session = nil;
    [self disconnect];
    if(s)
        [self _logout:s];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"host"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"path"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"uploadsAvailable"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"logs_cache"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"last_uid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [UIColor setTheme:@"dawn"];
    [self clearPrefs];
    [self->_servers clear];
    [self->_buffers clear];
    [self->_users clear];
    [self->_channels clear];
    [self->_events clear];
    self->_pendingEdits = [[NSMutableArray alloc] init];
    [self serialize];
    [NetworkConnection sync];
#ifndef EXTENSION
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    NSURL *caches = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    for(NSURL *file in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:caches includingPropertiesForKeys:nil options:0 error:nil]) {
        [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
    }
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    for(NSURL *file in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:sharedcontainer includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil]) {
        if(![file.absoluteString hasSuffix:@"/"]) {
            CLS_LOG(@"Removing: %@", file);
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        }
    }
    [[ImageCache sharedInstance] purge];
    [FIRAnalytics resetAnalyticsData];
#endif
    [self cancelIdleTimer];
}

-(NSString *)session {
    if(self->_mock)
        return @"__mock_session__";
    
    if(self->_session) {
        self->_keychainFailCount = 0;
        return _session;
    }
    
    @synchronized (self) {
        CFDataRef data = nil;
#ifdef ENTERPRISE
        OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.enterprise", kSecAttrService, kCFBooleanTrue, kSecReturnData, nil], (CFTypeRef*)&data);
#else
        OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.IRCCloud", kSecAttrService, kCFBooleanTrue, kSecReturnData, nil], (CFTypeRef*)&data);
#endif
        if(!err) {
            self->_keychainFailCount = 0;
            self->_session = [[NSString alloc] initWithData:CFBridgingRelease(data) encoding:NSUTF8StringEncoding];
            if(self->_session.length <= 1) {
                CLS_LOG(@"Removing invalid session");
                [self setSession:nil];
            }
            return _session;
        } else {
            self->_keychainFailCount++;
            if(self->_keychainFailCount < 10 && err != errSecItemNotFound) {
                CLS_LOG(@"Error fetching session: %i, trying again", (int)err);
                return self.session;
            } else {
                if(err == errSecItemNotFound)
                    CLS_LOG(@"Session key not found");
                else
                    CLS_LOG(@"Error fetching session: %i", (int)err);
                self->_keychainFailCount = 0;
                return nil;
            }
        }
    }
}

-(void)setSession:(NSString *)session {
    @synchronized (self) {
#ifdef ENTERPRISE
        SecItemDelete((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.enterprise", kSecAttrService, nil]);
        if(session)
            SecItemAdd((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.enterprise", kSecAttrService, [session dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, (__bridge id)(kSecAttrAccessibleAlways), kSecAttrAccessible, nil], NULL);
#else
        SecItemDelete((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.IRCCloud", kSecAttrService, nil]);
        if(session)
            SecItemAdd((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.IRCCloud", kSecAttrService, [session dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, (__bridge id)(kSecAttrAccessibleAlways), kSecAttrAccessible, nil], NULL);
#endif
        self->_session = session;
    }
}

-(BOOL)notifier {
    return _notifier;
}

-(void)setNotifier:(BOOL)notifier {
    self->_notifier = notifier;
    if(self->_state == kIRCCloudStateConnected && !notifier) {
        CLS_LOG(@"Upgrading websocket");
        [self _sendRequest:@"upgrade_notifier" args:nil handler:nil];
    }
}

-(NSDictionary *)userInfo {
    [__userInfoLock lock];
    NSDictionary *d = self->_userInfo;
    [__userInfoLock unlock];
    return d;
}

-(void)setUserInfo:(NSDictionary *)userInfo {
  [__userInfoLock lock];
  self->_userInfo = userInfo;
  [__userInfoLock unlock];
}

-(void)setLastSelectedBID:(int)bid {
  [__userInfoLock lock];
  NSMutableDictionary *d = self->_userInfo.mutableCopy;
  [d setObject:@(bid) forKey:@"last_selected_bid"];
  self->_userInfo = d;
  [__userInfoLock unlock];
  
}

-(FIRHTTPMetric *)httpMetric {
    return self->_httpMetric;
}
-(void)setHttpMetric:(FIRHTTPMetric *)metric {
    self->_httpMetric = metric;
}
@end
