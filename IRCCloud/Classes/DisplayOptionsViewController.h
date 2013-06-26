//
//  DisplayOptionsViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/26/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"

@interface DisplayOptionsViewController : UITableViewController {
    Buffer *_buffer;
    UISwitch *_showMembers;
    UISwitch *_trackUnread;
    UISwitch *_showJoinPart;
    int _reqid;
}
@property (strong, nonatomic) Buffer *buffer;
@end
