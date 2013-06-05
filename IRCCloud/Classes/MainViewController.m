//
//  MainViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <MobileCoreServices/UTCoreTypes.h>
#import "MainViewController.h"
#import "NetworkConnection.h"
#import "ColorFormatter.h"
#import "BansTableViewController.h"
#import "AppDelegate.h"
#import "IgnoresTableViewController.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ECSlidingViewController.h"
#import "ChannelInfoViewController.h"

#define TAG_BAN 1
#define TAG_IGNORE 2
#define TAG_KICK 3
#define TAG_INVITE 4
#define TAG_BADCHANNELKEY 5
#define TAG_INVALIDNICK 6

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _cidToOpen = -1;
        _bidToOpen = -1;
        _pendingEvents = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.titleView = _titleView;
    
    _barButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(0,0,_toolBar.frame.size.width, _toolBar.frame.size.height)];
    _barButtonContainer.autoresizesSubviews = YES;
    _barButtonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImage *buttonImage = [[UIImage imageNamed:@"UINavigationBarDefaultButton"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    UIImage *pressedButtonImage = [[UIImage imageNamed:@"UINavigationBarDefaultButtonPressed"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    UIImage *doneButtonImage = [[UIImage imageNamed:@"UINavigationBarDoneButton"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    UIImage *donePressedButtonImage = [[UIImage imageNamed:@"UINavigationBarDoneButtonPressed"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    button.contentMode = UIViewContentModeScaleToFill;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [button setBackgroundImage:buttonImage forState:UIControlStateNormal];
    [button setBackgroundImage:pressedButtonImage forState:UIControlStateHighlighted];
    [button setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    button.frame = CGRectMake(8,8,button.frame.size.width + 12, button.frame.size.height);
    [_barButtonContainer addSubview:button];

    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    button.contentMode = UIViewContentModeScaleToFill;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    
    [button setBackgroundImage:doneButtonImage forState:UIControlStateNormal];
    [button setBackgroundImage:donePressedButtonImage forState:UIControlStateHighlighted];
    [button setTitle:@"Send" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    button.frame = CGRectMake(_toolBar.frame.size.width - button.frame.size.width - 20,8,button.frame.size.width + 12,button.frame.size.height);
    [_barButtonContainer addSubview:button];
    
    [_toolBar addSubview:_barButtonContainer];
    
    if(_buffersView)
        [self addChildViewController:_buffersView];
    [self addChildViewController:_eventsView];
    
    if(_usersView)
        [self addChildViewController:_usersView];
    
    if(self.slidingViewController) {
        _buffersView = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
        _usersView = [[UsersTableView alloc] initWithStyle:UITableViewStylePlain];
        self.slidingViewController.shouldAllowPanningPastAnchor = NO;
        self.slidingViewController.underLeftViewController = _buffersView;
        self.slidingViewController.underRightViewController = _usersView;
        self.slidingViewController.anchorLeftRevealAmount = 240;
        self.slidingViewController.anchorRightRevealAmount = 240;
        self.slidingViewController.underLeftWidthLayout = ECFixedRevealWidth;
        self.slidingViewController.underRightWidthLayout = ECFixedRevealWidth;

        self.navigationController.view.layer.shadowOpacity = 0.75f;
        self.navigationController.view.layer.shadowRadius = 10.0f;
        self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    }
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _startHeight = [UIScreen mainScreen].applicationFrame.size.height;
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(listButtonPressed:)];
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(46,8,212,35)];
        _message.maximumNumberOfLines = 8;
    } else {
        _startHeight = [UIScreen mainScreen].applicationFrame.size.width - self.navigationController.navigationBar.frame.size.height;
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(46,10,476,35)];
    }
    _message.delegate = self;
    _message.returnKeyType = UIReturnKeySend;
    [_toolBar addSubview:_message];
    _usersButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"users"] style:UIBarButtonItemStylePlain target:self action:@selector(usersButtonPressed:)];
    int bid = [BuffersDataSource sharedInstance].firstBid;
    if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"]) {
        if([[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]])
            bid = [[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue];
    }
    if(_bidToOpen != -1) {
        bid = _bidToOpen;
        _bidToOpen = -1;
    }
    [self bufferSelected:bid];
}

- (void)_updateUnreadIndicator {
    int unreadCount = 0;
    int highlightCount = 0;
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    for(Server *server in [[ServersDataSource sharedInstance] getServers]) {
        NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffersForServer:server.cid];
        for(Buffer *buffer in buffers) {
            int type = -1;
            int joined = 1;
            if([buffer.type isEqualToString:@"channel"]) {
                type = 1;
                Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:buffer.bid];
                if(!channel) {
                    joined = 0;
                }
            } else if([buffer.type isEqualToString:@"conversation"]) {
                type = 2;
            }
            if(joined > 0 && buffer.archived == 0) {
                int unread = 0;
                int highlights = 0;
                unread = [[EventsDataSource sharedInstance] unreadCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                if(type == 1) {
                    if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                } else {
                    if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                    if(type == 2 && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        highlights = 0;
                }
                if(buffer.bid != _buffer.bid) {
                    unreadCount += unread;
                    highlightCount += highlights;
                }
            }
        }
    }
    if(highlightCount)
        self.navigationItem.leftBarButtonItem.tintColor = [UIColor redColor];
    else if(unreadCount)
        self.navigationItem.leftBarButtonItem.tintColor = [UIColor selectedBlueColor];
    else
        self.navigationItem.leftBarButtonItem.tintColor = nil;
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Buffer *b = nil;
    IRCCloudJSONObject *o = nil;
    BansTableViewController *btv = nil;
    Event *e = nil;
    Server *s = nil;
    UIAlertView *alert = nil;
    NSString *msg = nil;
    NSString *type = nil;
    switch(event) {
        case kIRCEventChannelInit:
        case kIRCEventChannelTopic:
            [self _updateTitleArea];
            [self _updateUserListVisibility];
            break;
        case kIRCEventBadChannelKey:
            _alertObject = notification.object;
            s = [[ServersDataSource sharedInstance] getServer:_alertObject.cid];
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:[NSString stringWithFormat:@"Password for %@",[_alertObject objectForKey:@"chan"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
            alert.tag = TAG_BADCHANNELKEY;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            break;
        case kIRCEventInvalidNick:
            _alertObject = notification.object;
            s = [[ServersDataSource sharedInstance] getServer:_alertObject.cid];
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Invalid nickname, try again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change", nil];
            alert.tag = TAG_INVALIDNICK;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
            break;
        case kIRCEventAlert:
            o = notification.object;
            type = o.type;
            
            if([type isEqualToString:@"invite_only_chan"])
                msg = [NSString stringWithFormat:@"You need an invitation to join %@", [o objectForKey:@"chan"]];
            else if([type isEqualToString:@"channel_full"])
                msg = [NSString stringWithFormat:@"%@ isn't allowing any more members to join.", [o objectForKey:@"chan"]];
            else if([type isEqualToString:@"banned_from_channel"])
                msg = [NSString stringWithFormat:@"You've been banned from %@", [o objectForKey:@"chan"]];
            else if([type isEqualToString:@"invalid_nickchange"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"ban_channel"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"no_messages_from_non_registered"]) {
                if([[o objectForKey:@"nick"] length])
                    msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"nick"], [o objectForKey:@"msg"]];
                else
                    msg = [o objectForKey:@"msg"];
            } else if([type isEqualToString:@"not_registered"]) {
                NSString *first = [o objectForKey:@"first"];
                if([[o objectForKey:@"rest"] length])
                    first = [first stringByAppendingString:[o objectForKey:@"rest"]];
                msg = [NSString stringWithFormat:@"%@: %@", first, [o objectForKey:@"msg"]];
            } else if([type isEqualToString:@"too_many_channels"])
                msg = [NSString stringWithFormat:@"Couldn't join %@: %@", [o objectForKey:@"chan"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"too_many_targets"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"description"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"no_such_server"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"server"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"unknown_command"])
                msg = [NSString stringWithFormat:@"Unknown command: %@", [o objectForKey:@"command"]];
            else if([type isEqualToString:@"help_not_found"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"topic"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"accept_exists"])
                msg = [NSString stringWithFormat:@"%@ %@", [o objectForKey:@"nick"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"accept_not"])
                msg = [NSString stringWithFormat:@"%@ %@", [o objectForKey:@"nick"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"nick_collision"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"collision"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"nick_too_fast"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"nick"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"save_nick"])
                msg = [NSString stringWithFormat:@"%@: %@: %@", [o objectForKey:@"nick"], [o objectForKey:@"msg"], [o objectForKey:@"new_nick"]];
            else if([type isEqualToString:@"unknown_mode"])
                msg = [NSString stringWithFormat:@"Missing mode: %@", [o objectForKey:@"params"]];
            else if([type isEqualToString:@"user_not_in_channel"])
                msg = [NSString stringWithFormat:@"%@ is not in %@", [o objectForKey:@"nick"], [o objectForKey:@"channel"]];
            else if([type isEqualToString:@"need_more_params"])
                msg = [NSString stringWithFormat:@"Missing parameters for command: %@", [o objectForKey:@"command"]];
            else if([type isEqualToString:@"chan_privs_needed"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"chan"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"not_on_channel"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"channel"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"ban_on_chan"])
                msg = [NSString stringWithFormat:@"You cannot change your nick to %@ while banned on %@", [o objectForKey:@"proposed_nick"], [o objectForKey:@"channel"]];
            else if([type isEqualToString:@"cannot_send_to_chan"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"channel"], [o objectForKey:@"msg"]];
            else if([type isEqualToString:@"user_on_channel"])
                msg = [NSString stringWithFormat:@"%@ is already a member of %@", [o objectForKey:@"nick"], [o objectForKey:@"channel"]];
            else if([type isEqualToString:@"no_nick_given"])
                msg = [NSString stringWithFormat:@"No nickname given"];
            else if([type isEqualToString:@"silence"]) {
                NSString *mask = [o objectForKey:@"usermask"];
                if([mask hasPrefix:@"-"])
                    msg = [NSString stringWithFormat:@"%@ removed from silence list", [mask substringFromIndex:1]];
                else if([mask hasPrefix:@"+"])
                    msg = [NSString stringWithFormat:@"%@ added to silence list", [mask substringFromIndex:1]];
                else
                    msg = [NSString stringWithFormat:@"Silence list change: %@", mask];
            } else if([type isEqualToString:@"no_channel_topic"])
                msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"channel"], [o objectForKey:@"msg"]];
            else
                msg = [o objectForKey:@"msg"];

            s = [[ServersDataSource sharedInstance] getServer:o.cid];
            alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            break;
        case kIRCEventSelfBack:
        case kIRCEventAway:
        case kIRCEventStatusChanged:
        case kIRCEventConnectionLag:
            [self _updateServerStatus];
            break;
        case kIRCEventBanList:
            o = notification.object;
            if(o.cid == _buffer.cid && [[o objectForKey:@"channel"] isEqualToString:_buffer.name]) {
                btv = [[BansTableViewController alloc] initWithStyle:UITableViewStylePlain];
                btv.event = o;
                btv.bans = [o objectForKey:@"bans"];
                btv.bid = _buffer.bid;
                if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                    btv.navigationItem.title = @"Ban List";
                    [self.navigationController pushViewController:btv animated:YES];
                } else {
                    btv.navigationItem.title = [NSString stringWithFormat:@"Bans for %@", [o objectForKey:@"channel"]];
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:btv];
                    nc.modalPresentationStyle = UIModalPresentationFormSheet;
                    [self presentViewController:nc animated:YES completion:nil];
                }
            }
            break;
        case kIRCEventLinkChannel:
            o = notification.object;
            if(_cidToOpen == o.cid && [[o objectForKey:@"invalid_chan"] isEqualToString:_bufferToOpen]) {
                _bufferToOpen = [o objectForKey:@"valid_chan"];
                b = [[BuffersDataSource sharedInstance] getBuffer:o.bid];
            }
        case kIRCEventMakeBuffer:
            if(!b)
                b = notification.object;
            if(_cidToOpen == b.cid && [b.name isEqualToString:_bufferToOpen] && ![_buffer.name isEqualToString:_bufferToOpen]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            } else if(_buffer.bid == -1 && b.cid == _buffer.cid && [b.name isEqualToString:_buffer.name]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            }
            break;
        case kIRCEventOpenBuffer:
            o = notification.object;
            _bufferToOpen = [o objectForKey:@"name"];
            _cidToOpen = o.cid;
            b = [[BuffersDataSource sharedInstance] getBufferWithName:_bufferToOpen server:_cidToOpen];
            if(b != nil && ![b.name isEqualToString:_buffer.name]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            }
            break;
        case kIRCEventUserInfo:
        case kIRCEventPart:
            [self _updateUserListVisibility];
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            if([o objectForKey:@"_reqid"]) {
                int reqid = [[o objectForKey:@"_reqid"] intValue];
                for(Event *e in _pendingEvents) {
                    if(e.reqId == reqid) {
                        [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                        [_pendingEvents removeObject:e];
                        e.msg = [e.msg stringByAppendingFormat:@" %c4(FAILED)%c", COLOR_MIRC, CLEAR];
                        e.formattedMsg = nil;
                        e.formatted = nil;
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:e userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:kIRCEventBufferMsg]}];
                        }];
                        break;
                    }
                }
            }
            break;
        case kIRCEventBufferMsg:
            e = notification.object;
            if([[e.from lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) {
                for(Event *e in _pendingEvents) {
                    [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                }
                [_pendingEvents removeAllObjects];
            } else {
                int reqid = e.reqId;
                for(Event *e in _pendingEvents) {
                    if(e.reqId == reqid) {
                        [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                        [_pendingEvents removeObject:e];
                        break;
                    }
                }
            }
            break;
        default:
            break;
    }
    if(self.slidingViewController)
        [self _updateUnreadIndicator];
}

-(void)_showConnectingView {
    self.navigationItem.titleView = _connectingView;
}

-(void)_hideConnectingView {
    self.navigationItem.titleView = _titleView;
}

-(void)connectivityChanged:(NSNotification *)notification {
    switch([NetworkConnection sharedInstance].state) {
        case kIRCCloudStateConnecting:
            [self _showConnectingView];
            _connectingStatus.text = @"Connecting";
            [_connectingActivity startAnimating];
            _connectingActivity.hidden = NO;
            _connectingProgress.progress = 0;
            _connectingProgress.hidden = YES;
            break;
        case kIRCCloudStateDisconnected:
            if([NetworkConnection sharedInstance].reconnectTimestamp > 0) {
                [_connectingStatus setText:[NSString stringWithFormat:@"Reconnecting in %0.f seconds", [NetworkConnection sharedInstance].reconnectTimestamp - [[NSDate date] timeIntervalSince1970]]];
                _connectingActivity.hidden = NO;
                [_connectingActivity startAnimating];
                _connectingProgress.progress = 0;
                _connectingProgress.hidden = YES;
                [self performSelector:@selector(connectivityChanged:) withObject:nil afterDelay:1];
            } else {
                _connectingStatus.text = @"Disconnected";
                _connectingActivity.hidden = YES;
                _connectingProgress.progress = 0;
                _connectingProgress.hidden = YES;
            }
        case kIRCCloudStateDisconnecting:
            [self _showConnectingView];
        case kIRCCloudStateConnected:
            [_connectingActivity stopAnimating];
            for(Event *e in _pendingEvents) {
                [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
            }
            [_pendingEvents removeAllObjects];
            break;
    }
}

-(void)backlogStarted:(NSNotification *)notification {
    [_connectingStatus setText:@"Loading"];
    _connectingActivity.hidden = YES;
    [_connectingActivity stopAnimating];
    _connectingProgress.progress = 0;
    _connectingProgress.hidden = NO;
}

-(void)backlogProgress:(NSNotification *)notification {
    [_connectingProgress setProgress:[notification.object floatValue] animated:YES];
}

-(void)backlogCompleted:(NSNotification *)notification {
    [self _hideConnectingView];
    if(_buffer) {
        [self _updateServerStatus];
        [self _updateUserListVisibility];
        if(self.slidingViewController) {
            [self.slidingViewController resetTopView];
            [self _updateUnreadIndicator];
        }
    } else {
        int bid = [BuffersDataSource sharedInstance].firstBid;
        if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"]) {
            if([[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]])
                bid = [[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue];
        }
        [self bufferSelected:bid];
    }
}

-(void)keyboardWillShow:(NSNotification*)notification {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGSize keyboardSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] toView:nil].size;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    
    if(self.slidingViewController) {
        CGRect frame = self.slidingViewController.view.frame;
        frame.size.height = _startHeight - keyboardSize.height;
        self.slidingViewController.view.frame = frame;
    } else {
        CGRect frame = self.view.frame;
        frame.size.height = _startHeight - keyboardSize.height;
        self.view.frame = frame;
    }
    
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    
    if(self.slidingViewController) {
        CGRect frame = self.slidingViewController.view.frame;
        frame.size.height = _startHeight;
        self.slidingViewController.view.frame = frame;
    } else {
        CGRect frame = self.view.frame;
        frame.size.height = _startHeight;
        self.view.frame = frame;
    }
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated {
    [self _updateTitleArea];
    if(self.slidingViewController) {
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
        CGRect frame = self.slidingViewController.view.frame;
        frame.size.height = _startHeight;
        self.slidingViewController.view.frame = frame;
        [self _updateUnreadIndicator];
        [self.slidingViewController resetTopView];
    } else {
        CGRect frame = self.view.frame;
        frame.size.height = _startHeight;
        self.view.frame = frame;
    }
    [_message resignFirstResponder];
    [self connectivityChanged:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogStarted:)
                                                 name:kIRCCloudBacklogStartedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogProgress:)
                                                 name:kIRCCloudBacklogProgressNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectivityChanged:)
                                                 name:kIRCCloudConnectivityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"session"];
    if(([NetworkConnection sharedInstance].state == kIRCCloudStateDisconnected || [NetworkConnection sharedInstance].state == kIRCCloudStateDisconnecting) && session != nil && [session length] > 0)
        [[NetworkConnection sharedInstance] connect];
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.slidingViewController) {
        [self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_doubleTapTimer invalidate];
    _doubleTapTimer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)serverStatusBarPressed:(id)sender {
    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    if(s) {
        if([s.status isEqualToString:@"disconnected"])
            [[NetworkConnection sharedInstance] reconnect:_buffer.cid];
        else if([s.away isKindOfClass:[NSString class]] && s.away.length)
            [[NetworkConnection sharedInstance] back:_buffer.cid];
    }
}

-(void)sendButtonPressed:(id)sender {
    if([NetworkConnection sharedInstance].state == kIRCCloudStateConnected && _message.text && _message.text.length) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        if(s) {
            User *u = [[UsersDataSource sharedInstance] getUser:s.nick cid:s.cid bid:_buffer.bid];
            Event *e = [[Event alloc] init];
            NSString *msg = _message.text;
            if([msg hasPrefix:@"//"])
                msg = [msg substringFromIndex:1];
            else if([msg hasPrefix:@"/"] && ![[msg lowercaseString] hasPrefix:@"/me "])
                msg = nil;
            if(msg) {
                e.cid = s.cid;
                e.bid = _buffer.bid;
                e.eid = ([[NSDate date] timeIntervalSince1970] + [NetworkConnection sharedInstance].clockOffset + 0.5) * 1000000;
                e.isSelf = YES;
                e.from = s.nick;
                e.nick = s.nick;
                if(u)
                    e.fromMode = u.mode;
                e.msg = msg;
                if(msg && [[msg lowercaseString] hasPrefix:@"/me "]) {
                    e.type = @"buffer_me_msg";
                    e.msg = [msg substringFromIndex:4];
                } else {
                    e.type = @"buffer_msg";
                }
                e.color = [UIColor timestampColor];
                if([_buffer.name isEqualToString:s.nick])
                    e.bgColor = [UIColor whiteColor];
                else
                    e.bgColor = [UIColor selfBackgroundColor];
                e.rowType = 0;
                e.formatted = nil;
                e.formattedMsg = nil;
                e.groupMsg = nil;
                e.linkify = YES;
                e.targetMode = nil;
                e.isHighlight = NO;
                e.reqId = -1;
                e.pending = YES;
                [_eventsView scrollToBottom];
                [[EventsDataSource sharedInstance] addEvent:e];
                [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:e userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:kIRCEventBufferMsg]}];
            }
            e.reqId = [[NetworkConnection sharedInstance] say:_message.text to:_buffer.name cid:_buffer.cid];
            if(e.msg)
                [_pendingEvents addObject:e];
            _message.text = @"";
        }
    }
}

-(BOOL)expandingTextViewShouldReturn:(UIExpandingTextView *)expandingTextView {
    [self sendButtonPressed:expandingTextView];
    return NO;
}

-(void)expandingTextView:(UIExpandingTextView *)expandingTextView willChangeHeight:(float)height {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGRect frame = _eventsView.tableView.frame;
    frame.size.height = self.view.frame.size.height - height - 9;
    if(!_serverStatusBar.hidden)
        frame.size.height -= _serverStatusBar.frame.size.height;
    _eventsView.tableView.frame = frame;
    frame = _serverStatusBar.frame;
    frame.origin.y = self.view.frame.size.height - height - 9 - frame.size.height;
    _serverStatusBar.frame = frame;
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    _toolBar.frame = CGRectMake(_toolBar.frame.origin.x, self.view.frame.size.height - height - 9, _toolBar.frame.size.width, height + 9);
    _barButtonContainer.frame = CGRectMake(0,0,_toolBar.frame.size.width, _toolBar.frame.size.height);
}

-(void)setUnreadColor:(UIColor *)color {
    self.navigationItem.leftBarButtonItem.tintColor = color;
}

-(void)_updateTitleArea {
    if([_buffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        if(s.name.length)
            _titleLabel.text = s.name;
        else
            _titleLabel.text = s.hostname;
        self.navigationItem.title = _titleLabel.text;
    } else {
        self.navigationItem.title = _buffer.name = _titleLabel.text = _buffer.name;
        _titleLabel.frame = CGRectMake(0,0,_titleView.frame.size.width,_titleView.frame.size.height);
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        if([_buffer.type isEqualToString:@"channel"]) {
            BOOL lock = NO;
            Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid];
            if(channel) {
                if([channel.mode rangeOfString:@"k"].location != NSNotFound)
                    lock = YES;
                if([channel.topic_text isKindOfClass:[NSString class]] && channel.topic_text.length) {
                    _topicLabel.hidden = NO;
                    _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
                    _titleLabel.font = [UIFont boldSystemFontOfSize:18];
                    _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
                    _topicLabel.text = [[ColorFormatter format:channel.topic_text defaultColor:[UIColor blackColor] mono:NO linkify:NO] string];
                } else {
                    _topicLabel.hidden = YES;
                }
            }
        }
    }
}

-(void)bufferSelected:(int)bid {
    TFLog(@"BID selected: %i", bid);
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    [self _updateTitleArea];
    [_buffersView setBuffer:_buffer];
    [UIView animateWithDuration:0.1 animations:^{
        _eventsView.view.alpha=0;
        _eventsView.topUnreadView.alpha=0;
        _eventsView.bottomUnreadView.alpha=0;
        _eventActivity.alpha=1;
        [_eventActivity startAnimating];
    } completion:^(BOOL finished){
        [_eventsView setBuffer:_buffer];
        [UIView animateWithDuration:0.1 animations:^{
            _eventsView.view.alpha=1;
            _eventActivity.alpha=0;
        } completion:^(BOOL finished){
            [_eventActivity stopAnimating];
        }];
    }];
    [_usersView setBuffer:_buffer];
    [self _updateUserListVisibility];
    [self _updateServerStatus];
    if(self.slidingViewController) {
        [self.slidingViewController resetTopView];
        [self _updateUnreadIndicator];
    }
}

-(void)_updateServerStatus {
    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    if(s && (![s.status isEqualToString:@"connected_ready"] || s.lag > 2*1000*1000 || ([s.away isKindOfClass:[NSString class]] && s.away.length))) {
        if(_serverStatusBar.hidden) {
            CGRect frame = _eventsView.view.frame;
            frame.size.height -= _serverStatusBar.frame.size.height;
            _eventsView.view.frame = frame;
            frame = _eventsView.bottomUnreadView.frame;
            frame.origin.y -= _serverStatusBar.frame.size.height;
            _eventsView.bottomUnreadView.frame = frame;
            _serverStatusBar.hidden = NO;
        }
        _serverStatusBar.backgroundColor = [UIColor backgroundBlueColor];
        _serverStatus.textColor = [UIColor selectedBlueColor];
        if([s.status isEqualToString:@"connected_ready"]) {
            if([s.away isKindOfClass:[NSString class]]) {
                _serverStatusBar.backgroundColor = [UIColor lightGrayColor];
                _serverStatus.textColor = [UIColor blackColor];
                if(![[s.away lowercaseString] isEqualToString:@"away"]) {
                    _serverStatus.text = [NSString stringWithFormat:@"Away (%@). Tap to come back.", s.away];
                } else {
                    _serverStatus.text = @"Away. Tap to come back.";
                }
            } else {
                _serverStatus.text = [NSString stringWithFormat:@"Slow ping response from %@ (%is)", s.hostname, s.lag / 1000 / 1000];
            }
        } else if([s.status isEqualToString:@"quitting"]) {
            _serverStatus.text = @"Disconnecting";
        } else if([s.status isEqualToString:@"disconnected"]) {
            NSString *reason = [s.fail_info objectForKey:@"reason"];
            if([reason isKindOfClass:[NSString class]] && [reason length]) {
                if([reason isEqualToString:@"nxdomain"])
                    reason = @"Invalid hostname";
                _serverStatus.text = [NSString stringWithFormat:@"Disconnected: Failed to connect - %@", reason];
                _serverStatusBar.backgroundColor = [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
                _serverStatus.textColor = [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
            } else {
                _serverStatus.text = @"Disconnected. Tap to reconnect.";
            }
        } else if([s.status isEqualToString:@"queued"]) {
            _serverStatus.text = @"Connection Queued";
        } else if([s.status isEqualToString:@"connecting"]) {
            _serverStatus.text = @"Connecting";
        } else if([s.status isEqualToString:@"connected"]) {
            _serverStatus.text = @"Connected";
        } else if([s.status isEqualToString:@"connected_joining"]) {
            _serverStatus.text = @"Connected: Joining Channels";
        } else if([s.status isEqualToString:@"pool_unavailable"]) {
            _serverStatus.text = @"Connection temporarily unavailable";
            _serverStatusBar.backgroundColor = [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
            _serverStatus.textColor = [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
        } else if([s.status isEqualToString:@"waiting_to_retry"]) {
            double seconds = ([[s.fail_info objectForKey:@"timestamp"] doubleValue] + [[s.fail_info objectForKey:@"retry_timeout"] intValue]) - [[NSDate date] timeIntervalSince1970];
            if(seconds > 0) {
                NSString *reason = [s.fail_info objectForKey:@"reason"];
                NSString *text = @"Disconnected";
                if([reason isKindOfClass:[NSString class]] && [reason length])
                    text = [text stringByAppendingFormat:@": %@, ", reason];
                else
                    text = [text stringByAppendingString:@"; "];
                text = [text stringByAppendingFormat:@"Reconnecting in %i seconds.", (int)seconds];
                _serverStatus.text = text;
                _serverStatusBar.backgroundColor = [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
                _serverStatus.textColor = [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
            } else {
                _serverStatus.text = @"Ready to connect.  Waiting our turn…";
            }
            [self performSelector:@selector(_updateServerStatus) withObject:nil afterDelay:0.5];
        } else if([s.status isEqualToString:@"ip_retry"]) {
            _serverStatus.text = @"Trying another IP address";
        } else {
            TFLog(@"Unhandled server status: %@", s.status);
        }
    } else {
        if(!_serverStatusBar.hidden) {
            CGRect frame = _eventsView.view.frame;
            frame.size.height += _serverStatusBar.frame.size.height;
            _eventsView.view.frame = frame;
            frame = _eventsView.bottomUnreadView.frame;
            frame.origin.y += _serverStatusBar.frame.size.height;
            _eventsView.bottomUnreadView.frame = frame;
            _serverStatusBar.hidden = YES;
        }
    }
}

-(void)_updateUserListVisibility {
    [[NSOperationQueue mainQueue]  addOperationWithBlock:^{
    if(self.slidingViewController) {
        if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid] && !([NetworkConnection sharedInstance].prefs && [[[[NetworkConnection sharedInstance].prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])) {
            self.navigationItem.rightBarButtonItem = _usersButtonItem;
            self.slidingViewController.underRightViewController = _usersView;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
            self.slidingViewController.underRightViewController = nil;
        }
    } else {
        if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid] && !([NetworkConnection sharedInstance].prefs && [[[[NetworkConnection sharedInstance].prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])) {
            CGRect frame = _eventsView.view.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
            _eventsView.view.frame = frame;
            frame = _toolBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
            _toolBar.frame = frame;
            frame = _serverStatusBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
            _serverStatusBar.frame = frame;
            _usersView.view.hidden = NO;
        } else {
            CGRect frame = _eventsView.view.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _eventsView.view.frame = frame;
            frame = _toolBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _toolBar.frame = frame;
            frame = _serverStatusBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _serverStatusBar.frame = frame;
            _usersView.view.hidden = YES;
        }
    }
    }];
}

-(void)usersButtonPressed:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)listButtonPressed:(id)sender {
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(IBAction)settingsButtonPressed:(id)sender {
    User *me = [[UsersDataSource sharedInstance] getUser:[[ServersDataSource sharedInstance] getServer:_buffer.cid].nick cid:_buffer.cid bid:_buffer.bid];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if([_buffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        NSLog(@"Status: %@", s.status);
        if([s.status isEqualToString:@"disconnected"]) {
            [sheet addButtonWithTitle:@"Reconnect"];
            [sheet addButtonWithTitle:@"Delete"];
        } else {
            //[sheet addButtonWithTitle:@"Identify Nickname…"];
            [sheet addButtonWithTitle:@"Disconnect"];
        }
        [sheet addButtonWithTitle:@"Edit Connection…"];
    } else if([_buffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
            [sheet addButtonWithTitle:@"Leave"];
            if([me.mode rangeOfString:@"q"].location != NSNotFound || [me.mode rangeOfString:@"a"].location != NSNotFound || [me.mode rangeOfString:@"o"].location != NSNotFound) {
                [sheet addButtonWithTitle:@"Ban List…"];
            }
        } else {
            [sheet addButtonWithTitle:@"Rejoin"];
            [sheet addButtonWithTitle:(_buffer.archived)?@"Unarchive":@"Archive"];
            [sheet addButtonWithTitle:@"Delete"];
        }
    } else {
        if(_buffer.archived) {
            [sheet addButtonWithTitle:@"Unarchive"];
            [sheet addButtonWithTitle:@"Delete"];
        } else {
            [sheet addButtonWithTitle:@"Archive"];
        }
    }
    [sheet addButtonWithTitle:@"Ignore List…"];
    //[sheet addButtonWithTitle:@"Display Options…"];
    //[sheet addButtonWithTitle:@"Settings…"];
    [sheet addButtonWithTitle:@"Logout"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    if(self.slidingViewController)
        [sheet showInView:self.slidingViewController.view.superview];
    else
        [sheet showInView:self.view.superview];
}

-(void)dismissKeyboard {
    [_message resignFirstResponder];
}

-(void)_eventTapped {
    _doubleTapTimer = nil;
    [_message resignFirstResponder];
}

-(void)rowSelected:(Event *)event {
    if(_doubleTapTimer) {
        [_doubleTapTimer invalidate];
        _doubleTapTimer = nil;
        _selectedUser = [[UsersDataSource sharedInstance] getUser:event.from cid:event.cid bid:event.bid];
        if(!_selectedUser) {
            _selectedUser = [[User alloc] init];
            _selectedUser.nick = event.from;
        }
        [self _mention];
    } else {
        _doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_eventTapped) userInfo:nil repeats:NO];
    }
}

-(void)_mention {
    if(!_selectedUser)
        return;

    //TODO: set the mention tip flag
    
    if(self.slidingViewController) {
        [self.slidingViewController resetTopView];
    }
    
    if(_message.text.length == 0) {
        _message.text = [NSString stringWithFormat:@"%@: ",_selectedUser.nick];
    } else {
        NSString *from = _selectedUser.nick;
        int oldPosition = _message.selectedRange.location;
        NSString *text = _message.text;
        int start = oldPosition - 1;
        if(start > 0 && [text characterAtIndex:start] == ' ')
            start--;
        while(start > 0 && [text characterAtIndex:start] != ' ')
            start--;
        if(start < 0)
            start = 0;
        int match = [text rangeOfString:from options:0 range:NSMakeRange(start, text.length - start)].location;
        int end = oldPosition + from.length;
        if(end > text.length - 1)
            end = text.length - 1;
        if(match >= 0 && match < end) {
            NSMutableString *newtext = [[NSMutableString alloc] init];
            if(match > 1 && [text characterAtIndex:match - 1] == ' ')
                [newtext appendString:[text substringWithRange:NSMakeRange(0, match - 1)]];
            else
                [newtext appendString:[text substringWithRange:NSMakeRange(0, match)]];
            if(match+from.length < text.length && [text characterAtIndex:match+from.length] == ':' &&
               match+from.length+1 < text.length && [text characterAtIndex:match+from.length+1] == ' ') {
                if(match+from.length+2 < text.length)
                    [newtext appendString:[text substringWithRange:NSMakeRange(match+from.length+2, text.length - (match+from.length+2))]];
            } else if(match+from.length < text.length) {
                [newtext appendString:[text substringWithRange:NSMakeRange(match+from.length, text.length - (match+from.length))]];
            }
            if([newtext hasSuffix:@" "])
                newtext = (NSMutableString *)[newtext substringWithRange:NSMakeRange(0, newtext.length - 1)];
            if([newtext isEqualToString:@":"])
                newtext = (NSMutableString *)@"";
            _message.text = newtext;
            if(match < newtext.length)
                _message.selectedRange = NSMakeRange(match, 0);
            else
                _message.selectedRange = NSMakeRange(newtext.length, 0);
        } else {
            if(oldPosition == text.length - 1) {
                text = [NSString stringWithFormat:@" %@", from];
            } else {
                NSMutableString *newtext = [[NSMutableString alloc] initWithString:[text substringWithRange:NSMakeRange(0, oldPosition)]];
                if(![newtext hasSuffix:@" "])
                    from = [NSString stringWithFormat:@" %@", from];
                if(![[text substringWithRange:NSMakeRange(oldPosition, text.length - oldPosition)] hasPrefix:@" "])
                    from = [NSString stringWithFormat:@"%@ ", from];
                [newtext appendString:from];
                [newtext appendString:[text substringWithRange:NSMakeRange(oldPosition, text.length - oldPosition)]];
                if([newtext hasSuffix:@" "])
                    newtext = (NSMutableString *)[newtext substringWithRange:NSMakeRange(0, newtext.length - 1)];
                text = newtext;
            }
            _message.text = text;
            if(text.length > 0) {
                if(oldPosition + from.length + 2 < text.length)
                    _message.selectedRange = NSMakeRange(oldPosition + from.length, 0);
                else
                    _message.selectedRange = NSMakeRange(text.length, 0);
            }
        }
    }
    [_message becomeFirstResponder];
}

-(void)_showUserPopupInRect:(CGRect)rect {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"%@\n(%@)",_selectedUser.nick,_selectedUser.hostmask] delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if(_selectedEvent)
        [sheet addButtonWithTitle:@"Copy Message"];
    //[sheet addButtonWithTitle:@"Whois…"];
    [sheet addButtonWithTitle:@"Send a message"];
    [sheet addButtonWithTitle:@"Mention"];
    [sheet addButtonWithTitle:@"Invite to channel…"];
    [sheet addButtonWithTitle:@"Ignore…"];
    if([_buffer.type isEqualToString:@"channel"]) {
        User *me = [[UsersDataSource sharedInstance] getUser:[[ServersDataSource sharedInstance] getServer:_buffer.cid].nick cid:_buffer.cid bid:_buffer.bid];
        if([me.mode rangeOfString:@"q"].location != NSNotFound || [me.mode rangeOfString:@"a"].location != NSNotFound || [me.mode rangeOfString:@"o"].location != NSNotFound) {
            if([_selectedUser.mode rangeOfString:@"o"].location != NSNotFound)
                [sheet addButtonWithTitle:@"Deop"];
            else
                [sheet addButtonWithTitle:@"Op"];
        }
        if([me.mode rangeOfString:@"q"].location != NSNotFound || [me.mode rangeOfString:@"a"].location != NSNotFound || [me.mode rangeOfString:@"o"].location != NSNotFound || [me.mode rangeOfString:@"h"].location != NSNotFound) {
            [sheet addButtonWithTitle:@"Kick…"];
            [sheet addButtonWithTitle:@"Ban…"];
        }
    }
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [sheet showInView:self.slidingViewController.view.superview];
    } else {
        if(_selectedEvent)
            [sheet showFromRect:rect inView:_eventsView.tableView animated:NO];
        else
            [sheet showFromRect:rect inView:_usersView.tableView animated:NO];
    }
}

-(void)_userTapped {
    _doubleTapTimer = nil;
    [self _showUserPopupInRect:_selectedRect];
}

-(void)userSelected:(NSString *)nick rect:(CGRect)rect {
    _selectedRect = rect;
    _selectedEvent = nil;
    _selectedUser = [[UsersDataSource sharedInstance] getUser:nick cid:_buffer.cid];
    if(_doubleTapTimer) {
        [_doubleTapTimer invalidate];
        _doubleTapTimer = nil;
        [self _mention];
    } else {
        _doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_userTapped) userInfo:nil repeats:NO];
    }
}

-(void)rowLongPressed:(Event *)event rect:(CGRect)rect {
    if(event.from) {
        _selectedEvent = event;
        _selectedUser = [[UsersDataSource sharedInstance] getUser:event.from cid:_buffer.cid];
        if(!_selectedUser) {
            _selectedUser = [[User alloc] init];
            _selectedUser.cid = _selectedEvent.cid;
            _selectedUser.bid = _selectedEvent.bid;
            _selectedUser.nick = _selectedEvent.from;
            _selectedUser.hostmask = _selectedEvent.hostmask;
        }
        [self _showUserPopupInRect:rect];
    }
}

-(IBAction)titleAreaPressed:(id)sender {
    if([_buffer.type isEqualToString:@"channel"]) {
        ChannelInfoViewController *c = [[ChannelInfoViewController alloc] initWithBid:_buffer.bid];
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self.navigationController pushViewController:c animated:YES];
        } else {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        }
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    switch(alertView.tag) {
        case TAG_BAN:
            if([title isEqualToString:@"Ban"]) {
                if([alertView textFieldAtIndex:0].text.length)
                    [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+b %@", [alertView textFieldAtIndex:0].text] chan:_buffer.name cid:_buffer.cid];
            }
            break;
        case TAG_IGNORE:
            if([title isEqualToString:@"Ignore"]) {
                if([alertView textFieldAtIndex:0].text.length)
                    [[NetworkConnection sharedInstance] ignore:[alertView textFieldAtIndex:0].text cid:_buffer.cid];
            }
            break;
        case TAG_KICK:
            if([title isEqualToString:@"Kick"]) {
               [[NetworkConnection sharedInstance] kick:_selectedUser.nick chan:_buffer.name msg:[alertView textFieldAtIndex:0].text cid:_buffer.cid];
            }
            break;
        case TAG_INVITE:
            if([title isEqualToString:@"Invite"]) {
                if([alertView textFieldAtIndex:0].text.length)
                    [[NetworkConnection sharedInstance] invite:_selectedUser.nick chan:[alertView textFieldAtIndex:0].text cid:_buffer.cid];
            }
            break;
        case TAG_BADCHANNELKEY:
            if([title isEqualToString:@"Join"]) {
                if([alertView textFieldAtIndex:0].text.length)
                    [[NetworkConnection sharedInstance] join:[_alertObject objectForKey:@"chan"] key:[alertView textFieldAtIndex:0].text cid:_alertObject.cid];
            }
            break;
        case TAG_INVALIDNICK:
            if([title isEqualToString:@"Change"]) {
                if([alertView textFieldAtIndex:0].text.length)
                    [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/nick %@",[alertView textFieldAtIndex:0].text] to:nil cid:_alertObject.cid];
            }
            break;
    }
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && alertView.tag != TAG_KICK && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [_message resignFirstResponder];
    if(buttonIndex != -1) {
        NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if([action isEqualToString:@"Copy Message"]) {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            NSString *plaintext = [NSString stringWithFormat:@"<%@> %@",_selectedEvent.from,[[ColorFormatter format:_selectedEvent.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO] string]];
            [pb setValue:plaintext forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
        } else if([action isEqualToString:@"Send a message"]) {
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:_selectedUser.nick server:_buffer.cid];
            if(b) {
                [self bufferSelected:b.bid];
            } else {
                b = [[Buffer alloc] init];
                b.cid = _buffer.cid;
                b.bid = -1;
                b.name = _selectedUser.nick;
                b.type = @"conversation";
                _buffer = b;
                self.navigationItem.title = _selectedUser.nick;
                [_buffersView setBuffer:b];
                [_usersView setBuffer:b];
                [_eventsView setBuffer:b];
                [self _updateUserListVisibility];
            }
        } else if([action isEqualToString:@"Op"]) {
            [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+o %@",_selectedUser.nick] chan:_buffer.name cid:_buffer.cid];
        } else if([action isEqualToString:@"Deop"]) {
            [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-o %@",_selectedUser.nick] chan:_buffer.name cid:_buffer.cid];
        } else if([action isEqualToString:@"Ban…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Add a ban mask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ban", nil];
            alert.tag = TAG_BAN;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"*!%@", _selectedUser.hostmask];
            [alert show];
        } else if([action isEqualToString:@"Ignore…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ignore messages from this mask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ignore", nil];
            alert.tag = TAG_IGNORE;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert textFieldAtIndex:0].text = [NSString stringWithFormat:@"*!%@", _selectedUser.hostmask];
            [alert show];
        } else if([action isEqualToString:@"Kick…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Give a reason for kicking" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Kick", nil];
            alert.tag = TAG_KICK;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        } else if([action isEqualToString:@"Invite to channel…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Invite to channel" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Invite", nil];
            alert.tag = TAG_INVITE;
            alert.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alert show];
        } else if([action isEqualToString:@"Archive"]) {
            [[NetworkConnection sharedInstance] archiveBuffer:_buffer.bid cid:_buffer.cid];
        } else if([action isEqualToString:@"Unarchive"]) {
            [[NetworkConnection sharedInstance] unarchiveBuffer:_buffer.bid cid:_buffer.cid];
        } else if([action isEqualToString:@"Delete"]) {
            //TODO: prompt for confirmation
            if([_buffer.type isEqualToString:@"console"]) {
                [[NetworkConnection sharedInstance] deleteServer:_buffer.cid];
            } else {
                [[NetworkConnection sharedInstance] deleteBuffer:_buffer.bid cid:_buffer.cid];
            }
        } else if([action isEqualToString:@"Leave"]) {
            [[NetworkConnection sharedInstance] part:_buffer.name msg:nil cid:_buffer.cid];
        } else if([action isEqualToString:@"Rejoin"]) {
            [[NetworkConnection sharedInstance] join:_buffer.name key:nil cid:_buffer.cid];
        } else if([action isEqualToString:@"Ban List…"]) {
            [[NetworkConnection sharedInstance] mode:@"b" chan:_buffer.name cid:_buffer.cid];
        } else if([action isEqualToString:@"Disconnect"]) {
            [[NetworkConnection sharedInstance] disconnect:_buffer.cid msg:nil];
        } else if([action isEqualToString:@"Reconnect"]) {
            [[NetworkConnection sharedInstance] reconnect:_buffer.cid];
        } else if([action isEqualToString:@"Logout"]) {
            [[NetworkConnection sharedInstance] unregisterAPNs:[[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"]];
            //TODO: check the above result, and retry if it fails
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"APNs"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"session"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NetworkConnection sharedInstance] disconnect];
            [[NetworkConnection sharedInstance] clearPrefs];
            [[ServersDataSource sharedInstance] clear];
            [[UsersDataSource sharedInstance] clear];
            [[ChannelsDataSource sharedInstance] clear];
            [[EventsDataSource sharedInstance] clear];
            [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
        } else if([action isEqualToString:@"Ignore List…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            IgnoresTableViewController *itv = [[IgnoresTableViewController alloc] initWithStyle:UITableViewStylePlain];
            itv.ignores = s.ignores;
            itv.cid = s.cid;
            itv.navigationItem.title = @"Ignore List";
            if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:itv animated:YES];
            } else {
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:itv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
        } else if([action isEqualToString:@"Mention"]) {
            //TODO: Show the double-tap tip
            [self _mention];
        } else if([action isEqualToString:@"Edit Connection…"]) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [ecv setServer:_buffer.cid];
            if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                [self.navigationController pushViewController:ecv animated:YES];
            } else {
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
        }
    }
    _selectedUser = nil;
    _selectedEvent = nil;
}
@end
