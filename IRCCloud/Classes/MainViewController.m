
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

#if !TARGET_OS_MACCATALYST
#import <AssetsLibrary/AssetsLibrary.h>
#endif
#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/UTType.h>
#import <UserNotifications/UserNotifications.h>
#import <Intents/Intents.h>
#import "MainViewController.h"
#import "NetworkConnection.h"
#import "ColorFormatter.h"
#import "ChannelModeListTableViewController.h"
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
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "FileMetadataViewController.h"
#import "FilesTableViewController.h"
#import "PastebinEditorViewController.h"
#import "PastebinsTableViewController.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "OpenInChromeController.h"
#import "ServerReorderViewController.h"
#import "FontAwesome.h"
#import "YouTubeViewController.h"
#import "AvatarsDataSource.h"
#import "TextTableViewController.h"
#import "SpamViewController.h"
#import "LinksListTableViewController.h"
#import "WhoWasTableViewController.h"
#import "LogExportsTableViewController.h"
#import "ImageCache.h"
#import "AvatarsTableViewController.h"
#import "PinReorderViewController.h"
#import "LicenseViewController.h"
@import Firebase;

extern NSDictionary *emojiMap;

NSArray *_sortedUsers;
NSArray *_sortedChannels;

@implementation UpdateSuggestionsTask

-(UIExpandingTextView *)message {
    return _message;
}

-(void)setMessage:(UIExpandingTextView *)message {
    self->_message = message;
    self->_text = message.text;
}

-(void)cancel {
    self->_cancelled = YES;
}

-(void)run {
    self.isEmoji = NO;
    NSMutableSet *suggestions_set = [[NSMutableSet alloc] init];
    NSMutableArray *suggestions = [[NSMutableArray alloc] init];
    
    if(self->_text.length > 0) {
        NSString *text = self->_text.lowercaseString;
        NSUInteger lastSpace = [text rangeOfString:@" " options:NSBackwardsSearch].location;
        if(lastSpace != NSNotFound && lastSpace != text.length) {
            text = [text substringFromIndex:lastSpace + 1];
        }
        if([text hasSuffix:@":"])
            text = [text substringToIndex:text.length - 1];
        if([text hasPrefix:@"@"]) {
            self->_atMention = YES;
            text = [text substringFromIndex:1];
        } else {
            self->_atMention = NO;
        }
        
        if(!_sortedChannels)
            _sortedChannels = [[[ChannelsDataSource sharedInstance] channels] sortedArrayUsingSelector:@selector(compare:)];
        
        if([[[[NSUserDefaults standardUserDefaults] objectForKey:@"disable-nick-suggestions"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue]) {
            if(self->_atMention || _force) {
                if(_sortedUsers.count == 0)
                    _sortedUsers = nil;
            } else {
                _sortedUsers = @[];
            }
        }
        if(!_sortedUsers)
            _sortedUsers = [[[UsersDataSource sharedInstance] usersForBuffer:self->_buffer.bid] sortedArrayUsingSelector:@selector(compareByMentionTime:)];
        if(self->_cancelled)
            return;
        
        if(text.length > 1 || _force) {
            if([self->_buffer.type isEqualToString:@"channel"] && [[self->_buffer.name lowercaseString] hasPrefix:text]) {
                [suggestions_set addObject:self->_buffer.name.lowercaseString];
                [suggestions addObject:self->_buffer.name];
            }
            for(Channel *channel in _sortedChannels) {
                if(self->_cancelled)
                    return;
                
                if(text.length > 0 && channel.name.length > 0 && [channel.name characterAtIndex:0] == [text characterAtIndex:0] && channel.bid != self->_buffer.bid && [[channel.name lowercaseString] hasPrefix:text] && ![suggestions_set containsObject:channel.name.lowercaseString] && ![[BuffersDataSource sharedInstance] getBuffer:channel.bid].isMPDM) {
                    [suggestions_set addObject:channel.name.lowercaseString];
                    [suggestions addObject:channel.name];
                    self.isEmoji = YES;
                }
            }
            
            for(User *user in _sortedUsers) {
                if(self->_cancelled)
                    return;
                
                NSString *nick = user.nick.lowercaseString;
                NSString *displayName = user.display_name.lowercaseString;
                NSUInteger location = [nick rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location;
                if([text rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location == 0 && location != NSNotFound && location > 0) {
                    nick = [nick substringFromIndex:location];
                }
                
                if((text.length == 0 || [nick hasPrefix:text] || [displayName hasPrefix:text]) && ![suggestions_set containsObject:user.nick.lowercaseString]) {
                    [suggestions_set addObject:user.nick.lowercaseString];
                    if(![user.nick isEqualToString:user.display_name])
                        [suggestions addObject:[NSString stringWithFormat:@"%@\u00a0(%@)",user.display_name,user.nick]];
                    else
                        [suggestions addObject:user.nick];
                }
            }
        }
        
        if(text.length > 2 && [text hasPrefix:@":"]) {
            NSString *q = [text substringFromIndex:1];
            
            for(NSString *emocode in emojiMap.keyEnumerator) {
                if(self->_cancelled)
                    return;
                
                if([emocode hasPrefix:q]) {
                    NSString *emoji = [emojiMap objectForKey:emocode];
                    if(![suggestions_set containsObject:emoji]) {
                        self.isEmoji = YES;
                        [suggestions_set addObject:emoji];
                        [suggestions addObject:emoji];
                    }
                }
            }
        }
    }
    
    if(self->_cancelled)
        return;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(self->_nickCompletionView.selection == -1 || suggestions.count == 0)
            [self->_nickCompletionView setSuggestions:suggestions];
        
        if(self->_cancelled)
            return;
        
        if(suggestions.count == 0) {
            if(self->_nickCompletionView.alpha > 0) {
                [UIView animateWithDuration:0.25 animations:^{ self->_nickCompletionView.alpha = 0; } completion:nil];
                _sortedChannels = nil;
                _sortedUsers = nil;
            }
            self->_atMention = NO;
        } else {
            if(self->_nickCompletionView.alpha == 0) {
                [UIView animateWithDuration:0.25 animations:^{ self->_nickCompletionView.alpha = 1; } completion:nil];
                NSString *text = self->_message.text;
                id delegate = self->_message.delegate;
                self->_message.delegate = nil;
                self->_message.text = text;
                self->_message.selectedRange = NSMakeRange(text.length, 0);
                if(self->_force && self->_nickCompletionView.selection == -1) {
                    [self->_nickCompletionView setSelection:0];
                    NSString *text = self->_message.text;
                    if(text.length == 0) {
                        if(self->_buffer.serverIsSlack)
                            self->_message.text = [NSString stringWithFormat:@"@%@",[self->_nickCompletionView suggestion]];
                        else
                            self->_message.text = [self->_nickCompletionView suggestion];
                    } else {
                        while(text.length > 0 && [text characterAtIndex:text.length - 1] != ' ') {
                            text = [text substringToIndex:text.length - 1];
                        }
                        if(self->_buffer.serverIsSlack)
                            text = [text stringByAppendingString:@"@"];
                        text = [text stringByAppendingString:[self->_nickCompletionView suggestion]];
                        self->_message.text = text;
                    }
                    if([text rangeOfString:@" "].location == NSNotFound && !self->_buffer.serverIsSlack)
                        self->_message.text = [self->_message.text stringByAppendingString:@":"];
                }
                self->_message.delegate = delegate;
            }
        }
    }];
}
@end

@implementation MainViewController

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if(self = [super initWithCoder:aDecoder]) {
        self->_cidToOpen = -1;
        self->_bidToOpen = -1;
        self->_pendingEvents = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)dealloc {
    AudioServicesDisposeSystemSoundID(alertSound);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_themeChanged {
    if(![self->_currentTheme isEqualToString:[UIColor currentTheme]]) {
        self->_currentTheme = [UIColor currentTheme];
        UIView *v = self.navigationController.view.superview;
        if(v) {
            [self.navigationController.view removeFromSuperview];
            [v addSubview: self.navigationController.view];
        }

        [self applyTheme];
    }
}

- (void)applyTheme {
    self->_currentTheme = [UIColor currentTheme];
    if (@available(iOS 13, *)) {
        self.view.window.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle = [self->_currentTheme isEqualToString:@"dawn"]?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark;
    }
    self.view.window.backgroundColor = [UIColor textareaBackgroundColor];
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    self.slidingViewController.view.backgroundColor = self.navigationController.view.backgroundColor = [UIColor navBarColor];
    self->_bottomBar.backgroundColor = [UIColor contentBackgroundColor];
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *a = [[UINavigationBarAppearance alloc] init];
        a.backgroundImage = [UIColor navBarBackgroundImage];
        a.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor navBarHeadingColor]};
        self.navigationController.navigationBar.standardAppearance = a;
        self.navigationController.navigationBar.compactAppearance = a;
        self.navigationController.navigationBar.scrollEdgeAppearance = a;
        if (@available(iOS 15.0, *)) {
#if !TARGET_OS_MACCATALYST
            self.navigationController.navigationBar.compactScrollEdgeAppearance = a;
#endif
        }
    }
    [self->_uploadsBtn setTintColor:[UIColor textareaBackgroundColor]];
    UIColor *c = ([NetworkConnection sharedInstance].state == kIRCCloudStateConnected)?([UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor unreadBlueColor]):[UIColor textareaBackgroundColor];
    [self->_sendBtn setTitleColor:c forState:UIControlStateNormal];
    [self->_sendBtn setTitleColor:c forState:UIControlStateDisabled];
    [self->_sendBtn setTitleColor:c forState:UIControlStateHighlighted];
    [self->_settingsBtn setTintColor:[UIColor textareaBackgroundColor]];
    [self->_message setBackgroundImage:[UIColor textareaBackgroundImage]];
    self->_message.textColor = [UIColor textareaTextColor];
    self->_message.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    self->_defaultTextareaFont = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightRegular];
    if(!_message.text.length)
        self->_message.font = self->_defaultTextareaFont;
    self->_message.minimumHeight = FONT_SIZE + 22;
    if(self->_message.minimumHeight < 35)
        self->_message.minimumHeight = 35;
    
    UIButton *users = [UIButton buttonWithType:UIButtonTypeCustom];
    [users setImage:[[UIImage imageNamed:@"users"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [users addTarget:self action:@selector(usersButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    users.frame = CGRectMake(0,0,24,22);
    [users setTintColor:[UIColor navBarSubheadingColor]];
    users.accessibilityLabel = @"Channel members list";
    self->_usersButtonItem = [[UIBarButtonItem alloc] initWithCustomView:users];
    
    self->_menuBtn.tintColor = [UIColor navBarSubheadingColor];
    
    self->_eventsView.topUnreadView.backgroundColor = [UIColor chatterBarColor];
    self->_eventsView.bottomUnreadView.backgroundColor = [UIColor chatterBarColor];
    self->_eventsView.topUnreadLabel.textColor = [UIColor chatterBarTextColor];
    self->_eventsView.bottomUnreadLabel.textColor = [UIColor chatterBarTextColor];
    self->_eventsView.topUnreadArrow.textColor = self->_eventsView.bottomUnreadArrow.textColor = [UIColor chatterBarTextColor];
    [self->_eventsView clearRowCache];
    
    self->_borders.backgroundColor = _leftBorder.backgroundColor = _rightBorder.backgroundColor = [UIColor iPadBordersColor];
    [[self->_borders.subviews objectAtIndex:0] setBackgroundColor:[UIColor contentBackgroundColor]];
    
    self->_eventActivity.activityIndicatorViewStyle = self->_headerActivity.activityIndicatorViewStyle = [UIColor activityIndicatorViewStyle];
    
    self->_globalMsg.linkAttributes = [UIColor lightLinkAttributes];
    
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.slidingViewController.view.frame = self.view.window.bounds;

    [self->_eventsView viewDidLoad];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
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
                                             selector:@selector(statusBarFrameWillChange:)
                                                 name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [super viewDidLoad];
    [self addChildViewController:self->_eventsView];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"a" ofType:@"caf"]], &alertSound);
    
    self->_globalMsg.linkDelegate = self;
    [self->_globalMsg addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(globalMsgPressed:)]];
    
    if(!_buffersView) {
        self->_buffersView = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
        self->_buffersView.view.autoresizingMask = UIViewAutoresizingNone;
        self->_buffersView.view.translatesAutoresizingMaskIntoConstraints = NO;
        self->_buffersView.delegate = self;
    }

    if(!_usersView) {
        self->_usersView = [[UsersTableView alloc] initWithStyle:UITableViewStylePlain];
        self->_usersView.view.autoresizingMask = UIViewAutoresizingNone;
        self->_usersView.view.translatesAutoresizingMaskIntoConstraints = NO;
        self->_usersView.delegate = self;
    }
    
    if(self->_swipeTip)
        self->_swipeTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tip_bg"]];
    
    if(_2swipeTip)
        _2swipeTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tip_bg"]];
    
    if(self->_mentionTip)
        self->_mentionTip.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"tip_bg"]];
    
    self->_lock.font = [UIFont fontWithName:@"FontAwesome" size:18];

    self->_uploadsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self->_uploadsBtn.contentMode = UIViewContentModeCenter;
    self->_uploadsBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self->_uploadsBtn setImage:[[UIImage imageNamed:@"upload_arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self->_uploadsBtn addTarget:self action:@selector(uploadsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self->_uploadsBtn sizeToFit];
    self->_uploadsBtn.frame = CGRectMake(9,2,_uploadsBtn.frame.size.width + 16, _uploadsBtn.frame.size.height + 16);
    self->_uploadsBtn.accessibilityLabel = @"Uploads";
    [self->_bottomBar addSubview:self->_uploadsBtn];

    self->_sendBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self->_sendBtn.contentMode = UIViewContentModeCenter;
    self->_sendBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self->_sendBtn setTitle:@"Send" forState:UIControlStateNormal];
    [self->_sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [self->_sendBtn sizeToFit];
    self->_sendBtn.frame = CGRectMake(self->_bottomBar.frame.size.width - _sendBtn.frame.size.width - 8,4,_sendBtn.frame.size.width,_sendBtn.frame.size.height);
    [self->_sendBtn addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self->_sendBtn sizeToFit];
    self->_sendBtn.enabled = NO;
    self->_sendBtn.adjustsImageWhenHighlighted = NO;
    [self->_bottomBar addSubview:self->_sendBtn];

    self->_settingsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self->_settingsBtn.contentMode = UIViewContentModeCenter;
    self->_settingsBtn.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
    [self->_settingsBtn setImage:[[UIImage imageNamed:@"settings"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self->_settingsBtn addTarget:self action:@selector(settingsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self->_settingsBtn sizeToFit];
    self->_settingsBtn.accessibilityLabel = @"Menu";
    self->_settingsBtn.enabled = NO;
    self->_settingsBtn.alpha = 0;
    self->_settingsBtn.frame = CGRectMake(self->_bottomBar.frame.size.width - _settingsBtn.frame.size.width - 24,2,_settingsBtn.frame.size.width + 16,_settingsBtn.frame.size.height + 16);
    [self->_bottomBar addSubview:self->_settingsBtn];
    
    self.slidingViewController.shouldAllowPanningPastAnchor = NO;
    if(self.slidingViewController.underLeftViewController == nil)
        self.slidingViewController.underLeftViewController = self->_buffersView;
    if(self.slidingViewController.underRightViewController == nil)
        self.slidingViewController.underRightViewController = self->_usersView;
    self.slidingViewController.anchorLeftRevealAmount = 240;
    self.slidingViewController.anchorRightRevealAmount = 240;
    self.slidingViewController.underLeftWidthLayout = ECFixedRevealWidth;
    self.slidingViewController.underRightWidthLayout = ECFixedRevealWidth;

    self->_menuBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self->_menuBtn setImage:[[UIImage imageNamed:@"menu"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self->_menuBtn addTarget:self action:@selector(listButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self->_menuBtn.frame = CGRectMake(0,0,20,18);
    self->_menuBtn.accessibilityLabel = @"Channels list";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->_menuBtn];
    
    self->_message = [[UIExpandingTextView alloc] initWithFrame:CGRectZero];
    self->_message.delegate = self;
    self->_message.returnKeyType = UIReturnKeySend;
    self->_message.autoresizesSubviews = NO;
    self->_message.translatesAutoresizingMaskIntoConstraints = NO;
    //    _message.internalTextView.font = self->_defaultTextareaFont = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] size:FONT_SIZE];
    self->_message.internalTextView.font = self->_defaultTextareaFont = [UIFont systemFontOfSize:FONT_SIZE weight:UIFontWeightRegular];
    self->_messageWidthConstraint = [NSLayoutConstraint constraintWithItem:self->_message attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0f constant:0.0f];
    self->_messageHeightConstraint = [NSLayoutConstraint constraintWithItem:self->_message attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:1.0f constant:36.0f];
    [self->_message addConstraints:@[self->_messageWidthConstraint, _messageHeightConstraint]];

    [self->_bottomBar addSubview:self->_message];
    [self->_bottomBar addConstraints:@[
                             [NSLayoutConstraint constraintWithItem:self->_message attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self->_bottomBar attribute:NSLayoutAttributeLeading multiplier:1.0f constant:50.0f],
                             [NSLayoutConstraint constraintWithItem:self->_message attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self->_bottomBar attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-2.0f]
                             ]];
    self->_nickCompletionView = [[NickCompletionView alloc] initWithFrame:CGRectZero];
    self->_nickCompletionView.translatesAutoresizingMaskIntoConstraints = NO;
    self->_nickCompletionView.completionDelegate = self;
    self->_nickCompletionView.alpha = 0;
    [self.view addSubview:self->_nickCompletionView];
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self->_nickCompletionView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self->_eventsView.tableView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f],
                                [NSLayoutConstraint constraintWithItem:self->_nickCompletionView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self->_eventsView.tableView attribute:NSLayoutAttributeWidth multiplier:1.0f constant:-20.0f],
                                 [NSLayoutConstraint constraintWithItem:self->_nickCompletionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self->_eventsView.bottomUnreadView attribute:NSLayoutAttributeTop multiplier:1.0f constant:-6.0f]
                                 ]];

    self->_colorPickerView = [[IRCColorPickerView alloc] initWithFrame:CGRectZero];
    self->_colorPickerView.translatesAutoresizingMaskIntoConstraints = NO;
    self->_colorPickerView.delegate = self;
    self->_colorPickerView.alpha = 0;
    [self.view addSubview:self->_colorPickerView];
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self->_colorPickerView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self->_eventsView.tableView attribute:NSLayoutAttributeCenterX multiplier:1.0f constant:0.0f],
                                [NSLayoutConstraint constraintWithItem:self->_colorPickerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self->_bottomBar attribute:NSLayoutAttributeTop multiplier:1.0f constant:-2.0f]
                                ]];
    
    self->_connectingProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    [self->_connectingProgress sizeToFit];
    self->_connectingProgress.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self->_connectingProgress.frame = CGRectMake(0,self.navigationController.navigationBar.bounds.size.height - _connectingProgress.bounds.size.height,self.navigationController.navigationBar.bounds.size.width,_connectingProgress.bounds.size.height);
    [self.navigationController.navigationBar addSubview:self->_connectingProgress];
    
    self->_connectingStatus.font = [UIFont boldSystemFontOfSize:20];
    self.navigationItem.titleView = self->_titleView;
    self->_connectingProgress.hidden = YES;
    self->_connectingProgress.progress = 0;
    [UIColor setTheme];
    [self _themeChanged];
    [self connectivityChanged:nil];
    [self updateLayout];
    [self _updateEventsInsets];
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeBack:)];
    swipe.numberOfTouchesRequired = 2;
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipe];
    
    swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeForward:)];
    swipe.numberOfTouchesRequired = 2;
    swipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipe];

    if([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        __previewer = [self registerForPreviewingWithDelegate:self sourceView:self.navigationController.view];
    }
    
    [self.view addInteraction:[[UIDropInteraction alloc] initWithDelegate:self]];
    
    _leftBorder = [[UIView alloc] init];
    _leftBorder.backgroundColor = [UIColor iPadBordersColor];
    [self.navigationController.view addSubview:_leftBorder];
    _rightBorder = [[UIView alloc] init];
    _rightBorder.backgroundColor = [UIColor iPadBordersColor];
    [self.navigationController.view addSubview:_rightBorder];
    self.navigationController.view.clipsToBounds = NO;
    [self applyTheme];
}

-(BOOL)dropInteraction:(UIDropInteraction *)interaction canHandleSession:(id<UIDropSession>)session __attribute__((availability(ios,introduced=11))) {
    return session.items.count == 1 && [session hasItemsConformingToTypeIdentifiers:@[@"com.apple.DocumentManager.uti.FPItem.File", @"public.image", @"public.movie"]];
}

-(UIDropProposal *)dropInteraction:(UIDropInteraction *)interaction sessionDidUpdate:(id<UIDropSession>)session __attribute__((availability(ios,introduced=11))) {
    return [[UIDropProposal alloc] initWithDropOperation:UIDropOperationCopy];
}

-(void)dropInteraction:(UIDropInteraction *)interaction performDrop:(id<UIDropSession>)session __attribute__((availability(ios,introduced=11))) {
    NSItemProvider *i = session.items.firstObject.itemProvider;
    
    FileUploader *u = [[FileUploader alloc] init];
    u.delegate = self;
    u.bid = self->_buffer.bid;
    u.msgid = self->_msgid;
    NSString *UTI = i.registeredTypeIdentifiers.lastObject;
    u.originalFilename = i.suggestedName;
    if(![u.originalFilename containsString:@"."] && ![UTI hasPrefix:@"dyn."]) {
        u.originalFilename = [u.originalFilename stringByAppendingPathExtension:[UTI componentsSeparatedByString:@"."].lastObject];
    }
    u.mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(UTI), kUTTagClassMIMEType);
    FileMetadataViewController *fvc = [[FileMetadataViewController alloc] initWithUploader:u];
    u.metadatadelegate = fvc;
    [i loadPreviewImageWithOptions:nil completionHandler:^(UIImage *preview, NSError *error) {
        if(preview) {
            [fvc setImage:preview];
        } else if([i canLoadObjectOfClass:UIImage.class]) {
            [i loadObjectOfClass:UIImage.class completionHandler:^(UIImage *item, NSError *error) {
                if(item) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [fvc setImage:item];
                    }];
                }
            }];
        }
    }];
    
    id imageHandler = ^(UIImage *item, NSError *error) {
        if(item) {
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"IRCCloud"]) {
                CLS_LOG(@"Uploading dropped image to IRCCloud");
                [u uploadImage:item];
            } else {
                CLS_LOG(@"Uploading dropped image to imgur");
                ImageUploader *img = [[ImageUploader alloc] init];
                img.delegate = self;
                img.bid = self->_buffer.bid;
                [img upload:item];
            }
        } else {
            CLS_LOG(@"Unable to handle dropped image: %@", error);
        }
    };
    
    if([i hasItemConformingToTypeIdentifier:@"com.apple.DocumentManager.uti.FPItem.File"]) {
        if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] && [i hasItemConformingToTypeIdentifier:@"public.image"]) {
            [i loadObjectOfClass:UIImage.class completionHandler:imageHandler];
        } else {
            [i loadInPlaceFileRepresentationForTypeIdentifier:@"com.apple.DocumentManager.uti.FPItem.File" completionHandler:^(NSURL *url, BOOL isInPlace, NSError *error) {
                if(url) {
                    CLS_LOG(@"Uploading dropped file to IRCCloud");
                    [i hasItemConformingToTypeIdentifier:@"public.movie"]?[u uploadVideo:url]:[u uploadFile:url];
                } else {
                    CLS_LOG(@"Unable to handle dropped file: %@", error);
                }
            }];
        }
    } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
        [i loadInPlaceFileRepresentationForTypeIdentifier:@"public.movie" completionHandler:^(NSURL *url, BOOL isInPlace, NSError *error) {
            if(url) {
                CLS_LOG(@"Uploading dropped movie to IRCCloud");
                [u uploadVideo:url];
            } else {
                CLS_LOG(@"Unable to handle dropped movie: %@", error);
            }
        }];
    } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
        [i loadObjectOfClass:UIImage.class completionHandler:imageHandler];
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] || ![i hasItemConformingToTypeIdentifier:@"public.image"]) {
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fvc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self presentViewController:nc animated:YES completion:nil];
        }
    }];
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if(CGRectContainsPoint(self->_titleView.frame, [self->_titleView convertPoint:location fromView:self.navigationController.view])) {
        if(self->_buffer && [self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
            previewingContext.sourceRect = [self.navigationController.view convertRect:self->_titleView.frame fromView:self.navigationController.navigationBar];
            ChannelInfoViewController *c = [[ChannelInfoViewController alloc] initWithChannel:[[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            nc.navigationBarHidden = YES;
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            return nc;
        }
    }
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if([viewControllerToCommit isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:((UINavigationController *)viewControllerToCommit).topViewController];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        viewControllerToCommit = nc;
    }
    [self presentViewController:viewControllerToCommit animated:YES completion:nil];
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == self->_eventsView.topUnreadView) {
        if(![[change objectForKey:NSKeyValueChangeOldKey] isEqualToNumber:[change objectForKey:NSKeyValueChangeNewKey]])
            [self _updateEventsInsets];
    } else if(object == self->_eventsView.tableView.layer) {
        CGRect old = [[change objectForKey:NSKeyValueChangeOldKey] CGRectValue];
        CGRect new = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
        if(new.size.height > 0 && old.size.width != new.size.width) {
            [self->_eventsView clearCachedHeights];
        }
    } else {
        NSLog(@"Change: %@", change);
    }
}

- (void)swipeBack:(UISwipeGestureRecognizer *)sender {
    if(self->_buffer.lastBuffer) {
        Buffer *b = self->_buffer;
        Buffer *last = self->_buffer.lastBuffer.lastBuffer;
        [self bufferSelected:b.lastBuffer.bid];
        self->_buffer.lastBuffer = last;
        self->_buffer.nextBuffer = b;
    }
}

- (void)swipeForward:(UISwipeGestureRecognizer *)sender {
    if(self->_buffer.nextBuffer) {
        Buffer *b = self->_buffer;
        Buffer *last = self->_buffer.lastBuffer;
        Buffer *next = self->_buffer.nextBuffer;
        Buffer *nextnext = self->_buffer.nextBuffer.nextBuffer;
        [self bufferSelected:next.bid];
        self->_buffer.nextBuffer = nextnext;
        b.nextBuffer = next;
        b.lastBuffer = last;
    }
}

- (void)_updateUnreadIndicator {
    @synchronized(self->_buffer) {
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
                if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
                    if(type == 1) {
                        if(![[prefs objectForKey:@"channel-enableTrackUnread"] isKindOfClass:[NSDictionary class]] || [[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] != 1)
                            unread = 0;
                    } else {
                        if(![[prefs objectForKey:@"buffer-enableTrackUnread"] isKindOfClass:[NSDictionary class]] || [[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] != 1)
                            unread = 0;
                        if(type == 2 && (![[prefs objectForKey:@"buffer-enableTrackUnread"] isKindOfClass:[NSDictionary class]] || [[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] != 1))
                            highlights = 0;
                    }
                }
                if(buffer.bid != self->_buffer.bid) {
                    unreadCount += unread;
                    highlightCount += highlights;
                }
                if(highlightCount > 0)
                    break;
            }
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(highlightCount) {
                self->_menuBtn.tintColor = [UIColor redColor];
                self->_menuBtn.accessibilityValue = @"Unread highlights";
                self->_sceneTitleExtra = [NSString stringWithFormat:@"(%i) ", highlightCount];
            } else if(unreadCount) {
                if(![self->_menuBtn.tintColor isEqual:[UIColor unreadBlueColor]])
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"New unread messages");
                self->_menuBtn.tintColor = [UIColor unreadBlueColor];
                self->_menuBtn.accessibilityValue = @"Unread messages";
                self->_sceneTitleExtra = @"* ";
            } else {
                self->_menuBtn.tintColor = [UIColor navBarSubheadingColor];
                self->_menuBtn.accessibilityValue = nil;
                self->_sceneTitleExtra = nil;
            }
            
            [self _updateTitleArea];
        }];
    }
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Channel *c;
    Buffer *b = nil;
    IRCCloudJSONObject *o = nil;
    ChannelModeListTableViewController *cmltv = nil;
    ChannelListTableViewController *ctv = nil;
    CallerIDTableViewController *citv = nil;
    WhoListTableViewController *wtv = nil;
    NamesListTableViewController *ntv = nil;
    Event *e = nil;
    Server *s = nil;
    NSString *msg = nil;
    NSString *type = nil;
    UIAlertController *ac = nil;
    switch(event) {
        case kIRCEventSessionDeleted:
            [self bufferSelected:-1];
            [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
            break;
        case kIRCEventGlobalMsg:
            [self _updateGlobalMsg];
            break;
        case kIRCEventWhois:
        {
            if([self.presentedViewController isKindOfClass:UINavigationController.class] && [((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:WhoisViewController.class]) {
                WhoisViewController *wvc = (WhoisViewController *)(((UINavigationController *)self.presentedViewController).topViewController);
                [wvc setData:notification.object];
            } else {
                WhoisViewController *wvc = [[WhoisViewController alloc] init];
                [wvc setData:notification.object];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:wvc];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
        }
            break;
        case kIRCEventChannelTopicIs:
            o = notification.object;
            b = [[BuffersDataSource sharedInstance] getBufferWithName:[o objectForKey:@"chan"] server:o.cid];
            if(b) {
                c = [[ChannelsDataSource sharedInstance] channelForBuffer:b.bid];
            } else {
                c = [[Channel alloc] init];
                c.cid = o.cid;
                c.bid = -1;
                c.name = [o objectForKey:@"chan"];
                c.topic_author = [o objectForKey:@"author"]?[o objectForKey:@"author"]:[o objectForKey:@"server"];
                c.topic_time = [[o objectForKey:@"time"] doubleValue];
                c.topic_text = [o objectForKey:@"text"];
            }
            if(c) {
                ChannelInfoViewController *cvc = [[ChannelInfoViewController alloc] initWithChannel:c];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cvc];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationFormSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventChannelInit:
        case kIRCEventChannelTopic:
        case kIRCEventChannelMode:
            [self _updateTitleArea];
            [self _updateUserListVisibility];
            break;
        case kIRCEventBadChannelKey: {
            self->_alertObject = notification.object;
            s = [[ServersDataSource sharedInstance] getServer:self->_alertObject.cid];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self dismissKeyboard];
                [self.view.window endEditing:YES];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:[NSString stringWithFormat:@"Password for %@",[self->_alertObject objectForKey:@"chan"]] preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length)
                        [[NetworkConnection sharedInstance] join:[self->_alertObject objectForKey:@"chan"] key:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_alertObject.cid handler:^(IRCCloudJSONObject *result) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Unable to join channel: %@. Please try again shortly.", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        }];
                }]];
                
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                }];
                
                [self presentViewController:alert animated:YES completion:nil];
            }];}
            break;
        case kIRCEventAlert:
            o = notification.object;
            type = o.type;
            
            if([type isEqualToString:@"help"] || [type isEqualToString:@"stats"]) {
                TextTableViewController *tv;
                if([self.presentedViewController isKindOfClass:UINavigationController.class] && [((UINavigationController *)self.presentedViewController).viewControllers.firstObject isKindOfClass:TextTableViewController.class]) {
                    tv = ((UINavigationController *)self.presentedViewController).viewControllers.firstObject;
                    if(![tv.type isEqualToString:type])
                        tv = nil;
                }
                NSString *msg = [o objectForKey:@"parts"];
                if([[o objectForKey:@"msg"] length]) {
                    if(msg.length)
                        msg = [msg stringByAppendingFormat:@": %@", [o objectForKey:@"msg"]];
                    else
                        msg = [o objectForKey:@"msg"];
                }
                msg = [msg stringByAppendingString:@"\n"];
                if(!msg)
                    msg = @"\n";
                if(tv) {
                    [tv appendText:msg];
                } else {
                    tv = [[TextTableViewController alloc] initWithText:msg];
                    if([[o objectForKey:@"command"] length])
                        tv.navigationItem.title = [NSString stringWithFormat:@"HELP For %@", [o objectForKey:@"command"]];
                    else
                        tv.navigationItem.title = type.uppercaseString;
                    tv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                    tv.type = type;
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                        nc.modalPresentationStyle = UIModalPresentationFormSheet;
                    else
                        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                    if(self.presentedViewController)
                        [self dismissViewControllerAnimated:NO completion:nil];
                    [self presentViewController:nc animated:YES completion:nil];
                }
            } else {
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
                else if([type isEqualToString:@"unknown_command"]) {
                    NSString *m = [o objectForKey:@"msg"];
                    if(!m.length)
                        m = @"Unknown command";
                    msg = [NSString stringWithFormat:@"%@: %@", m, [o objectForKey:@"command"]];
                } else if([type isEqualToString:@"help_not_found"])
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
                    msg = [NSString stringWithFormat:@"Missing mode: %@", [o objectForKey:@"param"]];
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
                else if([type isEqualToString:@"nickname_in_use"])
                    msg = [NSString stringWithFormat:@"%@ is already in use", [o objectForKey:@"nick"]];
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
                else if([type isEqualToString:@"blocked_channel"])
                    msg = @"This channel is blocked, you have been disconnected.";
                else if([type isEqualToString:@"unknown_error"])
                    msg = [NSString stringWithFormat:@"Unknown Error [%@] %@", [o objectForKey:@"command"], [o objectForKey:@"msg"]];
                else if([type isEqualToString:@"pong"]) {
                    if([o objectForKey:@"origin"])
                        msg = [NSString stringWithFormat:@"PONG from %@: %@", [o objectForKey:@"origin"], [o objectForKey:@"msg"]];
                    else
                        msg = [NSString stringWithFormat:@"PONG: %@", [o objectForKey:@"msg"]];
                }
                else if([type isEqualToString:@"monitor_full"]) {
                    if([[o objectForKey:@"limit"] respondsToSelector:@selector(intValue)] && [[o objectForKey:@"limit"] intValue])
                        msg = [NSString stringWithFormat:@"%@: %@ (limit: %i)", [o objectForKey:@"targets"], [o objectForKey:@"msg"], [[o objectForKey:@"limit"] intValue]];
                    else
                        msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"targets"], [o objectForKey:@"msg"]];
                }
                else if([type isEqualToString:@"mlock_restricted"])
                    msg = [NSString stringWithFormat:@"%@: %@\nMLOCK: %@\nRequested mode change: %@", [o objectForKey:@"channel"], [o objectForKey:@"msg"], [o objectForKey:@"mlock"], [o objectForKey:@"mode_change"]];
                else if([type isEqualToString:@"cannot_do_cmd"]) {
                    if([o objectForKey:@"cmd"])
                        msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"cmd"], [o objectForKey:@"msg"]];
                    else
                        msg = [o objectForKey:@"msg"];
                }
                else if([type isEqualToString:@"cannot_change_chan_mode"]) {
                    if([o objectForKey:@"mode"])
                        msg = [NSString stringWithFormat:@"You can't change channel mode: %@; %@", [o objectForKey:@"mode"], [o objectForKey:@"msg"]];
                    else
                        msg = [NSString stringWithFormat:@"You can't change channel mode; %@", [o objectForKey:@"msg"]];
                }
                else if([type isEqualToString:@"metadata_limit"])
                    msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"msg"], [o objectForKey:@"target"]];
                else if([type isEqualToString:@"metadata_targetinvalid"])
                    msg = [NSString stringWithFormat:@"%@: %@", [o objectForKey:@"msg"], [o objectForKey:@"target"]];
                else if([type isEqualToString:@"metadata_nomatchingkey"])
                    msg = [NSString stringWithFormat:@"%@: %@ for target %@", [o objectForKey:@"msg"], [o objectForKey:@"key"], [o objectForKey:@"target"]];
                else if([type isEqualToString:@"metadata_keyinvalid"])
                    msg = [NSString stringWithFormat:@"Invalid metadata key: %@", [o objectForKey:@"key"]];
                else if([type isEqualToString:@"metadata_keynotset"])
                    msg = [NSString stringWithFormat:@"%@: %@ for target %@", [o objectForKey:@"msg"], [o objectForKey:@"key"], [o objectForKey:@"target"]];
                else if([type isEqualToString:@"metadata_keynopermission"])
                    msg = [NSString stringWithFormat:@"%@: %@ for target %@", [o objectForKey:@"msg"], [o objectForKey:@"key"], [o objectForKey:@"target"]];
                else if([type isEqualToString:@"metadata_toomanysubs"])
                    msg = [NSString stringWithFormat:@"Metadata key subscription limit reached, keys after and including '%@' are not subscribed", [o objectForKey:@"key"]];
                else if([[o objectForKey:@"message"] isEqualToString:@"invalid_nick"])
                    msg = @"Invalid nickname";
                else
                    msg = [o objectForKey:@"msg"];

                s = [[ServersDataSource sharedInstance] getServer:o.cid];
                if (s) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:msg preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
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
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[ChannelModeListTableViewController class]])) {
                cmltv = [[ChannelModeListTableViewController alloc] initWithList:event mode:@"b" param:@"bans" placeholder:@"No bans in effect.\n\nYou can ban someone by tapping their nickname in the user list, long-pressing a message, or by using `/ban`.\n" cid: self->_buffer.cid bid:self->_buffer.bid];
                cmltv.event = o;
                cmltv.data = [o objectForKey:@"bans"];
                cmltv.navigationItem.title = [NSString stringWithFormat:@"Bans for %@", [o objectForKey:@"channel"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cmltv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventQuietList:
            o = notification.object;
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[ChannelModeListTableViewController class]])) {
                cmltv = [[ChannelModeListTableViewController alloc] initWithList:event mode:@"q" param:@"list" placeholder:@"Empty quiet list." cid: self->_buffer.cid bid:self->_buffer.bid];
                cmltv.event = o;
                cmltv.data = [o objectForKey:@"list"];
                cmltv.navigationItem.title = [NSString stringWithFormat:@"Quiet list for %@", [o objectForKey:@"channel"]];
                cmltv.mask = @"quiet_mask";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cmltv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventInviteList:
            o = notification.object;
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[ChannelModeListTableViewController class]])) {
                cmltv = [[ChannelModeListTableViewController alloc] initWithList:event mode:@"I" param:@"list" placeholder:@"Empty invite list." cid: self->_buffer.cid bid:self->_buffer.bid];
                cmltv.event = o;
                cmltv.data = [o objectForKey:@"list"];
                cmltv.navigationItem.title = [NSString stringWithFormat:@"Invite list for %@", [o objectForKey:@"channel"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cmltv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventBanExceptionList:
            o = notification.object;
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[ChannelModeListTableViewController class]])) {
                cmltv = [[ChannelModeListTableViewController alloc] initWithList:event mode:@"e" param:@"exceptions" placeholder:@"Empty exception list." cid: self->_buffer.cid bid:self->_buffer.bid];
                cmltv.event = o;
                cmltv.data = [o objectForKey:@"exceptions"];
                cmltv.navigationItem.title = [NSString stringWithFormat:@"Exception list for %@", [o objectForKey:@"channel"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cmltv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventChanFilterList:
            o = notification.object;
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[ChannelModeListTableViewController class]])) {
                cmltv = [[ChannelModeListTableViewController alloc] initWithList:event mode:@"g" param:@"list" placeholder:@"No channel filter patterns." cid: self->_buffer.cid bid:self->_buffer.bid];
                cmltv.event = o;
                cmltv.data = [o objectForKey:@"list"];
                cmltv.mask = @"pattern";
                cmltv.navigationItem.title = [NSString stringWithFormat:@"Channel filter for %@", [o objectForKey:@"channel"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:cmltv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventListResponseFetching:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                ctv = [[ChannelListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                ctv.event = o;
                ctv.navigationItem.title = @"Channel List";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ctv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventAcceptList:
            o = notification.object;
            if(o.cid == self->_buffer.cid && (![self.presentedViewController isKindOfClass:[UINavigationController class]] || ![((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[CallerIDTableViewController class]])) {
                citv = [[CallerIDTableViewController alloc] initWithStyle:UITableViewStylePlain];
                citv.event = o;
                citv.nicks = [o objectForKey:@"nicks"];
                citv.navigationItem.title = @"Accept List";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:citv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventWhoList:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                wtv = [[WhoListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                wtv.event = o;
                wtv.navigationItem.title = [NSString stringWithFormat:@"WHO For %@", [o objectForKey:@"subject"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:wtv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventWhoSpecialResponse:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                TextTableViewController *tv = [[TextTableViewController alloc] initWithData:[o objectForKey:@"users"]];
                tv.navigationItem.title = [NSString stringWithFormat:@"WHO For %@", [o objectForKey:@"subject"]];
                tv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventModulesList:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                TextTableViewController *tv = [[TextTableViewController alloc] initWithData:[o objectForKey:@"modules"]];
                tv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                tv.navigationItem.title = [NSString stringWithFormat:@"Modules list for %@", tv.server.hostname];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventTraceResponse:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                TextTableViewController *tv = [[TextTableViewController alloc] initWithData:[o objectForKey:@"trace"]];
                tv.navigationItem.title = [NSString stringWithFormat:@"Trace for %@", [o objectForKey:@"server"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventLinksResponse:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                LinksListTableViewController *lv = [[LinksListTableViewController alloc] init];
                lv.event = o;
                lv.navigationItem.title = [o objectForKey:@"server"];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventChannelQuery:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                NSString *type = [o objectForKey:@"query_type"];
                NSString *msg = nil;
                
                if([type isEqualToString:@"mode"]) {
                    msg = [NSString stringWithFormat:@"%@ mode is %c%@%c", [o objectForKey:@"channel"], BOLD, [o objectForKey:@"diff"], CLEAR];
                } else if([type isEqualToString:@"timestamp"]) {
                    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                    msg = [NSString stringWithFormat:@"%@ created on %c%@%c", [o objectForKey:@"channel"], BOLD, [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[o objectForKey:@"timestamp"] intValue]]], CLEAR];
                } else {
                    CLS_LOG(@"Unhandled channel_query type: %@", type);
                }
                
                if(msg) {
                    if([self.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[TextTableViewController class]] && [((TextTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController)).type isEqualToString:@"channel_query"]) {
                        TextTableViewController *tv = ((TextTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController));
                        [tv appendData:@[msg]];
                    } else {
                        TextTableViewController *tv = [[TextTableViewController alloc] initWithData:@[msg]];
                        tv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                        tv.type = @"channel_query";
                        tv.navigationItem.title = tv.server.hostname;
                        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                            nc.modalPresentationStyle = UIModalPresentationFormSheet;
                        else
                            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                        if(self.presentedViewController)
                            [self dismissViewControllerAnimated:NO completion:nil];
                        [self presentViewController:nc animated:YES completion:nil];
                    }
                }
            }
            break;
        case kIRCEventTextList:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                if([self.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[TextTableViewController class]] && [((TextTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController)).type isEqualToString:@"text"]) {
                    TextTableViewController *tv = ((TextTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController));
                    [tv appendText:@"\n"];
                    [tv appendText:[o objectForKey:@"msg"]];
                } else {
                    TextTableViewController *tv = [[TextTableViewController alloc] initWithText:[o objectForKey:@"msg"]];
                    tv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                    tv.type = @"text";
                    tv.navigationItem.title = [o objectForKey:@"server"];
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                        nc.modalPresentationStyle = UIModalPresentationPageSheet;
                    else
                        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                    if(self.presentedViewController)
                        [self dismissViewControllerAnimated:NO completion:nil];
                    [self presentViewController:nc animated:YES completion:nil];
                }
            }
            break;
        case kIRCEventNamesList:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                ntv = [[NamesListTableViewController alloc] initWithStyle:UITableViewStylePlain];
                ntv.event = o;
                ntv.navigationItem.title = [NSString stringWithFormat:@"NAMES For %@", [o objectForKey:@"chan"]];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ntv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventServerMap:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                TextTableViewController *smtv = [[TextTableViewController alloc] initWithData:[o objectForKey:@"servers"]];
                smtv.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                smtv.navigationItem.title = @"Server Map";
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:smtv];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationPageSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self presentViewController:nc animated:YES completion:nil];
            }
            break;
        case kIRCEventWhoWas:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                if([self.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[WhoWasTableViewController class]]) {
                    WhoWasTableViewController *tv = ((WhoWasTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController));
                    tv.event = o;
                    [tv refresh];
                } else {
                    WhoWasTableViewController *tv = [[WhoWasTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
                    tv.event = o;
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:tv];
                    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                        nc.modalPresentationStyle = UIModalPresentationPageSheet;
                    else
                        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                    if(self.presentedViewController)
                        [self dismissViewControllerAnimated:NO completion:nil];
                    [self presentViewController:nc animated:YES completion:nil];
                }
            }
            break;
        case kIRCEventLinkChannel:
            o = notification.object;
            if(self->_cidToOpen == o.cid && [[o objectForKey:@"invalid_chan"] isKindOfClass:[NSString class]] && [[[o objectForKey:@"invalid_chan"] lowercaseString] isEqualToString:[self->_bufferToOpen lowercaseString]]) {
                if([[o objectForKey:@"valid_chan"] isKindOfClass:[NSString class]] && [[o objectForKey:@"valid_chan"] length]) {
                    self->_bufferToOpen = [o objectForKey:@"valid_chan"];
                    b = [[BuffersDataSource sharedInstance] getBuffer:o.bid];
                }
            } else {
                self->_cidToOpen = o.cid;
                self->_bufferToOpen = nil;
            }
            if(!b)
                break;
        case kIRCEventMakeBuffer:
            if(!b)
                b = notification.object;
            if(self->_cidToOpen == b.cid && [[b.name lowercaseString] isEqualToString:[self->_bufferToOpen lowercaseString]] && ![[self->_buffer.name lowercaseString] isEqualToString:[self->_bufferToOpen lowercaseString]]) {
                [self bufferSelected:b.bid];
                self->_bufferToOpen = nil;
                self->_cidToOpen = -1;
            } else if(self->_buffer.bid == -1 && b.cid == self->_buffer.cid && [b.name isEqualToString:self->_buffer.name]) {
                [self bufferSelected:b.bid];
                self->_bufferToOpen = nil;
                self->_cidToOpen = -1;
            } else if(self->_cidToOpen == b.cid && _bufferToOpen == nil) {
                [self bufferSelected:b.bid];
            }
            break;
        case kIRCEventOpenBuffer:
            o = notification.object;
            b = [[BuffersDataSource sharedInstance] getBufferWithName:[o objectForKey:@"name"] server:o.cid];
            if(!b) {
                self->_bufferToOpen = [o objectForKey:@"name"];
                self->_cidToOpen = o.cid;
            } else if (b != self->_buffer) {
                [self bufferSelected:b.bid];
            }
            break;
        case kIRCEventUserInfo:
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [ColorFormatter loadFonts];
                [self _themeChanged];
            }];
        }
        case kIRCEventPart:
        case kIRCEventKick:
            [self _updateTitleArea];
            [self _updateUserListVisibility];
            break;
        case kIRCEventAuthFailure:
            [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(logout) withObject:nil waitUntilDone:YES];
            [self bufferSelected:-1];
            [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
            break;
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.bid == self->_buffer.bid) {
                if(e.isHighlight) {
                    [self showMentionTip];
                }
                if(!e.isSelf && !_buffer.scrolledUp && !self.view.accessibilityElementsHidden) {
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
                    Ignore *ignore = s.ignore;
                    if(e.ignoreMask && [ignore match:e.ignoreMask])
                        break;
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
                    if((e.isHighlight || [b.type isEqualToString:@"conversation"]) && !muted) {
                        self->_menuBtn.tintColor = [UIColor redColor];
                        self->_menuBtn.accessibilityValue = @"Unread highlights";
                        if (@available(iOS 14.0, *)) {
                            if([NSProcessInfo processInfo].macCatalystApp) {
                                [self _updateUnreadIndicator];
                            }
                        }
                    } else if(self->_menuBtn.accessibilityValue == nil) {
                        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
                        if([b.type isEqualToString:@"channel"]) {
                            if([[prefs objectForKey:@"channel-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                                break;
                        } else {
                            if([[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                                break;
                        }
                        if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
                            if([b.type isEqualToString:@"channel"]) {
                                if(![[prefs objectForKey:@"channel-enableTrackUnread"] isKindOfClass:[NSDictionary class]] || [[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] != 1)
                                    break;
                            } else {
                                if(![[prefs objectForKey:@"buffer-enableTrackUnread"] isKindOfClass:[NSDictionary class]] || [[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] != 1)
                                    break;
                            }
                        }
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"New unread messages");
                        self->_menuBtn.tintColor = [UIColor unreadBlueColor];
                        self->_menuBtn.accessibilityValue = @"Unread messages";
                        if (@available(iOS 14.0, *)) {
                            if([NSProcessInfo processInfo].macCatalystApp) {
                                self->_sceneTitleExtra = @"* ";
                                [self _updateTitleArea];
                            }
                        }
                    }
                }
            }
            if([[e.from lowercaseString] isEqualToString:[[[BuffersDataSource sharedInstance] getBuffer:e.bid].name lowercaseString]]) {
                for(Event *ev in [self->_pendingEvents copy]) {
                    if(ev.bid == e.bid) {
                        if(ev.expirationTimer && [ev.expirationTimer isValid])
                            [ev.expirationTimer invalidate];
                        ev.expirationTimer = nil;
                        [self->_pendingEvents removeObject:ev];
                        [[EventsDataSource sharedInstance] removeEvent:ev.eid buffer:ev.bid];
                    }
                }
            } else {
                int reqid = e.reqId;
                if(e.reqId > 0)
                    CLS_LOG(@"Removing expiration timer for reqid %i", e.reqId);
                for(Event *e in _pendingEvents) {
                    if(e.reqId == reqid) {
                        if(e.expirationTimer && [e.expirationTimer isValid])
                            [e.expirationTimer invalidate];
                        e.expirationTimer = nil;
                        [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
                        [self->_pendingEvents removeObject:e];
                        break;
                    }
                }
            }
            b = [[BuffersDataSource sharedInstance] getBuffer:e.bid];
            if(b && !b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0 && [[EventsDataSource sharedInstance] sizeOfBuffer:b.bid] > 200 && [self->_eventsView.tableView numberOfRowsInSection:0] > 100) {
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
                if(b.bid == self->_buffer.bid) {
                    if(b.last_seen_eid < e.eid)
                        b.last_seen_eid = e.eid;
                    [[ImageCache sharedInstance] clear];
                    [self->_eventsView refresh];
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
                    if([bid intValue] != self->_buffer.bid) {
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
            if(o.bid == self->_buffer.bid && ![self->_buffer.type isEqualToString:@"console"]) {
                if(self->_buffer && _buffer.lastBuffer && [[BuffersDataSource sharedInstance] getBuffer:self->_buffer.lastBuffer.bid])
                    [self bufferSelected:self->_buffer.lastBuffer.bid];
                else if([[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] && [[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]])
                    [self bufferSelected:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]];
                else
                    [self bufferSelected:[[BuffersDataSource sharedInstance] mostRecentBid]];
            }
            [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
            break;
        case kIRCEventConnectionDeleted:
            o = notification.object;
            if(o.cid == self->_buffer.cid) {
                if(self->_buffer && _buffer.lastBuffer) {
                    [self bufferSelected:self->_buffer.lastBuffer.bid];
                } else if([[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] && [[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]]) {
                    [self bufferSelected:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]];
                } else if([[ServersDataSource sharedInstance] count]) {
                    [self bufferSelected:[[BuffersDataSource sharedInstance] mostRecentBid]];
                } else {
                    [self bufferSelected:-1];
                    [(AppDelegate *)[UIApplication sharedApplication].delegate showConnectionView];
                }
            }
            [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
            break;
        case kIRCEventLogExportFinished:
            o = notification.object;
            if([o objectForKey:@"export"]) {
                NSDictionary *export = [o objectForKey:@"export"];
                Server *s = ![[export objectForKey:@"cid"] isKindOfClass:[NSNull class]] ? [[ServersDataSource sharedInstance] getServer:[[export objectForKey:@"cid"] intValue]] : nil;
                Buffer *b = ![[export objectForKey:@"bid"] isKindOfClass:[NSNull class]] ? [[BuffersDataSource sharedInstance] getBuffer:[[export objectForKey:@"bid"] intValue]] : nil;
                
                NSString *serverName = s ? (s.name.length ? s.name : s.hostname) : [NSString stringWithFormat:@"Unknown Network (%@)", [export objectForKey:@"cid"]];
                NSString *bufferName = b ? b.name : [NSString stringWithFormat:@"Unknown Log (%@)", [export objectForKey:@"bid"]];
                
                NSString *msg = @"Your log export is ready for download";
                if(![[export objectForKey:@"bid"] isKindOfClass:[NSNull class]])
                    msg = [NSString stringWithFormat:@"Logs for %@: %@ are ready for download", serverName, bufferName];
                else if(![[export objectForKey:@"cid"] isKindOfClass:[NSNull class]])
                    msg = [NSString stringWithFormat:@"Logs for %@ are ready for download", serverName];

                ac = [UIAlertController alertControllerWithTitle:@"Export Finished" message:msg preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                [ac addAction:[UIAlertAction actionWithTitle:@"Download" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [self launchURL:[NSURL URLWithString:[export objectForKey:@"redirect_url"]]];
                }]];
                
                [self presentViewController:ac animated:YES completion:nil];
            }
            break;
        default:
            break;
    }
}

-(void)_showConnectingView {
    self.navigationItem.titleView = self->_connectingView;
}

-(void)_hideConnectingView {
    self.navigationItem.titleView = self->_titleView;
    self->_connectingProgress.hidden = YES;
}

-(void)connectivityChanged:(NSNotification *)notification {
    self->_connectingStatus.textColor = [UIColor navBarHeadingColor];
    UIColor *c = ([NetworkConnection sharedInstance].state == kIRCCloudStateConnected)?([UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor unreadBlueColor]):[UIColor textareaBackgroundColor];
    [self->_sendBtn setTitleColor:c forState:UIControlStateNormal];
    [self->_sendBtn setTitleColor:c forState:UIControlStateDisabled];
    [self->_sendBtn setTitleColor:c forState:UIControlStateHighlighted];
    
    switch([NetworkConnection sharedInstance].state) {
        case kIRCCloudStateConnecting:
            [self _showConnectingView];
            self->_connectingStatus.text = @"Connecting";
            self->_connectingProgress.progress = 0;
            self->_connectingProgress.hidden = YES;
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Connecting");
            break;
        case kIRCCloudStateDisconnected:
            [self _showConnectingView];
            if([NetworkConnection sharedInstance].reconnectTimestamp > 0) {
                int seconds = (int)([NetworkConnection sharedInstance].reconnectTimestamp - [[NSDate date] timeIntervalSince1970]) + 1;
                if(seconds < 0) {
                    seconds = 0;
                    if([NetworkConnection sharedInstance].session.length && [NetworkConnection shouldReconnect]) {
                        CLS_LOG(@"Reconnect timestamp in the past, reconnecting");
                        [[NetworkConnection sharedInstance] connect:NO];
                    } else {
                        CLS_LOG(@"Reconnect timestamp in the past but app is in the background");
                    }
                }
                [self->_connectingStatus setText:[NSString stringWithFormat:@"Reconnecting in 0:%02i", seconds]];
                self->_connectingProgress.progress = 0;
                self->_connectingProgress.hidden = YES;
                [self performSelector:@selector(connectivityChanged:) withObject:nil afterDelay:1];
            } else {
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Disconnected");
                if([[NetworkConnection sharedInstance] reachable] == kIRCCloudReachable) {
                    self->_connectingStatus.text = @"Disconnected";
                    if([NetworkConnection sharedInstance].session.length && [NetworkConnection shouldReconnect]) {
                        CLS_LOG(@"I'm disconnected but IRCCloud is reachable, reconnecting");
                        [[NetworkConnection sharedInstance] connect:NO];
                    }
                } else {
                    self->_connectingStatus.text = @"Offline";
                }
                self->_connectingProgress.progress = 0;
                self->_connectingProgress.hidden = YES;
            }
            break;
        case kIRCCloudStateConnected:
            for(Event *e in [self->_pendingEvents copy]) {
                if(e.reqId == -1 && (([[NSDate date] timeIntervalSince1970] - (e.eid/1000000) - [NetworkConnection sharedInstance].clockOffset) < 60)) {
                    [e.expirationTimer invalidate];
                    e.expirationTimer = nil;
                    e.reqId = [[NetworkConnection sharedInstance] say:e.command to:e.to cid:e.cid handler:^(IRCCloudJSONObject *result) {
                        if(![[result objectForKey:@"success"] boolValue]) {
                            [self->_pendingEvents removeObject:e];
                            e.height = 0;
                            e.pending = NO;
                            e.rowType = ROW_FAILED;
                            e.color = [UIColor networkErrorColor];
                            e.bgColor = [UIColor errorBackgroundColor];
                            [e.expirationTimer invalidate];
                            e.expirationTimer = nil;
                            [self->_eventsView reloadData];
                        }
                    }];
                    if(e.reqId < 0)
                        e.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:e repeats:NO];
                } else {
                    [self->_pendingEvents removeObject:e];
                    e.height = 0;
                    e.pending = NO;
                    e.rowType = ROW_FAILED;
                    e.color = [UIColor networkErrorColor];
                    e.bgColor = [UIColor errorBackgroundColor];
                    [e.expirationTimer invalidate];
                    e.expirationTimer = nil;
                }
            }
            break;
    }
}

-(void)backlogStarted:(NSNotification *)notification {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(!self->_connectingView.hidden) {
                self->_connectingStatus.textColor = [UIColor navBarHeadingColor];
                [self->_connectingStatus setText:@"Loading"];
                self->_connectingProgress.progress = 0;
                self->_connectingProgress.hidden = NO;
            }
        }];
}

-(void)backlogProgress:(NSNotification *)notification {
    if(!_connectingView.hidden) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_connectingProgress setProgress:[notification.object floatValue] animated:YES];
        }];
    }
}

-(void)backlogCompleted:(NSNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([notification.object bid] == -1) {
          [self _themeChanged];
            if(!((AppDelegate *)([UIApplication sharedApplication].delegate)).movedToBackground && [NetworkConnection sharedInstance].ready && ![NetworkConnection sharedInstance].notifier && [ServersDataSource sharedInstance].count < 1) {
                [(AppDelegate *)([UIApplication sharedApplication].delegate) showConnectionView];
                return;
            }
        }
        [self _hideConnectingView];
        if(self->_buffer && !self->_urlToOpen && self->_bidToOpen < 1 && self->_eidToOpen < 1 && self->_cidToOpen < 1 && [[BuffersDataSource sharedInstance] getBuffer:self->_buffer.bid]) {
            [self _updateTitleArea];
            [self _updateServerStatus];
            [self _updateUserListVisibility];
            [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
            [self _updateGlobalMsg];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self->_eventsView name:kIRCCloudBacklogCompletedNotification object:nil];
            int bid = [self _lastSelectedBid];
            if(self->_bidToOpen > 0) {
                CLS_LOG(@"backlog complete: BID to open: %i", self->_bidToOpen);
                bid = self->_bidToOpen;
                self->_bidToOpen = -1;
            } else if(self->_eidToOpen > 0) {
                bid = self->_buffer.bid;
            } else if(self->_cidToOpen > 0 && self->_bufferToOpen) {
                Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:self->_bufferToOpen server:self->_cidToOpen];
                if(b) {
                    bid = b.bid;
                    self->_cidToOpen = -1;
                    self->_bufferToOpen = nil;
                }
            }
            [self bufferSelected:bid];
            self->_eidToOpen = -1;
            if(self->_urlToOpen)
                [self launchURL:self->_urlToOpen];
            [[NSNotificationCenter defaultCenter] addObserver:self->_eventsView selector:@selector(backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];
        }
    }];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    if (@available(iOS 13.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp) {
            self->_kbSize = CGSizeMake(0,0);
            return;
        }
    }
    if(self->_eventsView.topUnreadView.observationInfo) {
        @try {
            [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
        } @catch(id anException) {
            //Not registered yet
        }
    }
    CGSize size = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil].size;
    int height = size.height;
    
    CGPoint origin = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin;
    height = [UIScreen mainScreen].bounds.size.height - origin.y;
    height -= self.slidingViewController.view.safeAreaInsets.bottom / 2;
    if(height != self->_kbSize.height) {
        self->_kbSize = size;
        self->_kbSize.height = height;

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];

        [self updateLayout];
        
        [UIView commitAnimations];
        [self expandingTextViewDidChange:self->_message];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_buffersView scrollViewDidScroll:self->_buffersView.tableView];
        }];
    }
    [self->_eventsView.tableView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

-(void)_observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    if(self->_eventsView.topUnreadView.observationInfo) {
        @try {
            [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
        } @catch(id anException) {
            //Not registered yet
        }
    }
    self->_kbSize = CGSizeMake(0,0);
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];

    [self.slidingViewController updateUnderLeftLayout];
    [self.slidingViewController updateUnderRightLayout];
    [self updateLayout];

    [self->_buffersView scrollViewDidScroll:self->_buffersView.tableView];
    self->_nickCompletionView.alpha = 0;
    self->_updateSuggestionsTask.atMention = NO;
    [UIView commitAnimations];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self->_eventsView.tableView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
}

- (int)_lastSelectedBid {
    int bid = [BuffersDataSource sharedInstance].mostRecentBid;
    
    if(self->_buffer && self->_buffer.lastBuffer && [[BuffersDataSource sharedInstance] getBuffer:self->_buffer.lastBuffer.bid]) {
        bid = self->_buffer.lastBuffer.bid;
    } else if([[NSUserDefaults standardUserDefaults] objectForKey:@"last_selected_bid"] && [[BuffersDataSource sharedInstance] getBuffer:[[[NSUserDefaults standardUserDefaults] objectForKey:@"last_selected_bid"] intValue]]) {
        bid = [[[NSUserDefaults standardUserDefaults] objectForKey:@"last_selected_bid"] intValue];
    } else if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] &&
              [[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]]) {
            bid = [[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue];
    }
    return bid;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self->_ignoreVisibilityChanges)
        return;
    [UIColor setCurrentTraits:self.traitCollection];
    [UIColor setTheme];
    if(![self->_currentTheme isEqualToString:[UIColor currentTheme]]) {
        CLS_LOG(@"Switched from %@ to %@", self->_currentTheme, [UIColor currentTheme]);
        [self applyTheme];
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [ColorFormatter loadFonts];
        }
        [[EventsDataSource sharedInstance] reformat];
        [[AvatarsDataSource sharedInstance] clear];
        
        [self->_eventsView clearRowCache];
        [self->_eventsView refresh];
    }
    self->_isShowingPreview = NO;
    [self->_eventsView viewWillAppear:animated];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    for(Event *e in [self->_pendingEvents copy]) {
        if(e.reqId != -1) {
            [self->_pendingEvents removeObject:e];
            [[EventsDataSource sharedInstance] removeEvent:e.eid buffer:e.bid];
        }
    }
    [[EventsDataSource sharedInstance] clearPendingAndFailed];
    if(!_buffer || ![[BuffersDataSource sharedInstance] getBuffer:self->_buffer.bid]) {
        int bid = [self _lastSelectedBid];
        if(self->_bidToOpen > 0) {
            CLS_LOG(@"viewwillappear: BID to open: %i", _bidToOpen);
            bid = self->_bidToOpen;
        }
        [self bufferSelected:bid];
        if(self->_urlToOpen) {
            [self launchURL:self->_urlToOpen];
        }
    } else {
        [self bufferSelected:self->_buffer.bid];
    }
    if(!self.presentedViewController) {
        self.navigationController.navigationBar.translucent = NO;
        self.edgesForExtendedLayout=UIRectEdgeNone;
    }
    self.navigationController.navigationBar.clipsToBounds = YES;
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
    [self.slidingViewController resetTopView];
    
    NSString *session = [NetworkConnection sharedInstance].session;
#ifdef DEBUG
    if(![[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
#endif
    if(session.length) {
        if(@available(iOS 12, *)) {
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge + UNAuthorizationOptionProvidesAppNotificationSettings) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(!granted)
                    CLS_LOG(@"Notification permission denied: %@", error);
            }];
        } else {
            UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
            
            [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                if(!granted)
                    CLS_LOG(@"Notification permission denied: %@", error);
            }];
        }
#ifdef DEBUG
        CLS_LOG(@"This is a debug build, skipping APNs registration");
#else
        CLS_LOG(@"APNs registration");
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    }
#ifdef DEBUG
    }
#endif
    if([NetworkConnection shouldReconnect] && [NetworkConnection sharedInstance].state != kIRCCloudStateConnected && [NetworkConnection sharedInstance].state != kIRCCloudStateConnecting && session != nil && [session length] > 0) {
        [[NetworkConnection sharedInstance] connect:NO];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_message.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_message.internalTextView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    
    self.slidingViewController.view.autoresizesSubviews = NO;
    [self updateLayout];
    
    self->_buffersView.tableView.scrollsToTop = YES;
    self->_usersView.tableView.scrollsToTop = YES;
    if(self->_eventsView.topUnreadView.observationInfo) {
        @try {
            [self->_eventsView.topUnreadView removeObserver:self forKeyPath:@"alpha"];
            [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
        } @catch(id anException) {
            //Not registered yet
        }
    }
    [self->_eventsView.topUnreadView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self->_eventsView.tableView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    
    if (@available(iOS 14.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp) {
            [[UIMenuSystem mainSystem] setNeedsRebuild];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if(self->_ignoreVisibilityChanges)
        return;
    [self->_eventsView viewWillDisappear:animated];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [self.navigationController.view removeGestureRecognizer:self.slidingViewController.panGesture];
    [self->_doubleTapTimer invalidate];
    self->_doubleTapTimer = nil;
    self->_eidToOpen = -1;
    
    self.slidingViewController.view.autoresizesSubviews = YES;
    [self.slidingViewController resetTopView];
    
    self->_buffersView.tableView.scrollsToTop = NO;
    self->_usersView.tableView.scrollsToTop = NO;

    if(self->_eventsView.topUnreadView.observationInfo) {
        @try {
            [self->_eventsView.topUnreadView removeObserver:self forKeyPath:@"alpha"];
            [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
        } @catch(id anException) {
            //Not registered yet
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self->_eventsView viewDidAppear:animated];
    [self updateLayout];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _titleLabel);
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    self.slidingViewController.view.autoresizesSubviews = NO;
    if([FIROptions defaultOptions])
        [FIRAnalytics logEventWithName:kFIREventScreenView parameters:@{kFIRParameterScreenName:NSStringFromClass(self.class)}];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    CLS_LOG(@"Received low memory warning, cleaning up backlog");
    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
        if(b != self->_buffer && !b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
            [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:50];
    }
    if(!_buffer.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:self->_buffer.bid lastSeenEid:self->_buffer.last_seen_eid type:self->_buffer.type] == 0) {
        [[EventsDataSource sharedInstance] pruneEventsForBuffer:self->_buffer.bid maxSize:100];
        [self->_eventsView setBuffer:self->_buffer];
    }
    [[ImageCache sharedInstance] clear];
}

-(IBAction)serverStatusBarPressed:(id)sender {
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    if(s) {
        if([s.status isEqualToString:@"disconnected"])
            [[NetworkConnection sharedInstance] reconnect:self->_buffer.cid handler:nil];
        else if([s.away isKindOfClass:[NSString class]] && s.away.length) {
            [[NetworkConnection sharedInstance] back:self->_buffer.cid handler:nil];
            s.away = @"";
            [self _updateServerStatus];
        }
    }
}

-(void)sendButtonPressed:(id)sender {
    @synchronized(self->_message) {
        if(self->_message.text && _message.text.length) {
            id k = ((id (*)(id, SEL)) objc_msgSend)(NSClassFromString(@"UIKeyboard"), NSSelectorFromString(@"activeKeyboard"));
            SEL sel = NSSelectorFromString(@"acceptAutocorrection");
            if([k respondsToSelector:sel]) {
                ((id (*)(id, SEL)) objc_msgSend)(k, sel);
            }
            
            NSAttributedString *messageText = self->_message.attributedText;
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"clearFormattingAfterSending"]) {
                [self resetColors];
                if(self->_defaultTextareaFont) {
                    self->_message.internalTextView.font = self->_defaultTextareaFont;
                    self->_message.internalTextView.textColor = [UIColor textareaTextColor];
                    self->_message.internalTextView.typingAttributes = @{NSForegroundColorAttributeName:[UIColor textareaTextColor], NSFontAttributeName:self->_defaultTextareaFont };
                }
            }
            
            if(messageText.length > 1 && [messageText.string hasSuffix:@" "])
                messageText = [messageText attributedSubstringFromRange:NSMakeRange(0, messageText.length - 1)];

            NSString *messageString = messageText.string;
            
            Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
            if(s) {
                if([messageString isEqualToString:@"/ignore"]) {
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    IgnoresTableViewController *itv = [[IgnoresTableViewController alloc] initWithStyle:UITableViewStylePlain];
                    itv.ignores = s.ignores;
                    itv.cid = s.cid;
                    itv.navigationItem.title = @"Ignore List";
                    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:itv];
                    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                        nc.modalPresentationStyle = UIModalPresentationPageSheet;
                    else
                        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                    [self presentViewController:nc animated:YES completion:nil];
                    return;
                } else if([messageString isEqualToString:@"/clear"]) {
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    [[EventsDataSource sharedInstance] removeEventsForBuffer:self->_buffer.bid];
                    [self->_eventsView refresh];
                    self->_eventsView.shouldAutoFetch = NO;
                    return;
#ifndef APPSTORE
                } else if([messageString isEqualToString:@"/crash"]) {
                    CLS_LOG(@"/crash requested");
                    assert(NO);
                } else if([messageString isEqualToString:@"/compact 1"]) {
                    CLS_LOG(@"Set compact");
                    NSMutableDictionary *p = [[NetworkConnection sharedInstance] prefs].mutableCopy;
                    [p setObject:@YES forKey:@"ascii-compact"];
                    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                    NSString *json = [writer stringWithObject:p];
                    [[NetworkConnection sharedInstance] setPrefs:json handler:nil];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
                } else if([messageString isEqualToString:@"/compact 0"]) {
                    NSMutableDictionary *p = [[NetworkConnection sharedInstance] prefs].mutableCopy;
                    [p setObject:@NO forKey:@"ascii-compact"];
                    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                    NSString *json = [writer stringWithObject:p];
                    [[NetworkConnection sharedInstance] setPrefs:json handler:nil];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
                } else if([messageString isEqualToString:@"/mono 1"]) {
                    CLS_LOG(@"Set monospace");
                    NSMutableDictionary *p = [[NetworkConnection sharedInstance] prefs].mutableCopy;
                    [p setObject:@"mono" forKey:@"font"];
                    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                    NSString *json = [writer stringWithObject:p];
                    [[NetworkConnection sharedInstance] setPrefs:json handler:nil];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
                } else if([messageString isEqualToString:@"/mono 0"]) {
                    NSMutableDictionary *p = [[NetworkConnection sharedInstance] prefs].mutableCopy;
                    [p setObject:@"sans" forKey:@"font"];
                    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                    NSString *json = [writer stringWithObject:p];
                    [[NetworkConnection sharedInstance] setPrefs:json handler:nil];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
                } else if([messageString hasPrefix:@"/fontsize "]) {
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:
                                                                      MIN(FONT_MAX, MAX(FONT_MIN, ceilf([[messageString substringFromIndex:10] intValue])))
                                                                      ]
                                                              forKey:@"fontSize"];
                    if([ColorFormatter shouldClearFontCache]) {
                        [ColorFormatter clearFontCache];
                        [ColorFormatter loadFonts];
                    }
                    [[EventsDataSource sharedInstance] clearFormattingCache];
                    [[AvatarsDataSource sharedInstance] clear];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kIRCCloudEventNotification object:nil userInfo:@{kIRCCloudEventKey:[NSNumber numberWithInt:kIRCEventUserInfo]}];
                    }];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
                } else if([messageString isEqualToString:@"/read"]) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:self->_eventsView.YUNoHeartbeat preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    return;
#endif
                } else if(messageString.length > 1080 || [messageString isEqualToString:@"/paste"] || [messageString hasPrefix:@"/paste "] || [messageString rangeOfString:@"\n"].location < messageString.length - 1) {
                    BOOL prompt = YES;
                    if([[[[NetworkConnection sharedInstance] prefs] objectForKey:@"pastebin-disableprompt"] isKindOfClass:[NSNumber class]]) {
                        prompt = ![[[[NetworkConnection sharedInstance] prefs] objectForKey:@"pastebin-disableprompt"] boolValue];
                    } else {
                        prompt = YES;
                    }

                    if(prompt || [messageString isEqualToString:@"/paste"] || [messageString hasPrefix:@"/paste "]) {
                        if([messageString isEqualToString:@"/paste"])
                           [self->_message clearText];
                        else if([messageString hasPrefix:@"/paste "])
                            messageString = [messageString substringFromIndex:7];
                        self->_buffer.draft = messageString;
                        PastebinEditorViewController *pv = [[PastebinEditorViewController alloc] initWithBuffer:self->_buffer];
                        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pv];
                        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                            nc.modalPresentationStyle = UIModalPresentationPageSheet;
                        else
                            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                        if(self.presentedViewController)
                            [self dismissViewControllerAnimated:NO completion:nil];
                        [self presentViewController:nc animated:YES completion:nil];
                        return;
                    }
#ifndef APPSTORE
                } else if([messageString isEqualToString:@"/buffers"]) {
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    NSMutableString *msg = [[NSMutableString alloc] init];
                    [msg appendString:@"=== Buffers ===\n"];
                    NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffersForServer:self->_buffer.cid];
                    for(Buffer *buffer in buffers) {
                        [msg appendFormat:@"CID: %i BID: %i Name: %@ lastSeenEID: %f unread: %i highlight: %i extra: %i\n", buffer.cid, buffer.bid, buffer.name, buffer.last_seen_eid, [[EventsDataSource sharedInstance] unreadStateForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type], [[EventsDataSource sharedInstance] highlightCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type], buffer.extraHighlights];
                        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:buffer.bid];
                        Event *e = [events firstObject];
                        [msg appendFormat:@"First event: %f %@\n", e.eid, e.type];
                        e = [events lastObject];
                        [msg appendFormat:@"Last event: %f %@\n", e.eid, e.type];
                        [msg appendString:@"======\n"];
                    }
                    
                    CLS_LOG(@"%@", msg);
                    
                    Event *e = [[Event alloc] init];
                    e.cid = s.cid;
                    e.bid = self->_buffer.bid;
                    e.eid = [[NSDate date] timeIntervalSince1970] * 1000000;
                    if(e.eid < [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid])
                        e.eid = [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid] + 1000;
                    e.isSelf = YES;
                    e.from = nil;
                    e.nick = nil;
                    e.msg = msg;
                    e.type = @"buffer_msg";
                    e.color = [UIColor timestampColor];
                    if([self->_buffer.name isEqualToString:s.nick])
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
                    [self->_eventsView scrollToBottom];
                    [[EventsDataSource sharedInstance] addEvent:e];
                    [self->_eventsView insertEvent:e backlog:NO nextIsGrouped:NO];
                    return;
#endif
                } else if([messageString isEqualToString:@"/badge"]) {
                    [self->_message clearText];
                    self->_buffer.draft = nil;
                    [[UNUserNotificationCenter currentNotificationCenter] getDeliveredNotificationsWithCompletionHandler:^(NSArray *notifications) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            NSMutableString *msg = [[NSMutableString alloc] init];
                            [msg appendFormat:@"Notification Center currently has %lu notifications\n", (unsigned long)notifications.count];
                            for(UNNotification *n in notifications) {
                                NSArray *d = [n.request.content.userInfo objectForKey:@"d"];
                                [msg appendFormat:@"ID: %@ BID: %i EID: %f\n", n.request.identifier, [[d objectAtIndex:1] intValue], [[d objectAtIndex:2] doubleValue]];
                            }
                            
                            for(UNNotification *n in notifications) {
                                NSArray *d = [n.request.content.userInfo objectForKey:@"d"];
                                Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[d objectAtIndex:1] intValue]];
                                [msg appendFormat:@"BID %i last_seen_eid: %f extraHighlights: %i\n", b.bid, b.last_seen_eid, b.extraHighlights];
                                if((!b && [NetworkConnection sharedInstance].state == kIRCCloudStateConnected && [NetworkConnection sharedInstance].ready) || [[d objectAtIndex:2] doubleValue] <= b.last_seen_eid) {
                                    [msg appendFormat:@"Stale notification: %@\n", n.request.identifier];
                                }
                            }
                            
                            CLS_LOG(@"%@", msg);
                            
                            Event *e = [[Event alloc] init];
                            e.cid = s.cid;
                            e.bid = self->_buffer.bid;
                            e.eid = [[NSDate date] timeIntervalSince1970] * 1000000;
                            if(e.eid < [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid])
                                e.eid = [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid] + 1000;
                            e.isSelf = YES;
                            e.from = nil;
                            e.nick = nil;
                            e.msg = msg;
                            e.type = @"buffer_msg";
                            e.color = [UIColor timestampColor];
                            if([self->_buffer.name isEqualToString:s.nick])
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
                            [self->_eventsView scrollToBottom];
                            [[EventsDataSource sharedInstance] addEvent:e];
                            [self->_eventsView insertEvent:e backlog:NO nextIsGrouped:NO];
                        }];
                    }];
                    return;
                }
                
                User *u = [[UsersDataSource sharedInstance] getUser:s.nick cid:s.cid bid:self->_buffer.bid];
                Event *e = [[Event alloc] init];
                NSMutableString *msg = messageString.mutableCopy;
                NSMutableString *formattedMsg = s.isSlack?messageString.mutableCopy:[ColorFormatter toIRC:messageText].mutableCopy;
                
                BOOL disableConvert = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"emoji-disableconvert"] boolValue];
                if(!disableConvert)
                    [ColorFormatter emojify:formattedMsg];
                
                if([msg hasPrefix:@"//"])
                    [msg deleteCharactersInRange:NSMakeRange(0, 1)];
                else if([msg hasPrefix:@"/"] && ![[msg lowercaseString] hasPrefix:@"/me "])
                    msg = nil;
                if(msg) {
                    e.cid = s.cid;
                    e.bid = self->_buffer.bid;
                    e.eid = ([[NSDate date] timeIntervalSince1970] + [NetworkConnection sharedInstance].clockOffset) * 1000000;
                    if(e.eid < [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid])
                        e.eid = [[EventsDataSource sharedInstance] lastEidForBuffer:e.bid] + 1000;
                    e.isSelf = YES;
                    e.from = s.from;
                    e.nick = s.nick;
                    e.fromNick = s.nick;
                    e.avatar = s.avatar;
                    e.avatarURL = s.avatarURL;
                    e.hostmask = s.usermask;
                    if(u)
                        e.fromMode = u.mode;
                    e.msg = formattedMsg;
                    if(msg && [[msg lowercaseString] hasPrefix:@"/me "]) {
                        e.type = @"buffer_me_msg";
                        e.msg = [formattedMsg substringFromIndex:4];
                    } else {
                        e.type = @"buffer_msg";
                    }
                    e.color = [UIColor timestampColor];
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
                    e.realname = s.server_realname;
                    [[EventsDataSource sharedInstance] addEvent:e];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
#ifndef APPSTORE
                        CLS_LOG(@"Scrolling down after sending a message");
#endif
                        [self->_eventsView scrollToBottom];
                        [self->_eventsView insertEvent:e backlog:NO nextIsGrouped:NO];
                    }];
                }
                e.to = self->_buffer.name;
                e.command = formattedMsg;
                if(e.msg)
                    [self->_pendingEvents addObject:e];
                [self->_message clearText];
                self->_buffer.draft = nil;
                msg = e.command.mutableCopy;
                if(!disableConvert)
                    [ColorFormatter emojify:msg];
                if(self->_msgid) {
                    e.isReply = YES;
                    e.entities = @{@"reply":self->_msgid};
                    e.reqId = [[NetworkConnection sharedInstance] reply:msg to:self->_buffer.name cid:self->_buffer.cid msgid:self->_msgid handler:^(IRCCloudJSONObject *result) {
                        if(![[result objectForKey:@"success"] boolValue]) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self->_pendingEvents removeObject:e];
                                e.entities = @{@"reply":self->_msgid};
                                e.height = 0;
                                e.pending = NO;
                                e.rowType = ROW_FAILED;
                                e.color = [UIColor networkErrorColor];
                                e.bgColor = [UIColor errorBackgroundColor];
                                e.formatted = nil;
                                e.height = 0;
                                [e.expirationTimer invalidate];
                                e.expirationTimer = nil;
                                [self->_eventsView reloadData];
                            }];
                        }
                    }];
                } else {
                    e.reqId = [[NetworkConnection sharedInstance] say:msg to:self->_buffer.name cid:self->_buffer.cid handler:^(IRCCloudJSONObject *result) {
                        if(![[result objectForKey:@"success"] boolValue]) {
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self->_pendingEvents removeObject:e];
                                e.height = 0;
                                e.pending = NO;
                                e.rowType = ROW_FAILED;
                                e.color = [UIColor networkErrorColor];
                                e.bgColor = [UIColor errorBackgroundColor];
                                e.formatted = nil;
                                e.height = 0;
                                [e.expirationTimer invalidate];
                                e.expirationTimer = nil;
                                [self->_eventsView reloadData];
                            }];
                        }
                    }];
                }
                if(e.reqId < 0)
                    e.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_sendRequestDidExpire:) userInfo:e repeats:NO];
                CLS_LOG(@"Sending message with reqid %i", e.reqId);
            }
        }
    }
}

-(void)_sendRequestDidExpire:(NSTimer *)timer {
    Event *e = timer.userInfo;
    e.expirationTimer = nil;
    if([self->_pendingEvents containsObject:e]) {
        [self->_pendingEvents removeObject:e];
        e.height = 0;
        e.pending = NO;
        e.rowType = ROW_FAILED;
        e.color = [UIColor networkErrorColor];
        e.bgColor = [UIColor errorBackgroundColor];
        e.formatted = nil;
        e.height = 0;
        [self->_eventsView reloadData];
    }
}

-(void)nickSelected:(NSString *)nick {
    self->_message.selectedRange = NSMakeRange(0, 0);
    NSString *text = self->_message.text;
    BOOL isChannel = NO;
    
    for(Channel *channel in _sortedChannels) {
        if([nick isEqualToString:channel.name]) {
            isChannel = YES;
            break;
        }
    }
    
    if(self->_updateSuggestionsTask.atMention || (!_updateSuggestionsTask.isEmoji && _buffer.serverIsSlack))
        nick = [NSString stringWithFormat:@"@%@", nick];

    if(!isChannel && !_buffer.serverIsSlack && ![text hasPrefix:@":"] && [text rangeOfString:@" "].location == NSNotFound)
        nick = [nick stringByAppendingString:@": "];
    else
        nick = [nick stringByAppendingString:@" "];
    
    if(text.length == 0) {
        self->_message.text = nick;
    } else {
        while(text.length > 0 && [text characterAtIndex:text.length - 1] != ' ') {
            text = [text substringToIndex:text.length - 1];
        }
        text = [text stringByAppendingString:nick];
        self->_message.text = text;
    }
    
}

-(void)updateSuggestions:(BOOL)force {
    if(self->_updateSuggestionsTask)
        [self->_updateSuggestionsTask cancel];
    
    self->_updateSuggestionsTask = [[UpdateSuggestionsTask alloc] init];
    self->_updateSuggestionsTask.message = self->_message;
    self->_updateSuggestionsTask.buffer = self->_buffer;
    self->_updateSuggestionsTask.nickCompletionView = self->_nickCompletionView;
    self->_updateSuggestionsTask.force = force;
    
    [self->_updateSuggestionsTask performSelectorInBackground:@selector(run) withObject:nil];
}

-(void)_updateSuggestionsTimer {
    self->_nickCompletionTimer = nil;
    [self updateSuggestions:NO];
}

-(void)scheduleSuggestionsTimer {
    if(self->_nickCompletionTimer)
        [self->_nickCompletionTimer invalidate];
    self->_nickCompletionTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_updateSuggestionsTimer) userInfo:nil repeats:NO];
}

-(void)cancelSuggestionsTimer {
    if(self->_nickCompletionTimer)
        [self->_nickCompletionTimer invalidate];
    self->_nickCompletionTimer = nil;
}

-(void)_updateMessageWidth {
    self->_message.animateHeightChange = NO;
    BOOL dirty = NO;
    CGFloat messageWidth;
    
    if(self->_message.text.length > 0) {
        messageWidth = self->_eventsViewWidthConstraint.constant - _sendBtn.frame.size.width - _message.frame.origin.x - 16;
    } else {
        messageWidth = self->_eventsViewWidthConstraint.constant - _settingsBtn.frame.size.width - _message.frame.origin.x - 16;
    }
    messageWidth -= self.slidingViewController.view.safeAreaInsets.right;

    if(self->_message.text.length > 0) {
        if(self->_messageWidthConstraint.constant != messageWidth) {
            self->_messageWidthConstraint.constant = messageWidth;
            [self.view layoutIfNeeded];
            dirty = YES;
        }
        if(self->_sendBtn.alpha != 1) {
            self->_sendBtn.enabled = YES;
            self->_sendBtn.alpha = 1;
            self->_settingsBtn.enabled = NO;
            self->_settingsBtn.alpha = 0;
        }
    } else {
        if(self->_messageWidthConstraint.constant != messageWidth) {
            self->_messageWidthConstraint.constant = messageWidth;
            [self.view layoutIfNeeded];
            dirty = YES;
        }
        if(self->_sendBtn.alpha != 0) {
            self->_sendBtn.enabled = NO;
            self->_sendBtn.alpha = 0;
            self->_settingsBtn.enabled = YES;
            self->_settingsBtn.alpha = 1;
            self->_message.delegate = nil;
            [self->_message clearText];
            self->_message.delegate = self;
        }
    }
    self->_message.animateHeightChange = YES;
    
    if(dirty || self->_messageHeightConstraint.constant != self->_message.frame.size.height) {
        self->_messageHeightConstraint.constant = self->_message.frame.size.height;
        self->_bottomBarHeightConstraint.constant = self->_message.frame.size.height + 8;
        CGRect frame = self->_settingsBtn.frame;
        frame.origin.x = self->_eventsViewWidthConstraint.constant - _settingsBtn.frame.size.width - 10 - self.slidingViewController.view.safeAreaInsets.right;
        self->_settingsBtn.frame = frame;
        frame = self->_sendBtn.frame;
        frame.origin.x = self->_eventsViewWidthConstraint.constant - _sendBtn.frame.size.width - 8 - self.slidingViewController.view.safeAreaInsets.right;
        self->_sendBtn.frame = frame;
        [self _updateEventsInsets];
        [self.view layoutIfNeeded];
    }
}

-(BOOL)expandingTextView:(UIExpandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    self->_textIsChanging = YES;
    if(range.location == expandingTextView.text.length) {
        self->_currentMessageAttributes = expandingTextView.internalTextView.typingAttributes;
    } else {
        self->_currentMessageAttributes = nil;
    }
    return YES;
}

-(void)expandingTextViewDidChange:(UIExpandingTextView *)expandingTextView {
    if(!_textIsChanging)
        self->_currentMessageAttributes = expandingTextView.internalTextView.typingAttributes;
    else
        expandingTextView.internalTextView.typingAttributes = self->_currentMessageAttributes;
    self->_textIsChanging = NO;
    [self.view layoutIfNeeded];
    [UIView beginAnimations:nil context:nil];
    [self _updateMessageWidth];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
    if(self->_nickCompletionView.alpha == 1) {
        [self updateSuggestions:NO];
    } else {
        [self performSelectorOnMainThread:@selector(scheduleSuggestionsTimer) withObject:nil waitUntilDone:NO];
    }
    UIColor *c = ([NetworkConnection sharedInstance].state == kIRCCloudStateConnected)?([UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor unreadBlueColor]):[UIColor textareaBackgroundColor];
    [self->_sendBtn setTitleColor:c forState:UIControlStateNormal];
    [self->_sendBtn setTitleColor:c forState:UIControlStateDisabled];
    [self->_sendBtn setTitleColor:c forState:UIControlStateHighlighted];
    
    if(!self->_handoffTimer)
        self->_handoffTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_updateHandoffTimer) userInfo:nil repeats:NO];
}

-(void)_cancelHandoffTimer {
    if(self->_handoffTimer)
        [self->_handoffTimer invalidate];
    _handoffTimer = nil;
}

-(void)_updateHandoffTimer {
    _handoffTimer = nil;
    [[self userActivity] setNeedsSave:YES];
    [self userActivityWillSave:[self userActivity]];
    if(self->_buffer) {
        self->_buffer.draft = _message.text.length ? _message.text : nil;
    }
}

-(BOOL)expandingTextViewShouldReturn:(UIExpandingTextView *)expandingTextView {
    [self sendButtonPressed:expandingTextView];
    return NO;
}

-(void)expandingTextView:(UIExpandingTextView *)expandingTextView willChangeHeight:(float)height {
    if(expandingTextView.frame.size.height != height) {
        [self.view layoutIfNeeded];
        self->_messageHeightConstraint.constant = height;
        [self.view layoutIfNeeded];
        [self updateLayout];
    }
}

-(void)_updateTitleArea {
    NSString *sceneTitle = nil;
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    self->_lock.hidden = YES;
    self->_titleLabel.textColor = [UIColor navBarHeadingColor];
    self->_topicLabel.textColor = [UIColor navBarSubheadingColor];
    if([self->_buffer.type isEqualToString:@"console"]) {
        if(s.name.length)
            self->_titleLabel.text = s.name;
        else
            self->_titleLabel.text = s.hostname;
        self->_titleLabel.accessibilityLabel = @"Server";
        self->_titleLabel.accessibilityValue = self->_titleLabel.text;
        self.navigationItem.title = self->_titleLabel.text;
        self->_topicLabel.hidden = NO;
        self->_titleLabel.font = [UIFont boldSystemFontOfSize:18];
        self->_topicLabel.text = [NSString stringWithFormat:@"%@:%i", s.hostname, s.port];
        self->_lock.hidden = NO;
        if(s.isSlack)
            self->_lock.text = FA_SLACK;
        else if(s.ssl > 0)
            self->_lock.text = FA_SHIELD;
        else
            self->_lock.text = FA_GLOBE;
        self->_lock.textColor = [UIColor navBarHeadingColor];
        if(s)
            sceneTitle = [NSString stringWithFormat:@"%@", s.name.length?s.name:s.hostname];
    } else {
        self.navigationItem.title = self->_titleLabel.text = self->_buffer.displayName;
        self->_titleLabel.font = [UIFont boldSystemFontOfSize:20];
        self->_titleLabel.accessibilityValue = self->_buffer.accessibilityValue;
        self->_topicLabel.hidden = YES;
        self->_lock.text = FA_LOCK;
        self->_lock.textColor = [UIColor navBarHeadingColor];
        if([self->_buffer.type isEqualToString:@"channel"]) {
            self->_titleLabel.accessibilityLabel = self->_buffer.isMPDM ? @"Conversation with" : @"Channel";
            BOOL lock = NO;
            Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid];
            if(channel) {
                if(channel.key || (self->_buffer.serverIsSlack && !_buffer.isMPDM && [channel hasMode:@"s"]))
                    lock = YES;
                if([channel.topic_text isKindOfClass:[NSString class]] && channel.topic_text.length) {
                    self->_topicLabel.hidden = NO;
                    self->_titleLabel.font = [UIFont boldSystemFontOfSize:18];
                    self->_topicLabel.text = [channel.topic_text stripIRCFormatting];
                    self->_topicLabel.accessibilityLabel = @"Topic";
                    self->_topicLabel.accessibilityValue = self->_topicLabel.text;
                } else {
                    self->_topicLabel.hidden = YES;
                }
            }
            if(lock) {
                self->_lock.hidden = NO;
            } else {
                self->_lock.hidden = YES;
            }
        } else if([self->_buffer.type isEqualToString:@"conversation"]) {
            self->_titleLabel.accessibilityLabel = @"Conversation with";
            self.navigationItem.title = self->_titleLabel.text = self->_buffer.name;
            self->_topicLabel.hidden = NO;
            self->_titleLabel.font = [UIFont boldSystemFontOfSize:18];
            if(self->_buffer.away_msg.length) {
                self->_topicLabel.text = [NSString stringWithFormat:@"Away: %@", _buffer.away_msg];
            } else {
                User *u = [[UsersDataSource sharedInstance] getUser:self->_buffer.name cid:self->_buffer.cid];
                if(u && u.away) {
                    if(u.away_msg.length)
                        self->_topicLabel.text = [NSString stringWithFormat:@"Away: %@", u.away_msg];
                    else
                        self->_topicLabel.text = @"Away";
                } else {
                    Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
                    if(s.name.length)
                        self->_topicLabel.text = s.name;
                    else
                        self->_topicLabel.text = s.hostname;
                }
            }
        }
        if(s && _buffer)
            sceneTitle = [NSString stringWithFormat:@"%@ | %@", _buffer.displayName, s.name.length?s.name:s.hostname];
    }
    if(self->_msgid) {
        self->_topicLabel.text = self->_titleLabel.text;
        self->_topicLabel.hidden = NO;
        self->_titleLabel.text = @"Thread";
        self->_titleLabel.font = [UIFont boldSystemFontOfSize:18];
        self->_lock.hidden = YES;
        self->_titleLabel.accessibilityLabel = @"Thread from";
        self->_titleLabel.accessibilityValue = self->_topicLabel.text;
    }
    if(self->_lock.hidden == NO && _lock.alpha == 1)
        self->_titleOffsetXConstraint.constant = self->_lock.frame.size.width / 2;
    else
        self->_titleOffsetXConstraint.constant = 0;
    if(self->_topicLabel.hidden == NO && _topicLabel.alpha == 1)
        self->_titleOffsetYConstraint.constant = -10;
    else
        self->_titleOffsetYConstraint.constant = 0;
    [self->_titleView setNeedsUpdateConstraints];
    
    if (@available(iOS 13.0, *)) {
        if(sceneTitle && self->_sceneTitleExtra.length)
            sceneTitle = [self->_sceneTitleExtra stringByAppendingString:sceneTitle];
        UIScene *scene = [(AppDelegate *)[UIApplication sharedApplication].delegate sceneForWindow:self.view.window];
        scene.title = sceneTitle ? sceneTitle : @"IRCCloud";
    }
}

-(void)showJoinPrompt:(NSString *)channel server:(Server *)s {
    if(channel && s) {
        NSString *key = nil;
        NSRange range = [channel rangeOfString:@","];
        if(range.location != NSNotFound) {
            key = [channel substringFromIndex:range.location + 1];
            channel = [channel substringToIndex:range.location];
        }
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Join A Channel" message:[NSString stringWithFormat:@"Would you like to join the channel %@ on %@?", channel, s.name.length?s.name:s.hostname] preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[NetworkConnection sharedInstance] join:channel key:key cid:s.cid handler:nil];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)launchURL:(NSURL *)url {
    self->_urlToOpen = nil;
    if([url.path hasPrefix:@"/log-export/"]) {
        LogExportsTableViewController *lvc;
        
        if([self.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)self.presentedViewController).topViewController isKindOfClass:[LogExportsTableViewController class]]) {
            lvc = (LogExportsTableViewController *)(((UINavigationController *)self.presentedViewController).topViewController);
        } else {
            lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            lvc.buffer = self->_buffer;
            lvc.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lvc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self presentViewController:nc animated:YES completion:nil];
        }
        [lvc download:url];
        return;
    }
    
    if([url.path hasPrefix:@"/irc/"] && url.pathComponents.count >= 4) {
        NSString *network = [[url.pathComponents objectAtIndex:2] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        NSString *type = [url.pathComponents objectAtIndex:3];
        if([type isEqualToString:@"channel"] || [type isEqualToString:@"messages"]) {
            NSString *name = [[url.pathComponents objectAtIndex:4] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
            
            if(name) {
                for(Server *s in [[ServersDataSource sharedInstance] getServers]) {
                    NSString *serverHost = [s.hostname lowercaseString];
                    if([serverHost hasPrefix:@"irc."])
                        serverHost = [serverHost substringFromIndex:4];
                    serverHost = [serverHost stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
                    
                    NSString *serverName = [s.name lowercaseString];
                    serverName = [serverName stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

                    if([network isEqualToString:serverHost] || [network isEqualToString:serverName]) {
                        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:s.cid]) {
                            if(([type isEqualToString:@"channel"] && [b.type isEqualToString:@"channel"]) || ([type isEqualToString:@"messages"] && [b.type isEqualToString:@"conversation"])) {
                                NSString *bufferName = b.name;
                                
                                if([b.type isEqualToString:@"channel"]) {
                                    if([bufferName hasPrefix:@"#"])
                                        bufferName = [bufferName substringFromIndex:1];
                                    if(![bufferName isEqualToString:[b accessibilityValue]])
                                        bufferName = b.name;
                                }
                                
                                if([bufferName isEqualToString:name]) {
                                    [self bufferSelected:b.bid];
                                    return;
                                }
                            }
                        }
                        if([type isEqualToString:@"channel"])
                            [self showJoinPrompt:name server:s];
                        else if([type isEqualToString:@"messages"])
                            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", name] to:nil cid:s.cid handler:nil];
                    }
                }
            }
        }
        return;
    }

    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
    
    if([url.host isEqualToString:@"youtu.be"] || [url.host hasSuffix:@"youtube.com"]) {
        YouTubeViewController *yvc = [[YouTubeViewController alloc] initWithURL:url];
        yvc.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:yvc animated:NO completion:nil];
        return;
    }
    
    int port = [url.port intValue];
    int ssl = [url.scheme hasSuffix:@"s"]?1:0;
    BOOL match = NO;
    kIRCCloudState state = [NetworkConnection sharedInstance].state;
    
    if([url.host intValue] > 0 && url.path && url.path.length > 1) {
        Server *s = [[ServersDataSource sharedInstance] getServer:[url.host intValue]];
        if(s != nil) {
            match = YES;
            NSString *channel = [[url.path stringByRemovingPercentEncoding] substringFromIndex:1];
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:channel server:s.cid];
            if([b.type isEqualToString:@"channel"] && ![[ChannelsDataSource sharedInstance] channelForBuffer:b.bid])
                b = nil;
            if(b)
                [self bufferSelected:b.bid];
            else if(channel && state == kIRCCloudStateConnected)
                [self showJoinPrompt:channel server:s];
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
                    else if(channel && state == kIRCCloudStateConnected)
                        [self showJoinPrompt:channel server:s];
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
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:evc];
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self.navigationController presentViewController:nc animated:YES completion:nil];
        } else {
            self->_urlToOpen = url;
        }
    }
}

-(void)bufferSelected:(int)bid {
    [self performSelectorOnMainThread:@selector(cancelSuggestionsTimer) withObject:nil waitUntilDone:NO];
    [self performSelectorOnMainThread:@selector(_cancelHandoffTimer) withObject:nil waitUntilDone:NO];
    _sortedChannels = nil;
    _sortedUsers = nil;
    BOOL changed = (self->_buffer && _buffer.bid != bid) || !_buffer;
    if(self->_buffer && _buffer.bid != bid && _bidToOpen != bid) {
        self->_eidToOpen = -1;
    }

    if(changed) {
        [self resetColors];
        self->_msgid = self->_eventsView.msgid = nil;
        if(self->_defaultTextareaFont) {
            self->_message.internalTextView.font = self->_defaultTextareaFont;
            self->_message.internalTextView.textColor = [UIColor textareaTextColor];
            self->_message.internalTextView.typingAttributes = @{NSForegroundColorAttributeName:[UIColor textareaTextColor], NSFontAttributeName:self->_defaultTextareaFont };
        }
    }
    
    Buffer *lastBuffer = self->_buffer;
    self->_buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    if(lastBuffer && changed) {
        if([NetworkConnection sharedInstance].prefs) {
            BOOL enabled = [[[[NetworkConnection sharedInstance].prefs objectForKey:[lastBuffer.type isEqualToString:@"channel"]?@"channel-enableReadOnSelect":@"buffer-enableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",lastBuffer.bid]] boolValue] || [[[NetworkConnection sharedInstance].prefs objectForKey:@"enableReadOnSelect"] intValue] == 1;
            if([[[[NetworkConnection sharedInstance].prefs objectForKey:[lastBuffer.type isEqualToString:@"channel"]?@"channel-disableReadOnSelect":@"buffer-disableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",lastBuffer.bid]] boolValue])
                enabled = NO;
            
            if(enabled) {
                NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:lastBuffer.bid];
                NSTimeInterval eid = 0;
                Event *last;
                for(NSInteger i = events.count - 1; i >= 0; i--) {
                    last = [events objectAtIndex:i];
                    if(!last.pending && last.rowType != ROW_LASTSEENEID)
                        break;
                }
                if(!last.pending) {
                    eid = last.eid;
                }
                if(eid >= 0 && eid >= lastBuffer.last_seen_eid) {
                    [[NetworkConnection sharedInstance] heartbeat:self->_buffer.bid cid:lastBuffer.cid bid:lastBuffer.bid lastSeenEid:eid handler:nil];
                    lastBuffer.last_seen_eid = eid;
                }
            }
        }
        self->_buffer.lastBuffer = lastBuffer;
        self->_buffer.nextBuffer = nil;
        lastBuffer.draft = self->_message.text.length ? _message.text : nil;
        [self showTwoSwipeTip];
    }
    if(self->_buffer) {
        if(self->_incomingDraft) {
            if(changed) {
                self->_buffer.draft = self->_incomingDraft;
            } else {
                [self->_message setText:self->_incomingDraft];
            }
            self->_incomingDraft = nil;
        }
        if(self->_buffer.cid == self->_cidToOpen)
            self->_cidToOpen = -1;
        else if(self->_cidToOpen > 0)
            CLS_LOG(@"cid%i selected, but was waiting for cid%i", self->_buffer.cid, self->_cidToOpen);
        if(self->_buffer.bid == self->_bidToOpen)
            self->_bidToOpen = -1;
        else if(self->_bidToOpen > 0)
            CLS_LOG(@"bid%i selected, but was waiting for bid%i", self->_buffer.bid, self->_bidToOpen);
        self->_eidToOpen = -1;
        self->_bufferToOpen = nil;
        CLS_LOG(@"BID selected: cid%i bid%i", _buffer.cid, bid);
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid];
        for(Event *event in events) {
            if(event.isHighlight) {
                User *u = [[UsersDataSource sharedInstance] getUser:event.from cid:event.cid bid:event.bid];
                if(u && u.lastMention < event.eid) {
                    u.lastMention = event.eid;
                }
            }
        }
        [[NetworkConnection sharedInstance] setLastSelectedBID:bid];
        [[NSUserDefaults standardUserDefaults] setObject:@(bid) forKey:@"last_selected_bid"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        NSUserActivity *activity = [self userActivity];
        if(![activity.activityType hasSuffix:@".buffer"]) {
            [activity invalidate];
#ifdef ENTERPRISE
            activity = [[NSUserActivity alloc] initWithActivityType: @"com.irccloud.enterprise.buffer"];
#else
            activity = [[NSUserActivity alloc] initWithActivityType: @"com.irccloud.buffer"];
#endif
            activity.delegate = self;
            [self setUserActivity:activity];
        }
        [activity setNeedsSave:YES];
        [self userActivityWillSave:activity];
        [activity becomeCurrent];
    } else {
        CLS_LOG(@"BID selected but not found: bid%i", bid);
    }
    
    [self _updateTitleArea];
    [self->_buffersView setBuffer:self->_buffer];
    self->_eventsView.eidToOpen = self->_eidToOpen;
    [UIView animateWithDuration:0.1 animations:^{
        self->_eventsView.stickyAvatar.alpha = 0;
        self->_eventsView.tableView.alpha = 0;
        self->_eventsView.topUnreadView.alpha = 0;
        self->_eventsView.bottomUnreadView.alpha = 0;
        self->_eventActivity.alpha = 1;
        [self->_eventActivity startAnimating];
        if(changed) {
            NSString *draft = self->_buffer.draft.length ? self->_buffer.draft : nil;
            self->_message.delegate = nil;
            [self->_message clearText];
            self->_message.delegate = self;
            self->_buffer.draft = draft;
        }
    } completion:^(BOOL finished){
        [self->_eventsView setBuffer:self->_buffer];
        [UIView animateWithDuration:0.1 animations:^{
            self->_eventsView.stickyAvatar.alpha = 1;
            self->_eventsView.tableView.alpha = 1;
            self->_eventActivity.alpha = 0;
            if(changed) {
                self->_message.delegate = nil;
                self->_message.text = self->_buffer.draft;
                self->_message.delegate = self;
            }
        } completion:^(BOOL finished){
            [self->_eventActivity stopAnimating];
        }];
    }];
    [self->_usersView setBuffer:self->_buffer];
    [self _updateUserListVisibility];
    [self _updateServerStatus];
    [self.slidingViewController resetTopView];
    [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
    [self updateSuggestions:NO];
    
    if([[ServersDataSource sharedInstance] getServer:self->_buffer.cid].isSlack) {
        [UIMenuController sharedMenuController].menuItems = @[];
        [self resetColors];
        self->_message.internalTextView.allowsEditingTextAttributes = NO;
    } else {
        [UIMenuController sharedMenuController].menuItems = @[[[UIMenuItem alloc] initWithTitle:@"Paste With Style" action:@selector(pasteRich:)],
                                                              [[UIMenuItem alloc] initWithTitle:@"Color" action:@selector(chooseFGColor)],
                                                              [[UIMenuItem alloc] initWithTitle:@"Background" action:@selector(chooseBGColor)],
                                                              [[UIMenuItem alloc] initWithTitle:@"Reset Colors" action:@selector(resetColors)],
                                                              ];
        self->_message.internalTextView.allowsEditingTextAttributes = YES;
    }
#ifdef DEBUG
    if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"] && [[NSProcessInfo processInfo].arguments containsObject:@"-memberlist"]) {
        [self.slidingViewController performSelector:@selector(anchorTopViewTo:) withObject:nil afterDelay:0.5];
    }
#endif
}

-(void)userActivityWasContinued:(NSUserActivity *)userActivity {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self->_message clearText];
    }];
}

-(void)userActivityWillSave:(NSUserActivity *)activity {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
#ifndef ENTERPRISE
    NSString *draft_escaped = self->_message.text?self->_message.text:@"";
    draft_escaped = [draft_escaped stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    if([self->_buffer.type isEqualToString:@"console"]) {
        if(self->_message.text.length)
            activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.irccloud.com/#?/text=%@&url=%@%@:%i", draft_escaped, s.ssl?@"ircs://":@"", s.hostname, s.port]];
        else
            activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.irccloud.com/!%@%@:%i", s.ssl?@"ircs://":@"", s.hostname, s.port]];
        activity.title = [NSString stringWithFormat:@"%@ | IRCCloud", s.hostname];
    } else {
        if(self->_message.text.length)
            activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.irccloud.com/#?/text=%@&url=%@%@:%i/%@", draft_escaped, s.ssl?@"ircs://":@"", s.hostname, s.port, [self->_buffer.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]]];
        else
            activity.webpageURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.irccloud.com/#!/%@%@:%i/%@", s.ssl?@"ircs://":@"", s.hostname, s.port, [self->_buffer.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]]]];
        activity.title = [NSString stringWithFormat:@"%@ | IRCCloud", self->_buffer.name];
    }
#endif
        [activity addUserInfoEntriesFromDictionary:@{@"bid":@(self->_buffer.bid), @"cid":@(self->_buffer.cid), @"draft":(self->_message.text?self->_message.text:@"")}];
    }];
}

-(void)_updateGlobalMsg {
    if([NetworkConnection sharedInstance].globalMsg.length) {
        self->_globalMsgContainer.hidden = NO;
        self->_globalMsg.userInteractionEnabled = YES;
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
        
        NSArray *links;
        NSMutableAttributedString *s = (NSMutableAttributedString *)[ColorFormatter format:msg defaultColor:[UIColor blackColor] mono:NO linkify:YES server:nil links:&links];
        
        NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
        p.alignment = NSTextAlignmentCenter;
        [s addAttribute:NSParagraphStyleAttributeName value:p range:NSMakeRange(0, [s length])];

        self->_globalMsg.textColor = [UIColor messageTextColor];
        self->_globalMsg.attributedText = s;
        for(NSTextCheckingResult *result in links) {
            if(result.resultType == NSTextCheckingTypeLink) {
                [self->_globalMsg addLinkWithTextCheckingResult:result];
            }
        }
        self->_topUnreadBarYOffsetConstraint.constant = self->_globalMsg.intrinsicContentSize.height + 12;
        [self.view layoutIfNeeded];
    } else {
        self->_globalMsgContainer.hidden = YES;
        self->_topUnreadBarYOffsetConstraint.constant = 0;
    }
    [self _updateEventsInsets];
}

-(IBAction)globalMsgPressed:(id)sender {
    [NetworkConnection sharedInstance].globalMsg = nil;
    [self _updateGlobalMsg];
}

-(void)_updateServerStatus {
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    if(s && (![s.status isEqualToString:@"connected_ready"] || ([s.away isKindOfClass:[NSString class]] && s.away.length))) {
        if(self->_serverStatusBar.hidden) {
            self->_serverStatusBar.hidden = NO;
        }
        self->_serverStatusBar.backgroundColor = [UIColor connectionBarColor];
        self->_serverStatus.textColor = [UIColor connectionBarTextColor];
        self->_serverStatus.font = [UIFont systemFontOfSize:FONT_SIZE];
        if([s.status isEqualToString:@"connected_ready"]) {
            if([s.away isKindOfClass:[NSString class]]) {
                self->_serverStatusBar.backgroundColor = [UIColor awayBarColor];
                self->_serverStatus.textColor = [UIColor awayBarTextColor];
                if(![[s.away lowercaseString] isEqualToString:@"away"]) {
                    self->_serverStatus.text = [NSString stringWithFormat:@"Away (%@). Tap to come back.", s.away];
                } else {
                    self->_serverStatus.text = @"Away. Tap to come back.";
                }
            }
        } else if([s.status isEqualToString:@"quitting"]) {
            self->_serverStatus.text = @"Disconnecting";
        } else if([s.status isEqualToString:@"disconnected"]) {
            NSString *type = [s.fail_info objectForKey:@"type"];
            if([type isKindOfClass:[NSString class]] && [type length]) {
                NSString *reason = [s.fail_info objectForKey:@"reason"];
                if([type isEqualToString:@"killed"]) {
                    self->_serverStatus.text = [NSString stringWithFormat:@"Disconnected - Killed: %@", reason];
                } else if([type isEqualToString:@"connecting_restricted"]) {
                    self->_serverStatus.text = [EventsDataSource reason:reason];
                    if([self->_serverStatus.text isEqualToString:reason])
                        self->_serverStatus.text = @"You can’t connect to this server with a free account.";
                } else if([type isEqualToString:@"connection_blocked"]) {
                    self->_serverStatus.text = @"Disconnected - Connections to this server have been blocked";
                } else {
                    if([reason isKindOfClass:[NSString class]] && [reason length] && [reason isEqualToString:@"ssl_verify_error"])
                        self->_serverStatus.text = [NSString stringWithFormat:@"Strict transport security error: %@", [EventsDataSource SSLreason:[s.fail_info objectForKey:@"ssl_verify_error"]]];
                    else
                        self->_serverStatus.text = [NSString stringWithFormat:@"Disconnected: %@", [EventsDataSource reason:reason]];
                }
                self->_serverStatusBar.backgroundColor = [UIColor connectionErrorBarColor];
                self->_serverStatus.textColor = [UIColor connectionErrorBarTextColor];
            } else {
                self->_serverStatus.text = @"Disconnected. Tap to reconnect.";
            }
        } else if([s.status isEqualToString:@"queued"]) {
            self->_serverStatus.text = @"Connection Queued";
        } else if([s.status isEqualToString:@"connecting"]) {
            self->_serverStatus.text = @"Connecting";
        } else if([s.status isEqualToString:@"connected"]) {
            self->_serverStatus.text = @"Connected";
        } else if([s.status isEqualToString:@"connected_joining"]) {
            self->_serverStatus.text = @"Connected: Joining Channels";
        } else if([s.status isEqualToString:@"pool_unavailable"]) {
            self->_serverStatus.text = @"Connection temporarily unavailable";
            self->_serverStatusBar.backgroundColor = [UIColor connectionErrorBarColor];
            self->_serverStatus.textColor = [UIColor connectionErrorBarTextColor];
        } else if([s.status isEqualToString:@"waiting_to_retry"]) {
            double seconds = ([[s.fail_info objectForKey:@"timestamp"] doubleValue] + [[s.fail_info objectForKey:@"retry_timeout"] intValue]) - [[NSDate date] timeIntervalSince1970];
            if(seconds > 0) {
                NSString *reason = [EventsDataSource reason:[s.fail_info objectForKey:@"reason"]];
                NSString *text = @"Disconnected";
                if([reason isKindOfClass:[NSString class]] && [reason length])
                    text = [text stringByAppendingFormat:@": %@, ", reason];
                else
                    text = [text stringByAppendingString:@"; "];
                text = [text stringByAppendingFormat:@"Reconnecting in %i seconds.", (int)seconds];
                self->_serverStatus.text = text;
                self->_serverStatusBar.backgroundColor = [UIColor connectionErrorBarColor];
                self->_serverStatus.textColor = [UIColor connectionErrorBarTextColor];
            } else {
                self->_serverStatus.text = @"Ready to connect.  Waiting our turn…";
            }
            [self performSelector:@selector(_updateServerStatus) withObject:nil afterDelay:0.5];
        } else if([s.status isEqualToString:@"ip_retry"]) {
            self->_serverStatus.text = @"Trying another IP address";
        } else {
            CLS_LOG(@"Unhandled server status: %@", s.status);
        }
        self->_bottomUnreadBarYOffsetConstraint.constant = self->_serverStatus.intrinsicContentSize.height + 12;
    } else {
        if(!_serverStatusBar.hidden) {
            self->_serverStatusBar.hidden = YES;
        }
        self->_bottomUnreadBarYOffsetConstraint.constant = 0;
    }
    [self _updateEventsInsets];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    if(self.slidingViewController.view.safeAreaInsets.bottom) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight;
    }
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)prefersStatusBarHidden {
    if (@available(iOS 14.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp) {
            return YES;
        }
    }
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
}

-(void)statusBarFrameWillChange:(NSNotification *)n {
    if(self.slidingViewController.view.safeAreaInsets.bottom)
        return;
    CGRect newFrame = [[n.userInfo objectForKey:UIApplicationStatusBarFrameUserInfoKey] CGRectValue];
    if(newFrame.size.width > 0 && newFrame.size.width == [UIApplication sharedApplication].statusBarFrame.size.width) {
        [UIView animateWithDuration:0.25f animations:^{
            [self updateLayout:newFrame.size.height];
        }];
    }
}

-(void)updateLayout {
    BOOL scrolledUp = _buffer.scrolledUp;
    [UIApplication sharedApplication].statusBarHidden = self.prefersStatusBarHidden;
    [UIColor setSafeInsets:self.slidingViewController.view.safeAreaInsets];
    if(self.slidingViewController.view.safeAreaInsets.bottom)
        [self updateLayout:0];
    else
        [self updateLayout:[UIApplication sharedApplication].statusBarFrame.size.height];
    CGPoint contentOffset = _eventsView.tableView.contentOffset;
    [self.slidingViewController adjustLayout];
    [self.slidingViewController.view layoutIfNeeded];
    if(!scrolledUp)
        [self->_eventsView _scrollToBottom];
    else
        [self->_eventsView.tableView setContentOffset:contentOffset];
}

-(void)updateLayout:(float)sbHeight {
    CGRect frame = self.slidingViewController.view.frame;
    if(sbHeight >= 20 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
        frame.origin.y = (sbHeight - 20);

    frame.size = self.slidingViewController.view.window.bounds.size;

    if(frame.size.width > 0 && frame.size.height > 0) {
        if(sbHeight > 20 && [[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad)
            frame.size.height -= sbHeight;
        
        self.slidingViewController.view.frame = frame;
        [self.slidingViewController updateUnderLeftLayout];
        [self.slidingViewController updateUnderRightLayout];
        [self transitionToSize:frame.size];
    }
}

-(void)transitionToSize:(CGSize)size {
    BOOL isCatalyst = NO;
    if (@available(iOS 13.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp)
            isCatalyst = YES;
    }
    CLS_LOG(@"Transitioning to size: %f, %f", size.width, size.height);
    _ignoreInsetChanges = YES;
    CGPoint center = self.slidingViewController.view.center;
    if(self.slidingViewController.underLeftShowing)
        center.x += self->_buffersView.tableView.frame.size.width;
    if(self.slidingViewController.underRightShowing)
        center.x -= self->_buffersView.tableView.frame.size.width;
    
    self.navigationController.view.frame = self.slidingViewController.view.bounds;
    self.navigationController.view.center = center;
    self.navigationController.view.layer.position = self.navigationController.view.center;

    self->_bottomBarHeightConstraint.constant = self->_message.frame.size.height + 8;
    self->_eventsViewHeightConstraint.constant = self.slidingViewController.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.slidingViewController.view.safeAreaInsets.top - self.slidingViewController.view.safeAreaInsets.bottom;
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"] && size.width > size.height
       - (isCatalyst ? 78 : 0)
       && (isCatalyst || size.width == [UIScreen mainScreen].bounds.size.width)
       && ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || [[UIDevice currentDevice] isBigPhone])) {
        int buffersViewWidth = [[UIDevice currentDevice] isBigPhone]?200:240;
        self->_borders.hidden = NO;
        self->_eventsViewWidthConstraint.constant = self.view.frame.size.width - buffersViewWidth - 1;
        self->_eventsViewOffsetLeftConstraint.constant = buffersViewWidth + 1;
        self->_connectingXOffsetConstraint.constant = buffersViewWidth + 1;
        self->_topicXOffsetConstraint.constant = buffersViewWidth + 1;
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;
        self.slidingViewController.underLeftViewController = nil;
        if(self->_buffersView.view.superview != self.navigationController.navigationBar.superview) {
            [self->_buffersView willMoveToParentViewController:self.navigationController];
            [self->_buffersView viewWillAppear:NO];
            self->_buffersView.view.hidden = NO;
            [self.navigationController.navigationBar.superview addSubview:self->_buffersView.view];
            self->_buffersView.view.autoresizingMask = UIViewAutoresizingNone;
        }
#if TARGET_OS_MACCATALYST
        self->_buffersView.view.frame = CGRectMake(0,self.slidingViewController.view.safeAreaInsets.top,buffersViewWidth,self.slidingViewController.view.frame.size.height - self.slidingViewController.view.safeAreaInsets.top);
#else
        self->_buffersView.view.frame = CGRectMake(0,0,buffersViewWidth,self.slidingViewController.view.frame.size.height);
#endif
        [self.navigationController.navigationBar.superview bringSubviewToFront:self->_buffersView.view];
        self.navigationController.view.center = self.slidingViewController.view.center;
    } else {
        self->_borders.hidden = YES;
        self->_eventsViewWidthConstraint.constant = size.width + self.slidingViewController.view.safeAreaInsets.left / 2;
        self->_eventsViewOffsetLeftConstraint.constant = self.slidingViewController.view.safeAreaInsets.left / 2;
        self->_connectingXOffsetConstraint.constant = 0;
        self->_topicXOffsetConstraint.constant = 0;
        if(!self.slidingViewController.underLeftViewController)
            self.slidingViewController.underLeftViewController = self->_buffersView;
        if(!self.navigationItem.leftBarButtonItem)
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->_menuBtn];
        [self.slidingViewController updateUnderLeftLayout];
        [self.slidingViewController updateUnderRightLayout];
    }
    self->_buffersView.view.backgroundColor = [UIColor buffersDrawerBackgroundColor];
    CGRect frame = self->_titleView.frame;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        frame.size.height = (size.width > size.height)?24:40;
        self->_topicLabel.alpha = (size.width > size.height)?0:1;
    }
    self->_topicWidthConstraint.constant = frame.size.width = size.width - 128 - self->_topicXOffsetConstraint.constant;
    frame.size.width -= self.slidingViewController.view.safeAreaInsets.left;
    frame.size.width -= self.slidingViewController.view.safeAreaInsets.right;
    self->_topicWidthConstraint.constant -= self.slidingViewController.view.safeAreaInsets.left;
    self->_topicWidthConstraint.constant -= self.slidingViewController.view.safeAreaInsets.right;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"] && [[UIDevice currentDevice] isBigPhone] && (size.width > size.height))
        frame.size.width -= self->_buffersView.tableView.frame.size.width;
    self->_connectingView.frame = self->_titleView.frame = frame;

    [self _updateUserListVisibility];
    [self.view layoutIfNeeded];

    [self _updateTitleArea];
    [self _updateServerStatus];
    [self _updateGlobalMsg];
    
    [self.view layoutIfNeeded];
    
    //Re-calculate the expanding text view height for the new layout width
    if(_previousWidth != size.width)
        _message.text = _message.text;
    
    UIView *v = self.navigationItem.titleView;
    self.navigationItem.titleView = nil;
    self.navigationItem.titleView = v;
    self.navigationController.view.layer.shadowPath = nil;
    
    _leftBorder.frame = CGRectMake(-1,0,1,size.height);
    _rightBorder.frame = CGRectMake(size.width + 1,0,1,size.height);

    _ignoreInsetChanges = NO;
    [self _updateEventsInsets];
    _previousWidth = size.width;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if(self->_eventsView.topUnreadView.observationInfo) {
        @try {
            [self->_eventsView.topUnreadView removeObserver:self forKeyPath:@"alpha"];
            [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
        } @catch(id anException) {
            //Not registered yet
        }
    }
    [self->_eventsView viewWillResize];
    self->_eventActivity.alpha = 1;
    [self->_eventActivity startAnimating];
    [self.slidingViewController resetTopView];
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [UIApplication sharedApplication].statusBarHidden = self.prefersStatusBarHidden;
        [self transitionToSize:size];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self->_eventActivity.alpha = 0;
        [self->_eventActivity stopAnimating];
        if(self->_eventsView.topUnreadView.observationInfo) {
            @try {
                [self->_eventsView.topUnreadView removeObserver:self forKeyPath:@"alpha"];
                [self->_eventsView.tableView.layer removeObserver:self forKeyPath:@"bounds"];
            } @catch(id anException) {
                //Not registered yet
            }
        }
        [UIColor setTheme];
        [self updateLayout];
        [self->_eventsView viewDidResize];
        [self->_eventsView.topUnreadView addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
        [self->_eventsView.tableView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    }];
}

-(void)_updateEventsInsets {
    if(_ignoreInsetChanges)
        return;
    self->_bottomBarOffsetConstraint.constant = self->_kbSize.height;
    if(self.slidingViewController.view.safeAreaInsets.bottom) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) || _kbSize.height > 0)
            self->_bottomBarOffsetConstraint.constant -= self.slidingViewController.view.safeAreaInsets.bottom/2;
    }
    CGFloat height = self->_bottomBarHeightConstraint.constant + _kbSize.height;
    CGFloat top = 0;
    if(!_globalMsgContainer.hidden)
        top += self->_globalMsgContainer.frame.size.height;
    if(self->_eventsView.topUnreadView.alpha > 0)
        top += self->_eventsView.topUnreadView.frame.size.height;
    if(!_serverStatusBar.hidden)
        height += self->_serverStatusBar.bounds.size.height;
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
        height -= self.slidingViewController.view.safeAreaInsets.bottom/2;
    CGFloat diff = height - _eventsView.tableView.contentInset.bottom;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CGFloat bottom = self->_kbSize.height + self.slidingViewController.view.safeAreaInsets.bottom;
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation))
            bottom += self.slidingViewController.view.safeAreaInsets.top;
        if(@available(iOS 14, *)) {
            self->_buffersView.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,0,0);
            self->_usersView.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,0,0);
        } else if(@available(iOS 13, *)) {
        } else {
            self->_buffersView.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,bottom,0);
            self->_usersView.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0,0,bottom,0);
        }
        self->_buffersView.tableView.contentInset = UIEdgeInsetsZero;
        if(self->_buffersView.tableView.adjustedContentInset.bottom > 0) { //Sometimes iOS 11 automatically adds the keyboard padding even though I told it not to
            bottom -= self->_buffersView.tableView.adjustedContentInset.bottom;
        }
        self->_buffersView.tableView.contentInset = UIEdgeInsetsMake(0,0,bottom,0);
        self->_usersView.tableView.contentInset = UIEdgeInsetsMake(0,0,bottom,0);
    }];

    if(!_isShowingPreview && (self->_eventsView.tableView.contentInset.top != top || _eventsView.tableView.contentInset.bottom != height)) {
        [self->_eventsView.tableView setContentInset:UIEdgeInsetsMake(top, 0, height, 0)];
        [self->_eventsView.tableView setScrollIndicatorInsets:UIEdgeInsetsMake(top, 0, height, 0)];

        if(self->_eventsView.tableView.contentSize.height > (self->_eventsView.tableView.frame.size.height - _eventsView.tableView.contentInset.top - _eventsView.tableView.contentInset.bottom)) {
#ifndef APPSTORE
            CLS_LOG(@"Adjusting content offset after changing insets");
#endif
            if(floorf(self->_eventsView.tableView.contentOffset.y + diff + (self->_eventsView.tableView.frame.size.height - _eventsView.tableView.contentInset.top - _eventsView.tableView.contentInset.bottom)) >= floorf(self->_eventsView.tableView.contentSize.height)) {
                if(!_buffer.scrolledUp)
                    [self->_eventsView _scrollToBottom];
#ifndef APPSTORE
                else
                    CLS_LOG(@"Buffer was scrolled up, ignoring");
#endif
            } else if(diff > 0 || _buffer.scrolledUp)
                self->_eventsView.tableView.contentOffset = CGPointMake(0, _eventsView.tableView.contentOffset.y + diff);
        }
    }
}

-(void)refresh {
    [self->_buffersView refresh];
    [self->_eventsView refresh];
    [self->_usersView refresh];
    [self _updateTitleArea];
    [self performSelectorInBackground:@selector(_updateUnreadIndicator) withObject:nil];
}

-(void)setMsgId:(NSString *)msgId {
    self->_eventsView.msgid = self->_msgid = msgId;
    [self->_eventsView refresh];
    [self _updateTitleArea];
    [self _updateUserListVisibility];
}

-(void)clearMsgId {
    self->_eventsView.msgid = self->_msgid = nil;
}

-(void)_closeThread {
    [self setMsgId:nil];
}

-(void)_updateUserListVisibility {
    BOOL isCatalyst = NO;
    if (@available(iOS 13.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp)
            isCatalyst = YES;
    }
    /*if(![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(_updateUserListVisibility) withObject:nil waitUntilDone:YES];
        return;
    }*/
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && ![[UIDevice currentDevice] isBigPhone]) {
        if(self->_msgid) {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_closeThread)];
            self.slidingViewController.underRightViewController = nil;
        } else if([self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
            self.navigationItem.rightBarButtonItem = self->_usersButtonItem;
            if(self.slidingViewController.underRightViewController == nil)
                self.slidingViewController.underRightViewController = self->_usersView;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
            self.slidingViewController.underRightViewController = nil;
        }
    } else {
        if(self.view.bounds.size.width > self.view.bounds.size.height
           && (isCatalyst || self.view.bounds.size.width == [UIScreen mainScreen].bounds.size.width)
           && [[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"] && ![[NSUserDefaults standardUserDefaults] boolForKey:@"hiddenMembers"]) {
            if([self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid] && !([NetworkConnection sharedInstance].prefs && [[[[NetworkConnection sharedInstance].prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]) && ![[UIDevice currentDevice] isBigPhone] && !self->_msgid) {
                self.navigationItem.rightBarButtonItem = nil;
                if(self.slidingViewController.underRightViewController) {
                    self.slidingViewController.underRightViewController = nil;
                    [self addChildViewController:self->_usersView];
                    [self->_usersView willMoveToParentViewController:self];
                    [self->_usersView viewWillAppear:NO];
                    self->_usersView.view.autoresizingMask = UIViewAutoresizingNone;
                }
                self->_usersView.view.frame = CGRectMake(self.view.frame.size.width - 200,0,200,self.view.frame.size.height);
                self->_usersView.view.hidden = NO;
                if(self->_usersView.view.superview != self.view)
                    [self.view insertSubview:self->_usersView.view atIndex:1];
                self->_eventsViewWidthConstraint.constant = self.view.frame.size.width - self->_buffersView.view.frame.size.width - 202;
            } else {
                if(self->_msgid) {
                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_closeThread)];
                    self.slidingViewController.underRightViewController = nil;
                } else if([self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
                    self.navigationItem.rightBarButtonItem = self->_usersButtonItem;
                    if(self.slidingViewController.underRightViewController == nil) {
                        [self->_usersView.view removeFromSuperview];
                        [self->_usersView removeFromParentViewController];
                        CGRect frame = self->_usersView.view.frame;
                        frame.origin.x = 0;
                        frame.size.width = 220;
                        self->_usersView.view.frame = frame;
                        self.slidingViewController.underRightViewController = self->_usersView;
                    }
                    self->_usersView.view.hidden = NO;
                } else {
                    self.navigationItem.rightBarButtonItem = nil;
                    self.slidingViewController.underRightViewController = nil;
                    self->_usersView.view.hidden = YES;
                }
                self->_eventsViewWidthConstraint.constant = self.view.frame.size.width - self->_buffersView.tableView.frame.size.width - 2;
                self->_eventsViewWidthConstraint.constant += self.slidingViewController.view.safeAreaInsets.right;
                if(self.slidingViewController.underRightViewController) {
                    self->_eventsViewWidthConstraint.constant++;
                }
            }
        } else {
            if(self->_msgid) {
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_closeThread)];
                self.slidingViewController.underRightViewController = nil;
            } else if([self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
                self.navigationItem.rightBarButtonItem = self->_usersButtonItem;
                if(self.slidingViewController.underRightViewController == nil)
                    self.slidingViewController.underRightViewController = self->_usersView;
            } else {
                self.navigationItem.rightBarButtonItem = nil;
                self.slidingViewController.underRightViewController = nil;
            }
        }
    }
    [self _updateMessageWidth];
    [self->_message updateConstraints];
    [self.view layoutIfNeeded];
}

-(void)showMentionTip {
    [self->_mentionTip.superview bringSubviewToFront:self->_mentionTip];

    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"mentionTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"mentionTip"];
        [UIView animateWithDuration:0.5 animations:^{
            self->_mentionTip.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideMentionTip) withObject:nil afterDelay:2];
        }];
    }
}

-(void)hideMentionTip {
    [UIView animateWithDuration:0.5 animations:^{
        self->_mentionTip.alpha = 0;
    } completion:nil];
}

-(void)didSwipe:(NSNotification *)n {
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"swipeTip"];
    if([n.name isEqualToString:ECSlidingViewUnderLeftWillAppear]) {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, [self->_buffersView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
        self.view.accessibilityElementsHidden = YES;
    } else if([n.name isEqualToString:ECSlidingViewUnderRightWillAppear]) {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, [self->_usersView.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]);
        self.view.accessibilityElementsHidden = YES;
    } else {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, _titleLabel);
        self.view.accessibilityElementsHidden = NO;
    }
}

-(void)showSwipeTip {
    [self->_swipeTip.superview bringSubviewToFront:self->_swipeTip];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"swipeTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"swipeTip"];
        [UIView animateWithDuration:0.5 animations:^{
            self->_swipeTip.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideSwipeTip) withObject:nil afterDelay:2];
        }];
    }
}

-(void)hideSwipeTip {
    [UIView animateWithDuration:0.5 animations:^{
        self->_swipeTip.alpha = 0;
    } completion:nil];
}

-(void)showTwoSwipeTip {
    [_2swipeTip.superview bringSubviewToFront:self->_2swipeTip];
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"twoSwipeTip"]) {
        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"twoSwipeTip"];
        [UIView animateWithDuration:0.5 animations:^{
            self->_2swipeTip.alpha = 1;
        } completion:^(BOOL finished){
            [self performSelector:@selector(hideTwoSwipeTip) withObject:nil afterDelay:2];
        }];
    }
}

-(void)hideTwoSwipeTip {
    [UIView animateWithDuration:0.5 animations:^{
        self->_2swipeTip.alpha = 0;
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
    [self dismissKeyboard];
    self->_selectedBuffer = self->_buffer;
    self->_selectedUser = nil;
    self->_selectedEvent = nil;
    User *me = [[UsersDataSource sharedInstance] getUser:[[ServersDataSource sharedInstance] getServer:self->_buffer.cid].nick cid:self->_buffer.cid bid:self->_buffer.bid];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle;

    void (^handler)(UIAlertAction *action) = ^(UIAlertAction *a) {
        [self actionSheetActionClicked:a.title];
    };
    
    if([self->_buffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        if([s.status isEqualToString:@"disconnected"]) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Reconnect" style:UIAlertActionStyleDefault handler:handler]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:handler]];
        } else {
            //[sheet addButtonWithTitle:@"Identify Nickname…"];
            [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDefault handler:handler]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Edit Connection" style:UIAlertActionStyleDefault handler:handler]];
    } else if([self->_buffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDefault handler:handler]];
            if([me.mode rangeOfString:@"q"].location != NSNotFound || [me.mode rangeOfString:@"a"].location != NSNotFound || [me.mode rangeOfString:@"o"].location != NSNotFound) {
                [alert addAction:[UIAlertAction actionWithTitle:@"Ban List" style:UIAlertActionStyleDefault handler:handler]];
            }
            [alert addAction:[UIAlertAction actionWithTitle:@"Invite to Channel" style:UIAlertActionStyleDefault handler:handler]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Rejoin" style:UIAlertActionStyleDefault handler:handler]];
            [alert addAction:[UIAlertAction actionWithTitle:(self->_buffer.archived)?@"Unarchive":@"Archive" style:UIAlertActionStyleDefault handler:handler]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:handler]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:handler]];
    } else {
        [alert addAction:[UIAlertAction actionWithTitle:@"Whois" style:UIAlertActionStyleDefault handler:handler]];
        if(self->_buffer.archived) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Unarchive" style:UIAlertActionStyleDefault handler:handler]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDefault handler:handler]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:handler]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:handler]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Ignore List" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add Network" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Join a Channel" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Display Options" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Download Logs" style:UIAlertActionStyleDefault handler:handler]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:handler]];
//#ifndef DEBUG
    [alert addAction:[UIAlertAction actionWithTitle:@"Send Feedback" style:UIAlertActionStyleDefault handler:handler]];
//#endif
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDefault handler:handler]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:handler]];
    }

    alert.popoverPresentationController.sourceRect = CGRectMake(self->_bottomBar.frame.origin.x + _settingsBtn.frame.origin.x, _bottomBar.frame.origin.y,_settingsBtn.frame.size.width,_settingsBtn.frame.size.height);
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)dismissKeyboard {
    [self->_message resignFirstResponder];
}

-(void)_eventTapped:(NSTimer *)timer {
    self->_doubleTapTimer = nil;
    [self->_message resignFirstResponder];
    Event *e = timer.userInfo;
    if(e.rowType == ROW_FAILED) {
        self->_selectedEvent = e;
        Server *s = [[ServersDataSource sharedInstance] getServer:e.cid];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"This message could not be sent" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Try Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self->_selectedEvent.height = 0;
            self->_selectedEvent.rowType = ROW_MESSAGE;
            self->_selectedEvent.bgColor = [UIColor selfBackgroundColor];
            self->_selectedEvent.pending = YES;
            self->_selectedEvent.reqId = [[NetworkConnection sharedInstance] say:self->_selectedEvent.command to:self->_buffer.name cid:self->_buffer.cid handler:nil];
            if(self->_selectedEvent.msg)
                [self->_pendingEvents addObject:self->_selectedEvent];
            [self->_eventsView reloadData];
            if(self->_selectedEvent.reqId < 0)
                self->_selectedEvent.expirationTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(_sendRequestDidExpire:) userInfo:self->_selectedEvent repeats:NO];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else if(e.rowType == ROW_REPLY_COUNT) {
        [self setMsgId:[[e.entities objectForKey:@"parent"] msgid]];
    } else {
        [self->_eventsView clearLastSeenMarker];
    }
    [self closeColorPicker];
}

-(void)rowSelected:(Event *)event {
    if(self->_doubleTapTimer) {
        [self->_doubleTapTimer invalidate];
        self->_doubleTapTimer = nil;
        NSString *from = event.from;
        if(!from.length)
            from = event.nick;
        if(from.length) {
            self->_selectedUser = [[UsersDataSource sharedInstance] getUser:from cid:event.cid bid:event.bid];
            if(!_selectedUser) {
                self->_selectedUser = [[User alloc] init];
                self->_selectedUser.nick = event.fromNick;
                self->_selectedUser.display_name = event.from;
                self->_selectedUser.hostmask = event.hostmask;
                self->_selectedUser.parted = YES;
            }
            [self _mention];
        }
    } else {
        self->_doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_eventTapped:) userInfo:event repeats:NO];
    }
}

-(void)_mention {
    NSString *from = self->_selectedUser.nick;

    if(!from)
        return;

    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"mentionTip"];
    
    [self.slidingViewController resetTopView];
    
    if(self->_message.text.length == 0) {
        self->_message.text = self->_buffer.serverIsSlack ? [NSString stringWithFormat:@"@%@ ",_selectedUser.nick] : [NSString stringWithFormat:@"%@: ",_selectedUser.nick];
    } else {
        NSInteger oldPosition = self->_message.selectedRange.location;
        NSString *text = self->_message.text;
        NSInteger start = oldPosition - 1;
        if(start > 0 && [text characterAtIndex:start] == ' ')
            start--;
        while(start > 0 && [text characterAtIndex:start] != ' ')
            start--;
        if(start < 0)
            start = 0;
        NSRange range = [text rangeOfString:from options:0 range:NSMakeRange(start, text.length - start)];
        NSInteger match = range.location;
        char nextChar = (range.location != NSNotFound && range.location + range.length < text.length)?[text characterAtIndex:range.location + range.length]:0;
        if(match != NSNotFound && (nextChar == 0 || nextChar == ' ' || nextChar == ':')) {
            NSMutableString *newtext = [[NSMutableString alloc] init];
            if(match > 1 && ([text characterAtIndex:match - 1] == ' ' || [text characterAtIndex:match - 1] == '@'))
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
            if([newtext isEqualToString:@"@"])
                newtext = (NSMutableString *)@"";
            self->_message.text = newtext;
            if(match < newtext.length)
                self->_message.selectedRange = NSMakeRange(match, 0);
            else
                self->_message.selectedRange = NSMakeRange(newtext.length, 0);
        } else {
            if(oldPosition == text.length - 1) {
                text = [NSString stringWithFormat:@" %@", from];
            } else {
                NSMutableString *newtext = [[NSMutableString alloc] initWithString:[text substringWithRange:NSMakeRange(0, oldPosition)]];
                if(self->_buffer.serverIsSlack && ![newtext hasSuffix:@"@"])
                    from = [NSString stringWithFormat:@"@%@", from];
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
            self->_message.text = text;
            if(text.length > 0) {
                if(oldPosition + from.length + 2 < text.length)
                    self->_message.selectedRange = NSMakeRange(oldPosition + from.length, 0);
                else
                    self->_message.selectedRange = NSMakeRange(text.length, 0);
            }
        }
    }
    [self->_message becomeFirstResponder];
}

-(void)_showUserPopupInRect:(CGRect)rect {
    [self dismissKeyboard];
    NSString *title = @"";;
    Server *server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    if(self->_selectedUser) {
        if(!_buffer.serverIsSlack && ([self->_selectedUser.hostmask isKindOfClass:[NSString class]] &&_selectedUser.hostmask.length && (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)))
            title = [NSString stringWithFormat:@"%@\n(%@)",_selectedUser.display_name,[self->_selectedUser.hostmask stripIRCFormatting]];
        else
            title = self->_selectedUser.nick;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle;
    
    void (^handler)(UIAlertAction *action) = ^(UIAlertAction *a) {
        [self actionSheetActionClicked:a.title];
    };
    if(self->_selectedURL) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Copy URL" style:UIAlertActionStyleDefault handler:handler]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Share URL" style:UIAlertActionStyleDefault handler:handler]];
    }
    if(self->_selectedEvent) {
        if([[self->_selectedEvent.entities objectForKey:@"own_file"] intValue]) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete File" style:UIAlertActionStyleDefault handler:handler]];
        }
        if(self->_selectedEvent.rowType == ROW_THUMBNAIL || _selectedEvent.rowType == ROW_FILE)
            [alert addAction:[UIAlertAction actionWithTitle:@"Close Preview" style:UIAlertActionStyleDefault handler:handler]];
        if(self->_selectedEvent.msg.length || self->_selectedEvent.groupMsg.length)
            [alert addAction:[UIAlertAction actionWithTitle:@"Copy Message" style:UIAlertActionStyleDefault handler:handler]];
        if(!server.blocksReplies && !_msgid && _selectedEvent.msgid && ([self->_selectedEvent.type isEqualToString:@"buffer_msg"] || [self->_selectedEvent.type isEqualToString:@"buffer_me_msg"] || [self->_selectedEvent.type isEqualToString:@"notice"])) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Reply" style:UIAlertActionStyleDefault handler:handler]];
        }
        if(!server.blocksEdits && self->_selectedEvent.isSelf && _selectedEvent.msgid.length && (server.isSlack || server.orgId) && self->_selectedEvent.chan) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Edit Message" style:UIAlertActionStyleDefault handler:handler]];
        }
        if(!server.blocksDeletes && self->_selectedEvent.isSelf && _selectedEvent.msgid.length && (server.isSlack || server.orgId)) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete Message" style:UIAlertActionStyleDefault handler:handler]];
        }
    }
    if(self->_selectedUser) {
        if(self->_buffer.serverIsSlack)
            [alert addAction:[UIAlertAction actionWithTitle:@"Slack Profile" style:UIAlertActionStyleDefault handler:handler]];
        if(!_buffer.serverIsSlack)
            [alert addAction:[UIAlertAction actionWithTitle:@"Whois" style:UIAlertActionStyleDefault handler:handler]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Send a Message" style:UIAlertActionStyleDefault handler:handler]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Mention" style:UIAlertActionStyleDefault handler:handler]];
        if(!_buffer.serverIsSlack)
            [alert addAction:[UIAlertAction actionWithTitle:@"Invite to Channel" style:UIAlertActionStyleDefault handler:handler]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignore" style:UIAlertActionStyleDefault handler:handler]];
        if(!_buffer.serverIsSlack && [self->_buffer.type isEqualToString:@"channel"]) {
            User *me = [[UsersDataSource sharedInstance] getUser:[[ServersDataSource sharedInstance] getServer:self->_buffer.cid].nick cid:self->_buffer.cid bid:self->_buffer.bid];
            if([me.mode rangeOfString:server?server.MODE_OPER:@"Y"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OWNER:@"q"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_ADMIN:@"a"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound) {
                if([self->_selectedUser.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound)
                    [alert addAction:[UIAlertAction actionWithTitle:@"Deop" style:UIAlertActionStyleDefault handler:handler]];
                else
                    [alert addAction:[UIAlertAction actionWithTitle:@"Op" style:UIAlertActionStyleDefault handler:handler]];
            }
            if([me.mode rangeOfString:server?server.MODE_OPER:@"Y"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OWNER:@"q"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_ADMIN:@"a"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_OP:@"o"].location != NSNotFound || [me.mode rangeOfString:server?server.MODE_HALFOP:@"h"].location != NSNotFound) {
                if([self->_selectedUser.mode rangeOfString:server?server.MODE_VOICED:@"v"].location != NSNotFound)
                    [alert addAction:[UIAlertAction actionWithTitle:@"Devoice" style:UIAlertActionStyleDefault handler:handler]];
                else
                    [alert addAction:[UIAlertAction actionWithTitle:@"Voice" style:UIAlertActionStyleDefault handler:handler]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Kick" style:UIAlertActionStyleDefault handler:handler]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ban" style:UIAlertActionStyleDefault handler:handler]];
            }
        }
        if(!_buffer.serverIsSlack)
            [alert addAction:[UIAlertAction actionWithTitle:@"Copy Hostmask" style:UIAlertActionStyleDefault handler:handler]];
    }
    
    if(self->_selectedEvent)
        [alert addAction:[UIAlertAction actionWithTitle:@"Clear Backlog" style:UIAlertActionStyleDefault handler:handler]];

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:handler]];
    }
    
    alert.popoverPresentationController.sourceRect = rect;
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_userTapped {
    [self _showUserPopupInRect:self->_selectedRect];
    self->_doubleTapTimer = nil;
}

-(void)userSelected:(NSString *)nick rect:(CGRect)rect {
    rect = [_usersView.tableView convertRect:rect toView:self.view];
    self->_selectedRect = rect;
    self->_selectedEvent = nil;
    self->_selectedURL = nil;
    self->_selectedUser = [[UsersDataSource sharedInstance] getUser:nick cid:self->_buffer.cid bid:self->_buffer.bid];
    if(self->_doubleTapTimer) {
        [self->_doubleTapTimer invalidate];
        self->_doubleTapTimer = nil;
        [self.slidingViewController resetTopViewWithAnimations:nil onComplete:^{
            [self _mention];
        }];
    } else {
        self->_doubleTapTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_userTapped) userInfo:nil repeats:NO];
    }
}

-(void)markAsRead {
    [[NetworkConnection sharedInstance] heartbeat:self->_buffer.bid cid:self->_buffer.cid bid:self->_buffer.bid lastSeenEid:[[EventsDataSource sharedInstance] lastEidForBuffer:self->_buffer.bid] handler:nil];
    self->_buffer.last_seen_eid = [[EventsDataSource sharedInstance] lastEidForBuffer:self->_buffer.bid];
}

-(void)markAllAsRead {
    NSMutableArray *cids = [[NSMutableArray alloc] init];
    NSMutableArray *bids = [[NSMutableArray alloc] init];
    NSMutableArray *eids = [[NSMutableArray alloc] init];
    
    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
        if([[EventsDataSource sharedInstance] unreadStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] && [[EventsDataSource sharedInstance] lastEidForBuffer:b.bid]) {
            [cids addObject:@(b.cid)];
            [bids addObject:@(b.bid)];
            [eids addObject:@([[EventsDataSource sharedInstance] lastEidForBuffer:b.bid])];
        }
    }
    
    [[NetworkConnection sharedInstance] heartbeat:self->_buffer.bid cids:cids bids:bids lastSeenEids:eids handler:nil];
}

-(void)editConnection {
    EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [ecv setServer:self->_selectedBuffer.cid];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)_deleteSelectedBuffer {
    [self dismissKeyboard];
    [self.view.window endEditing:YES];
    NSString *title = [self->_selectedBuffer.type isEqualToString:@"console"]?@"Delete Connection":@"Clear History";
    NSString *msg;
    if([self->_selectedBuffer.type isEqualToString:@"console"]) {
        msg = @"Are you sure you want to remove this connection?";
    } else if([self->_selectedBuffer.type isEqualToString:@"channel"]) {
        msg = [NSString stringWithFormat:@"Are you sure you want to clear your history in %@?", _selectedBuffer.name];
    } else {
        msg = [NSString stringWithFormat:@"Are you sure you want to clear your history with %@?", _selectedBuffer.name];
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if([self->_selectedBuffer.type isEqualToString:@"console"]) {
            [[NetworkConnection sharedInstance] deleteServer:self->_selectedBuffer.cid handler:nil];
        } else if(self->_selectedBuffer == nil || self->_selectedBuffer.bid == -1) {
            if([[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] && [[BuffersDataSource sharedInstance] getBuffer:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]])
                [self bufferSelected:[[[NetworkConnection sharedInstance].userInfo objectForKey:@"last_selected_bid"] intValue]];
            else
                [self bufferSelected:[[BuffersDataSource sharedInstance] mostRecentBid]];
        } else {
            [[NetworkConnection sharedInstance] deleteBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)addNetwork {
    EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
    [self.slidingViewController resetTopView];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)_reorder {
    ServerReorderViewController *svc = [[ServerReorderViewController alloc] initWithStyle:UITableViewStylePlain];
    [self.slidingViewController resetTopView];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)_inviteToChannel {
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedUser?_buffer.cid:self->_selectedBuffer.cid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Invite to channel" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Invite" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
            if(self->_selectedUser)
                [[NetworkConnection sharedInstance] invite:self->_selectedUser.nick chan:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_buffer.cid handler:nil];
            else
                [[NetworkConnection sharedInstance] invite:((UITextField *)[alert.textFields objectAtIndex:0]).text chan:self->_selectedBuffer.name cid:self->_selectedBuffer.cid handler:nil];
        }
    }]];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = self->_selectedUser?@"#channel":@"nickname";
        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_joinAChannel {
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedBuffer.cid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Which channel do you want to join?" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Join" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/join %@",((UITextField *)[alert.textFields objectAtIndex:0]).text] to:nil cid:self->_selectedBuffer.cid handler:nil];
        }
    }]];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"#channel";
        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_renameBuffer:(Buffer *)b msg:(NSString *)msg {
    if(!msg) {
        msg = [NSString stringWithFormat:@"Choose a new name for this %@", b.type];
    } else {
        if([msg isEqualToString:@"invalid_name"]) {
            if([b.type isEqualToString:@"channel"])
                msg = @"You must choose a valid channel name";
            else
                msg = @"You must choose a valid nick name";
        } else if([msg isEqualToString:@"not_conversation"]) {
            msg = @"You can only rename private messages";
        } else if([msg isEqualToString:@"not_channel"]) {
            msg = @"You can only rename channels";
        } else if([msg isEqualToString:@"name_exists"]) {
            msg = @"That name is already taken";
        } else if([msg isEqualToString:@"channel_joined"]) {
            msg = @"You can only rename parted channels";
        }
        msg = [NSString stringWithFormat:@"Error renaming: %@. Please choose a new name for this %@", msg, b.type];
    }
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedBuffer.cid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:msg preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
            id handler = ^(IRCCloudJSONObject *result) {
                if([[result objectForKey:@"success"] intValue] == 0) {
                    CLS_LOG(@"Rename failed: %@", result);
                    [self _renameBuffer:self->_selectedBuffer msg:[result objectForKey:@"message"]];
                }
            };
            if([self->_selectedBuffer.type isEqualToString:@"channel"])
                [[NetworkConnection sharedInstance] renameChannel:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_selectedBuffer.cid bid:self->_selectedBuffer.bid handler:handler];
            else
                [[NetworkConnection sharedInstance] renameConversation:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_selectedBuffer.cid bid:self->_selectedBuffer.bid handler:handler];
        }
    }]];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = b.name;
        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)bufferLongPressed:(int)bid rect:(CGRect)rect {
    self->_selectedUser = nil;
    self->_selectedURL = nil;
    self->_selectedBuffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle;
    if([self->_selectedBuffer.type isEqualToString:@"console"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedBuffer.cid];
        if([s.status isEqualToString:@"disconnected"]) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Reconnect" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] reconnect:self->_selectedBuffer.cid handler:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *alert) {
                [self _deleteSelectedBuffer];
            }]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Disconnect" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] disconnect:self->_selectedBuffer.cid msg:nil handler:nil];
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Edit Connection" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self editConnection];
        }]];
#ifndef ENTERPRISE
        Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:@"*" server:s.cid];
        if(b.archived) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Expand" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] unarchiveBuffer:b.bid cid:b.cid handler:nil];
            }]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Collapse" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] archiveBuffer:b.bid cid:b.cid handler:nil];
            }]];
        }
#endif
    } else if([self->_selectedBuffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:self->_selectedBuffer.bid]) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Leave" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] part:self->_selectedBuffer.name msg:nil cid:self->_selectedBuffer.cid handler:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Invite to Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [self _inviteToChannel];
            }]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Rejoin" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] join:self->_selectedBuffer.name key:nil cid:self->_selectedBuffer.cid handler:nil];
            }]];
            if(self->_selectedBuffer.archived) {
                [alert addAction:[UIAlertAction actionWithTitle:@"Unarchive" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                    [[NetworkConnection sharedInstance] unarchiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
                }]];
            } else {
                [alert addAction:[UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                    [[NetworkConnection sharedInstance] archiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
                }]];
            }
            [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [self _renameBuffer:self->_selectedBuffer msg:nil];
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *alert) {
            [self _deleteSelectedBuffer];
        }]];
    } else {
        if(self->_selectedBuffer.archived) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Unarchive" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] unarchiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
            }]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:@"Archive" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                [[NetworkConnection sharedInstance] archiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self _renameBuffer:self->_selectedBuffer msg:nil];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *alert) {
            [self _deleteSelectedBuffer];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Mark All as Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self markAllAsRead];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add a Network" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self addNetwork];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Join a Channel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self _joinAChannel];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Send a Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedBuffer.cid];
        UIAlertController *a = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Which nick do you want to message?" preferredStyle:UIAlertControllerStyleAlert];
        
        [a addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [a addAction:[UIAlertAction actionWithTitle:@"Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[a.textFields objectAtIndex:0]).text.length) {
                [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@",((UITextField *)[a.textFields objectAtIndex:0]).text] to:nil cid:self->_selectedBuffer.cid handler:nil];
            }
        }]];
        
        [a addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"nickname";
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:a animated:YES completion:nil];
    }]];

    BOOL activeCount = NO;
    NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffersForServer:self->_selectedBuffer.cid];
    for(Buffer *b in buffers) {
        if([b.type isEqualToString:@"conversation"] && !b.archived) {
            activeCount = YES;
            break;
        }
    }
    
    if(activeCount) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete Active Conversations" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *alert) {
            [self spamSelected:self->_selectedBuffer.cid];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Reorder Connections" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self _reorder];
    }]];
    
    if(!self->_selectedBuffer.archived && ([self->_selectedBuffer.type isEqualToString:@"channel"] || [self->_selectedBuffer.type isEqualToString:@"conversation"])) {
        BOOL pinned = NO;
        
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        
        if([[prefs objectForKey:@"pinnedBuffers"] isKindOfClass:NSArray.class] && [(NSArray *)[prefs objectForKey:@"pinnedBuffers"] count] > 0) {
            for(NSNumber *n in [prefs objectForKey:@"pinnedBuffers"]) {
                if(n.intValue == self->_selectedBuffer.bid) {
                    pinned = YES;
                    break;
                }
            }
        }
        
        if(pinned) {
            [alert addAction:[UIAlertAction actionWithTitle:@"Reorder Pins" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                PinReorderViewController *pvc = [[PinReorderViewController alloc] initWithStyle:UITableViewStylePlain];
                [self.slidingViewController resetTopView];
                UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pvc];
                [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
                if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                    nc.modalPresentationStyle = UIModalPresentationFormSheet;
                else
                    nc.modalPresentationStyle = UIModalPresentationCurrentContext;
                [self presentViewController:nc animated:YES completion:nil];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:@"Remove Pin" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                NSMutableDictionary *mutablePrefs = prefs.mutableCopy;
                NSMutableArray *pinnedBuffers;
                if([[prefs objectForKey:@"pinnedBuffers"] isKindOfClass:NSArray.class] && [(NSArray *)[prefs objectForKey:@"pinnedBuffers"] count] > 0) {
                    pinnedBuffers = ((NSArray *)[prefs objectForKey:@"pinnedBuffers"]).mutableCopy;
                } else {
                    pinnedBuffers = [[NSMutableArray alloc] init];
                }
                [pinnedBuffers removeObject:@(self->_selectedBuffer.bid)];
                [mutablePrefs setObject:pinnedBuffers forKey:@"pinnedBuffers"];
                SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                NSString *json = [writer stringWithObject:mutablePrefs];

                [[NetworkConnection sharedInstance] setPrefs:json handler:^(IRCCloudJSONObject *result) {
                    if(![[result objectForKey:@"success"] boolValue]) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }]];
        } else {
            [alert addAction:[UIAlertAction actionWithTitle:[self->_selectedBuffer.type isEqualToString:@"channel"]?@"Pin Channel":@"Pin Conversation" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                NSMutableDictionary *mutablePrefs = prefs.mutableCopy;
                NSMutableArray *pinnedBuffers;
                if([[prefs objectForKey:@"pinnedBuffers"] isKindOfClass:NSArray.class] && [(NSArray *)[prefs objectForKey:@"pinnedBuffers"] count] > 0) {
                    pinnedBuffers = ((NSArray *)[prefs objectForKey:@"pinnedBuffers"]).mutableCopy;
                } else {
                    pinnedBuffers = [[NSMutableArray alloc] init];
                }
                [pinnedBuffers addObject:@(self->_selectedBuffer.bid)];
                [mutablePrefs setObject:pinnedBuffers forKey:@"pinnedBuffers"];
                SBJson5Writer *writer = [[SBJson5Writer alloc] init];
                NSString *json = [writer stringWithObject:mutablePrefs];

                [[NetworkConnection sharedInstance] setPrefs:json handler:^(IRCCloudJSONObject *result) {
                    if(![[result objectForKey:@"success"] boolValue]) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }]];
        }
    }

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    alert.popoverPresentationController.sourceRect = rect;
    alert.popoverPresentationController.sourceView = self->_buffersView.tableView;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)spamSelected:(int)cid {
    Server *s = [[ServersDataSource sharedInstance] getServer:cid];
    SpamViewController *svc = [[SpamViewController alloc] initWithCid:cid];
    svc.navigationItem.title = s.hostname;
    [self.slidingViewController resetTopView];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)rowLongPressed:(Event *)event rect:(CGRect)rect link:(NSString *)url {
    rect = [_eventsView.tableView convertRect:rect toView:self.view];
    if(event && (event.msg.length || event.groupMsg.length || event.rowType == ROW_THUMBNAIL)) {
        NSString *from = event.from;
        if(!from.length)
            from = event.nick;
        if(from) {
            self->_selectedUser = [[UsersDataSource sharedInstance] getUser:from cid:self->_buffer.cid bid:self->_buffer.bid];
            if(!_selectedUser) {
                self->_selectedUser = [[User alloc] init];
                self->_selectedUser.cid = self->_selectedEvent.cid;
                self->_selectedUser.bid = self->_selectedEvent.bid;
                self->_selectedUser.nick = from;
                self->_selectedUser.parted = YES;
            }
            if(event.hostmask.length)
                self->_selectedUser.hostmask = event.hostmask;
        } else {
            self->_selectedUser = nil;
        }
        self->_selectedEvent = event;
        self->_selectedRect = rect;
        self->_selectedURL = url;
        if([self->_selectedURL hasPrefix:@"irccloud-paste-"])
            self->_selectedURL = [self->_selectedURL substringFromIndex:15];
        [self _showUserPopupInRect:rect];
    }
}

-(IBAction)titleAreaPressed:(id)sender {
    if([NetworkConnection sharedInstance].state == kIRCCloudStateDisconnected) {
        [[NetworkConnection sharedInstance] connect:NO];
    } else {
        if(self->_buffer && !_buffer.isMPDM && [self->_buffer.type isEqualToString:@"channel"] && [[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
            ChannelInfoViewController *c = [[ChannelInfoViewController alloc] initWithChannel:[[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:c];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationPageSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            [self presentViewController:nc animated:YES completion:nil];
        }
    }
    [self closeColorPicker];
}

-(void)_setSelectedBuffer:(Buffer *)b {
    self->_selectedBuffer = b;
}

-(void)clearText {
    [self->_message clearText];
}

-(void)choosePhoto:(UIImagePickerControllerSourceType)sourceType {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"])
        picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:sourceType];
    picker.delegate = (id)self;
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone || sourceType == UIImagePickerControllerSourceTypeCamera) {
        [UIColor clearTheme];
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [UIColor clearTheme];
        picker.modalPresentationStyle = UIModalPresentationFormSheet;
        picker.preferredContentSize = CGSizeMake(540, 576);
        [self presentViewController:picker animated:YES completion:nil];
    }
}

-(void)chooseFile {
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypePackage, (NSString *)kUTTypeData]
                                                                                                            inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = self;
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    else {
        documentPicker.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    if(documentPicker) {
        [UIColor clearTheme];
        [self presentViewController:documentPicker animated:YES completion:nil];
    }
}

-(void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [UIColor setTheme];
    [self applyTheme];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [self documentPicker:controller didPickDocumentAtURL:urls[0]];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    [UIColor setTheme];
    [self applyTheme];
    FileUploader *u = [[FileUploader alloc] init];
    FileMetadataViewController *fvc = [[FileMetadataViewController alloc] initWithUploader:u];
    u.delegate = self;
    u.metadatadelegate = fvc;
    u.bid = self->_buffer.bid;
    u.msgid = self->_msgid;
    [u uploadFile:url];
    
    if([u.mimeType hasPrefix:@"image/"]) {
        NSData *d = [NSData dataWithContentsOfURL:url];
        UIImage *thumbnail = [UIImage imageWithData:d];
        if(thumbnail) {
            thumbnail = [FileUploader image:thumbnail scaledCopyOfSize:CGSizeMake(2048, 2048)];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [fvc setImage:thumbnail];
                [fvc viewWillAppear:YES];
            }];
        }
    }

    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fvc];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)_imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [UIColor setTheme];
    [self applyTheme];
    FileMetadataViewController *fvc = nil;
    NSURL *refURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSURL *mediaURL = [info valueForKey:UIImagePickerControllerMediaURL];
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!img)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CLS_LOG(@"Image file chosen: %@ %@", refURL, mediaURL);
    if(img || refURL || mediaURL) {
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera && [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"]) {
            if(img)
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
            else if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path))
                UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil);
        }
        if((!img || [[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"IRCCloud"]) && [[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"]) {
            FileUploader *u = [[FileUploader alloc] init];
            u.delegate = self;
            u.bid = self->_buffer.bid;
            u.msgid = self->_msgid;
            fvc = [[FileMetadataViewController alloc] initWithUploader:u];
            if(picker == nil || picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                [fvc showCancelButton];
            }
            
            if(refURL) {
#if !TARGET_OS_MACCATALYST
                CLS_LOG(@"Loading metadata from asset library");
                ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset) {
                    ALAssetRepresentation *imageRep = [imageAsset defaultRepresentation];
                    CLS_LOG(@"Got filename: %@", imageRep.filename);
                    u.originalFilename = imageRep.filename;
                    if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.movie"]) {
                        CLS_LOG(@"Uploading file URL");
                        u.originalFilename = [u.originalFilename stringByReplacingOccurrencesOfString:@".MOV" withString:@".MP4"];
                        [u uploadVideo:[info objectForKey:UIImagePickerControllerMediaURL]];
                        [fvc viewWillAppear:NO];
                    } else if([imageRep.filename.lowercaseString hasSuffix:@".gif"] || [imageRep.filename.lowercaseString hasSuffix:@".png"]) {
                        CLS_LOG(@"Uploading file data");
                        NSMutableData *data = [[NSMutableData alloc] initWithCapacity:(NSUInteger)imageRep.size];
                        uint8_t buffer[4096];
                        long long len = 0;
                        while(len < imageRep.size) {
                            long long i = [imageRep getBytes:buffer fromOffset:len length:4096 error:nil];
                            [data appendBytes:buffer length:(NSUInteger)i];
                            len += i;
                        }
                        [u uploadFile:imageRep.filename UTI:imageRep.UTI data:data];
                        [fvc viewWillAppear:NO];
                    } else {
                        CLS_LOG(@"Uploading UIImage");
                        [u uploadImage:img];
                        [fvc viewWillAppear:NO];
                    }
                    if(imageRep.fullScreenImage) {
                        UIImage *thumbnail = [FileUploader image:[UIImage imageWithCGImage:imageRep.fullScreenImage] scaledCopyOfSize:CGSizeMake(2048, 2048)];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [fvc setImage:thumbnail];
                        }];
                    }
                };
                
                ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
                [assetslibrary assetForURL:refURL resultBlock:resultblock failureBlock:^(NSError *e) {
                    CLS_LOG(@"Error getting asset: %@", e);
                    if(img) {
                        [u uploadImage:img];
                        UIImage *thumbnail = [FileUploader image:img scaledCopyOfSize:CGSizeMake(2048, 2048)];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [fvc setImage:thumbnail];
                        }];
                    } else if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.movie"]) {
                        [u uploadVideo:mediaURL];
                    } else {
                        [u uploadFile:mediaURL];
                    }
                    [fvc viewWillAppear:NO];
                }];
#endif
            } else if([info objectForKey:@"gifData"]) {
                CLS_LOG(@"Uploading GIF from Pasteboard");
                [u uploadFile:[NSString stringWithFormat:@"%li.GIF", time(NULL)] UTI:@"image/gif" data:[info objectForKey:@"gifData"]];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [fvc setImage:img];
                }];
            } else {
                CLS_LOG(@"no asset library URL, uploading image data instead");
                if(img) {
                    [u uploadImage:img];
                    UIImage *thumbnail = [FileUploader image:img scaledCopyOfSize:CGSizeMake(2048, 2048)];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [fvc setImage:thumbnail];
                    }];
                } else if([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:@"public.movie"]) {
                    [u uploadVideo:mediaURL];
                } else {
                    [u uploadFile:mediaURL];
                }
            }
        } else {
            [self _showConnectingView];
            self->_connectingStatus.text = @"Uploading";
            self->_connectingProgress.progress = 0;
            self->_connectingProgress.hidden = YES;
            ImageUploader *u = [[ImageUploader alloc] init];
            u.delegate = self;
            u.bid = self->_buffer.bid;
            [u upload:img];
        }
    }
    
    UINavigationController *nc = nil;
    
    if(fvc) {
        nc = [[UINavigationController alloc] initWithRootViewController:fvc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    }
    
    if(self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:^{
            if(nc)
                [self presentViewController:nc animated:YES completion:nil];
        }];
    } else if(nc) {
        [self presentViewController:nc animated:YES completion:nil];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self _imagePickerController:picker didFinishPickingMediaWithInfo:info];
    }];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    CLS_LOG(@"Image picker was cancelled");
    [UIColor setTheme];
    [self applyTheme];
    [self dismissViewControllerAnimated:YES completion:nil];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"])
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    [self _hideConnectingView];
}

-(void)filesTableViewControllerDidSelectFile:(NSDictionary *)file message:(NSString *)message {
    if(message.length)
        message = [message stringByAppendingString:@" "];
    message = [message stringByAppendingString:[file objectForKey:@"url"]];
    [[NetworkConnection sharedInstance] say:message to:self->_buffer.name cid:self->_buffer.cid handler:nil];
}

-(void)fileUploadProgress:(float)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if(!self.presentedViewController) {
            if(self.navigationItem.titleView != self->_connectingView) {
                [self _showConnectingView];
                self->_connectingStatus.text = @"Uploading";
                self->_connectingProgress.progress = progress;
            }
            self->_connectingProgress.hidden = NO;
            [self->_connectingProgress setProgress:progress animated:YES];
        }
    }];
}

-(void)fileUploadDidFail:(NSString *)reason {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CLS_LOG(@"File upload failed: %@", reason);
        NSString *msg;
        if([reason isEqualToString:@"upload_limit_reached"]) {
            msg = @"Sorry, you can’t upload more than 100 MB of files.  Delete some uploads and try again.";
        } else if([reason isEqualToString:@"upload_already_exists"]) {
            msg = @"You’ve already uploaded this file";
        } else if([reason isEqualToString:@"banned_content"]) {
            msg = @"Banned content";
        } else {
            msg = @"Failed to upload file. Please try again shortly.";
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:msg preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self _hideConnectingView];
    }];
}

-(void)fileUploadTooLarge {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CLS_LOG(@"File upload too large");
        [self dismissViewControllerAnimated:YES completion:nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"Sorry, you can’t upload files larger than 15 MB" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self _hideConnectingView];
    }];
}

-(void)fileUploadDidFinish {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CLS_LOG(@"File upload did finish");
        [self _hideConnectingView];
    }];
}

-(void)fileUploadWasCancelled {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CLS_LOG(@"File upload was cancelled");
        [self _hideConnectingView];
    }];
}

-(void)imageUploadProgress:(float)progress {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self->_connectingProgress.hidden = NO;
        [self->_connectingProgress setProgress:progress animated:YES];
    }];
}

-(void)imageUploadDidFail {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"An error occured while uploading the photo. Please try again." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self _hideConnectingView];
    }];
}

-(void)imageUploadNotAuthorized {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self _hideConnectingView];
        SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        [nc pushViewController:[[ImgurLoginViewController alloc] init] animated:NO];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        if(self.presentedViewController)
            [self dismissViewControllerAnimated:NO completion:nil];
        [self presentViewController:nc animated:YES completion:nil];
    }];
}

-(void)imageUploadDidFinish:(NSDictionary *)d bid:(int)bid {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([[d objectForKey:@"success"] intValue] == 1) {
            NSString *link = [[[d objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
            Buffer *b = self->_buffer;
            if(bid == self->_buffer.bid) {
                if(self->_message.text.length == 0) {
                    self->_message.text = link;
                } else {
                    if(![self->_message.text hasSuffix:@" "])
                        self->_message.text = [self->_message.text stringByAppendingString:@" "];
                    self->_message.text = [self->_message.text stringByAppendingString:link];
                }
            } else {
                b = [[BuffersDataSource sharedInstance] getBuffer:bid];
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
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                [[NotificationsDataSource sharedInstance] alert:@"Your image has been uploaded and is ready to send" title:nil category:nil userInfo:@{@"d":@[@(b.cid), @(b.bid), @(-1)]}];
            }
        } else {
            CLS_LOG(@"imgur upload failed: %@", d);
            [self imageUploadDidFail];
            return;
        }
        [self _hideConnectingView];
    }];
}

-(void)startPastebin {
    if(self->_buffer) {
        PastebinEditorViewController *pv = [[PastebinEditorViewController alloc] initWithBuffer:self->_buffer];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pv];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        if(self.presentedViewController)
            [self dismissViewControllerAnimated:NO completion:nil];
        [self presentViewController:nc animated:YES completion:nil];
    }
}

-(void)showPastebins {
    PastebinsTableViewController *ptv = [[PastebinsTableViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ptv];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)showUploads {
    FilesTableViewController *fcv = [[FilesTableViewController alloc] initWithStyle:UITableViewStylePlain];
    fcv.delegate = self;
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:fcv];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)uploadsButtonPressed:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    alert.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle;

    BOOL isCatalyst = NO;
    if (@available(iOS 13.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp)
            isCatalyst = YES;
    }
    
    if(!isCatalyst) {
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [alert addAction:[UIAlertAction actionWithTitle:([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"])?@"Take Photo or Video":@"Take a Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self choosePhoto:UIImagePickerControllerSourceTypeCamera];
            }]];
        }
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            [alert addAction:[UIAlertAction actionWithTitle:([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"])?@"Choose Photo or Video":@"Choose Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
                if(self.presentedViewController)
                    [self dismissViewControllerAnimated:NO completion:nil];
                [self choosePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
            }]];
        }
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Choose Document" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            if(self.presentedViewController)
                [self dismissViewControllerAnimated:NO completion:nil];
            [self chooseFile];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Start a Text Snippet" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self startPastebin];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Text Snippets" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        [self showPastebins];
    }]];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"File Uploads" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self showUploads];
        }]];
    }
#ifndef ENTERPRISE
    BOOL avatars_supported = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid].avatars_supported;
    if([[ServersDataSource sharedInstance] getServer:self->_buffer.cid].isSlack)
        avatars_supported = NO;
    [alert addAction:[UIAlertAction actionWithTitle:avatars_supported?@"Change Avatar":@"Change Public Avatar" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
        AvatarsTableViewController *atv = [[AvatarsTableViewController alloc] initWithServer:avatars_supported?self->_buffer.cid:-1];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:atv];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:nc animated:YES completion:nil];
    }]];
#endif
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    alert.popoverPresentationController.sourceRect = CGRectMake(self->_bottomBar.frame.origin.x + _uploadsBtn.frame.origin.x, _bottomBar.frame.origin.y,_uploadsBtn.frame.size.width,_uploadsBtn.frame.size.height);
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)actionSheetActionClicked:(NSString *)action {
    [self->_message resignFirstResponder];
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
        
    if([action isEqualToString:@"Copy Message"]) {
        Event *e = self->_selectedEvent;
        if(e.parent)
            e = [[EventsDataSource sharedInstance] event:e.parent buffer:e.bid];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        NSString *irc;
        if(e.groupMsg.length) {
            irc = [NSString stringWithFormat:@"%@ %@",e.timestamp,e.groupMsg];
        } else if(e.from.length || [e.type isEqualToString:@"buffer_me_msg"]) {
            irc = [e.type isEqualToString:@"buffer_me_msg"]?[NSString stringWithFormat:@"%@ %c— %@%c %@",e.timestamp,BOLD,e.nick,CLEAR,e.msg]:[NSString stringWithFormat:@"%@ %c<%@>%c %@",e.timestamp,BOLD,e.from,CLEAR,e.msg];
        } else {
            irc = [NSString stringWithFormat:@"%@ %@",e.timestamp,e.msg];
        }
        irc = [irc stringByReplacingOccurrencesOfString:@"\u00a0" withString:@" "];
        NSAttributedString *msg = [ColorFormatter format:irc defaultColor:nil mono:NO linkify:NO server:nil links:nil];
        pb.items = @[@{(NSString *)kUTTypeRTF:[msg dataFromRange:NSMakeRange(0, msg.length) documentAttributes:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType} error:nil],(NSString *)kUTTypeUTF8PlainText:msg.string,@"IRC formatting type":[irc dataUsingEncoding:NSUTF8StringEncoding]}];
    } else if([action isEqualToString:@"Clear Backlog"]) {
        int bid = self->_selectedBuffer?_selectedBuffer.bid:self->_selectedEvent.bid;
        [[EventsDataSource sharedInstance] removeEventsForBuffer:bid];
        if(self->_buffer.bid == bid)
            [self->_eventsView refresh];
    } else if([action isEqualToString:@"Copy URL"]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setValue:self->_selectedURL forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
    } else if([action isEqualToString:@"Share URL"]) {
        [UIColor clearTheme];
        UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[[NSURL URLWithString:self->_selectedURL]] type:@"URL"];
        activityController.popoverPresentationController.sourceView = self.view;
        activityController.popoverPresentationController.sourceRect = self->_selectedRect;
        [self presentViewController:activityController animated:YES completion:nil];
    } else if([action isEqualToString:@"Delete Message"]) {
        [self dismissKeyboard];
        [self.view.window endEditing:YES];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Message" message:@"Are you sure you want to delete this message?" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [[NetworkConnection sharedInstance] deleteMessage:self->_selectedEvent.msgid cid:self->_selectedEvent.cid to:self->_selectedEvent.chan handler:^(IRCCloudJSONObject *result) {
                if(![[result objectForKey:@"success"] boolValue]) {
                    CLS_LOG(@"Error deleting message: %@", result);
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to delete message, please try again." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if([action isEqualToString:@"Edit Message"]) {
        [self dismissKeyboard];
        [self.view.window endEditing:YES];
        
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_selectedEvent.cid];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Edit message" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length)
                [[NetworkConnection sharedInstance] editMessage:self->_selectedEvent.msgid cid:self->_selectedEvent.cid to:self->_selectedEvent.chan msg:((UITextField *)[alert.textFields objectAtIndex:0]).text handler:^(IRCCloudJSONObject *result) {
                    if(![[result objectForKey:@"success"] boolValue]) {
                        CLS_LOG(@"Error editing message: %@", result);
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to edit message, please try again." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                }];
        }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = self->_selectedEvent.msg;
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if([action isEqualToString:@"Delete File"]) {
        [[NetworkConnection sharedInstance] deleteFile:[self->_selectedEvent.entities objectForKey:@"id"] handler:^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                [self->_eventsView uncacheFile:[self->_selectedEvent.entities objectForKey:@"id"]];
                [self->_eventsView refresh];
            } else {
                CLS_LOG(@"Error deleting file: %@", result);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to delete file, please try again." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    } else if([action isEqualToString:@"Close Preview"]) {
        [self->_eventsView closePreview:self->_selectedEvent];
    } else if([action isEqualToString:@"Archive"]) {
        [[NetworkConnection sharedInstance] archiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Unarchive"]) {
        [[NetworkConnection sharedInstance] unarchiveBuffer:self->_selectedBuffer.bid cid:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Delete"]) {
        [self _deleteSelectedBuffer];
    } else if([action isEqualToString:@"Leave"]) {
        [[NetworkConnection sharedInstance] part:self->_selectedBuffer.name msg:nil cid:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Rejoin"]) {
        [[NetworkConnection sharedInstance] join:self->_selectedBuffer.name key:nil cid:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Rename"]) {
        [self _renameBuffer:self->_selectedBuffer msg:nil];
    } else if([action isEqualToString:@"Ban List"]) {
        [[NetworkConnection sharedInstance] mode:@"b" chan:self->_selectedBuffer.name cid:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Disconnect"]) {
        [[NetworkConnection sharedInstance] disconnect:self->_selectedBuffer.cid msg:nil handler:nil];
    } else if([action isEqualToString:@"Reconnect"]) {
        [[NetworkConnection sharedInstance] reconnect:self->_selectedBuffer.cid handler:nil];
    } else if([action isEqualToString:@"Logout"]) {
        [self logout];
    } else if([action isEqualToString:@"Ignore List"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        IgnoresTableViewController *itv = [[IgnoresTableViewController alloc] initWithStyle:UITableViewStylePlain];
        itv.ignores = s.ignores;
        itv.cid = s.cid;
        itv.navigationItem.title = @"Ignore List";
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:itv];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:nc animated:YES completion:nil];
    } else if([action isEqualToString:@"Mention"]) {
        [self.slidingViewController resetTopViewWithAnimations:nil onComplete:^{
            [self showMentionTip];
            [self _mention];
        }];
    } else if([action isEqualToString:@"Edit Connection"]) {
        [self editConnection];
    } else if([action isEqualToString:@"Settings"]) {
        [self showSettings];
    } else if([action isEqualToString:@"Display Options"]) {
        DisplayOptionsViewController *dvc = [[DisplayOptionsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        dvc.buffer = self->_buffer;
        dvc.navigationItem.title = self->_titleLabel.text;
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:dvc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:nc animated:YES completion:nil];
    } else if([action isEqualToString:@"Download Logs"]) {
        [self downloadLogs];
    } else if([action isEqualToString:@"Add Network"]) {
        [self addNetwork];
    } else if([action isEqualToString:@"Take a Photo"] || [action isEqualToString:@"Take Photo or Video"]) {
        if(self.presentedViewController)
            [self dismissViewControllerAnimated:NO completion:nil];
        [self choosePhoto:UIImagePickerControllerSourceTypeCamera];
    } else if([action isEqualToString:@"Choose Photo"] || [action isEqualToString:@"Choose Photo or Video"]) {
        if(self.presentedViewController)
            [self dismissViewControllerAnimated:NO completion:nil];
        [self choosePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
    } else if([action isEqualToString:@"Choose Document"]) {
        if(self.presentedViewController)
            [self dismissViewControllerAnimated:NO completion:nil];
        [self chooseFile];
    } else if([action isEqualToString:@"File Uploads"]) {
        [self showUploads];
    } else if([action isEqualToString:@"Text Snippets"]) {
        [self showPastebins];
    } else if([action isEqualToString:@"Start a Text Snippet"]) {
        [self startPastebin];
    } else if([action isEqualToString:@"Mark All As Read"]) {
        [self markAllAsRead];
    } else if([action isEqualToString:@"Add A Network"]) {
        [self addNetwork];
    } else if([action isEqualToString:@"Reorder"]) {
        [self _reorder];
    } else if([action isEqualToString:@"Invite to Channel"]) {
        [self _inviteToChannel];
    } else if([action isEqualToString:@"Join a Channel"]) {
        [self _joinAChannel];
    } else if([action isEqualToString:@"Whois"]) {
        if(self->_selectedUser && _selectedUser.nick.length > 0) {
            if(self->_selectedUser.parted) {
                [[NetworkConnection sharedInstance] whois:self->_selectedUser.nick server:nil cid:self->_buffer.cid handler:nil];
            } else {
                NSString *ircserver = self->_selectedUser.ircserver;
                if([ircserver rangeOfString:@"*"].location != NSNotFound)
                    ircserver = nil;
                [[NetworkConnection sharedInstance] whois:self->_selectedUser.nick server:ircserver.length?ircserver:self->_selectedUser.nick cid:self->_buffer.cid handler:nil];
            }
        } else if([self->_buffer.type isEqualToString:@"conversation"]) {
            User *u = [[UsersDataSource sharedInstance] getUser:self->_buffer.name cid:self->_buffer.cid];
            NSString *ircserver = u.ircserver;
            if([ircserver rangeOfString:@"*"].location != NSNotFound)
                ircserver = nil;
            [[NetworkConnection sharedInstance] whois:self->_buffer.name server:ircserver.length?ircserver:nil cid:self->_buffer.cid handler:nil];
        }
    } else if([action isEqualToString:@"Send Feedback"]) {
        [self sendFeedback];
    }
    
    if(!_selectedUser || !_selectedUser.nick || _selectedUser.nick.length < 1)
        return;
    
    if([action isEqualToString:@"Copy Hostmask"]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        NSString *plaintext = [NSString stringWithFormat:@"%@!%@", _selectedUser.nick, _selectedUser.hostmask];
        [pb setValue:plaintext forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
    } else if([action isEqualToString:@"Send a Message"]) {
        Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:self->_selectedUser.nick server:self->_buffer.cid];
        if(b) {
            [self bufferSelected:b.bid];
        } else {
            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", _selectedUser.nick] to:nil cid:self->_buffer.cid handler:nil];
        }
    } else if([action isEqualToString:@"Op"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+%@ %@",s?s.MODE_OP:@"o",_selectedUser.nick] chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
    } else if([action isEqualToString:@"Deop"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-%@ %@",s?s.MODE_OP:@"o",_selectedUser.nick] chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
    } else if([action isEqualToString:@"Voice"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+%@ %@",s?s.MODE_VOICED:@"v",_selectedUser.nick] chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
    } else if([action isEqualToString:@"Devoice"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-%@ %@",s?s.MODE_VOICED:@"v",_selectedUser.nick] chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
    } else if([action isEqualToString:@"Ban"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Add a ban mask" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ban" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
                [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+b %@", ((UITextField *)[alert.textFields objectAtIndex:0]).text] chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
            }
        }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if(self->_selectedUser.hostmask.length)
                textField.text = [NSString stringWithFormat:@"*!%@", self->_selectedUser.hostmask];
            else
                textField.text = [NSString stringWithFormat:@"%@!*", self->_selectedUser.nick];
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if([action isEqualToString:@"Ignore"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ignore messages from this mask" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Ignore" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
                [[NetworkConnection sharedInstance] ignore:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_buffer.cid handler:nil];
            }
        }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            if(self->_selectedUser.hostmask.length)
                textField.text = [NSString stringWithFormat:@"*!%@", self->_selectedUser.hostmask];
            else
                textField.text = [NSString stringWithFormat:@"%@!*", self->_selectedUser.nick];
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if([action isEqualToString:@"Kick"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Give a reason for kicking" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Kick" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
                [[NetworkConnection sharedInstance] kick:self->_selectedUser.nick chan:self->_buffer.name msg:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_buffer.cid handler:nil];
            }
        }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else if([action isEqualToString:@"Slack Profile"]) {
        Server *s = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/team/%@", s.slackBaseURL, _selectedUser.nick]];
        [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:url];
    } else if([action isEqualToString:@"Reply"]) {
        NSString *msgid = self->_selectedEvent.reply;
        if(!msgid)
            msgid = self->_selectedEvent.msgid;
        [self setMsgId:msgid];
    }
}

-(void)downloadLogs{
    LogExportsTableViewController *lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    lvc.buffer = self->_buffer;
    lvc.server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lvc];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationFormSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)showSettings {
//#if TARGET_OS_MACCATALYST
//        [[UIApplication sharedApplication] requestSceneSessionActivation:nil userActivity:[[NSUserActivity alloc] initWithActivityType:@"com.IRCCloud.settings"] options:nil errorHandler:nil];
//#else
        SettingsViewController *svc = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:svc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationPageSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewController:nc animated:YES completion:nil];
//#endif
}

-(void)logout {
    [self dismissKeyboard];
    [self.view.window endEditing:YES];
    
    NSURL *documentsPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    NSArray *documents = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsPath includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil];

    UIAlertController *alert;
    if (documents.count) {
        alert = [UIAlertController alertControllerWithTitle:@"Logout" message:[NSString stringWithFormat:@"You currently have %lu log export%@ stored on this device. %@ will remain on this device after logging out.", (unsigned long)documents.count, documents.count == 1?@"":@"s", documents.count == 1?@"It":@"They"] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete Log Exports" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            for(NSURL *file in [[NSFileManager defaultManager] contentsOfDirectoryAtURL:documentsPath includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:nil]) {
                if(![file.absoluteString hasSuffix:@"/"]) {
                    CLS_LOG(@"Removing: %@", file);
                    [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
                }
            }
        }]];
    } else {
        alert = [UIAlertController alertControllerWithTitle:@"Logout" message:@"Are you sure you want to logout of IRCCloud?" preferredStyle:UIAlertControllerStyleAlert];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NetworkConnection sharedInstance] logout];
        [self bufferSelected:-1];
        [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(paste:)) {
        return [UIPasteboard generalPasteboard].image != nil;
    } else if(action == @selector(chooseFGColor) || action == @selector(chooseBGColor) || action == @selector(resetColors)) {
        return YES;
    }

    return [super canPerformAction:action withSender:sender];
}

-(void)resetColors {
    if(self->_message.selectedRange.length) {
        NSRange selection = self->_message.selectedRange;
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        [msg removeAttribute:NSForegroundColorAttributeName range:self->_message.selectedRange];
        [msg removeAttribute:NSBackgroundColorAttributeName range:self->_message.selectedRange];
        self->_message.attributedText = msg;
        self->_message.selectedRange = selection;
    } else {
        if([UIColor textareaTextColor] && _message.font)
            self->_currentMessageAttributes = self->_message.internalTextView.typingAttributes = @{NSForegroundColorAttributeName:[UIColor textareaTextColor], NSFontAttributeName:self->_message.font };
    }
}

-(void)chooseFGColor {
    [self->_colorPickerView updateButtonColors:NO];
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 1; } completion:nil];
}

-(void)chooseBGColor {
    [self->_colorPickerView updateButtonColors:YES];
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 1; } completion:nil];
}

-(void)foregroundColorPicked:(UIColor *)color {
    if(self->_message.selectedRange.length) {
        NSRange selection = self->_message.selectedRange;
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        [msg addAttribute:NSForegroundColorAttributeName value:color range:self->_message.selectedRange];
        self->_message.attributedText = msg;
        self->_message.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:self->_message.internalTextView.typingAttributes];
        [d setObject:color forKey:NSForegroundColorAttributeName];
        self->_message.internalTextView.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)backgroundColorPicked:(UIColor *)color {
    if(self->_message.selectedRange.length) {
        NSRange selection = self->_message.selectedRange;
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        [msg addAttribute:NSBackgroundColorAttributeName value:color range:self->_message.selectedRange];
        self->_message.attributedText = msg;
        self->_message.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:self->_message.internalTextView.typingAttributes];
        [d setObject:color forKey:NSBackgroundColorAttributeName];
        self->_message.internalTextView.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)closeColorPicker {
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 0; } completion:nil];
}

-(void)paste:(id)sender {
    if([UIPasteboard generalPasteboard].image) {
        for(NSString *type in [UIPasteboard generalPasteboard].pasteboardTypes) {
            if([type isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                [self _imagePickerController:[UIImagePickerController new] didFinishPickingMediaWithInfo:@{UIImagePickerControllerOriginalImage:[UIPasteboard generalPasteboard].image, @"gifData":[[UIPasteboard generalPasteboard] dataForPasteboardType:(__bridge NSString *)kUTTypeGIF]}];
                return;
            }
        }
        [self _imagePickerController:[UIImagePickerController new] didFinishPickingMediaWithInfo:@{UIImagePickerControllerOriginalImage:[UIPasteboard generalPasteboard].image}];
    } else if([UIPasteboard generalPasteboard].strings) {
        NSMutableString *text = @"".mutableCopy;
        for(NSString *s in [UIPasteboard generalPasteboard].strings) {
            if(text.length)
                [text appendString:@" "];
            [text appendString:s];
        }
        
        if(text.length) {
            NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
            BOOL shouldMoveCursor = self->_message.selectedRange.location == 0 || self->_message.selectedRange.location == msg.length;
            if(self->_message.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_message.selectedRange];
            
            [msg insertAttributedString:[[NSAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:self->_message.font,NSForegroundColorAttributeName:self->_message.textColor}] atIndex:self->_message.selectedRange.location];
            
            [self->_message setAttributedText:msg];
            if(shouldMoveCursor)
                self->_message.selectedRange = NSMakeRange(msg.length, 0);
        }
    }
}

-(void)pasteRich:(id)sender {
    NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
    BOOL shouldMoveCursor = self->_message.selectedRange.location == 0 || self->_message.selectedRange.location == msg.length;

    if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"]) {
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        if(self->_message.selectedRange.length > 0)
            [msg deleteCharactersInRange:self->_message.selectedRange];
        [msg insertAttributedString:[ColorFormatter format:[[NSString alloc] initWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"] encoding:NSUTF8StringEncoding] defaultColor:self->_message.textColor mono:NO linkify:NO server:nil links:nil] atIndex:self->_message.internalTextView.selectedRange.location];
        
        [self->_message setAttributedText:msg];
        if(shouldMoveCursor)
            self->_message.selectedRange = NSMakeRange(msg.length, 0);
    } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF]) {
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        if(self->_message.selectedRange.length > 0)
            [msg deleteCharactersInRange:self->_message.selectedRange];
        [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF] options:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_message.font.pointSize] atIndex:self->_message.internalTextView.selectedRange.location];
        
        [self->_message setAttributedText:msg];
        if(shouldMoveCursor)
            self->_message.selectedRange = NSMakeRange(msg.length, 0);
    } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD]) {
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        if(self->_message.selectedRange.length > 0)
            [msg deleteCharactersInRange:self->_message.selectedRange];
        [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD] options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_message.font.pointSize] atIndex:self->_message.internalTextView.selectedRange.location];
        
        [self->_message setAttributedText:msg];
        if(shouldMoveCursor)
            self->_message.selectedRange = NSMakeRange(msg.length, 0);
    } else if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"]) {
        NSDictionary *d = [NSPropertyListSerialization propertyListWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"] options:NSPropertyListImmutable format:NULL error:NULL];
        NSMutableAttributedString *msg = self->_message.attributedText.mutableCopy;
        if(self->_message.selectedRange.length > 0)
            [msg deleteCharactersInRange:self->_message.selectedRange];
        [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[d objectForKey:@"WebMainResource"] objectForKey:@"WebResourceData"] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_message.font.pointSize] atIndex:self->_message.internalTextView.selectedRange.location];
        
        [self->_message setAttributedText:msg];
        if(shouldMoveCursor)
            self->_message.selectedRange = NSMakeRange(msg.length, 0);
    } else if([UIPasteboard generalPasteboard].strings) {
        [self paste:nil];
    }
}

- (void)LinkLabel:(LinkLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:result.URL];
}

-(NSArray<UIKeyCommand *> *)keyCommands {
    NSArray *commands = @[
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand action:@selector(selectPrevious) discoverabilityTitle:@"Switch to previous channel"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand action:@selector(selectNext) discoverabilityTitle:@"Switch to next channel"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(selectPreviousUnread) discoverabilityTitle:@"Switch to previous unread channel"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(selectNextUnread) discoverabilityTitle:@"Switch to next unread channel"],
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierAlternate action:@selector(selectPrevious)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierAlternate action:@selector(selectNext)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:UIKeyModifierAlternate|UIKeyModifierShift action:@selector(selectPreviousUnread)],
             [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:UIKeyModifierAlternate|UIKeyModifierShift action:@selector(selectNextUnread)],
             [UIKeyCommand keyCommandWithInput:@"\t" modifierFlags:0 action:@selector(onTabPressed:) discoverabilityTitle:@"Complete nicknames and channels"],
             [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(markAsRead) discoverabilityTitle:@"Mark channel as read"],
             [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift action:@selector(markAllAsRead) discoverabilityTitle:@"Mark all channels as read"],
             [UIKeyCommand keyCommandWithInput:@"b" modifierFlags:UIKeyModifierCommand action:@selector(toggleBoldface:) discoverabilityTitle:@"Bold"],
             [UIKeyCommand keyCommandWithInput:@"i" modifierFlags:UIKeyModifierCommand action:@selector(toggleItalics:) discoverabilityTitle:@"Italic"],
             [UIKeyCommand keyCommandWithInput:@"u" modifierFlags:UIKeyModifierCommand action:@selector(toggleUnderline:) discoverabilityTitle:@"Underline"],
             [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageUp" modifierFlags:0 action:@selector(onPgUpPressed:)],
             [UIKeyCommand keyCommandWithInput:@"UIKeyInputPageDown" modifierFlags:0 action:@selector(onPgDownPressed:)],
             ];

#if !TARGET_OS_MACCATALYST
    if (@available(iOS 15.0, *)) {
        for(UIKeyCommand *c in commands) {
            c.wantsPriorityOverSystemBehavior = YES;
        }
    }
#endif
    return commands;
}

-(void)getMessageAttributesBold:(BOOL *)bold italic:(BOOL *)italic underline:(BOOL *)underline {
    UIFont *font = [self->_message.internalTextView.typingAttributes objectForKey:NSFontAttributeName];
    
    *bold = font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold;
    *italic = font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic;
    *underline = [[self->_message.internalTextView.typingAttributes objectForKey:NSUnderlineStyleAttributeName] intValue] == NSUnderlineStyleSingle;
}

-(void)setMessageAttributesBold:(BOOL)bold italic:(BOOL)italic underline:(BOOL)underline {
    UIFont *font = [self->_message.internalTextView.typingAttributes objectForKey:NSFontAttributeName];
    UIFontDescriptorSymbolicTraits traits = 0;
    
    if(bold)
        traits |= UIFontDescriptorTraitBold;
    
    if(italic)
        traits |= UIFontDescriptorTraitItalic;
    
    font = [UIFont fontWithDescriptor:[font.fontDescriptor fontDescriptorWithSymbolicTraits:traits] size:font.pointSize];
    
    NSMutableDictionary *attributes = self->_message.internalTextView.typingAttributes.mutableCopy;
    [attributes setObject:@(underline?NSUnderlineStyleSingle:NSUnderlineStyleNone) forKey:NSUnderlineStyleAttributeName];
    [attributes setObject:font forKey:NSFontAttributeName];
    self->_message.internalTextView.typingAttributes = attributes;
}

-(void)toggleBoldface:(UIKeyCommand *)sender {
    BOOL hasBold, hasItalic, hasUnderline;
    
    [self getMessageAttributesBold:&hasBold italic:&hasItalic underline:&hasUnderline];
    [self setMessageAttributesBold:!hasBold italic:hasItalic underline:hasUnderline];
}

-(void)toggleItalics:(UIKeyCommand *)sender {
    BOOL hasBold, hasItalic, hasUnderline;
    
    [self getMessageAttributesBold:&hasBold italic:&hasItalic underline:&hasUnderline];
    [self setMessageAttributesBold:hasBold italic:!hasItalic underline:hasUnderline];
}

-(void)toggleUnderline:(UIKeyCommand *)sender {
    BOOL hasBold, hasItalic, hasUnderline;
    
    [self getMessageAttributesBold:&hasBold italic:&hasItalic underline:&hasUnderline];
    [self setMessageAttributesBold:hasBold italic:hasItalic underline:!hasUnderline];
}

-(void)onPgUpPressed:(UIKeyCommand *)sender {
    [self->_eventsView.tableView visibleCells];
    NSIndexPath *first = [self->_eventsView.tableView indexPathsForVisibleRows].firstObject;
    if(first && first.row > 0) {
        [self->_eventsView.tableView scrollToRowAtIndexPath:first atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)onPgDownPressed:(UIKeyCommand *)sender {
    [self->_eventsView.tableView visibleCells];
    NSIndexPath *last = [self->_eventsView.tableView indexPathsForVisibleRows].lastObject;
    if(last && last.row > 0) {
        [self->_eventsView.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

-(void)selectPrevious {
    [self->_buffersView prev];
}

-(void)selectNext {
    [self->_buffersView next];
}

-(void)selectPreviousUnread {
    [self->_buffersView prevUnread];
}

-(void)selectNextUnread {
    [self->_buffersView nextUnread];
}

-(void)sendFeedback {
    [[NetworkConnection sharedInstance] sendFeedbackReport:self];
}

-(void)joinFeedback {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"irc://irc.irccloud.com/%23feedback"]];
}

-(void)joinBeta {
    [FIRAnalytics logEventWithName:@"beta_invite" parameters:nil];
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://testflight.apple.com/join/MApr7Une"]];
}

-(void)FAQ {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://www.irccloud.com/faq"]];
}

-(void)versionHistory {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://github.com/irccloud/ios/releases"]];
}

-(void)openSourceLicenses {
    LicenseViewController *lvc = [[LicenseViewController alloc] init];
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lvc];
    [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
        nc.modalPresentationStyle = UIModalPresentationPageSheet;
    else
        nc.modalPresentationStyle = UIModalPresentationCurrentContext;
    if(self.presentedViewController)
        [self dismissViewControllerAnimated:NO completion:nil];
    [self presentViewController:nc animated:YES completion:nil];
}

-(void)onTabPressed:(UIKeyCommand *)sender {
    if(!self->_message.internalTextView.isFirstResponder)
        [self->_message.internalTextView becomeFirstResponder];
    if(self->_nickCompletionView.count == 0)
        [self updateSuggestions:YES];
    if(self->_nickCompletionView.count > 0) {
        NSInteger s = self->_nickCompletionView.selection;
        if(s == -1 || s == self->_nickCompletionView.count - 1)
            s = 0;
        else
            s++;
        [self->_nickCompletionView setSelection:s];
        NSString *text = self->_message.text;
        self->_message.delegate = nil;
        if(text.length == 0) {
            if(self->_buffer.serverIsSlack)
                self->_message.text = [NSString stringWithFormat:@"@%@", [self->_nickCompletionView suggestion]];
            else
                self->_message.text = [self->_nickCompletionView suggestion];
        } else {
            while(text.length > 0 && [text characterAtIndex:text.length - 1] != ' ') {
                text = [text substringToIndex:text.length - 1];
            }
            if(self->_buffer.serverIsSlack)
                text = [text stringByAppendingString:@"@"];
            text = [text stringByAppendingString:[self->_nickCompletionView suggestion]];
            self->_message.text = text;
        }
        if([text rangeOfString:@" "].location == NSNotFound && !_buffer.serverIsSlack)
            self->_message.text = [self->_message.text stringByAppendingString:@":"];
        self->_message.delegate = self;
    }
}

@end
