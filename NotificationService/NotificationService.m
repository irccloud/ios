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

#import <MobileCoreServices/MobileCoreServices.h>
#import "NetworkConnection.h"
#import "NotificationService.h"
#import "ColorFormatter.h"
#import "ImageCache.h"

@interface NotificationService ()
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    NSURL *attachment = nil;
    NSString *typeHint = (NSString *)kUTTypeJPEG;
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    IRCCLOUD_HOST = [d objectForKey:@"host"];
    IRCCLOUD_PATH = [d objectForKey:@"path"];

    if([d boolForKey:@"defaultSound"])
        self.bestAttemptContent.sound = [UNNotificationSound defaultSound];
    
    if(![d boolForKey:@"disableNotificationPreviews"]) {
        [NetworkConnection sync];
        
        if([request.content.userInfo objectForKey:@"f"]) {
            NSString *fileID = [[request.content.userInfo objectForKey:@"f"] objectAtIndex:0];
            NSString *type = [[request.content.userInfo objectForKey:@"f"] objectAtIndex:1];
            
            typeHint = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)(type), NULL);
            
            if(![NetworkConnection sharedInstance].config)
                [NetworkConnection sharedInstance].config = [[NetworkConnection sharedInstance] requestConfiguration];
            
            if([type hasPrefix:@"image/"])
                attachment = [NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%.f", ([UIScreen mainScreen].bounds.size.width/2) * [UIScreen mainScreen].scale]} error:nil]];
            else
                attachment = [NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID} error:nil]];
        } else if([d boolForKey:@"thirdPartyNotificationPreviews"]) {
            NSDictionary *extensions = @{@"png":(NSString *)kUTTypePNG,
                                         @"jpg":(NSString *)kUTTypeJPEG,
                                         @"jpeg":(NSString *)kUTTypeJPEG,
                                         @"gif":(NSString *)kUTTypeGIF,
                                         @"m4v":(NSString *)kUTTypeMPEG4,
                                         @"mp4":(NSString *)kUTTypeMPEG4,
                                         @"mov":(NSString *)kUTTypeMPEG4,
                                         @"m4a":(NSString *)kUTTypeMPEG4Audio,
                                         @"mp3":(NSString *)kUTTypeMP3,
                                         @"wav":(NSString *)kUTTypeWaveformAudio,
                                         @"avi":(NSString *)kUTTypeAVIMovie,
                                         @"aif":(NSString *)kUTTypeAudioInterchangeFileFormat,
                                         @"aiff":(NSString *)kUTTypeAudioInterchangeFileFormat
                                         };
            NSArray *links;
            [ColorFormatter format:request.content.body defaultColor:[UIColor blackColor] mono:NO linkify:YES server:nil links:&links];

            for(NSTextCheckingResult *r in links) {
                if(r.resultType == NSTextCheckingTypeLink) {
                    NSString *type = [r.URL.pathExtension lowercaseString];
                    if([extensions objectForKey:type]) {
                        attachment = r.URL;
                        typeHint = [extensions objectForKey:type];
                        break;
                    }
                }
            }
        }
    }
    
    if(attachment) {
        if([[NSFileManager defaultManager] fileExistsAtPath:[[ImageCache sharedInstance] pathForURL:attachment].path]) {
            [self downloadComplete:attachment typeHint:typeHint];
        } else {
            [[ImageCache sharedInstance] fetchURL:attachment completionHandler:^(BOOL success) {
                [self downloadComplete:attachment typeHint:typeHint];
            }];
        }
    } else {
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)downloadComplete:(NSURL *)url typeHint:(NSString *)typeHint {
    NSError *error;
    UNNotificationAttachment *a = [UNNotificationAttachment attachmentWithIdentifier:url.lastPathComponent URL:[[ImageCache sharedInstance] pathForURL:url] options:@{UNNotificationAttachmentOptionsTypeHintKey:typeHint} error:&error];
    if(error) {
        NSLog(@"Attachment error: %@", error);
    } else {
        self.bestAttemptContent.attachments = @[a];
    }
    self.contentHandler(self.bestAttemptContent);
}

- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

@end
