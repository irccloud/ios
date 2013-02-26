//
//  BuffersTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BuffersTableViewDelegate<NSObject>
-(void)bufferSelected:(int)bid;
@end

@interface BuffersTableView : UITableViewController {
    NSMutableArray *_data;
    int _selectedRow;
    IBOutlet id<BuffersTableViewDelegate> _delegate;
}

@end
