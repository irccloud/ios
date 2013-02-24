//
//  BuffersDataSource.h
//  IRCCloud
//
//  Created by Sam Steele on 2/24/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Buffer : NSObject {
    int _bid;
    int _cid;
    NSTimeInterval _min_eid;
    NSTimeInterval _last_seen_eid;
    NSString *_name;
    NSString *_type;
    int _archived;
    int _deferred;
    int _timeout;
    NSString *_away_msg;
}
@property int bid, cid, archived, deferred, timeout;
@property NSTimeInterval min_eid, last_seen_eid;
@property NSString *name, *type, *away_msg;
-(NSComparisonResult)compare:(Buffer *)aBuffer;
@end

@interface BuffersDataSource : NSObject {
    NSMutableArray *_buffers;
}
+(BuffersDataSource *)sharedInstance;
-(void)clear;
-(int)count;
-(int)firstBid;
-(void)addBuffer:(Buffer *)buffer;
-(Buffer *)getBuffer:(int)bid;
-(Buffer *)getBufferWithName:(NSString *)name server:(int)cid;
-(NSArray *)getBuffersForServer:(int)cid;
-(NSArray *)getBuffers;
-(void)updateLastSeenEID:(NSTimeInterval)eid buffer:(int)bid;
-(void)updateArchived:(int)archived buffer:(int)bid;
-(void)updateTimeout:(int)timeout buffer:(int)bid;
-(void)updateName:(NSString *)name buffer:(int)bid;
-(void)updateAway:(NSString *)away buffer:(int)bid;
-(void)removeBuffer:(int)bid;
-(void)removeAllDataForBuffer:(int)bid;
@end
