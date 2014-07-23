//
//  SplashViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":@"api.irccloud.com", @"saveToCameraRoll":@(YES), @"photoSize":@(1024)}];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"path"]) {
        IRCCLOUD_HOST = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
        IRCCLOUD_PATH = [[NSUserDefaults standardUserDefaults] objectForKey:@"path"];
    }
    _conn = [NetworkConnection sharedInstance];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnecting:)
                                                 name:kIRCCloudConnectivityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogStarted:)
                                                 name:kIRCCloudBacklogStartedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogProgress:)
                                                 name:kIRCCloudBacklogProgressNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogComplete:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [_conn connect];
}

-(void)updateConnecting:(NSNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
        if(_conn.state == kIRCCloudStateConnecting || [_conn reachable] == kIRCCloudUnknown) {
            [status setText:@"Connecting"];
            activity.hidden = NO;
            [activity startAnimating];
            progress.progress = 0;
            progress.hidden = YES;
            error.text = nil;
        } else if(_conn.state == kIRCCloudStateDisconnected) {
            if(_conn.reconnectTimestamp > 0) {
                int seconds = (int)(_conn.reconnectTimestamp - [[NSDate date] timeIntervalSince1970]) + 1;
                [status setText:[NSString stringWithFormat:@"Reconnecting in %i second%@", seconds, (seconds == 1)?@"":@"s"]];
                activity.hidden = NO;
                [activity startAnimating];
                progress.progress = 0;
                progress.hidden = YES;
                [self performSelector:@selector(updateConnecting:) withObject:nil afterDelay:1];
            } else {
                if([_conn reachable])
                    [status setText:@"Disconnected"];
                else
                    [status setText:@"Offline"];
                activity.hidden = YES;
                progress.progress = 0;
                progress.hidden = YES;
            }
        }
    }];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)backlogStarted:(NSNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
        [status setText:@"Loading"];
        activity.hidden = YES;
        progress.progress = 0;
        progress.hidden = NO;
    }];
}

-(void)backlogProgress:(NSNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
        [progress setProgress:[notification.object floatValue] animated:YES];
    }];
}

-(void)backlogComplete:(NSNotification *)notification {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^() {
        self.navigationController.navigationBarHidden = NO;
        [self.navigationController popToRootViewControllerAnimated:NO];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
