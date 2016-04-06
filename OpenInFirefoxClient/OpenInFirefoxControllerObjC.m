/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "OpenInFirefoxControllerObjC.h"

static NSString *const firefoxScheme = @"firefox:";

@implementation OpenInFirefoxControllerObjC

// Creates a shared instance of the controller.
+ (OpenInFirefoxControllerObjC *)sharedInstance {
    static OpenInFirefoxControllerObjC *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

// Custom function that does complete percent escape for constructing the URL.
static NSString *encodeByAddingPercentEscapes(NSString *string) {
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
    kCFAllocatorDefault,
    (CFStringRef)string,
    NULL,
    (CFStringRef)@"!*'();:@&=+$,/?%#[]",
    kCFStringEncodingUTF8));
    return encodedString;
}

// Checks if Firefox is installed.
- (BOOL)isFirefoxInstalled {
    NSURL *url = [NSURL URLWithString:firefoxScheme];
    return [[UIApplication sharedApplication] canOpenURL:url];
}

// Opens the URL in Firefox.
- (BOOL)openInFirefox:(NSURL *)url {
    if (![self isFirefoxInstalled]) {
        return NO;
    }

    NSString *scheme = [url.scheme lowercaseString];
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"]) {
        return NO;
    }

    NSString *urlString = [url absoluteString];
    NSMutableString *firefoxURLString = [NSMutableString string];
    [firefoxURLString appendFormat:@"%@//open-url?url=%@", firefoxScheme, encodeByAddingPercentEscapes(urlString)];
    NSURL *firefoxURL = [NSURL URLWithString: firefoxURLString];

    // Open the URL with Firefox.
    return [[UIApplication sharedApplication] openURL:firefoxURL];
}

@end
