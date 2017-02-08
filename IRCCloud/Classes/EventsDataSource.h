//
//  EventsDataSource.h
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
#import "IRCCloudJSONObject.h"

#define ROW_MESSAGE 0
#define ROW_TIMESTAMP 1
#define ROW_BACKLOG 2
#define ROW_LASTSEENEID 3
#define ROW_SOCKETCLOSED 4
#define ROW_FAILED 5
#define ROW_ME_MESSAGE 6
#define ROW_THUMBNAIL 7
#define ROW_FILE 8
#define TYPE_TIMESTMP @"__timestamp__"
#define TYPE_BACKLOG @"__backlog__"
#define TYPE_LASTSEENEID @"__lastseeneid"
#define TYPE_THUMBNAIL @"__thumbnail__"
#define TYPE_FILE @"__file__"

@interface Event : NSObject<NSCoding> {
    int _cid;
    int _bid;
    NSTimeInterval _eid;
    NSString *_timestamp;
    NSString *_type;
    NSString *_msg;
    NSString *_hostmask;
    NSString *_from;
    NSString *_fromMode;
    NSString *_nick;
    NSString *_oldNick;
    NSString *_server;
    NSString *_diff;
    NSString *_formattedMsg;
    NSString *_accessibilityLabel;
    NSString *_accessibilityValue;
    NSAttributedString *_formatted;
    NSAttributedString *_formattedNick;
    NSAttributedString *_formattedRealname;
    NSString *_realname;
    BOOL _isHighlight;
    BOOL _isSelf;
    BOOL _toChan;
    BOOL _toBuffer;
    UIColor *_color;
    UIColor *_bgColor;
    NSDictionary *_ops;
    NSTimeInterval _groupEid;
    int _rowType;
    NSString *_groupMsg;
    BOOL _linkify;
    NSString *_targetMode;
    int _reqid;
    BOOL _pending;
    BOOL _monospace;
    float _height;
    NSArray *_links;
    NSArray *_realnameLinks;
    NSString *_to;
    NSString *_command;
    NSString *_day;
    NSString *_ignoreMask;
    NSString *_chan;
    NSTimer *_expirationTimer;
    NSDictionary *_entities;
    float _timestampPosition;
    BOOL _isHeader;
    NSTimeInterval _serverTime;
    BOOL _isEmojiOnly;
}
@property (nonatomic, assign) int cid, bid, rowType, reqId;
@property (nonatomic, assign) NSTimeInterval eid, groupEid, serverTime;
@property (nonatomic, copy) NSString *timestamp, *type, *msg, *hostmask, *from, *fromMode, *nick, *oldNick, *server, *diff, *groupMsg, *targetMode, *formattedMsg, *to, *command, *day, *chan, *realname, *accessibilityLabel, *accessibilityValue;
@property (nonatomic, assign) BOOL isHighlight, isSelf, toChan, toBuffer, linkify, pending, monospace, isHeader, isEmojiOnly;
@property (nonatomic, copy) NSDictionary *ops,*entities;
@property (nonatomic, strong) UIColor *color, *bgColor;
@property (nonatomic, copy) NSAttributedString *formatted, *formattedNick, *formattedRealname;
@property (nonatomic, assign) float height, timestampPosition, avatarHeight;
@property (nonatomic, strong) NSArray *links, *realnameLinks;
@property (nonatomic, strong) NSTimer *expirationTimer;
-(NSComparisonResult)compare:(Event *)aEvent;
-(BOOL)isImportant:(NSString *)bufferType;
-(BOOL)isMessage;
-(NSString *)ignoreMask;
-(NSTimeInterval)time;
@end

@interface EventsDataSource : NSObject {
    NSMutableDictionary *_events;
    NSMutableDictionary *_events_sorted;
    NSMutableDictionary *_dirtyBIDs;
    NSMutableDictionary *_lastEIDs;
    NSDictionary *_formatterMap;
}
+(EventsDataSource *)sharedInstance;
-(void)serialize;
-(void)clear;
-(void)clearFormattingCache;
-(void)addEvent:(Event *)event;
-(Event *)addJSONObject:(IRCCloudJSONObject *)object;
-(Event *)event:(NSTimeInterval)eid buffer:(int)bid;
-(void)removeEvent:(NSTimeInterval)eid buffer:(int)bid;
-(void)removeEventsForBuffer:(int)bid;
-(void)pruneEventsForBuffer:(int)bid maxSize:(int)size;
-(NSArray *)eventsForBuffer:(int)bid;
-(NSUInteger)sizeOfBuffer:(int)bid;
-(void)removeEventsBefore:(NSTimeInterval)min_eid buffer:(int)bid;
-(int)unreadStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type;
-(int)highlightCountForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type;
-(int)highlightStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type;
-(NSTimeInterval)lastEidForBuffer:(int)bid;
-(void)clearPendingAndFailed;
-(void)reformat;
@end
