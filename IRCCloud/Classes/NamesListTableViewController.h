//
//  NamesListTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 7/7/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface NamesListTableViewController : UITableViewController<UIAlertViewDelegate> {
    IRCCloudJSONObject *_event;
    NSArray *_data;
}
@property (strong, nonatomic) IRCCloudJSONObject *event;
-(void)refresh;
@end
