//
//  UIColor+IRCCloud.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "UIColor+IRCCloud.h"

@implementation UIColor (IRCCloud)
+(UIColor *)backgroundBlueColor {
    return [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
}
+(UIColor *)selectedBlueColor {
    return [UIColor colorWithRed:0.322 green:0.49 blue:1 alpha:1];
}
+(UIColor *)ownersGroupColor {
    return [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
}
+(UIColor *)adminsGroupColor {
    return [UIColor colorWithRed:0.929 green:0.8 blue:1 alpha:1];
}
+(UIColor *)opsGroupColor {
    return [UIColor colorWithRed:0.996 green:0.949 blue:0.949 alpha:1];
}
+(UIColor *)halfopsGroupColor {
    return [UIColor colorWithRed:0.996 green:0.929 blue:0.855 alpha:1];
}
+(UIColor *)voicedGroupColor {
    return [UIColor colorWithRed:0.957 green:1 blue:0.929 alpha:1];
}
+(UIColor *)ownersHeadingColor {
    return [UIColor colorWithRed:0.906 green:0.667 blue:0 alpha:1];
}
+(UIColor *)adminsHeadingColor {
    return [UIColor colorWithRed:0.396 green:0 blue:0.647 alpha:1];
}
+(UIColor *)opsHeadingColor {
    return [UIColor colorWithRed:0.729 green:0.09 blue:0.098 alpha:1];
}
+(UIColor *)halfopsHeadingColor {
    return [UIColor colorWithRed:0.71 green:0.349 blue:0 alpha:1];
}
+(UIColor *)voicedHeadingColor {
    return [UIColor colorWithRed:0.145 green:0.694 blue:0 alpha:1];
}
+(UIColor *)membersHeadingColor {
    return [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
}
+(UIColor *)timestampColor {
    return [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1];
}
@end
