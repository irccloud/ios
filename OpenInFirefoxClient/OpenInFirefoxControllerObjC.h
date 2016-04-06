/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

// This class is used to check if Firefox is installed in the system and
// to open a URL in Firefox either with or without a callback URL.
@interface OpenInFirefoxControllerObjC : NSObject

// Returns a shared instance of the OpenInFirefoxControllerObjC.
+ (OpenInFirefoxControllerObjC *)sharedInstance;

// Returns YES if Firefox is installed in the user's system.
- (BOOL)isFirefoxInstalled;

// Opens a URL in Firefox.
- (BOOL)openInFirefox:(NSURL *)url;

@end
