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
-(void)addMode:(NSString *)mode param:(NSString *)param {
    [self removeMode:mode];
    if([mode isEqualToString:@"k"])
        _key = YES;
    @synchronized(_modes) {
        [_modes addObject:@{@"mode":mode,@"param":param}];
    }
}

-(void)removeMode:(NSString *)mode {
    @synchronized(_modes) {
        if([mode isEqualToString:@"k"])
            _key = NO;
        for(NSDictionary *m in _modes) {
            if([[[m objectForKey:@"mode"] lowercaseString] isEqualToString:mode]) {
                [_modes removeObject:m];
                return;
            }
        }
    }
}
-(BOOL)hasMode:(NSString *)mode {
    @synchronized(_modes) {
        for(NSDictionary *m in _modes) {
            if([[[m objectForKey:@"mode"] lowercaseString] isEqualToString:mode])
                return YES;
        }
    }
    return NO;
}
-(NSComparisonResult)compare:(Channel *)aChannel {
    return [[_name lowercaseString] compare:[aChannel.name lowercaseString]];
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(_cid);
        decodeInt(_bid);
        decodeObject(_name);
        decodeObject(_topic_text);
        decodeDouble(_topic_time);
        decodeObject(_topic_author);
        decodeObject(_type);
        decodeObject(_modes);
        decodeObject(_mode);
        decodeDouble(_timestamp);
        decodeObject(_url);
        decodeBool(_valid);
        decodeBool(_key);
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(_cid);
    encodeInt(_bid);
    encodeObject(_name);
    encodeObject(_topic_text);
    encodeDouble(_topic_time);
    encodeObject(_topic_author);
    encodeObject(_type);
    encodeObject(_modes);
    encodeObject(_mode);
    encodeDouble(_timestamp);
    encodeObject(_url);
    encodeBool(_valid);
    encodeBool(_key);
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
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"channels"];
            
            @try {
                _channels = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
            } @catch(NSException *e) {
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[ServersDataSource sharedInstance] clear];
                [[BuffersDataSource sharedInstance] clear];
                [[EventsDataSource sharedInstance] clear];
                [[UsersDataSource sharedInstance] clear];
            }
        }
        if(!_channels)
            _channels = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"channels"];
    
    NSArray *channels;
    @synchronized(_channels) {
        channels = [_channels copy];
    }
    
    @synchronized(self) {
        @try {
            [NSKeyedArchiver archiveRootObject:channels toFile:cacheFile];
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
}

-(void)clear {
    @synchronized(_channels) {
        [_channels removeAllObjects];
    }
}

-(void)invalidate {
    @synchronized(_channels) {
        for(Channel *channel in _channels) {
            channel.valid = NO;
        }
    }
}

-(void)addChannel:(Channel *)channel {
    @synchronized(_channels) {
        [_channels addObject:channel];
    }
}

-(void)removeChannelForBuffer:(int)bid {
    @synchronized(_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            [_channels removeObject:channel];
    }
}

-(void)updateTopic:(NSString *)text time:(NSTimeInterval)time author:(NSString *)author buffer:(int)bid {
    @synchronized(_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel) {
            channel.topic_text = text;
            channel.topic_time = time;
            channel.topic_author = author;
        }
    }
}

-(void)updateMode:(NSString *)mode buffer:(int)bid ops:(NSDictionary *)ops {
    @synchronized(_channels) {
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
    @synchronized(_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            channel.url = url;
    }
}

-(void)updateTimestamp:(NSTimeInterval)timestamp buffer:(int)bid {
    @synchronized(_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            channel.timestamp = timestamp;
    }
}

-(Channel *)channelForBuffer:(int)bid {
    @synchronized(_channels) {
        for(Channel *channel in _channels) {
            if(channel.bid == bid)
                return channel;
        }
        return nil;
    }
}

-(NSArray *)channelsForServer:(int)cid {
    NSMutableArray *channels = [[NSMutableArray alloc] init];
    @synchronized(_channels) {
        for(Channel *channel in _channels) {
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
    NSLog(@"Cleaning up invalid channels");
    NSArray *copy;
    @synchronized(_channels) {
        copy = _channels.copy;
    }
    for(Channel *channel in copy) {
        if(!channel.valid) {
            NSLog(@"Removing invalid channel: %@", channel.name);
            [_channels removeObject:channel];
            [[UsersDataSource sharedInstance] removeUsersForBuffer:channel.bid];
        }
    }
}
@end
