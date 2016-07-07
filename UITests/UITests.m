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

- (void)testDawnScreenshots {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-theme", @"dawn"];
    [Snapshot setupSnapshot:app];
    [app launch];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Dawn-Portrait" waitForLoadingIndicator:NO];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Dawn-Landscape" waitForLoadingIndicator:NO];
}

- (void)testDuskScreenshots {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-theme", @"dusk"];
    [Snapshot setupSnapshot:app];
    [app launch];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Dusk-Portrait" waitForLoadingIndicator:NO];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Dusk-Landscape" waitForLoadingIndicator:NO];
}

- (void)testAshScreenshots {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-theme", @"ash", @"-mono"];
    [Snapshot setupSnapshot:app];
    [app launch];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Ash-Portrait" waitForLoadingIndicator:NO];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [NSThread sleepForTimeInterval:SCREENSHOT_DELAY];
    [Snapshot snapshot:@"Ash-Landscape" waitForLoadingIndicator:NO];
}
@end
