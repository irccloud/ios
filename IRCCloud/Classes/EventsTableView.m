//
//  EventsTableView.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "EventsTableView.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"

#define ROW_MESSAGE 0
#define ROW_TIMESTAMP 1
#define ROW_BACKLOG 2
#define ROW_LASTSEENEID 3
#define TYPE_TIMESTMP @"__timestamp__"
#define TYPE_BACKLOG @"__backlog__"
#define TYPE_LASTSEENEID @"__lastseeneid"

@interface EventsTableCell : UITableViewCell {
    UILabel *_timestamp;
    TTTAttributedLabel *_message;
    int _type;
}
@property int type;
@property (readonly) UILabel *timestamp;
@property (readonly) TTTAttributedLabel *message;
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
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    if(_type == ROW_MESSAGE) {
        frame.origin.x = 6;
        frame.origin.y = 4;
        frame.size.height -= 6;
        frame.size.width -= 12;
        _timestamp.textAlignment = NSTextAlignmentRight;
        _timestamp.frame = CGRectMake(frame.origin.x, frame.origin.y, 70, 20);
        _timestamp.hidden = NO;
        _message.frame = CGRectMake(frame.origin.x + 76, frame.origin.y, frame.size.width - 76, frame.size.height);
        _message.hidden = NO;
    } else {
        if(_type == ROW_BACKLOG) {
            frame.origin.y = frame.size.height / 2;
            frame.size.height = 1;
        }
        _timestamp.frame = frame;
        _timestamp.hidden = NO;
        _timestamp.textAlignment = NSTextAlignmentCenter;
        _message.hidden = YES;
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
        _conn = [NetworkConnection sharedInstance];
        _ready = NO;
        _formatter = [[NSDateFormatter alloc] init];
        _data = [[NSMutableArray alloc] init];
        _expandedSectionEids = [[NSMutableDictionary alloc] init];
        _collapsedEvents = [[CollapsedEvents alloc] init];
        _buffer = nil;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(_buffer && [notification.object bid] == _buffer.bid) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self refresh];
        }];
    }
}

- (void)_sendHeartbeat {
    NSTimeInterval eid = [[_data lastObject] eid];
    if(eid > _buffer.last_seen_eid) {
        //[_conn heartbeat:_buffer.bid cid:_buffer.cid bid:_buffer.bid lastSeenEid:eid];
        //_buffer.last_seen_eid = eid;
    }
    _heartbeatTimer = nil;
}

- (void)sendHeartbeat {
    [_heartbeatTimer invalidate];
    
    _heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(_sendHeartbeat) userInfo:nil repeats:NO];
}

- (void)handleEvent:(NSNotification *)notification {
    IRCCloudJSONObject *e;
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
            e = notification.object;
            if(e.bid == _buffer.bid) {
                Event *event = [[EventsDataSource sharedInstance] event:e.eid buffer:e.bid];
                [self insertEvent:event backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventBufferMsg:
            if(((Event *)notification.object).bid == _buffer.bid) {
                //TODO: clear pending events
                [self insertEvent:notification.object backlog:NO nextIsGrouped:NO];
            }
        default:
            break;
    }
}

- (void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped {
    if(_minEid == 0)
        _minEid = event.eid;
    if(event.eid == _minEid) {
        //TODO: hide the loading header
    }
    if(event.eid < _earliestEid || _earliestEid == 0)
        _earliestEid = event.eid;
    
    NSTimeInterval eid = event.eid;
    NSString *type = event.type;
    if([type hasPrefix:@"you_"]) {
        type = [type substringFromIndex:4];
    }

    if([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"]) {
        //TODO: check join/part/quit hidden map
        
        [_formatter setDateFormat:@"DDD"];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:eid/1000000];
        
        if(_currentCollapsedEid == -1 || ![[_formatter stringFromDate:date] isEqualToString:_lastCollpasedDay]) {
            [_collapsedEvents clear];
            _currentCollapsedEid = eid;
            _lastCollpasedDay = [_formatter stringFromDate:date];
        }
        
        if([_expandedSectionEids objectForKey:@(_currentCollapsedEid)])
            [_collapsedEvents clear];
        
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
        
        NSString *msg = (nextIsGrouped && _currentCollapsedEid != event.eid)?@"":[_collapsedEvents collapse];
        if(msg == nil && [type isEqualToString:@"nickchange"])
            msg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
        if(msg == nil && [type isEqualToString:@"user_channel_mode"]) {
            msg = [NSString stringWithFormat:@"%c%@%c set mode: %c%@ %@%c", BOLD, [ColorFormatter formatNick:event.from mode:event.fromMode], BOLD, BOLD, event.diff, [ColorFormatter formatNick:event.nick mode:event.fromMode], BOLD];
            _currentCollapsedEid = eid;
        }
        if(![_expandedSectionEids objectForKey:@(_currentCollapsedEid)]) {
            if(eid != _currentCollapsedEid) {
                msg = [NSString stringWithFormat:@"[+] %@", msg];
                event.color = [UIColor timestampColor];
                event.bgColor = [UIColor whiteColor];
            }
            eid = _currentCollapsedEid;
        }
        event.groupMsg = msg;
        event.formattedMsg = nil;
        event.linkify = NO;
    } else {
        _currentCollapsedEid = -1;
        [_collapsedEvents clear];

        if([event.from length]) {
            event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [ColorFormatter formatNick:event.from mode:event.fromMode], event.msg];
        } else {
            event.formattedMsg = event.msg;
        }
    }
    
    //TODO: check ignores
    
    if([type isEqualToString:@"channel_mode"] && event.nick.length > 0) {
        event.formattedMsg = [NSString stringWithFormat:@"%@ by %c%@", event.msg, BOLD, event.nick];
    } else if([type isEqualToString:@"buffer_me_msg"]) {
        event.formattedMsg = [NSString stringWithFormat:@"— %c%c%@%c %@", ITALICS, BOLD, event.nick, BOLD, event.msg];
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
        event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by %c%@%c (%@)", BOLD, event.nick, CLEAR, event.hostmask];
        if(event.msg.length > 0)
            event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@": %@", event.msg];
    } else if([type isEqualToString:@"channel_mode_list_change"]) {
        if(event.from.length == 0)
            event.formattedMsg = [NSString stringWithFormat:@"%@ %c%@", event.msg, BOLD, event.nick];
    }

    [self _addItem:event eid:eid];
    
    if(!backlog) {
        [self.tableView reloadData];
        if([[[self.tableView indexPathsForVisibleRows] lastObject] row] == _data.count-2) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: YES];
        } else {
            _newMsgs++;
            if(event.isHighlight)
                _newHighlights++;
            [self updateUnread];
        }
    }
}

-(void)updateTopUnread:(int)firstRow {
    //TODO: resize the label and set the highlight indicator if required
    NSString *msg = @""; // @"highlighst and "; when highlights are unread
    if(_lastSeenEidPos == 0) {
        int seconds = ([[_data objectAtIndex:firstRow] eid] - _buffer.last_seen_eid) / 1000000;
        int minutes = seconds / 60;
        int hours = minutes / 60;
        int days = hours / 24;
        if(days) {
            if(days == 1)
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About a day of unread messages"];
            else
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About %i days of unread messages", days];
        } else if(hours) {
            if(hours == 1)
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About an hour of unread messages"];
            else
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About %i hours of unread messages", hours];
        } else if(minutes) {
            if(minutes == 1)
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About a minute of unread messages"];
            else
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About %i minutes of unread messages", minutes];
        } else {
            if(seconds == 1)
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About a second of unread messages"];
            else
                _topUndreadlabel.text = [msg stringByAppendingFormat:@"About %i seconds of unread messages", seconds];
        }
    } else {
        if(firstRow - _lastSeenEidPos == 1)
            _topUndreadlabel.text = [msg stringByAppendingFormat:@"%i unread message", firstRow - _lastSeenEidPos];
        else
            _topUndreadlabel.text = [msg stringByAppendingFormat:@"%i unread messages", firstRow - _lastSeenEidPos];
    }
}

-(void)updateUnread {
    if(_newMsgs > 0) {
        //TODO: resize the label and set the highlight indicator if required
        _bottomUndreadlabel.text = [NSString stringWithFormat:@"%i unread messages", _newMsgs];
        _bottomUnreadView.alpha = 1; //TODO: animate this
    }
}

-(void)_addItem:(Event *)e eid:(NSTimeInterval)eid {
    int insertPos = -1;
    NSString *lastDay = nil;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:eid/1000000];
    //TODO: check date format pref
    [_formatter setDateFormat:@"h:mm a"];
    e.timestamp = [_formatter stringFromDate:date];
    e.groupEid = _currentCollapsedEid;
    e.formatted = nil;
    if(e.groupMsg && !e.formattedMsg)
        e.formattedMsg = e.groupMsg;
    
    if(eid > _maxEid || _data.count == 0 || eid > ((Event *)[_data objectAtIndex:_data.count - 1]).eid) {
        //Message at bottom
        if(_data.count) {
            [_formatter setDateFormat:@"DDD"];
            lastDay = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:((Event *)[_data objectAtIndex:_data.count - 1]).eid/1000000]];
        }
        _maxEid = eid;
        [_data addObject:e];
        insertPos = _data.count - 1;
    } else if(_minEid > eid) {
        //Message on top
        if(_data.count > 1) {
            [_formatter setDateFormat:@"DDD"];
            lastDay = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:((Event *)[_data objectAtIndex:1]).eid/1000000]];
            if(![lastDay isEqualToString:[_formatter stringFromDate:date]]) {
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
            if(e1.rowType != ROW_TIMESTAMP && e1.eid > eid && e.eid == eid) {
                //Insert the message
                if(i > 0 && ((Event *)[_data objectAtIndex:i - 1]).rowType != ROW_TIMESTAMP) {
                    [_formatter setDateFormat:@"DDD"];
                    lastDay = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:((Event *)[_data objectAtIndex:i - 1]).eid/1000000]];
                    [_data insertObject:e atIndex:i];
                    insertPos = i;
                    break;
                } else {
                    //There was a dateline above our insertion point
                    [_formatter setDateFormat:@"DDD"];
                    lastDay = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:e1.eid/1000000]];
                    if(![lastDay isEqualToString:[_formatter stringFromDate:date]]) {
                        if(i > 1) {
                            lastDay = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:((Event *)[_data objectAtIndex:i - 2]).eid/1000000]];
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
                [_formatter setDateFormat:@"DDD"];
                lastDay = [_formatter stringFromDate:date];
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
        return;
    }
    
    //TODO: update unseen highlight positions array
    
    if(eid < _minEid || _minEid == 0)
        _minEid = eid;
    
    if(eid == _currentCollapsedEid && e.eid == eid)
        _currentGroupPosition = insertPos;
    else
        _currentGroupPosition = -1;
    
    [_formatter setDateFormat:@"DDD"];
    if(![lastDay isEqualToString:[_formatter stringFromDate:date]]) {
        [_formatter setDateFormat:@"EEEE, MMMM dd, yyyy"];
        Event *d = [[Event alloc] init];
        d.type = TYPE_TIMESTMP;
        d.rowType = ROW_TIMESTAMP;
        d.eid = eid;
        d.timestamp = [_formatter stringFromDate:date];
        d.bgColor = [UIColor timestampColor];
        [_data insertObject:d atIndex:insertPos];
        if(_currentGroupPosition > -1)
            _currentGroupPosition++;
    }
}

-(void)setBuffer:(Buffer *)buffer {
    _topUnreadView.alpha = 0;
    _bottomUnreadView.alpha = 0;
    _requestingBacklog = NO;
    _buffer = buffer;
    _earliestEid = 0;
    [_expandedSectionEids removeAllObjects];
    [self refresh];
}

- (void)refresh {
    @synchronized(_data) {
        _ready = NO;
        int oldPosition = (_requestingBacklog && _data.count)?[[[self.tableView indexPathsForVisibleRows] objectAtIndex: 0] row]:-1;
        NSTimeInterval backlogEid = (_requestingBacklog && _data.count)?[[_data objectAtIndex:oldPosition] groupEid]-1:0;
        if(backlogEid < 1)
            backlogEid = (_requestingBacklog && _data.count)?[[_data objectAtIndex:oldPosition] eid]-1:0;

        [_data removeAllObjects];
        _minEid = _maxEid = _earliestEid = 0;
        _lastSeenEidPos = -1;
        _currentCollapsedEid = 0;
        _currentGroupPosition = -1;
        _lastCollpasedDay = @"";
        [_collapsedEvents clear];
        
        [[NetworkConnection sharedInstance] cancelIdleTimer]; //This may take a while

        //TODO: calculate the timestamp width
        
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
        if(!events || (events.count == 0 && _buffer.min_eid > 0)) {
            if(_buffer.bid != -1) {
                _requestingBacklog = YES;
                [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid];
            } else {
                self.tableView.tableHeaderView = nil;
            }
        } else if(events.count) {
            //TODO: refresh the ignores array
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
            e.eid = _buffer.last_seen_eid;
            e.type = TYPE_LASTSEENEID;
            e.rowType = ROW_LASTSEENEID;
            e.formattedMsg = nil;
            e.bgColor = [UIColor whiteColor];
            e.timestamp = @"==== New Messages ====";
            _lastSeenEidPos = _data.count - 1;
            NSEnumerator *i = [_data reverseObjectEnumerator];
            Event *event = [i nextObject];
            while(event) {
                if(event.eid <= _buffer.last_seen_eid)
                    break;
                event = [i nextObject];
                _lastSeenEidPos--;
            }
            if(_lastSeenEidPos != _data.count - 1) {
                if(_lastSeenEidPos > 0 && [[_data objectAtIndex:_lastSeenEidPos - 1] rowType] == ROW_TIMESTAMP)
                    _lastSeenEidPos--;
                if(_lastSeenEidPos > 0)
                    [_data insertObject:e atIndex:_lastSeenEidPos + 1];
            } else {
                _lastSeenEidPos = -1;
            }
        }
        
        [self.tableView reloadData];
        if(_requestingBacklog && backlogEid > 0) {
            int markerPos = -1;
            for(Event *e in _data) {
                if(e.eid == backlogEid)
                    break;
                markerPos++;
            }
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:markerPos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        } else if(_data.count) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: NO];
        }
        
        int firstRow = [[[self.tableView indexPathsForVisibleRows] objectAtIndex:0] row];
        if(_lastSeenEidPos >=0 && firstRow > _lastSeenEidPos) {
            _topUnreadView.alpha = 1; //TODO: animate this
            [self updateTopUnread:firstRow];
        }
        
        [[NetworkConnection sharedInstance] scheduleIdleTimer];
        _ready = YES;
        _requestingBacklog = NO;
        [self scrollViewDidScroll:self.tableView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    @synchronized(_data) {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    @synchronized(_data) {
        return _data.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_data) {
        Event *e = [_data objectAtIndex:indexPath.row];
        if(e.rowType == ROW_MESSAGE) {
            if(e.formatted == nil && e.formattedMsg.length > 0) {
                e.formatted = [ColorFormatter format:e.formattedMsg defaultColor:e.color mono:e.monospace];
            } else if(e.formattedMsg.length == 0) {
                TFLog(@"No formatted message: %@", e);
                return 26;
            }
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(e.formatted));
             CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.tableView.frame.size.width - 76 - 12,CGFLOAT_MAX), NULL);
             float height = ceilf(suggestedSize.height);
             CFRelease(framesetter);
            return height + 8;
        } else {
            return 26;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_data) {
        EventsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"eventscell"];
        if(!cell)
            cell = [[EventsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"eventscell"];
        Event *e = [_data objectAtIndex:[indexPath row]];
        cell.type = e.rowType;
        cell.contentView.backgroundColor = e.bgColor;
        cell.message.delegate = self;
        if(e.linkify)
            cell.message.dataDetectorTypes = UIDataDetectorTypeLink;
        else
            cell.message.dataDetectorTypes = UIDataDetectorTypeNone;
        cell.message.text = e.formatted;
        cell.timestamp.text = e.timestamp;
        if(e.rowType == ROW_TIMESTAMP) {
            cell.timestamp.textColor = [UIColor blackColor];
        } else {
            cell.timestamp.textColor = [UIColor timestampColor];
        }
        if(e.rowType == ROW_BACKLOG) {
            cell.timestamp.backgroundColor = [UIColor selectedBlueColor];
        } else {
            cell.timestamp.backgroundColor = [UIColor clearColor];
        }
        return cell;
    }
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    //TODO: check for irc:// URLs
    [[UIApplication sharedApplication] openURL:url];
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

-(IBAction)topUnreadBarClicked:(id)sender {
    if(_topUnreadView.alpha) {
        _topUnreadView.alpha = 0; //TODO: animate this
        if(_lastSeenEidPos > 0)
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_lastSeenEidPos+1 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated: YES];
        else
            [self.tableView setContentOffset:CGPointMake(0,0) animated:YES];
    }
}

-(IBAction)bottomUnreadBarClicked:(id)sender {
    if(_bottomUnreadView.alpha) {
        _bottomUnreadView.alpha = 0; //TODO: animate this
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count-1 inSection:0] atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }
}

#pragma mark - Table view delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!_ready)
        return;
    
    if(self.tableView.tableHeaderView && _minEid > 0 && _buffer && _buffer.bid != -1/* TODO: && conn.ready */) {
        if(!_requestingBacklog && _conn.state == kIRCCloudStateConnected && scrollView.contentOffset.y < _headerView.frame.size.height) {
            _requestingBacklog = YES;
            [_conn requestBacklogForBuffer:_buffer.bid server:_buffer.cid beforeId:_earliestEid];
        }
    }
    
    NSArray *rows = [self.tableView indexPathsForVisibleRows];
    if(rows.count) {
        int firstRow = [[rows objectAtIndex:0] row];
        int lastRow = [[rows lastObject] row];
        
        if(_bottomUnreadView && _data.count) {
            if(lastRow == _data.count - 1) {
                _bottomUnreadView.alpha = 0; //TODO: animate this
                _newMsgs = 0;
                _newHighlights = 0;
                if(_topUnreadView.alpha == 0)
                    [self _sendHeartbeat];
            }
        }
        
        if(_topUnreadView && _data.count) {
            if(_lastSeenEidPos >= 0) {
                if(_lastSeenEidPos > 0 && firstRow <= _lastSeenEidPos) {
                    _topUnreadView.alpha = 0; //TODO: animate this
                    [self _sendHeartbeat];
                } else {
                    [self updateTopUnread:firstRow];
                }
            }
        }
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSTimeInterval group = ((Event *)[_data objectAtIndex:indexPath.row]).groupEid;
    if(group) {
        if([_expandedSectionEids objectForKey:@(group)])
            [_expandedSectionEids removeObjectForKey:@(group)];
        else
            [_expandedSectionEids setObject:@(YES) forKey:@(group)];
        [self refresh];
    }
}

@end
