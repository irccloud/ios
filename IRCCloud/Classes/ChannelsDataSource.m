//
//  ChannelsDataSource.m
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


#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "BuffersDataSource.h"
#import "ServersDataSource.h"
#import "EventsDataSource.h"

@implementation Channel

+ (BOOL)supportsSecureCoding {
    return YES;
}

-(void)addMode:(NSString *)mode param:(NSString *)param {
    [self removeMode:mode];
    if([mode isEqualToString:@"k"])
        self->_key = YES;
    @synchronized(self->_modes) {
        [self->_modes addObject:@{@"mode":mode,@"param":param}];
    }
}

-(void)removeMode:(NSString *)mode {
    @synchronized(self->_modes) {
        if([mode isEqualToString:@"k"])
            self->_key = NO;
        for(NSDictionary *m in _modes) {
            if([[[m objectForKey:@"mode"] lowercaseString] isEqualToString:mode]) {
                [self->_modes removeObject:m];
                return;
            }
        }
    }
}
-(BOOL)hasMode:(NSString *)mode {
    @synchronized(self->_modes) {
        for(NSDictionary *m in _modes) {
            if([[[m objectForKey:@"mode"] lowercaseString] isEqualToString:mode])
                return YES;
        }
    }
    return NO;
}
-(NSComparisonResult)compare:(Channel *)aChannel {
    return [[self->_name lowercaseString] compare:[aChannel.name lowercaseString]];
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, name: %@, type: %@}", _cid, _bid, _name, _type];
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(self->_cid);
        decodeInt(self->_bid);
        decodeObjectOfClass(NSString.class, self->_name);
        decodeObjectOfClass(NSString.class, self->_topic_text);
        decodeDouble(self->_topic_time);
        decodeObjectOfClass(NSString.class, self->_topic_author);
        decodeObjectOfClass(NSString.class, self->_type);
        decodeObjectOfClass(NSMutableArray.class, self->_modes);
        decodeObjectOfClass(NSString.class, self->_mode);
        decodeDouble(self->_timestamp);
        decodeObjectOfClass(NSString.class, self->_url);
        decodeBool(self->_valid);
        decodeBool(self->_key);
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(self->_cid);
    encodeInt(self->_bid);
    encodeObject(self->_name);
    encodeObject(self->_topic_text);
    encodeDouble(self->_topic_time);
    encodeObject(self->_topic_author);
    encodeObject(self->_type);
    encodeObject(self->_modes);
    encodeObject(self->_mode);
    encodeDouble(self->_timestamp);
    encodeObject(self->_url);
    encodeBool(self->_valid);
    encodeBool(self->_key);
}
@end

@implementation ChannelsDataSource
+(ChannelsDataSource *)sharedInstance {
    static ChannelsDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[ChannelsDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    if(self) {
        [NSKeyedArchiver setClassName:@"IRCCloud.Channel" forClass:Channel.class];
        [NSKeyedUnarchiver setClass:Channel.class forClassName:@"IRCCloud.Channel"];

        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"channels"];
            
            @try {
                NSError* error = nil;
                self->_channels = [[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[NSArray.class, Channel.class]] fromData:[NSData dataWithContentsOfFile:cacheFile] error:&error] mutableCopy];
                if(error)
                    @throw [NSException exceptionWithName:@"NSError" reason:error.debugDescription userInfo:@{ @"NSError" : error }];
            } @catch(NSException *e) {
                CLS_LOG(@"Exception: %@", e);
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[ServersDataSource sharedInstance] clear];
                [[BuffersDataSource sharedInstance] clear];
                [[EventsDataSource sharedInstance] clear];
                [[UsersDataSource sharedInstance] clear];
            }
        }
        if(!_channels)
            self->_channels = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"channels"];
    
    NSArray *channels;
    @synchronized(self->_channels) {
        channels = [self->_channels copy];
    }
    
    @synchronized(self) {
        @try {
            NSError* error = nil;
            [[NSKeyedArchiver archivedDataWithRootObject:channels requiringSecureCoding:YES error:&error] writeToFile:cacheFile atomically:YES];
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
    @synchronized(self->_channels) {
        [self->_channels removeAllObjects];
    }
}

-(void)invalidate {
    @synchronized(self->_channels) {
        for(Channel *channel in _channels) {
            channel.valid = NO;
        }
    }
}

-(void)addChannel:(Channel *)channel {
    @synchronized(self->_channels) {
        [self->_channels addObject:channel];
    }
}

-(void)removeChannelForBuffer:(int)bid {
    @synchronized(self->_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            [self->_channels removeObject:channel];
    }
}

-(void)updateTopic:(NSString *)text time:(NSTimeInterval)time author:(NSString *)author buffer:(int)bid {
    @synchronized(self->_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel) {
            channel.topic_text = text;
            channel.topic_time = time;
            channel.topic_author = author;
        }
    }
}

-(void)updateMode:(NSString *)mode buffer:(int)bid ops:(NSDictionary *)ops {
    @synchronized(self->_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel) {
            NSArray *add = [ops objectForKey:@"add"];
            for(NSDictionary *m in add) {
                [channel addMode:[m objectForKey:@"mode"] param:[m objectForKey:@"param"]];
            }
            NSArray *remove = [ops objectForKey:@"remove"];
            for(NSDictionary *m in remove) {
                [channel removeMode:[m objectForKey:@"mode"]];
            }
            channel.mode = mode;
        }
    }
}

-(void)updateURL:(NSString *)url buffer:(int)bid {
    @synchronized(self->_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            channel.url = url;
    }
}

-(void)updateTimestamp:(NSTimeInterval)timestamp buffer:(int)bid {
    @synchronized(self->_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            channel.timestamp = timestamp;
    }
}

-(Channel *)channelForBuffer:(int)bid {
    @synchronized(self->_channels) {
        for(int i = 0; i < _channels.count; i++) {
            Channel *channel = [self->_channels objectAtIndex:i];
            if(channel.bid == bid)
                return channel;
        }
        return nil;
    }
}

-(NSArray *)channelsForServer:(int)cid {
    NSMutableArray *channels = [[NSMutableArray alloc] init];
    @synchronized(self->_channels) {
        for(int i = 0; i < _channels.count; i++) {
            Channel *channel = [self->_channels objectAtIndex:i];
            if(channel.cid == cid)
                [channels addObject:channel];
        }
    }
    return channels;
}

-(NSArray *)channels {
    return _channels;
}

-(void)purgeInvalidChannels {
    CLS_LOG(@"Cleaning up invalid channels");
    NSArray *copy;
    @synchronized(self->_channels) {
        copy = self->_channels.copy;
    }
    for(Channel *channel in copy) {
        if(!channel.valid) {
            CLS_LOG(@"Removing invalid channel: %@", channel.name);
            [self->_channels removeObject:channel];
            [[UsersDataSource sharedInstance] removeUsersForBuffer:channel.bid];
        }
    }
}
@end
