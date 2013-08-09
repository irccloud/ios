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
        _timestamp.font = [UIFont systemFontOfSize:FONT_SIZE];
        _timestamp.backgroundColor = [UIColor clearColor];
        _timestamp.textColor = [UIColor timestampColor];
        [self.contentView addSubview:_timestamp];

        _message = [[TTTAttributedLabel alloc] init];
        _message.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
        _message.font = [UIFont systemFontOfSize:FONT_SIZE];
        _message.numberOfLines = 0;
        _message.lineBreakMode = NSLineBreakByWordWrapping;
        _message.backgroundColor = [UIColor clearColor];
        _message.textColor = [UIColor blackColor];
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
            frame.size.height -= 26;
            _socketClosedBar.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height, frame.size.width, 26);
            _socketClosedBar.hidden = NO;
        } else if(_type == ROW_FAILED) {
            frame.size.width -= 20;
            _accessory.frame = CGRectMake(frame.origin.x + frame.size.width + 6, frame.origin.y + 1, 16, 16);
        } else {
            _socketClosedBar.hidden = YES;
            _accessory.frame = CGRectMake(frame.origin.x + 2 + __timestampWidth, frame.origin.y + 1, 16, 16);
        }
        _timestamp.textAlignment = NSTextAlignmentRight;
        _timestamp.frame = CGRectMake(frame.origin.x, frame.origin.y, __timestampWidth, 20);
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
        _scrolledUpFrom = -1;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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
    if(_data.count && _scrolledUp)
        _bottomRow = [[[self.tableView indexPathsForVisibleRows] lastObject] row];
    else
        _bottomRow = -1;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(_data.count && _scrolledUp)
        _bottomRow = [[[self.tableView indexPathsForVisibleRows] lastObject] row];
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
            [self.tableView reloadData];
            if(_bottomRow >= 0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_bottomRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                _bottomRow = -1;
            } else {
                [self _scrollToBottom];
            }
        }
    }
    _lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
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
    }
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        if([[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid] == nil) {
            NSLog(@"This buffer contains no events, switching to backlog failed header view");
            self.tableView.tableHeaderView = _backlogFailedView;
            return;
        }
    }
    if([notification.object bid] == -1 || (_buffer && [notification.object bid] == _buffer.bid && _requestingBacklog)) {
        NSLog(@"Backlog loaded in current buffer, will find and remove the last seen EID marker");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
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
    NSTimeInterval eid = _scrolledUpFrom;
    if(eid <= 0) {
        Event *last;
        for(int i = events.count - 1; i >= 0; i--) {
            last = [events objectAtIndex:i];
            if(!last.pending && last.rowType != ROW_LASTSEENEID)
                break;
        }
        if(!last.pending) {
            eid = last.eid;
        }
    }
    if(eid >= 0 && eid > _buffer.last_seen_eid) {
        [_conn heartbeat:_buffer.bid cid:_buffer.cid bid:_buffer.bid lastSeenEid:eid];
        _buffer.last_seen_eid = eid;
    }
    _heartbeatTimer = nil;
}

- (void)sendHeartbeat {
    [_heartbeatTimer invalidate];
    
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_sendHeartbeat) userInfo:nil repeats:NO];
}

- (void)handleEvent:(NSNotification *)notification {
    IRCCloudJSONObject *o;
    Event *e;
    Buffer *b;
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
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
                        if(e.reqId == reqid && e.pending) {
                            if(i>1) {
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
            }
            [self refresh];
            break;
        default:
            break;
    }
}

- (void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped {
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

    if([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"]) {
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
        }
        
        [_formatter setDateFormat:@"DDD"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:eid/1000000];
        
        if(_currentCollapsedEid == -1 || ![[_formatter stringFromDate:date] isEqualToString:_lastCollpasedDay]) {
            [_collapsedEvents clear];
            _currentCollapsedEid = eid;
            _lastCollpasedDay = [_formatter stringFromDate:date];
        }
        
        if([type isEqualToString:@"user_channel_mode"]) {
            event.color = [UIColor blackColor];
            event.bgColor = [UIColor statusBackgroundColor];
        } else {
            event.color = [UIColor timestampColor];
            event.bgColor = [UIColor whiteColor];
        }
        
        if(![_collapsedEvents addEvent:event]) {
            [_collapsedEvents clear];
        }
        
        NSString *msg;
        if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
            CollapsedEvents *c = [[CollapsedEvents alloc] init];
            [c addEvent:event];
            msg = [c collapse];
            if(!nextIsGrouped) {
                NSString *groupMsg = [_collapsedEvents collapse];
                if(groupMsg == nil && [type isEqualToString:@"nickchange"])
                    groupMsg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
                if(groupMsg == nil && [type isEqualToString:@"user_channel_mode"]) {
                    groupMsg = [NSString stringWithFormat:@"%c%@%c set mode: %c%@ %@%c", BOLD, [ColorFormatter formatNick:event.from mode:event.fromMode], BOLD, BOLD, event.diff, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
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
            }
        } else {
            msg = (nextIsGrouped && _currentCollapsedEid != event.eid)?@"":[_collapsedEvents collapse];
        }
        if(msg == nil && [type isEqualToString:@"nickchange"])
            msg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
        if(msg == nil && [type isEqualToString:@"user_channel_mode"]) {
            msg = [NSString stringWithFormat:@"%c%@%c set mode: %c%@ %@%c", BOLD, [ColorFormatter formatNick:event.from mode:event.fromMode], BOLD, BOLD, event.diff, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
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
    } else {
        _currentCollapsedEid = -1;
        [_collapsedEvents clear];

        if(!event.formatted) {
            if([event.from length]) {
                event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [ColorFormatter formatNick:event.from mode:event.fromMode], event.msg];
            } else {
                event.formattedMsg = event.msg;
            }
        }
    }
    
    if(event.ignoreMask.length && ![type isEqualToString:@"user_channel_mode"] && [type rangeOfString:@"kicked"].location == NSNotFound) {
        if([_ignore match:event.ignoreMask]) {
            if(_topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0)
                [self sendHeartbeat];
            return;
        }
    }
    
    if(!event.formatted) {
        if([type isEqualToString:@"channel_mode"] && event.nick.length > 0) {
            event.formattedMsg = [NSString stringWithFormat:@"%@ by %@", event.msg, [ColorFormatter formatNick:event.nick mode:event.fromMode]];
        } else if([type isEqualToString:@"buffer_me_msg"]) {
            event.formattedMsg = [NSString stringWithFormat:@"— %c%@ %@", ITALICS, [ColorFormatter formatNick:event.nick mode:event.fromMode], event.msg];
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
            event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by %@ (%@)", [ColorFormatter formatNick:event.nick mode:event.fromMode], event.hostmask];
            if(event.msg.length > 0)
                event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@": %@", event.msg];
        } else if([type isEqualToString:@"channel_mode_list_change"]) {
            if(event.from.length == 0)
                event.formattedMsg = [NSString stringWithFormat:@"%@%@", event.msg, [ColorFormatter formatNick:event.nick mode:event.fromMode]];
        }
    }
    
    [self _addItem:event eid:eid];
    
    if(!backlog) {
        [self.tableView reloadData];
        if(!_scrolledUp) {
            [self scrollToBottom];
            [self _scrollToBottom];
        } else if(!event.isSelf) {
            _newMsgs++;
            if(event.isHighlight)
                _newHighlights++;
            [self updateUnread];
            [self scrollViewDidScroll:self.tableView];
        }
    }
}

-(void)updateTopUnread:(int)firstRow {
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
            _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i unread message", firstRow - _lastSeenEidPos];
        } else if(firstRow - _lastSeenEidPos > 0) {
            _topUnreadlabel.text = [msg stringByAppendingFormat:@"%i unread messages", firstRow - _lastSeenEidPos];
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
        _bottomHighlightsCountView.count = [NSString stringWithFormat:@"%i", _newHighlights];
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
            msg = [msg stringByAppendingFormat:@"%i unread message", _newMsgs - _newHighlights];
        else
            msg = [msg stringByAppendingFormat:@"%i unread messages", _newMsgs - _newHighlights];
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
    int insertPos = -1;
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
        TFLog(@"Couldn't insert EID: %f MSG: %@", eid, e.formattedMsg);
        [_lock unlock];
        return;
    }
    
    if(eid > _buffer.last_seen_eid && e.isHighlight) {
        [_unseenHighlightPositions addObject:@(insertPos)];
        [_unseenHighlightPositions sortUsingSelector:@selector(compare:)];
    }
    
    if(eid < _minEid || _minEid == 0)
        _minEid = eid;
    
    if(eid == _currentCollapsedEid && e.eid == eid)
        _currentGroupPosition = insertPos;
    else
        _currentGroupPosition = -1;
    
    if(![lastDay isEqualToString:e.day]) {
        [_formatter setDateFormat:@"EEEE, MMMM dd, yyyy"];
        Event *d = [[Event alloc] init];
        d.type = TYPE_TIMESTMP;
        d.rowType = ROW_TIMESTAMP;
        d.eid = eid;
        d.groupEid = -1;
        d.timestamp = [_formatter stringFromDate:date];
        d.bgColor = [UIColor timestampBackgroundColor];
        [_data insertObject:d atIndex:insertPos];
        if(_currentGroupPosition > -1)
            _currentGroupPosition++;
    }
    [_lock unlock];
}

-(void)setBuffer:(Buffer *)buffer {
    _ready = NO;
    [_scrollTimer invalidate];
    _scrollTimer = nil;
    _requestingBacklog = NO;
    if(buffer.bid != _buffer.bid) {
        for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:buffer.bid]) {
            if(event.rowType == ROW_LASTSEENEID) {
                [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                break;
            }
            event.formatted = nil;
            event.timestamp = nil;
        }
        _scrolledUp = NO;
        _scrolledUpFrom = -1;
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
    if(_data.count) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: NO];
        [self scrollViewDidScroll:self.tableView];
    }
    _scrollTimer = nil;
    _scrolledUp = NO;
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
    int oldPosition = (_requestingBacklog && _data.count)?[[[self.tableView indexPathsForVisibleRows] objectAtIndex: 0] row]:-1;
    NSTimeInterval backlogEid = (_requestingBacklog && _data.count)?[[_data objectAtIndex:oldPosition] groupEid]-1:0;
    if(backlogEid < 1)
        backlogEid = (_requestingBacklog && _data.count)?[[_data objectAtIndex:oldPosition] eid]-1:0;

    [_data removeAllObjects];
    _minEid = _maxEid = _earliestEid = _newMsgs = _newHighlights = 0;
    _lastSeenEidPos = -1;
    _currentCollapsedEid = 0;
    _currentGroupPosition = -1;
    _lastCollpasedDay = @"";
    [_collapsedEvents clear];
    [_unseenHighlightPositions removeAllObjects];
    
    if(!_buffer) {
        [self.tableView reloadData];
        return;
    }

    if(_conn.state == kIRCCloudStateConnected)
        [[NetworkConnection sharedInstance] cancelIdleTimer]; //This may take a while

    __timestampWidth = [@"88:88" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
    if([_conn prefs] && [[[_conn prefs] objectForKey:@"time-seconds"] boolValue])
        __timestampWidth += [@":88" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
    if(!([_conn prefs] && [[[_conn prefs] objectForKey:@"time-24hr"] boolValue]))
        __timestampWidth += [@" AM" sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE]].width;
    
    NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
    if(!events || (events.count == 0 && _buffer.min_eid > 0)) {
        if(_buffer.bid != -1 && _buffer.min_eid > 0) {
            self.tableView.tableHeaderView = _headerView;
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid];
        } else {
            self.tableView.tableHeaderView = nil;
        }
    } else if(events.count) {
        [_ignore setIgnores:_server.ignores];
        _earliestEid = ((Event *)[events objectAtIndex:0]).eid;
        if(_earliestEid > _buffer.min_eid && _buffer.min_eid > 0) {
            self.tableView.tableHeaderView = _headerView;
        } else {
            self.tableView.tableHeaderView = nil;
        }
        for(Event *e in events) {
            [self insertEvent:e backlog:true nextIsGrouped:false];
        }
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
    if(_requestingBacklog && backlogEid > 0 && _scrolledUp) {
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
                    _scrolledUpFrom = [[_data objectAtIndex:[[[self.tableView indexPathsForVisibleRows] lastObject] row]] eid];
                    break;
                }
                i++;
            }
            _eidToOpen = -1;
        } else {
            if(!_scrolledUp)
                _scrolledUpFrom = -1;
        }
    } else if(!_scrolledUp || (_data.count && _scrollTimer)) {
        [self _scrollToBottom];
        [self scrollToBottom];
    }
    
    if(_data.count) {
        int firstRow = [[[self.tableView indexPathsForVisibleRows] objectAtIndex:0] row];
        if(_lastSeenEidPos >=0 && firstRow > _lastSeenEidPos) {
            if(!_scrolledUp) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _topUnreadView.alpha = 1;
                [UIView commitAnimations];
            }
            [self updateTopUnread:firstRow];
        }
        _requestingBacklog = NO;
        if(_scrolledUpFrom > 0) {
            for(Event *e in _data) {
                if(_buffer.last_seen_eid > 0 && e.eid > _buffer.last_seen_eid && e.eid > _scrolledUpFrom && !e.isSelf && e.rowType != ROW_LASTSEENEID) {
                    _newMsgs++;
                    if(e.isHighlight)
                        _newHighlights++;
                }
            }
        }
    }
    
    if(_conn.state == kIRCCloudStateConnected)
        [[NetworkConnection sharedInstance] scheduleIdleTimer];
    _ready = YES;
    [self updateUnread];
    [self scrollViewDidScroll:self.tableView];
    [_lock unlock];
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
    int count = _data.count;
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
            //TFLog(@"No formatted message: %@", e);
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
    Event *e = [_data objectAtIndex:[indexPath row]];
    [_lock unlock];
    cell.type = e.rowType;
    cell.contentView.backgroundColor = e.bgColor;
    cell.message.delegate = self;
    cell.message.dataDetectorTypes = UIDataDetectorTypeNone;
    cell.message.text = e.formatted;
    if(e.rowType == ROW_MESSAGE && e.groupEid > 0 && (e.groupEid != e.eid || [_expandedSectionEids objectForKey:@(e.groupEid)])) {
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
    if(e.linkify) {
        for(NSTextCheckingResult *result in e.links) {
            if(result.resultType == NSTextCheckingTypeLink) {
                [cell.message addLinkWithTextCheckingResult:result];
            } else {
                NSString *url = [[e.formatted attributedSubstringFromRange:result.range] string];
                if(![url hasPrefix:@"irc"])
                    url = [NSString stringWithFormat:@"irc%@://%@:%i/%@", (_server.ssl==1)?@"s":@"", _server.hostname, _server.port, url];
                [cell.message addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
            }
        }
    }
    if(e.rowType == ROW_LASTSEENEID)
        cell.timestamp.text = @"New Messages";
    else
        cell.timestamp.text = e.timestamp;
    if(e.rowType == ROW_TIMESTAMP) {
        cell.timestamp.textColor = [UIColor blackColor];
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
        if(_lastSeenEidPos > 0) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            _topUnreadView.alpha = 0;
            [UIView commitAnimations];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSeenEidPos+1 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated: YES];
            [self scrollViewDidScroll:self.tableView];
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
    }
}

#pragma mark - Table view delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [_delegate dismissKeyboard];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!_ready || !_buffer)
        return;

    int firstRow = -1;
    int lastRow = -1;
    NSArray *rows = [self.tableView indexPathsForVisibleRows];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
        lastRow = [[rows lastObject] row];
    }
    
    if(self.tableView.tableHeaderView == _headerView && _minEid > 0 && _buffer && _buffer.bid != -1 && (_scrolledUp || (_data.count && firstRow == 0 && lastRow == _data.count - 1))) {
        if(!_requestingBacklog && _conn.state == kIRCCloudStateConnected && scrollView.contentOffset.y < _headerView.frame.size.height) {
            NSLog(@"The table scrolled and the loading header became visible, requesting more backlog");
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid];
        }
    }
    
    if(rows.count) {
        if(_data.count) {
            if(lastRow == _data.count - 1) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                _bottomUnreadView.alpha = 0;
                [UIView commitAnimations];
                _newMsgs = 0;
                _newHighlights = 0;
                if(_topUnreadView.alpha == 0)
                    [self _sendHeartbeat];
                _scrolledUp = NO;
                _scrolledUpFrom = -1;
            } else {
                if(!_scrolledUp)
                    _scrolledUpFrom = [[_data lastObject] eid];
                _scrolledUp = YES;
            }

            if(_lastSeenEidPos >= 0) {
                if(_lastSeenEidPos > 0 && firstRow <= _lastSeenEidPos + 1) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    _topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                    [self _sendHeartbeat];
                } else {
                    [self updateTopUnread:firstRow];
                }
            }
            
            if(self.tableView.tableHeaderView != _headerView && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && firstRow > 0 && lastRow < _data.count)
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
                else
                    [_expandedSectionEids setObject:@(YES) forKey:@(group)];
                for(Event *e in _data) {
                    e.timestamp = nil;
                    e.formatted = nil;
                }
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
    [self refresh];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                [_delegate rowLongPressed:[_data objectAtIndex:indexPath.row] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    }
}
@end
