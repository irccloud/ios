//
//  CollapsedEvents.h
//  IRCCloud
//
//  Created by Sam Steele on 3/7/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

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
}
@property kCollapsedEvent type;
@property kCollapsedMode mode;
@property NSString *nick, *oldNick, *hostname, *msg, *fromMode, *targetMode;
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent;
@end

@interface CollapsedEvents : NSObject {
    NSMutableArray *_data;
}
-(void)clear;
-(BOOL)addEvent:(Event *)event;
-(NSString *)collapse;
@end
