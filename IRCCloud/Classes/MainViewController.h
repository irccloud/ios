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
#import <MessageUI/MFMailComposeViewController.h>
#import "BuffersTableView.h"
#import "UsersTableView.h"
#import "EventsTableView.h"
#import "UIExpandingTextView.h"
#import "NickCompletionView.h"
#import "ImageUploader.h"
#import "FileUploader.h"
#import "FilesTableViewController.h"
#import "LinkLabel.h"
#import "IRCColorPickerView.h"

@interface UpdateSuggestionsTask : NSObject {
    BOOL _force, _atMention;
    BOOL _cancelled;
    UIExpandingTextView *_message;
    Buffer *_buffer;
    NickCompletionView *_nickCompletionView;
    NSString *_text;
}

@property UIExpandingTextView *message;
@property Buffer *buffer;
@property NickCompletionView *nickCompletionView;
@property BOOL force, atMention, cancelled, isEmoji;

-(void)cancel;
-(void)run;

@end

@interface MainViewController : UIViewController<FilesTableViewDelegate,NickCompletionViewDelegate,BuffersTableViewDelegate,UIExpandingTextViewDelegate,EventsTableViewDelegate,UsersTableViewDelegate,UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationBarDelegate,ImageUploaderDelegate,FileUploaderDelegate,UIDocumentPickerDelegate,NSUserActivityDelegate,UIPopoverPresentationControllerDelegate,UIViewControllerPreviewingDelegate,UIGestureRecognizerDelegate,MFMailComposeViewControllerDelegate,LinkLabelDelegate,IRCColorPickerViewDelegate,UIDropInteractionDelegate
> {
    IBOutlet EventsTableView *_eventsView;
    IBOutlet UIView *_connectingView;
    IBOutlet UILabel *_connectingStatus;
    IBOutlet UIView *_bottomBar;
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
    IBOutlet LinkLabel *_globalMsg;
    IBOutlet UIButton *_loadMoreBacklog;
    IBOutlet NSLayoutConstraint *_eventsViewWidthConstraint;
    IBOutlet NSLayoutConstraint *_eventsViewOffsetXConstraint;
    IBOutlet NSLayoutConstraint *_bottomBarOffsetConstraint;
    IBOutlet NSLayoutConstraint *_bottomBarHeightConstraint;
    IBOutlet NSLayoutConstraint *_titleOffsetXConstraint;
    IBOutlet NSLayoutConstraint *_titleOffsetYConstraint;
    IBOutlet NSLayoutConstraint *_topicWidthConstraint;
    IBOutlet NSLayoutConstraint *_topUnreadBarYOffsetConstraint;
    IBOutlet NSLayoutConstraint *_bottomUnreadBarYOffsetConstraint;
    UIProgressView *_connectingProgress;
    NSLayoutConstraint *_messageHeightConstraint;
    NSLayoutConstraint *_messageWidthConstraint;
    BuffersTableView *_buffersView;
    UsersTableView *_usersView;
    UIExpandingTextView *_message;
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
    IRCCloudJSONObject *_alertObject;
    SystemSoundID alertSound;
    CGSize _kbSize;
    NickCompletionView *_nickCompletionView;
    NSTimer *_nickCompletionTimer;
    NSTimeInterval _lastNotificationTime;
    BOOL _isShowingPreview;
    NSString *_currentTheme;
    UpdateSuggestionsTask *_updateSuggestionsTask;
    IRCColorPickerView *_colorPickerView;
    NSDictionary *_currentMessageAttributes;
    BOOL _textIsChanging;
    UIFont *_defaultTextareaFont;
    id<UIViewControllerPreviewing> __previewer;
    BOOL _ignoreVisibilityChanges;
    BOOL _ignoreInsetChanges;
    NSString *_msgid;
    UIView *_leftBorder, *_rightBorder;
}
@property (nonatomic) int cidToOpen;
@property (nonatomic) int bidToOpen;
@property (nonatomic) NSTimeInterval eidToOpen;
@property (nonatomic) NSString *incomingDraft;
@property (nonatomic) NSString *bufferToOpen;
@property (readonly) EventsTableView *eventsView;
@property (readonly) Buffer *buffer;
@property BOOL isShowingPreview;
@property BOOL ignoreVisibilityChanges;
-(void)bufferSelected:(int)bid;
-(void)sendButtonPressed:(id)sender;
-(void)usersButtonPressed:(id)sender;
-(void)listButtonPressed:(id)sender;
-(IBAction)serverStatusBarPressed:(id)sender;
-(IBAction)titleAreaPressed:(id)sender;
-(IBAction)globalMsgPressed:(id)sender;
-(void)launchURL:(NSURL *)url;
-(void)refresh;
-(void)_setSelectedBuffer:(Buffer *)b;
-(void)setMsgId:(NSString *)msgId;
-(void)applyTheme;
-(void)clearText;
-(void)clearMsgId;
@end
