//
//  NotificationsDataSource.m
//  IRCCloud
//
//  Created by Sam Steele on 7/21/15.
//  Copyright © 2015 IRCCloud, Ltd. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import "NotificationsDataSource.h"
#import "BuffersDataSource.h"
#import "EventsDataSource.h"

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
        if(!_notifications)
            _notifications = [[NSMutableDictionary alloc] init];
        
#ifdef __IPHONE_10_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 10) {
            [self refresh];
        } else
#endif
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"notifications"];
            
            @try {
                NSArray *ns = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
                for(UILocalNotification *n in ns) {
                    NSNumber *bid = [[n.userInfo objectForKey:@"d"] objectAtIndex:1];
                    if(![_notifications objectForKey:bid])
                        [_notifications setObject:[[NSMutableArray alloc] init] forKey:bid];
                    [[_notifications objectForKey:bid] addObject:n];
                }
            } @catch(NSException *e) {
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
            }
            CLS_LOG(@"NotificationsDataSource initialized with %lu items from cache", (unsigned long)_notifications.count);
        }
    }
    return self;
}

-(void)serialize {
#ifdef __IPHONE_10_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 10) {
        return;
    }
#endif
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"notifications"];
    
    NSMutableArray *n;
    @synchronized(_notifications) {
        for(NSNumber *bid in _notifications.allKeys) {
            [n addObjectsFromArray:[_notifications objectForKey:bid]];
        }
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
        CLS_LOG(@"Clearing badge count");
        [_notifications removeAllObjects];
#ifndef EXTENSION
        [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
#endif
    }
}

-(void)notify:(NSString *)alert category:(NSString *)category cid:(int)cid bid:(int)bid eid:(NSTimeInterval)eid {
#ifndef EXTENSION
#ifdef __IPHONE_10_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 10) {
#if TARGET_IPHONE_SIMULATOR
        UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
        content.title = @"IRCCloud";
        content.body = alert;
        content.sound = [UNNotificationSound soundNamed:@"a.caf"];
        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
        content.userInfo = @{@"d": @[@(cid), @(bid), @(eid)], @"aps":@{@"alert":@{@"loc-args":@[b.name, b.name, b.name, b.name]}}};
        content.categoryIdentifier = category;
        
        UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[@(eid) stringValue] content:content trigger:nil];
        [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError *error) {
            [self refresh];
        }];
#else
        [self refresh];
#endif
    } else {
#endif
    UILocalNotification *n = [[UILocalNotification alloc] init];
    if([n respondsToSelector:@selector(setAlertTitle:)])
        n.alertTitle = @"IRCCloud";
    n.alertBody = alert;
    n.alertAction = @"Reply";
    n.userInfo = @{@"d": @[@(cid), @(bid), @(eid)]};
    @synchronized(_notifications) {
        if(![_notifications objectForKey:@(bid)])
            [_notifications setObject:[[NSMutableArray alloc] init] forKey:@(bid)];
        
        NSArray *ns = [NSArray arrayWithArray:[_notifications objectForKey:@(bid)]];
        BOOL found = NO;
        for(UILocalNotification *n in ns) {
            NSArray *d = [n.userInfo objectForKey:@"d"];
            if([[d objectAtIndex:2] doubleValue] == eid) {
                found = YES;
                break;
            }
        }
        if(!found) {
            [[_notifications objectForKey:@(bid)] addObject:n];
            //[[UIApplication sharedApplication] presentLocalNotificationNow:n];
        }
    }
#ifdef __IPHONE_10_0
    }
#endif
#endif
}

-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid {
#ifndef EXTENSION
    @synchronized(_notifications) {
        NSArray *ns = [NSArray arrayWithArray:[_notifications objectForKey:@(bid)]];
        for(UILocalNotification *n in ns) {
            NSArray *d = [n.userInfo objectForKey:@"d"];
            if([[d objectAtIndex:1] intValue] == bid && [[d objectAtIndex:1] doubleValue] < eid) {
                //[[UIApplication sharedApplication] cancelLocalNotification:n];
                [[_notifications objectForKey:@(bid)] removeObject:n];
            }
        }
        if(![[_notifications objectForKey:@(bid)] count])
            [_notifications removeObjectForKey:@(bid)];
    }
#endif
}

-(id)getNotification:(NSTimeInterval)eid bid:(int)bid {
#ifndef EXTENSION
    @synchronized(_notifications) {
        NSArray *ns = [NSArray arrayWithArray:[_notifications objectForKey:@(bid)]];
#ifdef __IPHONE_10_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 10) {
            for(UNNotification *n in ns) {
                NSArray *d = [n.request.content.userInfo objectForKey:@"d"];
                if([[d objectAtIndex:1] intValue] == bid && [[d objectAtIndex:1] doubleValue] == eid) {
                    return n;
                }
            }
        } else
#endif
        for(UILocalNotification *n in ns) {
            NSArray *d = [n.userInfo objectForKey:@"d"];
            if([[d objectAtIndex:1] intValue] == bid && [[d objectAtIndex:1] doubleValue] == eid) {
                return n;
            }
        }
    }
#endif
    return nil;
}

-(void)updateBadgeCount {
#ifndef EXTENSION
    int count = 0;
    for(NSArray *a in _notifications.allValues) {
        count += a.count;
    }
    /*NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffers];
    for(Buffer *b in buffers) {
        count += [[EventsDataSource sharedInstance] highlightCountForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
    }*/
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([UIApplication sharedApplication].applicationIconBadgeNumber != count)
            CLS_LOG(@"Setting iOS icon badge to %i", count);
        [UIApplication sharedApplication].applicationIconBadgeNumber = count;
        if(!count)
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }];
#endif
}

-(NSUInteger)count {
    return _notifications.count;
}

-(void)refresh {
    [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray *notifications) {
        for(UNNotification *n in notifications) {
            @synchronized(_notifications) {
                int bid = [[[n.request.content.userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
                NSTimeInterval eid = [[[n.request.content.userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
                
                if(![_notifications objectForKey:@(bid)])
                    [_notifications setObject:[[NSMutableArray alloc] init] forKey:@(bid)];
                
                NSArray *ns = [NSArray arrayWithArray:[_notifications objectForKey:@(bid)]];
                BOOL found = NO;
                for(UNNotification *un in ns) {
                    NSArray *d = [un.request.content.userInfo objectForKey:@"d"];
                    if([[d objectAtIndex:2] doubleValue] == eid) {
                        found = YES;
                        break;
                    }
                }
                if(!found) {
                    [[_notifications objectForKey:@(bid)] addObject:n];
                }
            }
        }
        [self updateBadgeCount];
    }];
}
@end
