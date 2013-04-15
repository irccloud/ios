//
//  ChannelsDataSource.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

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
