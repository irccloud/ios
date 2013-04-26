//
//  UsersTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"

@protocol UsersTableViewDelegate<NSObject>
-(void)userSelected:(NSString *)nick rect:(CGRect)rect;
-(void)dismissKeyboard;
@end

@interface UsersTableView : UITableViewController {
    NSArray *_data;
    Buffer *_buffer;
    IBOutlet id<UsersTableViewDelegate> delegate;
}
-(void)setBuffer:(Buffer *)buffer;
@end
