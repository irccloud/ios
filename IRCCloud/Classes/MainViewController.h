//
//  MainViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersTableView.h"
#import "UsersTableView.h"
#import "EventsTableView.h"
#import "UIExpandingTextView.h"

@interface MainViewController : UIViewController<BuffersTableViewDelegate,UIExpandingTextViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,EventsTableViewDelegate,UsersTableViewDelegate> {
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
    IBOutlet UIView *_titleView;
    IBOutlet UILabel *_titleLabel;
    IBOutlet UILabel *_topicLabel;
    IBOutlet UIImageView *_lock;
    UIButton *_menuBtn;
    UIBarButtonItem *_usersButtonItem;
    Buffer *_buffer;
    int _startHeight;
    User *_selectedUser;
    Event *_selectedEvent;
    CGRect _selectedRect;
    int _cidToOpen;
    NSString *_bufferToOpen;
    NSTimer *_doubleTapTimer;
    NSMutableArray *_pendingEvents;
    int _bidToOpen;
    IRCCloudJSONObject *_alertObject;
}
@property (nonatomic) int bidToOpen;
-(void)bufferSelected:(int)bid;
-(void)sendButtonPressed:(id)sender;
-(void)usersButtonPressed:(id)sender;
-(void)listButtonPressed:(id)sender;
-(IBAction)serverStatusBarPressed:(id)sender;
-(IBAction)titleAreaPressed:(id)sender;
@end
