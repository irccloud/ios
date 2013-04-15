//
//  IgnoresTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 4/15/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface IgnoresTableViewController : UITableViewController<UIAlertViewDelegate> {
    NSArray *_ignores;
    UIBarButtonItem *_addButton;
    int _cid;
}
@property (strong, nonatomic) NSArray *ignores;
@property int cid;
@end
