//
//  EventsDataSource.m
//  IRCCloud
//
//  Created by Sam Steele on 2/27/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "EventsDataSource.h"

@implementation Event
-(NSComparisonResult)compare:(Event *)aEvent {
    if(aEvent.eid > _eid)
        return NSOrderedAscending;
    else if(aEvent.eid < _eid)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
-(BOOL)isImportant:(NSString *)bufferType {
    if(_isSelf)
        return NO;
    if(!_type)
        return NO;
    if([_type isEqualToString:@"notice"] && [bufferType isEqualToString:@"console"])
        if(_server && _toChan)
            return NO;
    return ([_type isEqualToString:@"buffer_msg"]
            ||[_type isEqualToString:@"buffer_me_msg"]
            ||[_type isEqualToString:@"notice"]
            ||[_type isEqualToString:@"channel_invite"]
            ||[_type isEqualToString:@"callerid"]
            ||[_type isEqualToString:@"wallops"]);
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, eid: %f, type: %@, msg: %@}", _cid, _bid, _eid, _type, _msg];
}
@end

@implementation EventsDataSource
+(EventsDataSource *)sharedInstance {
    static EventsDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[EventsDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    _events = [[NSMutableDictionary alloc] init];
    _highestEid = 0;
    return self;
}

-(void)clear {
    @synchronized(_events) {
        [_events removeAllObjects];
        _highestEid = 0;
    }
}

-(void)addEvent:(Event *)event {
    @synchronized(_events) {
        NSMutableArray *events = [_events objectForKey:@(event.bid)];
        if(!events) {
            events = [[NSMutableArray alloc] init];
            [_events setObject:events forKey:@(event.bid)];
        }
        [events addObject:event];
    }
}

-(Event *)addJSONObject:(IRCCloudJSONObject *)object {
    Event *event = [self event:object.eid buffer:object.bid];
    if(!event) {
        event = [[Event alloc] init];
        event.bid = object.bid;
        [self addEvent: event];
    }
    
    event.cid = object.cid;
    event.bid = object.bid;
    event.eid = object.eid;
    event.type = object.type;
    event.msg = [object objectForKey:@"msg"];
    event.hostmask = [object objectForKey:@"hostmask"];
    event.from = [object objectForKey:@"from"];
    event.fromMode = [object objectForKey:@"fromMode"];
    if([object objectForKey:@"newnick"])
        event.nick = [object objectForKey:@"newnick"];
    else
        event.nick = [object objectForKey:@"nick"];
    event.oldNick = [object objectForKey:@"oldnick"];
    event.server = [object objectForKey:@"server"];
    event.diff = [object objectForKey:@"diff"];
    event.isHighlight = [[object objectForKey:@"highlight"] boolValue];
    event.isSelf = [[object objectForKey:@"self"] boolValue];
    event.toChan = [[object objectForKey:@"to_chan"] boolValue];
    event.ops = [object objectForKey:@"ops"];
    if([object objectForKey:@"reqid"])
        event.reqId = [[object objectForKey:@"reqid"] intValue];
    else
        event.reqId = -1;
    event.color = [UIColor blackColor];
    event.bgColor = [UIColor whiteColor];
    event.rowType = 0;
    event.formatted = nil;
    event.formattedMsg = nil;
    event.groupMsg = nil;
    event.linkify = YES;
    event.targetMode = nil;
    event.pending = NO;
    
    if(event.eid > _highestEid)
        _highestEid = event.eid;
    
    return event;
}

-(Event *)event:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(_events) {
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid == eid)
                return event;
        }
        return nil;
    }
}

-(void)removeEvent:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(_events) {
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid == eid) {
                [[_events objectForKey:@(bid)] removeObject:event];
                break;
            }
        }
    }
}

-(void)removeEventsForBuffer:(int)bid {
    @synchronized(_events) {
        [_events removeObjectForKey:@(bid)];
    }
}

-(NSArray *)eventsForBuffer:(int)bid {
    @synchronized(_events) {
        return [[_events objectForKey:@(bid)] sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(void)removeEventsBefore:(NSTimeInterval)min_eid buffer:(int)bid {
    @synchronized(_events) {
        NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid < min_eid) {
                [eventsToRemove addObject:event];
            }
        }
        for(Event *event in eventsToRemove) {
            [[_events objectForKey:@(bid)] removeObject:event];
        }
    }
}

-(int)unreadCountForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    @synchronized(_events) {
        int count = 0;
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid > lastSeenEid && [event isImportant:type])
                count++;
        }
        return count;
    }
}

-(int)highlightCountForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    @synchronized(_events) {
        int count = 0;
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid > lastSeenEid && [event isImportant:type] && (event.isHighlight || [type isEqualToString:@"conversation"]))
                count++;
        }
        return count;
    }
}
@end
