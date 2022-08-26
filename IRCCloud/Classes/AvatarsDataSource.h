//
//  AvatarsDataSource.h
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

@interface Avatar : NSObject {
    int _bid;
    NSString *_nick;
    NSString *_displayName;
    NSMutableDictionary *_images;
    NSMutableDictionary *_selfImages;
    NSTimeInterval _lastAccessTime;
}
@property (nonatomic, assign) int bid;
@property (nonatomic, copy) NSString *nick, *displayName;
@property (nonatomic, readonly) NSTimeInterval lastAccessTime;
-(UIImage *)getImage:(int)size isSelf:(BOOL)isSelf;
-(UIImage *)getImage:(int)size isSelf:(BOOL)isSelf isChannel:(BOOL)isChannel;
@end

@interface AvatarsDataSource : NSObject {
    NSMutableDictionary *_avatars;
    NSMutableDictionary *_avatarURLs;
}
+(AvatarsDataSource *)sharedInstance;
-(void)invalidate;
-(void)serialize;
-(Avatar *)getAvatar:(NSString *)displayName nick:(NSString *)nick bid:(int)bid;
-(void)setAvatarURL:(NSURL *)url bid:(int)bid eid:(NSTimeInterval)eid;
-(NSURL *)URLforBid:(int)bid;
@end
