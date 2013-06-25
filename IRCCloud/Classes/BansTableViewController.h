//
//  BansTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 4/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface BansTableViewController : UITableViewController<UIAlertViewDelegate> {
    NSArray *_bans;
    IRCCloudJSONObject *_event;
    UIBarButtonItem *_addButton;
    int _bid;
    UITextView *_placeholder;
}
@property (strong, nonatomic) NSArray *bans;
@property (strong, nonatomic) IRCCloudJSONObject *event;
@property int bid;
@end
