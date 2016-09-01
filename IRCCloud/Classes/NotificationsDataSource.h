//
//  NotificationsDataSource.h
//  IRCCloud
//
//  Created by Sam Steele on 7/21/15.
//  Copyright © 2015 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EventsDataSource.h"

@interface NotificationsDataSource : NSObject {
    NSMutableDictionary *_notifications;
}
+(NotificationsDataSource *)sharedInstance;
-(NSUInteger)count;
-(void)serialize;
-(void)clear;
-(void)notify:(NSString *)alert category:(NSString *)category cid:(int)cid bid:(int)bid eid:(NSTimeInterval)eid;
-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid;
-(void)updateBadgeCount;
-(id)getNotification:(NSTimeInterval)eid bid:(int)bid;
-(void)refresh;
@end
