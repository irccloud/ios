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
#import "ServersDataSource.h"

NSString *__DEFAULT_CHANTYPES__;

@implementation Buffer

+ (BOOL)supportsSecureCoding {
    return YES;
}

-(NSComparisonResult)compare:(Buffer *)aBuffer {
    @synchronized (self) {
        int joinedLeft = 1, joinedRight = 1;
        if(self->_cid < aBuffer.cid)
            return NSOrderedAscending;
        if(self->_cid > aBuffer.cid)
            return NSOrderedDescending;
        if([self->_type isEqualToString:@"console"])
            return NSOrderedAscending;
        if([aBuffer.type isEqualToString:@"console"])
            return NSOrderedDescending;
        if(self->_bid == aBuffer.bid)
            return NSOrderedSame;
        if([self->_type isEqualToString:@"channel"] || self.isMPDM)
            joinedLeft = [[ChannelsDataSource sharedInstance] channelForBuffer:self->_bid] != nil;
        if([[aBuffer type] isEqualToString:@"channel"] || aBuffer.isMPDM)
            joinedRight = [[ChannelsDataSource sharedInstance] channelForBuffer:aBuffer.bid] != nil;
        
        NSString *typeLeft = self.isMPDM ? @"conversation" : _type;
        NSString *typeRight = aBuffer.isMPDM ? @"conversation" : aBuffer.type;
        if([typeLeft isEqualToString:@"conversation"] && [typeRight isEqualToString:@"channel"])
            return NSOrderedDescending;
        else if([typeLeft isEqualToString:@"channel"] && [typeRight isEqualToString:@"conversation"])
            return NSOrderedAscending;
        else if(joinedLeft > joinedRight)
            return NSOrderedAscending;
        else if(joinedLeft < joinedRight)
            return NSOrderedDescending;
        else {
            NSString *nameLeft = self.normalizedName;
            NSString *nameRight = aBuffer.normalizedName;
            
            if([nameLeft compare:nameRight] == NSOrderedSame)
                return (self->_bid < aBuffer.bid)?NSOrderedAscending:NSOrderedDescending;
            else
                return [nameLeft localizedStandardCompare:nameRight];
        }
    }
}
-(NSString *)normalizedName {
    if(self->_serverIsSlack)
        return self.displayName.lowercaseString;
    
    if(self->_chantypes == nil || _chantypes == __DEFAULT_CHANTYPES__) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_cid];
        if(s) {
            self->_chantypes = s.CHANTYPES;
            if(self->_chantypes == nil || _chantypes.length == 0)
                self->_chantypes = __DEFAULT_CHANTYPES__;
        }
    }
    NSRegularExpression *r = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^[%@]+", _chantypes] options:NSRegularExpressionCaseInsensitive error:nil];
    return [r stringByReplacingMatchesInString:[self->_name lowercaseString] options:0 range:NSMakeRange(0, _name.length) withTemplate:@""];
}
-(BOOL)isMPDM {
    if(!_serverIsSlack)
        return NO;
    
    static NSPredicate *p;
    if(!p)
        p = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"#mpdm-(.*)-\\d"];

    return [p evaluateWithObject:self->_name];
}
-(NSString *)name {
    return _name;
}
-(void)setName:(NSString *)name {
    self->_name = name;
    self->_displayName = nil;
}
-(NSString *)displayName {
    if(self.isMPDM) {
        if(!_displayName) {
            NSString *selfNick = [[ServersDataSource sharedInstance] getServer:self->_cid].nick.lowercaseString;
            NSMutableArray *names = [self->_name componentsSeparatedByString:@"-"].mutableCopy;
            [names removeObjectAtIndex:0];
            [names removeObjectAtIndex:names.count - 1];
            for(int i = 0; i < names.count; i++) {
                NSString *name = [[names objectAtIndex:i] lowercaseString];
                if([name length] == 0 || [selfNick isEqualToString:name]) {
                    [names removeObjectAtIndex:i];
                    i--;
                }
            }
            [names sortUsingComparator:^NSComparisonResult(NSString *left, NSString *right) {
                return [left.lowercaseString localizedStandardCompare:right.lowercaseString];
            }];
            self->_displayName = [names componentsJoinedByString:@", "];
        }
        return _displayName;
    } else {
        return _name;
    }
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, name: %@, type: %@}", _cid, _bid, _name, _type];
}
-(NSString *)accessibilityValue {
    if(self.isMPDM)
        return self.displayName;
    
    if(self->_chantypes == nil || _chantypes == __DEFAULT_CHANTYPES__) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_cid];
        if(s) {
            self->_chantypes = s.CHANTYPES;
            if(self->_chantypes == nil || _chantypes.length == 0)
                self->_chantypes = __DEFAULT_CHANTYPES__;
        }
    }
    NSRegularExpression *r = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^[%@]+", _chantypes] options:NSRegularExpressionCaseInsensitive error:nil];
    return [r stringByReplacingMatchesInString:self->_name options:0 range:NSMakeRange(0, _name.length) withTemplate:@""];
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(self->_bid);
        decodeInt(self->_cid);
        decodeDouble(self->_min_eid);
        decodeDouble(self->_last_seen_eid);
        decodeObjectOfClass(NSString.class, self->_name);
        decodeObjectOfClass(NSString.class, self->_type);
        decodeInt(self->_archived);
        decodeInt(self->_deferred);
        decodeObjectOfClass(NSString.class, self->_away_msg);
        decodeBool(self->_valid);
        decodeObjectOfClass(NSString.class, self->_draft);
        decodeObjectOfClass(NSString.class, self->_chantypes);
        decodeBool(self->_scrolledUp);
        decodeDouble(self->_scrolledUpFrom);
        decodeFloat(self->_savedScrollOffset);
        decodeObjectOfClass(Buffer.class, self->_lastBuffer);
        decodeObjectOfClass(Buffer.class, self->_nextBuffer);
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(self->_bid);
    encodeInt(self->_cid);
    encodeDouble(self->_min_eid);
    encodeDouble(self->_last_seen_eid);
    encodeObject(self->_name);
    encodeObject(self->_type);
    encodeInt(self->_archived);
    encodeInt(self->_deferred);
    encodeObject(self->_away_msg);
    encodeBool(self->_valid);
    encodeObject(self->_draft);
    encodeObject(self->_chantypes);
    encodeBool(self->_scrolledUp);
    encodeDouble(self->_scrolledUpFrom);
    encodeFloat(self->_savedScrollOffset);
    encodeObject(self->_lastBuffer);
    encodeObject(self->_nextBuffer);
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
    if(self) {
        __DEFAULT_CHANTYPES__ = @"#&!+";
        [NSKeyedArchiver setClassName:@"IRCCloud.Buffer" forClass:Buffer.class];
        [NSKeyedUnarchiver setClass:Buffer.class forClassName:@"IRCCloud.Buffer"];

        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"buffers"];
            
            @try {
                NSError* error = nil;
                self->_buffers = [[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSDictionary.class, NSArray.class, Buffer.class,nil] fromData:[NSData dataWithContentsOfFile:cacheFile] error:&error] mutableCopy];
                if(error)
                    @throw [NSException exceptionWithName:@"NSError" reason:error.debugDescription userInfo:@{ @"NSError" : error }];
            } @catch(NSException *e) {
                CLS_LOG(@"Exception: %@", e);
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[ServersDataSource sharedInstance] clear];
                [[ChannelsDataSource sharedInstance] clear];
                [[EventsDataSource sharedInstance] clear];
                [[UsersDataSource sharedInstance] clear];
            }
        }
        
        if(!_buffers)
            self->_buffers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"buffers"];

    NSArray *buffers;
    @synchronized(self->_buffers) {
        buffers = [self->_buffers copy];
    }
    
    @synchronized(self) {
        @try {
            NSError* error = nil;
            [[NSKeyedArchiver archivedDataWithRootObject:buffers requiringSecureCoding:YES error:&error] writeToFile:cacheFile atomically:YES];
            if(error)
                CLS_LOG(@"Error archiving: %@", error);
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
}

-(void)clear {
    @synchronized(self->_buffers) {
        [self->_buffers removeAllObjects];
    }
}

-(NSUInteger)count {
    @synchronized(self->_buffers) {
        return _buffers.count;
    }
}

-(int)firstBid {
    @synchronized(self->_buffers) {
        if(self->_buffers.count)
            return ((Buffer *)[self->_buffers.allValues objectAtIndex:0]).bid;
        else
            return -1;
    }
}

-(void)addBuffer:(Buffer *)buffer {
    @synchronized(self->_buffers) {
        [self->_buffers setObject:buffer forKey:@(buffer.bid)];
    }
}

-(Buffer *)getBuffer:(int)bid {
    return [self->_buffers objectForKey:@(bid)];
}

-(Buffer *)getBufferWithName:(NSString *)name server:(int)cid {
    NSArray *copy;
    @synchronized(self->_buffers) {
        copy = self->_buffers.allValues;
    }
    for(Buffer *buffer in copy) {
        if(buffer.cid == cid && [[buffer.name lowercaseString] isEqualToString:[name lowercaseString]])
            return buffer;
    }
    return nil;
}

-(NSArray *)getBuffersForServer:(int)cid {
    @synchronized (self) {
        NSMutableArray *buffers = [[NSMutableArray alloc] init];
        NSArray *copy;
        @synchronized(self->_buffers) {
            copy = self->_buffers.allValues;
        }
        for(Buffer *buffer in copy) {
            if(buffer.cid == cid)
                [buffers addObject:buffer];
        }
        return [buffers sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(NSArray *)getBuffers {
    @synchronized(self->_buffers) {
        return _buffers.allValues;
    }
}

-(void)updateLastSeenEID:(NSTimeInterval)eid buffer:(int)bid {
    Buffer *buffer = [self getBuffer:bid];
    if(buffer)
        buffer.last_seen_eid = eid;
}

-(void)updateArchived:(int)archived buffer:(int)bid {
    Buffer *buffer = [self getBuffer:bid];
    if(buffer) {
        buffer.archived = archived;
        if(!archived) {
            Server *s = [[ServersDataSource sharedInstance] getServer:buffer.cid];
            if(s.deferred_archives)
                s.deferred_archives--;
        }
    }
}

-(void)updateTimeout:(int)timeout buffer:(int)bid {
    Buffer *buffer = [self getBuffer:bid];
    if(buffer)
        buffer.timeout = timeout;
}

-(void)updateName:(NSString *)name buffer:(int)bid {
    Buffer *buffer = [self getBuffer:bid];
    if(buffer)
        buffer.name = name;
}

-(void)updateAway:(NSString *)away nick:(NSString *)nick server:(int)cid {
    Buffer *buffer = [self getBufferWithName:nick server:cid];
    if(buffer)
        buffer.away_msg = away;
}

-(void)removeBuffer:(int)bid {
    @synchronized(self->_buffers) {
        NSArray *copy;
        @synchronized(self->_buffers) {
            copy = self->_buffers.allValues;
        }
        for(Buffer *buffer in copy) {
            if(buffer.lastBuffer.bid == bid)
                buffer.lastBuffer = buffer.lastBuffer.lastBuffer;
            if(buffer.nextBuffer.bid == bid)
                buffer.nextBuffer = buffer.nextBuffer.nextBuffer;
        }
        [self->_buffers removeObjectForKey:@(bid)];
    }
}

-(void)removeAllDataForBuffer:(int)bid {
    Buffer *buffer = [self getBuffer:bid];
    if(buffer) {
        [self removeBuffer:bid];
        [[ChannelsDataSource sharedInstance] removeChannelForBuffer:bid];
        [[EventsDataSource sharedInstance] removeEventsForBuffer:bid];
        [[UsersDataSource sharedInstance] removeUsersForBuffer:bid];
    }
}

-(void)invalidate {
    NSArray *copy;
    @synchronized(self->_buffers) {
        copy = self->_buffers.allValues;
    }
    for(Buffer *buffer in copy) {
        buffer.valid = NO;
    }
}

-(void)purgeInvalidBIDs {
    CLS_LOG(@"Cleaning up invalid BIDs");
    NSArray *copy;
    @synchronized(self->_buffers) {
        copy = self->_buffers.allValues;
    }
    for(Buffer *buffer in copy) {
        if(!buffer.valid) {
            CLS_LOG(@"Removing buffer: bid%i", buffer.bid);
            [[ChannelsDataSource sharedInstance] removeChannelForBuffer:buffer.bid];
            [[EventsDataSource sharedInstance] removeEventsForBuffer:buffer.bid];
            [[UsersDataSource sharedInstance] removeUsersForBuffer:buffer.bid];
            if([buffer.type isEqualToString:@"console"]) {
                CLS_LOG(@"Removing CID: cid%i", buffer.cid);
                [[ServersDataSource sharedInstance] removeServer:buffer.cid];
            }
            [self removeBuffer:buffer.bid];
        }
    }
}
@end
