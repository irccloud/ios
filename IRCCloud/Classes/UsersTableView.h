//
//  UsersTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"

@interface UsersTableView : UITableViewController {
    NSMutableArray *_data;
    Buffer *_buffer;
}
-(void)setBuffer:(Buffer *)buffer;
@end
