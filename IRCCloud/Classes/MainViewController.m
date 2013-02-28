//
//  MainViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(_contentView != nil) {
        [(UIScrollView *)self.view addSubview:_contentView];
    } else {
        _contentView = self.view;
    }
    [self bufferSelected:[BuffersDataSource sharedInstance].firstBid];
}

- (void)viewDidAppear:(BOOL)animated {
    [_buffersView viewDidAppear:animated];
    [_usersView viewDidAppear:animated];
    [_eventsView viewDidAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [_buffersView viewDidDisappear:animated];
    [_usersView viewDidDisappear:animated];
    [_eventsView viewDidDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [_buffersView viewWillAppear:animated];
    [_usersView viewWillAppear:animated];
    [_eventsView viewWillAppear:animated];
    if([self.view isKindOfClass:[UIScrollView class]]) {
        ((UIScrollView *)self.view).contentSize = _contentView.bounds.size;
        ((UIScrollView *)self.view).contentOffset = CGPointMake(220, 0);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [_buffersView viewWillDisappear:animated];
    [_usersView viewWillDisappear:animated];
    [_eventsView viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)bufferSelected:(int)bid {
    NSLog(@"BID selected: %i", bid);
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    [_usersView setBuffer:bid];
    [_eventsView setBuffer:b.bid cid:b.cid name:b.name type:b.type];
}
@end
