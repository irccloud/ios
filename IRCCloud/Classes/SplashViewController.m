//
//  SplashViewController.h
//
//  Copyright (C) 2015 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

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
