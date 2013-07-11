//
//  BuffersTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"

@protocol BuffersTableViewDelegate<NSObject>
-(void)bufferSelected:(int)bid;
-(void)setUnreadColor:(UIColor *)color;
-(void)dismissKeyboard;
@end

@interface BuffersTableView : UITableViewController<UITextFieldDelegate, UIAlertViewDelegate> {
    NSArray *_data;
    int _selectedRow;
    IBOutlet UIViewController<BuffersTableViewDelegate> *_delegate;
    NSMutableDictionary *_expandedArchives;
    Buffer *_selectedBuffer;
    
    IBOutlet UIControl *topUnreadIndicator;
    IBOutlet UIView *topUnreadIndicatorColor;
    IBOutlet UIControl *bottomUnreadIndicator;
    IBOutlet UIView *bottomUnreadIndicatorColor;

    int _firstUnreadPosition;
	int _lastUnreadPosition;
	int _firstHighlightPosition;
	int _lastHighlightPosition;
    
    UIAlertView *_alertView;
}
-(void)setBuffer:(Buffer *)buffer;
-(IBAction)topUnreadIndicatorClicked:(id)sender;
-(IBAction)bottomUnreadIndicatorClicked:(id)sender;
@end
