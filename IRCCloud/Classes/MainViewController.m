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
#import "ChannelListTableViewController.h"
#import "SettingsViewController.h"
#import "CallerIDTableViewController.h"
#import "WhoisViewController.h"
#import "DisplayOptionsViewController.h"
#import "WhoListTableViewController.h"
#import "NamesListTableViewController.h"

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

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentMode = UIViewContentModeScaleToFill;
    button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [button setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    button.frame = CGRectMake(12,12,button.frame.size.width, button.frame.size.height);
    [_bottomBar addSubview:button];

    _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendBtn.contentMode = UIViewContentModeScaleToFill;
    _sendBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor selectedBlueColor] forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [_sendBtn setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _sendBtn.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [_sendBtn.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
    [_sendBtn setBackgroundImage:[UIImage imageNamed:@"sendbg_active"] forState:UIControlStateNormal];
    [_sendBtn setBackgroundImage:[UIImage imageNamed:@"sendbg"] forState:UIControlStateDisabled];
    [_sendBtn addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_sendBtn sizeToFit];
    _sendBtn.enabled = NO;
    _sendBtn.adjustsImageWhenHighlighted = NO;
    _sendBtn.frame = CGRectMake(_bottomBar.frame.size.width - _sendBtn.frame.size.width - 8,8,_sendBtn.frame.size.width,_sendBtn.frame.size.height);
    [_bottomBar addSubview:_sendBtn];
    
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
        self.navigationController.view.layer.shadowRadius = 2.0f;
        self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;

        _menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_menuBtn setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
        [_menuBtn addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        _menuBtn.frame = CGRectMake(0,0,32,32);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_menuBtn];
    }
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _startHeight = [UIScreen mainScreen].applicationFrame.size.height;
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(46,8,208,36)];
        _message.maximumNumberOfLines = 8;
    } else {
        _startHeight = [UIScreen mainScreen].applicationFrame.size.width - self.navigationController.navigationBar.frame.size.height;
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(46,8,472,36)];
    }
    _message.minimumHeight = 36;
    [_message sizeToFit];
    _message.delegate = self;
    _message.returnKeyType = UIReturnKeySend;
    [_bottomBar addSubview:_message];
    UIButton *users = [UIButton buttonWithType:UIButtonTypeCustom];
    [users setImage:[UIImage imageNamed:@"users"] forState:UIControlStateNormal];
    [users addTarget:self action:@selector(usersButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    users.frame = CGRectMake(0,0,40,40);
    _usersButtonItem = [[UIBarButtonItem alloc] initWithCustomView:users];
}

- (void)_updateUnreadIndicator {
    @synchronized(_buffer) {
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
            [_menuBtn setImage:[UIImage imageNamed:@"menu_highlight"] forState:UIControlStateNormal];
        else if(unreadCount)
            [_menuBtn setImage:[UIImage imageNamed:@"menu_unread"] forState:UIControlStateNormal];
        else
            [_menuBtn setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
    }
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Buffer *b = nil;
    IRCCloudJSONObject *o = nil;
    BansTableViewController *btv = nil;
    ChannelListTableViewController *ctv = nil;
    CallerIDTableViewController *citv = nil;
    WhoListTableViewController *wtv = nil;
    NamesListTableViewController *ntv = nil;
    Event *e = nil;
    Server *s = nil;
    UIAlertView *alert = nil;
    NSString *msg = nil;
    NSString *type = nil;
    switch(event) {
        case kIRCEventWhois:
        {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[[WhoisViewController alloc] initWithJSONObject:notification.object]];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        }
            break;
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
                btv.navigationItem.title = [NSString stringWithFormat:@"Bans for %@", [o objectForKey:@"channel"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:btv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventListResponseFetching:
            o = notification.object;
            if(o.cid == _buffer.cid) {
                ctv = [[ChannelListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                ctv.event = o;
                ctv.navigationItem.title = @"Channel List";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventAcceptList:
            o = notification.object;
            if(o.cid == _buffer.cid) {
                citv = [[CallerIDTableViewController alloc] initWithStyle:UITableViewStylePlain];
                citv.event = o;
                citv.nicks = [o objectForKey:@"nicks"];
                citv.navigationItem.title = @"Accept List";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:citv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventWhoList:
            o = notification.object;
            if(o.cid == _buffer.cid) {
                wtv = [[WhoListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                wtv.event = o;
                wtv.navigationItem.title = [NSString stringWithFormat:@"WHO For %@", [o objectForKey:@"subject"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:wtv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventNamesList:
            o = notification.object;
            if(o.cid == _buffer.cid) {
                ntv = [[NamesListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                ntv.event = o;
                ntv.navigationItem.title = [NSString stringWithFormat:@"NAMES For %@", [o objectForKey:@"chan"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ntv];
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:nc animated:YES completion:nil];
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
            } else {
                if([[o objectForKey:@"message"] isEqualToString:@"auth"]) {
                    [[NetworkConnection sharedInstance] unregisterAPNs:[[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"]];
                    //TODO: check the above result, and retry if it fails
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"APNs"];
                    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"session"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[NetworkConnection sharedInstance] disconnect];
                    [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(cancelIdleTimer) withObject:nil waitUntilDone:YES];
                    [NetworkConnection sharedInstance].reconnectTimestamp = 0;
                    [[NetworkConnection sharedInstance] clearPrefs];
                    [[ServersDataSource sharedInstance] clear];
                    [[UsersDataSource sharedInstance] clear];
                    [[ChannelsDataSource sharedInstance] clear];
                    [[EventsDataSource sharedInstance] clear];
                    _buffer = nil;
                    [_eventsView setBuffer:nil];
                    [_buffersView setBuffer:nil];
                    [_usersView setBuffer:nil];
                    [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
                } else if([[o objectForKey:@"message"] isEqualToString:@"set_shard"]) {
                    [[NSUserDefaults standardUserDefaults] setObject:[o objectForKey:@"cookie"] forKey:@"session"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[NetworkConnection sharedInstance] connect];
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
        case kIRCEventDeleteBuffer:
            o = notification.object;
            if(o.bid == _buffer.bid)
                [self bufferSelected:[[BuffersDataSource sharedInstance] firstBid]];
            break;
        case kIRCEventConnectionDeleted:
            o = notification.object;
            if(o.cid == _buffer.cid)
                [self bufferSelected:[[BuffersDataSource sharedInstance] firstBid]];
            break;
        default:
            break;
    }
    if(self.slidingViewController)
        [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
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
        case kIRCCloudStateDisconnecting:
            [self _showConnectingView];
            if([NetworkConnection sharedInstance].reconnectTimestamp > 0) {
                [_connectingStatus setText:[NSString stringWithFormat:@"Reconnecting in %0.f seconds", [NetworkConnection sharedInstance].reconnectTimestamp - [[NSDate date] timeIntervalSince1970]]];
                _connectingActivity.hidden = NO;
                [_connectingActivity startAnimating];
                _connectingProgress.progress = 0;
                _connectingProgress.hidden = YES;
                [self performSelector:@selector(connectivityChanged:) withObject:nil afterDelay:1];
            } else {
                if([[NetworkConnection sharedInstance] reachable])
                    _connectingStatus.text = @"Disconnected";
                else
                    _connectingStatus.text = @"Offline";
                _connectingActivity.hidden = YES;
                _connectingProgress.progress = 0;
                _connectingProgress.hidden = YES;
            }
            break;
        case kIRCCloudStateConnected:
            [_connectingActivity stopAnimating];
            for(Event *e in [_pendingEvents copy]) {
                if(e.reqId == -1 && (([[NSDate date] timeIntervalSince1970] - (e.eid/1000000)) < 60)) {
                    e.reqId = [[NetworkConnection sharedInstance] say:e.command to:e.to cid:e.cid];
                } else {
                    [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                    [_pendingEvents removeObject:e];
                }
            }
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
    if(_buffer && !_urlToOpen && _bidToOpen == -1) {
        [self _updateServerStatus];
        [self _updateUserListVisibility];
        if(self.slidingViewController) {
            [self _updateUnreadIndicator];
        }
    } else {
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
        if(_urlToOpen)
            [self launchURL:_urlToOpen];
        _urlToOpen = nil;
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
    if(!_buffer) {
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
        if(_urlToOpen) {
            [self launchURL:_urlToOpen];
            _urlToOpen = nil;
        }
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.clipsToBounds = YES;
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
    self.navigationItem.titleView = _titleView;
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
    if([NetworkConnection sharedInstance].state != kIRCCloudStateConnected && [[NetworkConnection sharedInstance] reachable] == kIRCCloudReachable && session != nil && [session length] > 0)
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
    if(_message.text && _message.text.length) {
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
                [_eventsView insertEvent:e backlog:NO nextIsGrouped:NO];
            }
            e.to = _buffer.name;
            e.command = _message.text;
            e.reqId = [[NetworkConnection sharedInstance] say:_message.text to:_buffer.name cid:_buffer.cid];
            if(e.msg)
                [_pendingEvents addObject:e];
            [_message clearText];
            [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:e repeats:NO];
        }
    }
}

-(void)_sendRequestDidExpire:(NSTimer *)timer {
    Event *e = timer.userInfo;
    if([_pendingEvents containsObject:e]) {
        [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
        [_pendingEvents removeObject:e];
        e.msg = [e.msg stringByAppendingFormat:@" %c4(FAILED)%c", COLOR_MIRC, CLEAR];
        e.formattedMsg = nil;
        e.formatted = nil;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:e userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:kIRCEventBufferMsg]}];
        }];
    }
}

-(void)expandingTextViewDidChange:(UIExpandingTextView *)expandingTextView {
    _sendBtn.enabled = expandingTextView.text.length > 0;
}

-(BOOL)expandingTextViewShouldReturn:(UIExpandingTextView *)expandingTextView {
    [self sendButtonPressed:expandingTextView];
    return NO;
}

-(void)expandingTextView:(UIExpandingTextView *)expandingTextView willChangeHeight:(float)height {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGRect frame = _eventsView.tableView.frame;
    frame.size.height = self.view.frame.size.height - height - 8;
    if(!_serverStatusBar.hidden)
        frame.size.height -= _serverStatusBar.frame.size.height;
    _eventsView.tableView.frame = frame;
    frame = _serverStatusBar.frame;
    frame.origin.y = self.view.frame.size.height - height - 8 - frame.size.height;
    _serverStatusBar.frame = frame;
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    _bottomBar.frame = CGRectMake(_bottomBar.frame.origin.x, self.view.frame.size.height - height - 8, _bottomBar.frame.size.width, height + 8);
}

-(void)setUnreadColor:(UIColor *)color {
    self.navigationItem.leftBarButtonItem.tintColor = color;
}

-(void)_updateTitleArea {
    _lock.hidden = YES;
    if([_buffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        if(s.name.length)
            _titleLabel.text = s.name;
        else
            _titleLabel.text = s.hostname;
        self.navigationItem.title = _titleLabel.text;
        _topicLabel.hidden = NO;
        _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
        _topicLabel.text = [NSString stringWithFormat:@"%@:%i", s.hostname, s.port];
    } else {
        self.navigationItem.title = _buffer.name = _titleLabel.text = _buffer.name;
        _titleLabel.frame = CGRectMake(0,0,_titleView.frame.size.width,_titleView.frame.size.height);
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _topicLabel.hidden = YES;
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
                    _topicLabel.text = [[ColorFormatter format:channel.topic_text defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
                } else {
                    _topicLabel.hidden = YES;
                }
            }
            if(lock) {
                _lock.frame = CGRectMake((_titleView.frame.size.width - [_titleLabel.text sizeWithFont:_titleLabel.font].width)/2 - 16,4,16,16);
                _lock.hidden = NO;
            } else {
                _lock.hidden = YES;
            }
        } else if([_buffer.type isEqualToString:@"conversation"]) {
            self.navigationItem.title = _titleLabel.text = _buffer.name;
            _topicLabel.hidden = NO;
            _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
            _titleLabel.font = [UIFont boldSystemFontOfSize:18];
            _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            if(s.name.length)
                _topicLabel.text = s.name;
            else
                _topicLabel.text = s.hostname;
        }
    }
}

-(void)launchURL:(NSURL *)url {
    int port = [url.port intValue];
    int ssl = [url.scheme hasSuffix:@"s"]?1:0;
    BOOL match = NO;
    kIRCCloudState state = [NetworkConnection sharedInstance].state;
    for(Server *s in [[ServersDataSource sharedInstance] getServers]) {
        if([[s.hostname lowercaseString] isEqualToString:[url.host lowercaseString]])
            match = YES;
        if(port > 0 && port != 6667 && port != s.port)
            match = NO;
        if(ssl == 1 && !s.ssl)
            match = NO;
        if(match) {
            NSString *channel = [url.path substringFromIndex:1];
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:channel server:s.cid];
            if(b)
                [self bufferSelected:b.bid];
            else if(state == kIRCCloudStateConnected)
                [[NetworkConnection sharedInstance] join:channel key:nil cid:s.cid];
            else
                match = NO;
            break;
        }
    }

    if(!match) {
        if(state == kIRCCloudStateConnected) {
            EditConnectionViewController *evc = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [evc setURL:url];
            [self.navigationController presentModalViewController:[[UINavigationController alloc] initWithRootViewController:evc] animated:YES];
        } else {
            _urlToOpen = url;
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
            if(self.slidingViewController.underRightViewController == nil)
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
            frame = _bottomBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
            _bottomBar.frame = frame;
            frame = _serverStatusBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
            _serverStatusBar.frame = frame;
            _usersViewBorder.hidden = _usersView.view.hidden = NO;
        } else {
            CGRect frame = _eventsView.view.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _eventsView.view.frame = frame;
            frame = _bottomBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _bottomBar.frame = frame;
            frame = _serverStatusBar.frame;
            frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
            _serverStatusBar.frame = frame;
            _usersViewBorder.hidden = _usersView.view.hidden = YES;
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
    [sheet addButtonWithTitle:@"Display Options…"];
    [sheet addButtonWithTitle:@"Settings…"];
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
    NSString *title;
    if([_selectedUser.hostmask isKindOfClass:[NSString class]] &&_selectedUser.hostmask.length)
        title = [NSString stringWithFormat:@"%@\n(%@)",_selectedUser.nick,_selectedUser.hostmask];
    else
        title = _selectedUser.nick;
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if(_selectedEvent)
        [sheet addButtonWithTitle:@"Copy Message"];
    [sheet addButtonWithTitle:@"Whois…"];
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
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nc animated:YES completion:nil];
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
            NSString *plaintext = [NSString stringWithFormat:@"<%@> %@",_selectedEvent.from,[[ColorFormatter format:_selectedEvent.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]];
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
        } else if([action isEqualToString:@"Whois…"]) {
            [[NetworkConnection sharedInstance] whois:_selectedUser.nick server:nil cid:_buffer.cid];
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
            [[NetworkConnection sharedInstance] cancelIdleTimer];
            [[NetworkConnection sharedInstance] clearPrefs];
            [[ServersDataSource sharedInstance] clear];
            [[UsersDataSource sharedInstance] clear];
            [[ChannelsDataSource sharedInstance] clear];
            [[EventsDataSource sharedInstance] clear];
            _buffer = nil;
            [_eventsView setBuffer:nil];
            [_buffersView setBuffer:nil];
            [_usersView setBuffer:nil];
            [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
        } else if([action isEqualToString:@"Ignore List…"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            IgnoresTableViewController *itv = [[IgnoresTableViewController alloc] initWithStyle:UITableViewStylePlain];
            itv.ignores = s.ignores;
            itv.cid = s.cid;
            itv.navigationItem.title = @"Ignore List";
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:itv];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Mention"]) {
            //TODO: Show the double-tap tip
            [self _mention];
        } else if([action isEqualToString:@"Edit Connection…"]) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [ecv setServer:_buffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Settings…"]) {
            SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Display Options…"]) {
            DisplayOptionsViewController *dvc = [[DisplayOptionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            dvc.buffer = _buffer;
            dvc.navigationItem.title = _titleLabel.text;
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:dvc];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        }
    }
    _selectedUser = nil;
    _selectedEvent = nil;
}
@end
