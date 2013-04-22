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

@interface MainViewController : UIViewController<BuffersTableViewDelegate,UIExpandingTextViewDelegate,UIActionSheetDelegate,UIAlertViewDelegate,UIScrollViewDelegate,EventsTableViewDelegate,UsersTableViewDelegate> {
    IBOutlet BuffersTableView *_buffersView;
    IBOutlet UsersTableView *_usersView;
    IBOutlet EventsTableView *_eventsView;
    IBOutlet UIView *_contentView;
    UIExpandingTextView *_message;
    IBOutlet UIView *_connectingView;
    IBOutlet UIProgressView *_connectingProgress;
    IBOutlet UILabel *_connectingStatus;
    IBOutlet UIActivityIndicatorView *_connectingActivity;
    IBOutlet UIToolbar *_toolBar;
    UIBarButtonItem *_usersButtonItem;
    Buffer *_buffer;
    int _startX;
    int _startHeight;
    User *_selectedUser;
    Event *_selectedEvent;
    int _cidToOpen;
    NSString *_bufferToOpen;
    UIView *_barButtonContainer;
}
-(IBAction)sendButtonPressed:(id)sender;
-(IBAction)usersButtonPressed:(id)sender;
-(IBAction)listButtonPressed:(id)sender;
@end
