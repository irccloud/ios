//
//  NotificationService.m
//  NotificationService
//
//  Created by Sam Steele on 1/9/17.
//  Copyright © 2017 IRCCloud, Ltd. All rights reserved.
//

#import "NetworkConnection.h"
#import "NotificationService.h"
#import "ColorFormatter.h"
#import "URLHandler.h"

@interface NotificationService () {
    NSURL *_attachment;
}

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];

#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    IRCCLOUD_HOST = [d objectForKey:@"host"];
    IRCCLOUD_PATH = [d objectForKey:@"path"];

    [NetworkConnection sync];
    NSLog(@"Config: %@", [NetworkConnection sharedInstance].config);
    
    NSArray *links;
    [ColorFormatter format:request.content.body defaultColor:[UIColor blackColor] mono:NO linkify:YES server:nil links:&links];
    NSLog(@"Links: %@", links);
    
    NSURL *attachment = nil;
    for(NSTextCheckingResult *r in links) {
        if(r.resultType == NSTextCheckingTypeLink && [URLHandler isImageURL:r.URL]) {
            attachment = r.URL;
            break;
        }
    }
    
    if(attachment) {
        sharedcontainer = [sharedcontainer URLByAppendingPathComponent:@"attachments/"];
        [[NSFileManager defaultManager] createDirectoryAtURL:sharedcontainer withIntermediateDirectories:YES attributes:nil error:nil];
        _attachment = [sharedcontainer URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.%@",[[request.content.userInfo objectForKey:@"d"] objectAtIndex:1], [[request.content.userInfo objectForKey:@"d"] objectAtIndex:1], attachment.pathExtension]];
        NSLog(@"Downloading %@ to %@", attachment.absoluteString, _attachment.absoluteString);
        
        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:attachment completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if(error) {
                NSLog(@"Download failed: %@", error);
            } else if(location) {
                NSLog(@"Downloaded to: %@", location);
                [[NSFileManager defaultManager] moveItemAtURL:location toURL:_attachment error:nil];
                UNNotificationAttachment *a = [UNNotificationAttachment attachmentWithIdentifier:_attachment.lastPathComponent URL:_attachment options:nil error:&error];
                if(error)
                    NSLog(@"Attachment error: %@", error);
                else
                    self.bestAttemptContent.attachments = @[a];
            }
            self.contentHandler(self.bestAttemptContent);
        }];
        [task resume];
    } else {
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

@end
