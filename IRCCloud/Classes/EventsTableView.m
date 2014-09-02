//
//  EventsTableView.m
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


#import "EventsTableView.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"

int __timestampWidth;

@interface EventsTableCell : UITableViewCell {
    UILabel *_timestamp;
    TTTAttributedLabel *_message;
    int _type;
    UIView *_socketClosedBar;
    UIImageView *_accessory;
}
@property int type;
@property (readonly) UILabel *timestamp;
@property (readonly) TTTAttributedLabel *message;
@property (readonly) UIImageView *accessory;
@end

@implementation EventsTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        
        _timestamp = [[UILabel alloc] init];
        _timestamp.backgroundColor = [UIColor clearColor];
        _timestamp.textColor = [UIColor timestampColor];
        [self.contentView addSubview:_timestamp];

        _message = [[TTTAttributedLabel alloc] init];
        _message.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        _message.numberOfLines = 0;
        _message.lineBreakMode = NSLineBreakByWordWrapping;
        _message.backgroundColor = [UIColor clearColor];
        _message.textColor = [UIColor blackColor];
        _message.dataDetectorTypes = UIDataDetectorTypeNone;
        [self.contentView addSubview:_message];
        
        _socketClosedBar = [[UIView alloc] initWithFrame:CGRectZero];
        _socketClosedBar.backgroundColor = [UIColor newMsgsBackgroundColor];
        _socketClosedBar.hidden = YES;
        [self.contentView addSubview:_socketClosedBar];
        
        _accessory = [[UIImageView alloc] initWithFrame:CGRectZero];
        _accessory.hidden = YES;
        _accessory.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_accessory];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    if(_type == ROW_MESSAGE || _type == ROW_SOCKETCLOSED || _type == ROW_FAILED) {
        frame.origin.x = 6;
        frame.origin.y = 4;
        frame.size.height -= 6;
        frame.size.width -= 12;
        if(_type == ROW_SOCKETCLOSED) {
            frame.size.height -= 20;
            _socketClosedBar.frame = CGRectMake(0, frame.origin.y + frame.size.height, frame.size.width + 12, 26);
            _socketClosedBar.hidden = NO;
        } else if(_type == ROW_FAILED) {
            frame.size.width -= 20;
            _accessory.frame = CGRectMake(frame.origin.x + frame.size.width + 6, frame.origin.y + 1, _timestamp.font.pointSize, _timestamp.font.pointSize);
        } else {
            _socketClosedBar.hidden = YES;
            _accessory.frame = CGRectMake(frame.origin.x + 2 + __timestampWidth, frame.origin.y + 1, _timestamp.font.pointSize, _timestamp.font.pointSize);
        }
        _timestamp.textAlignment = NSTextAlignmentRight;
        _timestamp.frame = CGRectMake(frame.origin.x, frame.origin.y, __timestampWidth, _timestamp.font.pointSize + 4);
        _timestamp.hidden = NO;
        _message.frame = CGRectMake(frame.origin.x + 6 + __timestampWidth, frame.origin.y, frame.size.width - 6 - __timestampWidth, frame.size.height);
        _message.hidden = NO;
    } else {
        if(_type == ROW_BACKLOG) {
            frame.origin.y = frame.size.height / 2;
            frame.size.height = 1;
        } else if(_type == ROW_LASTSEENEID) {
            int width = [_timestamp.text sizeWithFont:_timestamp.font].width + 12;
            frame.origin.x = (frame.size.width - width) / 2;
            frame.size.width = width;
        }
        _timestamp.frame = frame;
        _timestamp.hidden = NO;
        _timestamp.textAlignment = NSTextAlignmentCenter;
        _message.hidden = YES;
        _socketClosedBar.hidden = YES;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation EventsTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _lock = [[NSRecursiveLock alloc] init];
        _conn = [NetworkConnection sharedInstance];
        _ready = NO;
        _formatter = [[NSDateFormatter alloc] init];
        _data = [[NSMutableArray alloc] init];
        _expandedSectionEids = [[NSMutableDictionary alloc] init];
        _collapsedEvents = [[CollapsedEvents alloc] init];
        _unseenHighlightPositions = [[NSMutableArray alloc] init];
        _buffer = nil;
        _ignore = [[Ignore alloc] init];
        _eidToOpen = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGFloat lineSpacing = 6;
    CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
    CTParagraphStyleSetting paragraphStyles[2] = {
        {.spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(CGFloat), .value = &lineSpacing},
		{.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode}
	};
    CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 2);
    
    NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
    [mutableLinkAttributes setObject:(id)[[UIColor blueColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    [mutableLinkAttributes setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCTUnderlineStyleAttributeName];
	[mutableLinkAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
    _linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    CFRelease(paragraphStyle);
    
    [mutableLinkAttributes setObject:(id)[[UIColor lightLinkColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
    _lightLinkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
    
    self.tableView.scrollsToTop = NO;
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self.tableView addGestureRecognizer:lp];
    _topUnreadView.backgroundColor = [UIColor selectedBlueColor];
    _bottomUnreadView.backgroundColor = [UIColor selectedBlueColor];
    [_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateNormal];
    [_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateHighlighted];
    [_backlogFailedButton setTitleColor:[UIColor selectedBlueColor] forState:UIControlStateNormal];
    [_backlogFailedButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [_backlogFailedButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _backlogFailedButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [_backlogFailedButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogFailed:)
                                                 name:kIRCCloudBacklogFailedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_data.count && _buffer.scrolledUp) {
        _bottomRow = [[[self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)] lastObject] row];
        if(_bottomRow >= _data.count)
            _bottomRow = _data.count - 1;
    } else {
        _bottomRow = -1;
    }
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(_data.count && _buffer.scrolledUp)
        _bottomRow = [[[self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)] lastObject] row];
    else
        _bottomRow = -1;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(_ready && [UIApplication sharedApplication].statusBarOrientation != _lastOrientation) {
        NSLog(@"Did rotate, clearing cached heights");
        if([_data count]) {
            [_lock lock];
            for(Event *e in _data) {
                e.height = 0;
            }
            [_lock unlock];
            _ready = NO;
            [self.tableView reloadData];
            if(_bottomRow >= 0 && _bottomRow < [self.tableView numberOfRowsInSection:0]) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_bottomRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                _bottomRow = -1;
            } else {
                [self _scrollToBottom];
            }
            _ready = YES;
        }
    }
    _lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
    [self updateUnread];
}

- (IBAction)loadMoreBacklogButtonPressed:(id)sender {
    _requestingBacklog = YES;
    [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid];
    self.tableView.tableHeaderView = _headerView;
}

- (void)backlogFailed:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        _requestingBacklog = NO;
        self.tableView.tableHeaderView = _backlogFailedView;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Unable to download chat history. Please try again shortly.");
    }
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        if([[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid] == nil) {
            NSLog(@"This buffer contains no events, switching to backlog failed header view");
            self.tableView.tableHeaderView = _backlogFailedView;
            return;
        }
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Download complete.");
    }
    if(notification.object == nil || [notification.object bid] == -1 || (_buffer && [notification.object bid] == _buffer.bid && _requestingBacklog)) {
        NSLog(@"Backlog loaded in current buffer, will find and remove the last seen EID marker");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(_buffer.scrolledUp) {
                NSLog(@"Table was scrolled up, adjusting scroll offset");
                [_lock lock];
                int row = 0;
                NSInteger toprow = [self.tableView indexPathForRowAtPoint:CGPointMake(0,_buffer.savedScrollOffset)].row;
                if(self.tableView.tableHeaderView != nil)
                    row++;
                for(Event *event in _data) {
                    if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:_buffer.bid lastSeenEid:_buffer.last_seen_eid type:_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                        if(toprow > row) {
                            NSLog(@"Adjusting scroll offset");
                            _buffer.savedScrollOffset -= 26;
                        }
                    }
                    if(++row > toprow)
                        break;
                }
                [_lock unlock];
            }
            for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid]) {
                if(event.rowType == ROW_LASTSEENEID) {
                    NSLog(@"removing the last seen EID marker");
                    [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                    NSLog(@"removed!");
                    break;
                }
            }
            NSLog(@"Rebuilding the message table");
            [self refresh];
        }];
    }
}

- (void)_sendHeartbeat {
    NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
    NSTimeInterval eid = _buffer.scrolledUpFrom;
    if(eid <= 0) {
        Event *last;
        for(NSInteger i = events.count - 1; i >= 0; i--) {
            last = [events objectAtIndex:i];
            if(!last.pending && last.rowType != ROW_LASTSEENEID)
                break;
        }
        if(!last.pending) {
            eid = last.eid;
        }
    }
    if(eid >= 0 && eid > _buffer.last_seen_eid && _conn.state == kIRCCloudStateConnected) {
        [_conn heartbeat:_buffer.bid cid:_buffer.cid bid:_buffer.bid lastSeenEid:eid];
        _buffer.last_seen_eid = eid;
    }
    _heartbeatTimer = nil;
}

- (void)sendHeartbeat {
    if(!_heartbeatTimer)
        _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_sendHeartbeat) userInfo:nil repeats:NO];
}

- (void)handleEvent:(NSNotification *)notification {
    IRCCloudJSONObject *o;
    Event *e;
    Buffer *b;
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventHeartbeatEcho:
            [self updateUnread];
            if(_maxEid <= _buffer.last_seen_eid) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _topUnreadView.alpha = 0;
                [UIView commitAnimations];
            }
            break;
        case kIRCEventMakeBuffer:
            b = notification.object;
            if(_buffer.bid == -1 && b.cid == _buffer.cid && [[b.name lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) {
                _buffer = b;
                [self refresh];
            }
            break;
        case kIRCEventChannelTopic:
        case kIRCEventJoin:
        case kIRCEventPart:
        case kIRCEventNickChange:
        case kIRCEventQuit:
        case kIRCEventKick:
        case kIRCEventChannelMode:
        case kIRCEventSelfDetails:
        case kIRCEventUserMode:
        case kIRCEventUserChannelMode:
            o = notification.object;
            if(o.bid == _buffer.bid) {
                e = [[EventsDataSource sharedInstance] event:o.eid buffer:o.bid];
                [self insertEvent:e backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.bid == _buffer.bid) {
                if(((e.from && [[e.from lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) || (e.nick && [[e.nick lowercaseString] isEqualToString:[_buffer.name lowercaseString]])) && e.reqId == -1) {
                    [_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [_data objectAtIndex:i];
                        if(e.pending) {
                            if(i > 0) {
                                Event *p = [_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    [_data removeObject:p];
                                    i--;
                                }
                            }
                            [_data removeObject:e];
                            i--;
                        }
                    }
                    [_lock unlock];
                } else if(e.reqId != -1) {
                    int reqid = e.reqId;
                    [_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [_data objectAtIndex:i];
                        if(e.reqId == reqid && (e.pending || e.rowType == ROW_FAILED)) {
                            if(i>0) {
                                Event *p = [_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    [_data removeObject:p];
                                    i--;
                                }
                            }
                            [_data removeObject:e];
                            i--;
                        }
                    }
                    [_lock unlock];
                }
                [self insertEvent:notification.object backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventSetIgnores:
            [self refresh];
            break;
        case kIRCEventUserInfo:
            for(Event *e in _data) {
                e.formatted = nil;
                e.timestamp = nil;
                e.height = 0;
            }
            [self refresh];
            break;
        default:
            break;
    }
}

- (void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped {
    BOOL shouldExpand = NO;
    BOOL colors = NO;
    if(!event.isSelf && [_conn prefs] && [[[_conn prefs] objectForKey:@"nick-colors"] intValue] > 0)
        colors = YES;
    
    if(_minEid == 0)
        _minEid = event.eid;
    if(event.eid == _buffer.min_eid) {
        self.tableView.tableHeaderView = nil;
    }
    if(event.eid < _earliestEid || _earliestEid == 0)
        _earliestEid = event.eid;
    
    NSTimeInterval eid = event.eid;
    NSString *type = event.type;
    if([type hasPrefix:@"you_"]) {
        type = [type substringFromIndex:4];
    }

    if([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"]|| [type isEqualToString:@"socket_closed"] || [type isEqualToString:@"connecting_failed"] || [type isEqualToString:@"connecting_cancelled"]) {
        _collapsedEvents.showChan = ![_buffer.type isEqualToString:@"channel"];
        NSDictionary *prefs = _conn.prefs;
        if(prefs) {
            NSDictionary *hiddenMap;
            
            if([_buffer.type isEqualToString:@"channel"]) {
                hiddenMap = [prefs objectForKey:@"channel-hideJoinPart"];
            } else {
                hiddenMap = [prefs objectForKey:@"buffer-hideJoinPart"];
            }
            
            if(hiddenMap && [[hiddenMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]) {
                for(Event *e in _data) {
                    if(e.eid == event.eid) {
                        [_data removeObject:e];
                        break;
                    }
                }
                if(!backlog)
                    [self.tableView reloadData];
                return;
            }

            NSDictionary *expandMap;
            
            if([_buffer.type isEqualToString:@"channel"]) {
                expandMap = [prefs objectForKey:@"channel-expandJoinPart"];
            } else if([_buffer.type isEqualToString:@"console"]) {
                expandMap = [prefs objectForKey:@"buffer-expandDisco"];
            } else {
                expandMap = [prefs objectForKey:@"buffer-expandJoinPart"];
            }
            
            if(expandMap && [[expandMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                shouldExpand = YES;
        }
        
        [_formatter setDateFormat:@"DDD"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:eid/1000000];
        
        if(shouldExpand)
            [_expandedSectionEids removeAllObjects];
        
        if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
            Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
            if(last) {
                if(![last.type isEqualToString:@"socket_closed"] && ![last.type isEqualToString:@"connecting_failed"] && ![last.type isEqualToString:@"connecting_cancelled"])
                    _currentCollapsedEid = -1;
            }
        } else {
            Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
            if(last) {
                if([last.type isEqualToString:@"socket_closed"] || [last.type isEqualToString:@"connecting_failed"] || [last.type isEqualToString:@"connecting_cancelled"])
                    _currentCollapsedEid = -1;
            }
        }
        
        if(_currentCollapsedEid == -1 || ![[_formatter stringFromDate:date] isEqualToString:_lastCollpasedDay] || shouldExpand) {
            [_collapsedEvents clear];
            _currentCollapsedEid = eid;
            _lastCollpasedDay = [_formatter stringFromDate:date];
        }
        
        if(!_collapsedEvents.showChan)
            event.chan = _buffer.name;
        
        if(![_collapsedEvents addEvent:event]) {
            [_collapsedEvents clear];
        }

        if((_currentCollapsedEid == event.eid || [_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) && [event.type isEqualToString:@"user_channel_mode"]) {
            event.color = [UIColor blackColor];
            event.bgColor = [UIColor whiteColor];
        } else {
            event.color = [UIColor timestampColor];
            event.bgColor = [UIColor whiteColor];
        }
        
        NSString *msg;
        if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
            CollapsedEvents *c = [[CollapsedEvents alloc] init];
            c.showChan = _collapsedEvents.showChan;
            c.server = _server;
            [c addEvent:event];
            msg = [c collapse];
            if(!nextIsGrouped) {
                NSString *groupMsg = [_collapsedEvents collapse];
                if(groupMsg == nil && [type isEqualToString:@"nickchange"])
                    groupMsg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO], BOLD];
                if(groupMsg == nil && [type isEqualToString:@"user_channel_mode"]) {
                    if(event.from.length > 0)
                        groupMsg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO], BOLD];
                    else
                        groupMsg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
                }
                Event *heading = [[Event alloc] init];
                heading.cid = event.cid;
                heading.bid = event.bid;
                heading.eid = _currentCollapsedEid - 1;
                heading.groupMsg = [NSString stringWithFormat:@"   %@",groupMsg];
                heading.color = [UIColor timestampColor];
                heading.bgColor = [UIColor whiteColor];
                heading.formattedMsg = nil;
                heading.formatted = nil;
                heading.linkify = NO;
                [self _addItem:heading eid:_currentCollapsedEid - 1];
                if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                    Event *last = [[EventsDataSource sharedInstance] event:_lastCollapsedEid buffer:_buffer.bid];
                    if(last) {
                        last.rowType = ROW_MESSAGE;
                    }
                    event.rowType = ROW_SOCKETCLOSED;
                }
            }
            event.timestamp = nil;
        } else {
            msg = (nextIsGrouped && _currentCollapsedEid != event.eid)?@"":[_collapsedEvents collapse];
        }
        if(msg == nil && [type isEqualToString:@"nickchange"])
            msg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO], BOLD];
        if(msg == nil && [type isEqualToString:@"user_channel_mode"]) {
            if(event.from.length > 0)
                msg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO], BOLD];
            else
                msg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
            _currentCollapsedEid = eid;
        }
        if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
            msg = [NSString stringWithFormat:@"   %@", msg];
        } else {
            if(eid != _currentCollapsedEid)
                msg = [NSString stringWithFormat:@"   %@", msg];
            eid = _currentCollapsedEid;
        }
        event.groupMsg = msg;
        event.formattedMsg = nil;
        event.formatted = nil;
        event.linkify = NO;
        _lastCollapsedEid = event.eid;
        if([_buffer.type isEqualToString:@"console"] && ![type isEqualToString:@"socket_closed"] && ![type isEqualToString:@"connecting_failed"] && ![type isEqualToString:@"connecting_cancelled"]) {
            _currentCollapsedEid = -1;
            _lastCollapsedEid = -1;
            [_collapsedEvents clear];
        }
            
    } else {
        _currentCollapsedEid = -1;
        _lastCollapsedEid = -1;
        [_collapsedEvents clear];

        if(!event.formatted) {
            if([event.from length]) {
                event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors], event.msg];
            } else {
                event.formattedMsg = event.msg;
            }
        }
    }
    
    if(event.ignoreMask.length && ([type isEqualToString:@"buffer_msg"] || [type isEqualToString:@"buffer_me_msg"] || [type isEqualToString:@"callerid"] ||[type isEqualToString:@"channel_invite"] ||[type isEqualToString:@"wallops"] ||[type isEqualToString:@"notice"])) {
        if((!_buffer || ![_buffer.type isEqualToString:@"conversation"]) && [_ignore match:event.ignoreMask]) {
            if(_topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0)
                [self sendHeartbeat];
            return;
        }
    }
    
    if(!event.formatted) {
        if([type isEqualToString:@"channel_mode"] && event.nick.length > 0) {
            if(event.nick.length)
                event.formattedMsg = [NSString stringWithFormat:@"%@ by %@", event.msg, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO]];
            else if(event.server.length)
                event.formattedMsg = [NSString stringWithFormat:@"%@ by the server %c%@%c", event.msg, BOLD, event.server, CLEAR];
        } else if([type isEqualToString:@"buffer_me_msg"]) {
            event.formattedMsg = [NSString stringWithFormat:@"— %c%@ %@", ITALICS, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:colors], event.msg];
        } else if([type isEqualToString:@"notice"]) {
            if(event.from.length)
                event.formattedMsg = [NSString stringWithFormat:@"%@ ", [_collapsedEvents formatNick:event.from mode:event.fromMode colorize:colors]];
            else
                event.formattedMsg = @"";
            if([_buffer.type isEqualToString:@"console"] && event.toChan && event.chan.length) {
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%@%c: %@", event.chan, 1, event.msg];
            } else {
                event.formattedMsg = [event.formattedMsg stringByAppendingString:event.msg];
            }
        } else if([type isEqualToString:@"kicked_channel"]) {
            event.formattedMsg = @"← ";
            if([event.type hasPrefix:@"you_"])
                event.formattedMsg = [event.formattedMsg stringByAppendingString:@"You"];
            else
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%c%@%c", BOLD, event.oldNick, CLEAR];
            if([event.type hasPrefix:@"you_"])
                event.formattedMsg = [event.formattedMsg stringByAppendingString:@" were"];
            else
                event.formattedMsg = [event.formattedMsg stringByAppendingString:@" was"];
            if(event.hostmask && event.hostmask.length)
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by %c%@%c (%@)", BOLD, event.nick, BOLD, event.hostmask];
            else
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by the server %c%@%c", BOLD, event.nick, CLEAR];
            if(event.msg.length > 0)
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@": %@", event.msg];
        } else if([type isEqualToString:@"channel_mode_list_change"]) {
            if(event.from.length == 0) {
                if(event.nick.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by %@", event.msg, [_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO]];
                else if(event.server.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by the server %c%@%c", event.msg, BOLD, event.server, CLEAR];
            }
        }
    }
    
    [self _addItem:event eid:eid];
    
    if(!backlog) {
        [self.tableView reloadData];
        if(!_buffer.scrolledUp) {
            if(_topUnreadView.alpha == 0 && _data.count > 200) {
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:_buffer.bid maxSize:100];
                [self refresh];
            } else {
                [self scrollToBottom];
                [self _scrollToBottom];
            }
        } else if(!event.isSelf && [event isImportant:_buffer.type]) {
            _newMsgs++;
            if(event.isHighlight)
                _newHighlights++;
            [self updateUnread];
            [self scrollViewDidScroll:self.tableView];
        }
    }
}

-(void)updateTopUnread:(NSInteger)firstRow {
    int highlights = 0;
    for(NSNumber *pos in _unseenHighlightPositions) {
        if([pos intValue] > firstRow)
            break;
        highlights++;
    }
    NSString *msg = @"";
    CGRect rect = _topUnreadView.frame;
    if(highlights) {
        if(highlights == 1)
            msg = @"mention and ";
        else
            msg = @"mentions and ";
        _topHighlightsCountView.count = [NSString stringWithFormat:@"%i", highlights];
        CGSize size = [_topHighlightsCountView.count sizeWithFont:_topHighlightsCountView.font];
        size.width += 6;
        size.height = rect.size.height - 12;
        if(size.width < size.height)
            size.width = size.height;
        _topHighlightsCountView.frame = CGRectMake(4,6,size.width,size.height);
        _topHighlightsCountView.hidden = NO;
        _topUnreadlabel.frame = CGRectMake(8+size.width,6,rect.size.width - size.width - 8 - 32, rect.size.height-12);
    } else {
        _topHighlightsCountView.hidden = YES;
        _topUnreadlabel.frame = CGRectMake(4,6,rect.size.width - 8 - 32, rect.size.height-12);
    }
    if(_lastSeenEidPos == 0) {
        int seconds = ([[_data objectAtIndex:firstRow] eid] - _buffer.last_seen_eid) / 1000000;
        if(seconds < 0) {
            _backlogFailedView.frame = _headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 60);
            self.tableView.tableHeaderView = self.tableView.tableHeaderView;
            _topUnreadView.alpha = 0;
        } else {
            int minutes = seconds / 60;
            int hours = minutes / 60;
            int days = hours / 24;
            if(days) {
                if(days == 1)
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i day of unread messages", days];
                else
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i days of unread messages", days];
            } else if(hours) {
                if(hours == 1)
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i hour of unread messages", hours];
                else
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i hours of unread messages", hours];
            } else if(minutes) {
                if(minutes == 1)
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i minute of unread messages", minutes];
                else
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i minutes of unread messages", minutes];
            } else {
                if(seconds == 1)
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i second of unread messages", seconds];
                else
                    _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i seconds of unread messages", seconds];
            }
        }
    } else {
        if(firstRow - _lastSeenEidPos == 1) {
            _topUnreadlabel.text = [msg stringByAppendingFormat:@"%li unread message", (long)(firstRow - _lastSeenEidPos)];
        } else if(firstRow - _lastSeenEidPos > 0) {
            _topUnreadlabel.text = [msg stringByAppendingFormat:@"%li unread messages", (long)(firstRow - _lastSeenEidPos)];
        } else {
            _backlogFailedView.frame = _headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 60);
            self.tableView.tableHeaderView = self.tableView.tableHeaderView;
            _topUnreadView.alpha = 0;
        }
    }
}

-(void)updateUnread {
    NSString *msg = @"";
    CGRect rect = _bottomUnreadView.frame;
    if(_newHighlights) {
        if(_newHighlights == 1)
            msg = @"mention";
        else
            msg = @"mentions";
        _bottomHighlightsCountView.count = [NSString stringWithFormat:@"%li", (long)_newHighlights];
        CGSize size = [_bottomHighlightsCountView.count sizeWithFont:_bottomHighlightsCountView.font];
        size.width += 6;
        size.height = rect.size.height - 12;
        if(size.width < size.height)
            size.width = size.height;
        _bottomHighlightsCountView.frame = CGRectMake(4,6,size.width,size.height);
        _bottomHighlightsCountView.hidden = NO;
        _bottomUndreadlabel.frame = CGRectMake(8+size.width,6,rect.size.width - size.width - 8, rect.size.height-12);
    } else {
        _bottomHighlightsCountView.hidden = YES;
        _bottomUndreadlabel.frame = CGRectMake(4,6,rect.size.width - 8, rect.size.height-12);
    }
    if(_newMsgs - _newHighlights > 0) {
        if(_newHighlights)
            msg = [msg stringByAppendingString:@" and "];
        if(_newMsgs - _newHighlights == 1)
            msg = [msg stringByAppendingFormat:@"%li unread message", (long)(_newMsgs - _newHighlights)];
        else
            msg = [msg stringByAppendingFormat:@"%li unread messages", (long)(_newMsgs - _newHighlights)];
    }
    if(msg.length) {
        _bottomUndreadlabel.text = msg;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _bottomUnreadView.alpha = 1;
        [UIView commitAnimations];
    }
}

-(void)_addItem:(Event *)e eid:(NSTimeInterval)eid {
    [_lock lock];
    NSInteger insertPos = -1;
    NSString *lastDay = nil;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:eid/1000000];
    if(!e.timestamp) {
        if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-24hr"] boolValue]) {
            if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-seconds"] boolValue])
                [_formatter setDateFormat:@"H:mm:ss"];
            else
                [_formatter setDateFormat:@"H:mm"];
        } else if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-seconds"] boolValue]) {
            [_formatter setDateFormat:@"h:mm:ss a"];
        } else {
            [_formatter setDateFormat:@"h:mm a"];
        }

        e.timestamp = [_formatter stringFromDate:date];
    }
    if(!e.day) {
        [_formatter setDateFormat:@"DDD"];
        e.day = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:eid/1000000]];
    }
    if(e.groupMsg && !e.formattedMsg) {
        e.formattedMsg = e.groupMsg;
        e.formatted = nil;
    }
    e.groupEid = _currentCollapsedEid;
    
    if(eid > _maxEid || _data.count == 0 || (eid == e.eid && [e compare:[_data objectAtIndex:_data.count - 1]] == NSOrderedDescending)) {
        //Message at bottom
        if(_data.count) {
            lastDay = ((Event *)[_data objectAtIndex:_data.count - 1]).day;
        }
        _maxEid = eid;
        [_data addObject:e];
        insertPos = _data.count - 1;
    } else if(_minEid > eid) {
        //Message on top
        if(_data.count > 1) {
            lastDay = ((Event *)[_data objectAtIndex:1]).day;
            if(![lastDay isEqualToString:e.day]) {
                //Insert above the dateline
                [_data insertObject:e atIndex:0];
                insertPos = 0;
            } else {
                //Insert below the dateline
                [_data insertObject:e atIndex:1];
                insertPos = 1;
            }
        } else {
            [_data insertObject:e atIndex:0];
            insertPos = 0;
        }
    } else {
        int i = 0;
        for(Event *e1 in _data) {
            if(e1.rowType != ROW_TIMESTAMP && [e compare:e1] == NSOrderedAscending && e.eid == eid) {
                //Insert the message
                if(i > 0 && ((Event *)[_data objectAtIndex:i - 1]).rowType != ROW_TIMESTAMP) {
                    lastDay = ((Event *)[_data objectAtIndex:i - 1]).day;
                    [_data insertObject:e atIndex:i];
                    insertPos = i;
                    break;
                } else {
                    //There was a dateline above our insertion point
                    lastDay = e1.day;
                    if(![lastDay isEqualToString:e.day]) {
                        if(i > 1) {
                            lastDay = ((Event *)[_data objectAtIndex:i - 2]).day;
                        } else {
                            //We're above the first dateline, so we'll need to put a new one on top
                            lastDay = nil;
                        }
                        [_data insertObject:e atIndex:i-1];
                        insertPos = i-1;
                    } else {
                        //Insert below the dateline
                        [_data insertObject:e atIndex:i];
                        insertPos = i;
                    }
                    break;
                }
            } else if(e1.rowType != ROW_TIMESTAMP && (e1.eid == eid || e1.groupEid == eid)) {
                //Replace the message
                lastDay = e.day;
                [_data removeObjectAtIndex:i];
                [_data insertObject:e atIndex:i];
                insertPos = i;
                break;
            }
            i++;
        }
    }
    
    if(insertPos == -1) {
        CLS_LOG(@"Couldn't insert EID: %f MSG: %@", eid, e.formattedMsg);
        [_lock unlock];
        return;
    }
    
    if(eid > _buffer.last_seen_eid && e.isHighlight) {
        [_unseenHighlightPositions addObject:@(insertPos)];
        [_unseenHighlightPositions sortUsingSelector:@selector(compare:)];
    }
    
    if(eid < _minEid || _minEid == 0)
        _minEid = eid;
    
    if(![lastDay isEqualToString:e.day]) {
        [_formatter setDateFormat:@"EEEE, MMMM dd, yyyy"];
        Event *d = [[Event alloc] init];
        d.type = TYPE_TIMESTMP;
        d.rowType = ROW_TIMESTAMP;
        d.eid = eid;
        d.groupEid = -1;
        d.timestamp = [_formatter stringFromDate:date];
        d.bgColor = [UIColor timestampBackgroundColor];
        d.day = e.day;
        [_data insertObject:d atIndex:insertPos];
    }
    
    [_lock unlock];
}

-(void)setBuffer:(Buffer *)buffer {
    _ready = NO;
    [_heartbeatTimer invalidate];
    _heartbeatTimer = nil;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    _requestingBacklog = NO;
    _bottomRow = -1;
    if(_buffer && _buffer.scrolledUp) {
        NSLog(@"Table was scrolled up, adjusting scroll offset");
        [_lock lock];
        int row = 0;
        NSInteger toprow = [self.tableView indexPathForRowAtPoint:CGPointMake(0,_buffer.savedScrollOffset)].row;
        if(self.tableView.tableHeaderView != nil)
            row++;
        for(Event *event in _data) {
            if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:_buffer.bid lastSeenEid:_buffer.last_seen_eid type:_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                if(toprow > row) {
                    NSLog(@"Adjusting scroll offset");
                    _buffer.savedScrollOffset -= 26;
                }
            }
            if(++row > toprow)
                break;
        }
        [_lock unlock];
    }
    if(_buffer && buffer.bid != _buffer.bid) {
        for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:buffer.bid]) {
            if(event.rowType == ROW_LASTSEENEID) {
                [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                break;
            }
            event.formatted = nil;
            event.timestamp = nil;
        }
        _topUnreadView.alpha = 0;
        _bottomUnreadView.alpha = 0;
    }
    _buffer = buffer;
    if(buffer)
        _server = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    else
        _server = nil;
    _earliestEid = 0;
    [_expandedSectionEids removeAllObjects];
    [self refresh];
}

- (void)_scrollToBottom {
    [_lock lock];
    _scrollTimer = nil;
    _buffer.scrolledUp = NO;
    _buffer.scrolledUpFrom = -1;
    if(_data.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: NO];
        if(!_conn.background)
            [self scrollViewDidScroll:self.tableView];
    }
    [_lock unlock];
}

- (void)scrollToBottom {
    [_scrollTimer invalidate];
    
    _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_scrollToBottom) userInfo:nil repeats:NO];
}

- (void)refresh {
    [_lock lock];
    [_scrollTimer invalidate];
    _ready = NO;
    NSInteger oldPosition = (_requestingBacklog && _data.count && [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)].count)?[[[self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)] objectAtIndex: 0] row]:-1;
    NSTimeInterval backlogEid = (_requestingBacklog && _data.count && oldPosition < _data.count)?[[_data objectAtIndex:oldPosition] groupEid]-1:0;
    if(backlogEid < 1)
        backlogEid = (_requestingBacklog && _data.count && oldPosition < _data.count)?[[_data objectAtIndex:oldPosition] eid]-1:0;
    oldPosition = (_data.count && [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)].count)?[[[self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)] objectAtIndex: 0] row]:-1;

    [_data removeAllObjects];
    _minEid = _maxEid = _earliestEid = _newMsgs = _newHighlights = 0;
    _lastSeenEidPos = -1;
    _currentCollapsedEid = 0;
    _lastCollpasedDay = @"";
    [_collapsedEvents clear];
    _collapsedEvents.server = _server;
    [_unseenHighlightPositions removeAllObjects];
    
    if(!_buffer) {
        [_lock unlock];
        self.tableView.tableHeaderView = nil;
        [self.tableView reloadData];
        return;
    }

    if(_conn.state == kIRCCloudStateConnected)
        [[NetworkConnection sharedInstance] cancelIdleTimer]; //This may take a while
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
#endif
    __timestampWidth = [@"88:88" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
    if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-seconds"] boolValue])
        __timestampWidth += [@":88" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
    if(!([_conn prefs] && [[[_conn prefs] objectForKey:@"time-24hr"] boolValue]))
        __timestampWidth += [@" AM" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
#ifdef __IPHONE_7_0
    } else {
        UIFont *f = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        f = [UIFont fontWithName:f.fontName size:f.pointSize * 0.8];
        __timestampWidth = [@"88:88" sizeWithFont:f].width;
        if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-seconds"] boolValue])
            __timestampWidth += [@":88" sizeWithFont:f].width;
        if(!([_conn prefs] && [[[_conn prefs] objectForKey:@"time-24hr"] boolValue]))
            __timestampWidth += [@" AM" sizeWithFont:f].width;
    }
#endif
    
    NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
    if(!events || (events.count == 0 && _buffer.min_eid > 0)) {
        if(_buffer.bid != -1 && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected) {
            self.tableView.tableHeaderView = _headerView;
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid];
        } else {
            self.tableView.tableHeaderView = nil;
        }
    } else if(events.count) {
        [_ignore setIgnores:_server.ignores];
        _earliestEid = ((Event *)[events objectAtIndex:0]).eid;
        if(_earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected) {
            self.tableView.tableHeaderView = _headerView;
        } else {
            self.tableView.tableHeaderView = nil;
        }
        for(Event *e in events) {
            [self insertEvent:e backlog:true nextIsGrouped:false];
        }
    } else {
        self.tableView.tableHeaderView = nil;
    }
    
    if(backlogEid > 0) {
        Event *e = [[Event alloc] init];
        e.eid = backlogEid;
        e.type = TYPE_BACKLOG;
        e.rowType = ROW_BACKLOG;
        e.formattedMsg = nil;
        e.bgColor = [UIColor whiteColor];
        [self _addItem:e eid:backlogEid];
        e.timestamp = nil;
    }
    
    if(_minEid > 0 && _buffer.last_seen_eid > 0 && _minEid >= _buffer.last_seen_eid) {
        _lastSeenEidPos = 0;
    } else {
        Event *e = [[Event alloc] init];
        e.cid = _buffer.cid;
        e.bid = _buffer.bid;
        e.eid = _buffer.last_seen_eid + 1;
        e.type = TYPE_LASTSEENEID;
        e.rowType = ROW_LASTSEENEID;
        e.formattedMsg = nil;
        e.bgColor = [UIColor newMsgsBackgroundColor];
        e.timestamp = @"New Messages";
        _lastSeenEidPos = _data.count - 1;
        NSEnumerator *i = [_data reverseObjectEnumerator];
        Event *event = [i nextObject];
        while(event) {
            if(event.eid <= _buffer.last_seen_eid && event.rowType != ROW_LASTSEENEID)
                break;
            event = [i nextObject];
            _lastSeenEidPos--;
        }
        if(_lastSeenEidPos != _data.count - 1) {
            if(_lastSeenEidPos > 0 && [[_data objectAtIndex:_lastSeenEidPos - 1] rowType] == ROW_TIMESTAMP)
                _lastSeenEidPos--;
            if(_lastSeenEidPos > 0) {
                for(Event *event in events) {
                    if(event.rowType == ROW_LASTSEENEID) {
                        [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                        [_data removeObject:event];
                        break;
                    }
                }
                [[EventsDataSource sharedInstance] addEvent:e];
                [self _addItem:e eid:e.eid];
                e.groupEid = -1;
            }
        } else {
            _lastSeenEidPos = -1;
        }
    }

    if(_lastSeenEidPos == 0) {
        _backlogFailedView.frame = _headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 92);
    } else {
        _backlogFailedView.frame = _headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 60);
    }
    self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    
    [self.tableView reloadData];
    if(_requestingBacklog && backlogEid > 0 && _buffer.scrolledUp) {
        int markerPos = -1;
        for(Event *e in _data) {
            if(e.eid == backlogEid)
                break;
            markerPos++;
        }
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:markerPos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    } else if(_eidToOpen > 0) {
        if(_eidToOpen <= _maxEid) {
            int i = 0;
            for(Event *e in _data) {
                if(e.eid == _eidToOpen) {
                    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                    _buffer.scrolledUpFrom = [[_data objectAtIndex:[[[self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)] lastObject] row]] eid];
                    break;
                }
                i++;
            }
            _eidToOpen = -1;
        } else {
            if(!_buffer.scrolledUp)
                _buffer.scrolledUpFrom = -1;
        }
    } else if(_buffer.scrolledUp && _buffer.savedScrollOffset > 0) {
        if((_buffer.savedScrollOffset + self.tableView.tableHeaderView.bounds.size.height) < self.tableView.contentSize.height - self.tableView.bounds.size.height) {
            self.tableView.contentOffset = CGPointMake(0, (_buffer.savedScrollOffset + self.tableView.tableHeaderView.bounds.size.height));
        } else {
            [self _scrollToBottom];
            [self scrollToBottom];
        }
    } else if(!_buffer.scrolledUp || (_data.count && _scrollTimer)) {
        [self _scrollToBottom];
        [self scrollToBottom];
    }
    
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
    if(_data.count && rows.count) {
        NSInteger firstRow = [[rows objectAtIndex:0] row];
        NSInteger lastRow = [[rows lastObject] row];
        Event *e = [_data objectAtIndex:_lastSeenEidPos+1];
        if(_lastSeenEidPos >= 0 && firstRow > _lastSeenEidPos && e.eid > _buffer.last_seen_eid) {
            if(_topUnreadView.alpha == 0) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _topUnreadView.alpha = 1;
                [UIView commitAnimations];
            }
            [self updateTopUnread:firstRow];
        } else if(lastRow < _lastSeenEidPos) {
            for(Event *e in _data) {
                if(_buffer.last_seen_eid > 0 && e.eid > _buffer.last_seen_eid && e.eid > _buffer.scrolledUpFrom && !e.isSelf && e.rowType != ROW_LASTSEENEID && [e isImportant:_buffer.type]) {
                    _newMsgs++;
                    if(e.isHighlight)
                        _newHighlights++;
                }
            }
        } else {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            _topUnreadView.alpha = 0;
            [UIView commitAnimations];
        }
        _requestingBacklog = NO;
    }
    
    [self updateUnread];
    [self scrollViewDidScroll:self.tableView];
    
    _ready = YES;
    [_lock unlock];
    
    if(_conn.state == kIRCCloudStateConnected) {
        if(_data.count == 0 && _buffer.bid != -1 && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected) {
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid];
        }
        [[NetworkConnection sharedInstance] scheduleIdleTimer];
    }
    
    [self.tableView flashScrollIndicators];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [_lock lock];
    NSInteger count = _data.count;
    [_lock unlock];
    return count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [_lock lock];
    Event *e = [_data objectAtIndex:indexPath.row];
    [_lock unlock];
    if(e.rowType == ROW_MESSAGE || e.rowType == ROW_SOCKETCLOSED || e.rowType == ROW_FAILED) {
        if(e.formatted != nil && e.height > 0) {
            return e.height;
        } else if(e.formatted == nil && e.formattedMsg.length > 0) {
            NSArray *links;
            e.formatted = [ColorFormatter format:e.formattedMsg defaultColor:e.color mono:e.monospace linkify:e.linkify server:_server links:&links];
            e.links = links;
        } else if(e.formattedMsg.length == 0) {
            //CLS_LOG(@"No formatted message: %@", e);
            return 26;
        }
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(e.formatted));
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.tableView.frame.size.width - 6 - 12 - __timestampWidth - ((e.rowType == ROW_FAILED)?20:0),CGFLOAT_MAX), NULL);
         e.height = ceilf(suggestedSize.height) + 8 + ((e.rowType == ROW_SOCKETCLOSED)?26:0);
         CFRelease(framesetter);
        return e.height;
    } else {
        return 26;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    EventsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventscell"];
    if(!cell)
        cell = [[EventsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"eventscell"];
    [_lock lock];
    if([indexPath row] >= _data.count) {
        cell.type = ROW_MESSAGE;
        cell.message.text = @"";
        cell.timestamp.text = @"";
        cell.accessory.hidden = YES;
        [_lock unlock];
        return cell;
    }
    Event *e = [_data objectAtIndex:[indexPath row]];
    [_lock unlock];
    cell.type = e.rowType;
    cell.contentView.backgroundColor = e.bgColor;
    cell.timestamp.font = [ColorFormatter timestampFont];
    cell.message.font = [ColorFormatter timestampFont];
    cell.message.delegate = self;
    cell.message.text = e.formatted;
    if(e.from.length && e.msg.length) {
        cell.accessibilityLabel = [NSString stringWithFormat:@"Message from %@ at %@", e.from, e.timestamp];
        cell.accessibilityValue = [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
    } else if([e.type isEqualToString:@"buffer_me_msg"]) {
        cell.accessibilityLabel = [NSString stringWithFormat:@"Action at %@", e.timestamp];
        cell.accessibilityValue = [NSString stringWithFormat:@"%@ %@", e.nick, [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]];
    }
    if((e.rowType == ROW_MESSAGE || e.rowType == ROW_FAILED || e.rowType == ROW_SOCKETCLOSED) && e.groupEid > 0 && (e.groupEid != e.eid || [_expandedSectionEids objectForKey:@(e.groupEid)])) {
        if([_expandedSectionEids objectForKey:@(e.groupEid)]) {
            if(e.groupEid == e.eid + 1) {
                cell.accessory.image = [UIImage imageNamed:@"bullet_toggle_minus"];
                cell.contentView.backgroundColor = [UIColor collapsedHeadingBackgroundColor];
            } else {
                cell.accessory.image = [UIImage imageNamed:@"tiny_plus"];
                cell.contentView.backgroundColor = [UIColor collapsedRowBackgroundColor];
            }
        } else {
            cell.accessory.image = [UIImage imageNamed:@"bullet_toggle_plus"];
        }
        cell.accessory.hidden = NO;
    } else if(e.rowType == ROW_FAILED) {
        cell.accessory.hidden = NO;
        cell.accessory.image = [UIImage imageNamed:@"send_fail"];
    } else {
        cell.accessory.hidden = YES;
    }
    if(e.links.count) {
        if(e.pending || [e.color isEqual:[UIColor timestampColor]])
            cell.message.linkAttributes = _lightLinkAttributes;
        else
            cell.message.linkAttributes = _linkAttributes;
        @try {
            for(NSTextCheckingResult *result in e.links) {
                if(result.resultType == NSTextCheckingTypeLink) {
                    [cell.message addLinkWithTextCheckingResult:result];
                } else {
                    NSString *url = [[e.formatted attributedSubstringFromRange:result.range] string];
                    if(![url hasPrefix:@"irc"])
                        url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url];
                    [cell.message addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
                }
            }
        }
        @catch (NSException *exception) {
            NSLog(@"An exception occured while setting the links, the table is probably being reloaded: %@", exception);
        }
    }
    if(e.rowType == ROW_LASTSEENEID)
        cell.timestamp.text = @"New Messages";
    else
        cell.timestamp.text = e.timestamp;
    if(e.rowType == ROW_TIMESTAMP) {
        cell.timestamp.textColor = [UIColor blackColor];
    } else if(e.isHighlight) {
        cell.timestamp.textColor = [UIColor highlightTimestampColor];
    } else {
        cell.timestamp.textColor = [UIColor timestampColor];
    }
    if(e.rowType == ROW_BACKLOG) {
        cell.timestamp.backgroundColor = [UIColor selectedBlueColor];
    } else if(e.rowType == ROW_LASTSEENEID) {
        cell.timestamp.backgroundColor = [UIColor whiteColor];
    } else {
        cell.timestamp.backgroundColor = [UIColor clearColor];
    }
    return cell;
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:url];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

-(IBAction)dismissButtonPressed:(id)sender {
    if(_topUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _topUnreadView.alpha = 0;
        [UIView commitAnimations];
        [self sendHeartbeat];
    }
}

-(IBAction)topUnreadBarClicked:(id)sender {
    if(_topUnreadView.alpha) {
        if(!_buffer.scrolledUp) {
            _buffer.scrolledUpFrom = [[_data lastObject] eid];
            _buffer.scrolledUp = YES;
        }
        if(_lastSeenEidPos > 0) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            _topUnreadView.alpha = 0;
            [UIView commitAnimations];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSeenEidPos+1 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated: YES];
            [self scrollViewDidScroll:self.tableView];
            [self _sendHeartbeat];
        } else {
            if(self.tableView.tableHeaderView == _backlogFailedView)
                [self loadMoreBacklogButtonPressed:nil];
            [self.tableView setContentOffset:CGPointMake(0,0) animated:YES];
        }
    }
}

-(IBAction)bottomUnreadBarClicked:(id)sender {
    if(_bottomUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        _bottomUnreadView.alpha = 0;
        [UIView commitAnimations];
        if(_data.count)
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: YES];
        _buffer.scrolledUp = NO;
        _buffer.scrolledUpFrom = -1;
    }
}

#pragma mark - Table view delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_delegate dismissKeyboard];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!_ready || !_buffer)
        return;

    NSInteger firstRow = -1;
    NSInteger lastRow = -1;
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
        lastRow = [[rows lastObject] row];
    }
    
    if(self.tableView.tableHeaderView == _headerView && _minEid > 0 && _buffer && _buffer.bid != -1 && (_buffer.scrolledUp || (_data.count && firstRow == 0 && lastRow == _data.count - 1))) {
        if(!_requestingBacklog && _conn.state == kIRCCloudStateConnected && scrollView.contentOffset.y < _headerView.frame.size.height) {
            NSLog(@"The table scrolled and the loading header became visible, requesting more backlog");
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Downloading more chat history");
        }
    }
    
    if(rows.count) {
        if(_data.count) {
            if(lastRow < _data.count)
                _buffer.savedScrollOffset = self.tableView.contentOffset.y - self.tableView.tableHeaderView.bounds.size.height;
            
            if(self.tableView.contentOffset.y >= (self.tableView.contentSize.height - self.tableView.bounds.size.height)) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _bottomUnreadView.alpha = 0;
                [UIView commitAnimations];
                _newMsgs = 0;
                _newHighlights = 0;
                _buffer.scrolledUp = NO;
                _buffer.scrolledUpFrom = -1;
                _buffer.savedScrollOffset = -1;
                if(_topUnreadView.alpha == 0)
                    [self _sendHeartbeat];
            } else if (!_buffer.scrolledUp && (lastRow+1) < _data.count) {
                _buffer.scrolledUpFrom = [[_data objectAtIndex:lastRow+1] eid];
                _buffer.scrolledUp = YES;
            }

            if(_lastSeenEidPos >= 0) {
                if(_lastSeenEidPos > 0 && firstRow < _lastSeenEidPos + 1) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    _topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                    [self _sendHeartbeat];
                } else {
                    [self updateTopUnread:firstRow];
                }
            }
            
            if(self.tableView.tableHeaderView != _headerView && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && firstRow > 0 && lastRow < _data.count && _conn.state == kIRCCloudStateConnected)
                self.tableView.tableHeaderView = _headerView;
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row < _data.count) {
        NSTimeInterval group = ((Event *)[_data objectAtIndex:indexPath.row]).groupEid;
        if(group > 0) {
            int count = 0;
            for(Event *e in _data) {
                if(e.groupEid == group)
                    count++;
            }
            if(count > 1 || [((Event *)[_data objectAtIndex:indexPath.row]).groupMsg hasPrefix:@"   "]) {
                if([_expandedSectionEids objectForKey:@(group)])
                    [_expandedSectionEids removeObjectForKey:@(group)];
                else if(((Event *)[_data objectAtIndex:indexPath.row]).eid != group)
                    [_expandedSectionEids setObject:@(YES) forKey:@(group)];
                for(Event *e in _data) {
                    e.timestamp = nil;
                    e.formatted = nil;
                }
                if(!_buffer.scrolledUp) {
                    _buffer.scrolledUpFrom = [[_data lastObject] eid];
                    _buffer.scrolledUp = YES;
                }
                _buffer.savedScrollOffset = self.tableView.contentOffset.y - self.tableView.tableHeaderView.bounds.size.height;
                [self refresh];
            }
        } else if(indexPath.row < _data.count) {
            Event *e = [_data objectAtIndex:indexPath.row];
            if([e.type isEqualToString:@"channel_invite"])
                [_conn join:e.oldNick key:nil cid:e.cid];
            else if([e.type isEqualToString:@"callerid"])
                [_conn say:[NSString stringWithFormat:@"/accept %@", e.nick] to:nil cid:e.cid];
            else
                [_delegate rowSelected:e];
        }
    }
}

-(void)clearLastSeenMarker {
    for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid]) {
        if(event.rowType == ROW_LASTSEENEID) {
            [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
            break;
        }
    }
    for(Event *event in _data) {
        if(event.rowType == ROW_LASTSEENEID) {
            [_data removeObject:event];
            break;
        }
    }
    [self.tableView reloadData];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                EventsTableCell *c = (EventsTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                NSURL *url = [c.message linkAtPoint:[gestureRecognizer locationInView:c.message]].URL;
                if(url) {
                    if([url.scheme hasPrefix:@"irc"] && [url.host intValue] > 0 && url.path && url.path.length > 1) {
                        Server *s = [[ServersDataSource sharedInstance] getServer:[url.host intValue]];
                        if(s != nil) {
                            if(s.ssl > 0)
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"ircs://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                            else
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"irc://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                        }
                    }
                }
                [_delegate rowLongPressed:[_data objectAtIndex:indexPath.row] rect:[self.tableView rectForRowAtIndexPath:indexPath] link:url.absoluteString];
            }
        }
    }
}
@end
