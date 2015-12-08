//
//  BuffersTableView.h
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
#import "ServersDataSource.h"
#import "BuffersDataSource.h"

@protocol BuffersTableViewDelegate<NSObject>
-(void)bufferSelected:(int)bid;
-(void)bufferLongPressed:(int)bid rect:(CGRect)rect;
-(void)dismissKeyboard;
@end

@interface BuffersTableView : UITableViewController<UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate,UIViewControllerPreviewingDelegate> {
    NSMutableArray *_data;
    NSInteger _selectedRow;
    IBOutlet UIViewController<BuffersTableViewDelegate> *_delegate;
    NSMutableDictionary *_expandedArchives;
    Buffer *_selectedBuffer;
    
    IBOutlet UIControl *topUnreadIndicator;
    IBOutlet UIView *topUnreadIndicatorColor;
    IBOutlet UIView *topUnreadIndicatorBorder;
    IBOutlet UIControl *bottomUnreadIndicator;
    IBOutlet UIView *bottomUnreadIndicatorColor;
    IBOutlet UIView *bottomUnreadIndicatorBorder;

    NSInteger _firstUnreadPosition;
	NSInteger _lastUnreadPosition;
	NSInteger _firstHighlightPosition;
	NSInteger _lastHighlightPosition;
    NSInteger _firstFailurePosition;
    NSInteger _lastFailurePosition;
    
    UIAlertView *_alertView;
    ServersDataSource *_servers;
    BuffersDataSource *_buffers;
    
    UIFont *_boldFont;
    UIFont *_normalFont;
    UIFont *_awesomeFont;
    id<UIViewControllerPreviewing> __previewer;
    UILongPressGestureRecognizer *lp;
}
@property UIViewController<BuffersTableViewDelegate> *delegate;
-(void)setBuffer:(Buffer *)buffer;
-(IBAction)topUnreadIndicatorClicked:(id)sender;
-(IBAction)bottomUnreadIndicatorClicked:(id)sender;
-(void)refresh;
@end
