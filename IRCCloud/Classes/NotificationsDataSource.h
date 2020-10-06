//
//  NotificationsDataSource.h
//
//  Copyright (C) 2015 IRCCloud, Ltd.
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
#import "EventsDataSource.h"

@interface NotificationsDataSource : NSObject {
    NSMutableDictionary *_notifications;
}
+(NotificationsDataSource *)sharedInstance;
-(void)serialize;
-(void)clear;
-(void)notify:(NSString *)alert category:(NSString *)category cid:(int)cid bid:(int)bid eid:(NSTimeInterval)eid;
-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid;
-(void)updateBadgeCount;
-(id)getNotification:(NSTimeInterval)eid bid:(int)bid;
-(void)alert:(NSString *)alertBody title:(NSString *)title category:(NSString *)category userInfo:(NSDictionary *)userInfo;
@end
