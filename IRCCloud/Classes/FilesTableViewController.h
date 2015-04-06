//
//  FilesTableViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 4/6/15.
//  Copyright (c) 2015 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FilesTableViewDelegate<NSObject>
-(void)filesTableViewControllerDidSelectFile:(NSDictionary *)file;
@end

@interface FilesTableViewController : UITableViewController {
    int _pages;
    NSArray *_files;
    NSMutableDictionary *_thumbnails;
    NSDateFormatter *_formatter;
    NSOperationQueue *_thumbQueue;
    int _reqid;
    BOOL _canLoadMore;
    id<FilesTableViewDelegate> _delegate;
    UIView *_footerView;
}
@property id<FilesTableViewDelegate> delegate;
@end
