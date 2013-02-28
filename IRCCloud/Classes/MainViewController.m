//
//  MainViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "MainViewController.h"
#import "NetworkConnection.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    CGSize keyboardSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] toView:nil].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    CGRect frame = self.view.frame;
    frame.size.height -= keyboardSize.height;
    self.view.frame = frame;
    
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    CGSize keyboardSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] toView:nil].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:0.3];
    
    CGRect frame = self.view.frame;
    frame.size.height += keyboardSize.height;
    self.view.frame = frame;
    
    [UIView commitAnimations];
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

-(IBAction)sendButtonPressed:(id)sender {
    [[NetworkConnection sharedInstance] say:_message.text to:_buffer.name cid:_buffer.cid];
    _message.text = @"";
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonPressed:textField];
    return YES;
}

- (void)bufferSelected:(int)bid {
    NSLog(@"BID selected: %i", bid);
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    [_usersView setBuffer:_buffer];
    [_eventsView setBuffer:_buffer];
    if([self.view isKindOfClass:[UIScrollView class]]) {
        [((UIScrollView *)self.view) scrollRectToVisible:_eventsView.tableView.frame animated:YES];
    }
}
@end
