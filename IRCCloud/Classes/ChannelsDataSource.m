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

@implementation Channel

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
    _channels = [[NSMutableArray alloc] init];
    return self;
}

-(void)clear {
    @synchronized(_channels) {
        [_channels removeAllObjects];
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

-(void)updateMode:(NSString *)mode buffer:(int)bid {
    @synchronized(_channels) {
        Channel *channel = [self channelForBuffer:bid];
        if(channel)
            channel.mode = mode;
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
@end
