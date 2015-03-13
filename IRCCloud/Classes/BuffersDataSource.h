//
//  BuffersDataSource.h
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

@interface Buffer : NSObject<NSCoding> {
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
    BOOL _valid;
    NSString *_draft;
    NSString *_chantypes;
    BOOL _scrolledUp;
    NSTimeInterval _scrolledUpFrom;
    CGFloat _savedScrollOffset;
    Buffer *_lastBuffer;
    Buffer *_nextBuffer;
}
@property (nonatomic, assign) int bid, cid, archived, deferred, timeout;
@property (nonatomic, assign) NSTimeInterval min_eid, last_seen_eid, scrolledUpFrom;
@property (nonatomic, assign) CGFloat savedScrollOffset;
@property (nonatomic, copy) NSString *name, *type, *away_msg, *chantypes;
@property (nonatomic, assign) BOOL valid, scrolledUp;
@property (nonatomic, copy) NSString *draft;
@property (nonatomic, strong) Buffer *lastBuffer, *nextBuffer;
-(NSComparisonResult)compare:(Buffer *)aBuffer;
-(NSString *)accessibilityValue;
@end

@interface BuffersDataSource : NSObject {
    NSMutableDictionary *_buffers;
}
+(BuffersDataSource *)sharedInstance;
-(void)serialize;
-(void)clear;
-(void)invalidate;
-(NSUInteger)count;
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
-(void)updateAway:(NSString *)away nick:(NSString *)nick server:(int)cid;
-(void)removeBuffer:(int)bid;
-(void)removeAllDataForBuffer:(int)bid;
-(void)purgeInvalidBIDs;
@end
