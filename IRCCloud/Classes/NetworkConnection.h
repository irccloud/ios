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
    
    kIRCCloudState _state;
    NSDictionary *_userInfo;
    NSTimeInterval _clockOffset;
}
@property (readonly) kIRCCloudState state;
@property (readonly) NSDictionary *userInfo;
@property (readonly) NSTimeInterval clockOffset;

+(NetworkConnection*)sharedInstance;
-(NSDictionary *)login:(NSString *)email password:(NSString *)password;
-(void)connect;
-(void)disconnect;
-(void)scheduleIdleTimer;
-(void)cancelIdleTimer;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid;
-(void)requestBacklogForBuffer:(int)bid server:(int)cid beforeId:(NSTimeInterval)eid;
@end
