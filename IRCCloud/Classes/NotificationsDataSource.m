//
//  NotificationsDataSource.m
//  IRCCloud
//
//  Created by Sam Steele on 7/21/15.
//  Copyright © 2015 IRCCloud, Ltd. All rights reserved.
//

#import "NotificationsDataSource.h"

@implementation NotificationsDataSource
+(NotificationsDataSource *)sharedInstance {
    static NotificationsDataSource *sharedInstance;
    
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[NotificationsDataSource alloc] init];
        
        return sharedInstance;
    }
    return nil;
}

-(id)init {
    self = [super init];
    if(self) {
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"notifications"];
            
            @try {
                _notifications = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
            } @catch(NSException *e) {
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
            }
        }
        if(!_notifications)
            _notifications = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"notifications"];
    
    NSArray *n;
    @synchronized(_notifications) {
        n = [_notifications copy];
    }
    
    @synchronized(self) {
        @try {
            [NSKeyedArchiver archiveRootObject:n toFile:cacheFile];
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
}

-(void)clear {
    @synchronized(_notifications) {
        [_notifications removeAllObjects];
#ifndef EXTENSION
        [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
#endif
    }
}

-(void)notify:(NSString *)alert cid:(int)cid bid:(int)bid eid:(int)eid {
#ifndef EXTENSION
    UILocalNotification *n = [[UILocalNotification alloc] init];
    n.alertTitle = @"IRCCloud";
    n.alertBody = alert;
    n.alertAction = @"Reply";
    n.userInfo = @{@"d": @[@(cid), @(bid), @(eid)]};
    [_notifications addObject:n];
    //[[UIApplication sharedApplication] presentLocalNotificationNow:n];
    [UIApplication sharedApplication].applicationIconBadgeNumber = _notifications.count;
#endif
}

-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid {
#ifndef EXTENSION
    for(UILocalNotification *n in _notifications.copy) {
        NSArray *d = [n.userInfo objectForKey:@"d"];
        if([[d objectAtIndex:1] intValue] == bid && [[d objectAtIndex:1] doubleValue] < eid) {
            [[UIApplication sharedApplication] cancelLocalNotification:n];
            [_notifications removeObject:n];
        }
    }
    [UIApplication sharedApplication].applicationIconBadgeNumber = _notifications.count;
    if(!_notifications.count)
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
#endif
}

@end
