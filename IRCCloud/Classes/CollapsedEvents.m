//
//  CollapsedEvents.m
//  IRCCloud
//
//  Created by Sam Steele on 3/7/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "CollapsedEvents.h"
#import "ColorFormatter.h"

@implementation CollapsedEvent
-(NSComparisonResult)compare:(CollapsedEvent *)aEvent {
    if(_type == aEvent.type)
        return [_nick compare:aEvent.nick];
    else if(_type < aEvent.type)
        return NSOrderedAscending;
    else
        return NSOrderedDescending;
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{type: %i, nick: %@, oldNick: %@, hostmask: %@, msg: %@}", _type, _nick, _oldNick, _hostname, _msg];
}
@end

@implementation CollapsedEvents
-(id)init {
    self = [super init];
    if(self) {
        _data = [[NSMutableArray alloc] init];
    }
    return self;
}
-(void)clear {
    @synchronized(_data) {
        [_data removeAllObjects];
    }
}
-(CollapsedEvent *)findEvent:(NSString *)nick {
    @synchronized(_data) {
        for(CollapsedEvent *event in _data) {
            if([[event.nick lowercaseString] isEqualToString:[nick lowercaseString]])
                return event;
        }
        return nil;
    }
}
-(void)addCollapsedEvent:(CollapsedEvent *)event {
    @synchronized(_data) {
        CollapsedEvent *e = nil;
        
        if(event.type < kCollapsedEventNickChange) {
            if(event.oldNick.length > 0 && event.type != kCollapsedEventMode) {
                e = [self findEvent:event.oldNick];
                if(e)
                    e.nick = event.nick;
            }
            
            if(!e)
                e = [self findEvent:event.nick];
            
            if(e) {
                if(e.type == kCollapsedEventMode) {
                    e.type = event.type;
                    e.msg = event.msg;
                    if(event.fromMode)
                        e.fromMode = event.fromMode;
                    if(event.targetMode)
                        e.targetMode = event.targetMode;
                } else if(event.type == kCollapsedEventMode) {
                    e.fromMode = event.targetMode;
                } else if(event.type == e.type) {
                } else if(event.type == kCollapsedEventJoin) {
                    e.type = kCollapsedEventPopOut;
                    e.fromMode = event.fromMode;
                } else if(e.type == kCollapsedEventPopOut) {
                    e.type = event.type;
                } else {
                    e.type = kCollapsedEventPopIn;
                }
                if(event.mode > 0)
                    e.mode = event.mode;
            } else {
                [_data addObject:event];
            }
        } else {
            if(event.type == kCollapsedEventNickChange) {
                for(CollapsedEvent *e1 in _data) {
                    if(e1.type == kCollapsedEventNickChange && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        if([[e1.oldNick lowercaseString] isEqualToString:[event.nick lowercaseString]]) {
                            [_data removeObject:e1];
                        } else {
                            e1.nick = event.nick;
                        }
                        return;
                    }
                    if((e1.type == kCollapsedEventJoin || e1.type == kCollapsedEventPopOut) && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        e1.oldNick = event.oldNick;
                        e1.nick = event.nick;
                        return;
                    }
                    if((e1.type == kCollapsedEventQuit || e1.type == kCollapsedEventPart) && [[e1.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                        e1.type = kCollapsedEventPopOut;
                        for(CollapsedEvent *e2 in _data) {
                            if(e2.type == kCollapsedEventJoin && [[e2.nick lowercaseString] isEqualToString:[event.oldNick lowercaseString]]) {
                                [_data removeObject:e2];
                                break;
                            }
                        }
                        return;
                    }
                }
                [_data addObject:event];
            } else {
                [_data addObject:event];
            }
        }
    }
}
-(BOOL)addEvent:(Event *)event {
    @synchronized(_data) {
        CollapsedEvent *c;
        if([event.type hasSuffix:@"user_channel_mode"]) {
            if(event.ops) {
                for(NSDictionary *op in [event.ops objectForKey:@"add"]) {
                    c = [[CollapsedEvent alloc] init];
                    c.type = kCollapsedEventMode;
                    c.nick = [op objectForKey:@"param"];
                    c.oldNick = event.from;
                    c.hostname = event.hostmask;
                    c.fromMode = event.fromMode;
                    c.targetMode = event.targetMode;
                    NSString *mode = [op objectForKey:@"mode"];
                    if([mode rangeOfString:@"q"].location != NSNotFound)
                        c.mode = kCollapsedModeAdmin;
                    else if([mode rangeOfString:@"a"].location != NSNotFound)
                        c.mode = kCollapsedModeOwner;
                    else if([mode rangeOfString:@"o"].location != NSNotFound)
                        c.mode = kCollapsedModeOp;
                    else if([mode rangeOfString:@"h"].location != NSNotFound)
                        c.mode = kCollapsedModeHalfOp;
                    else if([mode rangeOfString:@"v"].location != NSNotFound)
                        c.mode = kCollapsedModeVoice;
                    else
                        return NO;
                    [self addCollapsedEvent:c];
                }
                for(NSDictionary *op in [event.ops objectForKey:@"remove"]) {
                    c = [[CollapsedEvent alloc] init];
                    c.type = kCollapsedEventMode;
                    c.nick = [op objectForKey:@"param"];
                    c.oldNick = event.from;
                    c.hostname = event.hostmask;
                    c.fromMode = event.fromMode;
                    c.targetMode = event.targetMode;
                    NSString *mode = [op objectForKey:@"mode"];
                    if([mode rangeOfString:@"q"].location != NSNotFound)
                        c.mode = kCollapsedModeDeAdmin;
                    else if([mode rangeOfString:@"a"].location != NSNotFound)
                        c.mode = kCollapsedModeDeOwner;
                    else if([mode rangeOfString:@"o"].location != NSNotFound)
                        c.mode = kCollapsedModeDeOp;
                    else if([mode rangeOfString:@"h"].location != NSNotFound)
                        c.mode = kCollapsedModeDeHalfOp;
                    else if([mode rangeOfString:@"v"].location != NSNotFound)
                        c.mode = kCollapsedModeDeVoice;
                    else
                        return NO;
                    [self addCollapsedEvent:c];
                }
            }
        } else {
            c = [[CollapsedEvent alloc] init];
            c.nick = event.nick;
            c.hostname = event.hostmask;
            c.fromMode = event.fromMode;
            if([event.type hasSuffix:@"joined_channel"]) {
                c.type = kCollapsedEventJoin;
            } else if([event.type hasSuffix:@"parted_channel"]) {
                c.type = kCollapsedEventPart;
                c.msg = event.msg;
            } else if([event.type hasSuffix:@"quit"]) {
                c.type = kCollapsedEventQuit;
                c.msg = event.msg;
            } else if([event.type hasSuffix:@"nickchange"]) {
                c.type = kCollapsedEventNickChange;
                c.oldNick = event.oldNick;
            } else {
                return NO;
            }
            [self addCollapsedEvent:c];
        }
        return YES;
    }
}
-(NSString *)was:(CollapsedEvent *)e {
    NSString *output = @"";
    
    if(e.oldNick && e.type != kCollapsedEventMode)
        output = [NSString stringWithFormat:@"was %@", e.oldNick];
    if(e.mode > 0) {
        if(output.length > 0)
            output = [output stringByAppendingString:@"; "];
        switch(e.mode) {
            case kCollapsedModeOwner:
                output = [output stringByAppendingString:@"promoted to owner"];
                break;
            case kCollapsedModeDeOwner:
                output = [output stringByAppendingString:@"demoted from owner"];
                break;
            case kCollapsedModeAdmin:
                output = [output stringByAppendingString:@"promoted to admin"];
                break;
            case kCollapsedModeDeAdmin:
                output = [output stringByAppendingString:@"demoted from admin"];
                break;
            case kCollapsedModeOp:
                output = [output stringByAppendingString:@"opped"];
                break;
            case kCollapsedModeDeOp:
                output = [output stringByAppendingString:@"de-opped"];
                break;
            case kCollapsedModeHalfOp:
                output = [output stringByAppendingString:@"halfopped"];
                break;
            case kCollapsedModeDeHalfOp:
                output = [output stringByAppendingString:@"de-halfopped"];
                break;
            case kCollapsedModeVoice:
                output = [output stringByAppendingString:@"voiced"];
                break;
            case kCollapsedModeDeVoice:
                output = [output stringByAppendingString:@"devoiced"];
                break;
        }
    }
    
    if(output.length)
        output = [NSString stringWithFormat:@" (%@)", output];
    
    return output;
}
-(NSString *)collapse {
    @synchronized(_data) {
        NSString *output;
        
        if(_data.count == 0)
            return nil;
        
        if(_data.count == 1) {
            CollapsedEvent *e = [_data objectAtIndex:0];
            switch(e.type) {
                case kCollapsedEventMode:
                    output = [NSString stringWithFormat:@"%@ was ", [ColorFormatter formatNick:e.nick mode:e.targetMode]];
                    switch(e.mode) {
                        case kCollapsedModeOwner:
                            output = [output stringByAppendingFormat:@"promoted to owner (%cE7AA00+q%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeDeOwner:
                            output = [output stringByAppendingFormat:@"demoted from owner (%cE7AA00-q%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeAdmin:
                            output = [output stringByAppendingFormat:@"promoted to admin (%c6500A5+a%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeDeAdmin:
                            output = [output stringByAppendingFormat:@"demoted from admin (%c6500A5-a%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeOp:
                            output = [output stringByAppendingFormat:@"opped (%cBA1719+o%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeDeOp:
                            output = [output stringByAppendingFormat:@"de-opped (%cBA1719-o%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeHalfOp:
                            output = [output stringByAppendingFormat:@"halfopped (%cB55900+h%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeDeHalfOp:
                            output = [output stringByAppendingFormat:@"de-halfopped (%cB55900-h%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeVoice:
                            output = [output stringByAppendingFormat:@"voiced (%c25B100+v%c)", COLOR_RGB, CLEAR];
                            break;
                        case kCollapsedModeDeVoice:
                            output = [output stringByAppendingFormat:@"devoiced (%c25B100-v%c)", COLOR_RGB, CLEAR];
                            break;
                    }
                    if(e.oldNick)
                        output = [output stringByAppendingFormat:@" by %@", [ColorFormatter formatNick:e.oldNick mode:e.fromMode]];
                    break;
                case kCollapsedEventJoin:
                    output = [NSString stringWithFormat:@"→ %@ joined (%@)", [ColorFormatter formatNick:e.nick mode:e.fromMode], e.hostname];
                    break;
                case kCollapsedEventPart:
                    output = [NSString stringWithFormat:@"← %@ left (%@)", [ColorFormatter formatNick:e.nick mode:e.fromMode], e.hostname];
                    if(e.msg.length > 0)
                        output = [output stringByAppendingFormat:@": %@", e.msg];
                    break;
                case kCollapsedEventQuit:
                    output = [NSString stringWithFormat:@"⇐ %@ quit", [ColorFormatter formatNick:e.nick mode:e.fromMode]];
                    if(e.hostname.length > 0)
                        output = [output stringByAppendingFormat:@" (%@)", e.hostname];
                    if(e.msg.length > 0)
                        output = [output stringByAppendingFormat:@": %@", e.msg];
                    break;
                case kCollapsedEventNickChange:
                    output = [NSString stringWithFormat:@"%@ → %@", e.oldNick, [ColorFormatter formatNick:e.nick mode:e.fromMode]];
                    break;
                case kCollapsedEventPopIn:
                    output = [NSString stringWithFormat:@"↔ %@ popped in", [ColorFormatter formatNick:e.nick mode:e.fromMode]];
                    break;
                case kCollapsedEventPopOut:
                    output = [NSString stringWithFormat:@"↔ %@ nipped out", [ColorFormatter formatNick:e.nick mode:e.fromMode]];
                    break;
            }
        } else {
            [_data sortUsingSelector:@selector(compare:)];
            NSEnumerator *i = [_data objectEnumerator];
            CollapsedEvent *last = nil;
            CollapsedEvent *next = [i nextObject];
            CollapsedEvent *e;
            int groupcount = 0;
            NSMutableString *message = [[NSMutableString alloc] init];
            
            while(next) {
                e = next;
                
                next = [i nextObject];
                
                if(output.length > 0 && e.type < kCollapsedEventNickChange && ((next == nil || next.type != e.type) && last != nil && last.type == e.type)) {
					if(groupcount == 1) {
                        [message deleteCharactersInRange:NSMakeRange(message.length - 2, 2)];
                        [message appendString:@" "];
                    }
                    [message appendString:@"and "];
				}
                
                if(last == nil || last.type != e.type) {
                    switch(e.type) {
                        case kCollapsedEventMode:
                            if(message.length)
                                [message appendString:@"• "];
                            [message appendString:@"mode: "];
                            break;
                        case kCollapsedEventJoin:
                            [message appendString:@"→ "];
                            break;
                        case kCollapsedEventPart:
                            [message appendString:@"← "];
                            break;
                        case kCollapsedEventQuit:
                            [message appendString:@"⇐ "];
                            break;
                        case kCollapsedEventNickChange:
                            if(message.length)
                                [message appendString:@"• "];
                            break;
                        case kCollapsedEventPopIn:
                        case kCollapsedEventPopOut:
                            [message appendString:@"↔ "];
                            break;
                    }
                }
                
                if(e.type == kCollapsedEventNickChange) {
                    [message appendFormat:@"%@ → %@", e.oldNick, [ColorFormatter formatNick:e.nick mode:e.fromMode]];
                    NSString *oldNick = e.oldNick;
                    e.oldNick = nil;
                    [message appendString:[self was:e]];
                    e.oldNick = oldNick;
                } else {
                    [message appendString:[ColorFormatter formatNick:e.nick mode:(e.type == kCollapsedEventMode)?e.targetMode:e.fromMode]];
                    [message appendString:[self was:e]];
                }
                
                if(next == nil || next.type != e.type) {
                    switch(e.type) {
                        case kCollapsedEventJoin:
                            [message appendString:@" joined"];
                            break;
                        case kCollapsedEventPart:
                            [message appendString:@" left"];
                            break;
                        case kCollapsedEventQuit:
                            [message appendString:@" quit"];
                        case kCollapsedEventPopIn:
                            [message appendString:@" popped in"];
                            break;
                        case kCollapsedEventPopOut:
                            [message appendString:@" nipped out"];
                            break;
                        default:
                            break;
                    }
                }
                
                if(next != nil && next.type == e.type) {
                    [message appendString:@", "];
                    groupcount++;
                } else if(next != nil) {
                    [message appendString:@" "];
                    groupcount = 0;
                }
                
                last = e;
            }
            output = message;
        }
        
        return output;
    }
}
@end
