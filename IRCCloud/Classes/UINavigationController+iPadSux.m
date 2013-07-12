//
//  UINavigationController+iPadSux.m
//  IRCCloud
//
//  Created by Sam Steele on 7/11/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "UINavigationController+iPadSux.h"

@implementation UINavigationController (iPadSux)
//Work-around for an iOS bug that prevents the keyboard from dismissing in a modal dialog on iPad
- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}
@end
