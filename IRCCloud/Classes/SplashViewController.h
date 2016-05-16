//
//  SplashViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 11/12/15.
//  Copyright © 2015 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SplashViewController : UIViewController {
    IBOutlet UIImageView *_logo;
}
-(void)animate:(UIImageView *)loginLogo;
@end
