//
//  LoginSplashViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 2/19/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "LoginSplashViewController.h"

@implementation LoginSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _conn = [NetworkConnection sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view from its nib.
    [version setText:[NSString stringWithFormat:@"Version %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]]];
}

-(void)viewWillAppear:(BOOL)animated {
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"session"];
    if(session != nil && [session length] > 0) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        if(_conn.state == kIRCCloudStateDisconnected) {
            loginView.alpha = 0;
            loadingView.alpha = 1;
            progress.hidden = YES;
            progress.progress = 0;
            [activity startAnimating];
            activity.hidden = NO;
            [status setText:@"Connecting"];
            [_conn connect];
            [self updateConnecting:nil];
        }
    } else {
        password.text = @"";
        loadingView.alpha = 0;
        loginView.alpha = 1;
    }
}

-(void)viewDidAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnecting:)
                                                 name:kIRCCloudConnectivityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogStarted:)
                                                 name:kIRCCloudBacklogStartedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogProgress:)
                                                 name:kIRCCloudBacklogProgressNotification object:nil];
}

-(void)updateConnecting:(NSNotification *)notification {
    if(_conn.state == kIRCCloudStateConnecting) {
        [status setText:@"Connecting"];
        activity.hidden = NO;
        [activity startAnimating];
        progress.progress = 0;
        progress.hidden = YES;
    } else if(_conn.state == kIRCCloudStateDisconnected) {
        if(_conn.reconnectTimestamp > 0) {
            [status setText:[NSString stringWithFormat:@"Reconnecting in %0.f seconds", _conn.reconnectTimestamp - [[NSDate date] timeIntervalSince1970]]];
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
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)backlogStarted:(NSNotification *)notification {
    [status setText:@"Loading"];
    activity.hidden = YES;
    progress.progress = 0;
    progress.hidden = NO;
}

-(void)backlogProgress:(NSNotification *)notification {
    [progress setProgress:[notification.object floatValue] animated:YES];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    [UIView beginAnimations:nil context:nil];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        logo.frame = CGRectMake(112, 16, 96, 96);
        loginView.frame = CGRectMake(0, 112, 320, 160);
    } else {
        logo.frame = CGRectMake(128, 246-180, 256, 256);
        loginView.frame = CGRectMake(392, 302-180, 612, 144);
    }
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    [UIView beginAnimations:nil context:nil];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        logo.frame = CGRectMake(96, 36, 128, 128);
        loginView.frame = CGRectMake(0, 200, 320, 160);
    } else {
        logo.frame = CGRectMake(128, 246, 256, 256);
        loginView.frame = CGRectMake(392, 302, 612, 144);
    }
    [UIView commitAnimations];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)loginButtonPressed:(id)sender {
    [username resignFirstResponder];
    [password resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loginView.alpha = 0;
    loadingView.alpha = 1;
    [UIView commitAnimations];
    [status setText:@"Signing In"];
    progress.hidden = YES;
    progress.progress = 0;
    [activity startAnimating];
    activity.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] login:[username text] password:[password text]];
        if([[result objectForKey:@"success"] intValue] == 1) {
            [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"session"] forKey:@"session"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
            [status setText:@"Connecting"];
            [_conn connect];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
                NSString *message = @"Unable to login to IRCCloud.  Please check your username and password, and try again shortly.";
                if([[result objectForKey:@"message"] isEqualToString:@"auth"]
                   || [[result objectForKey:@"message"] isEqualToString:@"email"]
                   || [[result objectForKey:@"message"] isEqualToString:@"password"]
                   || [[result objectForKey:@"message"] isEqualToString:@"legacy_account"])
                    message = @"Incorrect username or password.  Please try again.";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
        }
    });
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == username)
        [password becomeFirstResponder];
    else
        [self loginButtonPressed:textField];
    return YES;
}

@end
