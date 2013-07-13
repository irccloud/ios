//
//  UIColor+IRCCloud.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (IRCCloud)
+(UIColor *)backgroundBlueColor;
+(UIColor *)selectedBlueColor;
+(UIColor *)blueBorderColor;
+(UIColor *)ownersGroupColor;
+(UIColor *)adminsGroupColor;
+(UIColor *)opsGroupColor;
+(UIColor *)halfopsGroupColor;
+(UIColor *)voicedGroupColor;
+(UIColor *)ownersHeadingColor;
+(UIColor *)adminsHeadingColor;
+(UIColor *)opsHeadingColor;
+(UIColor *)halfopsHeadingColor;
+(UIColor *)voicedHeadingColor;
+(UIColor *)membersHeadingColor;
+(UIColor *)ownersBorderColor;
+(UIColor *)ownersLightColor;
+(UIColor *)adminsBorderColor;
+(UIColor *)adminsLightColor;
+(UIColor *)opsBorderColor;
+(UIColor *)opsLightColor;
+(UIColor *)halfopsBorderColor;
+(UIColor *)halfopsLightColor;
+(UIColor *)voicedBorderColor;
+(UIColor *)voicedLightColor;
+(UIColor *)timestampColor;
+(UIColor *)darkBlueColor;
+(UIColor *)networkErrorBackgroundColor;
+(UIColor *)networkErrorColor;
+(UIColor *)colorFromHexString:(NSString *)hexString;
+(UIColor *)mIRCColor:(int)color;
+(UIColor *)errorBackgroundColor;
+(UIColor *)statusBackgroundColor;
+(UIColor *)selfBackgroundColor;
+(UIColor *)highlightBackgroundColor;
+(UIColor *)noticeBackgroundColor;
+(UIColor *)timestampBackgroundColor;
+(UIColor *)newMsgsBackgroundColor;
+(UIColor *)collapsedRowBackgroundColor;
+(UIColor *)collapsedHeadingBackgroundColor;
+(UIColor *)navBarColor;
@end
