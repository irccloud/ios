//
//  URLtoBIDTests.m
//  IRCCloud
//
//  Created by Sam Steele on 4/27/17.
//  Copyright © 2017 IRCCloud, Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ServersDataSource.h"
#import "BuffersDataSource.h"
#import "URLHandler.h"

@interface URLtoBIDTests : XCTestCase

@end

@implementation URLtoBIDTests

- (void)setUp {
    [super setUp];
    
    Server *s = [[Server alloc] init];
    s.hostname = @"irc.irccloud.com";
    s.port = 6667;
    s.name = @"IRCCloud";
    s.cid = 1;
    s.isupport = @{
                   @"AWAYLEN": @(200),
                   @"CALLERID": @(1),
                   @"CASEMAPPING": @"ascii",
                   @"CHANMODES": @"IZbegw,k,FJLdfjl,ACKMNORSTcimnprstz",
                   @"CHANNELLEN": @(64),
                   @"CHANTYPES": @"#",
                   @"CHARSET": @"ascii",
                   @"ELIST": @"MU",
                   @"ESILENCE": @(1),
                   @"EXCEPTS": @"e",
                   @"FNC": @(1),
                   @"INVEX": @"I",
                   @"KICKLEN": @(255),
                   @"MAP": @(1),
                   @"MAXBANS": @(60),
                   @"MAXCHANNELS": @(20),
                   @"MAXPARA": @(32),
                   @"MAXTARGETS": @(20),
                   @"MODES": @(20),
                   @"NAMESX": @(1),
                   @"NETWORK": @"IRCCloud",
                   @"NICKLEN": @(32),
                   @"OVERRIDE": @(1),
                   @"PREFIX": @{@"Y": @"!", @"h": @"%", @"o": @"@", @"v": @"+"},
                   @"REMOVE": @(1),
                   @"SILENCE": @(32),
                   @"SSL": @"[::]:6697",
                   @"STATUSMSG": @"!@%+",
                   @"TOPICLEN": @(307),
                   @"UHNAMES": @(1),
                   @"USERIP": @(1),
                   @"VBANLIST": @(1),
                   @"WALLCHOPS": @(1),
                   @"WALLVOICES": @(1),
                   @"WATCH": @(32),
                   }.mutableCopy;
    
    [[ServersDataSource sharedInstance] addServer:s];
    
    Buffer *b = [[Buffer alloc] init];
    b.cid = 1;
    b.bid = 1;
    b.type = @"channel";
    b.name = @"#feedback";
    
    [[BuffersDataSource sharedInstance] addBuffer:b];

    b = [[Buffer alloc] init];
    b.cid = 1;
    b.bid = 2;
    b.type = @"conversation";
    b.name = @"sam";
    
    [[BuffersDataSource sharedInstance] addBuffer:b];

    b = [[Buffer alloc] init];
    b.cid = 1;
    b.bid = 3;
    b.type = @"channel";
    b.name = @"##test";
    
    [[BuffersDataSource sharedInstance] addBuffer:b];
}

- (void)tearDown {
    [super tearDown];
    [[ServersDataSource sharedInstance] clear];
    [[BuffersDataSource sharedInstance] clear];
}

- (void)testURLs {
    XCTAssertEqual(-1, [URLHandler URLtoBID:[NSURL URLWithString:@"https://www.irccloud.com/irc/irccloud.com/channel/vip"]]);
    XCTAssertEqual(-1, [URLHandler URLtoBID:[NSURL URLWithString:@"https://www.irccloud.com/irc/irccloud.com/channel/test"]]);
    XCTAssertEqual(1, [URLHandler URLtoBID:[NSURL URLWithString:@"https://www.irccloud.com/irc/irccloud.com/channel/feedback"]]);
    XCTAssertEqual(2, [URLHandler URLtoBID:[NSURL URLWithString:@"https://www.irccloud.com/irc/irccloud.com/messages/sam"]]);
    XCTAssertEqual(3, [URLHandler URLtoBID:[NSURL URLWithString:@"https://www.irccloud.com/irc/irccloud.com/channel/%23%23test"]]);
}

@end
