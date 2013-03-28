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
    self.navigationItem.leftBarButtonItem = _navItem.leftBarButtonItem;
    self.navigationItem.rightBarButtonItem = _navItem.rightBarButtonItem;
    //TODO: resize if the keyboard is visible
    //TODO: check the user info for the last BID
    [self bufferSelected:[BuffersDataSource sharedInstance].firstBid];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogStarted:)
                                                 name:kIRCCloudBacklogStartedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogProgress:)
                                                 name:kIRCCloudBacklogProgressNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogCompleted:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectivityChanged:)
                                                 name:kIRCCloudConnectivityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

-(void)_showConnectingView {
    if(_connectingView.hidden) {
        CGRect frame = _connectingView.frame;
        frame.origin.y = -frame.size.height;
        _connectingView.frame = frame;
        _connectingView.hidden = NO;
        frame.origin.y = 0;
        [UIView animateWithDuration:0.3
                         animations:^{_connectingView.frame = frame;}
                         completion:nil];
    }
}

-(void)_hideConnectingView {
    if(!_connectingView.hidden) {
        CGRect frame = _connectingView.frame;
        frame.origin.y = 0;
        _connectingView.frame = frame;
        _connectingView.hidden = NO;
        frame.origin.y = -frame.size.height;
        [UIView animateWithDuration:0.3
                         animations:^{_connectingView.frame = frame;}
                         completion:^(BOOL finished){ _connectingView.hidden = YES; }];
    }
}

-(void)connectivityChanged:(NSNotification *)notification {
    switch([NetworkConnection sharedInstance].state) {
        case kIRCCloudStateConnecting:
            [self _showConnectingView];
            _connectingStatus.text = @"Connecting";
            [_connectingActivity startAnimating];
            _connectingActivity.hidden = NO;
            _connectingProgress.progress = 0;
            _connectingProgress.hidden = YES;
            _connectingError.text = @"";
            break;
        case kIRCCloudStateDisconnected:
            _connectingStatus.text = @"Disconnected";
            _connectingActivity.hidden = YES;
            _connectingProgress.progress = 0;
            _connectingProgress.hidden = YES;
            _connectingError.text = @"";
        case kIRCCloudStateDisconnecting:
            [self _showConnectingView];
        case kIRCCloudStateConnected:
            [_connectingActivity stopAnimating];
            break;
    }
}

-(void)backlogStarted:(NSNotification *)notification {
    [_connectingStatus setText:@"Loading"];
    _connectingActivity.hidden = YES;
    [_connectingActivity stopAnimating];
    _connectingProgress.progress = 0;
    _connectingProgress.hidden = NO;
}

-(void)backlogProgress:(NSNotification *)notification {
    [_connectingProgress setProgress:[notification.object floatValue] animated:YES];
}

-(void)backlogCompleted:(NSNotification *)notification {
    [self _hideConnectingView];
    if(!_buffer) {
        //TODO: check the user info for the last BID
        [self bufferSelected:[BuffersDataSource sharedInstance].firstBid];
    }
}

-(void)keyboardWillShow:(NSNotification*)notification {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGSize keyboardSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] toView:nil].size;

    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    
    CGRect frame = self.view.frame;
    frame.size.height -= keyboardSize.height;
    self.view.frame = frame;
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    [UIView commitAnimations];

    if([self.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.view;
        scrollView.contentSize = CGSizeMake(_contentView.frame.size.width,frame.size.height);
    }
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    NSArray *rows = [_eventsView.tableView indexPathsForVisibleRows];
    CGSize keyboardSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue] toView:nil].size;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    
    CGRect frame = self.view.frame;
    frame.size.height += keyboardSize.height;
    self.view.frame = frame;
    [_eventsView.tableView scrollToRowAtIndexPath:[rows lastObject] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    
    [UIView commitAnimations];
    
    if([self.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.view;
        scrollView.contentSize = CGSizeMake(_contentView.frame.size.width,frame.size.height);
    }
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
    [self connectivityChanged:nil];
    if([NetworkConnection sharedInstance].state == kIRCCloudStateDisconnected)
        [[NetworkConnection sharedInstance] connect];
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

-(void)bufferSelected:(int)bid {
    TFLog(@"BID selected: %i", bid);
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    self.navigationItem.title = _buffer.name;
    [_usersView setBuffer:_buffer];
    [_eventsView setBuffer:_buffer];
    if([self.view isKindOfClass:[UIScrollView class]]) {
        [((UIScrollView *)self.view) scrollRectToVisible:_eventsView.tableView.frame animated:YES];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _startX = scrollView.contentOffset.x;
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if(!decelerate) {
        [self scrollViewWillBeginDecelerating:scrollView];
    }
}

-(IBAction)usersButtonPressed:(id)sender {
    UIScrollView *scrollView = (UIScrollView *)self.view;
    if(scrollView.contentOffset.x == _eventsView.tableView.frame.origin.x || scrollView.contentOffset.x == _buffersView.tableView.frame.origin.x) {
        [scrollView scrollRectToVisible:_usersView.tableView.frame animated:YES];
    } else {
        [scrollView scrollRectToVisible:_eventsView.tableView.frame animated:YES];
    }
}

-(IBAction)listButtonPressed:(id)sender {
    UIScrollView *scrollView = (UIScrollView *)self.view;
    if(scrollView.contentOffset.x == _buffersView.tableView.frame.origin.x) {
        [scrollView scrollRectToVisible:_eventsView.tableView.frame animated:YES];
    } else {
        [scrollView scrollRectToVisible:_buffersView.tableView.frame animated:YES];
    }
}

-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    int buffersDisplayWidth = _buffersView.tableView.bounds.size.width;
    int usersDisplayWidth = _usersView.tableView.bounds.size.width;
    
    if(abs(_startX - scrollView.contentOffset.x) > buffersDisplayWidth / 4) { //If they've dragged a drawer more than 25% on screen, snap the drawer onto the screen
        if(_startX < buffersDisplayWidth + usersDisplayWidth / 4 && scrollView.contentOffset.x < _startX) {
            [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
            //TODO: set the buffer swipe tip flag
        } else if(_startX >= buffersDisplayWidth && scrollView.contentOffset.x > _startX) {
            [scrollView setContentOffset:CGPointMake(buffersDisplayWidth + usersDisplayWidth,0) animated:YES];
            //TODO: set the buffer swipe tip flag
        } else {
            [scrollView setContentOffset:CGPointMake(buffersDisplayWidth,0) animated:YES];
        }
    } else { //Snap back
        if(_startX < buffersDisplayWidth)
            [scrollView setContentOffset:CGPointMake(0,0) animated:YES];
        else if(_startX > buffersDisplayWidth + usersDisplayWidth / 4)
            [scrollView setContentOffset:CGPointMake(buffersDisplayWidth + usersDisplayWidth,0) animated:YES];
        else
            [scrollView setContentOffset:CGPointMake(buffersDisplayWidth,0) animated:YES];
    }
    _startX = 0;
}

-(void)rowSelected:(Event *)event {
    [_message resignFirstResponder];
}
@end
