//
//  CallerIDTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/20/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface CallerIDTableViewController : UITableViewController<UIAlertViewDelegate> {
    NSArray *_nicks;
    IRCCloudJSONObject *_event;
    UIBarButtonItem *_addButton;
}
@property (strong, nonatomic) NSArray *nicks;
@property (strong, nonatomic) IRCCloudJSONObject *event;
@end
