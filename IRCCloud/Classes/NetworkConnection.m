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
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:_userAgent forHTTPHeaderField:@"User-Agent"];
    [request setValue:[NSString stringWithFormat:@"session=%@",[[NSUserDefaults standardUserDefaults] stringForKey:@"session"]] forHTTPHeaderField:@"Cookie"];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(_connection) {
        _running = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogStartedNotification object:self];
    } else {
        TFLog(@"Failed to create NSURLConnection");
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
    }
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	TFLog(@"Request failed: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogFailedNotification object:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	TFLog(@"Backlog download completed");
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogCompletedNotification object:self];
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	TFLog(@"Fetching: %@", [request URL]);
	return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if([response statusCode] != 200) {
        TFLog(@"HTTP status code: %i", [response statusCode]);
		TFLog(@"HTTP headers: %@", [response allHeaderFields]);
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

+(NetworkConnection *)sharedInstance {
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
    _servers = [ServersDataSource sharedInstance];
    _buffers = [BuffersDataSource sharedInstance];
    _channels = [ChannelsDataSource sharedIntance];
    _users = [UsersDataSource sharedInstance];
    _events = [EventsDataSource sharedInstance];
    _state = kIRCCloudStateDisconnected;
    _oobQueue = [[NSMutableArray alloc] init];
    _adapter = [[SBJsonStreamParserAdapter alloc] init];
    _adapter.delegate = self;
    _parser = [[SBJsonStreamParser alloc] init];
    _parser.supportMultipleDocuments = YES;
    _parser.delegate = _adapter;
    _lastReqId = 0;
    _writer = [[SBJsonWriter alloc] init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_backlogFailed:) name:kIRCCloudBacklogFailedNotification object:nil];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
    _userAgent = [NSString stringWithFormat:@"IRCCloud/%@ (%@; %@; %@ %@)", version, [UIDevice currentDevice].model, [[[NSUserDefaults standardUserDefaults] objectForKey: @"AppleLanguages"] objectAtIndex:0], [UIDevice currentDevice].systemName, [UIDevice currentDevice].systemVersion];
    TFLog(@"%@", _userAgent);
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

-(int)_sendRequest:(NSString *)method args:(NSDictionary *)args {
    @synchronized(_writer) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:args];
        [dict setObject:method forKey:@"_method"];
        [dict setObject:@(_lastReqId++) forKey:@"_reqid"];
        [_socket sendText:[_writer stringWithObject:dict]];
        return _lastReqId;
    }
}

-(int)say:(NSString *)message to:(NSString *)to cid:(int)cid {
    if(to)
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message, @"to":to}];
    else
        return [self _sendRequest:@"say" args:@{@"cid":@(cid), @"msg":message}];
}

-(void)connect {
    _state = kIRCCloudStateConnecting;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
    NSString *url = [NSString stringWithFormat:@"wss://%@",IRCCLOUD_HOST];
    if(_events.highestEid > 0)
        url = [url stringByAppendingFormat:@"?since_id=%g", _events.highestEid];
    WebSocketConnectConfig* config = [WebSocketConnectConfig configWithURLString:url origin:nil protocols:nil
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
    _state = kIRCCloudStateDisconnecting;
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
    TFLog(@"Socket connected");
    _state = kIRCCloudStateConnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError {
    TFLog(@"Status Code: %i", aStatusCode);
    TFLog(@"Close Message: %@", aMessage);
    TFLog(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
    _state = kIRCCloudStateDisconnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didReceiveError: (NSError*) aError {
    TFLog(@"Error: errorDesc=%@, failureReason=%@", [aError localizedDescription], [aError localizedFailureReason]);
    _state = kIRCCloudStateDisconnected;
    [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudConnectivityNotification object:self];
}

-(void)didReceiveTextMessage:(NSString*)aMessage {
    if(aMessage) {
        [_parser parse:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
    }
}

- (void) didReceiveBinaryMessage: (NSData*) aMessage {
    if(aMessage) {
        [_parser parse:aMessage];
    }
}

-(void)postObject:(id)object forEvent:(kIRCEvent)event {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:object userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:event]}];
    }];
}

-(void)parse:(NSDictionary *)dict backlog:(BOOL)backlog {
    [self performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
    IRCCloudJSONObject *object = [[IRCCloudJSONObject alloc] initWithDictionary:dict];
    if(object.type) {
        //NSLog(@"New event (%@)", object.type);
        if([object.type isEqualToString:@"header"]) {
            _idleInterval = [[object objectForKey:@"idle_interval"] doubleValue] / 1000.0;
            _clockOffset = [[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"time"] doubleValue];
            TFLog(@"idle interval: %f clock offset: %f", _idleInterval, _clockOffset);
        } else if([object.type isEqualToString:@"oob_include"]) {
            [self fetchOOB:[NSString stringWithFormat:@"https://%@%@", IRCCLOUD_HOST, [object objectForKey:@"url"]]];
        } else if([object.type isEqualToString:@"stat_user"]) {
            _userInfo = object.dictionary;
            [self postObject:object forEvent:kIRCEventUserInfo];
        } else if([object.type isEqualToString:@"backlog_starts"]) {
            _numBuffers = [[object objectForKey:@"numbuffers"] intValue];
            _totalBuffers = 0;
        } else if([object.type isEqualToString:@"makeserver"] || [object.type isEqualToString:@"server_details_changed"]) {
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
            server.lag = [[object objectForKey:@"lag"] intValue];
            server.ssl = [[object objectForKey:@"ssl"] intValue];
            server.realname = [object objectForKey:@"realname"];
            server.server_pass = [object objectForKey:@"server_pass"];
            server.nickserv_pass = [object objectForKey:@"nickserv_pass"];
            server.join_commands = [object objectForKey:@"join_commands"];
            server.fail_info = [object objectForKey:@"fail_info"];
            server.away = [object objectForKey:@"away"];
            server.ignores = [object objectForKey:@"ignores"];
            if(!backlog)
                [self postObject:server forEvent:kIRCEventMakeServer];
        } else if([object.type isEqualToString:@"makebuffer"]) {
            Buffer *buffer = [_buffers getBuffer:object.bid];
            if(!buffer) {
                buffer = [[Buffer alloc] init];
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
            if(!backlog)
                [self postObject:buffer forEvent:kIRCEventMakeBuffer];
            if(_numBuffers > 0) {
                _totalBuffers++;
                [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudBacklogProgressNotification object:[NSNumber numberWithFloat:(float)_totalBuffers / (float)_numBuffers]];
            }
        } else if([object.type isEqualToString:@"global_system_message"]) {
        } else if([object.type isEqualToString:@"idle"] || [object.type isEqualToString:@"end_of_backlog"] || [object.type isEqualToString:@"backlog_complete"]) {
        } else if([object.type isEqualToString:@"num_invites"]) {
        } else if([object.type isEqualToString:@"bad_channel_key"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventBadChannelKey];
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
            if(!backlog)
                [self postObject:object forEvent:kIRCEventAlert];
        } else if([object.type isEqualToString:@"open_buffer"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventOpenBuffer];
        } else if([object.type isEqualToString:@"invalid_nick"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventInvalidNick];
        } else if([object.type isEqualToString:@"ban_list"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventBanList];
        } else if([object.type isEqualToString:@"accept_list"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventAcceptList];
        } else if([object.type isEqualToString:@"who_response"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventWhoList];
        } else if([object.type isEqualToString:@"whois_response"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventWhois];
        } else if([object.type isEqualToString:@"list_response_fetching"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventListResponseFetching];
        } else if([object.type isEqualToString:@"list_response_toomany"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventListResponseTooManyChannels];
        } else if([object.type isEqualToString:@"list_response"]) {
            if(!backlog)
                [self postObject:object forEvent:kIRCEventListResponse];
        } else if([object.type isEqualToString:@"connection_deleted"]) {
            [_servers removeAllDataForServer:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventConnectionDeleted];
        } else if([object.type isEqualToString:@"delete_buffer"]) {
            [_buffers removeBuffer:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventDeleteBuffer];
        } else if([object.type isEqualToString:@"buffer_archived"]) {
            [_buffers updateArchived:1 buffer:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventBufferArchived];
        } else if([object.type isEqualToString:@"buffer_unarchived"]) {
            [_buffers updateArchived:0 buffer:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventBufferUnarchived];
        } else if([object.type isEqualToString:@"rename_conversation"]) {
            [_buffers updateName:[object objectForKey:@"new_name"] buffer:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventRenameConversation];
        } else if([object.type isEqualToString:@"status_changed"]) {
            [_servers updateStatus:[object objectForKey:@"status"] failInfo:[object objectForKey:@"fail_info"] server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventStatusChanged];
        } else if([object.type isEqualToString:@"buffer_msg"] || [object.type isEqualToString:@"buffer_me_msg"] || [object.type isEqualToString:@"server_motdstart"] || [object.type isEqualToString:@"wait"] || [object.type isEqualToString:@"banned"] || [object.type isEqualToString:@"kill"] || [object.type isEqualToString:@"connecting_cancelled"] || [object.type isEqualToString:@"target_callerid"]
                  || [object.type isEqualToString:@"notice"] || [object.type isEqualToString:@"server_welcome"] || [object.type isEqualToString:@"server_motd"] || [object.type isEqualToString:@"server_endofmotd"] || [object.type isEqualToString:@"services_down"] || [object.type isEqualToString:@"your_unique_id"] || [object.type isEqualToString:@"callerid"] || [object.type isEqualToString:@"target_notified"]
                  || [object.type isEqualToString:@"server_luserclient"] || [object.type isEqualToString:@"server_luserop"] || [object.type isEqualToString:@"server_luserconns"] || [object.type isEqualToString:@"myinfo"] || [object.type isEqualToString:@"hidden_host_set"] || [object.type isEqualToString:@"unhandled_line"] || [object.type isEqualToString:@"unparsed_line"]
                  || [object.type isEqualToString:@"server_luserme"] || [object.type isEqualToString:@"server_n_local"] || [object.type isEqualToString:@"server_luserchannels"] || [object.type isEqualToString:@"connecting_failed"] || [object.type isEqualToString:@"nickname_in_use"] || [object.type isEqualToString:@"channel_invite"] || [object.type hasPrefix:@"stats"]
                  || [object.type isEqualToString:@"server_n_global"] || [object.type isEqualToString:@"motd_response"] || [object.type isEqualToString:@"server_luserunknown"] || [object.type isEqualToString:@"socket_closed"] || [object.type isEqualToString:@"channel_mode_list_change"] || [object.type isEqualToString:@"msg_services"] || [object.type isEqualToString:@"endofstats"]
                  || [object.type isEqualToString:@"server_yourhost"] || [object.type isEqualToString:@"server_created"] || [object.type isEqualToString:@"inviting_to_channel"] || [object.type isEqualToString:@"error"] || [object.type isEqualToString:@"too_fast"] || [object.type isEqualToString:@"no_bots"] || [object.type isEqualToString:@"wallops"]) {
            Event *event = [_events addJSONObject:object];
            if(!backlog)
                [self postObject:event forEvent:kIRCEventBufferMsg];
        } else if([object.type isEqualToString:@"link_channel"]) {
            [_events addJSONObject:object];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventLinkChannel];
        } else if([object.type isEqualToString:@"channel_init"]) {
            Channel *channel = [_channels channelForBuffer:object.bid];
            if(!channel) {
                channel = [[Channel alloc] init];
                [_channels addChannel:channel];
            }
            channel.cid = object.cid;
            channel.bid = object.bid;
            channel.name = [object objectForKey:@"chan"];
            channel.type = [object objectForKey:@"channel_type"];
            channel.mode = [object objectForKey:@"mode"];
            channel.timestamp = [[object objectForKey:@"timestamp"] doubleValue];
            channel.topic_text = [[object objectForKey:@"topic"] objectForKey:@"text"];
            channel.topic_author = [[object objectForKey:@"topic"] objectForKey:@"nick"];
            channel.topic_time = [[[object objectForKey:@"topic"] objectForKey:@"time"] doubleValue];
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
        } else if([object.type isEqualToString:@"channel_topic"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_channels updateTopic:[object objectForKey:@"topic"] time:object.eid author:[object objectForKey:@"author"] buffer:object.bid];
                [self postObject:object forEvent:kIRCEventChannelTopic];
            }
        } else if([object.type isEqualToString:@"channel_url"]) {
            if(!backlog)
                [_channels updateURL:[object objectForKey:@"url"] buffer:object.bid];
        } else if([object.type isEqualToString:@"channel_mode"] || [object.type isEqualToString:@"channel_mode_is"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_channels updateMode:[object objectForKey:@"newmode"] buffer:object.bid];
                [self postObject:object forEvent:kIRCEventChannelMode];
            }
        } else if([object.type isEqualToString:@"channel_timestamp"]) {
            if(!backlog) {
                [_channels updateTimestamp:[[object objectForKey:@"timestamp"] doubleValue] buffer:object.bid];
                [self postObject:object forEvent:kIRCEventChannelTimestamp];
            }
        } else if([object.type isEqualToString:@"joined_channel"] || [object.type isEqualToString:@"you_joined_channel"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                User *user = [_users getUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                if(!user) {
                    user = [[User alloc] init];
                    [_users addUser:user];
                }
                if(user.nick)
                    user.old_nick = user.nick;
                user.nick = [object objectForKey:@"nick"];
                user.hostmask = [object objectForKey:@"hostmask"];
                user.mode = @"";
                user.away = 0;
                user.away_msg = @"";
                [self postObject:object forEvent:kIRCEventJoin];
            }
        } else if([object.type isEqualToString:@"parted_channel"] || [object.type isEqualToString:@"you_parted_channel"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                if([object.type isEqualToString:@"you_parted_channel"]) {
                    [_channels removeChannelForBuffer:object.bid];
                    [_users removeUsersForBuffer:object.bid];
                }
                [self postObject:object forEvent:kIRCEventPart];
            }
        } else if([object.type isEqualToString:@"quit"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                [self postObject:object forEvent:kIRCEventQuit];
            }
        } else if([object.type isEqualToString:@"quit_server"]) {
            [_events addJSONObject:object];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventQuit];
        } else if([object.type isEqualToString:@"kicked_channel"] || [object.type isEqualToString:@"you_kicked_channel"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_users removeUser:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                if([object.type isEqualToString:@"you_kicked_channel"]) {
                    [_channels removeChannelForBuffer:object.bid];
                    [_users removeUsersForBuffer:object.bid];
                }
                [self postObject:object forEvent:kIRCEventKick];
            }
        } else if([object.type isEqualToString:@"nickchange"] || [object.type isEqualToString:@"you_nickchange"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_users updateNick:[object objectForKey:@"newnick"] oldNick:[object objectForKey:@"oldnick"] cid:object.cid bid:object.bid];
                if([object.type isEqualToString:@"you_nickchange"])
                    [_servers updateNick:[object objectForKey:@"new_nick"] server:object.cid];
                [self postObject:object forEvent:kIRCEventNickChange];
            }
        } else if([object.type isEqualToString:@"user_channel_mode"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_users updateMode:[object objectForKey:@"newmode"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
                [self postObject:object forEvent:kIRCEventUserChannelMode];
            }
        } else if([object.type isEqualToString:@"member_updates"]) {
            TFLog(@"TODO: member_updates: %@", object);
        } else if([object.type isEqualToString:@"user_away"] || [object.type isEqualToString:@"away"]) {
            [_users updateAway:1 msg:[object objectForKey:@"msg"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            [_buffers updateAway:[object objectForKey:@"msg"] buffer:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventAway];
        } else if([object.type isEqualToString:@"self_away"]) {
            [_users updateAway:1 msg:[object objectForKey:@"away_msg"] nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            [_servers updateAway:[object objectForKey:@"away_msg"] server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventAway];
        } else if([object.type isEqualToString:@"self_back"]) {
            [_users updateAway:0 msg:@"" nick:[object objectForKey:@"nick"] cid:object.cid bid:object.bid];
            [_servers updateAway:@"" server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventSelfBack];
        } else if([object.type isEqualToString:@"self_details"]) {
            [_events addJSONObject:object];
            [_servers updateUsermask:[object objectForKey:@"usermask"] server:object.bid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventSelfDetails];
        } else if([object.type isEqualToString:@"user_mode"]) {
            [_events addJSONObject:object];
            if(!backlog) {
                [_servers updateMode:[object objectForKey:@"newmode"] server:object.cid];
                [self postObject:object forEvent:kIRCEventUserMode];
            }
        } else if([object.type isEqualToString:@"connection_lag"]) {
            [_servers updateLag:[[object objectForKey:@"lag"] intValue] server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventConnectionLag];
        } else if([object.type isEqualToString:@"isupport_params"]) {
            [_servers updateIsupport:[object objectForKey:@"params"] server:object.cid];
        } else if([object.type isEqualToString:@"set_ignores"] || [object.type isEqualToString:@"ignore_list"]) {
            [_servers updateIgnores:[object objectForKey:@"masks"] server:object.cid];
            if(!backlog)
                [self postObject:object forEvent:kIRCEventSetIgnores];
        } else if([object.type isEqualToString:@"heartbeat_echo"]) {
            NSDictionary *seenEids = [object objectForKey:@"seenEids"];
            for(NSNumber *cid in seenEids.allKeys) {
                NSDictionary *eids = [seenEids objectForKey:cid];
                for(NSNumber *bid in eids.allKeys) {
                    NSTimeInterval eid = [[eids objectForKey:bid] doubleValue];
                    [_buffers updateLastSeenEID:eid buffer:[bid intValue]];
                }
            }
        } else {
            TFLog(@"Unhandled type: %@", object);
        }
    } else {
        TFLog(@"Repsonse: %@", object);
    }
    if(_idleInterval > 0)
        [self performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:YES];
}

-(void)cancelIdleTimer {
    [_idleTimer invalidate];
    _idleTimer = nil;
}

-(void)scheduleIdleTimer {
    [_idleTimer invalidate];
    _idleTimer = nil;
    if(_idleInterval <= 0)
        return;
    
    _idleTimer = [NSTimer scheduledTimerWithTimeInterval:_idleInterval+10 target:self selector:@selector(_idle) userInfo:nil repeats:NO];
}

-(void)_idle {
    _idleTimer = nil;
    TFLog(@"Websocket idle time exceeded, reconnecting...");
    [_socket close];
    [self connect];
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid {
    [self requestBacklogForBuffer:bid server:cid beforeId:-1];
}

-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid {
    NSString *URL = nil;
    if(eid > 0)
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i&beforeId=%g", IRCCLOUD_HOST, cid, bid, eid];
    else
        URL = [NSString stringWithFormat:@"https://%@/chat/backlog?cid=%i&bid=%i", IRCCLOUD_HOST, cid, bid];
    OOBFetcher *fetcher = [self fetchOOB:URL];
    fetcher.bid = bid;
}


-(OOBFetcher *)fetchOOB:(NSString *)url {
    for(OOBFetcher *fetcher in _oobQueue) {
        if([fetcher.url isEqualToString:url]) {
            TFLog(@"Ignoring duplicate OOB request");
            return fetcher;
        }
    }
    OOBFetcher *fetcher = [[OOBFetcher alloc] initWithURL:url];
    [_oobQueue addObject:fetcher];
    if(_oobQueue.count == 1) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [fetcher start];
        }];
    } else {
        TFLog(@"OOB Request has been queued");
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

-(void)_backlogCompleted:(NSNotification *)notification {
    OOBFetcher *fetcher = notification.object;
    if(fetcher.bid > 0)
        [_buffers updateTimeout:0 buffer:fetcher.bid];
    [_oobQueue removeObject:fetcher];
    [self _scheduleTimedoutBuffers];
}

-(void)_backlogFailed:(NSNotification *)notification {
    [_oobQueue removeObject:notification.object];
    [self _scheduleTimedoutBuffers];
}

-(void)_scheduleTimedoutBuffers {
    for(Buffer *buffer in [_buffers getBuffers]) {
        if(buffer.timeout > 0) {
            TFLog(@"Requesting backlog for timed-out buffer: %@", buffer.name);
            [self requestBacklogForBuffer:buffer.bid server:buffer.cid];
        }
    }
    if(_oobQueue.count > 0) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [(OOBFetcher *)[_oobQueue objectAtIndex:0] start];
        }];
    }
}
@end
