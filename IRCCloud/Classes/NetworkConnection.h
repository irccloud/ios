//
//  NetworkConnection.h
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


#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "WebSocket.h"
#import "SBJson.h"
#import "ServersDataSource.h"
#import "BuffersDataSource.h"
#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "EventsDataSource.h"

#ifdef BRAND_HOST
#define IRCCLOUD_HOST BRAND_HOST
#else
#define IRCCLOUD_HOST "www.irccloud.com"
#endif

extern NSString *kIRCCloudConnectivityNotification;
extern NSString *kIRCCloudEventNotification;
extern NSString *kIRCCloudBacklogStartedNotification;
extern NSString *kIRCCloudBacklogFailedNotification;
extern NSString *kIRCCloudBacklogCompletedNotification;
extern NSString *kIRCCloudBacklogProgressNotification;

extern NSString *kIRCCloudEventKey;

typedef enum {
    kIRCEventUserInfo,
    kIRCEventMakeServer,
    kIRCEventMakeBuffer,
    kIRCEventDeleteBuffer,
    kIRCEventBufferMsg,
    kIRCEventHeartbeatEcho,
    kIRCEventChannelInit,
    kIRCEventChannelTopic,
    kIRCEventJoin,
    kIRCEventPart,
    kIRCEventNickChange,
    kIRCEventQuit,
    kIRCEventMemberUpdates,
    kIRCEventUserChannelMode,
    kIRCEventBufferArchived,
    kIRCEventBufferUnarchived,
    kIRCEventRenameConversation,
    kIRCEventStatusChanged,
    kIRCEventConnectionDeleted,
    kIRCEventAway,
    kIRCEventSelfBack,
    kIRCEventKick,
    kIRCEventChannelMode,
    kIRCEventChannelTimestamp,
    kIRCEventSelfDetails,
    kIRCEventUserMode,
    kIRCEventSetIgnores,
    kIRCEventBadChannelKey,
    kIRCEventOpenBuffer,
    kIRCEventInvalidNick,
    kIRCEventBanList,
    kIRCEventWhoList,
    kIRCEventWhois,
    kIRCEventNamesList,
    kIRCEventLinkChannel,
    kIRCEventListResponseFetching,
    kIRCEventListResponse,
    kIRCEventListResponseTooManyChannels,
    kIRCEventConnectionLag,
    kIRCEventGlobalMsg,
    kIRCEventAcceptList,
    kIRCEventFailureMsg,
    kIRCEventSuccess,
    kIRCEventAlert
} kIRCEvent;

typedef enum {
    kIRCCloudStateDisconnected,
    kIRCCloudStateConnecting,
    kIRCCloudStateConnected
} kIRCCloudState;

typedef enum {
    kIRCCloudUnreachable,
    kIRCCloudReachable,
    kIRCCloudUnknown
} kIRCCloudReachability;

@interface NetworkConnection : NSObject<WebSocketDelegate, SBJsonStreamParserAdapterDelegate> {
    WebSocket *_socket;
    SBJsonStreamParserAdapter *_adapter;
    SBJsonStreamParser *_parser;
    SBJsonWriter *_writer;
    ServersDataSource *_servers;
    BuffersDataSource *_buffers;
    ChannelsDataSource *_channels;
    UsersDataSource *_users;
    EventsDataSource *_events;
    NSMutableArray *_oobQueue;
    NSMutableDictionary *_awayOverride;
    NSTimer *_idleTimer;
    NSTimeInterval _idleInterval;
    int _totalBuffers;
    int _numBuffers;
    int _lastReqId;
    int _currentCount;
    int _totalCount;
    int _currentBid;
    int _failCount;
    BOOL _background;
    BOOL backlog;
    NSTimeInterval _firstEID;
    NSString *_streamId;
    int _accrued;
    
    kIRCCloudState _state;
    NSDictionary *_userInfo;
    NSDictionary *_prefs;
    NSTimeInterval _clockOffset;
    NSTimeInterval _reconnectTimestamp;
    NSOperationQueue *_queue;
    SCNetworkReachabilityRef _reachability;
    BOOL _reachabilityValid;
    NSDictionary *_parserMap;
}
@property (readonly) kIRCCloudState state;
@property (readonly) NSDictionary *userInfo;
@property (readonly) NSTimeInterval clockOffset;
@property NSTimeInterval idleInterval;
@property NSTimeInterval reconnectTimestamp;
@property BOOL background, reachabilityValid;
@property (readonly) kIRCCloudReachability reachable;

+(NetworkConnection*)sharedInstance;
-(NSDictionary *)login:(NSString *)email password:(NSString *)password;
-(NSDictionary *)prefs;
-(void)connect;
-(void)disconnect;
-(void)clearPrefs;
-(void)scheduleIdleTimer;
-(void)cancelIdleTimer;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid;
-(int)say:(NSString *)message to:(NSString *)cid cid:(int)cid;
-(int)heartbeat:(int)selectedBuffer cid:(int)cid bid:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid;
-(int)join:(NSString *)channel key:(NSString *)key cid:(int)cid;
-(int)part:(NSString *)channel msg:(NSString *)msg cid:(int)cid;
-(int)kick:(NSString *)nick chan:(NSString *)chan msg:(NSString *)msg cid:(int)cid;
-(int)mode:(NSString *)mode chan:(NSString *)chan cid:(int)cid;
-(int)invite:(NSString *)nick chan:(NSString *)chan cid:(int)cid;
-(int)archiveBuffer:(int)bid cid:(int)cid;
-(int)unarchiveBuffer:(int)bid cid:(int)cid;
-(int)deleteBuffer:(int)bid cid:(int)cid;
-(int)deleteServer:(int)cid;
-(int)addServer:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands channels:(NSString *)channels;
-(int)editServer:(int)cid hostname:(NSString *)hostname port:(int)port ssl:(int)ssl netname:(NSString *)netname nick:(NSString *)nick realname:(NSString *)realname serverPass:(NSString *)serverPass nickservPass:(NSString *)nickservPass joinCommands:(NSString *)joinCommands;
-(int)ignore:(NSString *)mask cid:(int)cid;
-(int)unignore:(NSString *)mask cid:(int)cid;
-(int)setPrefs:(NSString *)prefs;
-(int)setEmail:(NSString *)email realname:(NSString *)realname highlights:(NSString *)highlights autoaway:(BOOL)autoaway;
-(int)ns_help_register:(int)cid;
-(int)setNickservPass:(NSString *)nspass cid:(int)cid;
-(int)whois:(NSString *)nick server:(NSString *)server cid:(int)cid;
-(int)topic:(NSString *)topic chan:(NSString *)chan cid:(int)cid;
-(int)back:(int)cid;
-(int)disconnect:(int)cid msg:(NSString *)msg;
-(int)reconnect:(int)cid;
-(NSDictionary *)registerAPNs:(NSData *)token;
-(NSDictionary *)unregisterAPNs:(NSData *)token;
-(void)logout;
-(void)fail;
@end
