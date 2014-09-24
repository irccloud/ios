//
//  UIDevice+UIDevice_iPhone6Hax.m
//  IRCCloud
//
//  Created by Sam Steele on 9/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "UIDevice+UIDevice_iPhone6Hax.h"

@implementation UIDevice (UIDevice_iPhone6Hax)
-(BOOL)isBigPhone {
    if(![self respondsToSelector:@selector(nativeScale)])
        return NO;
    else
        return [self userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] nativeScale] > 2.0f;
}
@end
