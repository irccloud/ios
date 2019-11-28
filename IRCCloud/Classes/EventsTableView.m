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

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EventsTableView.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"
#import "FontAwesome.h"
#import "ImageViewController.h"
#import "PastebinViewController.h"
#import "YouTubeViewController.h"
#import "EditConnectionViewController.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "IRCCloudSafariViewController.h"
#import "AvatarsDataSource.h"
#import "ImageCache.h"

int __timestampWidth;
BOOL __24hrPref = NO;
BOOL __secondsPref = NO;
BOOL __timeLeftPref = NO;
BOOL __nickColorsPref = NO;
BOOL __hideJoinPartPref = NO;
BOOL __expandJoinPartPref = NO;
BOOL __avatarsOffPref = NO;
BOOL __chatOneLinePref = NO;
BOOL __norealnamePref = NO;
BOOL __monospacePref = NO;
BOOL __disableInlineFilesPref = NO;
BOOL __inlineMediaPref = NO;
BOOL __disableBigEmojiPref = NO;
BOOL __disableCodeSpanPref = NO;
BOOL __disableCodeBlockPref = NO;
BOOL __disableQuotePref = NO;
BOOL __avatarImages = YES;
BOOL __replyCollapsePref = NO;
BOOL __colorizeMentionsPref = NO;
BOOL __notificationsMuted = NO;
BOOL __noColor = NO;
int __smallAvatarHeight;
int __largeAvatarHeight = 32;

extern BOOL __compact;
extern UIImage *__socketClosedBackgroundImage;

@interface EventsTableCell : UITableViewCell {
    IBOutlet UIImageView *_avatar;
    IBOutlet UILabel *_timestampLeft,*_timestampRight,*_reply,*_datestamp;
    IBOutlet LinkLabel *_message;
    IBOutlet LinkLabel *_nickname;
    IBOutlet UIView *_socketClosedBar;
    IBOutlet UILabel *_accessory;
    IBOutlet UIView *_topBorder;
    IBOutlet UIView *_bottomBorder;
    IBOutlet UIView *_quoteBorder;
    IBOutlet UIView *_codeBlockBackground;
    IBOutlet UIView *_lastSeenEIDBackground;
    IBOutlet UILabel *_lastSeenEID;
    IBOutlet UIControl *_replyButton;
    IBOutlet NSLayoutConstraint *_messageOffsetLeft,*_messageOffsetRight,*_messageOffsetTop,*_messageOffsetBottom,*_timestampWidth,*_avatarOffset,*_nicknameOffset,*_lastSeenEIDOffset,*_avatarWidth,*_avatarHeight,*_replyCenter,*_replyXOffset,*_avatarTop;
}
@property (readonly) UILabel *timestampLeft, *timestampRight, *accessory, *lastSeenEID, *reply, *datestamp;
@property (readonly) LinkLabel *message, *nickname;
@property (readonly) UIImageView *avatar;
@property (readonly) UIView *quoteBorder, *codeBlockBackground, *topBorder, *bottomBorder, *lastSeenEIDBackground, *socketClosedBar;
@property (readonly) NSLayoutConstraint *messageOffsetLeft, *messageOffsetRight, *messageOffsetTop, *messageOffsetBottom, *timestampWidth, *avatarOffset, *nicknameOffset, *lastSeenEIDOffset, *avatarWidth, *avatarHeight, *replyCenter, *replyXOffset, *avatarTop;
@property (readonly) UIControl *replyButton;
@property (nonatomic) NSURL *largeAvatarURL;

-(IBAction)avatarTapped:(UITapGestureRecognizer *)sender;
@end

@implementation EventsTableCell
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(IBAction)avatarTapped:(UITapGestureRecognizer *)sender {
    [(AppDelegate *)[UIApplication sharedApplication].delegate setActiveScene:self.window];
    [(AppDelegate *)[UIApplication sharedApplication].delegate launchURL:_largeAvatarURL];
}
@end

@interface EventsTableCell_Thumbnail : EventsTableCell {
    IBOutlet UIView *_background;
    IBOutlet YYAnimatedImageView *_thumbnail;
    IBOutlet NSLayoutConstraint *_thumbnailWidth, *_thumbnailHeight;
    IBOutlet UILabel *_filename;
    IBOutlet UIActivityIndicatorView *_spinner;
}
@property (readonly) UIView *background;
@property (readonly) UILabel *filename;
@property (readonly) YYAnimatedImageView *thumbnail;
@property (readonly) NSLayoutConstraint *thumbnailWidth, *thumbnailHeight;
@property (readonly) UIActivityIndicatorView *spinner;

@end

@implementation EventsTableCell_Thumbnail
@end

@interface EventsTableCell_File : EventsTableCell {
    IBOutlet UIView *_background;
    IBOutlet UILabel *_filename;
    IBOutlet UILabel *_mimeType;
    IBOutlet UILabel *_extension;
}
@property (readonly) UIView *background;
@property (readonly) UILabel *filename, *mimeType, *extension;
@end

@implementation EventsTableCell_File
@end

@interface EventsTableCell_ReplyCount : EventsTableCell {
    IBOutlet UILabel *_replyCount;
}
@property (readonly) UILabel *replyCount;
@end

@implementation EventsTableCell_ReplyCount
@end

@implementation EventsTableView

- (id)init {
    self = [super init];
    if (self) {
        self->_conn = [NetworkConnection sharedInstance];
        self->_lock = [[NSRecursiveLock alloc] init];
        self->_ready = NO;
        self->_formatter = [[NSDateFormatter alloc] init];
        self->_formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self->_data = [[NSMutableArray alloc] init];
        self->_expandedSectionEids = [[NSMutableDictionary alloc] init];
        self->_collapsedEvents = [[CollapsedEvents alloc] init];
        self->_unseenHighlightPositions = [[NSMutableArray alloc] init];
        self->_filePropsCache = [[NSMutableDictionary alloc] init];
        self->_closedPreviews = [[NSMutableSet alloc] init];
        self->_buffer = nil;
        self->_eidToOpen = -1;
        self->_urlHandler = [[URLHandler alloc] init];
#ifdef ENTERPRISE
        self->_urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud-enterprise://"];
#else
        self->_urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud://"];
#endif
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self->_conn = [NetworkConnection sharedInstance];
        self->_lock = [[NSRecursiveLock alloc] init];
        self->_ready = NO;
        self->_formatter = [[NSDateFormatter alloc] init];
        self->_formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        self->_data = [[NSMutableArray alloc] init];
        self->_expandedSectionEids = [[NSMutableDictionary alloc] init];
        self->_collapsedEvents = [[CollapsedEvents alloc] init];
        self->_unseenHighlightPositions = [[NSMutableArray alloc] init];
        self->_filePropsCache = [[NSMutableDictionary alloc] init];
        self->_closedPreviews = [[NSMutableSet alloc] init];
        self->_buffer = nil;
        self->_eidToOpen = -1;
        self->_urlHandler = [[URLHandler alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(@available(iOS 11, *))
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    self->_rowCache = [[NSMutableDictionary alloc] init];
    
    if(!_headerView) {
        self->_headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,_tableView.frame.size.width,20)];
        self->_headerView.autoresizesSubviews = YES;
        UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        a.center = self->_headerView.center;
        [a startAnimating];
        [self->_headerView addSubview:a];
    }
    
    if(!_tableView) {
        self->_tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
        self->_tableView.dataSource = self;
        self->_tableView.delegate = self;
        [self.view addSubview:self->_tableView];
    }
    
    self->_eventsTableCell = [UINib nibWithNibName:@"EventsTableCell" bundle:nil];
    self->_eventsTableCell_File = [UINib nibWithNibName:@"EventsTableCell_File" bundle:nil];
    self->_eventsTableCell_Thumbnail = [UINib nibWithNibName:@"EventsTableCell_Thumbnail" bundle:nil];
    self->_eventsTableCell_ReplyCount = [UINib nibWithNibName:@"EventsTableCell_ReplyCount" bundle:nil];
    self->_tableView.scrollsToTop = NO;
    self->_tableView.estimatedRowHeight = 0;
    self->_tableView.estimatedSectionHeaderHeight = 0;
    self->_tableView.estimatedSectionFooterHeight = 0;
    lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self->_tableView addGestureRecognizer:lp];
    self->_topUnreadView.backgroundColor = [UIColor chatterBarColor];
    self->_bottomUnreadView.backgroundColor = [UIColor chatterBarColor];
    [self->_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateNormal];
    [self->_backlogFailedButton setBackgroundImage:[[UIImage imageNamed:@"sendbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateHighlighted];
    [self->_backlogFailedButton setTitleColor:[UIColor unreadBlueColor] forState:UIControlStateNormal];
    [self->_backlogFailedButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [self->_backlogFailedButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self->_backlogFailedButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [self->_backlogFailedButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
    
    self->_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self->_tableView.backgroundColor = [UIColor contentBackgroundColor];
    
    if([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        __previewer = [self registerForPreviewingWithDelegate:self sourceView:self->_tableView];
        [__previewer.previewingGestureRecognizerForFailureRelationship addTarget:self action:@selector(_3DTouchChanged:)];
    }
}

-(void)_3DTouchChanged:(UIGestureRecognizer *)gesture {
    if(gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
        mainViewController.isShowingPreview = NO;
    }
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if(!_data.count)
        return nil;
    MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
    EventsTableCell *cell = [self->_tableView cellForRowAtIndexPath:[self->_tableView indexPathForRowAtPoint:location]];
    self->_previewingRow = [self->_tableView indexPathForRowAtPoint:location].row;
    Event *e = [self->_data objectAtIndex:self->_previewingRow];
    
    NSURL *url;
    if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
        if([e.entities objectForKey:@"id"]) {
            NSString *extension = [e.entities objectForKey:@"extension"];
            if(!extension.length)
                extension = [@"." stringByAppendingString:[[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1]];
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":[e.entities objectForKey:@"id"]} error:nil], [[e.entities objectForKey:@"mime_type"] substringToIndex:5], extension]];
        } else {
            url = [e.entities objectForKey:@"url"];
        }
    } else {
        NSTextCheckingResult *r = [cell.message linkAtPoint:[self->_tableView convertPoint:location toView:cell.message]];
        url = r.URL;
    }
    mainViewController.isShowingPreview = YES;
    
    if([URLHandler isImageURL:url]) {
        previewingContext.sourceRect = cell.frame;
        ImageViewController *i = [[ImageViewController alloc] initWithURL:url];
        i.preferredContentSize = self.view.window.bounds.size;
        i.previewing = YES;
        lp.enabled = NO;
        lp.enabled = YES;
        return i;
    } else if([URLHandler isYouTubeURL:url]) {
        previewingContext.sourceRect = cell.frame;
        YouTubeViewController *y = [[YouTubeViewController alloc] initWithURL:url];
        [y loadViewIfNeeded];
        y.preferredContentSize = y.player.bounds.size;
        y.toolbar.hidden = YES;
        lp.enabled = NO;
        lp.enabled = YES;
        return y;
    } else if([url.scheme hasPrefix:@"irccloud-paste-"]) {
        previewingContext.sourceRect = cell.frame;
        PastebinViewController *pvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PastebinViewController"];
        [pvc setUrl:[NSURL URLWithString:[url.absoluteString substringFromIndex:15]]];
        lp.enabled = NO;
        lp.enabled = YES;
        return pvc;
    } else if([url.pathExtension.lowercaseString isEqualToString:@"mov"] || [url.pathExtension.lowercaseString isEqualToString:@"mp4"] || [url.pathExtension.lowercaseString isEqualToString:@"m4v"] || [url.pathExtension.lowercaseString isEqualToString:@"3gp"] || [url.pathExtension.lowercaseString isEqualToString:@"quicktime"]) {
        previewingContext.sourceRect = cell.frame;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
        player.player = [[AVPlayer alloc] initWithURL:url];
        player.modalPresentationStyle = UIModalPresentationCurrentContext;
        player.preferredContentSize = self.view.window.bounds.size;
        return player;
    } else if([SFSafariViewController class] && [url.scheme hasPrefix:@"http"]) {
        previewingContext.sourceRect = cell.frame;
        IRCCloudSafariViewController *s = [[IRCCloudSafariViewController alloc] initWithURL:url];
        s.modalPresentationStyle = UIModalPresentationCurrentContext;
        s.preferredContentSize = self.view.window.bounds.size;
        return s;
    }
    
    self->_previewingRow = -1;
    mainViewController.isShowingPreview = NO;
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    MainViewController *mainViewController = [(AppDelegate *)([UIApplication sharedApplication].delegate) mainViewController];
    mainViewController.isShowingPreview = NO;
    if([viewControllerToCommit isKindOfClass:[ImageViewController class]]) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = viewControllerToCommit;
        [appDelegate.window insertSubview:appDelegate.slideViewController.view belowSubview:appDelegate.window.rootViewController.view];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [viewControllerToCommit didMoveToParentViewController:nil];
    } else if([viewControllerToCommit isKindOfClass:[YouTubeViewController class]]) {
        viewControllerToCommit.modalPresentationStyle = UIModalPresentationCustom;
        ((YouTubeViewController *)viewControllerToCommit).toolbar.hidden = NO;
        [self.slidingViewController presentViewController:viewControllerToCommit animated:NO completion:nil];
    } else if([viewControllerToCommit isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:((UINavigationController *)viewControllerToCommit).topViewController];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        viewControllerToCommit = nc;
        [self.slidingViewController presentViewController:viewControllerToCommit animated:YES completion:nil];
    } else if([viewControllerToCommit isKindOfClass:[PastebinViewController class]]) {
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:viewControllerToCommit];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self.slidingViewController presentViewController:nc animated:YES completion:nil];
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
        [self.slidingViewController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    UIPreviewAction *deleteAction = [UIPreviewAction actionWithTitle:@"Delete" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        NSString *title = [self->_buffer.type isEqualToString:@"console"]?@"Delete Connection":@"Clear History";
        NSString *msg;
        if([self->_buffer.type isEqualToString:@"console"]) {
            msg = @"Are you sure you want to remove this connection?";
        } else if([self->_buffer.type isEqualToString:@"channel"]) {
            msg = [NSString stringWithFormat:@"Are you sure you want to clear your history in %@?", self->_buffer.name];
        } else {
            msg = [NSString stringWithFormat:@"Are you sure you want to clear your history with %@?", self->_buffer.name];
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            if([self->_buffer.type isEqualToString:@"console"]) {
                [self->_conn deleteServer:self->_buffer.cid handler:nil];
            } else {
                [self->_conn deleteBuffer:self->_buffer.bid cid:self->_buffer.cid handler:nil];
            }
        }]];
        
        if(((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController.presentedViewController)
            [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController dismissViewControllerAnimated:NO completion:nil];
        
        [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController presentViewController:alert animated:YES completion:nil];
    }];
    
    UIPreviewAction *archiveAction = [UIPreviewAction actionWithTitle:@"Archive" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self->_conn archiveBuffer:self->_buffer.bid cid:self->_buffer.cid handler:nil];
    }];
    
    UIPreviewAction *unarchiveAction = [UIPreviewAction actionWithTitle:@"Unarchive" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        [self->_conn unarchiveBuffer:self->_buffer.bid cid:self->_buffer.cid handler:nil];
    }];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    
    if([self->_buffer.type isEqualToString:@"console"]) {
        if([self->_server.status isEqualToString:@"disconnected"]) {
            [items addObject:[UIPreviewAction actionWithTitle:@"Reconnect" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [self->_conn reconnect:self->_buffer.cid handler:nil];
            }]];
            [items addObject:deleteAction];
        } else {
            [items addObject:[UIPreviewAction actionWithTitle:@"Disconnect" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [self->_conn disconnect:self->_buffer.cid msg:nil handler:nil];
            }]];
            
        }
        [items addObject:[UIPreviewAction actionWithTitle:@"Edit Connection" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
            EditConnectionViewController *ecv = [[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped];
            [ecv setServer:self->_buffer.cid];
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ecv];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
                nc.modalPresentationStyle = UIModalPresentationFormSheet;
            else
                nc.modalPresentationStyle = UIModalPresentationCurrentContext;
            
            if(((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController.presentedViewController)
                [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController dismissViewControllerAnimated:NO completion:nil];
            
            [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController presentViewController:nc animated:YES completion:nil];
        }]];
    } else if([self->_buffer.type isEqualToString:@"channel"]) {
        if([[ChannelsDataSource sharedInstance] channelForBuffer:self->_buffer.bid]) {
            [items addObject:[UIPreviewAction actionWithTitle:@"Leave" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [self->_conn part:self->_buffer.name msg:nil cid:self->_buffer.cid handler:nil];
            }]];
            [items addObject:[UIPreviewAction actionWithTitle:@"Invite to Channel" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController _setSelectedBuffer:self->_buffer];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", self->_server.name, self->_server.hostname, self->_server.port] message:@"Invite to channel" preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Invite" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
                        [[NetworkConnection sharedInstance] invite:((UITextField *)[alert.textFields objectAtIndex:0]).text chan:self->_buffer.name cid:self->_buffer.cid handler:nil];
                    }
                }]];
                
                if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 9) {
                    [self presentViewController:alert animated:YES completion:nil];
                }
                
                [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                    textField.placeholder = @"nickname";
                    textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                }];
                
                if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 9)
                    [self presentViewController:alert animated:YES completion:nil];
            }]];
        } else {
            [items addObject:[UIPreviewAction actionWithTitle:@"Rejoin" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                [self->_conn join:self->_buffer.name key:nil cid:self->_buffer.cid handler:nil];
            }]];
            if(self->_buffer.archived) {
                [items addObject:unarchiveAction];
            } else {
                [items addObject:archiveAction];
            }
            [items addObject:deleteAction];
        }
    } else {
        if(self->_buffer.archived) {
            [items addObject:unarchiveAction];
        } else {
            [items addObject:archiveAction];
        }
        [items addObject:deleteAction];
    }
    
    return items;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _reloadData];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogFailed:)
                                                 name:kIRCCloudBacklogFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(drawerClosed:)
                                                 name:ECSlidingViewTopDidReset object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(self->_data.count && _buffer.scrolledUp) {
        self->_bottomRow = [[[self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, _tableView.contentInset)] lastObject] row];
        if(self->_bottomRow >= self->_data.count)
            self->_bottomRow = self->_data.count - 1;
    } else {
        self->_bottomRow = -1;
    }
}

-(void)drawerClosed:(NSNotification *)n {
    if(self.slidingViewController.underLeftViewController)
        [self scrollViewDidScroll:self->_tableView];
}

-(void)viewWillResize {
    self->_ready = NO;
    self->_tableView.hidden = YES;
    self->_stickyAvatar.hidden = YES;
    if(self->_data.count && self->_buffer.scrolledUp)
        self->_bottomRow = [[[self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, self->_tableView.contentInset)] lastObject] row];
    else
        self->_bottomRow = -1;
}

-(void)viewDidResize {
    self->_ready = YES;
    [self clearCachedHeights];
    [self updateUnread];
    [self scrollViewDidScroll:self->_tableView];
    self->_tableView.hidden = NO;
}

-(void)uncacheFile:(NSString *)fileID {
    @synchronized (self->_filePropsCache) {
        if(fileID)
            [self->_filePropsCache removeObjectForKey:fileID];
    }
}

-(void)closePreview:(Event *)event {
    [self->_closedPreviews addObject:@(event.eid)];
    [self refresh];
}

-(void)clearRowCache {
    @synchronized (self->_rowCache) {
        [self->_rowCache removeAllObjects];
    }
}

-(void)clearCachedHeights {
    if(self->_ready) {
        if([self->_data count]) {
            [self->_lock lock];
            for(Event *e in _data) {
                e.height = 0;
            }
            [self clearRowCache];
            [self->_lock unlock];
            self->_ready = NO;
            [self->_tableView reloadData];
            if(self->_bottomRow >= 0 && _bottomRow < [self->_tableView numberOfRowsInSection:0]) {
                [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_bottomRow inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                self->_bottomRow = -1;
            } else {
                [self _scrollToBottom];
            }
            self->_ready = YES;
        }
    }
}

- (IBAction)loadMoreBacklogButtonPressed:(id)sender {
    if(self->_conn.ready) {
        self->_requestingBacklog = YES;
        self->_shouldAutoFetch = NO;
        [self->_conn cancelPendingBacklogRequests];
        [self->_conn requestBacklogForBuffer:self->_buffer.bid server:self->_buffer.cid beforeId:self->_earliestEid completion:nil];
        self->_tableView.tableHeaderView = self->_headerView;
    }
}

- (void)backlogFailed:(NSNotification *)notification {
    if(self->_buffer && [notification.object bid] == self->_buffer.bid) {
        self->_requestingBacklog = NO;
        self->_tableView.tableHeaderView = self->_backlogFailedView;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Unable to download chat history. Please try again shortly.");
    }
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(self->_buffer && [notification.object bid] == self->_buffer.bid) {
        if([[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid] == nil) {
            NSLog(@"This buffer contains no events, switching to backlog failed header view");
            self->_tableView.tableHeaderView = self->_backlogFailedView;
            return;
        }
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Download complete.");
    }
    if(notification.object == nil || [notification.object bid] == -1 || (self->_buffer && [notification.object bid] == self->_buffer.bid && _requestingBacklog)) {
        NSLog(@"Backlog loaded in current buffer, will find and remove the last seen EID marker");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if(self->_buffer.scrolledUp) {
                [self->_lock lock];
                int row = 0;
                NSInteger toprow = [self->_tableView indexPathForRowAtPoint:CGPointMake(0,self->_buffer.savedScrollOffset)].row;
                if(self->_tableView.tableHeaderView != nil)
                    row++;
                for(Event *event in self->_data) {
                    if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:self->_buffer.bid lastSeenEid:self->_buffer.last_seen_eid type:self->_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                        if(toprow > row) {
                            NSLog(@"Adjusting scroll offset");
                            self->_buffer.savedScrollOffset -= 26;
                        }
                    }
                    if(++row > toprow)
                        break;
                }
                [self->_lock unlock];
                for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid]) {
                    if(event.rowType == ROW_LASTSEENEID) {
                        NSLog(@"removing the last seen EID marker");
                        [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                        NSLog(@"removed!");
                        break;
                    }
                }
            }
            NSLog(@"Rebuilding the message table");
            [self refresh];
        }];
    }
}

- (void)_sendHeartbeat {
    if(self->_data.count && _topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0 && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && ![NetworkConnection sharedInstance].notifier && [self.slidingViewController topViewHasFocus] && !_requestingBacklog && _conn.state == kIRCCloudStateConnected) {
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid];
        NSTimeInterval eid = self->_buffer.scrolledUpFrom;
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
        if(eid >= 0 && eid >= self->_buffer.last_seen_eid) {
            [self->_conn heartbeat:self->_buffer.bid cid:self->_buffer.cid bid:self->_buffer.bid lastSeenEid:eid handler:nil];
            self->_buffer.last_seen_eid = eid;
        }
    }
    self->_heartbeatTimer = nil;
}

- (void)sendHeartbeat {
    if(!_heartbeatTimer)
        self->_heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_sendHeartbeat) userInfo:nil repeats:NO];
}

- (void)handleEvent:(NSNotification *)notification {
    IRCCloudJSONObject *o;
    Event *e;
    Buffer *b;
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventHeartbeatEcho:
            [self updateUnread];
            if(self->_maxEid <= self->_buffer.last_seen_eid) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                self->_topUnreadView.alpha = 0;
                [UIView commitAnimations];
            }
            break;
        case kIRCEventMakeBuffer:
            b = notification.object;
            if(self->_buffer.bid == -1 && b.cid == self->_buffer.cid && [[b.name lowercaseString] isEqualToString:[self->_buffer.name lowercaseString]]) {
                self->_buffer = b;
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
        case kIRCEventUserMode:
        case kIRCEventUserChannelMode:
            o = notification.object;
            if(o.bid == self->_buffer.bid) {
                e = [[EventsDataSource sharedInstance] event:o.eid buffer:o.bid];
                if(e)
                    [self insertEvent:e backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventSelfDetails:
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.bid == self->_buffer.bid) {
                if(((e.from && [[e.from lowercaseString] isEqualToString:[self->_buffer.name lowercaseString]]) || (e.nick && [[e.nick lowercaseString] isEqualToString:[self->_buffer.name lowercaseString]])) && e.reqId == -1) {
                    [self->_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [self->_data objectAtIndex:i];
                        if(e.pending) {
                            if(i > 0) {
                                Event *p = [self->_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    [self->_data removeObject:p];
                                    i--;
                                }
                            }
                            [self->_data removeObject:e];
                            i--;
                        }
                    }
                    [self->_lock unlock];
                } else if(e.reqId != -1) {
                    CLS_LOG(@"Searching for pending message matching reqid %i", e.reqId);
                    int reqid = e.reqId;
                    NSTimeInterval eid = -1;
                    [self->_lock lock];
                    for(int i = 0; i < _data.count; i++) {
                        e = [self->_data objectAtIndex:i];
                        if(e.reqId == reqid && (e.pending || e.rowType == ROW_FAILED)) {
                            CLS_LOG(@"Found at position %i", i);
                            eid = e.eid;
                            if(i>0) {
                                Event *p = [self->_data objectAtIndex:i-1];
                                if(p.rowType == ROW_TIMESTAMP) {
                                    CLS_LOG(@"Removing timestamp row");
                                    [self->_data removeObject:p];
                                    [self clearRowCache];
                                    i--;
                                }
                            }
                            CLS_LOG(@"Removing pending event");
                            [self->_data removeObject:e];
                            [self clearRowCache];
                            i--;
                        }
                        if(e.parent == eid) {
                            CLS_LOG(@"Removing child event");
                            [self->_data removeObject:e];
                            [self clearRowCache];
                            i--;
                        }
                    }
                    [self->_lock unlock];
                    CLS_LOG(@"Finished");
                }
                [self insertEvent:notification.object backlog:NO nextIsGrouped:NO];
            }
            break;
        case kIRCEventSetIgnores:
            [self refresh];
            break;
        case kIRCEventUserInfo:
            [[EventsDataSource sharedInstance] clearFormattingCache];
            for(Event *e in _data) {
                e.formatted = nil;
                e.timestamp = nil;
                e.formattedNick = nil;
                e.formattedRealname = nil;
                e.height = 0;
            }
            [self->_rowCache removeAllObjects];
            [self refresh];
            break;
        case kIRCEventMessageChanged:
            o = notification.object;
            if(o.bid == self->_buffer.bid) {
                [[EventsDataSource sharedInstance] clearFormattingCache];
                for(Event *e in _data) {
                    e.formatted = nil;
                    e.timestamp = nil;
                    e.formattedNick = nil;
                    e.formattedRealname = nil;
                    e.height = 0;
                }
                [self->_rowCache removeAllObjects];
                [self refresh];
            }
            break;
        default:
            break;
    }
}

- (void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped {
    @synchronized(self) {
        BOOL colors = NO;
        if(!event.isSelf && __nickColorsPref)
            colors = YES;
        
        if(self->_minEid == 0)
            self->_minEid = event.eid;
        if(event.eid == self->_buffer.min_eid || (self->_msgid && [self->_msgid isEqualToString:event.msgid])) {
            self->_tableView.tableHeaderView = nil;
        }
        if(event.eid < _earliestEid || _earliestEid == 0)
            self->_earliestEid = event.eid;
        
        if(self->_msgid && !([event.msgid isEqualToString:self->_msgid] || [event.reply isEqualToString:self->_msgid])) {
            return;
        }
        
        NSTimeInterval eid = event.eid;
        NSString *type = event.type;
        if([type hasPrefix:@"you_"]) {
            type = [type substringFromIndex:4];
        }
        NSString *eventmsg = __noColor ? event.msg.stripIRCColors : event.msg;

        if([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"]|| [type isEqualToString:@"socket_closed"] || [type isEqualToString:@"connecting_failed"] || [type isEqualToString:@"connecting_cancelled"]) {
            self->_collapsedEvents.showChan = ![self->_buffer.type isEqualToString:@"channel"];
            self->_collapsedEvents.noColor = __noColor;
            if(__hideJoinPartPref && !event.isSelf && ![type isEqualToString:@"socket_closed"] && ![type isEqualToString:@"connecting_failed"] && ![type isEqualToString:@"connecting_cancelled"]) {
                [self->_lock lock];
                for(Event *e in _data) {
                    if(e.eid == event.eid) {
                        [self->_data removeObject:e];
                        break;
                    }
                }
                [self->_lock unlock];
                if(!backlog)
                    [self _reloadData];
                return;
            }
            
            [self->_formatter setDateFormat:@"DDD"];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:event.time];
            
            if(__expandJoinPartPref)
                [self->_expandedSectionEids removeAllObjects];
            
            if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                Event *last = [[EventsDataSource sharedInstance] event:self->_lastCollapsedEid buffer:self->_buffer.bid];
                if(last) {
                    if(![last.type isEqualToString:@"socket_closed"] && ![last.type isEqualToString:@"connecting_failed"] && ![last.type isEqualToString:@"connecting_cancelled"])
                        self->_currentCollapsedEid = -1;
                }
            } else {
                Event *last = [[EventsDataSource sharedInstance] event:self->_lastCollapsedEid buffer:self->_buffer.bid];
                if(last) {
                    if([last.type isEqualToString:@"socket_closed"] || [last.type isEqualToString:@"connecting_failed"] || [last.type isEqualToString:@"connecting_cancelled"])
                        self->_currentCollapsedEid = -1;
                }
            }
            
            if(self->_currentCollapsedEid == -1 || ![[self->_formatter stringFromDate:date] isEqualToString:self->_lastCollpasedDay] || __expandJoinPartPref || [event.type isEqualToString:@"you_parted_channel"]) {
                [self->_collapsedEvents clear];
                self->_currentCollapsedEid = eid;
                self->_lastCollpasedDay = [self->_formatter stringFromDate:date];
            }
            
            if(!_collapsedEvents.showChan)
                event.chan = self->_buffer.name;
            
            if(![self->_collapsedEvents addEvent:event]) {
                [self->_collapsedEvents clear];
            }
            
            event.color = [UIColor collapsedRowTextColor];
            event.bgColor = [UIColor contentBackgroundColor];
            
            NSString *msg;
            if([self->_expandedSectionEids objectForKey:@(self->_currentCollapsedEid)]) {
                CollapsedEvents *c = [[CollapsedEvents alloc] init];
                c.showChan = self->_collapsedEvents.showChan;
                c.server = self->_server;
                [c addEvent:event];
                if(!nextIsGrouped) {
                    msg = [c collapse];
                    NSString *groupMsg = [self->_collapsedEvents collapse];
                    if(groupMsg == nil && [type isEqualToString:@"nickchange"])
                        groupMsg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO displayName:nil], BOLD];
                    if(groupMsg == nil && [type isEqualToString:@"user_channel_mode"]) {
                        if(event.from.length > 0)
                            groupMsg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [self->_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO displayName:nil], BOLD];
                        else
                            groupMsg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
                    }
                    Event *heading = [[Event alloc] init];
                    heading.cid = event.cid;
                    heading.bid = event.bid;
                    heading.eid = self->_currentCollapsedEid - 1;
                    heading.groupMsg = [NSString stringWithFormat:@"%@%@",_groupIndent,groupMsg];
                    heading.color = [UIColor timestampColor];
                    heading.bgColor = [UIColor contentBackgroundColor];
                    heading.formattedMsg = nil;
                    heading.formatted = nil;
                    heading.linkify = NO;
                    [self _addItem:heading eid:self->_currentCollapsedEid - 1];
                    if([event.type isEqualToString:@"socket_closed"] || [event.type isEqualToString:@"connecting_failed"] || [event.type isEqualToString:@"connecting_cancelled"]) {
                        Event *last = [[EventsDataSource sharedInstance] event:self->_lastCollapsedEid buffer:self->_buffer.bid];
                        if(last) {
                            if(last.msg.length == 0)
                                [self->_data removeObject:last];
                            else
                                last.rowType = ROW_MESSAGE;
                        }
                        event.rowType = ROW_SOCKETCLOSED;
                    }
                } else {
                    msg = @"";
                }
                event.timestamp = nil;
            } else {
                msg = (nextIsGrouped && _currentCollapsedEid != event.eid)?@"":[self->_collapsedEvents collapse];
            }
            if(msg == nil && [type isEqualToString:@"nickchange"])
                msg = [NSString stringWithFormat:@"%@ → %c%@%c", event.oldNick, BOLD, [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO displayName:nil], BOLD];
            if(msg == nil && [type isEqualToString:@"user_channel_mode"]) {
                if(event.from.length > 0)
                    msg = [NSString stringWithFormat:@"%c%@%c was set to: %c%@%c by %c%@%c", BOLD, event.nick, BOLD, BOLD, event.diff, BOLD, BOLD, [self->_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO displayName:nil], BOLD];
                else
                    msg = [NSString stringWithFormat:@"%@ was set to: %c%@%c by the server %c%@%c", event.nick, BOLD, event.diff, BOLD, BOLD, event.server, BOLD];
                self->_currentCollapsedEid = eid;
            }
            if([self->_expandedSectionEids objectForKey:@(self->_currentCollapsedEid)]) {
                msg = [NSString stringWithFormat:@"%@%@", _groupIndent, msg];
            } else {
                if(eid != self->_currentCollapsedEid)
                    msg = [NSString stringWithFormat:@"%@%@", _groupIndent, msg];
                eid = self->_currentCollapsedEid;
            }
            event.groupMsg = msg;
            event.formattedMsg = nil;
            event.formatted = nil;
            event.linkify = NO;
            self->_lastCollapsedEid = event.eid;
            if(([self->_buffer.type isEqualToString:@"console"] && ![type isEqualToString:@"socket_closed"] && ![type isEqualToString:@"connecting_failed"] && ![type isEqualToString:@"connecting_cancelled"]) || [event.type isEqualToString:@"you_parted_channel"]) {
                self->_currentCollapsedEid = -1;
                self->_lastCollapsedEid = -1;
                [self->_collapsedEvents clear];
            }
            EventsTableCell *cell = [self->_rowCache objectForKey:event.UUID];
            if(cell) {
                cell.message.text = nil;
            }
        } else {
            self->_currentCollapsedEid = -1;
            self->_lastCollapsedEid = -1;
            event.mentionOffset = 0;
            [self->_collapsedEvents clear];
            
            if(!event.formatted.length || !event.formattedMsg.length) {
                if((__chatOneLinePref || ![event isMessage]) && [event.from length] && event.rowType != ROW_THUMBNAIL && event.rowType != ROW_FILE) {
                    event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [self->_collapsedEvents formatNick:event.fromNick mode:event.fromMode colorize:colors defaultColor:[UIColor isDarkTheme]?@"ffffff":@"142b43" displayName:event.from], eventmsg];
                    event.mentionOffset = event.formattedMsg.length - eventmsg.length;
                } else {
                    event.formattedMsg = eventmsg;
                }
            }
        }
        
        if(event.ignoreMask.length && [event isMessage]) {
            if((!_buffer || ![self->_buffer.type isEqualToString:@"conversation"]) && [self->_server.ignore match:event.ignoreMask]) {
                if(self->_topUnreadView.alpha == 0 && _bottomUnreadView.alpha == 0)
                    [self sendHeartbeat];
                return;
            }
        }
        
        event.childEventCount = 0;
        
        if(!event.formatted) {
            if(event.rowType == ROW_THUMBNAIL) {
                event.formattedMsg = eventmsg;
            } else if([type isEqualToString:@"channel_mode"] && event.nick.length > 0) {
                if(event.nick.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by %@", event.msg, [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO displayName:nil]];
                else if(event.server.length)
                    event.formattedMsg = [NSString stringWithFormat:@"%@ by the server %c%@%c", event.msg, BOLD, event.server, CLEAR];
            } else if([type isEqualToString:@"buffer_me_msg"]) {
                NSString *msg = eventmsg;
                if(!__disableCodeSpanPref)
                    msg = [msg insertCodeSpans];
                event.formattedMsg = [NSString stringWithFormat:@"— %c%@ %@", ITALICS, [self->_collapsedEvents formatNick:event.fromNick mode:event.fromMode colorize:colors displayName:event.nick], msg];
                event.rowType = ROW_ME_MESSAGE;
                event.mentionOffset = event.formattedMsg.length - eventmsg.length;
            } else if([type isEqualToString:@"notice"] || [type isEqualToString:@"buffer_msg"]) {
                event.isCodeBlock = NO;
                if(event.rowType == ROW_FAILED)
                    event.color = [UIColor networkErrorColor];
                else if(event.pending)
                    event.color = [UIColor timestampColor];
                else
                    event.color = [UIColor messageTextColor];
                Server *s = [[ServersDataSource sharedInstance] getServer:event.cid];
                if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OPER]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Opers" mode:s.MODE_OPER colorize:NO displayName:nil],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OWNER]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Owners" mode:s.MODE_OWNER colorize:NO displayName:nil],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_ADMIN]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Admins" mode:s.MODE_ADMIN colorize:NO displayName:nil],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_OP]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Ops" mode:s.MODE_OP colorize:NO displayName:nil],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_HALFOP]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Half Ops" mode:s.MODE_HALFOP colorize:NO displayName:nil],BOLD];
                else if([event.targetMode isEqualToString:[s.PREFIX objectForKey:s.MODE_VOICED]])
                    event.formattedMsg = [NSString stringWithFormat:@"%c%@%c ",BOLD,[self->_collapsedEvents formatNick:@"Voiced" mode:s.MODE_VOICED colorize:NO displayName:nil],BOLD];
                else
                    event.formattedMsg = @"";
                
                event.mentionOffset = event.formattedMsg.length;
                
                if(event.edited)
                    eventmsg = [eventmsg stringByAppendingFormat:@" %c%@(edited)%c", COLOR_RGB, [UIColor collapsedRowTextColor].toHexString, COLOR_RGB];

                if(!__disableCodeBlockPref && eventmsg) {
                    static NSRegularExpression *_pattern = nil;
                    if(!_pattern) {
                        NSString *pattern = @"```([\\s\\S]+?)```(?=(?!`)[\\W\\s\\n]|$)";
                        _pattern = [NSRegularExpression
                                    regularExpressionWithPattern:pattern
                                    options:NSRegularExpressionCaseInsensitive
                                    error:nil];
                    }
                    
                    NSString *msg = eventmsg;
                    NSArray *matches = [_pattern matchesInString:msg options:0 range:NSMakeRange(0, msg.length)];
                    if(matches.count) {
                        NSUInteger start = 0;
                        
                        for(NSTextCheckingResult *result in matches) {
                            NSString *lastChunk = @"";
                            if(result.range.location)
                                lastChunk = [msg substringWithRange:NSMakeRange(start, result.range.location - start)];
                            BOOL strippedSpace = NO;
                            if([lastChunk hasPrefix:@" "] && lastChunk.length > 1) {
                                lastChunk = [lastChunk substringFromIndex:1];
                                strippedSpace = YES;
                            }
                            if(start > 0) {
                                Event *e = [event copy];
                                e.eid = event.eid + ++event.childEventCount;
                                e.msg = e.formattedMsg = lastChunk;
                                if(!__disableCodeSpanPref)
                                    e.msg = e.formattedMsg = [e.formattedMsg insertCodeSpans];
                                e.timestamp = @"";
                                e.parent = event.eid;
                                e.isHeader = NO;
                                e.mentionOffset = -start;
                                if(strippedSpace)
                                    e.mentionOffset--;
                                [self _addItem:e eid:e.eid];
                            } else {
                                eventmsg = lastChunk;
                            }
                            if(result.range.location == 0 && !__chatOneLinePref) {
                                eventmsg = [msg substringWithRange:NSMakeRange(3, result.range.length - 6)];
                                if([eventmsg hasPrefix:@"\n"])
                                    eventmsg = [eventmsg substringFromIndex:1];
                                if([eventmsg hasSuffix:@"\n"])
                                    eventmsg = [eventmsg substringToIndex:eventmsg.length - 1];
                                event.isCodeBlock = YES;
                                event.color = [UIColor codeSpanForegroundColor];
                                event.monospace = YES;
                            } else {
                                Event *e = [event copy];
                                e.eid = event.eid + ++event.childEventCount;
                                NSString *strippedmsg = [msg substringWithRange:NSMakeRange(result.range.location + 3, result.range.length - 6)];
                                if([strippedmsg hasPrefix:@"\n"])
                                    strippedmsg = [strippedmsg substringFromIndex:1];
                                if([strippedmsg hasSuffix:@"\n"])
                                    strippedmsg = [strippedmsg substringToIndex:strippedmsg.length - 1];
                                e.msg = e.formattedMsg = strippedmsg;
                                e.timestamp = @"";
                                e.parent = event.eid;
                                e.isCodeBlock = YES;
                                e.isHeader = NO;
                                e.color = [UIColor codeSpanForegroundColor];
                                e.monospace = YES;
                                e.entities = nil;
                                [self _addItem:e eid:e.eid];
                            }
                            start = result.range.location + result.range.length;
                        }
                        if(start < msg.length) {
                            Event *e = [event copy];
                            e.eid = event.eid + ++event.childEventCount;
                            e.msg = e.formattedMsg = [msg substringWithRange:NSMakeRange(start, msg.length - start)];
                            e.mentionOffset = -start;
                            if([e.formattedMsg hasPrefix:@" "] && e.formattedMsg.length > 1) {
                                e.formattedMsg = [e.formattedMsg substringFromIndex:1];
                                e.mentionOffset--;
                            }
                            if(!__disableCodeSpanPref)
                                e.formattedMsg = [e.formattedMsg insertCodeSpans];
                            e.timestamp = @"";
                            e.parent = event.eid;
                            e.isHeader = NO;
                            if(e.formattedMsg.length)
                                [self _addItem:e eid:e.eid];
                        }
                    }
                } else {
                    event.isCodeBlock = NO;
                }
                
                if(!__disableCodeSpanPref)
                    eventmsg = [eventmsg insertCodeSpans];
                if([type isEqualToString:@"notice"]) {
                    if([self->_buffer.type isEqualToString:@"console"] && event.toChan && event.chan.length) {
                        event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%c%@%c: %@", BOLD, event.chan, BOLD, eventmsg];
                    } else if([self->_buffer.type isEqualToString:@"console"] && event.isSelf && event.nick.length) {
                        event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%c%@%c: %@", BOLD, event.nick, BOLD, eventmsg];
                    } else {
                        event.formattedMsg = [event.formattedMsg stringByAppendingString:eventmsg];
                    }
                } else if(eventmsg) {
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:eventmsg];
                }
                if(event.from.length && __chatOneLinePref && event.rowType != ROW_THUMBNAIL && event.rowType != ROW_FILE) {
                    if(!__disableQuotePref && event.formattedMsg.length > 0 && [event.formattedMsg isBlockQuote]) {
                        Event *e1 = event.copy;
                        e1.eid = event.eid + ++event.childEventCount;
                        e1.timestamp = @"";
                        e1.formattedMsg = event.formattedMsg;
                        e1.parent = event.eid;
                        [self _addItem:e1 eid:e1.eid];
                        event.formattedMsg = [self->_collapsedEvents formatNick:event.fromNick mode:event.fromMode colorize:colors displayName:event.from];
                    } else {
                        NSInteger oldLength = event.formattedMsg.length;
                        event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [self->_collapsedEvents formatNick:event.fromNick mode:event.fromMode colorize:colors displayName:event.from], event.formattedMsg];
                        event.mentionOffset += event.formattedMsg.length - oldLength;
                    }
                }
            } else if([type isEqualToString:@"kicked_channel"]) {
                event.formattedMsg = [NSString stringWithFormat:@"%c%@← ", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString];
                if([event.type hasPrefix:@"you_"])
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@"You"];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@"%@%c", event.oldNick, CLEAR];
                if([event.type hasPrefix:@"you_"])
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@" were"];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingString:@" was"];
                if(event.hostmask && event.hostmask.length)
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by %@", [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil]];
                else
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@" kicked by the server %c%@%@%c", COLOR_RGB, [UIColor collapsedRowNickColor].toHexString, event.nick, CLEAR];
                if(event.msg.length > 0 && ![event.msg isEqualToString:event.nick])
                    event.formattedMsg = [event.formattedMsg stringByAppendingFormat:@": %@", eventmsg];
            } else if([type isEqualToString:@"channel_mode_list_change"]) {
                if(event.from.length == 0) {
                    if(event.nick.length)
                        event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO displayName:nil], event.msg];
                    else if(event.server.length)
                        event.formattedMsg = [NSString stringWithFormat:@"The server %c%@%c %@", BOLD, event.server, CLEAR, event.msg];
                }
            } else if([type isEqualToString:@"user_chghost"]) {
                event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [self->_collapsedEvents formatNick:event.nick mode:event.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString bold:NO displayName:nil], event.msg];
            } else if([type isEqualToString:@"channel_name_change"]) {
                if(event.from.length) {
                    event.formattedMsg = [NSString stringWithFormat:@"%@ %@", [self->_collapsedEvents formatNick:event.from mode:event.fromMode colorize:NO defaultColor:[UIColor collapsedRowNickColor].toHexString displayName:nil], event.msg];
                } else {
                    NSString *from = @"The server ";
                    if(event.server.length)
                        from = [from stringByAppendingFormat:@"%@ ",event.server];
                    event.formattedMsg = [NSString stringWithFormat:@"%@%@", from, event.msg];
                }
            } else if([type isEqualToString:@"channel_topic"]) {
                if([event.msg hasPrefix:@"set the topic: "])
                    event.mentionOffset += 15;
            }
        }

        if(event.msgid)
            [self->_msgids setObject:event forKey:event.msgid];
        if(event.reply) {
            Event *parent = [self->_msgids objectForKey:event.reply];
            parent.replyCount = parent.replyCount + 1;
            if(!parent.replyNicks)
                parent.replyNicks = [[NSMutableSet alloc] init];
            if(event.from)
                [parent.replyNicks addObject:event.from];
        }
        event.isReply = event.reply != nil;
        if(event.isReply && __replyCollapsePref) {
            Event *parent = [self->_msgids objectForKey:event.reply];
            if(parent && !parent.childEventCount) {
                Event *e1 = [self entity:parent eid:parent.eid + ++parent.childEventCount properties:nil];
                e1.rowType = ROW_REPLY_COUNT;
                e1.type = TYPE_REPLY_COUNT;
                e1.msg = e1.formattedMsg = nil;
                e1.formatted = nil;
                e1.entities = @{@"parent":parent};
                [self insertEvent:e1 backlog:YES nextIsGrouped:NO];
            }
            if(!backlog)
                [self reloadData];
            return;
        }
        [self _addItem:event eid:eid];
        if(!event.formatted && event.formattedMsg.length > 0 && !backlog) {
            [self _format:event];
        }
        
        if(!backlog) {
            [self _reloadData];
            if(!_buffer.scrolledUp) {
                [self scrollToBottom];
                [self _scrollToBottom];
                if(self->_topUnreadView.alpha == 0)
                    [self sendHeartbeat];
            } else if(!event.isSelf && [event isImportant:self->_buffer.type]) {
                self->_newMsgs++;
                if(event.isHighlight && !__notificationsMuted)
                    self->_newHighlights++;
                [self updateUnread];
                [self scrollViewDidScroll:self->_tableView];
            }
        }
        
        if(!__disableInlineFilesPref && event.rowType != ROW_THUMBNAIL) {
            NSTimeInterval entity_eid = event.eid;
            for(NSDictionary *entity in [event.entities objectForKey:@"files"]) {
                entity_eid = event.eid + ++event.childEventCount;
                if([self->_closedPreviews containsObject:@(entity_eid)])
                    continue;
                
                @synchronized (self->_filePropsCache) {
                    NSDictionary *properties = [self->_filePropsCache objectForKey:[entity objectForKey:@"id"]];
#ifdef DEBUG
                    if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
                        NSMutableDictionary *d = entity.mutableCopy;
                        [d removeObjectForKey:@"id"];
                        [d setObject:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.irccloud.com/static/test/%@", [d objectForKey:@"filename"]]] forKey:@"thumb"];
                        properties = d;
                    }
#endif
                    if(properties) {
                        Event *e1 = [self entity:event eid:entity_eid properties:properties];
                        [self insertEvent:e1 backlog:YES nextIsGrouped:NO];
                        if(!backlog)
                            [self reloadForEvent:e1];
                    } else {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSDictionary *properties = [self->_conn propertiesForFile:[entity objectForKey:@"id"]];
                            if(properties) {
                                @synchronized (self->_filePropsCache) {
                                    [self->_filePropsCache setObject:properties forKey:[entity objectForKey:@"id"]];
                                }
                                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                    if(self->_buffer.bid == event.bid) {
                                        Event *e1 = [self entity:event eid:entity_eid properties:properties];
                                        [self insertEvent:e1 backlog:YES nextIsGrouped:NO];
                                        [self reloadForEvent:e1];
                                    }
                                }];
                            }
                        });
                    }
                }
            }
            if(self->_buffer.last_seen_eid == event.eid)
                self->_buffer.last_seen_eid = entity_eid;
        }
        
        if(__inlineMediaPref && event.linkify && event.msg.length && event.rowType != ROW_THUMBNAIL) {
            NSTimeInterval entity_eid = event.eid;

            NSArray *results = event.links;
            for(id r in results) {
                if([r isKindOfClass:NSTextCheckingResult.class]) {
                    NSTextCheckingResult *result = r;
                    BOOL found = NO;
                    for(NSDictionary *entity in [event.entities objectForKey:@"files"]) {
                        if([result.URL.absoluteString rangeOfString:[entity objectForKey:@"id"]].location != NSNotFound) {
                            found = YES;
                            break;
                        }
                    }
                    
                    if(!found) {
                        entity_eid = event.eid + ++event.childEventCount;
                        if([self->_closedPreviews containsObject:@(entity_eid)])
                            continue;
                        if([URLHandler isImageURL:result.URL] && [[ImageCache sharedInstance] isValidURL:result.URL]) {
                            if([self->_urlHandler MediaURLs:result.URL]) {
                                Event *e1 = [self entity:event eid:entity_eid properties:[self->_urlHandler MediaURLs:result.URL]];
                                if([[ImageCache sharedInstance] isValidURL:[e1.entities objectForKey:@"url"]])
                                    [self insertEvent:e1 backlog:backlog nextIsGrouped:NO];
                            } else {
                                [self->_urlHandler fetchMediaURLs:result.URL result:^(BOOL success, NSString *error) {
                                    if([self->_data containsObject:event] && self->_buffer.bid == event.bid) {
                                        if(success) {
                                            Event *e1 = [self entity:event eid:entity_eid properties:[self->_urlHandler MediaURLs:result.URL]];
                                            if([[ImageCache sharedInstance] isValidURL:[e1.entities objectForKey:@"url"]]) {
                                                [self insertEvent:e1 backlog:YES nextIsGrouped:NO];
                                                [self reloadForEvent:e1];
                                            }
                                        } else {
                                            NSLog(@"METADATA FAILED: %@: %@", result.URL, error);
                                        }
                                    }
                                }];
                            }
                        }
                    }
                }
            }
        }
    }
}

-(Event *)entity:(Event *)parent eid:(NSTimeInterval)eid properties:(NSDictionary *)properties {
    Event *e1 = [[Event alloc] init];
    e1.cid = parent.cid;
    e1.bid = parent.bid;
    e1.eid = eid;
    e1.from = parent.from;
    e1.nick = parent.nick;
    e1.isSelf = parent.isSelf;
    e1.fromMode = parent.fromMode;
    e1.realname = parent.realname;
    e1.hostmask = parent.hostmask;
    e1.parent = parent.eid;
    e1.entities = properties;
    e1.avatar = parent.avatar;
    e1.avatarURL = parent.avatarURL;

    if([properties objectForKey:@"id"]) {
        if([[properties objectForKey:@"mime_type"] hasPrefix:@"image/"])
            e1.rowType = ROW_THUMBNAIL;
        else
            e1.rowType = ROW_FILE;
        int bytes = [[properties objectForKey:@"size"] intValue];
        if(bytes < 1024) {
            e1.msg = [NSString stringWithFormat:@"%lu B", (unsigned long)bytes];
        } else {
            int exp = (int)(log(bytes) / log(1024));
            e1.msg = [NSString stringWithFormat:@"%.1f %cB", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1]];
        }
    } else {
        e1.rowType = ROW_THUMBNAIL;
        if([[properties objectForKey:@"description"] isKindOfClass:NSString.class]) {
            e1.msg = [properties objectForKey:@"description"];
            e1.linkify = YES;
        } else {
            e1.msg = @"";
        }
    }
    e1.color = [UIColor messageTextColor];
    e1.bgColor = e1.isSelf?[UIColor selfBackgroundColor]:parent.bgColor;
    if([parent.type isEqualToString:@"buffer_me_msg"])
        e1.type = @"buffer_msg";
    else
        e1.type = parent.type;
    e1.formattedMsg = e1.msg;
    [self _format:e1];
    return e1;
}

-(void)updateTopUnread:(NSInteger)firstRow {
    if(!_topUnreadView)
        return;
    int highlights = 0;
    for(NSNumber *pos in _unseenHighlightPositions) {
        if([pos intValue] > firstRow)
            break;
        highlights++;
    }
    NSString *msg = @"";
    if(highlights) {
        if(highlights == 1)
            msg = @"mention and ";
        else
            msg = @"mentions and ";
        self->_topHighlightsCountView.count = [NSString stringWithFormat:@"%i", highlights];
        self->_topHighlightsCountView.hidden = NO;
        self->_topUnreadLabelXOffsetConstraint.constant = self->_topHighlightsCountView.intrinsicContentSize.width + 2;
    } else {
        self->_topHighlightsCountView.hidden = YES;
        self->_topUnreadLabelXOffsetConstraint.constant = 0;
    }
    if(@available(iOS 11, *)) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"] && [[UIDevice currentDevice] isBigPhone]) {
            self->_topUnreadDismissXOffsetConstraint.constant = -self.slidingViewController.view.safeAreaInsets.left;
        }
    }
    if(self->_lastSeenEidPos == 0 && firstRow < _data.count) {
        int seconds;
        if(firstRow < 0)
            seconds = (self->_earliestEid - _buffer.last_seen_eid) / 1000000;
        else
            seconds = ([[self->_data objectAtIndex:firstRow] eid] - _buffer.last_seen_eid) / 1000000;
        if(seconds < 0) {
            self->_topUnreadView.alpha = 0;
        } else {
            int minutes = seconds / 60;
            int hours = minutes / 60;
            int days = hours / 24;
            if(days) {
                if(days == 1)
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i day of unread messages", days];
                else
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i days of unread messages", days];
            } else if(hours) {
                if(hours == 1)
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i hour of unread messages", hours];
                else
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i hours of unread messages", hours];
            } else if(minutes) {
                if(minutes == 1)
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i minute of unread messages", minutes];
                else
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i minutes of unread messages", minutes];
            } else {
                if(seconds == 1)
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i second of unread messages", seconds];
                else
                    self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%i seconds of unread messages", seconds];
            }
        }
    } else {
        if(firstRow - _lastSeenEidPos == 1) {
            self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%li unread message", (long)(firstRow - _lastSeenEidPos)];
        } else if(firstRow - _lastSeenEidPos > 0) {
            self->_topUnreadLabel.text = [msg stringByAppendingFormat:@"%li unread messages", (long)(firstRow - _lastSeenEidPos)];
        } else {
            self->_topUnreadView.alpha = 0;
        }
    }
}

-(void)updateUnread {
    if(!_bottomUnreadView)
        return;
    NSString *msg = @"";
    if(self->_newHighlights) {
        if(self->_newHighlights == 1)
            msg = @"mention";
        else
            msg = @"mentions";
        self->_bottomHighlightsCountView.count = [NSString stringWithFormat:@"%li", (long)_newHighlights];
        self->_bottomHighlightsCountView.hidden = NO;
        self->_bottomUnreadLabelXOffsetConstraint.constant = self->_bottomHighlightsCountView.intrinsicContentSize.width + 2;
    } else {
        self->_bottomHighlightsCountView.hidden = YES;
        self->_bottomUnreadLabelXOffsetConstraint.constant = self->_bottomHighlightsCountView.intrinsicContentSize.width + 2;
    }
    if(self->_newMsgs - _newHighlights > 0) {
        if(self->_newHighlights)
            msg = [msg stringByAppendingString:@" and "];
        if(self->_newMsgs - _newHighlights == 1)
            msg = [msg stringByAppendingFormat:@"%li unread message", (long)(self->_newMsgs - _newHighlights)];
        else
            msg = [msg stringByAppendingFormat:@"%li unread messages", (long)(self->_newMsgs - _newHighlights)];
    }
    if(msg.length) {
        self->_bottomUnreadLabel.text = msg;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        self->_bottomUnreadView.alpha = 1;
        [UIView commitAnimations];
    }
}

-(void)_addItem:(Event *)e eid:(NSTimeInterval)eid {
    if(!e)
        return;
    @synchronized(self) {
        [self->_lock lock];
        NSInteger insertPos = -1;
        NSString *lastDay = nil;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:e.time];
        if(!e.timestamp) {
            if(__24hrPref) {
                if(__secondsPref)
                    [self->_formatter setDateFormat:@"HH:mm:ss"];
                else
                    [self->_formatter setDateFormat:@"HH:mm"];
            } else if(__secondsPref) {
                [self->_formatter setDateFormat:@"h:mm:ss a"];
            } else {
                [self->_formatter setDateFormat:@"h:mm a"];
            }
            
            e.timestamp = [self->_formatter stringFromDate:date];
        }
        if(!e.day) {
            [self->_formatter setDateFormat:@"DDD"];
            e.day = [self->_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:e.time]];
        }
        if(e.groupMsg && !e.formattedMsg) {
            e.formattedMsg = e.groupMsg;
            e.formatted = nil;
            e.height = 0;
        }
        e.groupEid = self->_currentCollapsedEid;
        
        if(eid > _maxEid || _data.count == 0 || (eid == e.eid && [e compare:[self->_data objectAtIndex:self->_data.count - 1]] == NSOrderedDescending)) {
            //Message at bottom
            if(self->_data.count) {
                lastDay = ((Event *)[self->_data objectAtIndex:self->_data.count - 1]).day;
            }
            self->_maxEid = eid;
            [self->_data addObject:e];
            insertPos = self->_data.count - 1;
        } else if(self->_minEid > eid) {
            //Message on top
            if(self->_data.count > 1) {
                lastDay = ((Event *)[self->_data objectAtIndex:1]).day;
                if(![lastDay isEqualToString:e.day]) {
                    //Insert above the dateline
                    [self->_data insertObject:e atIndex:0];
                    insertPos = 0;
                } else {
                    //Insert below the dateline
                    [self->_data insertObject:e atIndex:1];
                    insertPos = 1;
                }
            } else {
                [self->_data insertObject:e atIndex:0];
                insertPos = 0;
            }
        } else {
            int i = 0;
            for(Event *e1 in _data) {
                if(e1.rowType != ROW_TIMESTAMP && [e compare:e1] == NSOrderedAscending && e.eid == eid) {
                    //Insert the message
                    if(i > 0 && ((Event *)[self->_data objectAtIndex:i - 1]).rowType != ROW_TIMESTAMP) {
                        lastDay = ((Event *)[self->_data objectAtIndex:i - 1]).day;
                        [self->_data insertObject:e atIndex:i];
                        insertPos = i;
                        break;
                    } else {
                        //There was a dateline above our insertion point
                        lastDay = e1.day;
                        if(![lastDay isEqualToString:e.day]) {
                            if(i > 1) {
                                lastDay = ((Event *)[self->_data objectAtIndex:i - 2]).day;
                            } else {
                                //We're above the first dateline, so we'll need to put a new one on top
                                lastDay = nil;
                            }
                            [self->_data insertObject:e atIndex:i-1];
                            insertPos = i-1;
                        } else {
                            //Insert below the dateline
                            [self->_data insertObject:e atIndex:i];
                            insertPos = i;
                        }
                        break;
                    }
                } else if(e1.rowType != ROW_TIMESTAMP && (e1.eid == eid || e1.groupEid == eid)) {
                    //Replace the message
                    lastDay = e.day;
                    [self->_data removeObjectAtIndex:i];
                    [self->_data insertObject:e atIndex:i];
                    insertPos = i;
                    break;
                }
                i++;
            }
        }
        
        if(insertPos == -1) {
            CLS_LOG(@"Couldn't insert EID: %f MSG: %@", eid, e.formattedMsg);
            [self->_lock unlock];
            return;
        }
        
        if(eid > _buffer.last_seen_eid && e.isHighlight && !__notificationsMuted) {
            [self->_unseenHighlightPositions addObject:@(insertPos)];
            [self->_unseenHighlightPositions sortUsingSelector:@selector(compare:)];
        }
        
        if(eid < _minEid || _minEid == 0)
            self->_minEid = eid;
        
        if(![lastDay isEqualToString:e.day]) {
            [self->_formatter setDateFormat:@"EEEE, MMMM dd, yyyy"];
            Event *d = [[Event alloc] init];
            d.type = TYPE_TIMESTMP;
            d.rowType = ROW_TIMESTAMP;
            d.eid = eid;
            d.groupEid = -1;
            d.timestamp = [self->_formatter stringFromDate:date];
            d.bgColor = [UIColor timestampBackgroundColor];
            d.day = e.day;
            [self->_data insertObject:d atIndex:insertPos++];
        }
        
        if(insertPos < _data.count - 1) {
            Event *next = [self->_data objectAtIndex:insertPos + 1];
            if(![e isMessage] && e.rowType != ROW_LASTSEENEID) {
                next.isHeader = (next.groupEid < 1 && [next isMessage]) && next.rowType != ROW_ME_MESSAGE;
                next.height = 0;
                [self->_rowCache removeObjectForKey:@(insertPos + 1)];
            }
            if(([next.type isEqualToString:e.type] && [next.from isEqualToString:e.from] && [[next avatar:__largeAvatarHeight].absoluteString isEqualToString:[e avatar:__largeAvatarHeight].absoluteString]) || e.rowType == ROW_ME_MESSAGE) {
                if(e.isHeader)
                    e.height = 0;
                e.isHeader = NO;
            }
        }
        
        if(insertPos > 0 && e.parent == 0) {
            Event *prev = [self->_data objectAtIndex:insertPos - 1];
            if(prev.rowType == ROW_LASTSEENEID)
                prev = [self->_data objectAtIndex:insertPos - 2];
            BOOL wasHeader = e.isHeader;
            NSString *prevAvatar = [prev avatar:__largeAvatarHeight].absoluteString;
            NSString *avatar = [e avatar:__largeAvatarHeight].absoluteString;
            BOOL newAvatar = NO;
            if(prevAvatar || avatar) {
                newAvatar = ![avatar isEqualToString:prevAvatar];
            }
            e.isHeader = !__chatOneLinePref && (e.groupEid < 1 && [e isMessage] && (![prev.type isEqualToString:e.type] || ![prev.from isEqualToString:e.from] || newAvatar)) && e.rowType != ROW_ME_MESSAGE;
            if(wasHeader != e.isHeader)
                e.height = 0;
        }
        
        e.row = insertPos;
        
        [self->_lock unlock];
    }
}

-(Buffer *)buffer {
    return _buffer;
}

-(void)setBuffer:(Buffer *)buffer {
    self->_ready = NO;
    [self->_heartbeatTimer invalidate];
    self->_heartbeatTimer = nil;
    [self->_scrollTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
    self->_scrollTimer = nil;
    self->_requestingBacklog = NO;
    if(self->_buffer && _buffer.scrolledUp) {
        [self->_lock lock];
        int row = 0;
        NSInteger toprow = [self->_tableView indexPathForRowAtPoint:CGPointMake(0,_buffer.savedScrollOffset)].row;
        if(self->_tableView.tableHeaderView != nil)
            row++;
        for(Event *event in _data) {
            if((event.rowType == ROW_LASTSEENEID && [[EventsDataSource sharedInstance] unreadStateForBuffer:self->_buffer.bid lastSeenEid:self->_buffer.last_seen_eid type:self->_buffer.type] == 0) || event.rowType == ROW_BACKLOG) {
                if(toprow > row) {
                    self->_buffer.savedScrollOffset -= 26;
                }
            }
            if(++row > toprow)
                break;
        }
        [self->_lock unlock];
    }
    if(self->_buffer && buffer.bid != self->_buffer.bid) {
        for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:buffer.bid]) {
            if(event.rowType == ROW_LASTSEENEID) {
                [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                break;
            }
            event.formatted = nil;
            event.timestamp = nil;
        }
        self->_topUnreadView.alpha = 0;
        self->_bottomUnreadView.alpha = 0;
        @synchronized (self->_rowCache) {
            [self->_rowCache removeAllObjects];
        }
        [self->_expandedSectionEids removeAllObjects];
        [self->_urlHandler clearFileIDs];
        self->_bottomRow = -1;
        [[ImageCache sharedInstance] clear];
    }
    self->_buffer = buffer;
    if(buffer)
        self->_server = [[ServersDataSource sharedInstance] getServer:self->_buffer.cid];
    else
        self->_server = nil;
    self->_earliestEid = 0;
    [self refresh];
}

- (void)_scrollToBottom {
    @try {
        [self->_lock lock];
        [self->_scrollTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
        self->_scrollTimer = nil;
        if(self->_data.count) {
            [self->_tableView reloadData];
            [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_data.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            if([UIApplication sharedApplication].applicationState == UIApplicationStateActive)
                [self scrollViewDidScroll:self->_tableView];
        }
        self->_buffer.scrolledUp = NO;
        self->_buffer.scrolledUpFrom = -1;
        [self->_lock unlock];
    } @catch (NSException * e) {
        CLS_LOG(@"Failed to scroll down, will retry shortly. Exception: %@", e);
        [self performSelectorOnMainThread:@selector(scrollToBottom) withObject:nil waitUntilDone:YES];
    }
}

- (void)scrollToBottom {
    if(![NSThread currentThread].isMainThread) {
        CLS_LOG(@"scrollToBottom called on wrong thread");
        [self performSelectorOnMainThread:@selector(scrollToBottom) withObject:nil waitUntilDone:YES];
        return;
    }
    [self->_scrollTimer invalidate];
    
    self->_scrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_scrollToBottom) userInfo:nil repeats:NO];
}

- (void)reloadData {
    @synchronized(self) {
        [self->_reloadTimer invalidate];
        
        self->_reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_reloadData) userInfo:nil repeats:NO];
    }
}

- (void)_reloadData {
    @synchronized(self) {
        CGPoint offset = self->_tableView.contentOffset;
        [self->_tableView reloadData];
        if(self->_buffer.scrolledUp) {
            self->_tableView.contentOffset = offset;
        } else {
            [self _scrollToBottom];
        }
    }
}

- (void)reloadForEvent:(Event *)e {
    CGFloat h = self->_tableView.contentSize.height;
    [self _reloadData];
    [self->_tableView visibleCells];
    NSInteger bottom = self->_tableView.indexPathsForVisibleRows.lastObject.row;
    if(!_buffer.scrolledUp) {
        [self _scrollToBottom];
    } else if(e.row < bottom) {
        self->_tableView.contentOffset = CGPointMake(0, _tableView.contentOffset.y + (self->_tableView.contentSize.height - h));
    }
}

- (void)refresh {
    @synchronized(self) {
        NSDate *start = [NSDate date];
        if(self.tableView.bounds.size.width != [EventsDataSource sharedInstance].widthForHeightCache)
            [[EventsDataSource sharedInstance] clearHeightCache];
        [EventsDataSource sharedInstance].widthForHeightCache = self.tableView.bounds.size.width;
        [self->_reloadTimer invalidate];
        self->_urlHandler.window = self->_tableView.window;

        if(@available(iOS 11, *)) {
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"]) {
                self->_stickyAvatarXOffsetConstraint.constant = 20;
            } else {
                self->_stickyAvatarXOffsetConstraint.constant = 20 + self.slidingViewController.view.safeAreaInsets.left;
            }
        } else {
            self->_stickyAvatarXOffsetConstraint.constant = 20;
        }

        __24hrPref = NO;
        __secondsPref = NO;
        __timeLeftPref = NO;
        __nickColorsPref = NO;
        __colorizeMentionsPref = NO;
        __hideJoinPartPref = NO;
        __expandJoinPartPref = NO;
        __avatarsOffPref = NO;
        __chatOneLinePref = NO;
        __norealnamePref = NO;
        __monospacePref = NO;
        __disableInlineFilesPref = NO;
        __compact = NO;
        __disableBigEmojiPref = NO;
        __disableCodeSpanPref = NO;
        __disableCodeBlockPref = NO;
        __disableQuotePref = NO;
        __inlineMediaPref = NO;
        __avatarImages = YES;
        __replyCollapsePref = NO;
        __notificationsMuted = NO;
        __noColor = NO;
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        if(prefs) {
            __monospacePref = [[prefs objectForKey:@"font"] isEqualToString:@"mono"];
            __nickColorsPref = [[prefs objectForKey:@"nick-colors"] boolValue];
            __colorizeMentionsPref = [[prefs objectForKey:@"mention-colors"] boolValue];
            __secondsPref = [[prefs objectForKey:@"time-seconds"] boolValue];
            __24hrPref = [[prefs objectForKey:@"time-24hr"] boolValue];
            __timeLeftPref = [[NSUserDefaults standardUserDefaults] boolForKey:@"time-left"];
            __avatarsOffPref = [[NSUserDefaults standardUserDefaults] boolForKey:@"avatars-off"];
            __chatOneLinePref = [[NSUserDefaults standardUserDefaults] boolForKey:@"chat-oneline"];
            if(!__chatOneLinePref && !__avatarsOffPref)
                __timeLeftPref = NO;
            __norealnamePref = [[NSUserDefaults standardUserDefaults] boolForKey:@"chat-norealname"];
            __compact = [[prefs objectForKey:@"ascii-compact"] boolValue];
            __disableBigEmojiPref = [[prefs objectForKey:@"emoji-nobig"] boolValue];
            __disableCodeSpanPref = [[prefs objectForKey:@"chat-nocodespan"] boolValue];
            __disableCodeBlockPref = [[prefs objectForKey:@"chat-nocodeblock"] boolValue];
            __disableQuotePref = [[prefs objectForKey:@"chat-noquote"] boolValue];
            __avatarImages = [[NSUserDefaults standardUserDefaults] boolForKey:@"avatarImages"];

            __hideJoinPartPref = [[prefs objectForKey:@"hideJoinPart"] boolValue];
            if(__hideJoinPartPref) {
                NSDictionary *enableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    enableMap = [prefs objectForKey:@"channel-showJoinPart"];
                } else {
                    enableMap = [prefs objectForKey:@"buffer-showJoinPart"];
                }
                
                if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __hideJoinPartPref = NO;
            } else {
                NSDictionary *disableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    disableMap = [prefs objectForKey:@"channel-hideJoinPart"];
                } else {
                    disableMap = [prefs objectForKey:@"buffer-hideJoinPart"];
                }
                
                if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __hideJoinPartPref = YES;
            }

            
            __expandJoinPartPref = [[prefs objectForKey:@"expandJoinPart"] boolValue];
            if(__expandJoinPartPref) {
                NSDictionary *collapseMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    collapseMap = [prefs objectForKey:@"channel-collapseJoinPart"];
                } else {
                    collapseMap = [prefs objectForKey:@"buffer-collapseJoinPart"];
                }
                
                if((collapseMap && [[collapseMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]))
                    __expandJoinPartPref = NO;
            } else {
                NSDictionary *expandMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    expandMap = [prefs objectForKey:@"channel-expandJoinPart"];
                } else if([self->_buffer.type isEqualToString:@"console"]) {
                    expandMap = [prefs objectForKey:@"buffer-expandDisco"];
                } else {
                    expandMap = [prefs objectForKey:@"buffer-expandJoinPart"];
                }
                
                if((expandMap && [[expandMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]))
                    __expandJoinPartPref = YES;
            }
            NSDictionary *disableFilesMap;
            
            if([self->_buffer.type isEqualToString:@"channel"]) {
                disableFilesMap = [prefs objectForKey:@"channel-files-disableinline"];
            } else {
                disableFilesMap = [prefs objectForKey:@"buffer-files-disableinline"];
            }
            
            if([[prefs objectForKey:@"files-disableinline"] boolValue] || (disableFilesMap && [[disableFilesMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue]))
                __disableInlineFilesPref = YES;

            __inlineMediaPref = [[prefs objectForKey:@"inlineimages"] boolValue];
            if(__inlineMediaPref) {
                NSDictionary *disableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    disableMap = [prefs objectForKey:@"channel-inlineimages-disable"];
                } else {
                    disableMap = [prefs objectForKey:@"buffer-inlineimages-disable"];
                }
                
                if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __inlineMediaPref = NO;
            } else {
                NSDictionary *enableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    enableMap = [prefs objectForKey:@"channel-inlineimages"];
                } else {
                    enableMap = [prefs objectForKey:@"buffer-inlineimages"];
                }
                
                if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __inlineMediaPref = YES;
            }
            
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"inlineWifiOnly"] && ![NetworkConnection sharedInstance].isWifi) {
                __disableInlineFilesPref = YES;
                __inlineMediaPref = NO;
            }
            
            NSDictionary *replyCollapseMap;
            
            if([self->_buffer.type isEqualToString:@"channel"]) {
                replyCollapseMap = [prefs objectForKey:@"channel-reply-collapse"];
            } else {
                replyCollapseMap = [prefs objectForKey:@"buffer-reply-collapse"];
            }
            
            if([[prefs objectForKey:@"reply-collapse"] boolValue] || (replyCollapseMap && [[replyCollapseMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])) {
                __replyCollapsePref = YES;
            }
            
            if(self->_msgid)
                __replyCollapsePref = NO;
            
            __notificationsMuted = [[prefs objectForKey:@"notifications-mute"] boolValue];
            if(__notificationsMuted) {
                NSDictionary *disableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    disableMap = [prefs objectForKey:@"channel-notifications-mute-disable"];
                } else {
                    disableMap = [prefs objectForKey:@"buffer-notifications-mute-disable"];
                }
                
                if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __notificationsMuted = NO;
            } else {
                NSDictionary *enableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    enableMap = [prefs objectForKey:@"channel-notifications-mute"];
                } else {
                    enableMap = [prefs objectForKey:@"buffer-notifications-mute"];
                }
                
                if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __notificationsMuted = YES;
            }
            
            __noColor = [[prefs objectForKey:@"chat-nocolor"] boolValue];
            if(__noColor) {
                NSDictionary *enableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    enableMap = [prefs objectForKey:@"channel-chat-color"];
                } else {
                    enableMap = [prefs objectForKey:@"buffer-chat-color"];
                }
                
                if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __noColor = NO;
            } else {
                NSDictionary *disableMap;
                
                if([self->_buffer.type isEqualToString:@"channel"]) {
                    disableMap = [prefs objectForKey:@"channel-chat-nocolor"];
                } else {
                    disableMap = [prefs objectForKey:@"buffer-chat-nocolor"];
                }
                
                if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                    __noColor = YES;
            }
        }
#ifdef DEBUG
        if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
            __24hrPref = NO;
            __secondsPref = NO;
            __timeLeftPref = NO;
            __nickColorsPref = YES;
            __colorizeMentionsPref = YES;
            __hideJoinPartPref = NO;
            __expandJoinPartPref = NO;
            __avatarsOffPref = NO;
            __chatOneLinePref = NO;
            __norealnamePref = NO;
            __monospacePref = [[NSProcessInfo processInfo].arguments containsObject:@"-mono"];
            __disableInlineFilesPref = NO;
            __compact = NO;
            __disableBigEmojiPref = NO;
            __disableCodeSpanPref = NO;
            __disableCodeBlockPref = NO;
            __disableQuotePref = NO;
            __inlineMediaPref = YES;
            __avatarImages = YES;
            __replyCollapsePref = NO;
        }
#endif
        __largeAvatarHeight = MIN(32, roundf(FONT_SIZE * 2) + (__compact ? 1 : 6));
        if(__monospacePref)
            self->_groupIndent = @"  ";
        else
            self->_groupIndent = @"    ";
        self->_tableView.backgroundColor = [UIColor contentBackgroundColor];
        self->_headerView.backgroundColor = [UIColor contentBackgroundColor];
        self->_backlogFailedView.backgroundColor = [UIColor contentBackgroundColor];
        [self->_loadMoreBacklog setTitleColor:[UIColor isDarkTheme]?[UIColor navBarSubheadingColor]:[UIColor unreadBlueColor] forState:UIControlStateNormal];
        [self->_loadMoreBacklog setTitleShadowColor:[UIColor contentBackgroundColor] forState:UIControlStateNormal];
        self->_loadMoreBacklog.backgroundColor = [UIColor contentBackgroundColor];
        
        self->_linkAttributes = [UIColor linkAttributes];
        self->_lightLinkAttributes = [UIColor lightLinkAttributes];
        
        __socketClosedBackgroundImage = nil;
        [UIColor socketClosedBackgroundColor];
        
        [self->_lock lock];
        [self->_scrollTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
        self->_scrollTimer = nil;
        self->_ready = NO;
        NSInteger oldPosition = (self->_requestingBacklog && _data.count && [self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, _tableView.contentInset)].count)?[[[self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, _tableView.contentInset)] objectAtIndex: 0] row]:-1;
        NSTimeInterval backlogEid = (self->_requestingBacklog && _data.count && oldPosition < _data.count)?[[self->_data objectAtIndex:oldPosition] groupEid]-1:0;
        if(backlogEid < 1)
            backlogEid = (self->_requestingBacklog && _data.count && oldPosition < _data.count)?[[self->_data objectAtIndex:oldPosition] eid]-1:0;
        
        [self->_data removeAllObjects];
        self->_minEid = self->_maxEid = self->_earliestEid = self->_newMsgs = self->_newHighlights = 0;
        self->_lastSeenEidPos = -1;
        self->_currentCollapsedEid = 0;
        self->_lastCollpasedDay = @"";
        [self->_collapsedEvents clear];
        self->_collapsedEvents.server = self->_server;
        [self->_unseenHighlightPositions removeAllObjects];
        self->_hiddenAvatarRow = -1;
        self->_stickyAvatar.hidden = YES;
        __smallAvatarHeight = roundf(FONT_SIZE) + 2;
        self->_msgids = [[NSMutableDictionary alloc] init];
        
        if(!_buffer) {
            [self->_lock unlock];
            self->_tableView.tableHeaderView = nil;
            [self->_tableView reloadData];
            return;
        }
        
        if(self->_conn.state == kIRCCloudStateConnected)
            [[NetworkConnection sharedInstance] cancelIdleTimer]; //This may take a while
        UIFont *f = __monospacePref?[ColorFormatter monoTimestampFont]:[ColorFormatter timestampFont];
        __timestampWidth = [@"88:88" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        if(__secondsPref)
            __timestampWidth += [@":88" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        if(!__24hrPref)
            __timestampWidth += [@" AM" sizeWithAttributes:@{NSFontAttributeName:f}].width;
        __timestampWidth += 8;
        
        NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid];
        _shouldAutoFetch = !_requestingBacklog && events.count < 50;
        
        if(events.count) {
            NSMutableDictionary *uuids = [[NSMutableDictionary alloc] init];
            for(int i = 0; i < events.count; i++) {
                Event *e = [events objectAtIndex:i];
                Event *next = (i < events.count - 1)?[events objectAtIndex:i+1]:nil;
                if(e.childEventCount) {
                    e.formatted = nil;
                    e.formattedMsg = nil;
                }
                e.replyCount = 0;
                NSString *type = next.type;
                if(next && _currentCollapsedEid != -1 && ![_expandedSectionEids objectForKey:@(_currentCollapsedEid)] &&
                   ([type isEqualToString:@"joined_channel"] || [type isEqualToString:@"parted_channel"] || [type isEqualToString:@"nickchange"] || [type isEqualToString:@"quit"] || [type isEqualToString:@"user_channel_mode"])) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:next.time];
                    [self insertEvent:e backlog:YES nextIsGrouped:[_lastCollpasedDay isEqualToString:[self->_formatter stringFromDate:date]]];
                } else {
                    [self insertEvent:e backlog:YES nextIsGrouped:NO];
                }
                [uuids setObject:@(YES) forKey:e.UUID];
            }
            for(NSString *uuid in _rowCache.allKeys) {
                if(![uuids objectForKey:uuid])
                    [self->_rowCache removeObjectForKey:uuid];
            }
            self->_tableView.tableHeaderView = nil;
        }
        
        int row = 0;
        for(Event *e in _data) {
            if(e.formattedMsg && !e.formatted) {
                [self _format:e];
                [self tableView:self.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            }
            row++;
        }
        
        if(backlogEid > 0) {
            for(NSInteger i = self->_data.count-1 ; i >= 0; i--) {
                Event *e = [self->_data objectAtIndex:i];
                if(e.eid == backlogEid)
                    backlogEid--;
            }
            
            Event *e = [[Event alloc] init];
            e.eid = backlogEid;
            e.type = TYPE_BACKLOG;
            e.rowType = ROW_BACKLOG;
            e.formattedMsg = nil;
            e.bgColor = [UIColor contentBackgroundColor];
            [self _addItem:e eid:backlogEid];
            e.timestamp = nil;
        }
        
        if(self->_buffer.last_seen_eid == 0 && _data.count > 1) {
            self->_lastSeenEidPos = 1;
        } else if((self->_minEid > 0 && _minEid >= self->_buffer.last_seen_eid) || (self->_data.count == 0 && _buffer.last_seen_eid > 0)) {
            self->_lastSeenEidPos = 0;
        } else {
            Event *e = [[Event alloc] init];
            e.cid = self->_buffer.cid;
            e.bid = self->_buffer.bid;
            e.type = TYPE_LASTSEENEID;
            e.rowType = ROW_LASTSEENEID;
            e.formattedMsg = nil;
            e.bgColor = [UIColor contentBackgroundColor];
            e.timestamp = @"New Messages";
            self->_lastSeenEidPos = self->_data.count - 1;
            NSEnumerator *i = [self->_data reverseObjectEnumerator];
            Event *event = [i nextObject];
            while(event) {
                if((event.eid <= self->_buffer.last_seen_eid || (event.parent > 0 && event.parent <= self->_buffer.last_seen_eid)) && event.rowType != ROW_LASTSEENEID)
                    break;
                e.eid = event.eid - 1;
                event = [i nextObject];
                self->_lastSeenEidPos--;
            }
            if(self->_lastSeenEidPos != self->_data.count - 1 && !event.isSelf && !event.pending) {
                if(self->_lastSeenEidPos > 0 && [[self->_data objectAtIndex:self->_lastSeenEidPos - 1] rowType] == ROW_TIMESTAMP)
                    self->_lastSeenEidPos--;
                if(self->_lastSeenEidPos > 0) {
                    for(Event *event in events) {
                        if(event.rowType == ROW_LASTSEENEID) {
                            [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
                            [self->_data removeObject:event];
                            break;
                        }
                    }
                    [[EventsDataSource sharedInstance] addEvent:e];
                    [self _addItem:e eid:e.eid];
                    e.groupEid = -1;
                }
            } else {
                self->_lastSeenEidPos = -1;
            }
        }
        
        self->_backlogFailedView.frame = self->_headerView.frame = CGRectMake(0,0,_headerView.frame.size.width, 60);
        
        [self->_tableView reloadData];
        
        if(events.count)
            self->_earliestEid = ((Event *)[events objectAtIndex:0]).eid;
        if(events.count && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && _conn.ready && _tableView.contentSize.height > _tableView.bounds.size.height) {
            self->_tableView.tableHeaderView = self->_headerView;
        } else if((!_data.count || _earliestEid > _buffer.min_eid) && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && _conn.ready && !(self->_msgid && [self->_msgids objectForKey:self->_msgid])) {
            self->_tableView.tableHeaderView = self->_backlogFailedView;
        } else {
            self->_tableView.tableHeaderView = nil;
        }
        if(_earliestEid == _buffer.min_eid)
            self->_shouldAutoFetch = NO;
        
        @try {
            if(self->_requestingBacklog && backlogEid > 0 && _buffer.scrolledUp) {
                int markerPos = -1;
                for(Event *e in _data) {
                    if(e.eid == backlogEid)
                        break;
                    markerPos++;
                }
                if(markerPos < [self->_tableView numberOfRowsInSection:0])
                    [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:markerPos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            } else if(self->_eidToOpen > 0) {
                if(self->_eidToOpen <= self->_maxEid) {
                    int i = 0;
                    for(Event *e in _data) {
                        if(e.eid == self->_eidToOpen) {
                            [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                            self->_buffer.scrolledUpFrom = [[self->_data objectAtIndex:[[[self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, _tableView.contentInset)] lastObject] row]] eid];
                            break;
                        }
                        i++;
                    }
                    self->_eidToOpen = -1;
                } else {
                    if(!_buffer.scrolledUp)
                        self->_buffer.scrolledUpFrom = -1;
                }
            } else if(self->_buffer.scrolledUp && _buffer.savedScrollOffset > 0) {
                if((self->_buffer.savedScrollOffset + _tableView.tableHeaderView.bounds.size.height) <= _tableView.contentSize.height - UIEdgeInsetsInsetRect(_tableView.bounds, _tableView.contentInset).size.height) {
                    self->_tableView.contentOffset = CGPointMake(0, (self->_buffer.savedScrollOffset + _tableView.tableHeaderView.bounds.size.height));
                } else {
                    [self _scrollToBottom];
                    [self scrollToBottom];
                }
            } else if(!_buffer.scrolledUp || (self->_data.count && _scrollTimer)) {
                [self _scrollToBottom];
                [self scrollToBottom];
            }
        } @catch (NSException *e) {
            NSLog(@"Unable to set scroll position: %@", e);
        }
        
        if(self->_data.count == 0 && _buffer.bid != -1 && _buffer.min_eid > 0 && _conn.state == kIRCCloudStateConnected && [UIApplication sharedApplication].applicationState == UIApplicationStateActive && _conn.ready && !_requestingBacklog) {
            self->_tableView.tableHeaderView = self->_backlogFailedView;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            NSArray *rows = [self->_tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self->_tableView.bounds, self->_tableView.contentInset)];
            if(self->_data.count && rows.count) {
                NSInteger firstRow = [[rows objectAtIndex:0] row];
                NSInteger lastRow = [[rows lastObject] row];
                Event *e = ((self->_lastSeenEidPos+1) < self->_data.count)?[self->_data objectAtIndex:self->_lastSeenEidPos+1]:nil;
                if(e && ((self->_lastSeenEidPos > 0 && firstRow > self->_lastSeenEidPos) || self->_lastSeenEidPos == 0) && e.eid >= self->_buffer.last_seen_eid) {
                    if(self->_topUnreadView.alpha == 0) {
                        [UIView beginAnimations:nil context:nil];
                        [UIView setAnimationDuration:0.1];
                        self->_topUnreadView.alpha = 1;
                        [UIView commitAnimations];
                    }
                    [self updateTopUnread:firstRow];
                } else if(lastRow < self->_lastSeenEidPos) {
                    for(Event *e in self->_data) {
                        if(self->_buffer.last_seen_eid > 0 && e.eid > self->_buffer.last_seen_eid && !e.isSelf && e.rowType != ROW_LASTSEENEID && [e isImportant:self->_buffer.type]) {
                            self->_newMsgs++;
                            if(e.isHighlight && !__notificationsMuted)
                                self->_newHighlights++;
                        }
                    }
                } else {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    self->_topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                }
                self->_requestingBacklog = NO;
            } else if(self->_earliestEid > self->_buffer.last_seen_eid) {
                if(self->_topUnreadView.alpha == 0) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    self->_topUnreadView.alpha = 1;
                    [UIView commitAnimations];
                }
                [self updateTopUnread:-1];
            }
            
            [self updateUnread];
            self->_ready = YES;
            [self scrollViewDidScroll:self->_tableView];
            [self->_tableView flashScrollIndicators];
            
            if((self->_buffer.deferred || (self->_shouldAutoFetch && (rows.count == 0 || [[rows objectAtIndex:0] row] == 0))) && self->_conn.state == kIRCCloudStateConnected && self->_conn.ready) {
                [self loadMoreBacklogButtonPressed:nil];
            }
            
            NSLog(@"Refresh finished in %f seconds", [start timeIntervalSinceNow] * -1.0);
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    @synchronized (self->_rowCache) {
        [self->_rowCache removeAllObjects];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    [self->_lock lock];
    NSInteger count = self->_data.count;
    [self->_lock unlock];
    return count;
}

- (void)_format:(Event *)e {
    @synchronized (e) {
        NSArray *links;
        [self->_lock lock];
        if(!__disableBigEmojiPref && ([e.type isEqualToString:@"buffer_msg"] || [e.type isEqualToString:@"notice"])) {
            NSMutableString *msg = [[e.msg stripIRCFormatting] mutableCopy];
            if(msg) {
                [ColorFormatter emojify:msg];
                e.isEmojiOnly = [msg isEmojiOnly];
            }
        } else {
            e.isEmojiOnly = NO;
        }
        if(e.from.length)
            e.formattedNick = [ColorFormatter format:[self->_collapsedEvents formatNick:e.fromNick mode:e.fromMode colorize:(__nickColorsPref && !e.isSelf) defaultColor:[UIColor isDarkTheme]?@"ffffff":@"142b43" displayName:e.from] defaultColor:e.color mono:__monospacePref linkify:NO server:nil links:nil];
        if([e.realname isKindOfClass:[NSString class]] && e.realname.length) {
            e.formattedRealname = [ColorFormatter format:e.realname.stripIRCColors defaultColor:[UIColor collapsedRowTextColor] mono:__monospacePref linkify:YES server:self->_server links:&links];
            e.realnameLinks = links;
            links = nil;
        }
        if(!__disableQuotePref && e.rowType == ROW_MESSAGE && e.formattedMsg.length > 1 && [e.formattedMsg isBlockQuote]) {
            e.formattedMsg = [e.formattedMsg substringFromIndex:1];
            e.mentionOffset--;
            e.isQuoted = YES;
        } else {
            e.isQuoted = NO;
        }
        NSString *formattedMsg = e.formattedMsg;
        if(e.rowType == ROW_FAILED || (e.groupEid < 0 && (e.from.length || e.rowType == ROW_ME_MESSAGE) && !__avatarsOffPref && (__chatOneLinePref || e.rowType == ROW_ME_MESSAGE) && e.rowType != ROW_THUMBNAIL && e.rowType != ROW_FILE && e.parent == 0))
            formattedMsg = [NSString stringWithFormat:@"\u2001\u2005%@",e.formattedMsg];

        e.formatted = [ColorFormatter format:formattedMsg defaultColor:e.color mono:__monospacePref || e.monospace linkify:e.linkify server:self->_server links:&links largeEmoji:e.isEmojiOnly mentions:[e.entities objectForKey:@"mentions"] colorizeMentions:__colorizeMentionsPref mentionOffset:e.mentionOffset + (formattedMsg.length - e.formattedMsg.length) mentionData:[e.entities objectForKey:@"mention_data"]];

        if([e.entities objectForKey:@"files"] || [e.entities objectForKey:@"pastes"]) {
            NSMutableArray *mutableLinks = links.mutableCopy;
            for(int i = 0; i < mutableLinks.count; i++) {
                NSTextCheckingResult *r = [mutableLinks objectAtIndex:i];
                if(r.resultType == NSTextCheckingTypeLink) {
                    for(NSDictionary *file in [e.entities objectForKey:@"files"]) {
                        NSString *url = [[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":[file objectForKey:@"id"]} error:nil];
                        if(url && ([r.URL.absoluteString isEqualToString:url] || [r.URL.absoluteString hasPrefix:[url stringByAppendingString:@"/"]])) {
                            [_urlHandler addFileID:[file objectForKey:@"id"] URL:r.URL];
                        }
                    }
                    for(NSDictionary *paste in [e.entities objectForKey:@"pastes"]) {
                        NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:@{@"id":[paste objectForKey:@"id"]} error:nil];
                        if(url && ([r.URL.absoluteString isEqualToString:url] || [r.URL.absoluteString hasPrefix:[url stringByAppendingString:@"/"]])) {
                            r = [NSTextCheckingResult linkCheckingResultWithRange:r.range URL:[NSURL URLWithString:[NSString stringWithFormat:@"irccloud-paste-%@?id=%@", url, [paste objectForKey:@"id"]]]];
                            [mutableLinks setObject:r atIndexedSubscript:i];
                        }
                    }
                }
            }
            links = mutableLinks;
        }
        e.links = links;
        
        if(e.from.length && e.msg.length) {
            e.accessibilityLabel = [NSString stringWithFormat:@"Message from %@: ", e.from];
            e.accessibilityValue = [[[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string] stringByAppendingFormat:@", at %@", e.timestamp];
        } else if([e.type isEqualToString:@"buffer_me_msg"]) {
            e.accessibilityLabel = @"Action: ";
            e.accessibilityValue = [NSString stringWithFormat:@"%@ %@, at: %@", e.nick, [[ColorFormatter format:e.msg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string], e.timestamp];
        } else if(e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE) {
            NSMutableString *s = [[[ColorFormatter format:e.formattedMsg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string] mutableCopy];
            if(s.length > 1) {
                [s replaceOccurrencesOfString:@"→" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"←" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"⇐" withString:@"" options:0 range:NSMakeRange(0, 1)];
                [s replaceOccurrencesOfString:@"•" withString:@"" options:0 range:NSMakeRange(0, s.length)];
                [s replaceOccurrencesOfString:@"↔" withString:@"" options:0 range:NSMakeRange(0, 1)];
                
                if([e.type hasSuffix:@"nickchange"])
                    [s replaceOccurrencesOfString:@"→" withString:@"changed their nickname to" options:0 range:NSMakeRange(0, s.length)];
            }
            [s appendFormat:@", at: %@", e.timestamp];
            e.accessibilityLabel = @"Status message:";
            e.accessibilityValue = s;
        }
        
        if((e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE || e.rowType == ROW_FAILED || e.rowType == ROW_SOCKETCLOSED) && e.groupEid > 0 && (e.groupEid != e.eid || [self->_expandedSectionEids objectForKey:@(e.groupEid)])) {
            NSMutableString *s = [[[ColorFormatter format:e.formattedMsg defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string] mutableCopy];
            [s replaceOccurrencesOfString:@"→" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"←" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"⇐" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"•" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            [s replaceOccurrencesOfString:@"↔" withString:@"." options:0 range:NSMakeRange(0, s.length)];
            if([s rangeOfString:@"."].location != NSNotFound)
                [s replaceCharactersInRange:[s rangeOfString:@"."] withString:@""];
            e.accessibilityValue = s;
        }
        [self->_lock unlock];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self->_lock lock];
    if(indexPath.row >= self->_data.count) {
        [self->_lock unlock];
        return 0;
    }
    Event *e = [self->_data objectAtIndex:indexPath.row];
    [self->_lock unlock];
    @synchronized (e) {
        if(e.rowType == ROW_THUMBNAIL) {
            float width = self.tableView.bounds.size.width/2;
            if(![[[e.entities objectForKey:@"properties"] objectForKey:@"width"] intValue] || ![[[e.entities objectForKey:@"properties"] objectForKey:@"height"] intValue]) {
                CGSize size = CGSizeZero;
                
                if([e.entities objectForKey:@"id"] && [[ImageCache sharedInstance] isLoaded:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)]) {
                    YYImage *img = [[ImageCache sharedInstance] imageForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)];
                    if(img)
                        size = img.size;
                } else if([[ImageCache sharedInstance] isLoaded:[e.entities objectForKey:@"thumb"]]) {
                    YYImage *img = [[ImageCache sharedInstance] imageForURL:[e.entities objectForKey:@"thumb"]];
                    if(img)
                        size = img.size;
                }
                if(size.width > 0 && size.height > 0) {
                    NSMutableDictionary *entities = [e.entities mutableCopy];
                    if(size.width > width) {
                        float ratio = width / size.width;
                        size.width = width;
                        size.height = size.height * ratio;
                    } else {
                        size.width *= [UIScreen mainScreen].scale;
                        size.height *= [UIScreen mainScreen].scale;
                    }
                    [entities setObject:@{@"width":@(size.width), @"height":@(size.height)} forKey:@"properties"];
                    e.entities = entities;
                }
            }
        }
        if(e.formattedMsg && !e.formatted)
            [self _format:e];
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        cell.bounds = CGRectMake(0,0,self.tableView.bounds.size.width,cell.bounds.size.height);
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        e.height = ceilf([cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height);
        return e.height;
    }
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self->_lock lock];
    if(indexPath.row >= self->_data.count) {
        [self->_lock unlock];
        return 0;
    }
    Event *e = [self->_data objectAtIndex:indexPath.row];
    [self->_lock unlock];
    if(e.height)
        return e.height;
    else
        return ceilf(FONT_SIZE);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath row] >= self->_data.count) {
        [self->_lock unlock];
        return [[self->_eventsTableCell instantiateWithOwner:self options:nil] objectAtIndex:0];
    }

    [self->_lock lock];
    Event *e = [self->_data objectAtIndex:indexPath.row];
    [self->_lock unlock];

    if(e.rowType == ROW_THUMBNAIL) {
        EventsTableCell_Thumbnail *cell = nil;
        if([[self->_rowCache objectForKey:[e UUID]] isKindOfClass:EventsTableCell_Thumbnail.class])
            cell = [self->_rowCache objectForKey:[e UUID]];
        if(!cell)
            cell = [[self->_eventsTableCell_Thumbnail instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self->_rowCache setObject:cell forKey:[e UUID]];
        
        cell.filename.textColor = [UIColor linkColor];
        cell.filename.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        cell.filename.text = [e.entities objectForKey:@"name"];
        
        if([e.entities objectForKey:@"id"] || [[e.entities objectForKey:@"name"] length] || [[e.entities objectForKey:@"description"] length]) {
            cell.background.backgroundColor = [UIColor navBarColor];
        } else {
            cell.background.backgroundColor = [UIColor clearColor];
        }
        float width = self.tableView.bounds.size.width/2;
        if([e.entities objectForKey:@"id"]) {
            cell.thumbnail.image = [[ImageCache sharedInstance] imageForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)];
        } else {
            cell.thumbnail.image = [[ImageCache sharedInstance] imageForURL:[e.entities objectForKey:@"thumb"]];
        }
        cell.spinner.hidden = YES;
        cell.spinner.activityIndicatorViewStyle = [UIColor activityIndicatorViewStyle];
        cell.thumbnail.hidden = !(cell.thumbnail.image != nil);
        if(cell.thumbnail.image) {
            if(![[[e.entities objectForKey:@"properties"] objectForKey:@"height"] intValue]) {
                cell.thumbnail.image = nil;
                cell.spinner.hidden = NO;
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    NSLog(@"Image dimensions were missing, reloading table");
                    e.height = 0;
                    [self reloadForEvent:e];
                }];
            } else {
                if(width > [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue])
                    width = [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
                float ratio = width / [[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue];
                CGFloat thumbWidth = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"width"] floatValue] * ratio);
                if(thumbWidth == 0 || thumbWidth > self.tableView.bounds.size.width) {
                    CLS_LOG(@"invalid thumbnail width: %f ratio: %f", width, ratio);
                    @synchronized(self->_data) {
                        [self->_data removeObject:e];
                    }
                    cell.thumbnailWidth.constant = FONT_SIZE * 2;
                    cell.thumbnailHeight.constant = FONT_SIZE * 2;
                    [self.tableView reloadData];
                } else {
                    cell.thumbnailWidth.constant = thumbWidth;
                    cell.thumbnailHeight.constant = ceilf([[[e.entities objectForKey:@"properties"] objectForKey:@"height"] floatValue] * ratio);
                    if(e.height > 0 && e.height < cell.thumbnailHeight.constant) {
                        e.height = 0;
                        [self reloadForEvent:e];
                    }
                    [cell.thumbnail layoutIfNeeded];
                }
            }
        } else {
            cell.thumbnailWidth.constant = FONT_SIZE * 2;
            cell.thumbnailHeight.constant = FONT_SIZE * 2;
            if([e.entities objectForKey:@"id"]) {
                if(![[NSFileManager defaultManager] fileExistsAtPath:[[ImageCache sharedInstance] pathForFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale)].path]) {
                    cell.spinner.hidden = NO;
                    [[ImageCache sharedInstance] fetchFileID:[e.entities objectForKey:@"id"] width:(int)(width * [UIScreen mainScreen].scale) completionHandler:^(BOOL success) {
                        if(!success) {
                            e.rowType = ROW_FILE;
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            cell.spinner.hidden = YES;
                            e.height = 0;
                            [self reloadForEvent:e];
                        }];
                    }];
                } else {
                    e.rowType = ROW_FILE;
                    cell.spinner.hidden = YES;
                }
            } else {
                if(![[NSFileManager defaultManager] fileExistsAtPath:[[ImageCache sharedInstance] pathForURL:[e.entities objectForKey:@"thumb"]].path]) {
                    cell.spinner.hidden = NO;
                    [[ImageCache sharedInstance] fetchURL:[e.entities objectForKey:@"thumb"] completionHandler:^(BOOL success) {
                        if(!success) {
                            @synchronized(self->_data) {
                                [self->_data removeObject:e];
                            }
                        }
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            e.height = 0;
                            cell.spinner.hidden = YES;
                            [self reloadForEvent:e];
                        }];
                    }];
                } else {
                    cell.spinner.hidden = YES;
                    @synchronized(self->_data) {
                        [self->_data removeObject:e];
                    }
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self reloadData];
                    }];
                }
            }
        }
    }

    if(e.rowType == ROW_FILE) {
        EventsTableCell_File *cell = nil;
        if([[self->_rowCache objectForKey:[e UUID]] isKindOfClass:EventsTableCell_File.class])
            cell = [self->_rowCache objectForKey:[e UUID]];
        if(!cell)
            cell = [[self->_eventsTableCell_File instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self->_rowCache setObject:cell forKey:[e UUID]];
        
        NSString *extension = [e.entities objectForKey:@"extension"];
        if(extension.length)
            extension = [extension substringFromIndex:1];
        else
            extension = [[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1];
        
        cell.extension.font = [UIFont boldSystemFontOfSize:FONT_SIZE * 1.5];
        cell.extension.text = extension.uppercaseString;
        
        cell.filename.textColor = [UIColor linkColor];
        cell.filename.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        cell.filename.text = [e.entities objectForKey:@"name"];

        cell.mimeType.textColor = [UIColor messageTextColor];
        cell.mimeType.font = [UIFont systemFontOfSize:FONT_SIZE];
        cell.mimeType.text = [e.entities objectForKey:@"mime_type"];
        cell.mimeType.numberOfLines = 1;
        cell.mimeType.lineBreakMode = NSLineBreakByTruncatingTail;
        
        cell.background.backgroundColor = [UIColor connectionBarColor];
    }
    
    if(e.rowType == ROW_REPLY_COUNT) {
        EventsTableCell_ReplyCount *cell = nil;
        if([[self->_rowCache objectForKey:[e UUID]] isKindOfClass:EventsTableCell_File.class])
            cell = [self->_rowCache objectForKey:[e UUID]];
        if(!cell)
            cell = [[self->_eventsTableCell_ReplyCount instantiateWithOwner:self options:nil] objectAtIndex:0];
        [self->_rowCache setObject:cell forKey:[e UUID]];
        
        Event *parent = [e.entities objectForKey:@"parent"];
        cell.reply.font = [ColorFormatter awesomeFont];
        cell.reply.textColor = [UIColor colorFromHexString:[UIColor colorForNick:parent.msgid]];
        cell.reply.text = FA_COMMENTS;
        cell.reply.hidden = NO;
        cell.replyButton.hidden = NO;
        cell.reply.alpha = 0.4;
        cell.replyCount.font = [ColorFormatter messageFont:__monospacePref];
        cell.replyCount.textColor = [UIColor messageTextColor];
        cell.replyCount.text = [NSString stringWithFormat:@"%i %@", parent.replyCount, parent.replyCount == 1 ? @"reply" : @"replies"];
        if(parent.replyNicks.count)
            cell.replyCount.text = [NSString stringWithFormat:@"%@: %@", cell.replyCount.text, [parent.replyNicks.allObjects componentsJoinedByString:@", "]];
        cell.replyCount.alpha = 0.4;
        cell.replyCount.preferredMaxLayoutWidth = self.tableView.bounds.size.width / 2;
    }

    EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
    if(!cell)
        cell = [[self->_eventsTableCell instantiateWithOwner:self options:nil] objectAtIndex:0];
    [self->_rowCache setObject:cell forKey:[e UUID]];

    cell.backgroundView = nil;
    cell.backgroundColor = nil;
    cell.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    cell.contentView.backgroundColor = e.bgColor;
    if(e.isHeader && !__chatOneLinePref) {
        if(!cell.nickname.text.length) {
            NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithAttributedString:e.formattedNick];
            if(e.formattedRealname && ([e.realname isKindOfClass:[NSString class]] && ![e.realname.lowercaseString isEqualToString:e.from.lowercaseString]) && !__norealnamePref) {
                [s appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
                [s appendAttributedString:e.formattedRealname];
            }
            cell.nickname.attributedText = s;
            cell.nickname.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        cell.avatar.hidden = __avatarsOffPref || (indexPath.row == self->_hiddenAvatarRow);
    } else {
        cell.nickname.text = nil;
        cell.avatar.hidden = !((__chatOneLinePref || e.rowType == ROW_ME_MESSAGE) && !__avatarsOffPref && e.parent == 0 && e.groupEid < 1);
    }
    float avatarHeight = __avatarsOffPref?0:((__chatOneLinePref || e.rowType == ROW_ME_MESSAGE)?__smallAvatarHeight:__largeAvatarHeight);

    cell.avatarTop.constant = (avatarHeight > __smallAvatarHeight || !__compact)?2:0;
    if(__chatOneLinePref && e.isEmojiOnly)
        cell.avatarTop.constant += FONT_SIZE;
    cell.avatarWidth.constant = cell.avatarHeight.constant = avatarHeight;
    
    cell.replyXOffset.constant = __timeLeftPref ? -__timestampWidth : 0;
    
    if(__avatarsOffPref) {
        cell.avatar.image = nil;
        cell.replyXOffset.constant += 4;
    } else {
        cell.replyXOffset.constant -= 4;
        if(__avatarImages) {
            NSURL *avatarURL = [e avatar:avatarHeight * [UIScreen mainScreen].scale];
            if(avatarURL) {
                BOOL needsRefresh = NO;
                if(![[ImageCache sharedInstance] isLoaded:avatarURL])
                    needsRefresh = [[ImageCache sharedInstance] ageOfCache:avatarURL] >= 600;
                
                if(needsRefresh) {
                    NSLog(@"Avatar needs refresh: %@", avatarURL);
                }
                
                UIImage *image = [[ImageCache sharedInstance] imageForURL:avatarURL];
                if(image) {
                    cell.avatar.image = image;
                    cell.avatar.layer.cornerRadius = 5.0;
                    cell.avatar.layer.masksToBounds = YES;
                    cell.avatar.userInteractionEnabled = YES;
                    cell.largeAvatarURL = [e avatar:[UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale];
                } else {
                    cell.avatar.userInteractionEnabled = NO;
                    cell.largeAvatarURL = nil;
                }
                
                if(![[NSFileManager defaultManager] fileExistsAtPath:[[ImageCache sharedInstance] pathForURL:avatarURL].path] || needsRefresh) {
                    [[ImageCache sharedInstance] fetchURL:avatarURL completionHandler:^(BOOL success) {
                        if(success || [[ImageCache sharedInstance] isValidURL:[e avatar:avatarHeight * [UIScreen mainScreen].scale]])
                            [self reloadForEvent:e];
                    }];
                }
            }
        }
        if(!cell.avatar.image) {
            cell.avatar.layer.cornerRadius = 0;
            if(e.from.length) {
                cell.avatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.from nick:e.fromNick bid:e.bid] getImage:avatarHeight isSelf:e.isSelf];
            } else if(e.rowType == ROW_ME_MESSAGE && e.nick.length) {
                cell.avatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.nick nick:e.fromNick bid:e.bid] getImage:__smallAvatarHeight isSelf:e.isSelf];
            } else {
                cell.avatar.image = nil;
            }
        }
    }
    cell.timestampLeft.font = cell.timestampRight.font = cell.lastSeenEID.font = __monospacePref?[ColorFormatter monoTimestampFont]:[ColorFormatter timestampFont];
    cell.message.linkDelegate = self;
    cell.nickname.linkDelegate = self;
    cell.accessory.font = [ColorFormatter awesomeFont];
    cell.accessory.textColor = [UIColor expandCollapseIndicatorColor];
    cell.accessibilityLabel = e.accessibilityLabel;
    cell.accessibilityValue = e.accessibilityValue;
    cell.accessibilityHint = nil;
    cell.accessibilityElementsHidden = NO;

    cell.messageOffsetTop.constant = __compact ? -2 : 0;
    cell.messageOffsetLeft.constant = (__timeLeftPref ? __timestampWidth : 6) + (__compact ? 6 : 10) + 10;
    cell.messageOffsetRight.constant = __timeLeftPref ? 6 : (__timestampWidth + 16);
    cell.messageOffsetBottom.constant = __compact ? 0 : 4;

    cell.quoteBorder.hidden = !e.isQuoted;
    cell.quoteBorder.backgroundColor = [UIColor quoteBorderColor];
    if(e.isQuoted) {
        cell.messageOffsetLeft.constant += 8;
        cell.avatarOffset.constant = __compact ? -14 : -18;
        cell.nicknameOffset.constant = -8;
    } else {
        cell.avatarOffset.constant = __compact ? -6 : -10;
        cell.nicknameOffset.constant = 0;
    }
    if(avatarHeight > 0) {
        if(__chatOneLinePref || e.rowType == ROW_ME_MESSAGE)
            cell.avatarOffset.constant = avatarHeight;
        if(!__chatOneLinePref)
            cell.messageOffsetLeft.constant += __largeAvatarHeight + 4;
    }
    if(__avatarsOffPref)
        cell.nicknameOffset.constant -= 6;
    cell.nickname.preferredMaxLayoutWidth = cell.message.preferredMaxLayoutWidth = self.tableView.bounds.size.width - cell.messageOffsetLeft.constant - cell.messageOffsetRight.constant;

    if(e.rowType == ROW_TIMESTAMP || e.rowType == ROW_LASTSEENEID) {
        cell.message.text = @"";
    } else if(!cell.message.text.length || e.rowType == ROW_FAILED) {
        cell.message.attributedText = e.formatted;
        
        if((e.rowType == ROW_MESSAGE || e.rowType == ROW_ME_MESSAGE || e.rowType == ROW_FAILED || e.rowType == ROW_SOCKETCLOSED) && e.groupEid > 0 && (e.groupEid != e.eid || [self->_expandedSectionEids objectForKey:@(e.groupEid)])) {
            if([self->_expandedSectionEids objectForKey:@(e.groupEid)]) {
                if(e.groupEid == e.eid + 1) {
                    cell.accessory.text = FA_MINUS_SQUARE_O;
                    cell.contentView.backgroundColor = [UIColor collapsedHeadingBackgroundColor];
                    cell.accessibilityLabel = [NSString stringWithFormat:@"Expanded status messages heading. at %@", e.timestamp];
                    cell.accessibilityHint = @"Collapses this group";
                } else {
                    cell.accessory.text = FA_ANGLE_RIGHT;
                    cell.contentView.backgroundColor = [UIColor contentBackgroundColor];
                    cell.accessibilityLabel = [NSString stringWithFormat:@"Expanded status message. at %@", e.timestamp];
                    cell.accessibilityHint = @"Collapses this group";
                }
            } else {
                cell.accessory.text = FA_PLUS_SQUARE_O;
                cell.accessibilityLabel = [NSString stringWithFormat:@"Collapsed status messages. at %@", e.timestamp];
                cell.accessibilityHint = @"Expands this group";
            }
            cell.accessory.hidden = NO;
        } else if(e.rowType == ROW_FAILED) {
            cell.accessory.hidden = NO;
            cell.accessory.text = FA_EXCLAMATION_TRIANGLE;
            cell.accessory.textColor = [UIColor networkErrorColor];
        } else {
            cell.accessory.hidden = YES;
        }
        
        if(e.links.count) {
            if(e.pending || [e.color isEqual:[UIColor timestampColor]])
                cell.message.linkAttributes = self->_lightLinkAttributes;
            else
                cell.message.linkAttributes = self->_linkAttributes;
            @try {
                for(NSTextCheckingResult *result in e.links) {
                    if(result.resultType == NSTextCheckingTypeLink) {
                        if(result.URL)
                            [cell.message addLinkWithTextCheckingResult:result];
                    } else {
                        NSString *url = [[e.formatted attributedSubstringFromRange:result.range] string];
                        if(![url hasPrefix:@"irc"]) {
                            CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                            if(url_escaped != NULL) {
                                url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url_escaped];
                                CFRelease(url_escaped);
                            }
                        }
                        NSURL *u = [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]];
                        if(u)
                            [cell.message addLinkToURL:u withRange:result.range];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"An exception occured while setting the links, the table is probably being reloaded: %@", exception);
            }
        }
        if(cell.nickname.text.length && e.realnameLinks.count) {
            cell.nickname.linkAttributes = self->_lightLinkAttributes;
            @try {
                for(NSTextCheckingResult *result in e.realnameLinks) {
                    if(result.resultType == NSTextCheckingTypeLink) {
                        if(result.URL)
                            [cell.nickname addLinkToURL:result.URL withRange:NSMakeRange(result.range.location + e.formattedNick.length + 1, result.range.length)];
                    } else {
                        NSString *url = [[e.formattedRealname attributedSubstringFromRange:result.range] string];
                        if(![url hasPrefix:@"irc"]) {
                            CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                            if(url_escaped != NULL) {
                                url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url_escaped];
                                CFRelease(url_escaped);
                            }
                        }
                        NSURL *u = [NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]];
                        if(u)
                            [cell.nickname addLinkToURL:u withRange:NSMakeRange(result.range.location + e.formattedNick.length + 1, result.range.length)];
                    }
                }
            }
            @catch (NSException *exception) {
                NSLog(@"An exception occured while setting the links, the table is probably being reloaded: %@", exception);
            }
        }
    }
    cell.timestampLeft.hidden = !__timeLeftPref;
    cell.timestampRight.hidden = __timeLeftPref;
    cell.datestamp.hidden = YES;
    UILabel *timestamp = __timeLeftPref ? cell.timestampLeft : cell.timestampRight;
    if(e.rowType == ROW_LASTSEENEID) {
        timestamp.hidden = YES;
        cell.lastSeenEIDBackground.backgroundColor = [UIColor timestampColor];
        cell.lastSeenEIDBackground.hidden = NO;
        cell.lastSeenEID.textColor = [UIColor timestampColor];
        cell.lastSeenEID.superview.backgroundColor = [UIColor contentBackgroundColor];
        cell.lastSeenEID.superview.hidden = NO;
        cell.lastSeenEIDOffset.constant = __avatarsOffPref ? 0 : cell.messageOffsetLeft.constant;
    } else {
        cell.lastSeenEIDBackground.hidden = YES;
        cell.lastSeenEID.superview.hidden = YES;
        timestamp.text = e.timestamp;
        cell.timestampWidth.constant = __timestampWidth - 8;
        cell.lastSeenEIDOffset.constant = 0;
    }
    if(e.rowType == ROW_TIMESTAMP) {
        timestamp.hidden = YES;
        timestamp = cell.datestamp;
        timestamp.hidden = NO;
        timestamp.text = e.timestamp;
        timestamp.font = [ColorFormatter messageFont:__monospacePref];
        timestamp.textColor = [UIColor messageTextColor];
    } else if(e.isHighlight && !e.isSelf) {
        timestamp.textColor = [UIColor highlightTimestampColor];
    } else if(e.rowType == ROW_FAILED || [e.bgColor isEqual:[UIColor errorBackgroundColor]]) {
        timestamp.textColor = [UIColor networkErrorColor];
    } else {
        timestamp.textColor = [UIColor timestampColor];
    }
    if(e.rowType == ROW_BACKLOG) {
        timestamp.hidden = YES;
        cell.lastSeenEIDBackground.backgroundColor = [UIColor backlogDividerColor];
        cell.lastSeenEIDBackground.hidden = NO;
        cell.accessibilityElementsHidden = YES;
    } else if(e.rowType == ROW_LASTSEENEID) {
        timestamp.backgroundColor = [UIColor contentBackgroundColor];
    } else {
        timestamp.backgroundColor = [UIColor clearColor];
    }
    if(e.rowType == ROW_TIMESTAMP) {
        cell.topBorder.backgroundColor = [UIColor timestampTopBorderColor];
        cell.topBorder.hidden = NO;
        
        cell.bottomBorder.backgroundColor = [UIColor timestampBottomBorderColor];
        cell.bottomBorder.hidden = NO;
        cell.messageOffsetBottom.constant = 4;
    } else {
        cell.topBorder.hidden = cell.bottomBorder.hidden = YES;
    }
    cell.codeBlockBackground.backgroundColor = [UIColor codeSpanBackgroundColor];
    cell.codeBlockBackground.hidden = !e.isCodeBlock;
    if(e.isCodeBlock) {
        cell.messageOffsetTop.constant += 6;
        cell.messageOffsetLeft.constant += 6;
        cell.messageOffsetBottom.constant += 6;
        cell.messageOffsetRight.constant += 6;
    }

    if(e.rowType == ROW_SOCKETCLOSED) {
        cell.socketClosedBar.backgroundColor = [UIColor socketClosedBackgroundColor];
        cell.socketClosedBar.hidden = NO;
        if(!e.msg.length && !e.groupMsg.length) {
            cell.message.text = nil;
            cell.timestampLeft.text = nil;
            cell.timestampRight.text = nil;
        }
        cell.messageOffsetBottom.constant = FONT_SIZE;
    } else {
        cell.socketClosedBar.hidden = YES;
    }
    
    if(!__replyCollapsePref) {
        if(e.isReply || e.replyCount) {
            cell.reply.font = [ColorFormatter replyThreadFont];
            cell.reply.textColor = [UIColor colorFromHexString:[UIColor colorForNick:e.isReply ? e.reply : e.msgid]];
            cell.reply.text = e.isReply ? FA_COMMENTS : FA_COMMENT;
            cell.reply.hidden = NO;
            cell.replyButton.hidden = NO;
            cell.replyButton.userInteractionEnabled = YES;
            cell.reply.alpha = 0.4;
            cell.replyCenter.priority = (e.isHeader && !__avatarsOffPref && !__chatOneLinePref) ? 999 : 1;
        } else {
            cell.reply.hidden = YES;
            cell.replyButton.hidden = YES;
            cell.replyButton.userInteractionEnabled = NO;
        }
    } else if(e.rowType != ROW_REPLY_COUNT) {
        cell.reply.hidden = YES;
        cell.replyButton.hidden = YES;
        cell.replyButton.userInteractionEnabled = NO;
    }

    if(cell.replyButton && !cell.replyButton.hidden) {
        [cell.replyButton addTarget:self action:@selector(_replyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        cell.replyButton.tag = indexPath.row;
    } else {
        [cell.replyButton removeTarget:self action:@selector(_replyButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if(e.rowType == ROW_FILE) {
        cell.message.textColor = [UIColor messageTextColor];
        cell.message.font = [UIFont systemFontOfSize:FONT_SIZE];
        cell.messageOffsetTop.constant += FONT_SIZE + 4;
        cell.messageOffsetBottom.constant += FONT_SIZE + 8;
        cell.messageOffsetLeft.constant += 60;
        cell.messageOffsetRight.constant += 4;
    }

    if(e.rowType == ROW_THUMBNAIL) {
        if([e.entities objectForKey:@"id"]) {
            cell.message.text = [NSString stringWithFormat:@"%@ • %@", [e.entities objectForKey:@"mime_type"], e.msg];
            cell.message.numberOfLines = 1;
            cell.message.lineBreakMode = NSLineBreakByTruncatingTail;
            cell.message.textColor = [UIColor messageTextColor];
            cell.message.font = [UIFont systemFontOfSize:FONT_SIZE];
        }
        cell.messageOffsetLeft.constant += 4;
        cell.messageOffsetRight.constant += 4;
    }

    return cell;
}

- (void)LinkLabel:(LinkLabel *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [_urlHandler launchURL:result.URL];
}

-(IBAction)dismissButtonPressed:(id)sender {
    if(self->_topUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        self->_topUnreadView.alpha = 0;
        [UIView commitAnimations];
        [self sendHeartbeat];
    }
}

-(IBAction)topUnreadBarClicked:(id)sender {
    if(self->_topUnreadView.alpha) {
        if(!_buffer.scrolledUp) {
            self->_buffer.scrolledUpFrom = [[self->_data lastObject] eid];
            self->_buffer.scrolledUp = YES;
        }
        if(self->_lastSeenEidPos > 0) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.1];
            self->_topUnreadView.alpha = 0;
            [UIView commitAnimations];
            [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_lastSeenEidPos+1 inSection:0] atScrollPosition: UITableViewScrollPositionTop animated: YES];
            [self scrollViewDidScroll:self->_tableView];
            [self sendHeartbeat];
        } else {
            if(self->_tableView.tableHeaderView == self->_backlogFailedView)
                [self loadMoreBacklogButtonPressed:nil];
            [self->_tableView setContentOffset:CGPointMake(0,0) animated:YES];
        }
    }
}

-(IBAction)bottomUnreadBarClicked:(id)sender {
    if(self->_bottomUnreadView.alpha) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.1];
        self->_bottomUnreadView.alpha = 0;
        [UIView commitAnimations];
        if(self->_data.count) {
            [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_data.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        self->_buffer.scrolledUp = NO;
        self->_buffer.scrolledUpFrom = -1;
    }
}

#pragma mark - Table view delegate

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self->_delegate dismissKeyboard];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(!_ready || !_buffer || _requestingBacklog || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        self->_stickyAvatar.hidden = YES;
        if(self->_data.count && _hiddenAvatarRow != -1) {
            Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
            EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
            cell.avatar.hidden = !e.isHeader;
            self->_hiddenAvatarRow = -1;
        }
        return;
    }
    
    if(self->_previewingRow) {
        EventsTableCell *cell = [self->_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self->_previewingRow inSection:0]];
        __previewer.sourceRect = cell.frame;
    }
    
    UITableView *tableView = self->_tableView;
    NSInteger firstRow = -1;
    NSInteger lastRow = -1;
    if(@available(iOS 13, *)) {
        //visibleCells resets the scroll position on iOS 13
    } else {
        [tableView visibleCells];
    }
    NSArray *rows = [tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(tableView.bounds, tableView.contentInset)];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
        lastRow = [[rows lastObject] row];
    } else {
        self->_stickyAvatar.hidden = YES;
        if(self->_hiddenAvatarRow != -1) {
            Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
            EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
            cell.avatar.hidden = !e.isHeader;
            self->_hiddenAvatarRow = -1;
        }
    }
    
    if(tableView.tableHeaderView == self->_headerView && _minEid > 0 && _buffer && _buffer.bid != -1 && (self->_buffer.scrolledUp || !_data.count || (self->_data.count && firstRow == 0 && lastRow == self->_data.count - 1))) {
        if(self->_conn.state == kIRCCloudStateConnected && scrollView.contentOffset.y < _headerView.frame.size.height && _conn.ready) {
            CLS_LOG(@"The table scrolled and the loading header became visible, requesting more backlog");
            self->_requestingBacklog = YES;
            [self->_conn cancelPendingBacklogRequests];
            [self->_conn requestBacklogForBuffer:self->_buffer.bid server:self->_buffer.cid beforeId:self->_earliestEid completion:nil];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Downloading more chat history");
            self->_stickyAvatar.hidden = YES;
            if(self->_hiddenAvatarRow != -1) {
                Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
                EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
                cell.avatar.hidden = !e.isHeader;
                self->_hiddenAvatarRow = -1;
            }
            return;
        }
    }
    
    if(rows.count && _topUnreadView) {
        if(self->_data.count) {
            if(lastRow < _data.count)
                self->_buffer.savedScrollOffset = floorf(tableView.contentOffset.y - tableView.tableHeaderView.bounds.size.height);
            
            CGRect frame = [tableView convertRect:[tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:self->_data.count - 1 inSection:0]] toView:tableView.superview];
            
            if(frame.origin.y + frame.size.height <= tableView.frame.origin.y + tableView.frame.size.height - tableView.contentInset.bottom + 4 + (FONT_SIZE / 2)) {
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.1];
                self->_bottomUnreadView.alpha = 0;
                [UIView commitAnimations];
                self->_newMsgs = 0;
                self->_newHighlights = 0;
                self->_buffer.scrolledUp = NO;
                self->_buffer.scrolledUpFrom = -1;
                self->_buffer.savedScrollOffset = -1;
                [self sendHeartbeat];
            } else if (!_buffer.scrolledUp && lastRow < (_data.count - 1)) {
                self->_buffer.scrolledUpFrom = [[self->_data objectAtIndex:lastRow] eid];
                self->_buffer.scrolledUp = YES;
                [self->_scrollTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
                self->_scrollTimer = nil;
            }
            
            if(self->_lastSeenEidPos >= 0) {
                if(self->_lastSeenEidPos > 0 && firstRow < _lastSeenEidPos + 1) {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:0.1];
                    self->_topUnreadView.alpha = 0;
                    [UIView commitAnimations];
                    [self sendHeartbeat];
                } else {
                    [self updateTopUnread:firstRow];
                }
            }
            
            if(tableView.tableHeaderView != self->_headerView && _earliestEid > _buffer.min_eid && _buffer.min_eid > 0 && firstRow > 0 && lastRow < _data.count && _conn.state == kIRCCloudStateConnected && !(self->_msgid && [self->_msgids objectForKey:self->_msgid]))
                tableView.tableHeaderView = self->_headerView;
        }
    }
    
    if(rows.count && !__chatOneLinePref && !__avatarsOffPref && scrollView.contentOffset.y > _headerView.frame.size.height) {
        int offset = ((self->_topUnreadView.alpha == 0)?0:self->_topUnreadView.bounds.size.height);
        NSUInteger i = firstRow;
        CGRect rect;
        NSIndexPath *topIndexPath;
        do {
            topIndexPath = [NSIndexPath indexPathForRow:i++ inSection:0];
            rect = [self->_tableView convertRect:[self->_tableView rectForRowAtIndexPath:topIndexPath] toView:self->_tableView.superview];
        } while(i < _data.count && rect.origin.y + rect.size.height <= offset - 1);
        Event *e = [self->_data objectAtIndex:firstRow];
        if((e.groupEid < 1 && e.from.length && [e isMessage]) || e.rowType == ROW_LASTSEENEID) {
            float groupHeight = rect.size.height;
            for(i = firstRow; i < _data.count - 1 && i < firstRow + 4; i++) {
                e = [self->_data objectAtIndex:i];
                if(e.rowType == ROW_LASTSEENEID)
                    e = [self->_data objectAtIndex:i-1];
                NSUInteger next = i+1;
                Event *e1 = [self->_data objectAtIndex:next];
                if(e1.rowType == ROW_LASTSEENEID) {
                    next++;
                    e1 = [self->_data objectAtIndex:next];
                }
                if([e.from isEqualToString:e1.from] && e1.groupEid < 1 && !e1.isHeader) {
                    rect = [self->_tableView convertRect:[self->_tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:next inSection:0]] toView:self->_tableView.superview];
                    groupHeight += rect.size.height;
                } else {
                    break;
                }
            }
            if(e.from.length && !(((Event *)[self->_data objectAtIndex:firstRow]).rowType == ROW_LASTSEENEID && groupHeight == 26) && (!e.isHeader || groupHeight > __largeAvatarHeight + 14)) {
                self->_stickyAvatarYOffsetConstraint.constant = rect.origin.y + rect.size.height - (__largeAvatarHeight + 4);
                if(self->_stickyAvatarYOffsetConstraint.constant >= offset + 4)
                    self->_stickyAvatarYOffsetConstraint.constant = offset + 4;
                self->_stickyAvatarWidthConstraint.constant = self->_stickyAvatarHeightConstraint.constant = __largeAvatarHeight;
                if(self->_hiddenAvatarRow != topIndexPath.row) {
                    self->_stickyAvatar.image = nil;
                    if(__avatarImages) {
                        NSURL *avatarURL = [e avatar:__largeAvatarHeight * [UIScreen mainScreen].scale];
                        if(avatarURL) {
                            UIImage *image = [[ImageCache sharedInstance] imageForURL:avatarURL];
                            if(image) {
                                self->_stickyAvatar.image = image;
                                self->_stickyAvatar.layer.cornerRadius = 5.0;
                                self->_stickyAvatar.layer.masksToBounds = YES;
                            } else {
                                [[ImageCache sharedInstance] fetchURL:avatarURL completionHandler:^(BOOL success) {
                                    if(success)
                                        [self scrollViewDidScroll:self.tableView];
                                }];
                            }
                        }
                    }
                    if(!_stickyAvatar.image) {
                        self->_stickyAvatar.image = [[[AvatarsDataSource sharedInstance] getAvatar:e.from nick:e.fromNick bid:e.bid] getImage:__largeAvatarHeight isSelf:e.isSelf];
                        self->_stickyAvatar.layer.cornerRadius = 0;
                    }
                    self->_stickyAvatar.hidden = NO;
                    if(self->_hiddenAvatarRow != -1 && _hiddenAvatarRow < _data.count) {
                        Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
                        EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
                        cell.avatar.hidden = !e.isHeader;
                    }
                    if(topIndexPath.row < self->_data.count) {
                        EventsTableCell *cell = [self->_rowCache objectForKey:[[self->_data objectAtIndex: topIndexPath.row] UUID]];
                        cell.avatar.hidden = YES;
                        self->_hiddenAvatarRow = topIndexPath.row;
                    }
                }
            } else {
                self->_stickyAvatar.hidden = YES;
                if(self->_hiddenAvatarRow != -1) {
                    if(self->_hiddenAvatarRow < self->_data.count) {
                        Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
                        EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
                        cell.avatar.hidden = !e.isHeader;
                    }
                    self->_hiddenAvatarRow = -1;
                }
            }
        } else {
            self->_stickyAvatar.hidden = YES;
            if(self->_hiddenAvatarRow != -1) {
                if(self->_hiddenAvatarRow < self->_data.count) {
                    Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
                    EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
                    cell.avatar.hidden = !e.isHeader;
                }
                self->_hiddenAvatarRow = -1;
            }
        }
    } else {
        self->_stickyAvatar.hidden = YES;
        if(self->_hiddenAvatarRow != -1) {
            if(self->_hiddenAvatarRow < self->_data.count) {
                Event *e = [self->_data objectAtIndex:self->_hiddenAvatarRow];
                EventsTableCell *cell = [self->_rowCache objectForKey:[e UUID]];
                cell.avatar.hidden = !e.isHeader;
            }
            self->_hiddenAvatarRow = -1;
        }
    }
#ifdef DEBUG
    if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
        self->_tableView.tableHeaderView = nil;
    }
#endif
}

-(void)_replyButtonPressed:(UIControl *)sender {
    [self->_lock lock];
    Event *e = [self->_data objectAtIndex:sender.tag];
    [self->_lock unlock];

    if(self->_msgid) {
        self->_eidToOpen = e.eid;
        [(MainViewController *)_delegate setMsgId:nil];
    } else if(e.reply) {
        [(MainViewController *)_delegate setMsgId:e.reply];
    } else {
        [(MainViewController *)_delegate setMsgId:e.msgid];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if(indexPath.row < _data.count) {
        NSTimeInterval group = ((Event *)[self->_data objectAtIndex:indexPath.row]).groupEid;
        if(group > 0) {
            int count = 0;
            for(Event *e in _data) {
                if(e.groupEid == group)
                    count++;
            }
            if(count > 1 || [((Event *)[self->_data objectAtIndex:indexPath.row]).groupMsg hasPrefix:self->_groupIndent]) {
                if([self->_expandedSectionEids objectForKey:@(group)])
                    [self->_expandedSectionEids removeObjectForKey:@(group)];
                else if(((Event *)[self->_data objectAtIndex:indexPath.row]).eid != group)
                    [self->_expandedSectionEids setObject:@(YES) forKey:@(group)];
                for(Event *e in _data) {
                    e.timestamp = nil;
                    e.formatted = nil;
                }
                if(!_buffer.scrolledUp) {
                    self->_buffer.scrolledUpFrom = [[self->_data lastObject] eid];
                    self->_buffer.scrolledUp = YES;
                }
                self->_buffer.savedScrollOffset = floorf(self->_tableView.contentOffset.y - _tableView.tableHeaderView.bounds.size.height);
                [self refresh];
            }
        } else if(indexPath.row < _data.count) {
            Event *e = [self->_data objectAtIndex:indexPath.row];
            if([e.type isEqualToString:@"channel_invite"])
                [self->_delegate showJoinPrompt:e.oldNick server:[[ServersDataSource sharedInstance] getServer:e.cid]];
            else if([e.type isEqualToString:@"callerid"])
                [self->_conn say:[NSString stringWithFormat:@"/accept %@", e.nick] to:nil cid:e.cid handler:nil];
            else if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE) {
                if([e.entities objectForKey:@"id"]) {
                    NSString *extension = [e.entities objectForKey:@"extension"];
                    if(!extension.length)
                        extension = [@"." stringByAppendingString:[[e.entities objectForKey:@"mime_type"] substringFromIndex:[[e.entities objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1]];
                    if([[[e.entities objectForKey:@"name"] lowercaseString] hasSuffix:extension.lowercaseString]) {
                        [_urlHandler launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":[e.entities objectForKey:@"id"]} error:nil], [[e.entities objectForKey:@"name"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]]];
                    } else {
                        [_urlHandler launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@%@", [[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":[e.entities objectForKey:@"id"]} error:nil], [e.entities objectForKey:@"id"], extension]]];
                    }
                } else {
                    [_urlHandler launchURL:[e.entities objectForKey:@"url"]];
                }
            } else
                [self->_delegate rowSelected:e];
        }
    }
}

-(void)clearLastSeenMarker {
    [self->_lock lock];
    for(Event *event in [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid]) {
        if(event.rowType == ROW_LASTSEENEID) {
            [[EventsDataSource sharedInstance] removeEvent:event.eid buffer:event.bid];
            break;
        }
    }
    for(Event *event in _data) {
        if(event.rowType == ROW_LASTSEENEID) {
            [self->_data removeObject:event];
            break;
        }
    }
    [self->_lock unlock];
    [self _reloadData];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self->_tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self->_tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                Event *e = [self->_data objectAtIndex:indexPath.row];
                EventsTableCell *c = (EventsTableCell *)[self->_tableView cellForRowAtIndexPath:indexPath];
                NSURL *url;
                if(e.rowType == ROW_THUMBNAIL || e.rowType == ROW_FILE)
                    url = [e.entities objectForKey:@"id"]?[NSURL URLWithString:[e.entities objectForKey:@"url"]]:[e.entities objectForKey:@"url"];
                else
                    url = [c.message linkAtPoint:[gestureRecognizer locationInView:c.message]].URL;
                if(url) {
                    if([url.scheme hasPrefix:@"irc"] && [url.host intValue] > 0 && url.path && url.path.length > 1) {
                        Server *s = [[ServersDataSource sharedInstance] getServer:[url.host intValue]];
                        if(s != nil) {
                            if(s.ssl > 0)
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"ircs://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                            else
                                url = [NSURL URLWithString:[NSString stringWithFormat:@"irc://%@%@", s.hostname, [url.path stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                        }
                    } else if([url.scheme hasPrefix:@"irccloud-paste-"]) {
                        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", [url.scheme substringFromIndex:15], url.host, url.path]];
                    }
                }
                [self->_delegate rowLongPressed:[self->_data objectAtIndex:indexPath.row] rect:[self->_tableView rectForRowAtIndexPath:indexPath] link:url.absoluteString];
            }
        }
    }
}

-(NSString *)YUNoHeartbeat {
    if(!_ready)
        return @"Events table view not ready";
    if(!_buffer)
        return @"No buffer";
    if(self->_requestingBacklog)
        return @"Currently requesting backlog";
    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
        return @"Application state not active";
    if(!_topUnreadView)
        return @"Can't find top chatter bar";
    if(self->_topUnreadView.alpha != 0)
        return @"Top chatter bar is visible";
    if(self->_bottomUnreadView.alpha != 0)
        return @"Bottom chatter bar is visible";
    if([NetworkConnection sharedInstance].notifier)
        return @"Connected as a notifier socket";
    if(![self.slidingViewController topViewHasFocus])
        return @"A drawer is open";
    if(self->_conn.state != kIRCCloudStateConnected)
        return @"Websocket not in Connected state";
    if(self->_lastSeenEidPos == 0)
        return @"New Messages marker is above the loaded backlog";
    UITableView *tableView = self->_tableView;
    NSInteger firstRow = -1;
    NSArray *rows = [tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(tableView.bounds, tableView.contentInset)];
    if(rows.count) {
        firstRow = [[rows objectAtIndex:0] row];
    } else {
        return @"Empty table view";
    }
    if(self->_lastSeenEidPos > 0 && firstRow >= self->_lastSeenEidPos)
        return @"New Messages marker is above the current visible range";
    NSArray *events = [[EventsDataSource sharedInstance] eventsForBuffer:self->_buffer.bid];
    NSTimeInterval eid = self->_buffer.scrolledUpFrom;
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
    if(eid < 0 || eid < _buffer.last_seen_eid)
        return @"eid <= last_seen_eid";
    if(floorf(tableView.contentOffset.y) >= floorf(tableView.contentSize.height - (tableView.bounds.size.height - tableView.contentInset.top - tableView.contentInset.bottom)))
        return @"This channel should be marked as read";
    else
        return @"Table view is not scrolled to the bottom";
}

-(CGRect)rectForEvent:(Event *)event {
    int i = 0;
    for(Event *e in _data) {
        if(event == e)
            break;
        i++;
    }
    if(i < _data.count) {
        return [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
    } else {
        return CGRectZero;
    }
}
@end

