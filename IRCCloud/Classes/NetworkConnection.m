//
//  NetworkConnection.m
//  IRCCloud
//
//  Created by Sam Steele on 2/22/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

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

@interface OOBFetcher : NSObject<NSURLConnectionDelegate> {
    SBJsonStreamParser *_parser;
    NSString *url;
    BOOL _cancelled;
    NSURLConnection *_connection;
}
@property (readonly) NSString *url;
-(id)initWithURL:(NSString *)URL parser:(SBJsonStreamParser *)parser;
-(void)cancel;
-(void)start;
@end

@implementation OOBFetcher
@synthesize url;

-(id)initWithURL:(NSString *)URL parser:(SBJsonStreamParser *)parser {
    self = [super init];
    url = URL;
    _parser = parser;
    _cancelled = NO;
    return self;
}
-(void)cancel {
    _cancelled = YES;
    [_connection cancel];
}
-(void)start {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"session"]] forHTTPHeaderField:@"Cookie"];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(_connection) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:self];
    } else {
        NSLog(@"Failed to create NSURLConnection");
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Request failed: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	NSLog(@"Backlog download completed");
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:self];
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	NSLog(@"Fetching: %@", [request URL]);
	return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if([response statusCode] != 200) {
        NSLog(@"HTTP status code: %i", [response statusCode]);
		NSLog(@"HTTP headers: %@", [response allHeaderFields]);
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if(!_cancelled) {
        [_parser parse:data];
    }
}

@end

@implementation NetworkConnection

@synthesize state, userInfo, clockOffset;

+ (NetworkConnection *)sharedInstance {
    static NetworkConnection *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[NetworkConnection alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    state = kIRCCloudStateDisconnected;
    _oobQueue = [[NSMutableArray alloc] init];
    _adapter = [[SBJsonStreamParserAdapter alloc] init];
    _adapter.delegate = self;
    _parser = [[SBJsonStreamParser alloc] init];
    _parser.supportMultipleDocuments = YES;
    _parser.delegate = _adapter;
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    _userAgent = [NSString stringWithFormat:@"IRCCloud/%@ (%@; %@; %@ %@)", version, [UIDevice currentDevice].model, [[[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"] objectAtIndex:0], [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
    NSLog(@"%@", _userAgent);
    return self;
}

-(NSDictionary *)login:(NSString *)email password:(NSString *)password {
	NSData *data;
	NSURLResponse *response = nil;
	NSError *error = nil;

    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/login", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"email=%@&password=%@", [email stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [password stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    return [[[SBJsonParser alloc] init] objectWithData:data];
}

-(void)connect {
    state = kIRCCloudStateConnecting;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
    WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:[NSString stringWithFormat:@"wss://%@",IRCCLOUD_HOST] origin:nil protocols:nil
                                                                     tlsSettings:[@{(NSString *)kCFStreamSSLPeerName: [NSNull null],
                                                                                  (NSString *)kCFStreamSSLAllowsAnyRoot: @YES,
                                                                                  (NSString *)kCFStreamSSLValidatesCertificateChain: @NO} mutableCopy]
                                                                         headers:[@[[HandshakeHeader headerWithValue:_userAgent forKey:@"User-Agent"],
                                                                                    [HandshakeHeader headerWithValue:[NSString stringWithFormat:@"session=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"session"]] forKey:@"Cookie"]] mutableCopy]
                                                               verifySecurityKey:YES extensions:nil ];
    _socket = [WebSocket webSocketWithConfig:config delegate:self];
    
    [_socket open];
}

-(void)disconnect {
    state = kIRCCloudStateDisconnecting;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
    [_socket close];
}

-(void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    //This is wasteful, we don't use it
}

-(void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
    [self parse:dict backlog:NO];
}

-(void)parser:(SBJsonStreamParser *)parser foundObjectInArray:(NSDictionary *)dict {
    [self parse:dict backlog:YES];
}

-(void)didOpen {
    NSLog(@"Socket connected");
    state = kIRCCloudStateConnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError {
    NSLog(@"Status Code: %i", aStatusCode);
    NSLog(@"Close Message: %@", aMessage);
    NSLog(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
    state = kIRCCloudStateDisconnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didReceiveError: (NSError*) aError {
    NSLog(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
    state = kIRCCloudStateDisconnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didReceiveTextMessage:(NSString*)aMessage {
    if(aMessage) {
        [_parser parse:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) didReceiveBinaryMessage: (NSData*) aMessage {
}

-(void)postObject:(id)object forEvent:(kIRCEvent)event {
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:object userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:event]}];
}

-(void)parse:(NSDictionary *)dict backlog:(BOOL)backlog {
    IRCCloudJSONObject *object = [[IRCCloudJSONObject alloc] initWithDictionary:dict];
    if(object.type) {
        //NSLog(@"New event (%@)", object.type);
        if([object.type isEqualToString:@"header"]) {
            _idleInterval = [[object objectForKey:@"idle_interval"] longValue];
            clockOffset = [[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"time"] longValue];
            NSLog(@"idle interval: %li clock offset: %f", _idleInterval, clockOffset);
        } else if([object.type isEqualToString:@"oob_include"]) {
            [self fetchOOB:[NSString stringWithFormat:@"https://%@%@", IRCCLOUD_HOST, [object objectForKey:@"url"]]];
        } else if([object.type isEqualToString:@"stat_user"]) {
            userInfo = object.dictionary;
            [self postObject:object forEvent:kIRCEventUserInfo];
        } else if([object.type isEqualToString:@"backlog_starts"]) {
            _numBuffers = [[object objectForKey:@"numbuffers"] intValue];
            _totalBuffers = 0;
        } else if([object.type isEqualToString:@"makeserver"] || [object.type isEqualToString:@"server_details_changed"]) {
            NSLog(@"New server: %@", [object objectForKey:@"hostname"]);
        } else if([object.type isEqualToString:@"makebuffer"]) {
            NSLog(@"New buffer: %@", [object objectForKey:@"name"]);
            _totalBuffers++;
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogProgressNotification object:[NSNumber numberWithFloat:(float)_totalBuffers / (float)_numBuffers]];
        } else if([object.type isEqualToString:@"global_system_message"]) {
        } else if([object.type isEqualToString:@"idle"] || [object.type isEqualToString:@"end_of_backlog"] || [object.type isEqualToString:@"backlog_complete"]) {
        } else if([object.type isEqualToString:@"num_invites"]) {
        } else if([object.type isEqualToString:@"bad_channel_key"]) {
        } else if([object.type isEqualToString:@"too_many_channels"] || [object.type isEqualToString:@"no_such_channel"] ||
                  [object.type isEqualToString:@"no_such_nick"] || [object.type isEqualToString:@"invalid_nick_change"] ||
                  [object.type isEqualToString:@"chan_privs_needed"] || [object.type isEqualToString:@"accept_exists"] ||
                  [object.type isEqualToString:@"banned_from_channel"] || [object.type isEqualToString:@"oper_only"] ||
                  [object.type isEqualToString:@"no_nick_change"] || [object.type isEqualToString:@"no_messages_from_non_registered"] ||
                  [object.type isEqualToString:@"not_registered"] || [object.type isEqualToString:@"already_registered"] ||
                  [object.type isEqualToString:@"too_many_targets"] || [object.type isEqualToString:@"no_such_server"] ||
                  [object.type isEqualToString:@"unknown_command"] || [object.type isEqualToString:@"help_not_found"] ||
                  [object.type isEqualToString:@"accept_full"] || [object.type isEqualToString:@"accept_not"] ||
                  [object.type isEqualToString:@"nick_collision"] || [object.type isEqualToString:@"nick_too_fast"] ||
                  [object.type isEqualToString:@"save_nick"] || [object.type isEqualToString:@"unknown_mode"] ||
                  [object.type isEqualToString:@"user_not_in_channel"] || [object.type isEqualToString:@"need_more_params"] ||
                  [object.type isEqualToString:@"users_dont_match"] || [object.type isEqualToString:@"users_disabled"] ||
                  [object.type isEqualToString:@"invalid_operator_password"] || [object.type isEqualToString:@"flood_warning"] ||
                  [object.type isEqualToString:@"privs_needed"] || [object.type isEqualToString:@"operator_fail"] ||
                  [object.type isEqualToString:@"not_on_channel"] || [object.type isEqualToString:@"ban_on_chan"] ||
                  [object.type isEqualToString:@"cannot_send_to_chan"] || [object.type isEqualToString:@"user_on_channel"] ||
                  [object.type isEqualToString:@"no_nick_given"] || [object.type isEqualToString:@"no_text_to_send"] ||
                  [object.type isEqualToString:@"no_origin"] || [object.type isEqualToString:@"only_servers_can_change_mode"] ||
                  [object.type isEqualToString:@"silence"] || [object.type isEqualToString:@"no_channel_topic"] ||
                  [object.type isEqualToString:@"invite_only_chan"] || [object.type isEqualToString:@"channel_full"]) {
        } else if([object.type isEqualToString:@"open_buffer"]) {
        } else if([object.type isEqualToString:@"invalid_nick"]) {
        } else if([object.type isEqualToString:@"ban_list"]) {
        } else if([object.type isEqualToString:@"accept_list"]) {
        } else if([object.type isEqualToString:@"who_response"]) {
        } else if([object.type isEqualToString:@"whois_response"]) {
        } else if([object.type isEqualToString:@"list_response_fetching"]) {
        } else if([object.type isEqualToString:@"list_response_toomany"]) {
        } else if([object.type isEqualToString:@"list_response"]) {
        } else if([object.type isEqualToString:@"connection_deleted"]) {
        } else if([object.type isEqualToString:@"delete_buffer"]) {
        } else if([object.type isEqualToString:@"buffer_archived"]) {
        } else if([object.type isEqualToString:@"buffer_unarchived"]) {
        } else if([object.type isEqualToString:@"rename_conversation"]) {
        } else if([object.type isEqualToString:@"status_changed"]) {
        } else if([object.type isEqualToString:@"buffer_msg"] || [object.type isEqualToString:@"buffer_me_msg"] || [object.type isEqualToString:@"server_motdstart"] || [object.type isEqualToString:@"wait"] || [object.type isEqualToString:@"banned"] || [object.type isEqualToString:@"kill"] || [object.type isEqualToString:@"connecting_cancelled"] || [object.type isEqualToString:@"target_callerid"]
                  || [object.type isEqualToString:@"notice"] || [object.type isEqualToString:@"server_welcome"] || [object.type isEqualToString:@"server_motd"] || [object.type isEqualToString:@"server_endofmotd"] || [object.type isEqualToString:@"services_down"] || [object.type isEqualToString:@"your_unique_id"] || [object.type isEqualToString:@"callerid"] || [object.type isEqualToString:@"target_notified"]
                  || [object.type isEqualToString:@"server_luserclient"] || [object.type isEqualToString:@"server_luserop"] || [object.type isEqualToString:@"server_luserconns"] || [object.type isEqualToString:@"myinfo"] || [object.type isEqualToString:@"hidden_host_set"] || [object.type isEqualToString:@"unhandled_line"] || [object.type isEqualToString:@"unparsed_line"]
                  || [object.type isEqualToString:@"server_luserme"] || [object.type isEqualToString:@"server_n_local"] || [object.type isEqualToString:@"server_luserchannels"] || [object.type isEqualToString:@"connecting_failed"] || [object.type isEqualToString:@"nickname_in_use"] || [object.type isEqualToString:@"channel_invite"] || [object.type hasPrefix:@"stats"]
                  || [object.type isEqualToString:@"server_n_global"] || [object.type isEqualToString:@"motd_response"] || [object.type isEqualToString:@"server_luserunknown"] || [object.type isEqualToString:@"socket_closed"] || [object.type isEqualToString:@"channel_mode_list_change"] || [object.type isEqualToString:@"msg_services"] || [object.type isEqualToString:@"endofstats"]
                  || [object.type isEqualToString:@"server_yourhost"] || [object.type isEqualToString:@"server_created"] || [object.type isEqualToString:@"inviting_to_channel"] || [object.type isEqualToString:@"error"] || [object.type isEqualToString:@"too_fast"] || [object.type isEqualToString:@"no_bots"] || [object.type isEqualToString:@"wallops"]) {
        } else if([object.type isEqualToString:@"link_channel"]) {
        } else if([object.type isEqualToString:@"channel_init"]) {
        } else if([object.type isEqualToString:@"channel_topic"]) {
        } else if([object.type isEqualToString:@"channel_url"]) {
        } else if([object.type isEqualToString:@"channel_mode"] || [object.type isEqualToString:@"channel_mode_is"]) {
        } else if([object.type isEqualToString:@"channel_timestamp"]) {
        } else if([object.type isEqualToString:@"joined_channel"] || [object.type isEqualToString:@"you_joined_channel"]) {
        } else if([object.type isEqualToString:@"parted_channel"] || [object.type isEqualToString:@"you_parted_channel"]) {
        } else if([object.type isEqualToString:@"quit"]) {
        } else if([object.type isEqualToString:@"quit_server"]) {
        } else if([object.type isEqualToString:@"kicked_channel"] || [object.type isEqualToString:@"you_kicked_channel"]) {
        } else if([object.type isEqualToString:@"nickchange"] || [object.type isEqualToString:@"you_nickchange"]) {
        } else if([object.type isEqualToString:@"user_channel_mode"]) {
        } else if([object.type isEqualToString:@"member_updates"]) {
        } else if([object.type isEqualToString:@"user_away"] || [object.type isEqualToString:@"away"]) {
        } else if([object.type isEqualToString:@"self_away"]) {
        } else if([object.type isEqualToString:@"self_back"]) {
        } else if([object.type isEqualToString:@"self_details"]) {
        } else if([object.type isEqualToString:@"user_mode"]) {
        } else if([object.type isEqualToString:@"connection_lag"]) {
        } else if([object.type isEqualToString:@"isupport_params"]) {
        } else if([object.type isEqualToString:@"set_ignores"] || [object.type isEqualToString:@"ignore_list"]) {
        } else if([object.type isEqualToString:@"heartbeat_echo"]) {
        } else {
            NSLog(@"Unhandled type: %@", object);
        }
    } else {
        NSLog(@"Repsonse: %@", object);
    }
}

-(void)fetchOOB:(NSString *)url {
    for(OOBFetcher *fetcher in _oobQueue) {
        if([fetcher.url isEqualToString:url]) {
            NSLog(@"Ignoring duplicate OOB request");
            return;
        }
    }
    OOBFetcher *fetcher = [[OOBFetcher alloc] initWithURL:url parser:_parser];
    [_oobQueue addObject:fetcher];
    if(_oobQueue.count == 1)
        [fetcher performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    else
        NSLog(@"OOB Request has been queued");
}

-(void)clearOOB {
    NSMutableArray *oldQueue = _oobQueue;
    _oobQueue = [[NSMutableArray alloc] init];
    for(OOBFetcher *fetcher in oldQueue) {
        [fetcher cancel];
    }
}
@end
