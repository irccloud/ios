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


#import "NetworkConnection.h"
#import "SBJson.h"
#import "HandshakeHeader.h"
#import "IRCCloudJSONObject.h"

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
NSString *IRCCLOUD_HOST = @"api.irccloud.com";
#endif
NSString *IRCCLOUD_PATH = @"/";

#define BACKLOG_BUFFER_MAX 99

#define TYPE_UNKNOWN 0
#define TYPE_WIFI 1
#define TYPE_WWAN 2

NSLock *__parserLock = nil;

@interface OOBFetcher : NSObject<NSURLConnectionDelegate> {
    SBJsonStreamParser *_parser;
    SBJsonStreamParserAdapter *_adapter;
    NSString *_url;
    BOOL _cancelled;
    BOOL _running;
    NSURLConnection *_connection;
    int _bid;
}
@property (readonly) NSString *url;
@property int bid;
-(id)initWithURL:(NSString *)URL;
-(void)cancel;
-(void)start;
@end

@implementation OOBFetcher

-(id)initWithURL:(NSString *)URL {
    self = [super init];
    _url = URL;
    _bid = -1;
    _adapter = [[SBJsonStreamParserAdapter alloc] init];
    _adapter.delegate = [NetworkConnection sharedInstance];
    _parser = [[SBJsonStreamParser alloc] init];
    _parser.delegate = _adapter;
    _cancelled = NO;
    _running = NO;
    return self;
}
-(void)cancel {
    _cancelled = YES;
    [_connection cancel];
}
-(void)start {
    if(_cancelled || _running)
        return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(_connection) {
        [__parserLock lock];
        _running = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:self];
        NSRunLoop *loop = [NSRunLoop currentRunLoop];
        while(!_cancelled && _running && [loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
        [__parserLock unlock];
    } else {
        CLS_LOG(@"Failed to create NSURLConnection");
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(_cancelled)
        return;
	CLS_LOG(@"Request failed: %@", error);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
    }];
    _running = NO;
    _cancelled = YES;
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(_cancelled)
        return;
	CLS_LOG(@"Backlog download completed");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:self];
    }];
    _running = NO;
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if(_cancelled)
        return nil;
	CLS_LOG(@"Fetching: %@", [request URL]);
	return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if([response statusCode] != 200) {
        CLS_LOG(@"HTTP status code: %li", (long)[response statusCode]);
		CLS_LOG(@"HTTP headers: %@", [response allHeaderFields]);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
        }];
        _cancelled = YES;
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //NSLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if(!_cancelled) {
        [_parser parse:data];
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
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
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
    __parserLock = [[NSLock alloc] init];
    _queue = [[NSOperationQueue alloc] init];
    _servers = [ServersDataSource sharedInstance];
    _buffers = [BuffersDataSource sharedInstance];
    _channels = [ChannelsDataSource sharedInstance];
    _users = [UsersDataSource sharedInstance];
    _events = [EventsDataSource sharedInstance];
    _state = kIRCCloudStateDisconnected;
    _oobQueue = [[NSMutableArray alloc] init];
    _awayOverride = nil;
    _adapter = [[SBJsonStreamParserAdapter alloc] init];
    _adapter.delegate = self;
    _parser = [[SBJsonStreamParser alloc] init];
    _parser.supportMultipleDocuments = YES;
    _parser.delegate = _adapter;
    _lastReqId = 1;
    _idleInterval = 20;
    _reconnectTimestamp = -1;
    _failCount = 0;
    _notifier = NO;
    _writer = [[SBJsonWriter alloc] init];
    _reachabilityValid = NO;
    _reachability = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogStarted:) name:kIRCCloudBacklogStartedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogFailed:) name:kIRCCloudBacklogFailedNotification object:nil];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    _userAgent = [NSString stringWithFormat:@"IRCCloud/%@ (%@; %@; %@ %@)", version, [UIDevice currentDevice].model, [[[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"] objectAtIndex:0], [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
    
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"stream"];
    _userInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile];
#ifndef EXTENSION
    if(_userInfo)
        _streamId = [_userInfo objectForKey:@"streamId"];
#endif
    
    CLS_LOG(@"%@", _userAgent);
    
    void (^ignored)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
    };
    
    void (^alert)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        if(!backlog)
            [self postObject:object forEvent:kIRCEventAlert];
    };
    
    void (^makeserver)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        Server *server = [_servers getServer:object.cid];
        if(!server) {
            server = [[Server alloc] init];
            [_servers addServer:server];
        }
        server.cid = object.cid;
        server.name = [object objectForKey:@"name"];
        server.hostname = [object objectForKey:@"hostname"];
        server.port = [[object objectForKey:@"port"] intValue];
        server.nick = [object objectForKey:@"nick"];
        server.status = [object objectForKey:@"status"];
        server.ssl = [[object objectForKey:@"ssl"] intValue];
        server.realname = [object objectForKey:@"realname"];
        server.server_pass = [object objectForKey:@"server_pass"];
        server.nickserv_pass = [object objectForKey:@"nickserv_pass"];
        server.join_commands = [object objectForKey:@"join_commands"];
        server.fail_info = [object objectForKey:@"fail_info"];
        server.away = (backlog && [_awayOverride objectForKey:@(object.cid)])?@"":[object objectForKey:@"away"];
        server.ignores = [object objectForKey:@"ignores"];
        if([[object objectForKey:@"order"] isKindOfClass:[NSNumber class]])
            server.order = [[object objectForKey:@"order"] intValue];
        else
            server.order = 0;
        if(!backlog)
            [self postObject:server forEvent:kIRCEventMakeServer];
    };
    
    void (^msg)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        Buffer *b = [_buffers getBuffer:object.bid];
        if(b) {
            Event *event = [_events addJSONObject:object];
            if(!backlog || _resuming) {
                if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7 && [event isImportant:b.type] && (event.isHighlight || [b.type isEqualToString:@"conversation"]))
                    [self updateBadgeCount];

                if(!backlog) {
                    [self postObject:event forEvent:kIRCEventBufferMsg];
                }
            }
        } else {
            CLS_LOG(@"Event recieved for invalid BID, reconnecting!");
            _streamId = nil;
            [self performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
            _state = kIRCCloudStateDisconnected;
            [self performSelectorOnMainThread:@selector(fail) withObject:nil waitUntilDone:NO];
        }
    };
    
    void (^joined_channel)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        [_events addJSONObject:object];
        if(!backlog || _resuming) {
            User *user = [_users getUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if(!user) {
                user = [[User alloc] init];
                user.cid = object.cid;
                user.bid = object.bid;
                user.nick = [object objectForKey:@"nick"];
                [_users addUser:user];
            }
            if(user.nick)
                user.old_nick = user.nick;
            user.hostmask = [object objectForKey:@"hostmask"];
            user.mode = @"";
            user.away = 0;
            user.away_msg = @"";
            if(!backlog)
                [self postObject:object forEvent:kIRCEventJoin];
        }
    };
    
    void (^parted_channel)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        [_events addJSONObject:object];
        if(!backlog || _resuming) {
            [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_parted_channel"]) {
                [_channels removeChannelForBuffer:object.bid];
                [_users removeUsersForBuffer:object.bid];
            }
            if(!backlog)
                [self postObject:object forEvent:kIRCEventPart];
        }
    };
    
    void (^kicked_channel)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        [_events addJSONObject:object];
        if(!backlog || _resuming) {
            [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_kicked_channel"]) {
                [_channels removeChannelForBuffer:object.bid];
                [_users removeUsersForBuffer:object.bid];
            }
            if(!backlog)
                [self postObject:object forEvent:kIRCEventKick];
        }
    };
    
    void (^nickchange)(IRCCloudJSONObject *object) = ^(IRCCloudJSONObject *object) {
        [_events addJSONObject:object];
        if(!backlog || _resuming) {
            [_users updateNick:[object objectForKey:@"newnick"] oldNick:[object objectForKey:@"oldnick"] cid:object.cid bid:object.bid];
            if([object.type isEqualToString:@"you_nickchange"])
                [_servers updateNick:[object objectForKey:@"newnick"] server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventNickChange];
        }
    };
    
    _parserMap = @{
                   @"idle":ignored, @"end_of_backlog":ignored, @"oob_skipped":ignored, @"num_invites":ignored, @"user_account":ignored,
                   @"header": ^(IRCCloudJSONObject *object) {
                       _idleInterval = ([[object objectForKey:@"idle_interval"] doubleValue] / 1000.0) + 10;
                       _clockOffset = [[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"time"] doubleValue];
                       _streamId = [object objectForKey:@"streamid"];
                       _accrued = [[object objectForKey:@"accrued"] intValue];
                       _currentCount = 0;
                       CLS_LOG(@"idle interval: %f clock offset: %f stream id: %@", _idleInterval, _clockOffset, _streamId);
                       if(_accrued > 0) {
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:nil];
                           }];
                       }
                       _resuming = [[object objectForKey:@"resumed"] boolValue];
                   },
                   @"global_system_message": ^(IRCCloudJSONObject *object) {
                       if([object objectForKey:@"system_message_type"] && ![[object objectForKey:@"system_message_type"] isEqualToString:@"eval"] && ![[object objectForKey:@"system_message_type"] isEqualToString:@"refresh"]) {
                           _globalMsg = [object objectForKey:@"msg"];
                           [self postObject:object forEvent:kIRCEventGlobalMsg];
                       }
                   },
                   @"oob_include": ^(IRCCloudJSONObject *object) {
                       _awayOverride = [[NSMutableDictionary alloc] init];
                       _reconnectTimestamp = 0;
                       CLS_LOG(@"oob_include, invalidating BIDs");
                       [_buffers invalidate];
                       [_channels invalidate];
                       [self fetchOOB:[NSString stringWithFormat:@"https://%@%@", IRCCLOUD_HOST, [object objectForKey:@"url"]]];
                   },
                   @"stat_user": ^(IRCCloudJSONObject *object) {
                       _userInfo = object.dictionary;
                       _prefs = nil;
#ifndef EXTENSION
                       if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
                           [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
#endif
                       [[Crashlytics sharedInstance] setUserIdentifier:[NSString stringWithFormat:@"uid%@",[_userInfo objectForKey:@"id"]]];
                       [self postObject:object forEvent:kIRCEventUserInfo];
                   },
                   @"backlog_starts": ^(IRCCloudJSONObject *object) {
                       if([object objectForKey:@"numbuffers"]) {
                           CLS_LOG(@"I currently have %lu servers with %lu buffers", (unsigned long)[_servers count], (unsigned long)[_buffers count]);
                           _numBuffers = [[object objectForKey:@"numbuffers"] intValue];
                           _totalBuffers = 0;
                           CLS_LOG(@"OOB includes has %i buffers", _numBuffers);
                       }
                       backlog = YES;
                       [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                           [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:nil];
                       }];
                   },
                   @"makeserver": makeserver,
                   @"server_details_changed": makeserver,
                   @"makebuffer": ^(IRCCloudJSONObject *object) {
                       Buffer *buffer = [_buffers getBuffer:object.bid];
                       if(!buffer) {
                           buffer = [[Buffer alloc] init];
                           buffer.bid = object.bid;
                           buffer.scrolledUpFrom = -1;
                           buffer.savedScrollOffset = -1;
                           [_buffers addBuffer:buffer];
                       }
                       buffer.bid = object.bid;
                       buffer.cid = object.cid;
                       buffer.min_eid = [[object objectForKey:@"min_eid"] doubleValue];
                       buffer.last_seen_eid = [[object objectForKey:@"last_seen_eid"] doubleValue];
                       buffer.name = [object objectForKey:@"name"];
                       buffer.type = [object objectForKey:@"buffer_type"];
                       buffer.archived = [[object objectForKey:@"archived"] intValue];
                       buffer.deferred = [[object objectForKey:@"deferred"] intValue];
                       buffer.timeout = [[object objectForKey:@"timeout"] intValue];
                       buffer.valid = YES;
                       if(!backlog)
                           [self postObject:buffer forEvent:kIRCEventMakeBuffer];
                       if(_numBuffers > 0) {
                           _totalBuffers++;
                           [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@((float)_totalBuffers / (float)_numBuffers) waitUntilDone:YES];
                       }
                   },
                   @"backlog_complete": ^(IRCCloudJSONObject *object) {
                       if(_oobQueue.count == 0) {
                           [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                               [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:nil];
                           }];
                       }
                   },
                   @"bad_channel_key": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventBadChannelKey];
                   },
                   @"too_many_channels": alert, @"no_such_channel": alert, @"bad_channel_name": alert,
                   @"no_such_nick": alert, @"invalid_nick_change": alert, @"chan_privs_needed": alert,
                   @"accept_exists": alert, @"banned_from_channel": alert, @"oper_only": alert,
                   @"no_nick_change": alert, @"no_messages_from_non_registered": alert, @"not_registered": alert,
                   @"already_registered": alert, @"too_many_targets": alert, @"no_such_server": alert,
                   @"unknown_command": alert, @"help_not_found": alert, @"accept_full": alert,
                   @"accept_not": alert, @"nick_collision": alert, @"nick_too_fast": alert,
                   @"save_nick": alert, @"unknown_mode": alert, @"user_not_in_channel": alert,
                   @"need_more_params": alert, @"users_dont_match": alert, @"users_disabled": alert,
                   @"invalid_operator_password": alert, @"flood_warning": alert, @"privs_needed": alert,
                   @"operator_fail": alert, @"not_on_channel": alert, @"ban_on_chan": alert,
                   @"cannot_send_to_chan": alert, @"user_on_channel": alert, @"no_nick_given": alert,
                   @"no_text_to_send": alert, @"no_origin": alert, @"only_servers_can_change_mode": alert,
                   @"silence": alert, @"no_channel_topic": alert, @"invite_only_chan": alert, @"channel_full": alert,
                   @"open_buffer": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventOpenBuffer];
                   },
                   @"invalid_nick": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventInvalidNick];
                   },
                   @"ban_list": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventBanList];
                   },
                   @"accept_list": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventAcceptList];
                   },
                   @"who_response": ^(IRCCloudJSONObject *object) {
                       if(!backlog) {
                           for(NSDictionary *user in [object objectForKey:@"users"]) {
                               [_users updateHostmask:[user objectForKey:@"usermask"] nick:[user objectForKey:@"nick"] cid:object.cid bid:object.bid];
                               [_users updateAway:[[user objectForKey:@"away"] intValue] nick:[user objectForKey:@"nick"] cid:object.cid bid:object.bid];
                           }
                           [self postObject:object forEvent:kIRCEventWhoList];
                       }
                   },
                   @"names_reply": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventNamesList];
                   },
                   @"whois_response": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventWhois];
                   },
                   @"list_response_fetching": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventListResponseFetching];
                   },
                   @"list_response_toomany": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventListResponseTooManyChannels];
                   },
                   @"list_response": ^(IRCCloudJSONObject *object) {
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventListResponse];
                   },
                   @"connection_deleted": ^(IRCCloudJSONObject *object) {
                       [_servers removeAllDataForServer:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventConnectionDeleted];
                   },
                   @"delete_buffer": ^(IRCCloudJSONObject *object) {
                       [_buffers removeAllDataForBuffer:object.bid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventDeleteBuffer];
                   },
                   @"buffer_archived": ^(IRCCloudJSONObject *object) {
                       [_buffers updateArchived:1 buffer:object.bid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventBufferArchived];
                   },
                   @"buffer_unarchived": ^(IRCCloudJSONObject *object) {
                       [_buffers updateArchived:0 buffer:object.bid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventBufferUnarchived];
                   },
                   @"rename_conversation": ^(IRCCloudJSONObject *object) {
                       [_buffers updateName:[object objectForKey:@"new_name"] buffer:object.bid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventRenameConversation];
                   },
                   @"status_changed": ^(IRCCloudJSONObject *object) {
                       [_servers updateStatus:[object objectForKey:@"new_status"] failInfo:[object objectForKey:@"fail_info"] server:object.cid];
                       if(!backlog) {
                           if([[object objectForKey:@"new_status"] isEqualToString:@"disconnected"]) {
                               NSArray *channels = [_channels channelsForServer:object.cid];
                               for(Channel *c in channels) {
                                   [_channels removeChannelForBuffer:c.bid];
                               }
                           }
                           [self postObject:object forEvent:kIRCEventStatusChanged];
                       }
                   },
                   @"buffer_msg": msg, @"buffer_me_msg": msg, @"wait": msg,
                   @"banned": msg, @"kill": msg, @"connecting_cancelled": msg,
                   @"target_callerid": msg, @"notice": msg, @"server_motdstart": msg,
                   @"server_welcome": msg, @"server_motd": msg, @"server_endofmotd": msg,
                   @"server_nomotd": msg, @"server_luserclient": msg, @"server_luserop": msg,
                   @"server_luserconns": msg, @"server_luserme": msg, @"server_n_local": msg,
                   @"server_luserchannels": msg, @"server_n_global": msg, @"server_yourhost": msg,
                   @"server_created": msg, @"server_luserunknown": msg, @"services_down": msg,
                   @"your_unique_id": msg, @"callerid": msg, @"target_notified": msg,
                   @"myinfo": msg, @"hidden_host_set": msg, @"unhandled_line": msg,
                   @"unparsed_line": msg, @"connecting_failed": msg, @"nickname_in_use": msg,
                   @"channel_invite": msg, @"motd_response": msg, @"socket_closed": msg,
                   @"channel_mode_list_change": msg, @"msg_services": msg,
                   @"stats": msg, @"statslinkinfo": msg, @"statscommands": msg, @"statscline": msg, @"statsnline": msg, @"statsiline": msg, @"statskline": msg, @"statsqline": msg, @"statsyline": msg, @"statsbline": msg, @"statsgline": msg, @"statstline": msg, @"statseline": msg, @"statsvline": msg, @"statslline": msg, @"statsuptime": msg, @"statsoline": msg, @"statshline": msg, @"statssline": msg, @"statsuline": msg, @"statsdebug": msg, @"endofstats": msg,
                   @"inviting_to_channel": msg, @"error": msg, @"too_fast": msg, @"no_bots": msg,
                   @"wallops": msg, @"logged_in_as": msg, @"sasl_fail": msg, @"sasl_too_long": msg,
                   @"sasl_aborted": msg, @"sasl_already": msg, @"you_are_operator": msg,
                   @"btn_metadata_set": msg, @"sasl_success": msg, @"cap_ls": msg,
                   @"cap_req": msg, @"cap_ack": msg,
                   @"help_topics_start": msg, @"help_topics": msg, @"help_topics_end": msg, @"helphdr": msg, @"helpop": msg, @"helptlr": msg, @"helphlp": msg, @"helpfwd": msg, @"helpign": msg, @"version": msg,
                   @"newsflash": msg, @"invited": msg, @"server_snomask": msg, @"codepage": msg, @"logged_out": msg, @"nick_locked": msg, @"info_response": msg, @"generic_server_info": msg, @"unknown_umode": msg, @"bad_ping": msg, @"cap_raw": msg, @"rehashed_config": msg, @"knock": msg, @"bad_channel_mask": msg, @"kill_deny": msg, @"chan_own_priv_needed": msg, @"not_for_halfops": msg, @"chan_forbidden": msg, @"starircd_welcome": msg, @"zurna_motd": msg, @"ambiguous_error_message": msg, @"list_usage": msg, @"list_syntax": msg, @"who_syntax": msg, @"text": msg, @"admin_info": msg, @"watch_status": msg, @"sqline_nick": msg,
                   @"time": ^(IRCCloudJSONObject *object) {
                       Event *event = [_events addJSONObject:object];
                       if(!backlog) {
                           [self postObject:object forEvent:kIRCEventAlert];
                           [self postObject:event forEvent:kIRCEventBufferMsg];
                       }
                   },
                   @"link_channel": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventLinkChannel];
                   },
                   @"channel_init": ^(IRCCloudJSONObject *object) {
                       Channel *channel = [_channels channelForBuffer:object.bid];
                       if(!channel) {
                           channel = [[Channel alloc] init];
                           [_channels addChannel:channel];
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
                       channel.valid = YES;
                       channel.key = NO;
                       [_channels updateMode:[object objectForKey:@"mode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                       [_users removeUsersForBuffer:object.bid];
                       for(NSDictionary *member in [object objectForKey:@"members"]) {
                           User *user = [[User alloc] init];
                           user.cid = object.cid;
                           user.bid = object.bid;
                           user.nick = [member objectForKey:@"nick"];
                           user.hostmask = [member objectForKey:@"usermask"];
                           user.mode = [member objectForKey:@"mode"];
                           user.away = [[member objectForKey:@"away"] intValue];
                           [_users addUser:user];
                       }
                       if(!backlog)
                           [self postObject:channel forEvent:kIRCEventChannelInit];
                   },
                   @"channel_topic": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_channels updateTopic:[object objectForKey:@"topic"] time:object.eid/1000000 author:[[object objectForKey:@"author"] length]?[object objectForKey:@"author"]:[object objectForKey:@"server"] buffer:object.bid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventChannelTopic];
                       }
                   },
                   @"channel_topic_is": ^(IRCCloudJSONObject *object) {
                       if(!backlog || _resuming) {
                           Buffer *b = [_buffers getBufferWithName:[object objectForKey:@"chan"] server:object.cid];
                           if(b) {
                               [_channels updateTopic:[object objectForKey:@"text"] time:[[object objectForKey:@"time"] longValue] author:[object objectForKey:@"author"] buffer:b.bid];
                           }
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventChannelTopicIs];
                       }
                   },
                   @"channel_url": ^(IRCCloudJSONObject *object) {
                       if(!backlog || _resuming)
                           [_channels updateURL:[object objectForKey:@"url"] buffer:object.bid];
                   },
                   @"channel_mode": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_channels updateMode:[object objectForKey:@"newmode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventChannelMode];
                       }
                   },
                   @"channel_mode_is": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_channels updateMode:[object objectForKey:@"newmode"] buffer:object.bid ops:[object objectForKey:@"ops"]];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventChannelMode];
                       }
                   },
                   @"channel_timestamp": ^(IRCCloudJSONObject *object) {
                       if(!backlog || _resuming) {
                           [_channels updateTimestamp:[[object objectForKey:@"timestamp"] doubleValue] buffer:object.bid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventChannelTimestamp];
                       }
                   },
                   @"joined_channel":joined_channel, @"you_joined_channel":joined_channel,
                   @"parted_channel":parted_channel, @"you_parted_channel":parted_channel,
                   @"kicked_channel":kicked_channel, @"you_kicked_channel":kicked_channel,
                   @"nickchange":nickchange, @"you_nickchange":nickchange,
                   @"quit": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventQuit];
                       }
                   },
                   @"quit_server": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventQuit];
                   },
                   @"user_channel_mode": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_users updateMode:[object objectForKey:@"newmode"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventUserChannelMode];
                       }
                   },
                   @"member_updates": ^(IRCCloudJSONObject *object) {
                       NSDictionary *updates = [object objectForKey:@"updates"];
                       NSEnumerator *keys = updates.keyEnumerator;
                       NSString *nick;
                       while((nick = (NSString *)(keys.nextObject))) {
                           NSDictionary *update = [updates objectForKey:nick];
                           [_users updateAway:[[update objectForKey:@"away"] intValue] nick:nick cid:object.cid bid:object.bid];
                           [_users updateHostmask:[update objectForKey:@"usermask"] nick:nick cid:object.cid bid:object.bid];
                       }
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventMemberUpdates];
                   },
                   @"user_away": ^(IRCCloudJSONObject *object) {
                       [_users updateAway:1 msg:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                       [_buffers updateAway:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventAway];
                   },
                   @"away": ^(IRCCloudJSONObject *object) {
                       [_users updateAway:1 msg:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                       [_buffers updateAway:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventAway];
                   },
                   @"user_back": ^(IRCCloudJSONObject *object) {
                       [_users updateAway:0 msg:@"" nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                       [_buffers updateAway:@"" nick:[object objectForKey:@"nick"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventAway];
                   },
                   @"self_away": ^(IRCCloudJSONObject *object) {
                       [_users updateAway:1 msg:[object objectForKey:@"away_msg"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                       [_servers updateAway:[object objectForKey:@"away_msg"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventAway];
                   },
                   @"self_back": ^(IRCCloudJSONObject *object) {
                       [_awayOverride setObject:@YES forKey:@(object.cid)];
                       [_users updateAway:0 msg:@"" nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                       [_servers updateAway:@"" server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventSelfBack];
                   },
                   @"self_details": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       [_servers updateUsermask:[object objectForKey:@"usermask"] server:object.bid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventSelfDetails];
                   },
                   @"user_mode": ^(IRCCloudJSONObject *object) {
                       [_events addJSONObject:object];
                       if(!backlog || _resuming) {
                           [_servers updateMode:[object objectForKey:@"newmode"] server:object.cid];
                           if(!backlog)
                               [self postObject:object forEvent:kIRCEventUserMode];
                       }
                   },
                   @"isupport_params": ^(IRCCloudJSONObject *object) {
                       [_servers updateUserModes:[object objectForKey:@"usermodes"] server:object.cid];
                       [_servers updateIsupport:[object objectForKey:@"params"] server:object.cid];
                   },
                   @"set_ignores": ^(IRCCloudJSONObject *object) {
                       [_servers updateIgnores:[object objectForKey:@"masks"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventSetIgnores];
                   },
                   @"ignore_list": ^(IRCCloudJSONObject *object) {
                       [_servers updateIgnores:[object objectForKey:@"masks"] server:object.cid];
                       if(!backlog)
                           [self postObject:object forEvent:kIRCEventSetIgnores];
                   },
                   @"heartbeat_echo": ^(IRCCloudJSONObject *object) {
                       NSDictionary *seenEids = [object objectForKey:@"seenEids"];
                       for(NSNumber *cid in seenEids.allKeys) {
                           NSDictionary *eids = [seenEids objectForKey:cid];
                           for(NSNumber *bid in eids.allKeys) {
                               NSTimeInterval eid = [[eids objectForKey:bid] doubleValue];
                               [_buffers updateLastSeenEID:eid buffer:[bid intValue]];
                           }
                       }
                       [self postObject:object forEvent:kIRCEventHeartbeatEcho];
                       [self updateBadgeCount];
                   },
                   @"reorder_connections": ^(IRCCloudJSONObject *object) {
                       NSArray *order = [object objectForKey:@"order"];
                       
                       for(int i = 0; i < order.count; i++) {
                           Server *s = [_servers getServer:[[order objectAtIndex:i] intValue]];
                           s.order = i + 1;
                       }
                       [self postObject:object forEvent:kIRCEventReorderConnections];
                   }
               };

    return self;
}

//Adapted from http://stackoverflow.com/a/17057553/1406639
-(kIRCCloudReachability)reachable {
    SCNetworkReachabilityFlags flags;
    if(_reachabilityValid && SCNetworkReachabilityGetFlags(_reachability, &flags)) {
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
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
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
        [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
        [NetworkConnection sharedInstance].reconnectTimestamp = -1;
        [[NetworkConnection sharedInstance] performSelectorInBackground:@selector(serialize) withObject:nil];
    }
    [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
}

-(void)_connect {
    [self connect:_notifier];
}

-(NSDictionary *)login:(NSString *)email password:(NSString *)password token:(NSString *)token {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    
    CFStringRef email_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)email, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    CFStringRef password_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)password, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/login", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:token forHTTPHeaderField:@"x-auth-formtoken"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"email=%@&password=%@&token=%@", email_escaped, password_escaped, token] dataUsingEncoding:NSUTF8StringEncoding]];
    
    CFRelease(email_escaped);
    CFRelease(password_escaped);
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(NSDictionary *)login:(NSURL *)accessLink {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:accessLink cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(NSDictionary *)signup:(NSString *)email password:(NSString *)password realname:(NSString *)realname token:(NSString *)token {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    
    CFStringRef realname_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)realname, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    CFStringRef email_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)email, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    CFStringRef password_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)password, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/signup", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:token forHTTPHeaderField:@"x-auth-formtoken"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"realname=%@&email=%@&password=%@&token=%@", realname_escaped, email_escaped, password_escaped, token] dataUsingEncoding:NSUTF8StringEncoding]];
    
    CFRelease(realname_escaped);
    CFRelease(email_escaped);
    CFRelease(password_escaped);
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(NSDictionary *)requestPassword:(NSString *)email token:(NSString *)token {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    
    CFStringRef email_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)email, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/request-access-link", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:token forHTTPHeaderField:@"x-auth-formtoken"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"email=%@&token=%@&mobile=1", email_escaped, token] dataUsingEncoding:NSUTF8StringEncoding]];
    
    CFRelease(email_escaped);
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
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

-(NSDictionary *)registerAPNs:(NSData *)token {
#if defined(DEBUG) || defined(EXTENSION)
    return nil;
#else
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    NSString *body = [NSString stringWithFormat:@"device_id=%@&session=%@", [self dataToHex:token], self.session];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/apn-register", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@",self.session] forHTTPHeaderField:@"Cookie"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    return [[[SBJsonParser alloc] init] objectWithData:data];
#endif
}

-(NSDictionary *)unregisterAPNs:(NSData *)token session:(NSString *)session {
#if defined(DEBUG) || defined(EXTENSION)
    return nil;
#else
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    NSString *body = [NSString stringWithFormat:@"device_id=%@&session=%@", [self dataToHex:token], session];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/apn-unregister", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@",self.session] forHTTPHeaderField:@"Cookie"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    return [[[SBJsonParser alloc] init] objectWithData:data];
#endif
}

-(NSDictionary *)requestAuthToken {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/auth-formtoken", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"POST"];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(NSDictionary *)requestConfiguration {
    NSData *data;
    NSURLResponse *response = nil;
    NSError *error = nil;
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/config", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(int)_sendRequest:(NSString *)method args:(NSDictionary *)args {
    @synchronized(_writer) {
        if([self reachable] && _state == kIRCCloudStateConnected) {
            NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:args];
            [dict setObject:method forKey:@"_method"];
            [dict setObject:@(++_lastReqId) forKey:@"_reqid"];
            [_socket sendText:[_writer stringWithObject:dict]];
            return _lastReqId;
        } else {
            CLS_LOG(@"Discarding request '%@' on disconnected socket", method);
            return -1;
        }
    }
}

-(int)say:(NSString *)message to:(NSString *)to cid:(int)cid {
    if(to)
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message, @"to":to}];
    else
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message}];
}

-(int)heartbeat:(int)selectedBuffer cids:(NSArray *)cids bids:(NSArray *)bids lastSeenEids:(NSArray *)lastSeenEids {
    @synchronized(_writer) {
        NSMutableDictionary *heartbeat = [[NSMutableDictionary alloc] init];
        for(int i = 0; i < cids.count; i++) {
            NSMutableDictionary *d = [heartbeat objectForKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            if(!d) {
                d = [[NSMutableDictionary alloc] init];
                [heartbeat setObject:d forKey:[NSString stringWithFormat:@"%@",[cids objectAtIndex:i]]];
            }
            [d setObject:[lastSeenEids objectAtIndex:i] forKey:[NSString stringWithFormat:@"%@",[bids objectAtIndex:i]]];
        }
        NSString *seenEids = [_writer stringWithObject:heartbeat];
        NSMutableDictionary *d = _userInfo.mutableCopy;
        [d setObject:@(selectedBuffer) forKey:@"last_selected_bid"];
        _userInfo = d;
        return [self _sendRequest:@"heartbeat" args:@{@"selectedBuffer":@(selectedBuffer), @"seenEids":seenEids}];
    }
}
-(int)heartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid {
    return [self heartbeat:selectedBuffer cids:@[@(cid)] bids:@[@(bid)] lastSeenEids:@[@(lastSeenEid)]];
}

-(int)join:(NSString *)channel key:(NSString *)key cid:(int)cid {
    if(key.length) {
        return [self _sendRequest:@"join" args:@{@"cid":@(cid), @"channel":channel, @"key":key}];
    } else {
        return [self _sendRequest:@"join" args:@{@"cid":@(cid), @"channel":channel}];
    }
}
-(int)part:(NSString *)channel msg:(NSString *)msg cid:(int)cid {
    if(msg.length) {
        return [self _sendRequest:@"part" args:@{@"cid":@(cid), @"channel":channel, @"msg":msg}];
    } else {
        return [self _sendRequest:@"part" args:@{@"cid":@(cid), @"channel":channel}];
    }
}

-(int)kick:(NSString *)nick chan:(NSString *)chan msg:(NSString *)msg cid:(int)cid {
    return [self say:[NSString stringWithFormat:@"/kick %@ %@",nick,(msg.length)?msg:@""] to:chan cid:cid];
}

-(int)mode:(NSString *)mode chan:(NSString *)chan cid:(int)cid {
    return [self say:[NSString stringWithFormat:@"/mode %@ %@",chan,mode] to:chan cid:cid];
}

-(int)invite:(NSString *)nick chan:(NSString *)chan cid:(int)cid {
    return [self say:[NSString stringWithFormat:@"/invite %@ %@",nick,chan] to:chan cid:cid];
}

-(int)archiveBuffer:(int)bid cid:(int)cid {
    return [self _sendRequest:@"archive-buffer" args:@{@"cid":@(cid),@"id":@(bid)}];
}

-(int)unarchiveBuffer:(int)bid cid:(int)cid {
    return [self _sendRequest:@"unarchive-buffer" args:@{@"cid":@(cid),@"id":@(bid)}];
}

-(int)deleteBuffer:(int)bid cid:(int)cid {
    return [self _sendRequest:@"delete-buffer" args:@{@"cid":@(cid),@"id":@(bid)}];
}

-(int)deleteServer:(int)cid {
    return [self _sendRequest:@"delete-connection" args:@{@"cid":@(cid)}];
}

-(int)addServer:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands channels:(NSString *)channels {
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
                                                   @"channels":channels?channels:@""}];
}

-(int)editServer:(int)cid hostname:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands {
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
                                                    @"cid":@(cid)}];
}

-(int)ignore:(NSString *)mask cid:(int)cid {
    return [self _sendRequest:@"ignore" args:@{@"cid":@(cid),@"mask":mask}];
}

-(int)unignore:(NSString *)mask cid:(int)cid {
    return [self _sendRequest:@"unignore" args:@{@"cid":@(cid),@"mask":mask}];
}

-(int)setPrefs:(NSString *)prefs {
    _prefs = nil;
    return [self _sendRequest:@"set-prefs" args:@{@"prefs":prefs}];
}

-(int)setEmail:(NSString *)email realname:(NSString *)realname highlights:(NSString *)highlights autoaway:(BOOL)autoaway {
    return [self _sendRequest:@"user-settings" args:@{
                                                      @"email":email,
                                                      @"realname":realname,
                                                      @"hwords":highlights,
                                                      @"autoaway":autoaway?@"1":@"0"}];
}

-(int)ns_help_register:(int)cid {
    return [self _sendRequest:@"ns-help-register" args:@{@"cid":@(cid)}];
}

-(int)setNickservPass:(NSString *)nspass cid:(int)cid {
    return [self _sendRequest:@"set-nspass" args:@{@"cid":@(cid),@"nspass":nspass}];
}

-(int)whois:(NSString *)nick server:(NSString *)server cid:(int)cid {
    if(server.length) {
        return [self _sendRequest:@"whois" args:@{@"cid":@(cid), @"nick":nick, @"server":server}];
    } else {
        return [self _sendRequest:@"whois" args:@{@"cid":@(cid), @"nick":nick}];
    }
}

-(int)topic:(NSString *)topic chan:(NSString *)chan cid:(int)cid {
    return [self _sendRequest:@"topic" args:@{@"cid":@(cid),@"channel":chan,@"topic":topic}];
}

-(int)back:(int)cid {
    return [self _sendRequest:@"back" args:@{@"cid":@(cid)}];
}

-(int)disconnect:(int)cid msg:(NSString *)msg {
    if(msg.length)
        return [self _sendRequest:@"disconnect" args:@{@"cid":@(cid), @"msg":msg}];
    else
        return [self _sendRequest:@"disconnect" args:@{@"cid":@(cid)}];
}

-(int)reconnect:(int)cid {
    return [self _sendRequest:@"reconnect" args:@{@"cid":@(cid)}];
}

-(int)reorderConnections:(NSString *)cids {
    return [self _sendRequest:@"reorder-connections" args:@{@"cids":cids}];
}

-(void)connect:(BOOL)notifier {
    @synchronized(self) {
        if(IRCCLOUD_HOST.length < 1) {
            CLS_LOG(@"Not connecting, no host");
            return;
        }
        
        if(self.session.length < 1) {
            CLS_LOG(@"Not connecting, no session");
            return;
        }
        
        if(_state == kIRCCloudStateConnecting) {
            CLS_LOG(@"Ignoring duplicate connection request");
            return;
        }
        
        if(_socket) {
            CLS_LOG(@"Discarding previous socket");
            WebSocket *s = _socket;
            _socket = nil;
            s.delegate = nil;
            [s close];
        }
        
        if(!_reachability) {
            _reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [IRCCLOUD_HOST cStringUsingEncoding:NSUTF8StringEncoding]);
            SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
            SCNetworkReachabilitySetCallback(_reachability, ReachabilityCallback, NULL);
        } else {
            kIRCCloudReachability reachability = [self reachable];
            if(reachability != kIRCCloudReachable) {
                CLS_LOG(@"IRCCloud is unreachable");
                _reconnectTimestamp = -1;
                _state = kIRCCloudStateDisconnected;
                if(reachability == kIRCCloudUnreachable)
                    [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
                return;
            }
        }
        
        if(_oobQueue.count) {
            NSLog(@"Cancelling pending OOB requests");
            for(OOBFetcher *fetcher in _oobQueue) {
                [fetcher cancel];
            }
            [_oobQueue removeAllObjects];
        }
        
        NSString *url = [NSString stringWithFormat:@"wss://%@%@",IRCCLOUD_HOST,IRCCLOUD_PATH];
        if(_events.highestEid > 0) {
            url = [url stringByAppendingFormat:@"?since_id=%.0lf", _events.highestEid];
            if(_streamId)
                url = [url stringByAppendingFormat:@"&stream_id=%@", _streamId];
        }
        if(notifier) {
            if([url rangeOfString:@"?"].location == NSNotFound)
                url = [url stringByAppendingFormat:@"?notifier=1"];
            else
                url = [url stringByAppendingFormat:@"&notifier=1"];
        }
        CLS_LOG(@"Connecting: %@", url);
        _notifier = notifier;
        _state = kIRCCloudStateConnecting;
        _idleInterval = 20;
        _accrued = 0;
        _currentCount = 0;
        _totalCount = 0;
        _reconnectTimestamp = -1;
        _resuming = NO;
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
        WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:url origin:[NSString stringWithFormat:@"https://%@", IRCCLOUD_HOST] protocols:nil
                                                                         tlsSettings:[@{(NSString *)kCFStreamSSLPeerName: IRCCLOUD_HOST,
                                                                                        (NSString *)kCFStreamSSLLevel: (NSString *)kCFStreamSocketSecurityLevelSSLv3,
#ifndef ENTERPRISE
                                                                                        @"fingerprint":@"8D:3B:E1:98:3F:75:F4:A4:54:6F:42:F5:EC:18:9B:C6:5A:9D:3A:42"
#endif
                                                                                        } mutableCopy]
                                                                             headers:[@[[HandshakeHeader headerWithValue:_userAgent forKey:@"User-Agent"],
                                                                                        [HandshakeHeader headerWithValue:[NSString stringWithFormat:@"session=%@",self.session] forKey:@"Cookie"]] mutableCopy]
                                                                   verifySecurityKey:YES extensions:@[@"x-webkit-deflate-frame"]];
        _socket = [WebSocket webSocketWithConfig:config delegate:self];
        
        [_socket open];
    }
}

-(void)disconnect {
    CLS_LOG(@"Closing websocket");
    for(OOBFetcher *fetcher in _oobQueue) {
        [fetcher cancel];
    }
    [_oobQueue removeAllObjects];
    _reconnectTimestamp = 0;
    [self cancelIdleTimer];
    _state = kIRCCloudStateDisconnected;
    [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    [_socket close];
    _socket = nil;
    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
        if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
            [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
    }
}

-(void)clearPrefs {
    _prefs = nil;
    _userInfo = nil;
}

-(void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    //This is wasteful, we don't use it
}

-(void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
    [self parse:dict];
}

-(void)parser:(SBJsonStreamParser *)parser foundObjectInArray:(NSDictionary *)dict {
    [self parse:dict];
}

-(void)webSocketDidOpen:(WebSocket *)socket {
    if(socket == _socket) {
        CLS_LOG(@"Socket connected");
        _idleInterval = 20;
        _reconnectTimestamp = 0;
        _state = kIRCCloudStateConnected;
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    }
}

-(void)fail {
    _failCount++;
    if(_failCount < 4)
        _idleInterval = _failCount;
    else if(_failCount < 10)
        _idleInterval = 10;
    else
        _idleInterval = 30;
    _reconnectTimestamp = -1;
    [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:YES];
}

-(void)webSocket:(WebSocket *)socket didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError {
    if(socket == _socket) {
        CLS_LOG(@"Status Code: %lu", (unsigned long)aStatusCode);
        CLS_LOG(@"Close Message: %@", aMessage);
        CLS_LOG(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
        _state = kIRCCloudStateDisconnected;
        if([self reachable] == kIRCCloudReachable && _reconnectTimestamp != 0) {
            [self fail];
        } else {
            [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
            [self serialize];
        }
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
        if([aError.domain isEqualToString:@"kCFStreamErrorDomainSSL"] || aStatusCode == WebSocketCloseStatusTlsHandshakeError) {
            IRCCloudJSONObject *o = [[IRCCloudJSONObject alloc] initWithDictionary:@{@"success":@0,@"message":@"Unable to establish a secure connection"}];
            [self postObject:o forEvent:kIRCEventFailureMsg];
        } else if([aError localizedDescription]) {
            IRCCloudJSONObject *o = [[IRCCloudJSONObject alloc] initWithDictionary:@{@"success":@0,@"message":@"Unable to connect to IRCCloud"}];
            [self postObject:o forEvent:kIRCEventFailureMsg];
        }
    }
}

-(void)webSocket:(WebSocket *)socket didReceiveError: (NSError*) aError {
    if(socket == _socket) {
        CLS_LOG(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
        _state = kIRCCloudStateDisconnected;
        if([self reachable] && _reconnectTimestamp != 0) {
            [self fail];
        }
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    }
}

-(void)webSocket:(WebSocket *)socket didReceiveTextMessage:(NSString*)aMessage {
    if(socket == _socket) {
        if(aMessage) {
            [__parserLock lock];
            [_parser parse:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [__parserLock unlock];
        }
    }
}

- (void)webSocket:(WebSocket *)socket didReceiveBinaryMessage: (NSData*) aMessage {
    if(socket == _socket) {
        if(aMessage) {
            [__parserLock lock];
            [_parser parse:aMessage];
            [__parserLock unlock];
        }
    }
}

-(void)postObject:(id)object forEvent:(kIRCEvent)event {
    if(_accrued == 0) {
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
    if(!_prefs && _userInfo && [[_userInfo objectForKey:@"prefs"] isKindOfClass:[NSString class]] && [[_userInfo objectForKey:@"prefs"] length]) {
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        _prefs = [parser objectWithString:[_userInfo objectForKey:@"prefs"]];
    }
    return _prefs;
}

-(void)parse:(NSDictionary *)dict {
    if(backlog)
        _totalCount++;
    if([NSThread currentThread].isMainThread)
        NSLog(@"WARNING: Parsing on main thread");
    [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
    if(_accrued > 0) {
        [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@(((float)_currentCount++ / (float)_accrued)) waitUntilDone:NO];
    }
    IRCCloudJSONObject *object = [[IRCCloudJSONObject alloc] initWithDictionary:dict];
    if(object.type) {
        //NSLog(@"New event (backlog: %i) (%@) %@", backlog, object.type, object);
        void (^block)(IRCCloudJSONObject *o) = [_parserMap objectForKey:object.type];
        if(block != nil) {
            block(object);
        } else {
            CLS_LOG(@"Unhandled type: %@", object.type);
        }
        if(backlog) {
            if(_numBuffers > 1 && (object.bid > -1 || [object.type isEqualToString:@"backlog_complete"]) && ![object.type isEqualToString:@"makebuffer"] && ![object.type isEqualToString:@"channel_init"]) {
                if(object.bid != _currentBid) {
                    if(_currentBid != -1 && _currentCount >= BACKLOG_BUFFER_MAX) {
                        [_events removeEventsBefore:_firstEID buffer:_currentBid];
                    }
                    _currentBid = object.bid;
                    _currentCount = 0;
                    _firstEID = object.eid;
                }
                [self performSelectorOnMainThread:@selector(_postLoadingProgress:) withObject:@(((float)_totalBuffers + (float)_currentCount/100.0f)/ (float)_numBuffers) waitUntilDone:NO];
                _currentCount++;
            }
        }
    } else {
        if([object objectForKey:@"success"] && ![[object objectForKey:@"success"] boolValue] && [object objectForKey:@"message"]) {
            [self postObject:object forEvent:kIRCEventFailureMsg];
        } else if([object objectForKey:@"success"]) {
            [self postObject:object forEvent:kIRCEventSuccess];
        }
    }
    if(!backlog && _reconnectTimestamp != 0)
        [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:YES];
}

-(void)cancelIdleTimer {
    if(![NSThread currentThread].isMainThread)
        CLS_LOG(@"WARNING: cancel idle timer called outside of main thread");
    
    [_idleTimer invalidate];
    _idleTimer = nil;
}

-(void)scheduleIdleTimer {
    if(![NSThread currentThread].isMainThread)
        CLS_LOG(@"WARNING: schedule idle timer called outside of main thread");
    [_idleTimer invalidate];
    _idleTimer = nil;
    if(_reconnectTimestamp == 0)
        return;
    
    _idleTimer = [NSTimer scheduledTimerWithTimeInterval:_idleInterval target:self selector:@selector(_idle) userInfo:nil repeats:NO];
    _reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
}

-(void)_idle {
    _reconnectTimestamp = 0;
    _idleTimer = nil;
    [_socket close];
    CLS_LOG(@"Websocket idle time exceeded, reconnecting...");
    [self connect:_notifier];
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid {
    [self requestBacklogForBuffer:bid server:cid beforeId:-1];
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid {
    NSString *URL = nil;
    if(eid > 0)
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i&beforeid=%.0lf", IRCCLOUD_HOST, cid, bid, eid];
    else
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i", IRCCLOUD_HOST, cid, bid];
    OOBFetcher *fetcher = [self fetchOOB:URL];
    fetcher.bid = bid;
}


-(OOBFetcher *)fetchOOB:(NSString *)url {
    for(OOBFetcher *fetcher in _oobQueue) {
        if([fetcher.url isEqualToString:url]) {
            CLS_LOG(@"Ignoring duplicate OOB request");
            return fetcher;
        }
    }
    OOBFetcher *fetcher = [[OOBFetcher alloc] initWithURL:url];
    [_oobQueue addObject:fetcher];
    if(_oobQueue.count == 1) {
        [_queue addOperationWithBlock:^{
            [fetcher start];
        }];
    } else {
        CLS_LOG(@"OOB Request has been queued");
    }
    return fetcher;
}

-(void)clearOOB {
    NSMutableArray *oldQueue = _oobQueue;
    _oobQueue = [[NSMutableArray alloc] init];
    for(OOBFetcher *fetcher in oldQueue) {
        [fetcher cancel];
    }
}

-(void)_backlogStarted:(NSNotification *)notification {
    if(_awayOverride.count)
        NSLog(@"Caught %lu self_back events", (unsigned long)_awayOverride.count);
    _currentBid = -1;
    _currentCount = 0;
    _firstEID = 0;
    _totalCount = 0;
    backlog = YES;
}

-(void)_backlogCompleted:(NSNotification *)notification {
    _failCount = 0;
    _accrued = 0;
    backlog = NO;
    _resuming = NO;
    _awayOverride = nil;
    _reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
    [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
    OOBFetcher *fetcher = notification.object;
    CLS_LOG(@"Backlog finished for bid: %i", fetcher.bid);
    if(fetcher.bid > 0) {
        [_buffers updateTimeout:0 buffer:fetcher.bid];
    } else {
        CLS_LOG(@"I now have %lu servers with %lu buffers", (unsigned long)[_servers count], (unsigned long)[_buffers count]);
        if(fetcher.bid == -1) {
            [_buffers purgeInvalidBIDs];
            [_channels purgeInvalidChannels];
            CLS_LOG(@"I now have %lu servers with %lu buffers", (unsigned long)[_servers count], (unsigned long)[_buffers count]);
        }
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
        }
        _numBuffers = 0;
    }
    CLS_LOG(@"I downloaded %i events", _totalCount);
    [_oobQueue removeObject:fetcher];
    if([_servers count]) {
        [self performSelectorOnMainThread:@selector(_scheduleTimedoutBuffers) withObject:nil waitUntilDone:YES];
    }
    [self performSelectorInBackground:@selector(serialize) withObject:nil];
}

-(void)updateBadgeCount {
#ifndef EXTENSION
#if 0
    int count = 0;
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            count += [[EventsDataSource sharedInstance] highlightCountForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
        }
        if(count) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = count;
        } else {
#endif
            [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
#if 0
        }
    }
#endif
#endif
}

-(void)serialize {
    @synchronized(self) {
        NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"stream"];
        NSMutableDictionary *stream = [_userInfo mutableCopy];
        if(_streamId)
            [stream setObject:_streamId forKey:@"streamId"];
        else
            [stream removeObjectForKey:@"streamId"];
        [NSKeyedArchiver archiveRootObject:stream toFile:cacheFile];
        [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        [_servers serialize];
        [_buffers serialize];
        [_channels serialize];
        [_users serialize];
        [_events serialize];
        [NetworkConnection sync];
    }
}

-(void)_backlogFailed:(NSNotification *)notification {
    _accrued = 0;
    backlog = NO;
    _awayOverride = nil;
    _reconnectTimestamp = [[NSDate date] timeIntervalSince1970] + _idleInterval;
    [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
    [_oobQueue removeObject:notification.object];
    if([(OOBFetcher *)notification.userInfo bid] > 0) {
        CLS_LOG(@"Backlog download failed, rescheduling timed out buffers");
        [self _scheduleTimedoutBuffers];
    } else {
        CLS_LOG(@"Initial backlog download failed");
        [self disconnect];
        _state = kIRCCloudStateDisconnected;
        _streamId = nil;
        [self fail];
        [self performSelectorOnMainThread:@selector(_postConnectivityChange) withObject:nil waitUntilDone:YES];
    }
}

-(void)_scheduleTimedoutBuffers {
    for(Buffer *buffer in [_buffers getBuffers]) {
        if(buffer.timeout > 0) {
            CLS_LOG(@"Requesting backlog for timed-out buffer: %@", buffer.name);
            [self requestBacklogForBuffer:buffer.bid server:buffer.cid];
        }
    }
    if(_oobQueue.count > 0) {
        [_queue addOperationWithBlock:^{
            [(OOBFetcher *)[_oobQueue objectAtIndex:0] start];
        }];
    }
}

-(void)_logout:(NSString *)session {
    NSLog(@"Unregister result: %@", [self unregisterAPNs:[[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"] session:session]);
    //TODO: check the above result, and retry if it fails
	NSURLResponse *response = nil;
	NSError *error = nil;
    NSString *body = [NSString stringWithFormat:@"session=%@", self.session];
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/logout", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@", session] forHTTPHeaderField:@"Cookie"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
}

-(void)logout {
    CLS_LOG(@"Logging out");
    [self performSelectorInBackground:@selector(_logout:) withObject:self.session];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"APNs"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"host"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"path"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self disconnect];
    [self cancelIdleTimer];
    _reconnectTimestamp = 0;
    _streamId = nil;
    _userInfo = @{};
    [self clearPrefs];
    [_servers clear];
    [_buffers clear];
    [_users clear];
    [_channels clear];
    [_events clear];
    SecItemDelete((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, [NSBundle mainBundle].bundleIdentifier, kSecAttrService, nil]);
    [self serialize];
    [NetworkConnection sync];
#ifndef EXTENSION
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
#endif
}

-(NSString *)session {
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"session"]) {
        self.session = [[NSUserDefaults standardUserDefaults] stringForKey:@"session"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"session"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    CFDataRef data = nil;
#ifdef ENTERPRISE
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.enterprise", kSecAttrService, kCFBooleanTrue, kSecReturnData, nil], (CFTypeRef*)&data);
#else
    OSStatus err = SecItemCopyMatching((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.IRCCloud", kSecAttrService, kCFBooleanTrue, kSecReturnData, nil], (CFTypeRef*)&data);
#endif
    if(!err) {
        return [[NSString alloc] initWithData:CFBridgingRelease(data) encoding:NSUTF8StringEncoding];
    }
    return nil;
}

-(void)setSession:(NSString *)session {
#ifdef ENTERPRISE
    SecItemAdd((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.enterprise", kSecAttrService, [session dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil], NULL);
#else
    SecItemAdd((__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)(kSecClassGenericPassword),  kSecClass, @"com.irccloud.IRCCloud", kSecAttrService, [session dataUsingEncoding:NSUTF8StringEncoding], kSecValueData, nil], NULL);
#endif
}

-(BOOL)notifier {
    return _notifier;
}

-(void)setNotifier:(BOOL)notifier {
    _notifier = notifier;
    if(_state == kIRCCloudStateConnected && !notifier) {
        CLS_LOG(@"Upgrading websocket");
        [self _sendRequest:@"upgrade_notifier" args:nil];
    }
}
@end
