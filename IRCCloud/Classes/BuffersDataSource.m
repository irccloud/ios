//
//  BuffersDataSource.m
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


#import "BuffersDataSource.h"
#import "ChannelsDataSource.h"
#import "EventsDataSource.h"
#import "UsersDataSource.h"

@implementation Buffer
-(NSComparisonResult)compare:(Buffer *)aBuffer {
    int joinedLeft = 1, joinedRight = 1;
    if([_type isEqualToString:@"channel"])
        joinedLeft = [[ChannelsDataSource sharedInstance] channelForBuffer:_bid] != nil;
    if([[aBuffer type] isEqualToString:@"channel"])
        joinedRight = [[ChannelsDataSource sharedInstance] channelForBuffer:aBuffer.bid] != nil;
    if([_type isEqualToString:@"conversation"] && [[aBuffer type] isEqualToString:@"channel"])
        return NSOrderedDescending;
    else if([_type isEqualToString:@"channel"] && [[aBuffer type] isEqualToString:@"conversation"])
        return NSOrderedAscending;
    else if(joinedLeft > joinedRight)
        return NSOrderedAscending;
    else if(joinedLeft < joinedRight)
        return NSOrderedDescending;
    else
        return [[_name lowercaseString] compare:aBuffer.name];
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, name: %@, type: %@}", _cid, _bid, _name, _type];
}
@end

@implementation BuffersDataSource
+(BuffersDataSource *)sharedInstance {
    static BuffersDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[BuffersDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    _buffers = [[NSMutableArray alloc] init];
    return self;
}

-(void)clear {
    @synchronized(_buffers) {
        [_buffers removeAllObjects];
        NSLog(@"Buffers list cleared: %@",[NSThread callStackSymbols]);
    }
}

-(int)count {
    @synchronized(_buffers) {
        return _buffers.count;
    }
}

-(int)firstBid {
    @synchronized(_buffers) {
        if(_buffers.count)
            return ((Buffer *)[_buffers objectAtIndex:0]).bid;
        else
            return -1;
    }
}

-(void)addBuffer:(Buffer *)buffer {
    @synchronized(_buffers) {
        [_buffers addObject:buffer];
    }
}

-(Buffer *)getBuffer:(int)bid {
    @synchronized(_buffers) {
        for(Buffer *buffer in _buffers) {
            if(buffer.bid == bid)
                return buffer;
        }
    }
    return nil;
}

-(Buffer *)getBufferWithName:(NSString *)name server:(int)cid {
    @synchronized(_buffers) {
        for(Buffer *buffer in _buffers) {
            if(buffer.cid == cid && [[buffer.name lowercaseString] isEqualToString:[name lowercaseString]])
                return buffer;
        }
        return nil;
    }
}

-(NSArray *)getBuffersForServer:(int)cid {
    @synchronized(_buffers) {
        NSMutableArray *buffers = [[NSMutableArray alloc] init];
        for(Buffer *buffer in _buffers) {
            if(buffer.cid == cid)
                [buffers addObject:buffer];
        }
        return [buffers sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(NSArray *)getBuffers {
    @synchronized(_buffers) {
        return [_buffers sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(void)updateLastSeenEID:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            buffer.last_seen_eid = eid;
    }
}

-(void)updateArchived:(int)archived buffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            buffer.archived = archived;
    }
}

-(void)updateTimeout:(int)timeout buffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            buffer.timeout = timeout;
    }
}

-(void)updateName:(NSString *)name buffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            buffer.name = name;
    }
}

-(void)updateAway:(NSString *)away buffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            buffer.away_msg = away;
    }
}

-(void)removeBuffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer)
            [_buffers removeObject:buffer];
    }
}

-(void)removeAllDataForBuffer:(int)bid {
    @synchronized(_buffers) {
        Buffer *buffer = [self getBuffer:bid];
        if(buffer) {
            [_buffers removeObject:buffer];
            [[ChannelsDataSource sharedInstance] removeChannelForBuffer:bid];
            [[EventsDataSource sharedInstance] removeEventsForBuffer:bid];
            [[UsersDataSource sharedInstance] removeUsersForBuffer:bid];
        }
    }
}
@end
