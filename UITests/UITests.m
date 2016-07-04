//
//  UITests.m
//  UITests
//
//  Created by Sam Steele on 7/4/16.
//  Copyright © 2016 IRCCloud, Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "UITests-Swift.h"

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
    [Snapshot snapshot:@"Dawn-Portrait" waitForLoadingIndicator:YES];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [Snapshot snapshot:@"Dawn-Landscape" waitForLoadingIndicator:YES];
}

- (void)testDuskScreenshots {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-theme", @"dusk"];
    [Snapshot setupSnapshot:app];
    [app launch];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [Snapshot snapshot:@"Dusk-Portrait" waitForLoadingIndicator:YES];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [Snapshot snapshot:@"Dusk-Landscape" waitForLoadingIndicator:YES];
}

- (void)testAshScreenshots {
    XCUIApplication *app = [[XCUIApplication alloc] init];
    app.launchArguments = @[@"-theme", @"ash"];
    [Snapshot setupSnapshot:app];
    [app launch];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [Snapshot snapshot:@"Ash-Portrait" waitForLoadingIndicator:YES];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    [Snapshot snapshot:@"Ash-Landscape" waitForLoadingIndicator:YES];
}
@end
