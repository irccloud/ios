//
//  NotificationService.h
//
//  Copyright (C) 2017 IRCCloud, Ltd.
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

#import "NetworkConnection.h"
#import "NotificationService.h"
#import "ColorFormatter.h"
#import "CSURITemplate.h"

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
    NSURL *attachment = nil;
    
    if([request.content.userInfo objectForKey:@"f"]) {
        NSString *fileID = [[request.content.userInfo objectForKey:@"f"] objectAtIndex:0];
        NSString *type = [[request.content.userInfo objectForKey:@"f"] objectAtIndex:1];
        
        if(![NetworkConnection sharedInstance].config)
            [NetworkConnection sharedInstance].config = [[NetworkConnection sharedInstance] requestConfiguration];
        
        CSURITemplate *template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"file_uri_template"] error:nil];

        if([type hasPrefix:@"image/"])
            attachment = [NSURL URLWithString:[template relativeStringWithVariables:@{@"name":[NSString stringWithFormat:@"%@.%@", fileID, [type substringFromIndex:[type rangeOfString:@"/"].location + 1]], @"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%.f", [UIScreen mainScreen].bounds.size.width]} error:nil]];
        else
            attachment = [NSURL URLWithString:[template relativeStringWithVariables:@{@"name":[NSString stringWithFormat:@"%@.%@", fileID, [type substringFromIndex:[type rangeOfString:@"/"].location + 1]], @"id":fileID} error:nil]];
    } else {
        NSArray *links;
        [ColorFormatter format:request.content.body defaultColor:[UIColor blackColor] mono:NO linkify:YES server:nil links:&links];

        for(NSTextCheckingResult *r in links) {
            if(r.resultType == NSTextCheckingTypeLink) {
                NSString *type = [r.URL.pathExtension lowercaseString];
                if([type isEqualToString:@"png"] || [type isEqualToString:@"jpg"] || [type isEqualToString:@"jpeg"] || [type isEqualToString:@"gif"] || [type isEqualToString:@"m4v"] || [type isEqualToString:@"mp4"] || [type isEqualToString:@"mov"] || [type isEqualToString:@"m4a"] || [type isEqualToString:@"mp3"]) {
                    attachment = r.URL;
                    break;
                }
            }
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
