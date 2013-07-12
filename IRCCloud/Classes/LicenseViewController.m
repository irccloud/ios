//
//  LicenseViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 7/5/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "LicenseViewController.h"
#import "UIColor+IRCCloud.h"

@implementation LicenseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.navigationItem.title = @"Licenses";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 7) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
    }
    UITextView *tv = [[UITextView alloc] initWithFrame:self.view.bounds];
    tv.text = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"licenses" ofType:@"txt"] encoding:NSUTF8StringEncoding error:nil];
    tv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tv];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
