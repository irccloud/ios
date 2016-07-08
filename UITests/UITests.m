//
//  UITests.m
//  UITests
//
//  Created by Sam Steele on 7/4/16.
//  Copyright © 2016 IRCCloud, Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UITests-Swift.h"

#define SCREENSHOT_DELAY 2

@interface UITests : XCTestCase

@end

@implementation UITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
}

- (void)takeScreenshotTheme:(NSString *)theme mono:(BOOL)mono {
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    if (mono) {
        app.launchArguments = @[@"-theme", theme];
    } else {
        app.launchArguments = @[@"-theme", theme, @"-mono"];
    }
    [Snapshot setupSnapshot:app];
    [app launch];
    
    // XCUIElement *window = [app.windows elementBoundByIndex:0];
    
    // if (
    //     [theme isEqual: @"dawn"] ||
    //     window.horizontalSizeClass == UIUserInterfaceSizeClassCompact
    // ) {
        [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
        [Snapshot snapshot:[NSString stringWithFormat:@"%@-Portrait", theme]
                  waitForLoadingIndicator:NO];
    // }
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    // if (
    //     window.horizontalSizeClass == UIUserInterfaceSizeClassRegular && (
    //         [theme isEqual: @"dawn"] ||
    //         window.verticalSizeClass == UIUserInterfaceSizeClassRegular
    //     )
    // ) {
        [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
        [Snapshot snapshot:[NSString stringWithFormat:@"%@-Landscape", theme]
                  waitForLoadingIndicator:NO];
    // }
}

- (void)testAshScreenshots {
    [self takeScreenshotTheme:@"ash" mono:YES];
}

- (void)testDawnScreenshots {
    [self takeScreenshotTheme:@"dawn" mono:NO];
}

- (void)testDuskScreenshots {
    [self takeScreenshotTheme:@"dusk" mono:NO];
}
@end
