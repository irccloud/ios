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
    kCollapsedEventJoin,
    kCollapsedEventPart,
    kCollapsedEventQuit,
    kCollapsedEventMode,
    kCollapsedEventPopIn,
    kCollapsedEventPopOut,
    kCollapsedEventNickChange,
} kCollapsedEvent;

typedef enum {
    kCollapsedModeOwner = 1,
    kCollapsedModeDeOwner,
    kCollapsedModeAdmin,
    kCollapsedModeDeAdmin,
    kCollapsedModeOp,
    kCollapsedModeDeOp,
    kCollapsedModeHalfOp,
    kCollapsedModeDeHalfOp,
    kCollapsedModeVoice,
    kCollapsedModeDeVoice,
} kCollapsedMode;

@interface CollapsedEvent : NSObject {
    kCollapsedEvent _type;
    kCollapsedMode _mode;
    NSString *_nick;
    NSString *_oldNick;
    NSString *_hostname;
    NSString *_msg;
    NSString *_fromMode;
    NSString *_targetMode;
    NSString *_chan;
}
@property kCollapsedEvent type;
@property kCollapsedMode mode;
@property NSString *nick, *oldNick, *hostname, *msg, *fromMode, *targetMode, *chan;
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent;
@end

@interface CollapsedEvents : NSObject {
    NSMutableArray *_data;
}
-(void)clear;
-(BOOL)addEvent:(Event *)event;
-(NSString *)collapse:(BOOL)showChan;
@end
