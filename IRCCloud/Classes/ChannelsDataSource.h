//
//  ChannelsDataSource.h
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

@interface Channel : NSObject {
    int _cid;
    int _bid;
    NSString *_name;
    NSString *_topic_text;
    NSTimeInterval _topic_time;
    NSString *_topic_author;
    NSString *_type;
    NSString *_mode;
    NSTimeInterval _timestamp;
    NSString *_url;
}
@property int cid, bid;
@property NSString *name, *topic_text, *topic_author, *type, *mode, *url;
@property NSTimeInterval topic_time, timestamp;
@end

@interface ChannelsDataSource : NSObject {
    NSMutableArray *_channels;
}
+(ChannelsDataSource *)sharedInstance;
-(void)clear;
-(void)addChannel:(Channel *)channel;
-(void)removeChannelForBuffer:(int)bid;
-(void)updateTopic:(NSString *)text time:(NSTimeInterval)time author:(NSString *)author buffer:(int)bid;
-(void)updateMode:(NSString *)mode buffer:(int)bid;
-(void)updateURL:(NSString *)url buffer:(int)bid;
-(void)updateTimestamp:(NSTimeInterval)timestamp buffer:(int)bid;
-(Channel *)channelForBuffer:(int)bid;
@end
