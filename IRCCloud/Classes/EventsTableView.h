//
//  EventsTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"
#import "EventsDataSource.h"

@interface EventsTableView : UITableViewController {
    NSDateFormatter *_formatter;
    NSMutableArray *_data;
    Buffer *_buffer;
    
    NSTimeInterval _maxEid, _minEid, _currentCollapsedEid, _earliestEid;
    int _currentGroupPosition;
}
-(void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped;
-(void)setBuffer:(int)bid cid:(int)cid name:(NSString *)name type:(NSString *)type;
@end
