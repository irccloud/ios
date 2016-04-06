//
//  CollapsedEvents.h
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
#import "EventsDataSource.h"
#import "ServersDataSource.h"

typedef enum {
    kCollapsedEventNetSplit,
    kCollapsedEventJoin,
    kCollapsedEventPart,
    kCollapsedEventQuit,
    kCollapsedEventMode,
    kCollapsedEventPopIn,
    kCollapsedEventPopOut,
    kCollapsedEventNickChange,
    kCollapsedEventConnectionStatus
} kCollapsedEvent;

typedef enum {
    kCollapsedModeOper,
    kCollapsedModeOwner,
    kCollapsedModeAdmin,
    kCollapsedModeOp,
    kCollapsedModeHalfOp,
    kCollapsedModeVoice,
    
    kCollapsedModeDeOper,
    kCollapsedModeDeOwner,
    kCollapsedModeDeAdmin,
    kCollapsedModeDeOp,
    kCollapsedModeDeHalfOp,
    kCollapsedModeDeVoice,
} kCollapsedMode;

@interface CollapsedEvent : NSObject {
    kCollapsedEvent _type;
    BOOL _modes[12];
    BOOL _netsplit;
    BOOL _operIsLower;
    NSTimeInterval _eid;
    NSString *_nick;
    NSString *_oldNick;
    NSString *_hostname;
    NSString *_msg;
    NSString *_fromMode;
    NSString *_fromNick;
    NSString *_targetMode;
    NSString *_chan;
    int _count;
}
@property NSTimeInterval eid;
@property kCollapsedEvent type;
@property NSString *nick, *oldNick, *hostname, *msg, *fromMode, *fromNick, *targetMode, *chan;
@property BOOL netsplit, operIsLower;
@property int count;
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent;
-(BOOL)addMode:(NSString *)mode server:(Server *)server;
-(BOOL)removeMode:(NSString *)mode server:(Server *)server;
-(NSString *)modes:(BOOL)showSymbol mode_modes:(NSArray *)mode_modes;
-(void)copyModes:(CollapsedEvent *)from;
-(int)modeCount;
@end

@interface CollapsedEvents : NSObject {
    NSMutableArray *_data;
    Server *_server;
    NSArray *_mode_modes;
    BOOL _showChan;
}
@property BOOL showChan;
-(void)clear;
-(BOOL)addEvent:(Event *)event;
-(NSString *)collapse;
-(NSUInteger)count;
-(NSString *)formatNick:(NSString *)nick mode:(NSString *)mode colorize:(BOOL)colorize;
-(void)setServer:(Server *)server;
@end
