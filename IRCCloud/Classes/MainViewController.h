//
//  MainViewController.h
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


#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "BuffersTableView.h"
#import "UsersTableView.h"
#import "EventsTableView.h"
#import "UIExpandingTextView.h"
#import "NickCompletionView.h"
#import "ImageUploader.h"
#import "FileUploader.h"
#import "FilesTableViewController.h"
#import "YTPlayerView.h"

@interface MainViewController : UIViewController<FilesTableViewDelegate,NickCompletionViewDelegate,BuffersTableViewDelegate,UIExpandingTextViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,EventsTableViewDelegate,UsersTableViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationBarDelegate,ImageUploaderDelegate,UIPopoverControllerDelegate,FileUploaderDelegate,UIDocumentPickerDelegate,NSUserActivityDelegate,YTPlayerViewDelegate,UIPopoverPresentationControllerDelegate,UIViewControllerPreviewingDelegate,UIGestureRecognizerDelegate> {
    IBOutlet BuffersTableView *_buffersView;
    IBOutlet UsersTableView *_usersView;
    IBOutlet EventsTableView *_eventsView;
    UIExpandingTextView *_message;
    IBOutlet UIView *_connectingView;
    IBOutlet UIProgressView *_connectingProgress;
    IBOutlet UILabel *_connectingStatus;
    IBOutlet UIActivityIndicatorView *_connectingActivity;
    IBOutlet UIImageView *_bottomBar;
    IBOutlet UILabel *_serverStatus;
    IBOutlet UIView *_serverStatusBar;
    IBOutlet UIActivityIndicatorView *_eventActivity;
    IBOutlet UIActivityIndicatorView *_headerActivity;
    IBOutlet UIView *_titleView;
    IBOutlet UILabel *_titleLabel;
    IBOutlet UILabel *_topicLabel;
    IBOutlet UILabel *_lock;
    IBOutlet UIView *_borders;
    IBOutlet UIView *_swipeTip;
    IBOutlet UIView *_2swipeTip;
    IBOutlet UIView *_mentionTip;
    IBOutlet UIView *_globalMsgContainer;
    IBOutlet TTTAttributedLabel *_globalMsg;
    IBOutlet UILabel *_fetchingFailed;
    IBOutlet UIButton *_loadMoreBacklog;
    UIButton *_menuBtn, *_sendBtn, *_settingsBtn, *_uploadsBtn;
    UIBarButtonItem *_usersButtonItem;
    Buffer *_buffer;
    User *_selectedUser;
    Event *_selectedEvent;
    CGRect _selectedRect;
    Buffer *_selectedBuffer;
    NSString *_selectedURL;
    int _cidToOpen;
    NSString *_bufferToOpen;
    NSURL *_urlToOpen;
    NSString *_incomingDraft;
    NSTimer *_doubleTapTimer;
    NSMutableArray *_pendingEvents;
    int _bidToOpen;
    NSTimeInterval _eidToOpen;
    UIAlertView *_alertView;
    IRCCloudJSONObject *_alertObject;
    SystemSoundID alertSound;
    UIView *_landscapeView;
    CGSize _kbSize;
    NickCompletionView *_nickCompletionView;
    NSTimer *_nickCompletionTimer;
    NSArray *_sortedUsers;
    NSArray *_sortedChannels;
    UIPopoverController *_popover;
    NSTimeInterval _lastNotificationTime;
    UIView *_YTWrapperView;
    YTPlayerView *_ytPlayer;
    NSURL *_ytURL;
    UIActivityIndicatorView *_ytActivity;
    BOOL __ignoreLayoutChanges;
    NSString *__currentTheme;
    
    id<UIViewControllerPreviewing> __previewer;
}
@property (nonatomic) int bidToOpen;
@property (nonatomic) NSTimeInterval eidToOpen;
@property (nonatomic) NSString *incomingDraft;
@property (readonly) EventsTableView *eventsView;
-(void)bufferSelected:(int)bid;
-(void)sendButtonPressed:(id)sender;
-(void)usersButtonPressed:(id)sender;
-(void)listButtonPressed:(id)sender;
-(IBAction)serverStatusBarPressed:(id)sender;
-(IBAction)titleAreaPressed:(id)sender;
-(IBAction)globalMsgPressed:(id)sender;
-(void)launchURL:(NSURL *)url;
-(void)refresh;
@end
