//
//  UIDevice+UIDevice_iPhone6Hax.m
//  IRCCloud
//
//  Created by Sam Steele on 9/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "UIDevice+UIDevice_iPhone6Hax.h"

BOOL __isBigPhone = NO;
BOOL __isBigPhone_set = NO;

@implementation UIDevice (UIDevice_iPhone6Hax)
-(BOOL)isBigPhone {
    if(__isBigPhone_set)
        return __isBigPhone;
    
    if(![[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)])
        __isBigPhone = NO;
    else
        __isBigPhone = [self userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] nativeScale] > 2.0f;
    
    __isBigPhone_set = YES;
    return __isBigPhone;
}
@end
