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
    NSMutableArray *_notifications;
}
+(NotificationsDataSource *)sharedInstance;
-(void)serialize;
-(void)clear;
-(void)notify:(NSString *)alert cid:(int)cid bid:(int)bid eid:(int)eid;
-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid;
@end
