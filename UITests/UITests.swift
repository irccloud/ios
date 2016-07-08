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
    
    let isPhone = UIDevice().userInterfaceIdiom == .Phone
    let isPad = UIDevice().userInterfaceIdiom == .Pad
    let args = app.launchArguments
    var isBigPhone = false
    if (
        args[args.endIndex-2] == "-FASTLANE_SNAPSHOT_DEVICE" &&
        args[args.endIndex-1] == "\"iPhone 6 Plus\""
    ) {
        isBigPhone = true
    }
    let isDawn = theme == "dawn"
    print(isPhone, isPad, isBigPhone, isDawn, args)
    
    if (isDawn || isPhone) {
        sleep(SCREENSHOT_DELAY)
        snapshot("\(theme)-Portrait", waitForLoadingIndicator: false)
    }
    if (isPad || (isDawn && isBigPhone)) {
        XCUIDevice().orientation = UIDeviceOrientation.LandscapeLeft;
        sleep(SCREENSHOT_DELAY)
        snapshot("\(theme)-Landscape", waitForLoadingIndicator: false)
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
