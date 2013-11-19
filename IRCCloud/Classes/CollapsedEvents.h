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

typedef enum {
    kCollapsedEventNetSplit,
    kCollapsedEventJoin,
    kCollapsedEventPart,
    kCollapsedEventQuit,
    kCollapsedEventMode,
    kCollapsedEventPopIn,
    kCollapsedEventPopOut,
    kCollapsedEventNickChange
} kCollapsedEvent;

typedef enum {
    kCollapsedModeOwner,
    kCollapsedModeAdmin,
    kCollapsedModeOp,
    kCollapsedModeHalfOp,
    kCollapsedModeVoice,
    
    kCollapsedModeDeOwner,
    kCollapsedModeDeAdmin,
    kCollapsedModeDeOp,
    kCollapsedModeDeHalfOp,
    kCollapsedModeDeVoice,
} kCollapsedMode;

@interface CollapsedEvent : NSObject {
    kCollapsedEvent _type;
    BOOL _modes[10];
    BOOL _netsplit;
    NSString *_nick;
    NSString *_oldNick;
    NSString *_hostname;
    NSString *_msg;
    NSString *_fromMode;
    NSString *_fromNick;
    NSString *_targetMode;
    NSString *_chan;
}
@property kCollapsedEvent type;
@property NSString *nick, *oldNick, *hostname, *msg, *fromMode, *fromNick, *targetMode, *chan;
@property BOOL netsplit;
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent;
-(BOOL)addMode:(NSString *)mode;
-(BOOL)removeMode:(NSString *)mode;
-(NSString *)modes:(BOOL)showSymbol;
-(void)copyModes:(CollapsedEvent *)from;
-(int)modeCount;
@end

@interface CollapsedEvents : NSObject {
    NSMutableArray *_data;
}
-(void)clear;
-(BOOL)addEvent:(Event *)event;
-(NSString *)collapse:(BOOL)showChan;
@end
