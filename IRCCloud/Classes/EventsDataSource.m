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
#import "NetworkConnection.h"
#import "ImageCache.h"

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
    if(self->_isSelf)
        return NO;
    if(!_type)
        return NO;
    if(self->_rowType == ROW_THUMBNAIL || _rowType == ROW_FILE)
        return NO;
    if([self->_type isEqualToString:@"notice"] || [self->_type isEqualToString:@"channel_invite"]) {
        // Notices sent from the server (with no nick sender) aren't important
        // e.g. *** Looking up your hostname...
        if(self->_from.length == 0)
            return NO;
        
        // Notices and invites sent to a buffer shouldn't notify in the server buffer
        if([bufferType isEqualToString:@"console"] && (self->_toChan || _toBuffer))
            return NO;
    }

    return [self isMessage];
}
-(BOOL)isMessage {
    return ([self->_type isEqualToString:@"buffer_msg"]
            ||[self->_type isEqualToString:@"buffer_me_msg"]
            ||[self->_type isEqualToString:@"notice"]
            ||[self->_type isEqualToString:@"channel_invite"]
            ||[self->_type isEqualToString:@"callerid"]
            ||[self->_type isEqualToString:@"wallops"]);
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, eid: %f, group: %f, type: %@, from: %@, msg: %@, self: %i, header: %i, reqid: %i, pending: %i, formatted: %@}", _cid, _bid, _eid, _groupEid, _type, _from, _msg, _isSelf, _isHeader, _reqid, _pending, _formatted];
}
-(NSString *)ignoreMask {
    if(!_ignoreMask) {
        NSString *from = self->_from;
        if(!from.length)
            from = self->_nick;
        
        if(from) {
            self->_ignoreMask = [NSString stringWithFormat:@"%@!%@", from, _hostmask];
        }
    }
    return _ignoreMask;
}
-(Event *)copy {
    BOOL pending = self->_pending;
    self->_pending = NO;
    Event *e = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
    self->_pending = e.pending = pending;
    return e;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if(self) {
        decodeInt(self->_cid);
        decodeInt(self->_bid);
        decodeDouble(self->_eid);
        decodeObject(self->_type);
        decodeObject(self->_msg);
        decodeObject(self->_hostmask);
        decodeObject(self->_from);
        decodeObject(self->_fromMode);
        decodeObject(self->_nick);
        decodeObject(self->_oldNick);
        decodeObject(self->_server);
        decodeObject(self->_diff);
        decodeObject(self->_realname);
        decodeBool(self->_isHighlight);
        decodeBool(self->_isSelf);
        decodeBool(self->_toChan);
        decodeBool(self->_toBuffer);
        decodeObject(self->_color);
        decodeObject(self->_ops);
        decodeInt(self->_rowType);
        decodeBool(self->_linkify);
        decodeObject(self->_targetMode);
        decodeInt(self->_reqid);
        decodeBool(self->_pending);
        decodeBool(self->_monospace);
        decodeObject(self->_to);
        decodeObject(self->_command);
        decodeObject(self->_day);
        decodeObject(self->_ignoreMask);
        decodeObject(self->_chan);
        decodeObject(self->_entities);
        decodeFloat(self->_timestampPosition);
        decodeDouble(self->_serverTime);
        decodeObject(self->_avatar);
        decodeObject(self->_avatarURL);
        decodeObject(self->_fromNick);
        decodeObject(self->_msgid);
        decodeBool(self->_edited);
        decodeDouble(self->_lastEditEID);

        if(self->_rowType == ROW_TIMESTAMP)
            self->_bgColor = [UIColor timestampBackgroundColor];
        else if(self->_rowType == ROW_LASTSEENEID)
            self->_bgColor = [UIColor contentBackgroundColor];
        else
            decodeObject(self->_bgColor);
        
        if(self->_pending) {
            self->_height = 0;
            self->_pending = NO;
            self->_rowType = ROW_FAILED;
            self->_color = [UIColor networkErrorColor];
            self->_bgColor = [UIColor errorBackgroundColor];
        }
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(self->_cid);
    encodeInt(self->_bid);
    encodeDouble(self->_eid);
    encodeObject(self->_type);
    encodeObject(self->_msg);
    encodeObject(self->_hostmask);
    encodeObject(self->_from);
    encodeObject(self->_fromMode);
    encodeObject(self->_nick);
    encodeObject(self->_oldNick);
    encodeObject(self->_server);
    encodeObject(self->_diff);
    encodeObject(self->_realname);
    encodeBool(self->_isHighlight);
    encodeBool(self->_isSelf);
    encodeBool(self->_toChan);
    encodeBool(self->_toBuffer);
    @try {
        encodeObject(self->_color);
    }
    @catch (NSException *exception) {
        self->_color = [UIColor blackColor];
        encodeObject(self->_color);
    }
    encodeObject(self->_ops);
    encodeInt(self->_rowType);
    encodeBool(self->_linkify);
    encodeObject(self->_targetMode);
    encodeInt(self->_reqid);
    encodeBool(self->_pending);
    encodeBool(self->_monospace);
    encodeObject(self->_to);
    encodeObject(self->_command);
    encodeObject(self->_day);
    encodeObject(self->_ignoreMask);
    encodeObject(self->_chan);
    encodeObject(self->_entities);
    encodeFloat(self->_timestampPosition);
    encodeDouble(self->_serverTime);
    encodeObject(self->_avatar);
    encodeObject(self->_avatarURL);
    encodeObject(self->_fromNick);
    encodeObject(self->_msgid);
    encodeBool(self->_edited);
    encodeDouble(self->_lastEditEID);

    if(self->_rowType != ROW_TIMESTAMP && _rowType != ROW_LASTSEENEID)
        encodeObject(self->_bgColor);
}

-(NSTimeInterval)time {
    if(self->_serverTime > 0)
        return _serverTime / 1000;
    else
        return (self->_eid / 1000000) + [NetworkConnection sharedInstance].clockOffset;
}

-(NSString *)UUID {
    if(!_UUID)
        self->_UUID = [[NSUUID UUID] UUIDString];
    return _UUID;
}

-(NSString *)reply {
    if([self->_entities objectForKey:@"reply"])
        return [self->_entities objectForKey:@"reply"];
    else
        return [[self->_entities objectForKey:@"known_client_tags"] objectForKey:@"reply"];
}

-(NSURL *)avatar:(int)size {
#ifndef ENTERPRISE
    BOOL isIRCCloudAvatar = NO;
    if([self isMessage] && (!_cachedAvatarURL || size != self->_cachedAvatarSize || ![[ImageCache sharedInstance] isValidURL:self->_cachedAvatarURL])) {
        if(self->_avatar.length) {
            self->_cachedAvatarURL = [NSURL URLWithString:[[NetworkConnection sharedInstance].avatarURITemplate relativeStringWithVariables:@{@"id":self->_avatar, @"modifiers":[NSString stringWithFormat:@"s%i", size]} error:nil]];
        } else if([self->_avatarURL hasPrefix:@"https://"]) {
            if([self->_avatarURL containsString:@"{size}"]) {
                CSURITemplate *template = [CSURITemplate URITemplateWithString:self->_avatarURL error:nil];
                if(size <= 72)
                    self->_cachedAvatarURL = [NSURL URLWithString:[template relativeStringWithVariables:@{@"size":@"72"} error:nil]];
                else if(size <= 192)
                    self->_cachedAvatarURL = [NSURL URLWithString:[template relativeStringWithVariables:@{@"size":@"192"} error:nil]];
                else
                    self->_cachedAvatarURL = [NSURL URLWithString:[template relativeStringWithVariables:@{@"size":@"512"} error:nil]];
            } else {
                self->_cachedAvatarURL = [NSURL URLWithString:self->_avatarURL];
            }
        } else {
            self->_cachedAvatarURL = nil;
            if([self->_hostmask rangeOfString:@"@"].location != NSNotFound) {
                NSString *ident = [self->_hostmask substringToIndex:[self->_hostmask rangeOfString:@"@"].location];
                if([ident hasPrefix:@"~"])
                    ident = [ident substringFromIndex:1];
                if([ident hasPrefix:@"uid"] || [ident hasPrefix:@"sid"]) {
                    ident = [ident substringFromIndex:3];
                    if(ident.length && [ident intValue]) {
                        self->_cachedAvatarURL = [NSURL URLWithString:[[NetworkConnection sharedInstance].avatarRedirectURITemplate relativeStringWithVariables:@{@"id":ident, @"modifiers":[NSString stringWithFormat:@"s%i", size]} error:nil]];
                        if([[ImageCache sharedInstance] isValidURL:self->_cachedAvatarURL])
                            isIRCCloudAvatar = YES;
                        else
                            self->_cachedAvatarURL = nil;
                    }
                }
            }
            if(!_cachedAvatarURL) {
                NSString *n = self->_realname.lowercaseString;
                if(n.length) {
                    NSArray *results = [[ColorFormatter email] matchesInString:n options:0 range:NSMakeRange(0, n.length)];
                    if(results.count == 1) {
                        NSString *email = [n substringWithRange:[results.firstObject range]];
                        self->_cachedAvatarURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.gravatar.com/avatar/%@?size=%i&default=404", [ImageCache md5:email].lowercaseString, size]];
                        isIRCCloudAvatar = NO;
                    }
                }
            }
        }
        if(self->_cachedAvatarURL && !_avatar.length && !isIRCCloudAvatar && ![[ServersDataSource sharedInstance] getServer:self->_cid].isSlack) {
            BOOL inlineMediaPref = NO;
            Buffer *buffer = [[BuffersDataSource sharedInstance] getBuffer:self->_bid];
            NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
            if(buffer && prefs) {
                inlineMediaPref = [[prefs objectForKey:@"inlineimages"] boolValue];
                if(inlineMediaPref) {
                    NSDictionary *disableMap;
                    
                    if([buffer.type isEqualToString:@"channel"]) {
                        disableMap = [prefs objectForKey:@"channel-inlineimages-disable"];
                    } else {
                        disableMap = [prefs objectForKey:@"buffer-inlineimages-disable"];
                    }
                    
                    if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] boolValue])
                        inlineMediaPref = NO;
                } else {
                    NSDictionary *enableMap;
                    
                    if([buffer.type isEqualToString:@"channel"]) {
                        enableMap = [prefs objectForKey:@"channel-inlineimages"];
                    } else {
                        enableMap = [prefs objectForKey:@"buffer-inlineimages"];
                    }
                    
                    if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] boolValue])
                        inlineMediaPref = YES;
                }
                
                if([[NSUserDefaults standardUserDefaults] boolForKey:@"inlineWifiOnly"] && ![NetworkConnection sharedInstance].isWifi) {
                    inlineMediaPref = NO;
                }
            }
            if(!inlineMediaPref)
                self->_cachedAvatarURL = nil;
        }
    }
    if(self->_cachedAvatarURL)
        self->_cachedAvatarSize = size;
#endif
    return _cachedAvatarURL;
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
    if(self) {
        [NSKeyedArchiver setClassName:@"IRCCloud.Event" forClass:Event.class];
        [NSKeyedUnarchiver setClass:Event.class forClassName:@"IRCCloud.Event"];

#ifndef EXTENSION
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"events"];
            
            @try {
                self->_events = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
            } @catch(NSException *e) {
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[ServersDataSource sharedInstance] clear];
                [[BuffersDataSource sharedInstance] clear];
                [[ChannelsDataSource sharedInstance] clear];
                [[UsersDataSource sharedInstance] clear];
            }
            [self->_events removeAllObjects];
        }
#endif
        self->_dirtyBIDs = [[NSMutableDictionary alloc] init];
        self->_lastEIDs = [[NSMutableDictionary alloc] init];
        self->_events_sorted = [[NSMutableDictionary alloc] init];
        self->_msgIDs = [[NSMutableDictionary alloc] init];
        if(self->_events) {
            for(NSNumber *bid in _events) {
                NSMutableArray *events = [self->_events objectForKey:bid];
                NSMutableDictionary *events_sorted = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *msgids = [[NSMutableDictionary alloc] init];
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
                    }
                }

                for(Event *e in events) {
                    [events_sorted setObject:e forKey:@(e.eid)];
                    if(e.msgid.length)
                        [msgids setObject:e forKey:e.msgid];
                    if(!e.pending) {
                        if(![self->_lastEIDs objectForKey:@(e.bid)] || [[self->_lastEIDs objectForKey:@(e.bid)] doubleValue] < e.eid)
                            [self->_lastEIDs setObject:@(e.eid) forKey:@(e.bid)];
                    }
                }
                [self->_events_sorted setObject:events_sorted forKey:bid];
                [self->_msgIDs setObject:msgids forKey:bid];
                [[self->_events objectForKey:bid] sortUsingSelector:@selector(compare:)];
            }
            [self clearPendingAndFailed];
        } else {
            self->_events = [[NSMutableDictionary alloc] init];
        }
        
        void (^error)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            event.from = @"";
            event.color = [UIColor networkErrorColor];
            event.bgColor = [UIColor errorBackgroundColor];
        };
        
        void (^notice)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            event.bgColor = [UIColor noticeBackgroundColor];
            if(object) {
                event.chan = [object objectForKey:@"target"];
                event.nick = [object objectForKey:@"target"];
                if([[object objectForKey:@"statusmsg"] isKindOfClass:[NSString class]])
                    event.targetMode = [object objectForKey:@"statusmsg"];
                else
                    event.targetMode = nil;
            }
            event.monospace = YES;
            event.isHighlight = NO;
        };
        
        void (^status)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            event.from = @"";
            event.bgColor = [UIColor statusBackgroundColor];
            if([object objectForKey:@"parts"] && [[object objectForKey:@"parts"] length] > 0)
                event.msg = [NSString stringWithFormat:@"%@: %@", [object objectForKey:@"parts"], event.msg];
            else if([object objectForKey:@"msg"])
                event.msg = [object objectForKey:@"msg"];
            event.monospace = YES;
            if(![event.type isEqualToString:@"server_motd"] && ![event.type isEqualToString:@"zurna_motd"])
                event.linkify = NO;
        };
        
        void (^unhandled_line)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            if(object) {
                event.from = @"";
                event.msg = @"";
                if([object objectForKey:@"command"])
                    event.msg = [[object objectForKey:@"command"] stringByAppendingString:@" "];
                if([object objectForKey:@"raw"])
                    event.msg = [event.msg stringByAppendingString:[object objectForKey:@"raw"]];
                else
                    event.msg = [event.msg stringByAppendingString:[object objectForKey:@"msg"]];
            }
            event.color = [UIColor networkErrorColor];
            event.bgColor = [UIColor errorBackgroundColor];
        };
        
        void (^kicked_channel)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            event.from = @"";
            if(object) {
                event.oldNick = [object objectForKey:@"nick"];
                event.nick = [object objectForKey:@"kicker"];
                event.fromMode = [object objectForKey:@"kicker_mode"];
                event.hostmask = [object objectForKey:@"kicker_hostmask"];
            }
            event.color = [UIColor timestampColor];
            event.linkify = NO;
            if(event.isSelf)
                event.rowType = ROW_SOCKETCLOSED;
        };
        
        void (^motd)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            if(object) {
                NSArray *lines = [object objectForKey:@"lines"];
                event.from = @"";
                if([lines count]) {
                    NSMutableString *motd = [[NSMutableString alloc] init];
                    if([[object objectForKey:@"start"] length]) {
                        [motd appendFormat:@"%@\n", [object objectForKey:@"start"]];
                    }
                    
                    for(NSString *line in lines) {
                        [motd appendFormat:@"%@\n", line];
                    }
                    event.msg = motd;
                }
            }
            event.bgColor = [UIColor selfBackgroundColor];
            event.monospace = YES;
        };
        
        void (^cap)(Event *event, IRCCloudJSONObject *object) = ^(Event *event, IRCCloudJSONObject *object) {
            event.bgColor = [UIColor statusBackgroundColor];
            event.linkify = NO;
            event.from = nil;
            if(object) {
                if([event.type isEqualToString:@"cap_ls"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Server supports: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_list"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Enabled: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_req"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Requesting: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_ack"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Acknowledged: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_nak"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Rejected: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_new"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Server added: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_del"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c Server removed: ", BOLD, BOLD];
                else if([event.type isEqualToString:@"cap_raw"])
                    event.msg = [object objectForKey:@"line"];
                else if([event.type isEqualToString:@"cap_invalid"])
                    event.msg = [NSString stringWithFormat:@"%cCAP%c %@", BOLD, BOLD, event.msg];
                if([object objectForKey:@"caps"])
                    event.msg = [event.msg stringByAppendingString:[[object objectForKey:@"caps"] componentsJoinedByString:@" | "]];
            }
            event.monospace = YES;
        };
        
        self->_formatterMap = @{@"too_fast":error, @"sasl_fail":error, @"sasl_too_long":error, @"sasl_aborted":error,
                          @"sasl_already":error, @"no_bots":error, @"msg_services":error, @"bad_ping":error, @"error":status,
                          @"not_for_halfops":error, @"ambiguous_error_message":error, @"list_syntax":error, @"who_syntax":error,
                          @"wait":status, @"stats": status, @"statslinkinfo": status, @"statscommands": status, @"statscline": status, @"statsnline": status, @"statsiline": status, @"statskline": status, @"statsqline": status, @"statsyline": status, @"statsbline": status, @"statsgline": status, @"statstline": status, @"statseline": status, @"statsvline": status, @"statslline": status, @"statsuptime": status, @"statsoline": status, @"statshline": status, @"statssline": status, @"statsuline": status, @"statsdebug": status, @"endofstats": status, @"spamfilter": status,
                          @"server_motdstart": status, @"server_welcome": status, @"server_endofmotd": status,
                          @"server_nomotd": status, @"server_luserclient": status, @"server_luserop": status,
                          @"server_luserconns": status, @"server_luserme": status, @"server_n_local": status,
                          @"server_luserchannels": status, @"server_n_global": status, @"server_yourhost": status,
                          @"server_created": status, @"server_luserunknown": status,
                          @"btn_metadata_set": status, @"logged_in_as": status, @"sasl_success": status, @"you_are_operator": status,
                          @"server_snomask": status, @"starircd_welcome": status, @"zurna_motd": status, @"codepage": status, @"logged_out": status,
                          @"nick_locked": status, @"text": status, @"admin_info": status,
                          @"cap_ls": cap, @"cap_list": cap, @"cap_req": cap, @"cap_ack": cap, @"cap_raw": cap, @"cap_nak": cap, @"cap_new": cap, @"cap_del": cap, @"cap_invalid": cap, 
                          @"unhandled_line":unhandled_line, @"unparsed_line":unhandled_line,
                          @"kicked_channel":kicked_channel, @"you_kicked_channel":kicked_channel,
                          @"motd_response":motd, @"server_motd":motd, @"info_response":motd,
                          @"notice":notice, @"newsflash":notice, @"generic_server_info":notice, @"list_usage":notice,
                          @"buffer_msg": ^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  if([[object objectForKey:@"statusmsg"] isKindOfClass:[NSString class]])
                                      event.targetMode = [object objectForKey:@"statusmsg"];
                                  else
                                      event.targetMode = nil;
                              }
                          },
                          @"socket_closed":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              event.rowType = ROW_SOCKETCLOSED;
                              event.color = [UIColor timestampColor];
                              if(object) {
                                  if([object objectForKey:@"pool_lost"])
                                      event.msg = @"Connection pool lost";
                                  else if([object objectForKey:@"server_ping_timeout"])
                                      event.msg = @"Server PING timed out";
                                  else if([object objectForKey:@"reason"] && [[object objectForKey:@"reason"] length] > 0) {
                                      event.msg = [@"Connection lost: " stringByAppendingString:[EventsDataSource reason:[object objectForKey:@"reason"]]];
                                  } else if([object objectForKey:@"abnormal"])
                                      event.msg = @"Connection closed unexpectedly";
                                  else
                                      event.msg = @"";
                              }
                          },
                          @"user_channel_mode":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.targetMode = [object objectForKey:@"newmode"];
                                  event.chan = [object objectForKey:@"channel"];
                              }
                              event.isSelf = NO;
                          },
                          @"buffer_me_msg":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  if([[object objectForKey:@"display_name"] isKindOfClass:NSString.class])
                                      event.nick = [object objectForKey:@"display_name"];
                                  else
                                      event.nick = [object objectForKey:@"from"];
                                  event.fromNick = [object objectForKey:@"from"];
                                  event.from = @"";
                              }
                          },
                          @"nickname_in_use":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.from = [object objectForKey:@"nick"];
                              }
                              event.msg = @"is already in use";
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                          },
                          @"connecting_cancelled":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  if([object objectForKey:@"sts"])
                                      event.msg = @"Upgrading connection security";
                                  else
                                      event.msg = @"Cancelled";
                              }
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                          },
                          @"connecting_failed":^(Event *event, IRCCloudJSONObject *object) {
                              event.rowType = ROW_SOCKETCLOSED;
                              event.color = [UIColor timestampColor];
                              event.from = @"";
                              if(object) {
                                  NSString *reason = [object objectForKey:@"reason"];
                                  if([reason isKindOfClass:[NSString class]] && [reason length]) {
                                      if([reason isEqualToString:@"ssl_verify_error"]) {
                                          NSDictionary *error = [object objectForKey:@"ssl_verify_error"];
                                          if([error objectForKey:@"type"]) {
                                              event.msg = [@"Strict transport security error: " stringByAppendingString:[EventsDataSource SSLreason:error]];
                                          } else {
                                              event.msg = @"Strict transport security error";
                                          }
                                      } else {
                                          event.msg = [@"Failed to connect: " stringByAppendingString:[EventsDataSource reason:reason]];
                                      }
                                  } else {
                                      event.msg = @"Failed to connect.";
                                  }
                              }
                          },
                          @"quit_server":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              event.msg = @"⇐ You disconnected";
                              event.color = [UIColor timestampColor];
                              event.isSelf = NO;
                          },
                          @"self_details":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              if(object) {
                                  event.from = @"";
                                  if([[object objectForKey:@"user"] length]) {
                                      event.msg = [NSString stringWithFormat:@"Your hostmask: %c%@%c", BOLD, [object objectForKey:@"usermask"], BOLD];
                                      if([object objectForKey:@"server_realname"]) {
                                          Event *e1 = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:event]];
                                          e1.eid++;
                                          e1.msg = [NSString stringWithFormat:@"Your name: %c%@%c", BOLD, [object objectForKey:@"server_realname"], BOLD];
                                          e1.linkify = YES;
                                          [self addEvent:e1];
                                      }
                                  } else if([object objectForKey:@"server_realname"]) {
                                      event.msg = [NSString stringWithFormat:@"Your name: %c%@%c", BOLD, [object objectForKey:@"server_realname"], BOLD];
                                      event.linkify = YES;
                                  }
                              }
                              event.monospace = YES;
                          },
                          @"myinfo":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"Host: %@\n", [object objectForKey:@"server"]];
                                  event.msg = [event.msg stringByAppendingFormat:@"IRCd: %@\n", [object objectForKey:@"version"]];
                                  event.msg = [event.msg stringByAppendingFormat:@"User modes: %@\n", [object objectForKey:@"user_modes"]];
                                  event.msg = [event.msg stringByAppendingFormat:@"Channel modes: %@\n", [object objectForKey:@"channel_modes"]];
                                  if([[object objectForKey:@"rest"] length])
                                      event.msg = [event.msg stringByAppendingFormat:@"Parametric channel modes: %@\n", [object objectForKey:@"rest"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.monospace = YES;
                          },
                          @"user_mode":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"Your user mode is: %c+%@%c", BOLD, [object objectForKey:@"newmode"], BOLD];
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.monospace = YES;
                          },
                          @"your_unique_id":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"Your unique ID is: %c%@%c", BOLD, [object objectForKey:@"unique_id"], BOLD];
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.monospace = YES;
                          },
                          @"kill":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  event.msg = @"You were killed";
                                  if([object objectForKey:@"from"])
                                      event.msg = [event.msg stringByAppendingFormat:@" by %@", [object objectForKey:@"from"]];
                                  if([object objectForKey:@"killer_hostmask"])
                                      event.msg = [event.msg stringByAppendingFormat:@" (%@)", [object objectForKey:@"killer_hostmask"]];
                                  if([object objectForKey:@"reason"])
                                      event.msg = [event.msg stringByAppendingFormat:@": %@", [object objectForKey:@"reason"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                          },
                          @"banned":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  event.msg = @"You were banned";
                                  if([object objectForKey:@"server"])
                                      event.msg = [event.msg stringByAppendingFormat:@" from %@", [object objectForKey:@"server"]];
                                  if([object objectForKey:@"reason"])
                                      event.msg = [event.msg stringByAppendingFormat:@": %@", [object objectForKey:@"reason"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                          },
                          @"channel_topic":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.from = [[object objectForKey:@"author"] length]?[object objectForKey:@"author"]:[object objectForKey:@"server"];
                                  if([object objectForKey:@"topic"] && [[object objectForKey:@"topic"] length])
                                      event.msg = [NSString stringWithFormat:@"set the topic: %@", [object objectForKey:@"topic"]];
                                  else
                                      event.msg = @"cleared the topic";
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                          },
                          @"channel_mode":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.nick = event.from;
                                  event.from = @"";
                                  if(event.server && [event.server isKindOfClass:[NSString class]] && event.server.length)
                                      event.msg = [NSString stringWithFormat:@"Channel mode set to: %c%@%c by the server %c%@%c", BOLD, [object objectForKey:@"diff"], CLEAR, BOLD, event.server, CLEAR];
                                  else
                                      event.msg = [NSString stringWithFormat:@"Channel mode set to: %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                              }
                              event.linkify = NO;
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.isSelf = NO;
                          },
                          @"channel_mode_is":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  if([[object objectForKey:@"diff"] length] > 0)
                                      event.msg = [NSString stringWithFormat:@"Channel mode is: %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                                  else
                                      event.msg = @"No channel mode";
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                          },
                          @"channel_mode_list_change":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  BOOL unknown = YES;
                                  NSDictionary *ops = [object objectForKey:@"ops"];
                                  if(ops) {
                                      NSArray *add = [ops objectForKey:@"add"];
                                      if(add.count > 0) {
                                          NSDictionary *op = [add objectAtIndex:0];
                                          if([[op objectForKey:@"mode"] isEqualToString:@"b"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"banned %c%@%c (%c14+b%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"e"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"exempted %c%@%c from bans (%c14+e%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"q"]) {
                                              if([[op objectForKey:@"param"] rangeOfString:@"@"].location == NSNotFound && [[op objectForKey:@"param"] rangeOfString:@"$"].location == NSNotFound) {
                                                  event.type = @"user_channel_mode";
                                              } else {
                                                  event.nick = event.from;
                                                  event.from = @"";
                                                  event.msg = [NSString stringWithFormat:@"quieted %c%@%c (%c14+q%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              }
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"I"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"added %c%@%c to the invite list (%c14+I%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          }
                                      }
                                      NSArray *remove = [ops objectForKey:@"remove"];
                                      if(remove.count > 0) {
                                          NSDictionary *op = [remove objectAtIndex:0];
                                          if([[op objectForKey:@"mode"] isEqualToString:@"b"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"un-banned %c%@%c (%c14-b%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"e"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"un-exempted %c%@%c from bans (%c14-e%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"q"]) {
                                              if([[op objectForKey:@"param"] rangeOfString:@"@"].location == NSNotFound && [[op objectForKey:@"param"] rangeOfString:@"$"].location == NSNotFound) {
                                                  event.type = @"user_channel_mode";
                                              } else {
                                                  event.nick = event.from;
                                                  event.from = @"";
                                                  event.msg = [NSString stringWithFormat:@"un-quieted %c%@%c (%c14-q%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              }
                                              unknown = NO;
                                          } else if([[op objectForKey:@"mode"] isEqualToString:@"I"]) {
                                              event.nick = event.from;
                                              event.from = @"";
                                              event.msg = [NSString stringWithFormat:@"removed %c%@%c from the invite list (%c14-I%c)", BOLD, [op objectForKey:@"param"], BOLD, COLOR_MIRC, COLOR_MIRC];
                                              unknown = NO;
                                          }
                                      }
                                  }
                                  if(unknown) {
                                      event.nick = event.from;
                                      event.from = @"";
                                      event.msg = [NSString stringWithFormat:@"set channel mode %c%@%c", BOLD, [object objectForKey:@"diff"], BOLD];
                                  }
                              }
                              event.isSelf = NO;
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                          },
                          @"hidden_host_set":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"hidden_host"], BOLD, event.msg];
                              event.monospace = YES;
                          },
                          @"inviting_to_channel":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"You invited %@ to join %@", [object objectForKey:@"recipient"], [object objectForKey:@"channel"]];
                              event.bgColor = [UIColor noticeBackgroundColor];
                              event.monospace = YES;
                          },
                          @"channel_invite":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"Invite to join %@", [object objectForKey:@"channel"]];
                                  event.oldNick = [object objectForKey:@"channel"];
                              }
                              event.bgColor = [UIColor noticeBackgroundColor];
                              event.monospace = YES;
                          },
                          @"callerid":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = event.nick;
                              event.isHighlight = YES;
                              event.linkify = NO;
                              event.monospace = YES;
                              if(object) {
                                  event.hostmask = [object objectForKey:@"usermask"];
                                  event.msg = [event.msg stringByAppendingFormat:@" Tap to add %c%@%c to the whitelist.", BOLD, event.nick, CLEAR];
                              }
                          },
                          @"target_callerid":^(Event *event, IRCCloudJSONObject *object) {
                              if(object)
                                  event.from = [object objectForKey:@"target_nick"];
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              event.monospace = YES;
                          },
                          @"target_notified":^(Event *event, IRCCloudJSONObject *object) {
                              if(object)
                                  event.from = [object objectForKey:@"target_nick"];
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              event.monospace = YES;
                          },
                          @"link_channel":^(Event *event, IRCCloudJSONObject *object) {
                              event.from = @"";
                              if(object) {
                                  if([[object objectForKey:@"invalid_chan"] isKindOfClass:[NSString class]] && [[object objectForKey:@"invalid_chan"] length]) {
                                      if([[object objectForKey:@"valid_chan"] isKindOfClass:[NSString class]] && [[object objectForKey:@"valid_chan"] length]) {
                                          event.msg = [NSString stringWithFormat:@"%@ → %@ %@", [object objectForKey:@"invalid_chan"], [object objectForKey:@"valid_chan"], event.msg];
                                      } else {
                                          event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"invalid_chan"], event.msg];
                                      }
                                  }
                              }
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              event.monospace = YES;
                          },
                          @"version":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"server_version"], BOLD, [object objectForKey:@"comments"]];
                              event.monospace = YES;
                          },
                          @"rehashed_config":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor noticeBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"Rehashed config: %@ (%@)", [object objectForKey:@"file"], event.msg];
                              event.monospace = YES;
                          },
                          @"knock":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor noticeBackgroundColor];
                              event.linkify = NO;
                              event.monospace = YES;
                              if(object) {
                                  if(event.nick.length) {
                                      event.from = event.nick;
                                      if(event.hostmask.length)
                                          event.msg = [event.msg stringByAppendingFormat:@" (%@)", event.hostmask];
                                  } else {
                                      event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"userhost"], event.msg];
                                  }
                              }
                          },
                          @"rehashed_config":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor noticeBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              if(object)
                                  event.msg = [NSString stringWithFormat:@"Rehashed config: %@ (%@)", [object objectForKey:@"file"], event.msg];
                              event.monospace = YES;
                          },
                          @"unknown_umode":^(Event *event, IRCCloudJSONObject *object) {
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              if(object && [[object objectForKey:@"flag"] length])
                                  event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"flag"], BOLD, event.msg];
                          },
                          @"kill_deny":^(Event *event, IRCCloudJSONObject *object) {
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              if(object)
                                  event.from = [object objectForKey:@"channel"];
                          },
                          @"chan_own_priv_needed":^(Event *event, IRCCloudJSONObject *object) {
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              if(object)
                                  event.from = [object objectForKey:@"channel"];
                          },
                          @"chan_forbidden":^(Event *event, IRCCloudJSONObject *object) {
                              event.color = [UIColor networkErrorColor];
                              event.bgColor = [UIColor errorBackgroundColor];
                              if(object)
                                  event.from = [object objectForKey:@"channel"];
                          },
                          @"time":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.from = @"";
                              event.monospace = YES;
                              if(object) {
                                  event.msg = [object objectForKey:@"time_string"];
                                  if([[object objectForKey:@"time_stamp"] length]) {
                                      event.msg = [event.msg stringByAppendingFormat:@" (%@)", [object objectForKey:@"time_stamp"]];
                                  }
                                  event.msg = [event.msg stringByAppendingFormat:@" — %c%@%c", BOLD, [object objectForKey:@"time_server"], CLEAR];
                              }
                          },
                          @"watch_status":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              if(object) {
                                  event.from = [object objectForKey:@"watch_nick"];
                                  event.msg = [event.msg stringByAppendingFormat:@" (%@@%@)", [object objectForKey:@"username"], [object objectForKey:@"userhost"]];
                              }
                              event.monospace = YES;
                          },
                          @"sqline_nick":^(Event *event, IRCCloudJSONObject *object) {
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              if(object)
                                  event.from = [object objectForKey:@"charset"];
                              event.monospace = YES;
                          },
                          @"you_parted_channel":^(Event *event, IRCCloudJSONObject *object) {
                              event.rowType = ROW_SOCKETCLOSED;
                          },
                          @"user_chghost":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"changed host: %@@%@ → %@@%@", [object objectForKey:@"user"], [object objectForKey:@"userhost"], [object objectForKey:@"from_name"], [object objectForKey:@"from_host"]];
                              }
                              event.color = [UIColor collapsedRowTextColor];
                              event.linkify = NO;
                          },
                          @"loaded_module":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"module"], BOLD, [object objectForKey:@"msg"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.monospace = YES;
                          },
                          @"unloaded_module":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"%c%@%c %@", BOLD, [object objectForKey:@"module"], BOLD, [object objectForKey:@"msg"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = NO;
                              event.monospace = YES;
                          },
                          @"invite_notify":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"invited %@ to join %@", [object objectForKey:@"target"], [object objectForKey:@"channel"]];
                              }
                              event.bgColor = [UIColor statusBackgroundColor];
                              event.linkify = YES;
                              event.monospace = YES;
                          },
                          @"channel_name_change":^(Event *event, IRCCloudJSONObject *object) {
                              if(object) {
                                  event.msg = [NSString stringWithFormat:@"renamed the channel: %@ → %c%@%c", [object objectForKey:@"old_name"], BOLD, [object objectForKey:@"new_name"], BOLD];
                              }
                              event.color = [UIColor timestampColor];
                          },
      };
    }
    return self;
}

-(void)serialize {
#ifndef EXTENSION
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"events"];
    
    NSMutableDictionary *events = [[NSMutableDictionary alloc] init];
    NSArray *bids;
    @synchronized(self->_events) {
        bids = self->_events.allKeys;
    }
    
    for(NSNumber *bid in bids) {
        NSMutableArray *e;
        @synchronized(self->_events) {
            e = [[self->_events objectForKey:bid] mutableCopy];
        }
        [e sortUsingSelector:@selector(compare:)];
        if(e.count > 50) {
            Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid.intValue];
            if(b && !b.scrolledUp && [self highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0) {
                e = [[e subarrayWithRange:NSMakeRange(e.count - 50, 50)] mutableCopy];
            }
        }
        if(e && bid)
            [events setObject:e forKey:bid];
    }
    
    @synchronized(self) {
        @try {
            [NSKeyedArchiver archiveRootObject:events toFile:cacheFile];
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
#endif
}

-(void)clear {
    @synchronized(self->_events) {
        [self->_events removeAllObjects];
        [self->_events_sorted removeAllObjects];
        [self->_msgIDs removeAllObjects];
        [self->_dirtyBIDs removeAllObjects];
        [self->_lastEIDs removeAllObjects];
        CLS_LOG(@"EventsDataSource cleared");
    }
}

-(void)addEvent:(Event *)event {
#ifndef EXTENSION
    @synchronized(self->_events) {
        NSMutableArray *events = [self->_events objectForKey:@(event.bid)];
        if(!events) {
            events = [[NSMutableArray alloc] init];
            [self->_events setObject:events forKey:@(event.bid)];
        }
        [events addObject:event];
        NSMutableDictionary *events_sorted = [self->_events_sorted objectForKey:@(event.bid)];
        if(!events_sorted) {
            events_sorted = [[NSMutableDictionary alloc] init];
            [self->_events_sorted setObject:events_sorted forKey:@(event.bid)];
        }
        [events_sorted setObject:event forKey:@(event.eid)];
        if(event.msgid.length) {
            NSMutableDictionary *msgids = [self->_msgIDs objectForKey:@(event.bid)];
            if(!msgids) {
                msgids = [[NSMutableDictionary alloc] init];
                [self->_msgIDs setObject:msgids forKey:@(event.bid)];
            }
            [msgids setObject:event forKey:event.msgid];
        }
        if(!event.pending && (![self->_lastEIDs objectForKey:@(event.bid)] || [[self->_lastEIDs objectForKey:@(event.bid)] doubleValue] < event.eid)) {
            [self->_lastEIDs setObject:@(event.eid) forKey:@(event.bid)];
        } else {
            [self->_dirtyBIDs setObject:@YES forKey:@(event.bid)];
        }

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
        if([[object objectForKey:@"msgid"] isKindOfClass:[NSString class]])
            event.msgid = [object objectForKey:@"msgid"];
        else
            event.msgid = nil;
        [self addEvent: event];
    }
    
    event.cid = object.cid;
    event.bid = object.bid;
    event.eid = object.eid;
    event.type = object.type;
    event.msg = [[object objectForKey:@"msg"] precomposedStringWithCanonicalMapping];
    event.hostmask = [object objectForKey:@"hostmask"];
    if([[object objectForKey:@"display_name"] isKindOfClass:NSString.class])
        event.from = [object objectForKey:@"display_name"];
    else
        event.from = [object objectForKey:@"from"];
    event.fromMode = [object objectForKey:@"from_mode"];
    event.fromNick = [object objectForKey:@"from"];
    if([object objectForKey:@"newnick"])
        event.nick = [object objectForKey:@"newnick"];
    else
        event.nick = [object objectForKey:@"nick"];
    if([[object objectForKey:@"from_realname"] isKindOfClass:[NSString class]])
        event.realname = [object objectForKey:@"from_realname"];
    else
        event.realname = nil;
    event.oldNick = [object objectForKey:@"oldnick"];
    if([[object objectForKey:@"from_realname"] isKindOfClass:[NSString class]])
        event.server = [object objectForKey:@"server"];
    else
        event.server = nil;
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
    event.color = [UIColor messageTextColor];
    event.bgColor = [UIColor contentBackgroundColor];
    event.rowType = 0;
    event.formatted = nil;
    event.formattedMsg = nil;
    event.formattedNick = nil;
    event.formattedRealname = nil;
    event.groupMsg = nil;
    event.linkify = YES;
    event.targetMode = nil;
    event.pending = NO;
    event.monospace = NO;
    event.entities = [object objectForKey:@"entities"];
    event.serverTime = [[object objectForKey:@"server_time"] doubleValue];
    if([[object objectForKey:@"avatar"] isKindOfClass:[NSString class]])
        event.avatar = [object objectForKey:@"avatar"];
    else
        event.avatar = nil;
    if([[object objectForKey:@"avatar_url"] isKindOfClass:[NSString class]])
        event.avatarURL = [object objectForKey:@"avatar_url"];
    else
        event.avatarURL = nil;
    if([[object objectForKey:@"msgid"] isKindOfClass:[NSString class]])
        event.msgid = [object objectForKey:@"msgid"];
    else
        event.msgid = nil;

    if([event isMessage] && !event.from.length && event.server.length) {
        event.from = event.fromNick = event.server;
    }

    void (^formatter)(Event *event, IRCCloudJSONObject *object) = [self->_formatterMap objectForKey:object.type];
    if(formatter)
        formatter(event, object);
        
    if([object objectForKey:@"value"] && ![event.type hasPrefix:@"cap_"]) {
        event.msg = [NSString stringWithFormat:@"%@ %@", [object objectForKey:@"value"], event.msg];
    }

    if(event.isHighlight)
        event.bgColor = [UIColor highlightBackgroundColor];

    if(event.isSelf && event.rowType != ROW_SOCKETCLOSED && ![event.type isEqualToString:@"notice"])
        event.bgColor = [UIColor selfBackgroundColor];
    
    return event;
#endif
}

-(Event *)event:(NSTimeInterval)eid buffer:(int)bid {
    return [[self->_events_sorted objectForKey:@(bid)] objectForKey:@(eid)];
}

-(Event *)message:(NSString *)msgid buffer:(int)bid {
    return [[self->_msgIDs objectForKey:@(bid)] objectForKey:msgid];
}

-(void)removeEvent:(NSTimeInterval)eid buffer:(int)bid {
    @synchronized(self->_events) {
        for(Event *event in [self->_events objectForKey:@(bid)]) {
            if(event.eid == eid) {
                [[self->_events objectForKey:@(bid)] removeObject:event];
                [[self->_events_sorted objectForKey:@(bid)] removeObjectForKey:@(eid)];
                if(event.msgid.length)
                    [[self->_msgIDs objectForKey:@(bid)] removeObjectForKey:event.msgid];
                break;
            }
        }
    }
}

-(void)removeEventsForBuffer:(int)bid {
    @synchronized(self->_events) {
        [self->_events removeObjectForKey:@(bid)];
        [self->_events_sorted removeObjectForKey:@(bid)];
        [self->_msgIDs removeObjectForKey:@(bid)];
        CLS_LOG(@"Removing all events for bid%i", bid);
    }
}

-(void)pruneEventsForBuffer:(int)bid maxSize:(int)size {
    @synchronized(self->_events) {
        if([[self->_events objectForKey:@(bid)] count] > size) {
            CLS_LOG(@"Pruning events for bid%i (%lu, max = %i)", bid, (unsigned long)[[self->_events objectForKey:@(bid)] count], size);
            NSMutableArray *events = [self eventsForBuffer:bid].mutableCopy;
            while(events.count > size) {
                Event *e = [events objectAtIndex:0];
                [events removeObject:e];
                [[self->_events objectForKey:@(bid)] removeObject:e];
                [[self->_events_sorted objectForKey:@(bid)] removeObjectForKey:@(e.eid)];
                if(e.msgid.length)
                    [[self->_msgIDs objectForKey:@(bid)] removeObjectForKey:e.msgid];
            }
        }
    }
}

-(NSArray *)eventsForBuffer:(int)bid {
    @synchronized(self->_events) {
        if([self->_dirtyBIDs objectForKey:@(bid)]) {
            CLS_LOG(@"Buffer bid%i needs sorting", bid);
            [[self->_events objectForKey:@(bid)] sortUsingSelector:@selector(compare:)];
            [self->_dirtyBIDs removeObjectForKey:@(bid)];
        }
        return [NSArray arrayWithArray:[self->_events objectForKey:@(bid)]];
    }
}

-(NSUInteger)sizeOfBuffer:(int)bid {
    return [[self->_events objectForKey:@(bid)] count];
}

-(NSTimeInterval)lastEidForBuffer:(int)bid {
    return [[self->_lastEIDs objectForKey:@(bid)] doubleValue];
}

-(void)removeEventsBefore:(NSTimeInterval)min_eid buffer:(int)bid {
    CLS_LOG(@"Removing events for bid%i older than %.0f", bid, min_eid);
    @synchronized(self->_events) {
        NSArray *events = [self->_events objectForKey:@(bid)];
        NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
        for(Event *event in events) {
            if(event.eid < min_eid) {
                [eventsToRemove addObject:event];
            }
        }
        for(Event *event in eventsToRemove) {
            [[self->_events objectForKey:@(bid)] removeObject:event];
            [[self->_events_sorted objectForKey:@(bid)] removeObjectForKey:@(event.eid)];
            if(event.msgid.length)
                [[self->_msgIDs objectForKey:@(bid)] removeObjectForKey:event.msgid];
        }
    }
}

-(int)unreadStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    if(![self->_events objectForKey:@(bid)])
        return 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = s.ignore;

    NSArray *copy;
    @synchronized(self->_events) {
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
    if(![self->_events objectForKey:@(bid)])
        return 0;
    int count = 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = s.ignore;
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    BOOL muted = [[prefs objectForKey:@"notifications-mute"] boolValue];
    if(muted) {
        NSDictionary *disableMap;
        
        if([b.type isEqualToString:@"channel"]) {
            disableMap = [prefs objectForKey:@"channel-notifications-mute-disable"];
        } else {
            disableMap = [prefs objectForKey:@"buffer-notifications-mute-disable"];
        }
        
        if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",b.bid]] boolValue])
            muted = NO;
    } else {
        NSDictionary *enableMap;
        
        if([b.type isEqualToString:@"channel"]) {
            enableMap = [prefs objectForKey:@"channel-notifications-mute"];
        } else {
            enableMap = [prefs objectForKey:@"buffer-notifications-mute"];
        }
        
        if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",b.bid]] boolValue])
            muted = YES;
    }
    if(muted)
        return 0;

    NSArray *copy;
    @synchronized(self->_events) {
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
    return count + b.extraHighlights;
}

-(int)highlightStateForBuffer:(int)bid lastSeenEid:(NSTimeInterval)lastSeenEid type:(NSString *)type {
    if(![self->_events objectForKey:@(bid)])
        return 0;
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
    Ignore *ignore = s.ignore;
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    BOOL muted = [[prefs objectForKey:@"notifications-mute"] boolValue];
    if(muted) {
        NSDictionary *disableMap;
        
        if([b.type isEqualToString:@"channel"]) {
            disableMap = [prefs objectForKey:@"channel-notifications-mute-disable"];
        } else {
            disableMap = [prefs objectForKey:@"buffer-notifications-mute-disable"];
        }
        
        if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",b.bid]] boolValue])
            muted = NO;
    } else {
        NSDictionary *enableMap;
        
        if([b.type isEqualToString:@"channel"]) {
            enableMap = [prefs objectForKey:@"channel-notifications-mute"];
        } else {
            enableMap = [prefs objectForKey:@"buffer-notifications-mute"];
        }
        
        if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",b.bid]] boolValue])
            muted = YES;
    }
    if(muted)
        return 0;

    NSArray *copy;
    @synchronized(self->_events) {
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
    return b.extraHighlights ? 1 : 0;
}

-(void)clearFormattingCache {
    @synchronized(self->_events) {
        for(NSNumber *bid in _events) {
            NSArray *events = [self->_events objectForKey:bid];
            for(Event *e in events) {
                e.formatted = nil;
                e.formattedNick = nil;
                e.formattedRealname = nil;
                e.timestamp = nil;
                e.height = 0;
                e.isHeader = NO;
                e.isCodeBlock = NO;
                e.isQuoted = NO;
            }
        }
    }
}


-(void)clearHeightCache {
    @synchronized(self->_events) {
        for(NSNumber *bid in _events) {
            NSArray *events = [self->_events objectForKey:bid];
            for(Event *e in events) {
                e.height = 0;
            }
        }
    }
}
-(void)reformat {
    @synchronized(self->_events) {
        for(NSNumber *bid in _events) {
            NSArray *events = [self->_events objectForKey:bid];
            for(Event *e in events) {
                e.color = [UIColor messageTextColor];
                if(e.rowType == ROW_LASTSEENEID)
                    e.bgColor = [UIColor contentBackgroundColor];
                else if(e.rowType == ROW_TIMESTAMP)
                    e.bgColor = [UIColor timestampBackgroundColor];
                else
                    e.bgColor = [UIColor contentBackgroundColor];
                e.formatted = nil;
                e.formattedNick = nil;
                e.formattedRealname = nil;
                e.timestamp = nil;
                e.height = 0;
                e.isHeader = NO;
                void (^formatter)(Event *event, IRCCloudJSONObject *object) = [self->_formatterMap objectForKey:e.type];
                if(formatter)
                    formatter(e, nil);
                
                if(e.isHighlight)
                    e.bgColor = [UIColor highlightBackgroundColor];
                
                if(e.isSelf && e.rowType != ROW_SOCKETCLOSED)
                    e.bgColor = [UIColor selfBackgroundColor];
            }
        }
    }

}

-(void)clearPendingAndFailed {
    @synchronized(self->_events) {
        NSMutableArray *eventsToRemove = [[NSMutableArray alloc] init];
        for(NSNumber *bid in _events) {
            NSArray *events = [[self->_events objectForKey:bid] copy];
            for(Event *e in events) {
                if((e.pending || e.rowType == ROW_FAILED) && e.reqId != -1)
                    [eventsToRemove addObject:e];
            }
        }
        for(Event *e in eventsToRemove) {
            [[self->_events objectForKey:@(e.bid)] removeObject:e];
            [[self->_events_sorted objectForKey:@(e.bid)] removeObjectForKey:@(e.eid)];
            if(e.msgid.length)
                [[self->_msgIDs objectForKey:@(e.bid)] removeObjectForKey:e.msgid];
            if(e.expirationTimer && [e.expirationTimer isValid])
                [e.expirationTimer invalidate];
            e.expirationTimer = nil;
        }
    }
}

+(NSString *)reason:(NSString *)reason {
    static NSDictionary *r;
    if(!r)
        r = @{@"pool_lost":@"Connection pool failed",
              @"no_pool":@"No available connection pools",
              @"enetdown":@"Network down",
              @"etimedout":@"Timed out",
              @"timeout":@"Timed out",
              @"ehostunreach":@"Host unreachable",
              @"econnrefused":@"Connection refused",
              @"nxdomain":@"Invalid hostname",
              @"server_ping_timeout":@"PING timeout",
              @"ssl_certificate_error":@"SSL certificate error",
              @"ssl_error":@"SSL error",
              @"crash":@"Connection crashed",
              @"networks":@"You've exceeded the connection limit for free accounts.",
              @"passworded_servers":@"You can't connect to passworded servers with free accounts.",
              @"unverified":@"You can’t connect to external servers until you confirm your email address.",
              };
    if([reason isKindOfClass:[NSString class]] && [reason length]) {
        if([r objectForKey:reason])
            return [r objectForKey:reason];
    }
    return reason;
}

+(NSString *)SSLreason:(NSDictionary *)info {
    static NSDictionary *r;
    if(!r)
        r = @{@"bad_cert":@{@"unknown_ca": @"Unknown certificate authority",
                            @"selfsigned_peer": @"Self signed certificate",
                            @"cert_expired": @"Certificate expired",
                            @"invalid_issuer": @"Invalid certificate issuer",
                            @"invalid_signature": @"Invalid certificate signature",
                            @"name_not_permitted": @"Invalid certificate alternative hostname",
                            @"missing_basic_constraint": @"Missing certificate basic contraints",
                            @"invalid_key_usage": @"Invalid certificate key usage"},
              @"ssl_verify_hostname":@{@"unable_to_match_altnames": @"Certificate hostname mismatch",
                                       @"unable_to_match_common_name": @"Certificate hostname mismatch",
                                       @"unable_to_decode_common_name": @"Invalid certificate hostname"}
              };

    if([[r objectForKey:[info objectForKey:@"type"]] objectForKey:@"error"]) {
        return [[r objectForKey:[info objectForKey:@"type"]] objectForKey:@"error"];
    }
    
    return [NSString stringWithFormat:@"%@: %@", [info objectForKey:@"type"], [info objectForKey:@"error"]];
}
@end
