//
//  MainViewController.m
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
#import "ImgurLoginViewController.h"
#import <objc/message.h>
#import "config.h"

#define TAG_BAN 1
#define TAG_IGNORE 2
#define TAG_KICK 3
#define TAG_INVITE 4
#define TAG_BADCHANNELKEY 5
#define TAG_INVALIDNICK 6
#define TAG_FAILEDMSG 7

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
    [self addChildViewController:_eventsView];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"a" ofType:@"caf"]], &alertSound);
    
    if(!_buffersView)
        _buffersView = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
    
    if(!_usersView)
        _usersView = [[UsersTableView alloc] initWithStyle:UITableViewStylePlain];
    
    if(_swipeTip)
        _swipeTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tip_bg"]];
    
    if(_mentionTip)
        _mentionTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tip_bg"]];
    
    self.navigationItem.titleView = _titleView;

    _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cameraBtn.contentMode = UIViewContentModeCenter;
    _cameraBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_cameraBtn setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_cameraBtn addTarget:self action:@selector(cameraButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraBtn sizeToFit];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 6)
        _cameraBtn.frame = CGRectMake(5,5,_cameraBtn.frame.size.width + 16, _cameraBtn.frame.size.height + 16);
    else if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 6)
        _cameraBtn.frame = CGRectMake(5,3,_cameraBtn.frame.size.width + 16, _cameraBtn.frame.size.height + 16);
    else
        _cameraBtn.frame = CGRectMake(5,2,_cameraBtn.frame.size.width + 16, _cameraBtn.frame.size.height + 16);
    _cameraBtn.accessibilityLabel = @"Insert a Photo";
    [_bottomBar addSubview:_cameraBtn];

    _sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sendBtn.contentMode = UIViewContentModeCenter;
    _sendBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor selectedBlueColor] forState:UIControlStateNormal];
    [_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [_sendBtn sizeToFit];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
        _sendBtn.frame = CGRectMake(_bottomBar.frame.size.width - _sendBtn.frame.size.width - 8,12,_sendBtn.frame.size.width,_sendBtn.frame.size.height);
    else
        _sendBtn.frame = CGRectMake(_bottomBar.frame.size.width - _sendBtn.frame.size.width - 8,4,_sendBtn.frame.size.width,_sendBtn.frame.size.height);
    [_sendBtn addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_sendBtn sizeToFit];
    _sendBtn.enabled = NO;
    _sendBtn.adjustsImageWhenHighlighted = NO;
    [_bottomBar addSubview:_sendBtn];

    _settingsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _settingsBtn.contentMode = UIViewContentModeCenter;
    _settingsBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [_settingsBtn setImage:[UIImage imageNamed:@"settings"] forState:UIControlStateNormal];
    [_settingsBtn addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_settingsBtn sizeToFit];
    _settingsBtn.accessibilityLabel = @"Menu";
    _settingsBtn.enabled = NO;
    _settingsBtn.alpha = 0;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 6)
        _settingsBtn.frame = CGRectMake(_bottomBar.frame.size.width - _settingsBtn.frame.size.width - 20,4,_settingsBtn.frame.size.width + 16,_settingsBtn.frame.size.height + 16);
    else
        _settingsBtn.frame = CGRectMake(_bottomBar.frame.size.width - _settingsBtn.frame.size.width - 20,2,_settingsBtn.frame.size.width + 16,_settingsBtn.frame.size.height + 16);
    [_bottomBar addSubview:_settingsBtn];
    
    self.slidingViewController.view.frame = [UIScreen mainScreen].applicationFrame;
    self.slidingViewController.shouldAllowPanningPastAnchor = NO;
    if(self.slidingViewController.underLeftViewController == nil)
        self.slidingViewController.underLeftViewController = _buffersView;
    if(self.slidingViewController.underRightViewController == nil)
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
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
        _menuBtn.frame = CGRectMake(0,0,32,32);
    else
        _menuBtn.frame = CGRectMake(0,0,20,18);
#else
    _menuBtn.frame = CGRectMake(0,0,32,32);
#endif
    _menuBtn.accessibilityLabel = @"Channels list";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_menuBtn];
    
    [_swipeTip removeFromSuperview];
    [self.slidingViewController.view addSubview:_swipeTip];

    [_mentionTip removeFromSuperview];
    [self.slidingViewController.view addSubview:_mentionTip];
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(44,8,0,36)];
        _landscapeView = [[UIView alloc] initWithFrame:CGRectZero];
    } else {
        _message = [[UIExpandingTextView alloc] initWithFrame:CGRectMake(44,8,0,36)];
    }
    _message.delegate = self;
    _message.returnKeyType = UIReturnKeySend;
    _message.autoresizesSubviews = NO;
    _nickCompletionView = [[NickCompletionView alloc] initWithFrame:CGRectZero];
    _nickCompletionView.completionDelegate = self;
    _nickCompletionView.alpha = 0;
    [self.view addSubview:_nickCompletionView];
    [_bottomBar addSubview:_message];
    UIButton *users = [UIButton buttonWithType:UIButtonTypeCustom];
    [users setImage:[UIImage imageNamed:@"users"] forState:UIControlStateNormal];
    [users addTarget:self action:@selector(usersButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
        users.frame = CGRectMake(0,0,40,40);
    else
        users.frame = CGRectMake(0,0,24,22);
#else
    users.frame = CGRectMake(0,0,40,40);
#endif
    users.accessibilityLabel = @"Channel members list";
    _usersButtonItem = [[UIBarButtonItem alloc] initWithCustomView:users];

#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar addSubview:_connectingProgress];
        [_connectingProgress sizeToFit];
        [_connectingActivity removeFromSuperview];
        _connectingStatus.font = [UIFont boldSystemFontOfSize:20];
    }
#endif
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    AudioServicesDisposeSystemSoundID(alertSound);
}

- (void)_updateUnreadIndicator {
    @synchronized(_buffer) {
        int unreadCount = 0;
        int highlightCount = 0;
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        
        NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffers];
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
                if(unreadCount == 0)
                    unread = [[EventsDataSource sharedInstance] unreadStateForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                highlights = [[EventsDataSource sharedInstance] highlightStateForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                if(type == 1) {
                    if([[prefs objectForKey:@"channel-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                } else {
                    if([[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                    if(type == 2 && [[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        highlights = 0;
                }
                if(buffer.bid != _buffer.bid) {
                    unreadCount += unread;
                    highlightCount += highlights;
                }
                if(highlightCount > 0)
                    break;
            }
        }
        
        if(highlightCount) {
            [_menuBtn setImage:[UIImage imageNamed:@"menu_highlight"] forState:UIControlStateNormal];
            _menuBtn.accessibilityValue = @"Unread highlights";
        } else if(unreadCount) {
            if(![_menuBtn.imageView.image isEqual:[UIImage imageNamed:@"menu_unread"]])
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"New unread messages");
            [_menuBtn setImage:[UIImage imageNamed:@"menu_unread"] forState:UIControlStateNormal];
            _menuBtn.accessibilityValue = @"Unread messages";
        } else {
            [_menuBtn setImage:[UIImage imageNamed:@"menu"] forState:UIControlStateNormal];
            _menuBtn.accessibilityValue = nil;
        }
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
    NSString *msg = nil;
    NSString *type = nil;
    switch(event) {
        case kIRCEventGlobalMsg:
            [self _updateGlobalMsg];
            break;
        case kIRCEventWhois:
        {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:[[WhoisViewController alloc] initWithJSONObject:notification.object]];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        }
            break;
        case kIRCEventChannelTopicIs:
            [self titleAreaPressed:nil];
            break;
        case kIRCEventChannelInit:
        case kIRCEventChannelTopic:
        case kIRCEventChannelMode:
            [self _updateTitleArea];
            [self _updateUserListVisibility];
            break;
        case kIRCEventBadChannelKey:
            _alertObject = notification.object;
            s = [[ServersDataSource sharedInstance] getServer:_alertObject.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:[NSString stringWithFormat:@"Password for %@",[_alertObject objectForKey:@"chan"]] delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
            _alertView.tag = TAG_BADCHANNELKEY;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
            break;
        case kIRCEventInvalidNick:
            _alertObject = notification.object;
            s = [[ServersDataSource sharedInstance] getServer:_alertObject.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Invalid nickname, try again." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Change", nil];
            _alertView.tag = TAG_INVALIDNICK;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
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
            else if([type isEqualToString:@"bad_channel_name"])
                msg = [NSString stringWithFormat:@"Bad channel name: %@", [o objectForKey:@"chan"]];
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
            else if([type isEqualToString:@"time"]) {
                msg = [o objectForKey:@"time_string"];
                if([[o objectForKey:@"time_stamp"] length]) {
                    msg = [msg stringByAppendingFormat:@" (%@)", [o objectForKey:@"time_stamp"]];
                }
                msg = [msg stringByAppendingFormat:@" — %@", [o objectForKey:@"time_server"]];
            }
            else
                msg = [o objectForKey:@"msg"];

            s = [[ServersDataSource sharedInstance] getServer:o.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [_alertView show];
            break;
        case kIRCEventStatusChanged:
            [self _updateUserListVisibility];
        case kIRCEventAway:
            [self _updateTitleArea];
        case kIRCEventSelfBack:
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
            if(_cidToOpen == o.cid && [[o objectForKey:@"invalid_chan"] isKindOfClass:[NSString class]] && [[[o objectForKey:@"invalid_chan"] lowercaseString] isEqualToString:[_bufferToOpen lowercaseString]]) {
                if([[o objectForKey:@"valid_chan"] isKindOfClass:[NSString class]] && [[o objectForKey:@"valid_chan"] length]) {
                    _bufferToOpen = [o objectForKey:@"valid_chan"];
                    b = [[BuffersDataSource sharedInstance] getBuffer:o.bid];
                }
            } else {
                _cidToOpen = o.cid;
                _bufferToOpen = nil;
            }
            if(!b)
                break;
        case kIRCEventMakeBuffer:
            if(!b)
                b = notification.object;
            if(_cidToOpen == b.cid && [[b.name lowercaseString] isEqualToString:[_bufferToOpen lowercaseString]] && ![[_buffer.name lowercaseString] isEqualToString:[_bufferToOpen lowercaseString]]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            } else if(_buffer.bid == -1 && b.cid == _buffer.cid && [b.name isEqualToString:_buffer.name]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            } else if([b.type isEqualToString:@"console"] || (_cidToOpen == b.cid && _bufferToOpen == nil)) {
                [self bufferSelected:b.bid];
            }
            break;
        case kIRCEventOpenBuffer:
            o = notification.object;
            _bufferToOpen = [o objectForKey:@"name"];
            _cidToOpen = o.cid;
            b = [[BuffersDataSource sharedInstance] getBufferWithName:_bufferToOpen server:_cidToOpen];
            if(b != nil && ![[b.name lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) {
                [self bufferSelected:b.bid];
                _bufferToOpen = nil;
                _cidToOpen = -1;
            }
            break;
        case kIRCEventUserInfo:
        case kIRCEventPart:
        case kIRCEventKick:
            [self _updateTitleArea];
            [self _updateUserListVisibility];
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            if([o objectForKey:@"_reqid"] && [[o objectForKey:@"_reqid"] intValue] > 0) {
                int reqid = [[o objectForKey:@"_reqid"] intValue];
                for(Event *e in _pendingEvents) {
                    if(e.reqId == reqid) {
                        [_pendingEvents removeObject:e];
                        e.height = 0;
                        e.pending = NO;
                        e.rowType = ROW_FAILED;
                        e.bgColor = [UIColor errorBackgroundColor];
                        [e.expirationTimer invalidate];
                        e.expirationTimer = nil;
                        [_eventsView.tableView reloadData];
                        break;
                    }
                }
            } else {
                if([[o objectForKey:@"message"] isEqualToString:@"auth"]) {
                    [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(logout) withObject:nil waitUntilDone:YES];
                    [self bufferSelected:-1];
                    [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
                } else if([[o objectForKey:@"message"] isEqualToString:@"set_shard"]) {
                    [NetworkConnection sharedInstance].session = [o objectForKey:@"cookie"];
                    [[NetworkConnection sharedInstance] connect];
                } else {
                    [[NetworkConnection sharedInstance] disconnect];
                    [[NetworkConnection sharedInstance] fail];
                    [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
                    [self connectivityChanged:nil];
                }
            }
            break;
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.bid == _buffer.bid) {
                if(e.isHighlight) {
                    [self showMentionTip];
                    User *u = [[UsersDataSource sharedInstance] getUser:e.from cid:e.cid bid:e.bid];
                    if(u && u.lastMention < e.eid) {
                        u.lastMention = e.eid;
                    }
                }
                if([[e.from lowercaseString] isEqualToString:[_buffer.name lowercaseString]]) {
                    for(Event *e in [_pendingEvents copy]) {
                        if(e.bid == _buffer.bid) {
                            if(e.expirationTimer && [e.expirationTimer isValid])
                                [e.expirationTimer invalidate];
                            e.expirationTimer = nil;
                            [_pendingEvents removeObject:e];
                            [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                        }
                    }
                } else {
                    int reqid = e.reqId;
                    for(Event *e in _pendingEvents) {
                        if(e.reqId == reqid) {
                            if(e.expirationTimer && [e.expirationTimer isValid])
                                [e.expirationTimer invalidate];
                            e.expirationTimer = nil;
                            [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                            [_pendingEvents removeObject:e];
                            break;
                        }
                    }
                }
                if(!e.isSelf && !_buffer.scrolledUp) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        if(e.from.length)
                            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"New message from %@: %@", e.from, [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]]);
                        else if([e.type isEqualToString:@"buffer_me_msg"])
                            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, [NSString stringWithFormat:@"New action: %@ %@", e.nick, [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]]);
                    }];
                }
            } else {
                Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:e.bid];
                if(b && [e isImportant:b.type]) {
                    Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
                    Ignore *ignore = [[Ignore alloc] init];
                    [ignore setIgnores:s.ignores];
                    if(e.ignoreMask && [ignore match:e.ignoreMask])
                        break;
                    if(e.isHighlight || [b.type isEqualToString:@"conversation"]) {
                        AudioServicesPlaySystemSound(alertSound);
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        [_menuBtn setImage:[UIImage imageNamed:@"menu_highlight"] forState:UIControlStateNormal];
                        _menuBtn.accessibilityValue = @"Unread highlights";
                    } else if(_menuBtn.accessibilityValue == nil) {
                        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
                        if([b.type isEqualToString:@"channel"]) {
                            if([[prefs objectForKey:@"channel-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                                break;
                        } else {
                            if([[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                                break;
                        }
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"New unread messages");
                        [_menuBtn setImage:[UIImage imageNamed:@"menu_unread"] forState:UIControlStateNormal];
                        _menuBtn.accessibilityValue = @"Unread messages";
                    }
                }
            }
            break;
        case kIRCEventHeartbeatEcho:
        {
            o = notification.object;
            BOOL important = NO;
            NSDictionary *seenEids = [o objectForKey:@"seenEids"];
            for(NSNumber *cid in seenEids.allKeys) {
                NSDictionary *eids = [seenEids objectForKey:cid];
                for(NSNumber *bid in eids.allKeys) {
                    if([bid intValue] != _buffer.bid) {
                        important = YES;
                        break;
                    }
                }
            }
            if(important) {
                [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
            }
            break;
        }
        case kIRCEventDeleteBuffer:
        case kIRCEventBufferArchived:
            o = notification.object;
            if(o.bid == _buffer.bid) {
                if(_buffer && _buffer.lastBuffer && [[BuffersDataSource sharedInstance] getBuffer:_buffer.lastBuffer.bid])
                    [self bufferSelected:_buffer.lastBuffer.bid];
                else
                    [self bufferSelected:[[BuffersDataSource sharedInstance] firstBid]];
            }
            [self _updateUnreadIndicator];
            break;
        case kIRCEventConnectionDeleted:
            o = notification.object;
            if(o.cid == _buffer.cid) {
                if(_buffer && _buffer.lastBuffer) {
                    [self bufferSelected:_buffer.lastBuffer.bid];
                } else if([[ServersDataSource sharedInstance] count]) {
                    [self bufferSelected:[[BuffersDataSource sharedInstance] firstBid]];
                } else {
                    [self bufferSelected:-1];
                    [(AppDelegate *)[UIApplication sharedApplication].delegate showConnectionView];
                }
            }
            [self _updateUnreadIndicator];
            break;
        default:
            break;
    }
}

-(void)_showConnectingView {
    self.navigationItem.titleView = _connectingView;
}

-(void)_hideConnectingView {
    self.navigationItem.titleView = _titleView;
    _connectingProgress.hidden = YES;
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
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Connecting");
            break;
        case kIRCCloudStateDisconnected:
            [self _showConnectingView];
            if([NetworkConnection sharedInstance].reconnectTimestamp > 0) {
                int seconds = (int)([NetworkConnection sharedInstance].reconnectTimestamp - [[NSDate date] timeIntervalSince1970]) + 1;
                [_connectingStatus setText:[NSString stringWithFormat:@"Reconnecting in %i second%@", seconds, (seconds == 1)?@"":@"s"]];
                _connectingActivity.hidden = NO;
                [_connectingActivity startAnimating];
                _connectingProgress.progress = 0;
                _connectingProgress.hidden = YES;
                [self performSelector:@selector(connectivityChanged:) withObject:nil afterDelay:1];
            } else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Disconnected");
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
                if(e.reqId == -1 && (([[NSDate date] timeIntervalSince1970] - (e.eid/1000000) - [NetworkConnection sharedInstance].clockOffset) < 60)) {
                    [e.expirationTimer invalidate];
                    e.expirationTimer = nil;
                    e.reqId = [[NetworkConnection sharedInstance] say:e.command to:e.to cid:e.cid];
                    if(e.reqId < 0)
                        e.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:e repeats:NO];
                } else {
                    [_pendingEvents removeObject:e];
                    e.height = 0;
                    e.pending = NO;
                    e.rowType = ROW_FAILED;
                    e.bgColor = [UIColor errorBackgroundColor];
                    [e.expirationTimer invalidate];
                    e.expirationTimer = nil;
                }
            }
            break;
    }
}

-(void)backlogStarted:(NSNotification *)notification {
    if(!_connectingView.hidden) {
        [_connectingStatus setText:@"Loading"];
        _connectingActivity.hidden = YES;
        [_connectingActivity stopAnimating];
        _connectingProgress.progress = 0;
        _connectingProgress.hidden = NO;
    }
}

-(void)backlogProgress:(NSNotification *)notification {
    [_connectingProgress setProgress:[notification.object floatValue] animated:YES];
}

-(void)backlogCompleted:(NSNotification *)notification {
    if([ServersDataSource sharedInstance].count < 1) {
        [(AppDelegate *)([UIApplication sharedApplication].delegate) showConnectionView];
        return;
    }
    [self _hideConnectingView];
    if(_buffer && !_urlToOpen && _bidToOpen == -1 && _eidToOpen < 1 && [[BuffersDataSource sharedInstance] getBuffer:_buffer.bid]) {
        [self _updateTitleArea];
        [self _updateServerStatus];
        [self _updateUserListVisibility];
        [self _updateUnreadIndicator];
        [self _updateGlobalMsg];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:_eventsView name:kIRCCloudBacklogCompletedNotification object:nil];
        int bid = [BuffersDataSource sharedInstance].firstBid;
        if(_buffer && _buffer.lastBuffer)
            bid = _buffer.lastBuffer.bid;
        if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"]) {
            if([[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]])
                bid = [[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue];
        }
        if(_bidToOpen != -1) {
            bid = _bidToOpen;
            _bidToOpen = -1;
        } else if(_eidToOpen > 0) {
            bid = _buffer.bid;
        }
        [self bufferSelected:bid];
        _eidToOpen = -1;
        if(_urlToOpen)
            [self launchURL:_urlToOpen];
        _urlToOpen = nil;
        [[NSNotificationCenter defaultCenter] addObserver:_eventsView selector:@selector(backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];
    }
}

-(void)keyboardWillShow:(NSNotification*)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGSize size = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil].size;
    if(size.height != _kbSize.height) {
        _kbSize = size;

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];

        [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
        
        if(((NSIndexPath *)[rows lastObject]).row < [_eventsView tableView:_eventsView.tableView numberOfRowsInSection:0])
            [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        else
            [_eventsView scrollToBottom];
        [_buffersView scrollViewDidScroll:_buffersView.tableView];
        [UIView commitAnimations];
        [self expandingTextViewDidChange:_message];
    }
    [self performSelector:@selector(_observeKeyboard) withObject:nil afterDelay:0.01];
}

-(void)_observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    _kbSize = CGSizeMake(0,0);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];

    [self.slidingViewController updateUnderLeftLayout];
    [self.slidingViewController updateUnderRightLayout];
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];

    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    [_buffersView scrollViewDidScroll:_buffersView.tableView];
    _nickCompletionView.alpha = 0;
    [UIView commitAnimations];
}

- (void)viewWillAppear:(BOOL)animated {
#ifdef __IPHONE_7_0
    if(!self.presentedViewController && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        ([UIApplication sharedApplication].delegate).window.backgroundColor = [UIColor whiteColor];
#endif
    if([ServersDataSource sharedInstance].count < 1) {
        [(AppDelegate *)([UIApplication sharedApplication].delegate) showConnectionView];
        return;
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    for(Event *e in [_pendingEvents copy]) {
        if(e.reqId != -1) {
            [_pendingEvents removeObject:e];
            [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
        }
    }
    if(!_buffer || ![[BuffersDataSource sharedInstance] getBuffer:_buffer.bid]) {
        int bid = [BuffersDataSource sharedInstance].firstBid;
        if(_buffer && _buffer.lastBuffer)
            bid = _buffer.lastBuffer.bid;
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
    } else {
        [self bufferSelected:_buffer.bid];
    }
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.clipsToBounds = YES;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self _updateUnreadIndicator];
    [self.slidingViewController resetTopView];
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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSwipe:)
                                                 name:ECSlidingViewUnderLeftWillAppear object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSwipe:)
                                                 name:ECSlidingViewUnderRightWillAppear object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSwipe:)
                                                 name:ECSlidingViewUnderLeftWillDisappear object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didSwipe:)
                                                 name:ECSlidingViewUnderRightWillDisappear object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewWillLayoutSubviews)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    
    NSString *session = [NetworkConnection sharedInstance].session;
    if([NetworkConnection sharedInstance].state != kIRCCloudStateConnected && [[NetworkConnection sharedInstance] reachable] == kIRCCloudReachable && session != nil && [session length] > 0)
        [[NetworkConnection sharedInstance] connect];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        _message.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        _message.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        self.view.window.backgroundColor = [UIColor blackColor];
#endif
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_doubleTapTimer invalidate];
    _doubleTapTimer = nil;
    _eidToOpen = -1;
}

- (void)viewDidAppear:(BOOL)animated {
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [_eventsView didRotateFromInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _titleLabel);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    CLS_LOG(@"Received low memory warning, cleaning up backlog");
    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
        if(b != _buffer && !b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
            [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:50];
    }
    if(!_buffer.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:_buffer.bid lastSeenEid:_buffer.last_seen_eid type:_buffer.type] == 0) {
        [[EventsDataSource sharedInstance] pruneEventsForBuffer:_buffer.bid maxSize:100];
        [_eventsView setBuffer:_buffer];
    }
}

-(IBAction)serverStatusBarPressed:(id)sender {
    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    if(s) {
        if([s.status isEqualToString:@"disconnected"])
            [[NetworkConnection sharedInstance] reconnect:_buffer.cid];
        else if([s.away isKindOfClass:[NSString class]] && s.away.length) {
            [[NetworkConnection sharedInstance] back:_buffer.cid];
            s.away = @"";
            [self _updateServerStatus];
        }
    }
}

-(void)sendButtonPressed:(id)sender {
    if(_message.text && _message.text.length) {
        id k = objc_msgSend(NSClassFromString(@"UIKeyboard"), NSSelectorFromString(@"activeKeyboard"));
        if([k respondsToSelector:NSSelectorFromString(@"acceptAutocorrection")]) {
            objc_msgSend(k, NSSelectorFromString(@"acceptAutocorrection"));
        }

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
                e.eid = ([[NSDate date] timeIntervalSince1970] + [NetworkConnection sharedInstance].clockOffset) * 1000000;
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
            _buffer.draft = nil;
            if(e.reqId < 0)
                e.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:e repeats:NO];
        }
    }
}

-(void)_sendRequestDidExpire:(NSTimer *)timer {
    Event *e = timer.userInfo;
    e.expirationTimer = nil;
    if([_pendingEvents containsObject:e]) {
        [_pendingEvents removeObject:e];
        e.height = 0;
        e.pending = NO;
        e.rowType = ROW_FAILED;
        e.bgColor = [UIColor errorBackgroundColor];
        [_eventsView.tableView reloadData];
    }
}

-(void)nickSelected:(NSString *)nick {
    _message.selectedRange = NSMakeRange(0, 0);
    NSString *text = _message.text;
    if(text.length == 0) {
        _message.text = nick;
    } else {
        while(text.length > 0 && [text characterAtIndex:text.length - 1] != ' ') {
            text = [text substringToIndex:text.length - 1];
        }
        text = [text stringByAppendingString:nick];
        _message.text = text;
    }
    
    if([text rangeOfString:@" "].location == NSNotFound)
        _message.text = [_message.text stringByAppendingString:@": "];
    else
        _message.text = [_message.text stringByAppendingString:@" "];
}

-(void)updateSuggestions:(BOOL)force {
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    if(_message.text.length > 0) {
        if(!_sortedChannels)
            _sortedChannels = [[[ChannelsDataSource sharedInstance] channels] sortedArrayUsingSelector:@selector(compare:)];
        if(!_sortedUsers)
            _sortedUsers = [[[UsersDataSource sharedInstance] usersForBuffer:_buffer.bid] sortedArrayUsingSelector:@selector(compareByMentionTime:)];
        NSString *text = [_message.text lowercaseString];
        NSUInteger lastSpace = [text rangeOfString:@" " options:NSBackwardsSearch].location;
        if(lastSpace != NSNotFound && lastSpace != text.length) {
            text = [text substringFromIndex:lastSpace + 1];
        }
        if([text hasSuffix:@":"])
            text = [text substringToIndex:text.length - 1];
        if(text.length > 1 || force) {
            if([_buffer.type isEqualToString:@"channel"] && [[_buffer.name lowercaseString] hasPrefix:text])
                [suggestions addObject:_buffer.name];
            for(Channel *channel in _sortedChannels) {
                if(text.length > 0 && channel.name.length > 0 && [channel.name characterAtIndex:0] == [text characterAtIndex:0] && channel.bid != _buffer.bid && [[channel.name lowercaseString] hasPrefix:text])
                    [suggestions addObject:channel.name];
            }
            
            for(User *user in _sortedUsers) {
                if([[user.nick lowercaseString] hasPrefix:text]) {
                    [suggestions addObject:user.nick];
                }
            }
        }
    }
    if(_nickCompletionView.selection == -1 || suggestions.count == 0)
        [_nickCompletionView setSuggestions:suggestions];
    if(suggestions.count == 0) {
        if(_nickCompletionView.alpha > 0) {
            [UIView animateWithDuration:0.25 animations:^{ _nickCompletionView.alpha = 0; } completion:nil];
            _message.internalTextView.autocorrectionType = UITextAutocorrectionTypeYes;
            [_message.internalTextView reloadInputViews];
            id k = objc_msgSend(NSClassFromString(@"UIKeyboard"), NSSelectorFromString(@"activeKeyboard"));
            if([k respondsToSelector:NSSelectorFromString(@"_setAutocorrects:")]) {
                objc_msgSend(k, NSSelectorFromString(@"_setAutocorrects:"), YES);
            }
            _sortedChannels = nil;
            _sortedUsers = nil;
        }
    } else {
        if(_nickCompletionView.alpha == 0) {
            [UIView animateWithDuration:0.25 animations:^{ _nickCompletionView.alpha = 1; } completion:nil];
            NSString *text = _message.text;
            _message.internalTextView.autocorrectionType = UITextAutocorrectionTypeNo;
            _message.delegate = nil;
            _message.text = text;
            _message.selectedRange = NSMakeRange(text.length, 0);
            _message.delegate = self;
            [_message.internalTextView reloadInputViews];
            id k = objc_msgSend(NSClassFromString(@"UIKeyboard"), NSSelectorFromString(@"activeKeyboard"));
            if([k respondsToSelector:NSSelectorFromString(@"_setAutocorrects:")]) {
                objc_msgSend(k, NSSelectorFromString(@"_setAutocorrects:"), NO);
                objc_msgSend(k, NSSelectorFromString(@"removeAutocorrectPrompt"));
            }
        }
    }
}

-(BOOL)expandingTextView:(UIExpandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\t"]) {
        if(_nickCompletionView.count == 0)
            [self updateSuggestions:YES];
        if(_nickCompletionView.count > 0) {
            int s = _nickCompletionView.selection;
            if(s == -1 || s == _nickCompletionView.count - 1)
                s = 0;
            else
                s++;
            [_nickCompletionView setSelection:s];
            text = _message.text;
            if(text.length == 0) {
                _message.text = [_nickCompletionView suggestion];
            } else {
                while(text.length > 0 && [text characterAtIndex:text.length - 1] != ' ') {
                    text = [text substringToIndex:text.length - 1];
                }
                text = [text stringByAppendingString:[_nickCompletionView suggestion]];
                _message.text = text;
            }
            if([text rangeOfString:@" "].location == NSNotFound)
                _message.text = [_message.text stringByAppendingString:@":"];
        }
        return NO;
    } else {
        _nickCompletionView.selection = -1;
    }
    return YES;
}

-(void)_updateSuggestionsTimer {
    _nickCompletionTimer = nil;
    [self updateSuggestions:NO];
}

-(void)scheduleSuggestionsTimer {
    if(_nickCompletionTimer)
        [_nickCompletionTimer invalidate];
    _nickCompletionTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_updateSuggestionsTimer) userInfo:nil repeats:NO];
}

-(void)cancelSuggestionsTimer {
    if(_nickCompletionTimer)
        [_nickCompletionTimer invalidate];
    _nickCompletionTimer = nil;
}

-(void)_updateMessageWidth {
    if(_message.text.length > 0) {
        CGRect frame = _message.frame;
        frame.size.width = _bottomBar.frame.size.width - _sendBtn.frame.size.width - frame.origin.x - 16;
        _message.frame = frame;
        _sendBtn.enabled = YES;
        _sendBtn.alpha = 1;
        _settingsBtn.enabled = NO;
        _settingsBtn.alpha = 0;
    } else {
        CGRect frame = _message.frame;
        frame.size.width = _bottomBar.frame.size.width - _settingsBtn.frame.size.width - frame.origin.x - 8;
        _message.frame = frame;
        _sendBtn.enabled = NO;
        _sendBtn.alpha = 0;
        _settingsBtn.enabled = YES;
        _settingsBtn.alpha = 1;
    }
}

-(void)expandingTextViewDidChange:(UIExpandingTextView *)expandingTextView {
    [UIView beginAnimations:nil context:nil];
    [self _updateMessageWidth];
    [UIView commitAnimations];
    if(_nickCompletionView.alpha == 1) {
        [self updateSuggestions:NO];
    } else {
        [self performSelectorOnMainThread:@selector(scheduleSuggestionsTimer) withObject:nil waitUntilDone:NO];
    }
}

-(BOOL)expandingTextViewShouldReturn:(UIExpandingTextView *)expandingTextView {
    [self sendButtonPressed:expandingTextView];
    return NO;
}

-(void)expandingTextView:(UIExpandingTextView *)expandingTextView willChangeHeight:(float)height {
    if(expandingTextView.frame.size.height != height) {
        NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
        CGRect frame = _eventsView.tableView.frame;
        frame.size.height = self.view.frame.size.height - height - 8;
        if(!_serverStatusBar.hidden)
            frame.size.height -= _serverStatusBar.frame.size.height;
        _eventsView.tableView.frame = frame;
        frame = _serverStatusBar.frame;
        frame.origin.y = self.view.frame.size.height - height - 8 - frame.size.height;
        _serverStatusBar.frame = frame;
        frame = _eventsView.bottomUnreadView.frame;
        frame.origin.y = self.view.frame.size.height - height - 8 - frame.size.height;
        _eventsView.bottomUnreadView.frame = frame;
        [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        _bottomBar.frame = CGRectMake(_bottomBar.frame.origin.x, self.view.frame.size.height - height - 8, _bottomBar.frame.size.width, height + 8);
    }
}

-(void)_updateTitleArea {
    _lock.hidden = YES;
    if([_buffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        if(s.name.length)
            _titleLabel.text = s.name;
        else
            _titleLabel.text = s.hostname;
        _titleLabel.accessibilityLabel = @"Server";
        _titleLabel.accessibilityValue = _titleLabel.text;
        self.navigationItem.title = _titleLabel.text;
        _topicLabel.hidden = NO;
        _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
        _titleLabel.font = [UIFont boldSystemFontOfSize:18];
        _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
        _topicLabel.text = [NSString stringWithFormat:@"%@:%i", s.hostname, s.port];
        _lock.frame = CGRectMake((_titleView.frame.size.width - [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:_titleLabel.bounds.size].width)/2 - 20,4,16,16);
        _lock.hidden = NO;
        if(s.ssl > 0)
            _lock.image = [UIImage imageNamed:@"world_shield"];
        else
            _lock.image = [UIImage imageNamed:@"world"];
    } else {
        self.navigationItem.title = _buffer.name = _titleLabel.text = _buffer.name;
        _titleLabel.frame = CGRectMake(0,0,_titleView.frame.size.width,_titleView.frame.size.height);
        _titleLabel.font = [UIFont boldSystemFontOfSize:20];
        _titleLabel.accessibilityValue = _buffer.accessibilityValue;
        _topicLabel.hidden = YES;
        _lock.image = [UIImage imageNamed:@"lock"];
        if([_buffer.type isEqualToString:@"channel"]) {
            _titleLabel.accessibilityLabel = @"Channel";
            BOOL lock = NO;
            Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid];
            if(channel) {
                if(channel.key)
                    lock = YES;
                if([channel.topic_text isKindOfClass:[NSString class]] && channel.topic_text.length) {
                    _topicLabel.hidden = NO;
                    _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
                    _titleLabel.font = [UIFont boldSystemFontOfSize:18];
                    _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
                    _topicLabel.text = [[ColorFormatter format:channel.topic_text defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
                    _topicLabel.accessibilityLabel = @"Topic";
                    _topicLabel.accessibilityValue = _topicLabel.text;
                    _lock.frame = CGRectMake((_titleView.frame.size.width - [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:_titleLabel.bounds.size].width)/2 - 20,4,16,_titleLabel.bounds.size.height-4);
                } else {
                    _lock.frame = CGRectMake((_titleView.frame.size.width - [_titleLabel.text sizeWithFont:_titleLabel.font constrainedToSize:_titleLabel.bounds.size].width)/2 - 20,0,16,_titleLabel.bounds.size.height);
                    _topicLabel.hidden = YES;
                }
            }
            if(lock) {
                _lock.hidden = NO;
            } else {
                _lock.hidden = YES;
            }
        } else if([_buffer.type isEqualToString:@"conversation"]) {
            _titleLabel.accessibilityLabel = @"Conversation with";
            self.navigationItem.title = _titleLabel.text = _buffer.name;
            _topicLabel.hidden = NO;
            _titleLabel.frame = CGRectMake(0,2,_titleView.frame.size.width,20);
            _titleLabel.font = [UIFont boldSystemFontOfSize:18];
            _topicLabel.frame = CGRectMake(0,20,_titleView.frame.size.width,18);
            if(_buffer.away_msg.length) {
                _topicLabel.text = [NSString stringWithFormat:@"Away: %@", _buffer.away_msg];
            } else {
                User *u = [[UsersDataSource sharedInstance] getUser:_buffer.name cid:_buffer.cid];
                if(u && u.away) {
                    if(u.away_msg.length)
                        _topicLabel.text = [NSString stringWithFormat:@"Away: %@", u.away_msg];
                    else
                        _topicLabel.text = @"Away";
                } else {
                    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
                    if(s.name.length)
                        _topicLabel.text = s.name;
                    else
                        _topicLabel.text = s.hostname;
                }
            }
        }
    }
}

-(void)launchURL:(NSURL *)url {
    int port = [url.port intValue];
    int ssl = [url.scheme hasSuffix:@"s"]?1:0;
    BOOL match = NO;
    kIRCCloudState state = [NetworkConnection sharedInstance].state;
    
    if([url.host intValue] > 0 && url.path && url.path.length > 1) {
        Server *s = [[ServersDataSource sharedInstance] getServer:[url.host intValue]];
        if(s != nil) {
            match = YES;
            NSString *channel = [url.path substringFromIndex:1];
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:channel server:s.cid];
            if([b.type isEqualToString:@"channel"] && ![[ChannelsDataSource sharedInstance] channelForBuffer:b.bid])
                b = nil;
            if(b)
                [self bufferSelected:b.bid];
            else if(state == kIRCCloudStateConnected)
                [[NetworkConnection sharedInstance] join:channel key:nil cid:s.cid];
            else
                match = NO;
        }
    }
    
    if(!match) {
        for(Server *s in [[ServersDataSource sharedInstance] getServers]) {
            if([[s.hostname lowercaseString] isEqualToString:[url.host lowercaseString]])
                match = YES;
            if(port > 0 && port != 6667 && port != s.port)
                match = NO;
            if(ssl == 1 && !s.ssl)
                match = NO;
            if(match) {
                if(url.path && url.path.length > 1) {
                    NSString *channel = [url.path substringFromIndex:1];
                    Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:channel server:s.cid];
                    if([b.type isEqualToString:@"channel"] && ![[ChannelsDataSource sharedInstance] channelForBuffer:b.bid])
                        b = nil;
                    if(b)
                        [self bufferSelected:b.bid];
                    else if(state == kIRCCloudStateConnected)
                        [[NetworkConnection sharedInstance] join:channel key:nil cid:s.cid];
                    else
                        match = NO;
                } else {
                    Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:@"*" server:s.cid];
                    if(b)
                        [self bufferSelected:b.bid];
                    else
                        match = NO;
                }
                break;
            }
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
    [self performSelectorOnMainThread:@selector(cancelSuggestionsTimer) withObject:nil waitUntilDone:NO];
    _sortedChannels = nil;
    _sortedUsers = nil;
    BOOL changed = (_buffer && _buffer.bid != bid) || !_buffer;
    if(_buffer && _buffer.bid != bid && _bidToOpen != bid) {
        _eidToOpen = -1;
    }

    Buffer *lastBuffer = _buffer;
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    if(lastBuffer && changed) {
        _buffer.lastBuffer = lastBuffer;
        lastBuffer.draft = _message.text;
    }
    if(_buffer) {
        CLS_LOG(@"BID selected: cid%i bid%i", _buffer.cid, bid);
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:_buffer.bid];
        for(Event *event in events) {
            if(event.isHighlight) {
                User *u = [[UsersDataSource sharedInstance] getUser:event.from cid:event.cid bid:event.bid];
                if(u && u.lastMention < event.eid) {
                    u.lastMention = event.eid;
                }
            }
        }
    } else {
        CLS_LOG(@"BID selected but not found: bid%i", bid);
    }
    
    [self _updateTitleArea];
    [_buffersView setBuffer:_buffer];
    _eventsView.eidToOpen = _eidToOpen;
    if(changed) {
        [UIView animateWithDuration:0.1 animations:^{
            _eventsView.view.alpha = 0;
            _eventsView.topUnreadView.alpha = 0;
            _eventsView.bottomUnreadView.alpha = 0;
            _eventActivity.alpha = 1;
            [_eventActivity startAnimating];
            [_message clearText];
        } completion:^(BOOL finished){
            [_eventsView setBuffer:_buffer];
            [UIView animateWithDuration:0.1 animations:^{
                _eventsView.view.alpha = 1;
                _eventActivity.alpha = 0;
                _message.text = _buffer.draft;
            } completion:^(BOOL finished){
                [_eventActivity stopAnimating];
            }];
        }];
    } else {
        [_eventsView setBuffer:_buffer];
    }
    [_usersView setBuffer:_buffer];
    [self _updateUserListVisibility];
    [self _updateServerStatus];
    [self.slidingViewController resetTopView];
    [self _updateUnreadIndicator];
    [self updateSuggestions:NO];
}

-(void)_updateGlobalMsg {
    if([NetworkConnection sharedInstance].globalMsg.length) {
        _globalMsgContainer.hidden = NO;
        _globalMsg.userInteractionEnabled = NO;
        NSString *msg = [NetworkConnection sharedInstance].globalMsg;
        msg = [msg stringByReplacingOccurrencesOfString:@"<b>" withString:[NSString stringWithFormat:@"%c", BOLD]];
        msg = [msg stringByReplacingOccurrencesOfString:@"</b>" withString:[NSString stringWithFormat:@"%c", BOLD]];
        msg = [msg stringByReplacingOccurrencesOfString:@"<strong>" withString:[NSString stringWithFormat:@"%c", BOLD]];
        msg = [msg stringByReplacingOccurrencesOfString:@"</strong>" withString:[NSString stringWithFormat:@"%c", BOLD]];
        msg = [msg stringByReplacingOccurrencesOfString:@"<i>" withString:[NSString stringWithFormat:@"%c", ITALICS]];
        msg = [msg stringByReplacingOccurrencesOfString:@"</i>" withString:[NSString stringWithFormat:@"%c", ITALICS]];
        msg = [msg stringByReplacingOccurrencesOfString:@"<u>" withString:[NSString stringWithFormat:@"%c", UNDERLINE]];
        msg = [msg stringByReplacingOccurrencesOfString:@"</u>" withString:[NSString stringWithFormat:@"%c", UNDERLINE]];
        msg = [msg stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
        msg = [msg stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
        
        NSMutableAttributedString *s = (NSMutableAttributedString *)[ColorFormatter format:msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil];
        
        CTTextAlignment alignment = kCTCenterTextAlignment;
        CTParagraphStyleSetting paragraphStyle;
        paragraphStyle.spec = kCTParagraphStyleSpecifierAlignment;
        paragraphStyle.valueSize = sizeof(CTTextAlignment);
        paragraphStyle.value = &alignment;
        
        CTParagraphStyleRef style = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &paragraphStyle, 1);
        [s addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(__bridge id)style range:NSMakeRange(0, [s length])];
        CFRelease(style);

        _globalMsg.attributedText = s;
        
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_globalMsg.attributedText));
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(_bottomBar.frame.size.width,CGFLOAT_MAX), NULL);
        _globalMsgContainer.frame = CGRectMake(_bottomBar.frame.origin.x, 0, _bottomBar.frame.size.width, suggestedSize.height + 4);
        CFRelease(framesetter);
    } else {
        _globalMsgContainer.hidden = YES;
    }
}

-(IBAction)globalMsgPressed:(id)sender {
    _globalMsgContainer.hidden = YES;
    [NetworkConnection sharedInstance].globalMsg = nil;
}

-(void)_updateServerStatus {
    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    if(s && (![s.status isEqualToString:@"connected_ready"] || ([s.away isKindOfClass:[NSString class]] && s.away.length))) {
        if(_serverStatusBar.hidden) {
            _serverStatusBar.hidden = NO;
        }
        _serverStatusBar.backgroundColor = [UIColor backgroundBlueColor];
        _serverStatus.textColor = [UIColor darkBlueColor];
        _serverStatus.font = [UIFont systemFontOfSize:FONT_SIZE];
        if([s.status isEqualToString:@"connected_ready"]) {
            if([s.away isKindOfClass:[NSString class]]) {
                _serverStatusBar.backgroundColor = [UIColor lightGrayColor];
                _serverStatus.textColor = [UIColor blackColor];
                if(![[s.away lowercaseString] isEqualToString:@"away"]) {
                    _serverStatus.text = [NSString stringWithFormat:@"Away (%@). Tap to come back.", s.away];
                } else {
                    _serverStatus.text = @"Away. Tap to come back.";
                }
            }
        } else if([s.status isEqualToString:@"quitting"]) {
            _serverStatus.text = @"Disconnecting";
        } else if([s.status isEqualToString:@"disconnected"]) {
            NSString *type = [s.fail_info objectForKey:@"type"];
            if([type isKindOfClass:[NSString class]] && [type length]) {
                NSString *reason = [s.fail_info objectForKey:@"reason"];
                if([type isEqualToString:@"killed"]) {
                    _serverStatus.text = [NSString stringWithFormat:@"Disconnected - Killed: %@", reason];
                } else if([type isEqualToString:@"connecting_restricted"]) {
                    _serverStatus.text = @"You can’t connect to this server with a free account.";
                } else if([type isEqualToString:@"connection_blocked"]) {
                    _serverStatus.text = @"Disconnected - Connections to this server have been blocked";
                } else {
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
                    else if([reason isEqualToString:@"nxdomain"] || [reason isEqualToString:@"einval"])
                        reason = @"Invalid hostname";
                    else if([reason isEqualToString:@"server_ping_timeout"])
                        reason = @"PING timeout";
                    else if([reason isEqualToString:@"ssl_certificate_error"])
                        reason = @"SSL certificate error";
                    else if([reason isEqualToString:@"ssl_error"])
                        reason = @"SSL error";
                    else if([reason isEqualToString:@"crash"])
                        reason = @"Connection crashed";
                    else if([reason isEqualToString:@"networks"])
                        reason = @"You've exceeded the connection limit for free accounts.";
                    else if([reason isEqualToString:@"passworded_servers"])
                        reason = @"You can't connect to passworded servers with free accounts.";
                    _serverStatus.text = [NSString stringWithFormat:@"Disconnected: %@", reason];
                }
                _serverStatusBar.backgroundColor = [UIColor networkErrorBackgroundColor];
                _serverStatus.textColor = [UIColor networkErrorColor];
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
            _serverStatusBar.backgroundColor = [UIColor networkErrorBackgroundColor];
            _serverStatus.textColor = [UIColor networkErrorColor];
        } else if([s.status isEqualToString:@"waiting_to_retry"]) {
            double seconds = ([[s.fail_info objectForKey:@"timestamp"] doubleValue] + [[s.fail_info objectForKey:@"retry_timeout"] intValue]) - [[NSDate date] timeIntervalSince1970];
            if(seconds > 0) {
                NSString *reason = [s.fail_info objectForKey:@"reason"];
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
                NSString *text = @"Disconnected";
                if([reason isKindOfClass:[NSString class]] && [reason length])
                    text = [text stringByAppendingFormat:@": %@, ", reason];
                else
                    text = [text stringByAppendingString:@"; "];
                text = [text stringByAppendingFormat:@"Reconnecting in %i seconds.", (int)seconds];
                _serverStatus.text = text;
                _serverStatusBar.backgroundColor = [UIColor networkErrorBackgroundColor];
                _serverStatus.textColor = [UIColor networkErrorColor];
            } else {
                _serverStatus.text = @"Ready to connect.  Waiting our turn…";
            }
            [self performSelector:@selector(_updateServerStatus) withObject:nil afterDelay:0.5];
        } else if([s.status isEqualToString:@"ip_retry"]) {
            _serverStatus.text = @"Trying another IP address";
        } else {
            CLS_LOG(@"Unhandled server status: %@", s.status);
        }
        CGRect frame = _serverStatus.frame;
        frame.origin.x = 8;
        frame.origin.y = 4;
        frame.size.width = _serverStatusBar.frame.size.width - 16;
        frame.size.height = [_serverStatus.text sizeWithFont:_serverStatus.font constrainedToSize:CGSizeMake(frame.size.width, INT_MAX) lineBreakMode:_serverStatus.lineBreakMode].height;
        _serverStatus.frame = frame;
        frame = _serverStatusBar.frame;
        frame.size.height = _serverStatus.frame.size.height + 8;
        frame.origin.y = _bottomBar.frame.origin.y - frame.size.height;
        _serverStatusBar.frame = frame;
        frame = _eventsView.view.frame;
        frame.size.height = _serverStatusBar.frame.origin.y;
        _eventsView.view.frame = frame;
        frame = _eventsView.bottomUnreadView.frame;
        frame.origin.y = _serverStatusBar.frame.origin.y - frame.size.height;
        _eventsView.bottomUnreadView.frame = frame;
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

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)viewWillLayoutSubviews {
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(duration > 0)
        [self.slidingViewController resetTopView];

    int height = (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?[UIScreen mainScreen].applicationFrame.size.width:[UIScreen mainScreen].applicationFrame.size.height) - _kbSize.height;
    int width = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?[UIScreen mainScreen].applicationFrame.size.height:[UIScreen mainScreen].applicationFrame.size.width;
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        height += UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?[UIApplication sharedApplication].statusBarFrame.size.width:[UIApplication sharedApplication].statusBarFrame.size.height;
#endif
    
    CGRect frame = self.slidingViewController.view.frame;
    if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)
        frame.origin.y = _kbSize.height;
    else if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait)
        frame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height - (([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)?20:0);
    else if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)
        frame.origin.x = _kbSize.height;
    else if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
        frame.origin.x = [UIApplication sharedApplication].statusBarFrame.size.width - (([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)?20:0);
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        frame.size.width = height;
        frame.size.height = width;
    } else {
        frame.size.width = width;
        frame.size.height = height;
    }
    self.slidingViewController.view.frame = frame;
    
    height -= self.navigationController.navigationBar.frame.size.height;
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        height -= UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?[UIApplication sharedApplication].statusBarFrame.size.width:[UIApplication sharedApplication].statusBarFrame.size.height;
#endif

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        _eventsView.view.frame = CGRectMake(0,0, width, height - _bottomBar.frame.size.height);
        _bottomBar.frame = CGRectMake(0,height - _bottomBar.frame.size.height,_eventsView.view.frame.size.width,_bottomBar.frame.size.height);
        CGRect frame = _titleView.frame;
        frame.size.width = UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?364:204;
        frame.size.height = UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?24:40;
        _titleView.frame = frame;
        if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
            _landscapeView.transform = ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)?CGAffineTransformMakeRotation(-M_PI/2):CGAffineTransformMakeRotation(M_PI/2);
        else
            _landscapeView.transform = CGAffineTransformIdentity;
        _landscapeView.frame = [UIScreen mainScreen].applicationFrame;
        _topicLabel.alpha = UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?0:1;
        [self.slidingViewController updateUnderLeftLayout];
        [self.slidingViewController updateUnderRightLayout];
    } else {
        if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
            self.navigationItem.leftBarButtonItem = nil;
            self.navigationItem.rightBarButtonItem = nil;
            self.slidingViewController.underLeftViewController = nil;
            self.slidingViewController.underRightViewController = nil;
            [self addChildViewController:_buffersView];
            [self addChildViewController:_usersView];
            _buffersView.view.frame = CGRectMake(0,0,220,height);
            _eventsView.view.frame = CGRectMake(220,0,width - 440,height - _bottomBar.frame.size.height);
            _usersView.view.frame = CGRectMake(_eventsView.view.frame.origin.x + _eventsView.view.frame.size.width,0,220,height);
            _bottomBar.frame = CGRectMake(220,height - _bottomBar.frame.size.height,_eventsView.view.frame.size.width,_bottomBar.frame.size.height);
            _borders.frame = CGRectMake(219,0,_eventsView.view.frame.size.width + 2,height);
            [_buffersView willMoveToParentViewController:self];
            [_buffersView viewWillAppear:NO];
            _buffersView.view.hidden = NO;
            [self.view insertSubview:_buffersView.view atIndex:1];
            [_usersView willMoveToParentViewController:self];
            [_usersView viewWillAppear:NO];
            _usersView.view.hidden = NO;
            [self.view insertSubview:_usersView.view atIndex:1];
            _borders.hidden = NO;
            CGRect frame = _titleView.frame;
            frame.size.width = 800;
            _titleView.frame = frame;
            frame = _serverStatusBar.frame;
            frame.origin.x = _buffersView.view.frame.size.width;
            frame.size.width = _eventsView.view.frame.size.width;
            _serverStatusBar.frame = frame;
        } else {
            _borders.hidden = YES;
            if(!self.slidingViewController.underLeftViewController)
                self.slidingViewController.underLeftViewController = _buffersView;
            if(!self.navigationItem.leftBarButtonItem)
                self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_menuBtn];
            _buffersView.view.frame = CGRectMake(0,0,220,height);
            _usersView.view.frame = CGRectMake(0,0,220,height);
            [self.slidingViewController updateUnderLeftLayout];
            [self.slidingViewController updateUnderRightLayout];
            _eventsView.view.frame = CGRectMake(0,0,(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?[UIScreen mainScreen].applicationFrame.size.height:[UIScreen mainScreen].applicationFrame.size.width), height - _bottomBar.frame.size.height);
            _bottomBar.frame = CGRectMake(0,height - _bottomBar.frame.size.height,_eventsView.view.frame.size.width,_bottomBar.frame.size.height);
            CGRect frame = _titleView.frame;
            frame.size.width = 500;
            _titleView.frame = frame;
            frame = _serverStatusBar.frame;
            frame.origin.x = 0;
            frame.size.width = _eventsView.view.frame.size.width;
            _serverStatusBar.frame = frame;
        }
    }
    if(duration > 0) {
        _eventsView.view.hidden = YES;
        _eventActivity.alpha = 1;
        [_eventActivity startAnimating];
    }
    _message.maximumNumberOfLines = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)?10:UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?4:6;
    if(duration > 0)
        _message.text = _message.text;
    frame = _eventsView.view.frame;
    frame.size.height = 32;
    _eventsView.topUnreadView.frame = frame;
    frame.origin.y += _eventsView.view.frame.size.height - 32;
    _eventsView.bottomUnreadView.frame = frame;
    float h = [@" " sizeWithFont:_nickCompletionView.font].height + 12;
    _nickCompletionView.frame = CGRectMake(_bottomBar.frame.origin.x + 8,_bottomBar.frame.origin.y - h - 20, _bottomBar.frame.size.width - 16, h);
    _nickCompletionView.layer.cornerRadius = 5;
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        frame = _connectingProgress.frame;
        frame.origin.x = 0;
        frame.origin.y = self.navigationController.navigationBar.frame.size.height - frame.size.height;
        frame.size.width = self.navigationController.navigationBar.frame.size.width;
        _connectingProgress.frame = frame;
        frame = _connectingStatus.frame;
        frame.origin.y = 0;
        frame.size.height = _connectingView.frame.size.height;
        _connectingStatus.frame = frame;
    }
#endif
    self.navigationController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.slidingViewController.view.layer.bounds].CGPath;
    [self _updateTitleArea];
    [self _updateServerStatus];
    [self _updateUserListVisibility];
    [self _updateGlobalMsg];
    [self _updateMessageWidth];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    _eventsView.view.hidden = NO;
    _eventActivity.alpha = 0;
    [_eventActivity stopAnimating];
}

-(void)_updateUserListVisibility {
    if(![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(_updateUserListVisibility) withObject:nil waitUntilDone:YES];
        return;
    }
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
            self.navigationItem.rightBarButtonItem = _usersButtonItem;
            if(self.slidingViewController.underRightViewController == nil)
                self.slidingViewController.underRightViewController = _usersView;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
            self.slidingViewController.underRightViewController = nil;
        }
    } else {
        if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid] && !([NetworkConnection sharedInstance].prefs && [[[[NetworkConnection sharedInstance].prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])) {
                self.navigationItem.rightBarButtonItem = nil;
                CGRect frame = _eventsView.view.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
                _eventsView.view.frame = frame;
                frame = _bottomBar.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
                _bottomBar.frame = frame;
                frame = _serverStatusBar.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
                _serverStatusBar.frame = frame;
                _usersView.view.hidden = NO;
                frame = _borders.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width + 2;
                _borders.frame = frame;
                frame = _eventsView.topUnreadView.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
                _eventsView.topUnreadView.frame = frame;
                frame = _eventsView.bottomUnreadView.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width - _usersView.view.bounds.size.width;
                _eventsView.bottomUnreadView.frame = frame;
            } else {
                if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
                    self.navigationItem.rightBarButtonItem = _usersButtonItem;
                    if(self.slidingViewController.underRightViewController == nil)
                        self.slidingViewController.underRightViewController = _usersView;
                } else {
                    self.navigationItem.rightBarButtonItem = nil;
                    self.slidingViewController.underRightViewController = nil;
                }
                CGRect frame = _eventsView.view.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
                _eventsView.view.frame = frame;
                frame = _bottomBar.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
                _bottomBar.frame = frame;
                frame = _serverStatusBar.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
                _serverStatusBar.frame = frame;
                _usersView.view.hidden = YES;
                frame = _borders.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width + 2;
                _borders.frame = frame;
                frame = _eventsView.topUnreadView.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
                _eventsView.topUnreadView.frame = frame;
                frame = _eventsView.bottomUnreadView.frame;
                frame.size.width = [UIScreen mainScreen].bounds.size.height - _buffersView.view.bounds.size.width;
                _eventsView.bottomUnreadView.frame = frame;
            }
            [self _updateMessageWidth];
        } else {
            if([_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
                self.navigationItem.rightBarButtonItem = _usersButtonItem;
                if(self.slidingViewController.underRightViewController == nil)
                    self.slidingViewController.underRightViewController = _usersView;
            } else {
                self.navigationItem.rightBarButtonItem = nil;
                self.slidingViewController.underRightViewController = nil;
            }
        }
    }
}

-(void)showMentionTip {
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"mentionTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"mentionTip"];
        [UIView animateWithDuration:0.5 animations:^{
            _mentionTip.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideMentionTip) withObject:nil afterDelay:2];
        }];
    }
}

-(void)hideMentionTip {
    [UIView animateWithDuration:0.5 animations:^{
        _mentionTip.alpha = 0;
    } completion:nil];
}

-(void)didSwipe:(NSNotification *)n {
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"swipeTip"];
    if([n.name isEqualToString:ECSlidingViewUnderLeftWillAppear])
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, [_buffersView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
    else if([n.name isEqualToString:ECSlidingViewUnderRightWillAppear])
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, [_usersView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
    else
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _titleLabel);
}

-(void)showSwipeTip {
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"swipeTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"swipeTip"];
        [UIView animateWithDuration:0.5 animations:^{
            _swipeTip.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideSwipeTip) withObject:nil afterDelay:2];
        }];
    }
}

-(void)hideSwipeTip {
    [UIView animateWithDuration:0.5 animations:^{
        _swipeTip.alpha = 0;
    } completion:nil];
}

-(void)usersButtonPressed:(id)sender {
    [self showSwipeTip];
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

-(void)listButtonPressed:(id)sender {
    [self showSwipeTip];
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(IBAction)settingsButtonPressed:(id)sender {
    _selectedBuffer = _buffer;
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
        [sheet addButtonWithTitle:@"Edit Connection"];
    } else if([_buffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
            [sheet addButtonWithTitle:@"Leave"];
            if([me.mode rangeOfString:@"q"].location != NSNotFound || [me.mode rangeOfString:@"a"].location != NSNotFound || [me.mode rangeOfString:@"o"].location != NSNotFound) {
                [sheet addButtonWithTitle:@"Ban List"];
            }
        } else {
            [sheet addButtonWithTitle:@"Rejoin"];
            [sheet addButtonWithTitle:(_buffer.archived)?@"Unarchive":@"Archive"];
            [sheet addButtonWithTitle:@"Delete"];
        }
    } else {
        if(_buffer.archived) {
            [sheet addButtonWithTitle:@"Unarchive"];
        } else {
            [sheet addButtonWithTitle:@"Archive"];
        }
        [sheet addButtonWithTitle:@"Delete"];
    }
    [sheet addButtonWithTitle:@"Ignore List"];
    [sheet addButtonWithTitle:@"Add Network"];
    [sheet addButtonWithTitle:@"Display Options"];
    [sheet addButtonWithTitle:@"Settings"];
    [sheet addButtonWithTitle:@"Logout"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.view.window addSubview:_landscapeView];
        [sheet showInView:_landscapeView];
    } else {
        [sheet showInView:self.slidingViewController.view.superview];
    }
}

-(void)dismissKeyboard {
    [_message resignFirstResponder];
}

-(void)_eventTapped:(NSTimer *)timer {
    _doubleTapTimer = nil;
    [_message resignFirstResponder];
    Event *e = timer.userInfo;
    if(e.rowType == ROW_FAILED) {
        _selectedEvent = e;
        Server *s = [[ServersDataSource sharedInstance] getServer:e.cid];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"This message could not be sent" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Try Again", nil];
        alert.tag = TAG_FAILEDMSG;
        [alert show];
    } else {
        [_eventsView clearLastSeenMarker];
    }
}

-(void)rowSelected:(Event *)event {
    if(_doubleTapTimer) {
        [_doubleTapTimer invalidate];
        _doubleTapTimer = nil;
        NSString *from = event.from;
        if(!from.length)
            from = event.nick;
        if(from.length) {
            _selectedUser = [[UsersDataSource sharedInstance] getUser:from cid:event.cid bid:event.bid];
            if(!_selectedUser) {
                _selectedUser = [[User alloc] init];
                _selectedUser.nick = from;
            }
            [self _mention];
        }
    } else {
        _doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_eventTapped:) userInfo:event repeats:NO];
    }
}

-(void)_mention {
    if(!_selectedUser)
        return;

    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"mentionTip"];
    
    [self.slidingViewController resetTopView];
    
    if(_message.text.length == 0) {
        _message.text = [NSString stringWithFormat:@"%@: ",_selectedUser.nick];
    } else {
        NSString *from = _selectedUser.nick;
        NSInteger oldPosition = _message.selectedRange.location;
        NSString *text = _message.text;
        NSInteger start = oldPosition - 1;
        if(start > 0 && [text characterAtIndex:start] == ' ')
            start--;
        while(start > 0 && [text characterAtIndex:start] != ' ')
            start--;
        if(start < 0)
            start = 0;
        NSInteger match = [text rangeOfString:from options:0 range:NSMakeRange(start, text.length - start)].location;
        NSInteger end = oldPosition + from.length;
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
    [sheet addButtonWithTitle:@"Whois"];
    [sheet addButtonWithTitle:@"Send a message"];
    [sheet addButtonWithTitle:@"Mention"];
    [sheet addButtonWithTitle:@"Invite to channel"];
    [sheet addButtonWithTitle:@"Ignore"];
    if([_buffer.type isEqualToString:@"channel"]) {
        Server *server = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
        User *me = [[UsersDataSource sharedInstance] getUser:[[ServersDataSource sharedInstance] getServer:_buffer.cid].nick cid:_buffer.cid bid:_buffer.bid];
        if([me.mode rangeOfString:server?server.MODE_OWNER:@"q"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_ADMIN:@"a"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound) {
            if([_selectedUser.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound)
                [sheet addButtonWithTitle:@"Deop"];
            else
                [sheet addButtonWithTitle:@"Op"];
        }
        if([me.mode rangeOfString:server?server.MODE_OWNER:@"q"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_ADMIN:@"a"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_HALFOP:@"h"].location != NSNotFound) {
            [sheet addButtonWithTitle:@"Kick"];
            [sheet addButtonWithTitle:@"Ban"];
        }
    }
    [sheet addButtonWithTitle:@"Copy Hostmask"];
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        [self.view.window addSubview:_landscapeView];
        [sheet showInView:_landscapeView];
    } else {
        if(_selectedEvent)
            [sheet showFromRect:rect inView:_eventsView.tableView animated:NO];
        else
            [sheet showFromRect:rect inView:_usersView.tableView animated:NO];
    }
}

-(void)_userTapped {
    [self _showUserPopupInRect:_selectedRect];
    _doubleTapTimer = nil;
}

-(void)userSelected:(NSString *)nick rect:(CGRect)rect {
    _selectedRect = rect;
    _selectedEvent = nil;
    _selectedUser = [[UsersDataSource sharedInstance] getUser:nick cid:_buffer.cid bid:_buffer.bid];
    if(_doubleTapTimer) {
        [_doubleTapTimer invalidate];
        _doubleTapTimer = nil;
        [self _mention];
    } else {
        _doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_userTapped) userInfo:nil repeats:NO];
    }
}

-(void)bufferLongPressed:(int)bid rect:(CGRect)rect {
    _selectedBuffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    if([_selectedBuffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:_selectedBuffer.cid];
        if([s.status isEqualToString:@"disconnected"]) {
            [sheet addButtonWithTitle:@"Reconnect"];
            [sheet addButtonWithTitle:@"Delete"];
        } else {
            [sheet addButtonWithTitle:@"Disconnect"];
        }
        [sheet addButtonWithTitle:@"Edit Connection"];
    } else if([_selectedBuffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:_selectedBuffer.bid]) {
            [sheet addButtonWithTitle:@"Leave"];
        } else {
            [sheet addButtonWithTitle:@"Rejoin"];
            [sheet addButtonWithTitle:(_selectedBuffer.archived)?@"Unarchive":@"Archive"];
            [sheet addButtonWithTitle:@"Delete"];
        }
    } else {
        if(_selectedBuffer.archived) {
            [sheet addButtonWithTitle:@"Unarchive"];
        } else {
            [sheet addButtonWithTitle:@"Archive"];
        }
        [sheet addButtonWithTitle:@"Delete"];
    }
    [sheet addButtonWithTitle:@"Mark All As Read"];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.view.window addSubview:_landscapeView];
        [sheet showInView:_landscapeView];
    } else {
        [sheet showFromRect:rect inView:_buffersView.tableView animated:YES];
    }
}

-(void)rowLongPressed:(Event *)event rect:(CGRect)rect {
    NSString *from = event.from;
    if(!from.length)
        from = event.nick;
    if(from) {
        _selectedEvent = event;
        _selectedUser = [[UsersDataSource sharedInstance] getUser:from cid:_buffer.cid bid:_buffer.bid];
        if(!_selectedUser) {
            _selectedUser = [[User alloc] init];
            _selectedUser.cid = _selectedEvent.cid;
            _selectedUser.bid = _selectedEvent.bid;
            _selectedUser.nick = from;
            _selectedUser.hostmask = _selectedEvent.hostmask;
        }
        [self _showUserPopupInRect:rect];
    }
}

-(IBAction)titleAreaPressed:(id)sender {
    if(_buffer && [_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:_buffer.bid]) {
        ChannelInfoViewController *c = [[ChannelInfoViewController alloc] initWithBid:_buffer.bid];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:nc animated:YES completion:nil];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
    return NO;
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
        case TAG_FAILEDMSG:
            if([title isEqualToString:@"Try Again"]) {
                _selectedEvent.height = 0;
                _selectedEvent.rowType = ROW_MESSAGE;
                _selectedEvent.bgColor = [UIColor selfBackgroundColor];
                _selectedEvent.pending = YES;
                _selectedEvent.reqId = [[NetworkConnection sharedInstance] say:_selectedEvent.command to:_buffer.name cid:_buffer.cid];
                if(_selectedEvent.msg)
                    [_pendingEvents addObject:_selectedEvent];
                [_eventsView.tableView reloadData];
                if(_selectedEvent.reqId < 0)
                    _selectedEvent.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:_selectedEvent repeats:NO];
            }
    }
    _alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && alertView.tag != TAG_KICK && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

-(void)_choosePhoto:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.delegate = (id)self;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [picker.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
    }
    [self.slidingViewController presentModalViewController:picker animated:YES];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self.slidingViewController dismissModalViewControllerAnimated:YES];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!img)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if(img) {
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera && [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"])
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
        [self _showConnectingView];
        _connectingStatus.text = @"Uploading";
        [_connectingActivity startAnimating];
        _connectingActivity.hidden = NO;
        _connectingProgress.progress = 0;
        _connectingProgress.hidden = YES;
        ImageUploader *u = [[ImageUploader alloc] init];
        u.delegate = self;
        u.bid = _buffer.bid;
        [u upload:img];
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self.slidingViewController dismissModalViewControllerAnimated:YES];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)imageUploadProgress:(float)progress {
    [_connectingActivity stopAnimating];
    _connectingActivity.hidden = YES;
    _connectingProgress.hidden = NO;
    [_connectingProgress setProgress:progress animated:YES];
}

-(void)imageUploadDidFail {
    _alertView = [[UIAlertView alloc] initWithTitle:@"Upload Failed" message:@"An error occured while uploading the photo. Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [_alertView show];
    [self _hideConnectingView];
}

-(void)imageUploadNotAuthorized {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self _hideConnectingView];
    SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
    [nc pushViewController:[[ImgurLoginViewController alloc] init] animated:NO];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)imageUploadDidFinish:(NSDictionary *)d bid:(int)bid {
    if([[d objectForKey:@"success"] intValue] == 1) {
        NSString *link = [[[d objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        if(bid == _buffer.bid) {
            if(_message.text.length == 0) {
                _message.text = link;
            } else {
                if(![_message.text hasSuffix:@" "])
                    _message.text = [_message.text stringByAppendingString:@" "];
                _message.text = [_message.text stringByAppendingString:link];
            }
        } else {
            Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
            if(b) {
                if(b.draft.length == 0) {
                    b.draft = link;
                } else {
                    if(![b.draft hasSuffix:@" "])
                        b.draft = [b.draft stringByAppendingString:@" "];
                    b.draft = [b.draft stringByAppendingString:link];
                }
            }
        }
    } else {
        CLS_LOG(@"imgur upload failed: %@", d);
        [self imageUploadDidFail];
        return;
    }
    [self _hideConnectingView];
}

-(void)cameraButtonPressed:(id)sender {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take a Photo", @"Choose Existing", nil];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [self.view.window addSubview:_landscapeView];
            [sheet showInView:_landscapeView];
        } else {
            [sheet showInView:self.slidingViewController.view.superview];
        }
    } else {
        [self _choosePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [_landscapeView removeFromSuperview];
    [_message resignFirstResponder];
    if(buttonIndex != -1) {
        NSString *action = [actionSheet buttonTitleAtIndex:buttonIndex];
        
        if([action isEqualToString:@"Copy Message"]) {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            NSString *plaintext = [_selectedEvent.type isEqualToString:@"buffer_me_msg"]?[NSString stringWithFormat:@"%@ — %@ %@", _selectedEvent.timestamp,_selectedEvent.nick,[[ColorFormatter format:_selectedEvent.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]]:[NSString stringWithFormat:@"%@ <%@> %@", _selectedEvent.timestamp,_selectedEvent.from,[[ColorFormatter format:_selectedEvent.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string]];
            [pb setValue:plaintext forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
        } else if([action isEqualToString:@"Archive"]) {
            [[NetworkConnection sharedInstance] archiveBuffer:_selectedBuffer.bid cid:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Unarchive"]) {
            [[NetworkConnection sharedInstance] unarchiveBuffer:_selectedBuffer.bid cid:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Delete"]) {
            //TODO: prompt for confirmation
            if([_selectedBuffer.type isEqualToString:@"console"]) {
                [[NetworkConnection sharedInstance] deleteServer:_selectedBuffer.cid];
            } else if(_selectedBuffer == nil || _selectedBuffer.bid == -1) {
                [self bufferSelected:[[BuffersDataSource sharedInstance] firstBid]];
            } else {
                [[NetworkConnection sharedInstance] deleteBuffer:_selectedBuffer.bid cid:_selectedBuffer.cid];
            }
        } else if([action isEqualToString:@"Leave"]) {
            [[NetworkConnection sharedInstance] part:_selectedBuffer.name msg:nil cid:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Rejoin"]) {
            [[NetworkConnection sharedInstance] join:_selectedBuffer.name key:nil cid:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Ban List"]) {
            [[NetworkConnection sharedInstance] mode:@"b" chan:_selectedBuffer.name cid:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Disconnect"]) {
            [[NetworkConnection sharedInstance] disconnect:_selectedBuffer.cid msg:nil];
        } else if([action isEqualToString:@"Reconnect"]) {
            [[NetworkConnection sharedInstance] reconnect:_selectedBuffer.cid];
        } else if([action isEqualToString:@"Logout"]) {
            [[NetworkConnection sharedInstance] logout];
            [self bufferSelected:-1];
            [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
        } else if([action isEqualToString:@"Ignore List"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            IgnoresTableViewController *itv = [[IgnoresTableViewController alloc] initWithStyle:UITableViewStylePlain];
            itv.ignores = s.ignores;
            itv.cid = s.cid;
            itv.navigationItem.title = @"Ignore List";
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:itv];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Mention"]) {
            [self showMentionTip];
            [self _mention];
        } else if([action isEqualToString:@"Edit Connection"]) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [ecv setServer:_selectedBuffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Settings"]) {
            SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Display Options"]) {
            DisplayOptionsViewController *dvc = [[DisplayOptionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
            dvc.buffer = _buffer;
            dvc.navigationItem.title = _titleLabel.text;
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:dvc];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Add Network"]) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:nc animated:YES completion:nil];
        } else if([action isEqualToString:@"Take a Photo"]) {
            [self _choosePhoto:UIImagePickerControllerSourceTypeCamera];
        } else if([action isEqualToString:@"Choose Existing"]) {
            [self _choosePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
        } else if([action isEqualToString:@"Mark All As Read"]) {
            NSMutableArray *cids = [[NSMutableArray alloc] init];
            NSMutableArray *bids = [[NSMutableArray alloc] init];
            NSMutableArray *eids = [[NSMutableArray alloc] init];
            
            for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
                if([[EventsDataSource sharedInstance] lastEidForBuffer:b.bid]) {
                    [cids addObject:@(b.cid)];
                    [bids addObject:@(b.bid)];
                    [eids addObject:@([[EventsDataSource sharedInstance] lastEidForBuffer:b.bid])];
                }
            }
            
            [[NetworkConnection sharedInstance] heartbeat:_buffer.bid cids:cids bids:bids lastSeenEids:eids];
        }
        
        if(!_selectedUser || !_selectedUser.nick || _selectedUser.nick.length < 1)
            return;
        
        if([action isEqualToString:@"Copy Hostmask"]) {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            NSString *plaintext = [NSString stringWithFormat:@"%@!%@", _selectedUser.nick, _selectedUser.hostmask];
            [pb setValue:plaintext forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
        } else if([action isEqualToString:@"Send a message"]) {
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:_selectedUser.nick server:_buffer.cid];
            if(b) {
                [self bufferSelected:b.bid];
            } else {
                [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", _selectedUser.nick] to:nil cid:_buffer.cid];
            }
        } else if([action isEqualToString:@"Whois"]) {
            if(_selectedUser && _selectedUser.nick.length > 0)
                [[NetworkConnection sharedInstance] whois:_selectedUser.nick server:nil cid:_buffer.cid];
        } else if([action isEqualToString:@"Op"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+%@ %@",s?s.MODE_OP:@"o",_selectedUser.nick] chan:_buffer.name cid:_buffer.cid];
        } else if([action isEqualToString:@"Deop"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-%@ %@",s?s.MODE_OP:@"o",_selectedUser.nick] chan:_buffer.name cid:_buffer.cid];
        } else if([action isEqualToString:@"Ban"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Add a ban mask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ban", nil];
            _alertView.tag = TAG_BAN;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].text = [NSString stringWithFormat:@"*!%@", _selectedUser.hostmask];
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
        } else if([action isEqualToString:@"Ignore"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ignore messages from this mask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ignore", nil];
            _alertView.tag = TAG_IGNORE;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].text = [NSString stringWithFormat:@"*!%@", _selectedUser.hostmask];
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
        } else if([action isEqualToString:@"Kick"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Give a reason for kicking" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Kick", nil];
            _alertView.tag = TAG_KICK;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
        } else if([action isEqualToString:@"Invite to channel"]) {
            Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
            _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Invite to channel" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Invite", nil];
            _alertView.tag = TAG_INVITE;
            _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [_alertView textFieldAtIndex:0].delegate = self;
            [_alertView show];
        }
    }
}
@end
