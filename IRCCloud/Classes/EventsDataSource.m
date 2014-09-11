//
//  EventsDataSource.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


#import "EventsDataSource.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "BuffersDataSource.h"
#import "ServersDataSource.h"
#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "Ignore.h"

@implementation Event
-(NSComparisonResult)compare:(Event *)aEvent {
    if(aEvent.pending && !_pending)
        return NSOrderedAscending;
    if(!aEvent.pending && _pending)
        return NSOrderedDescending;
    if(aEvent.eid > _eid)
        return NSOrderedAscending;
    else if(aEvent.eid < _eid)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
-(BOOL)isImportant:(NSString *)bufferType {
    if(_isSelf)
        return NO;
    if(!_type)
        return NO;
    if([_type isEqualToString:@"notice"] || [_type isEqualToString:@"channel_invite"]) {
        // Notices sent from the server (with no nick sender) aren't important
        // e.g. *** Looking up your hostname...
        if(_from.length == 0)
            return NO;
        
        // Notices and invites sent to a buffer shouldn't notify in the server buffer
        if([bufferType isEqualToString:@"console"] && (_toChan || _toBuffer))
            return NO;
    }

    return ([_type isEqualToString:@"buffer_msg"]
            ||[_type isEqualToString:@"buffer_me_msg"]
            ||[_type isEqualToString:@"notice"]
            ||[_type isEqualToString:@"channel_invite"]
            ||[_type isEqualToString:@"callerid"]
            ||[_type isEqualToString:@"wallops"]);
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, eid: %f, group: %f, type: %@, msg: %@}", _cid, _bid, _eid, _groupEid, _type, _msg];
}
-(NSString *)ignoreMask {
    if(!_ignoreMask) {
        NSString *from = _from;
        if(!from.length)
            from = _nick;
        
        if(from) {
            _ignoreMask = [NSString stringWithFormat:@"%@!%@", from, _hostmask];
        }
    }
    return _ignoreMask;
}
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self) {
        decodeInt(_cid);
        decodeInt(_bid);
        decodeDouble(_eid);
        decodeObject(_timestamp);
        decodeObject(_type);
        decodeObject(_msg);
        decodeObject(_hostmask);
        decodeObject(_from);
        decodeObject(_fromMode);
        decodeObject(_nick);
        decodeObject(_oldNick);
        decodeObject(_server);
        decodeObject(_diff);
        decodeObject(_formattedMsg);
        decodeBool(_isHighlight);
        decodeBool(_isSelf);
        decodeBool(_toChan);
        decodeBool(_toBuffer);
        decodeObject(_color);
        decodeObject(_ops);
        decodeDouble(_groupEid);
        decodeInt(_rowType);
        decodeObject(_groupMsg);
        decodeBool(_linkify);
        decodeObject(_targetMode);
        decodeInt(_reqid);
        decodeBool(_pending);
        decodeBool(_monospace);
        decodeObject(_links);
        decodeObject(_to);
        decodeObject(_command);
        decodeObject(_day);
        decodeObject(_ignoreMask);
        decodeObject(_chan);
        if(_rowType == ROW_TIMESTAMP)
            _bgColor = [UIColor timestampBackgroundColor];
        else if(_rowType == ROW_LASTSEENEID)
            _bgColor = [UIColor newMsgsBackgroundColor];
        else
            decodeObject(_bgColor);
        
        if(_pending) {
            _height = 0;
            _pending = NO;
            _rowType = ROW_FAILED;
            _bgColor = [UIColor errorBackgroundColor];
        }
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(_cid);
    encodeInt(_bid);
    encodeDouble(_eid);
    encodeObject(_timestamp);
    encodeObject(_type);
    encodeObject(_msg);
    encodeObject(_hostmask);
    encodeObject(_from);
    encodeObject(_fromMode);
    encodeObject(_nick);
    encodeObject(_oldNick);
    encodeObject(_server);
    encodeObject(_diff);
    encodeObject(_formattedMsg);
    encodeBool(_isHighlight);
    encodeBool(_isSelf);
    encodeBool(_toChan);
    encodeBool(_toBuffer);
    encodeObject(_color);
    encodeObject(_ops);
    encodeDouble(_groupEid);
    encodeInt(_rowType);
    encodeObject(_groupMsg);
    encodeBool(_linkify);
    encodeObject(_targetMode);
    encodeInt(_reqid);
    encodeBool(_pending);
    encodeBool(_monospace);
    encodeObject(_links);
    encodeObject(_to);
    encodeObject(_command);
    encodeObject(_day);
    encodeObject(_ignoreMask);
    encodeObject(_chan);
    if(_rowType != ROW_TIMESTAMP && _rowType != ROW_LASTSEENEID)
        encodeObject(_bgColor);
}
@end

@implementation EventsDataSource
+(EventsDataSource *)sharedInstance {
    static EventsDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[EventsDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"events"];
    
    _events = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
    _events_sorted = [[NSMutableDictionary alloc] init];
    _highestEid = 0;
    if(_events) {
        for(NSNumber *bid in _events) {
            NSMutableArray *events = [_events objectForKey:bid];
            NSMutableDictionary *events_sorted = [[NSMutableDictionary alloc] init];
            for(Event *e in events) {
                [events_sorted setObject:e forKey:@(e.eid)];
                if(e.eid > _highestEid)
                    _highestEid = e.eid;
            }
            
            if(events.count > 1000) {
                CLS_LOG(@"Cleaning up excessive backlog in BID: bid%@", bid);
                Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid.intValue];
                if(b) {
                    b.scrolledUp = NO;
                    b.scrolledUpFrom = -1;
                    b.savedScrollOffset = -1;
                }
                while(events.count > 1000) {
                    Event *e = [events firstObject];
                    [events removeObject:e];
                    [events_sorted removeObjectForKey:@(e.eid)];
                }
            }
            [_events_sorted setObject:events_sorted forKey:bid];
        }
        [self clearPendingAndFailed];
    } else {
        _events = [[NSMutableDictionary alloc] init];
    }
    _dirty = YES;
    
    void (^error)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.from = @"";
        event.bgColor = [UIColor errorBackgroundColor];
    };
    
    void (^notice)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.bgColor = [UIColor noticeBackgroundColor];
        event.chan = [object objectForKey:@"target"];
        event.monospace = YES;
    };
    
    void (^status)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.from = @"";
        event.bgColor = [UIColor statusBackgroundColor];
        if([object objectForKey:@"parts"] && [[object objectForKey:@"parts"] length] > 0)
            event.msg = [NSString stringWithFormat:@"%@: %@", [object objectForKey:@"parts"], event.msg];
        event.monospace = YES;
        if(![event.type isEqualToString:@"server_motd"] && ![event.type isEqualToString:@"zurna_motd"])
            event.linkify = NO;
    };
    
    void (^unhandled_line)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.from = @"";
        event.msg = @"";
        if([object objectForKey:@"command"])
            event.msg = [[object objectForKey:@"command"] stringByAppendingString:@" "];
        if([object objectForKey:@"raw"])
            event.msg = [event.msg stringByAppendingString:[object objectForKey:@"raw"]];
        else
            event.msg = [event.msg stringByAppendingString:[object objectForKey:@"msg"]];
        event.bgColor = [UIColor errorBackgroundColor];
    };
    
    void (^kicked_channel)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.from = @"";
        event.fromMode = nil;
        event.oldNick = [object objectForKey:@"nick"];
        event.nick = [object objectForKey:@"kicker"];
        event.hostmask = [object objectForKey:@"kicker_hostmask"];
        event.color = [UIColor timestampColor];
        event.linkify = NO;
    };
    
    void (^motd)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        NSArray *lines = [object objectForKey:@"lines"];
        event.from = @"";
        if([lines count]) {
            if([[object objectForKey:@"start"] length])
                event.msg = [[object objectForKey:@"start"] stringByAppendingString:@"\n"];
            else
                event.msg = @"";
            
            for(NSString *line in lines) {
                event.msg = [event.msg stringByAppendingFormat:@"%@\n", line];
            }
        }
        event.bgColor = [UIColor selfBackgroundColor];
        event.monospace = YES;
    };
    
    void (^cap)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
        event.bgColor = [UIColor statusBackgroundColor];
        event.linkify = NO;
        event.from = @"CAP";
        if([event.type isEqualToString:@"cap_ls"])
            event.msg = @"Server supports: ";
        else if([event.type isEqualToString:@"cap_req"])
            event.msg = @"Requesting: ";
        else if([event.type isEqualToString:@"cap_ack"])
            event.msg = @"Acknowledged: ";
        else if([event.type isEqualToString:@"cap_raw"])
            event.msg = [object objectForKey:@"line"];
        event.msg = [event.msg stringByAppendingString:[[object objectForKey:@"caps"] componentsJoinedByString:@" | "]];
        event.monospace = YES;
    };
    
    _formatterMap = @{@"too_fast":error, @"sasl_fail":error, @"sasl_too_long":error, @"sasl_aborted":error,
                      @"sasl_already":error, @"no_bots":error, @"msg_services":error, @"bad_ping":error,
                      @"not_for_halfops":error, @"ambiguous_error_message":error, @"list_syntax":error, @"who_syntax":error,
                      @"wait":status, @"stats": status, @"statslinkinfo": status, @"statscommands": status, @"statscline": status, @"statsnline": status, @"statsiline": status, @"statskline": status, @"statsqline": status, @"statsyline": status, @"statsbline": status, @"statsgline": status, @"statstline": status, @"statseline": status, @"statsvline": status, @"statslline": status, @"statsuptime": status, @"statsoline": status, @"statshline": status, @"statssline": status, @"statsuline": status, @"statsdebug": status, @"endofstats": status,
                      @"server_motdstart": status, @"server_welcome": status, @"server_endofmotd": status,
                      @"server_nomotd": status, @"server_luserclient": status, @"server_luserop": status,
                      @"server_luserconns": status, @"server_luserme": status, @"server_n_local": status,
                      @"server_luserchannels": status, @"server_n_global": status, @"server_yourhost": status,
                      @"server_created": status, @"server_luserunknown": status,
                      @"help_topics_start": status, @"help_topics": status, @"help_topics_end": status, @"helphdr": status, @"helpop": status, @"helptlr": status, @"helphlp": status, @"helpfwd": status, @"helpign": status,
                      @"btn_metadata_set": status, @"logged_in_as": status, @"sasl_success": status, @"you_are_operator": status,
                      @"server_snomask": status, @"starircd_welcome": status, @"zurna_motd": status, @"codepage": status, @"logged_out": status,
                      @"nick_locked": status, @"text": status, @"admin_info": status,
                      @"cap_ls": cap, @"cap_req": cap, @"cap_ack": cap, @"cap_raw": cap,
                      @"unhandled_line":unhandled_line, @"unparsed_line":unhandled_line,
                      @"kicked_channel":kicked_channel, @"you_kicked_channel":kicked_channel,
                      @"motd_response":motd, @"server_motd":motd, @"info_response":motd,
                      @"notice":notice, @"newsflash":notice, @"generic_server_info":notice, @"list_usage":notice,
                      @"socket_closed":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.rowType = ROW_SOCKETCLOSED;
                          event.color = [UIColor timestampColor];
                          if([object objectForKey:@"pool_lost"])
                              event.msg = @"Connection pool lost";
                          else if([object objectForKey:@"server_ping_timeout"])
                              event.msg = @"Server PING timed out";
                          else if([object objectForKey:@"reason"] && [[object objectForKey:@"reason"] length] > 0) {
                              NSString *reason = [object objectForKey:@"reason"];
                              if([reason isKindOfClass:[NSString class]] && [reason length]) {
                                  if([reason isEqualToString:@"pool_lost"])
                                      reason = @"Connection pool failed";
                                  else if([reason isEqualToString:@"no_pool"])
                                      reason = @"No available connection pools";
                                  else if([reason isEqualToString:@"enetdown"])
                                      reason = @"Network down";
                                  else if([reason isEqualToString:@"etimedout"] || [reason isEqualToString:@"timeout"])
                                      reason = @"Timed out";
                                  else if([reason isEqualToString:@"ehostunreach"])
                                      reason = @"Host unreachable";
                                  else if([reason isEqualToString:@"econnrefused"])
                                      reason = @"Connection refused";
                                  else if([reason isEqualToString:@"nxdomain"])
                                      reason = @"Invalid hostname";
                                  else if([reason isEqualToString:@"server_ping_timeout"])
                                      reason = @"PING timeout";
                                  else if([reason isEqualToString:@"ssl_certificate_error"])
                                      reason = @"SSL certificate error";
                                  else if([reason isEqualToString:@"ssl_error"])
                                      reason = @"SSL error";
                                  else if([reason isEqualToString:@"crash"])
                                      reason = @"Connection crashed";
                              }
                              event.msg = [@"Connection lost: " stringByAppendingString:reason];
                          } else if([object objectForKey:@"abnormal"])
                              event.msg = @"Connection closed unexpectedly";
                          else
                              event.msg = @"";
                      },
                      @"user_channel_mode":^(Event *event, IRCCloudJSONObject *object) {
                          event.targetMode = [object objectForKey:@"newmode"];
                          event.chan = [object objectForKey:@"channel"];
                      },
                      @"buffer_me_msg":^(Event *event, IRCCloudJSONObject *object) {
                          event.nick = event.from;
                          event.from = @"";
                      },
                      @"nickname_in_use":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = [object objectForKey:@"nick"];
                          event.msg = @"is already in use";
                          event.bgColor = [UIColor errorBackgroundColor];
                      },
                      @"connecting_cancelled":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = @"Cancelled";
                          event.bgColor = [UIColor errorBackgroundColor];
                      },
                      @"connecting_failed":^(Event *event, IRCCloudJSONObject *object) {
                          event.rowType = ROW_SOCKETCLOSED;
                          event.color = [UIColor timestampColor];
                          event.from = @"";
                          NSString *reason = [object objectForKey:@"reason"];
                          if([reason isKindOfClass:[NSString class]] && [reason length]) {
                              if([reason isEqualToString:@"pool_lost"])
                                  reason = @"Connection pool failed";
                              else if([reason isEqualToString:@"no_pool"])
                                  reason = @"No available connection pools";
                              else if([reason isEqualToString:@"enetdown"])
                                  reason = @"Network down";
                              else if([reason isEqualToString:@"etimedout"] || [reason isEqualToString:@"timeout"])
                                  reason = @"Timed out";
                              else if([reason isEqualToString:@"ehostunreach"])
                                  reason = @"Host unreachable";
                              else if([reason isEqualToString:@"econnrefused"])
                                  reason = @"Connection refused";
                              else if([reason isEqualToString:@"nxdomain"])
                                  reason = @"Invalid hostname";
                              else if([reason isEqualToString:@"server_ping_timeout"])
                                  reason = @"PING timeout";
                              else if([reason isEqualToString:@"ssl_certificate_error"])
                                  reason = @"SSL certificate error";
                              else if([reason isEqualToString:@"ssl_error"])
                                  reason = @"SSL error";
                              else if([reason isEqualToString:@"crash"])
                                  reason = @"Connection crashed";
                              event.msg = [@"Failed to connect: " stringByAppendingString:reason];
                          } else {
                              event.msg = @"Failed to connect.";
                          }
                      },
                      @"quit_server":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = @"⇐ You disconnected";
                          event.color = [UIColor timestampColor];
                          event.isSelf = NO;
                      },
                      @"self_details":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Your hostmask: %c%@%c", BOLD, [object objectForKey:@"usermask"], BOLD];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.monospace = YES;
                      },
                      @"myinfo":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Host: %@\n", [object objectForKey:@"server"]];
                          event.msg = [event.msg stringByAppendingFormat:@"IRCd: %@\n", [object objectForKey:@"version"]];
                          event.msg = [event.msg stringByAppendingFormat:@"User modes: %@\n", [object objectForKey:@"user_modes"]];
                          event.msg = [event.msg stringByAppendingFormat:@"Channel modes: %@\n", [object objectForKey:@"channel_modes"]];
                          if([[object objectForKey:@"rest"] length])
                              event.msg = [event.msg stringByAppendingFormat:@"Parametric channel modes: %@\n", [object objectForKey:@"rest"]];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.monospace = YES;
                      },
                      @"user_mode":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Your user mode is: %c+%@%c", BOLD, [object objectForKey:@"newmode"], BOLD];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.monospace = YES;
                      },
                      @"your_unique_id":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Your unique ID is: %c%@%c", BOLD, [object objectForKey:@"unique_id"], BOLD];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.monospace = YES;
                      },
                      @"kill":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = @"You were killed";
                          if([object objectForKey:@"from"])
                              event.msg = [event.msg stringByAppendingFormat:@" by %@", [object objectForKey:@"from"]];
                          if([object objectForKey:@"killer_hostmask"])
                              event.msg = [event.msg stringByAppendingFormat:@" (%@)", [object objectForKey:@"killer_hostmask"]];
                          if([object objectForKey:@"reason"])
                              event.msg = [event.msg stringByAppendingFormat:@": %@", [object objectForKey:@"reason"]];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                      },
                      @"banned":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = @"You were banned";
                          if([object objectForKey:@"server"])
                              event.msg = [event.msg stringByAppendingFormat:@" from %@", [object objectForKey:@"server"]];
                          if([object objectForKey:@"reason"])
                              event.msg = [event.msg stringByAppendingFormat:@": %@", [object objectForKey:@"reason"]];
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                      },
                      @"channel_topic":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = [[object objectForKey:@"author"] length]?[object objectForKey:@"author"]:[object objectForKey:@"server"];
                          if([object objectForKey:@"topic"] && [[object objectForKey:@"topic"] length])
                              event.msg = [NSString stringWithFormat:@"set the topic: %@", [object objectForKey:@"topic"]];
                          else
                              event.msg = @"cleared the topic";
                          event.bgColor = [UIColor statusBackgroundColor];
                      },
                      @"channel_mode":^(Event *event, IRCCloudJSONObject *object) {
                          event.nick = event.from;
                          event.from = @"";
                          if(event.server && [event.server isKindOfClass:[NSString class]] && event.server.length)
                              event.msg = [NSString stringWithFormat:@"Channel mode set to: %c%@%c by the server %c%@%c", BOLD, [object objectForKey:@"diff"], CLEAR, BOLD, event.server, CLEAR];
                          else
                              event.msg = [NSString stringWithFormat:@"Channel mode set to: %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                          event.linkify = NO;
                          event.bgColor = [UIColor statusBackgroundColor];
                      },
                      @"channel_mode_is":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          if([[object objectForKey:@"diff"] length] > 0)
                              event.msg = [NSString stringWithFormat:@"Channel mode is: %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                          else
                              event.msg = @"No channel mode";
                          event.bgColor = [UIColor statusBackgroundColor];
                      },
                      @"channel_mode_list_change":^(Event *event, IRCCloudJSONObject *object) {
                          BOOL unknown = YES;
                          NSDictionary *ops = [object objectForKey:@"ops"];
                          if(ops) {
                              NSArray *add = [ops objectForKey:@"add"];
                              if(add.count > 0) {
                                  NSDictionary *op = [add objectAtIndex:0];
                                  if([[[op objectForKey:@"mode"] lowercaseString] isEqualToString:@"b"]) {
                                      event.nick = event.from;
                                      event.from = @"";
                                      event.msg = [NSString stringWithFormat:@"Channel ban set for %c%@%c (+b)", BOLD, [op objectForKey:@"param"], BOLD];
                                      unknown = NO;
                                  } else if([[[op objectForKey:@"mode"] lowercaseString] isEqualToString:@"e"]) {
                                      event.nick = event.from;
                                      event.from = @"";
                                      event.msg = [NSString stringWithFormat:@"Channel ban exception set for %c%@%c (+e)", BOLD, [op objectForKey:@"param"], BOLD];
                                      unknown = NO;
                                  }
                              }
                              NSArray *remove = [ops objectForKey:@"remove"];
                              if(remove.count > 0) {
                                  NSDictionary *op = [remove objectAtIndex:0];
                                  if([[[op objectForKey:@"mode"] lowercaseString] isEqualToString:@"b"]) {
                                      event.nick = event.from;
                                      event.from = @"";
                                      event.msg = [NSString stringWithFormat:@"Channel ban removed for %c%@%c (-b)", BOLD, [op objectForKey:@"param"], BOLD];
                                      unknown = NO;
                                  } else if([[[op objectForKey:@"mode"] lowercaseString] isEqualToString:@"e"]) {
                                      event.nick = event.from;
                                      event.from = @"";
                                      event.msg = [NSString stringWithFormat:@"Channel ban exception removed for %c%@%c (+e)", BOLD, [op objectForKey:@"param"], BOLD];
                                      unknown = NO;
                                  }
                              }
                          }
                          if(unknown) {
                              event.nick = event.from;
                              event.from = @"";
                              event.msg = [NSString stringWithFormat:@"Channel mode set to %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                          }
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                      },
                      @"hidden_host_set":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"hidden_host"], BOLD, event.msg];
                          event.monospace = YES;
                      },
                      @"inviting_to_channel":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"You invited %@ to join %@", [object objectForKey:@"recipient"], [object objectForKey:@"channel"]];
                          event.bgColor = [UIColor noticeBackgroundColor];
                      },
                      @"channel_invite":^(Event *event, IRCCloudJSONObject *object) {
                          event.msg = [NSString stringWithFormat:@"Invite to join %@", [object objectForKey:@"channel"]];
                          event.oldNick = [object objectForKey:@"channel"];
                          event.bgColor = [UIColor noticeBackgroundColor];
                          event.monospace = YES;
                      },
                      @"callerid":^(Event *event, IRCCloudJSONObject *object) {
                          event.msg = [event.msg stringByAppendingFormat:@" Tap to add %c%@%c to the whitelist.", BOLD, event.nick, CLEAR];
                          event.from = event.nick;
                          event.isHighlight = YES;
                          event.linkify = NO;
                          event.monospace = YES;
                          event.hostmask = [object objectForKey:@"usermask"];
                      },
                      @"target_callerid":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = [object objectForKey:@"target_nick"];
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.monospace = YES;
                      },
                      @"target_notified":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = [object objectForKey:@"target_nick"];
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.monospace = YES;
                      },
                      @"link_channel":^(Event *event, IRCCloudJSONObject *object) {
                          event.from = @"";
                          if([[object objectForKey:@"invalid_chan"] isKindOfClass:[NSString class]] && [[object objectForKey:@"invalid_chan"] length]) {
                              if([[object objectForKey:@"valid_chan"] isKindOfClass:[NSString class]] && [[object objectForKey:@"valid_chan"] length]) {
                                  event.msg = [NSString stringWithFormat:@"%@ → %@ %@", [object objectForKey:@"invalid_chan"], [object objectForKey:@"valid_chan"], event.msg];
                              } else {
                                  event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"invalid_chan"], event.msg];
                              }
                          }
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.monospace = YES;
                      },
                      @"version":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"server_version"], BOLD, [object objectForKey:@"comments"]];
                          event.monospace = YES;
                      },
                      @"rehashed_config":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor noticeBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Rehashed config: %@ (%@)", [object objectForKey:@"file"], event.msg];
                          event.monospace = YES;
                      },
                      @"knock":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor noticeBackgroundColor];
                          event.linkify = NO;
                          event.monospace = YES;
                          if(event.nick.length) {
                              event.from = event.nick;
                              if(event.hostmask.length)
                                  event.msg = [event.msg stringByAppendingFormat:@" (%@)", event.hostmask];
                          } else {
                              event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"userhost"], event.msg];
                          }
                      },
                      @"rehashed_config":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor noticeBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          event.msg = [NSString stringWithFormat:@"Rehashed config: %@ (%@)", [object objectForKey:@"file"], event.msg];
                          event.monospace = YES;
                      },
                      @"unknown_umode":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          if([[object objectForKey:@"flag"] length])
                              event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"flag"], BOLD, event.msg];
                      },
                      @"kill_deny":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.from = [object objectForKey:@"channel"];
                      },
                      @"chan_own_priv_needed":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.from = [object objectForKey:@"channel"];
                      },
                      @"chan_forbidden":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor errorBackgroundColor];
                          event.from = [object objectForKey:@"channel"];
                      },
                      @"time":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.from = @"";
                          event.monospace = YES;
                          event.msg = [object objectForKey:@"time_string"];
                          if([[object objectForKey:@"time_stamp"] length]) {
                              event.msg = [event.msg stringByAppendingFormat:@" (%@)", [object objectForKey:@"time_stamp"]];
                          }
                          event.msg = [event.msg stringByAppendingFormat:@" — %c%@%c", BOLD, [object objectForKey:@"time_server"], CLEAR];
                      },
                      @"watch_status":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.from = [object objectForKey:@"watch_nick"];
                          event.msg = [event.msg stringByAppendingFormat:@" (%@@%@)", [object objectForKey:@"username"], [object objectForKey:@"userhost"]];
                          event.monospace = YES;
                      },
                      @"sqline_nick":^(Event *event, IRCCloudJSONObject *object) {
                          event.bgColor = [UIColor statusBackgroundColor];
                          event.linkify = NO;
                          event.from = [object objectForKey:@"charset"];
                          event.monospace = YES;
                      },
                      };
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"events"];
    
    NSMutableDictionary *events = [[NSMutableDictionary alloc] init];
    @synchronized(_events) {
        for(NSNumber *bid in _events) {
            [events setObject:[[_events objectForKey:bid] mutableCopy] forKey:bid];
        }
    }
    
    @synchronized(self) {
        [NSKeyedArchiver archiveRootObject:events toFile:cacheFile];
        [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
    }
}

-(void)clear {
    @synchronized(_events) {
        [_events removeAllObjects];
        [_events_sorted removeAllObjects];
        _highestEid = 0;
    }
}

-(void)addEvent:(Event *)event {
#ifndef EXTENSION
    @synchronized(_events) {
        NSMutableArray *events = [_events objectForKey:@(event.bid)];
        if(!events) {
            events = [[NSMutableArray alloc] init];
            [_events setObject:events forKey:@(event.bid)];
        }
        [events addObject:event];
        NSMutableDictionary *events_sorted = [_events_sorted objectForKey:@(event.bid)];
        if(!events_sorted) {
            events_sorted = [[NSMutableDictionary alloc] init];
            [_events_sorted setObject:events_sorted forKey:@(event.bid)];
        }
        [events_sorted setObject:event forKey:@(event.eid)];
        _dirty = YES;
    }
#endif
}

-(Event *)addJSONObject:(IRCCloudJSONObject *)object {
#ifdef EXTENSION
    return nil;
#else
    Event *event = [self event:object.eid buffer:object.bid];
    if(!event) {
        event = [[Event alloc] init];
        event.bid = object.bid;
        event.eid = object.eid;
        [self addEvent: event];
    }
    _dirty = YES;
    
    event.cid = object.cid;
    event.bid = object.bid;
    event.eid = object.eid;
    event.type = object.type;
    event.msg = [object objectForKey:@"msg"];
    event.hostmask = [object objectForKey:@"hostmask"];
    event.from = [object objectForKey:@"from"];
    event.fromMode = [object objectForKey:@"from_mode"];
    if([object objectForKey:@"newnick"])
        event.nick = [object objectForKey:@"newnick"];
    else
        event.nick = [object objectForKey:@"nick"];
    event.oldNick = [object objectForKey:@"oldnick"];
    event.server = [object objectForKey:@"server"];
    event.diff = [object objectForKey:@"diff"];
    event.isHighlight = [[object objectForKey:@"highlight"] boolValue];
    event.isSelf = [[object objectForKey:@"self"] boolValue];
    event.toChan = [[object objectForKey:@"to_chan"] boolValue];
    event.toBuffer = [[object objectForKey:@"to_buffer"] boolValue];
    event.ops = [object objectForKey:@"ops"];
    event.chan = [object objectForKey:@"chan"];
    if([object objectForKey:@"reqid"])
        event.reqId = [[object objectForKey:@"reqid"] intValue];
    else
        event.reqId = -1;
    event.color = [UIColor blackColor];
    event.bgColor = [UIColor whiteColor];
    event.rowType = 0;
    event.formatted = nil;
    event.formattedMsg = nil;
    event.groupMsg = nil;
    event.linkify = YES;
    event.targetMode = nil;
    event.pending = NO;
    event.monospace = NO;
    
    void (^formatter)(Event *event, IRCCloudJSONObject *object) = [_formatterMap objectForKey:object.type];
    if(formatter)
        formatter(event, object);
        
    if([object objectForKey:@"value"] && ![event.type hasPrefix:@"cap_"]) {
        event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"value"], event.msg];
    }

    if(event.isHighlight)
        event.bgColor = [UIColor highlightBackgroundColor];

    if(event.isSelf)
        event.bgColor = [UIColor selfBackgroundColor];
    
    if(event.eid > _highestEid)
        _highestEid = event.eid;
    
    return event;
#endif
}

-(Event *)event:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(_events) {
        return [[_events_sorted objectForKey:@(bid)] objectForKey:@(eid)];
    }
}

-(void)removeEvent:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(_events) {
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid == eid) {
                [[_events objectForKey:@(bid)] removeObject:event];
                [[_events_sorted objectForKey:@(bid)] removeObjectForKey:@(eid)];
                break;
            }
        }
        _dirty = YES;
    }
}

-(void)removeEventsForBuffer:(int)bid {
    @synchronized(_events) {
        [_events removeObjectForKey:@(bid)];
        [_events_sorted removeObjectForKey:@(bid)];
    }
}

-(void)pruneEventsForBuffer:(int)bid maxSize:(int)size {
    @synchronized(_events) {
        NSMutableArray *events = [_events objectForKey:@(bid)];
        while(events.count > size) {
            Event *e = [events objectAtIndex:0];
            [[_events_sorted objectForKey:@(bid)] removeObjectForKey:@(e.eid)];
            [events removeObject:e];
        }
    }
}

-(NSArray *)eventsForBuffer:(int)bid {
    @synchronized(_events) {
        if(_dirty) {
            [[_events objectForKey:@(bid)] sortUsingSelector:@selector(compare:)];
            _dirty = NO;
        }
        return [NSArray arrayWithArray:[_events objectForKey:@(bid)]];
    }
}

-(NSUInteger)sizeOfBuffer:(int)bid {
    @synchronized(_events) {
        return [[_events objectForKey:@(bid)] count];
    }
}

-(NSTimeInterval)lastEidForBuffer:(int)bid {
    @synchronized(_events) {
        if(_dirty) {
            [[_events objectForKey:@(bid)] sortUsingSelector:@selector(compare:)];
            _dirty = NO;
        }
        return [[[_events objectForKey:@(bid)] lastObject] eid];
    }
}

-(void)removeEventsBefore:(NSTimeInterval)min_eid buffer:(int)bid {
    @synchronized(_events) {
        NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
        for(Event *event in [_events objectForKey:@(bid)]) {
            if(event.eid < min_eid) {
                [eventsToRemove addObject:event];
            }
        }
        for(Event *event in eventsToRemove) {
            [[_events objectForKey:@(bid)] removeObject:event];
            [[_events_sorted objectForKey:@(bid)] removeObjectForKey:@(event.eid)];
        }
    }
}

-(int)unreadStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    if(![_events objectForKey:@(bid)])
        return 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = [[Ignore alloc] init];
    [ignore setIgnores:s.ignores];
    NSArray *copy;
    @synchronized(_events) {
        copy = [self eventsForBuffer:bid];
    }
    for(Event *event in copy.reverseObjectEnumerator) {
        if(event.eid <= lastSeenEid) {
            break;
        } else if([event isImportant:type]) {
            if(event.ignoreMask && [ignore match:event.ignoreMask])
                continue;
            return 1;
        }
    }
    return 0;
}

-(int)highlightCountForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    if(![_events objectForKey:@(bid)])
        return 0;
    int count = 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = [[Ignore alloc] init];
    [ignore setIgnores:s.ignores];
    NSArray *copy;
    @synchronized(_events) {
        copy = [self eventsForBuffer:bid];
    }
    for(Event *event in copy.reverseObjectEnumerator) {
        if(event.eid <= lastSeenEid) {
            break;
        } else if([event isImportant:type] && (event.isHighlight || [type isEqualToString:@"conversation"])) {
            if(event.ignoreMask && [ignore match:event.ignoreMask])
                continue;
            count++;
        }
    }
    return count;
}

-(int)highlightStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    if(![_events objectForKey:@(bid)])
        return 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = [[Ignore alloc] init];
    [ignore setIgnores:s.ignores];
    NSArray *copy;
    @synchronized(_events) {
        copy = [self eventsForBuffer:bid];
    }
    for(Event *event in copy.reverseObjectEnumerator) {
        if(event.eid <= lastSeenEid) {
            break;
        } else if([event isImportant:type] && (event.isHighlight || [type isEqualToString:@"conversation"])) {
            if(event.ignoreMask && [ignore match:event.ignoreMask])
                continue;
            return 1;
        }
    }
    return 0;
}

-(void)clearFormattingCache {
    @synchronized(_events) {
        for(NSNumber *bid in _events) {
            NSArray *events = [_events objectForKey:bid];
            for(Event *e in events)
                e.formatted = nil;
        }
    }
}

-(void)clearPendingAndFailed {
    @synchronized(_events) {
        NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
        for(NSNumber *bid in _events) {
            NSArray *events = [[_events objectForKey:bid] copy];
            for(Event *e in events) {
                if((e.pending || e.rowType == ROW_FAILED) && e.reqId != -1)
                    [eventsToRemove addObject:e];
            }
        }
        for(Event *e in eventsToRemove) {
            [[_events objectForKey:@(e.bid)] removeObject:e];
            [[_events_sorted objectForKey:@(e.bid)] removeObjectForKey:@(e.eid)];
            if(e.expirationTimer && [e.expirationTimer isValid])
                [e.expirationTimer invalidate];
            e.expirationTimer = nil;
        }
    }
}

@end
