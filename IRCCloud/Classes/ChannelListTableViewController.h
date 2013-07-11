//
//  ChannelListTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/18/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface ChannelListTableViewController : UITableViewController<UIAlertViewDelegate,UITextFieldDelegate> {
    NSArray *_channels;
    NSArray *_data;
    IRCCloudJSONObject *_event;
    UITextView *_placeholder;
    UIActivityIndicatorView *_activity;
    UIAlertView *_alertView;
}
@property (strong, nonatomic) NSArray *channels;
@property (strong, nonatomic) IRCCloudJSONObject *event;
-(void)refresh;
@end
