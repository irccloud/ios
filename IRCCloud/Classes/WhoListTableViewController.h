//
//  WhoListTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 7/7/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IRCCloudJSONObject.h"

@interface WhoListTableViewController : UITableViewController<UIAlertViewDelegate,UITextFieldDelegate> {
    IRCCloudJSONObject *_event;
    NSArray *_data;
    UIAlertView *_alertView;
}
@property (strong, nonatomic) IRCCloudJSONObject *event;
-(void)refresh;
@end
