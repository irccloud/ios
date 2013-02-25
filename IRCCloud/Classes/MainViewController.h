//
//  MainViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersTableView.h"

@interface MainViewController : UIViewController {
    IBOutlet BuffersTableView *_buffersView;
    IBOutlet UIView *_contentView;
}

@end
