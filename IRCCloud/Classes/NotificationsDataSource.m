//
//  NotificationsDataSource.m
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

#import <UserNotifications/UserNotifications.h>
#import "NotificationsDataSource.h"
#import "BuffersDataSource.h"
#import "EventsDataSource.h"
#import "NetworkConnection.h"

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
            self->_notifications = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)serialize {
    return;
}

-(void)clear {
    @synchronized(self->_notifications) {
        CLS_LOG(@"Clearing badge count");
        [self->_notifications removeAllObjects];
#ifndef EXTENSION
        [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
#endif
    }
}

-(void)notify:(NSString *)alert category:(NSString *)category cid:(int)cid bid:(int)bid eid:(NSTimeInterval)eid {
#ifndef EXTENSION
#if TARGET_IPHONE_SIMULATOR
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = @"IRCCloud";
    content.body = alert;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    content.userInfo = @{@"d": @[@(cid), @(bid), @(eid)], @"aps":@{@"alert":@{@"loc-args":@[b.name, b.name, b.name, b.name]}}};
    content.categoryIdentifier = category;
    content.threadIdentifier = [NSString stringWithFormat:@"%i-%i", cid, bid];
    
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[@(eid) stringValue] content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
#endif
#endif
}

-(void)alert:(NSString *)alertBody title:(NSString *)title category:(NSString *)category userInfo:(NSDictionary *)userInfo {
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = title?title:@"IRCCloud";
    content.body = alertBody;
    content.userInfo = userInfo;
    content.categoryIdentifier = category;
    content.sound = [UNNotificationSound soundNamed:@"a.caf"];
    
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:[@([NSDate date].timeIntervalSince1970) stringValue] content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
}


-(void)removeNotificationsForBID:(int)bid olderThan:(NSTimeInterval)eid {
#ifndef EXTENSION
    @synchronized(self->_notifications) {
        if(![[self->_notifications objectForKey:@(bid)] count])
            [self->_notifications removeObjectForKey:@(bid)];
    }
#endif
}

-(id)getNotification:(NSTimeInterval)eid bid:(int)bid {
#ifndef EXTENSION
    @synchronized(self->_notifications) {
        NSArray *ns = [NSArray arrayWithArray:[self->_notifications objectForKey:@(bid)]];
        for(UNNotification *n in ns) {
            NSArray *d = [n.request.content.userInfo objectForKey:@"d"];
            if([[d objectAtIndex:1] intValue] == bid && [[d objectAtIndex:2] doubleValue] == eid) {
                return n;
            }
        }
    }
#endif
    return nil;
}

-(void)updateBadgeCount {
#ifndef EXTENSION
    __block BOOL __interrupt = NO;
    UIBackgroundTaskIdentifier background_task = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^ {
        CLS_LOG(@"NotificationsDataSource updateBadgeCount task expired");
        __interrupt = YES;
    }];
    [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray *notifications) {
        NSUInteger count = 0;
        NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffers];
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        NSMutableArray *identifiers = [[NSMutableArray alloc] init];
        NSMutableSet *dirtyBuffers = [[NSMutableSet alloc] init];
        
        if(__interrupt)
            return;
        
        for(Buffer *b in buffers) {
            if(b.extraHighlights)
                [dirtyBuffers addObject:b];
            b.extraHighlights = 0;
        }
        
        for(UNNotification *n in notifications) {
            NSArray *d = [n.request.content.userInfo objectForKey:@"d"];
            Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[d objectAtIndex:1] intValue]];
            NSTimeInterval eid = [[d objectAtIndex:2] doubleValue];
            if((!b && [NetworkConnection sharedInstance].state == kIRCCloudStateConnected && [NetworkConnection sharedInstance].ready) || eid <= b.last_seen_eid) {
                if(!b)
                    CLS_LOG(@"Removing eid%f because bid%i doesn't exist", eid, [[d objectAtIndex:1] intValue]);
                else
                    CLS_LOG(@"Removing eid%f because bid%i.last_seen_eid = %f", eid, [[d objectAtIndex:1] intValue], b.last_seen_eid);
                [identifiers addObject:n.request.identifier];
            } else if(b && ![[EventsDataSource sharedInstance] event:eid buffer:b.bid]) {
                b.extraHighlights++;
                [dirtyBuffers addObject:b];
                CLS_LOG(@"bid%i has notification eid%.0f that's not in the loaded backlog, extraHighlights: %i", b.bid, eid, b.extraHighlights);
            }

            if(__interrupt)
                break;
        }
        
        if(identifiers.count > 0)
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:identifiers];
            }];
        
        for(Buffer *b in buffers) {
            int highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
            if([b.type isEqualToString:@"conversation"] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                highlights = 0;
            count += highlights;
            if(__interrupt)
                break;
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if([UIApplication sharedApplication].applicationIconBadgeNumber != count)
                CLS_LOG(@"Setting iOS icon badge to %lu", (unsigned long)count);
            [UIApplication sharedApplication].applicationIconBadgeNumber = count;
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:dirtyBuffers userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:kIRCEventRefresh]}];
            [[UIApplication sharedApplication] endBackgroundTask: background_task];
        }];
    }];
#endif
}
@end
