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
    NSMutableDictionary *_images;
    NSTimeInterval _lastAccessTime;
}
@property (nonatomic, assign) int bid;
@property (nonatomic, copy) NSString *nick;
@property (nonatomic, readonly) NSTimeInterval lastAccessTime;
-(UIImage *)getImage:(int)size;
@end

@interface AvatarsDataSource : NSObject {
    NSMutableDictionary *_avatars;
}
+(AvatarsDataSource *)sharedInstance;
-(void)clear;
-(Avatar *)getAvatar:(NSString *)nick bid:(int)bid;
@end
