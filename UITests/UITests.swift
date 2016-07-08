//
//  UITests.swift
//  UITests
//
//  Copyright © 2016 IRCCloud, Ltd. All rights reserved.
//

import Foundation
import XCTest

let SCREENSHOT_DELAY:UInt32 = 2;

class UITests: XCTestCase {


override func setUp() {
    super.setUp()
    XCUIDevice().orientation = UIDeviceOrientation.Portrait
}

func takeScreenshotTheme(theme: String, mono: Bool = false) {
    let app = XCUIApplication()
    app.launchArguments = ["-theme", theme]
    if (mono) {
        app.launchArguments += ["-mono"]
    }
    setupSnapshot(app)
    app.launch()
    
    if (theme == "dawn" || UIDevice().userInterfaceIdiom != .Pad) {
        sleep(SCREENSHOT_DELAY)
        snapshot(String(format: "%@-Portrait", theme), waitForLoadingIndicator: false)
    }
    if (theme == "dawn" && (UIDevice().userInterfaceIdiom == .Pad || UIScreen().nativeScale > 2.0)) {
        XCUIDevice().orientation = UIDeviceOrientation.LandscapeLeft;
        sleep(SCREENSHOT_DELAY)
        snapshot(String(format: "%@-Landscape", theme), waitForLoadingIndicator: false)
    }
}

func testAshScreenshots () {
    takeScreenshotTheme("ash", mono: true)
}
    
func testDawnScreenshots () {
    takeScreenshotTheme("dawn")
}
    
func testDuskScreenshots () {
    takeScreenshotTheme("dusk")
}

}
