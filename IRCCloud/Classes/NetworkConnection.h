//
//  NetworkConnection.h
//  IRCCloud
//
//  Created by Sam Steele on 2/22/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebSocket.h"
#import "SBJson.h"
#import "ServersDataSource.h"
#import "BuffersDataSource.h"
#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "EventsDataSource.h"

#define IRCCLOUD_HOST @"www.irccloud.com"

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
    kIRCCloudStateConnected,
    kIRCCloudStateDisconnecting
} kIRCCloudState;

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
    NSTimer *_idleTimer;
    NSTimeInterval _idleInterval;
    int _totalBuffers;
    int _numBuffers;
    int _lastReqId;
    int _currentCount;
    int _currentBid;
    NSTimeInterval _firstEID;
    
    kIRCCloudState _state;
    NSDictionary *_userInfo;
    NSDictionary *_prefs;
    NSTimeInterval _clockOffset;
    NSTimeInterval _reconnectTimestamp;
    NSOperationQueue *_queue;
}
@property (readonly) kIRCCloudState state;
@property (readonly) NSDictionary *userInfo;
@property (readonly) NSTimeInterval clockOffset;
@property (readonly) NSTimeInterval reconnectTimestamp;

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
@end
