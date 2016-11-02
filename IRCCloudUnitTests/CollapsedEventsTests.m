//
//  CollapsedEventsTests.m
//  IRCCloudUnitTests
//
//  Created by Sam Steele on 11/2/16.
//  Copyright © 2016 IRCCloud, Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ServersDataSource.h"
#import "EventsDataSource.h"
#import "CollapsedEvents.h"
#import "ColorFormatter.h"

#define AssertEvents(expectedResult) XCTAssert([[_events.collapse stripIRCFormatting] isEqualToString:expectedResult], "Unexpected result: %@", [_events.collapse stripIRCFormatting]);

@interface CollapsedEventsTests : XCTestCase {
    CollapsedEvents *_events;
    NSTimeInterval _eid;
}

@end

@implementation CollapsedEventsTests

- (void)setUp {
    [super setUp];
    _events = [CollapsedEvents new];
    [_events setServer:nil];
    _events.showChan = NO;
    self.continueAfterFailure = YES;
}

- (void)tearDown {
    [_events clear];
    [super tearDown];
}

- (void)addMode:(NSString *)mode nick:(NSString *)nick from:(NSString *)from channel:(NSString *)channel {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"user_channel_mode";
    e.from = from;
    e.fromMode = @"q";
    e.nick = nick;
    e.targetMode = mode;
    e.server = @"irc.example.net";
    e.chan = channel;
    e.ops = @{@"add":@[@{@"param":nick, @"mode": mode}], @"remove":@[]};
    
    [_events addEvent:e];
}

- (void)removeMode:(NSString *)mode nick:(NSString *)nick from:(NSString *)from channel:(NSString *)channel {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"user_channel_mode";
    e.from = from;
    e.fromMode = @"q";
    e.nick = nick;
    e.targetMode = mode;
    e.server = @"irc.example.net";
    e.chan = channel;
    e.ops = @{@"remove":@[@{@"param":nick, @"mode": mode}], @"add":@[]};
    
    [_events addEvent:e];
}

- (void)join:(NSString *)channel nick:(NSString *)nick hostmask:(NSString *)hostmask {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"joined_channel";
    e.nick = nick;
    e.hostmask = hostmask;
    e.server = @"irc.example.net";
    e.chan = channel;
    
    [_events addEvent:e];
}

- (void)part:(NSString *)channel nick:(NSString *)nick hostmask:(NSString *)hostmask {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"parted_channel";
    e.nick = nick;
    e.hostmask = hostmask;
    e.server = @"irc.example.net";
    e.chan = channel;
    
    [_events addEvent:e];
}

- (void)quit:(NSString *)message nick:(NSString *)nick hostmask:(NSString *)hostmask {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"quit";
    e.nick = nick;
    e.hostmask = hostmask;
    e.server = @"irc.example.net";
    e.msg = message;
    
    [_events addEvent:e];
}

- (void)nickChange:(NSString *)nick oldNick:(NSString *)oldNick hostmask:(NSString *)hostmask {
    Event *e = [Event new];
    e.eid = _eid++;
    e.type = @"nickchange";
    e.nick = nick;
    e.oldNick = oldNick;
    e.hostmask = hostmask;
    e.server = @"irc.example.net";
    
    [_events addEvent:e];
}

- (void)testOper1 {
    [self addMode:@"Y" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was promoted to oper (+Y) by • ChanServ");
}

- (void)testOper2 {
    [self addMode:@"y" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was promoted to oper (+y) by • ChanServ");
}

- (void)testOwner1 {
    [self addMode:@"q" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was promoted to owner (+q) by • ChanServ");
}

- (void)testOwner2 {
    Server *s = [Server new];
    s.MODE_OPER = @"";
    s.MODE_OWNER = @"y";
    [_events setServer:s];
    [self addMode:@"y" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was promoted to owner (+y) by • ChanServ");
}

- (void)testOp {
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was opped (+o) by • ChanServ");
}

- (void)testDeop {
    [self removeMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was de-opped (-o) by • ChanServ");
}

- (void)testVoice {
    [self addMode:@"v" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was voiced (+v) by • ChanServ");
}

- (void)testDevoice {
    [self removeMode:@"v" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was de-voiced (-v) by • ChanServ");
}

- (void)testOpByServer {
    [self addMode:@"o" nick:@"sam" from:nil channel:@"#test"];
    AssertEvents(@"• sam was opped (+o) by the server irc.example.net");
}

- (void)testOpDeop {
    [self addMode:@"o" nick:@"sam" from:@"james" channel:@"#test"];
    [self removeMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"• sam was de-opped (-o) by • ChanServ");
}

- (void)testJoin {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"→︎ sam joined (sam@example.net)");
}

- (void)testPart {
    [self part:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"←︎ sam left (sam@example.net)");
}

- (void)testQuit {
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"⇐︎ sam quit (sam@example.net): Leaving");
}

- (void)testQuit2 {
    [self quit:@"*.net *.split" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"⇐︎ sam quit (sam@example.net): *.net *.split");
}

- (void)testNickChange {
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"sam_ →︎ sam");
}

- (void)testNickChangeQuit {
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"⇐︎ sam (was sam_) quit (sam@example.net): Leaving");
}

- (void)testJoinQuit {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam popped in");
}

- (void)testJoinQuitJoin {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"→︎ sam joined (sam@example.net)");
}

- (void)testJoinJoin {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"james" hostmask:@"james@example.net"];
    AssertEvents(@"→︎ sam and james joined");
}

- (void)testJoinQuit2 {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"james" hostmask:@"james@example.net"];
    AssertEvents(@"→︎ sam joined ⇐︎ james quit");
}

- (void)testJoinPart {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self part:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam popped in");
}

- (void)testJoinPart2 {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self part:@"#test" nick:@"james" hostmask:@"james@example.net"];
    AssertEvents(@"→︎ sam joined ←︎ james left");
}

- (void)testQuitJoin {
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam nipped out");
}

- (void)testPartJoin {
    [self part:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam nipped out");
}

- (void)testJoinNickchange {
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"→︎ sam (was sam_) joined (sam@example.net)");
}

- (void)testQuitJoinNickchange {
    [self quit:@"Leaving" nick:@"sam_" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam (was sam_) nipped out");
}

- (void)testQuitJoinNickchange2 {
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam nipped out");
}

- (void)testQuitJoinMode {
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"↔︎ • sam (opped) nipped out");
}

- (void)testQuitJoinModeNickPart {
    [self quit:@"Leaving" nick:@"sam_" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self addMode:@"o" nick:@"sam_" from:@"ChanServ" channel:@"#test"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self part:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"←︎ • sam (was sam_; opped) left");
}

- (void)testNickchangeNickchange {
    [self nickChange:@"james" oldNick:@"james_old" hostmask:@"james@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"james_old →︎ james, sam_ →︎ sam");
}

- (void)testJoinQuitNickchange {
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam (was sam_) nipped out");
}

- (void)testJoinQuitNickchange2 {
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self join:@"#test" nick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam (was sam_) nipped out");
}

- (void)testModeMode {
    [self addMode:@"v" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    [self addMode:@"o" nick:@"james" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"mode: • sam (voiced) and • james (opped)");
}

- (void)testModeMode2 {
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"mode: • sam (opped; voiced)");
}

- (void)testModeNickchange {
    [self addMode:@"o" nick:@"james" from:@"ChanServ" channel:@"#test"];
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    AssertEvents(@"mode: • james (opped) • sam_ →︎ sam");
}

- (void)testJoinMode {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"→︎ • sam (opped) joined");
}

- (void)testJoinModeMode {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self addMode:@"o" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    [self addMode:@"q" nick:@"sam" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"→︎ • sam (promoted to owner, opped) joined");
}

- (void)testModeJoinPart {
    [self addMode:@"o" nick:@"james" from:@"ChanServ" channel:@"#test"];
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self part:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"mode: • james (opped) ↔︎ sam popped in");
}

- (void)testJoinNickchangeModeModeMode {
    [self join:@"#test" nick:@"sam" hostmask:@"sam@example.net"];
    [self nickChange:@"james" oldNick:@"james_old" hostmask:@"james@example.net"];
    [self removeMode:@"o" nick:@"james" from:@"ChanServ" channel:@"#test"];
    [self addMode:@"v" nick:@"RJ" from:@"ChanServ" channel:@"#test"];
    [self addMode:@"v" nick:@"james" from:@"ChanServ" channel:@"#test"];
    AssertEvents(@"→︎ sam joined • mode: • RJ (voiced) • james_old →︎ • james (voiced, de-opped)");
}

- (void)testMultiChannelJoin {
    _events.showChan = YES;
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test3" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"→︎ sam joined #test1, #test2, and #test3");
}

- (void)testMultiChannelNickChangeQuitJoin {
    _events.showChan = YES;
    [self nickChange:@"sam" oldNick:@"sam_" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam (was sam_) nipped out #test1 and #test2");
}

- (void)testMultiChannelPopIn1 {
    _events.showChan = YES;
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test3" nick:@"sam" hostmask:@"sam@example.net"];
    [self part:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self part:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"→︎ sam joined #test3 ↔︎ sam popped in #test1 and #test2");
}

- (void)testMultiChannelPopIn2 {
    _events.showChan = YES;
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test2" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test3" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"↔︎ sam popped in #test1, #test2, and #test3");
}

- (void)testMultiChannelQuit {
    _events.showChan = YES;
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"Leaving" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"⇐︎ sam quit (sam@example.net): Leaving");
}

- (void)testNetSplit {
    [self quit:@"irc.example.net irc2.example.net" nick:@"sam" hostmask:@"sam@example.net"];
    [self quit:@"irc.example.net irc2.example.net" nick:@"james" hostmask:@"james@example.net"];
    [self quit:@"irc3.example.net irc2.example.net" nick:@"RJ" hostmask:@"RJ@example.net"];
    [self quit:@"fake.net fake.net" nick:@"russ" hostmask:@"russ@example.net"];
    [self join:@"#test1" nick:@"sam" hostmask:@"sam@example.net"];
    AssertEvents(@"irc.example.net ↮︎ irc2.example.net and irc3.example.net ↮︎ irc2.example.net ⇐︎ james, RJ, and russ quit ↔︎ sam nipped out");
}

- (void)testChanServJoin {
    [self join:@"#test" nick:@"ChanServ" hostmask:@"ChanServ@services."];
    [self addMode:@"o" nick:@"ChanServ" from:nil channel:@"#test"];
    AssertEvents(@"→︎ • ChanServ (opped) joined");
}

@end
