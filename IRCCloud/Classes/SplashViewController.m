//
//  SplashViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 11/12/15.
//  Copyright © 2015 IRCCloud, Ltd. All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()

@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _logo.center = CGPointMake(self.view.center.x, 39 + [UIApplication sharedApplication].statusBarFrame.size.height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)animate:(UIImageView *)loginLogo {
    if(loginLogo) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [animation setFromValue:@(_logo.layer.position.x)];
        [animation setToValue:@((self.view.bounds.size.width / 2) - 112)];
        [animation setDuration:0.4];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.17 :.89 :.32 :1.28]];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [_logo.layer addAnimation:animation forKey:nil];
    } else {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [animation setFromValue:@(_logo.layer.position.x)];
        [animation setToValue:@(self.view.bounds.size.width + _logo.bounds.size.width)];
        [animation setDuration:0.4];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.8 :-.3 :.8 :-.3]];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [_logo.layer addAnimation:animation forKey:nil];
    }
}

@end
