//
//  ImgurLoginViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 5/19/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "ImgurLoginViewController.h"
#import "config.h"

@implementation ImgurLoginViewController

- (id)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.navigationItem.title = @"Login to Imgur";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    }
#endif
    self.view.backgroundColor = [UIColor blackColor];
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    _webView.backgroundColor = [UIColor blackColor];
    _webView.delegate = self;
#ifdef IMGUR_KEY
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.imgur.com/oauth2/authorize?client_id=%@&response_type=token", @IMGUR_KEY]]]];
#endif
    [self.view addSubview:_webView];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)
        return;
    NSLog(@"Error: %@", error);
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL.host isEqualToString:@"imgur.com"]) {
        if([request.URL.fragment hasPrefix:@"access_token="]) {
            for(NSString *param in [request.URL.fragment componentsSeparatedByString:@"&"]) {
                NSArray *p = [param componentsSeparatedByString:@"="];
                NSString *name = [p objectAtIndex:0];
                NSString *value = [p objectAtIndex:1];
                [[NSUserDefaults standardUserDefaults] setObject:value forKey:[NSString stringWithFormat:@"imgur_%@", name]];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.navigationController popViewControllerAnimated:YES];
            return NO;
        } else if([request.URL.query isEqualToString:@"error=access_denied"]) {
            [self.navigationController popViewControllerAnimated:YES];
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
