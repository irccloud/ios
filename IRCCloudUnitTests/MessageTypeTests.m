//
//  MessageTypeTests.m
//  IRCCloudUnitTests
//
//  Created by Sam Steele on 8/16/17.
//  Copyright © 2017 IRCCloud, Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NetworkConnection.h"

@interface MessageTypeTests : XCTestCase

@end

@implementation MessageTypeTests

- (void)testMessageTypes {
    //JSON.stringify(Object.keys(cbv().scroll.log.lineRenderer.messageHandlers))
    NSArray *types = @[@"channel_topic",@"buffer_msg",@"newsflash",@"invited",@"channel_invite",@"callerid",@"buffer_me_msg",@"twitch_hosttarget_start",@"twitch_hosttarget_stop",@"twitch_usernotice",@"your_unique_id",@"server_welcome",@"server_yourhost",@"server_created",@"myinfo",@"version",@"server_luserclient",@"server_luserop",@"server_luserunknown",@"server_luserchannels",@"server_luserconns",@"server_luserme",@"server_n_global",@"server_n_local",@"server_snomask",@"self_details",@"hidden_host_set",@"codepage",@"logged_in_as",@"logged_out",@"nick_locked",@"server_motdstart",@"server_motd",@"server_endofmotd",@"server_nomotd",@"motd_response",@"info_response",@"generic_server_info",@"error",@"unknown_umode",@"notice",@"wallops",@"too_fast",@"no_bots",@"bad_ping",@"nickname_in_use",@"invalid_nick_change",@"save_nick",@"nick_collision",@"bad_channel_mask",@"you_are_operator",@"sasl_success",@"sasl_fail",@"sasl_too_long",@"sasl_aborted",@"sasl_already",@"cap_ls",@"cap_list",@"cap_new",@"cap_del",@"cap_req",@"cap_ack",@"cap_nak",@"cap_raw",@"cap_invalid",@"rehashed_config",@"inviting_to_channel",@"invite_notify",@"user_chghost",@"channel_name_change",@"knock",@"kill_deny",@"chan_own_priv_needed",@"not_for_halfops",@"link_channel",@"chan_forbidden",@"joined_channel",@"you_joined_channel",@"parted_channel",@"you_parted_channel",@"kicked_channel",@"you_kicked_channel",@"quit",@"quit_server",@"kill",@"banned",@"socket_closed",@"connecting_failed",@"connecting_cancelled",@"wait",@"starircd_welcome",@"nickchange",@"you_nickchange",@"channel_mode_list_change",@"user_channel_mode",@"user_mode",@"channel_mode",@"channel_mode_is",@"channel_url",@"zurna_motd",@"loaded_module",@"unloaded_module",@"unhandled_line",@"unparsed_line",@"msg_services",@"ambiguous_error_message",@"list_usage",@"list_syntax",@"who_syntax",@"services_down",@"help_topics_start",@"help_topics",@"help_topics_end",@"helphdr",@"helpop",@"helptlr",@"helphlp",@"helpfwd",@"helpign",@"stats",@"statslinkinfo",@"statscommands",@"statscline",@"statsnline",@"statsiline",@"statskline",@"statsqline",@"statsyline",@"endofstats",@"statsbline",@"statsgline",@"statstline",@"statseline",@"statsvline",@"statslline",@"statsuptime",@"statsoline",@"statshline",@"statssline",@"statsuline",@"statsdebug",@"spamfilter",@"text",@"target_callerid",@"target_notified",@"time",@"admin_info",@"watch_status",@"sqline_nick"];
    
    NSDictionary *map = [NetworkConnection sharedInstance].parserMap;
    
    for(NSString *type in types) {
        XCTAssertTrue([map objectForKey:type], @"Missing handler for message type: %@", type);
    }
}
@end
