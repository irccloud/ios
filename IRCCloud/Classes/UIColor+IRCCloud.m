//
//  UIColor+IRCCloud.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
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


#import "UIColor+IRCCloud.h"

UIImage *__timestampBackgroundImage;
UIImage *__newMsgsBackgroundImage;
UIImage *__navbarBackgroundImage;
UIImage *__textareaBackgroundImage;
UIImage *__buffersDrawerBackgroundImage;
UIImage *__usersDrawerBackgroundImage;

UIColor *__color_border1;
UIColor *__color_border2;
UIColor *__color_border3;
UIColor *__color_border4;
UIColor *__color_border5;
UIColor *__color_border6;
UIColor *__color_border7;
UIColor *__color_border8;
UIColor *__color_border9;
UIColor *__color_border10;
UIColor *__color_border11;

UIColor *__color_text1;
UIColor *__color_text2;
UIColor *__color_text3;
UIColor *__color_text4;
UIColor *__color_text5;
UIColor *__color_text6;
UIColor *__color_text7;
UIColor *__color_text8;
UIColor *__color_text9;
UIColor *__color_text10;
UIColor *__color_text11;
UIColor *__color_text12;

UIColor *__color_background0;
UIColor *__color_background1;
UIColor *__color_background2;
UIColor *__color_background3;
UIColor *__color_background4;
UIColor *__color_background5;
UIColor *__color_background5a;
UIColor *__color_background6;
UIColor *__color_background6a;
UIColor *__color_background7;

UIColor *__selectedColor;
UIColor *__selectedBorder;
UIColor *__unreadColor;
UIColor *__iPadBordersColor;
UIColor *__bufferTextColor;
UIColor *__inactiveBufferTextColor;
UIColor *__navbarSubheadingTextColor;
UIColor *__chatterBarTextColor;
UIColor *__linkColor;
UIColor *__highlightTimestampColor;
UIColor *__highlightBackgroundColor;
UIColor *__selfBackgroundColor;

UIColor *__color_opers_bg;
UIColor *__color_owners_bg;
UIColor *__color_admins_bg;
UIColor *__color_ops_bg;
UIColor *__color_halfops_bg;
UIColor *__color_voiced_bg;
UIColor *__color_member_bg;

UIColor *__color_opers_border;
UIColor *__color_owners_border;
UIColor *__color_admins_border;
UIColor *__color_ops_border;
UIColor *__color_halfops_border;
UIColor *__color_voiced_border;
UIColor *__color_member_border;

BOOL __color_theme_is_dark;

@implementation UITextField (IRCCloudAppearanceHax)
-(void)setPlaceholder:(NSString *)placeholder {
    [self setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:placeholder attributes:@{NSForegroundColorAttributeName:__color_text12}]];
}
@end

@implementation UITableViewCell (IRCCloudAppearanceHax)
- (UIColor *)textLabelColor {
    return self.textLabel.textColor;
}

- (void)setTextLabelColor:(UIColor *)textLabelColor {
    if(textLabelColor)
        self.textLabel.textColor = textLabelColor;
}

- (UIColor *)detailTextLabelColor {
    return self.detailTextLabel.textColor;
}

- (void)setDetailTextLabelColor:(UIColor *)detailTextLabelColor {
    if(detailTextLabelColor)
        self.detailTextLabel.textColor = detailTextLabelColor;
}
@end

@implementation UIColor (IRCCloud)
+(BOOL)isDarkTheme {
    return __color_theme_is_dark;
}

+(UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)light alpha:(CGFloat)alpha {
    saturation *= (light < 0.5)?light:(1-light);
    
    return [UIColor colorWithHue:hue saturation:(2*saturation)/(light+saturation) brightness:light+saturation alpha:alpha];
}

+(void)setTheme:(NSString *)theme {
    if([theme isEqualToString:@"dawn"]) {
        __color_theme_is_dark = NO;
        
        __color_background0 = [UIColor whiteColor];
        __color_background1 = [UIColor whiteColor];
        __color_background2 = [UIColor whiteColor];
        __color_background3 = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __color_background4 = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __color_background5 = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __color_background5a = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __color_background6 = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __color_background6a = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __color_background7 = [UIColor whiteColor];
        
        __color_text1 = [UIColor blackColor];
        __color_text2 = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __color_text3 = [UIColor colorWithRed:0.118 green:0.447 blue:1 alpha:1];
        __color_text4 = [UIColor blackColor];
        __color_text5 = [UIColor colorWithWhite:0.133 alpha:1.0];
        __color_text6 = [UIColor blackColor];
        __color_text7 = [UIColor colorWithWhite:0.686 alpha:1.0];
        __color_text8 = [UIColor blackColor];
        __color_text9 = [UIColor colorWithWhite:0.667 alpha:1.0];
        __color_text10 = [UIColor colorWithWhite:0.667 alpha:1.0];
        __color_text11 = [UIColor blackColor];
        __color_text12 = [UIColor blackColor];
        
        __color_border1 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border2 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border3 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border4 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border5 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border6 = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __color_border7 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __color_border8 = [UIColor whiteColor];
        __color_border9 = [UIColor colorWithRed:0.702 green:0.812 blue:1 alpha:1];
        __color_border10 = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __color_border11 = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        
        __selectedColor = [UIColor colorWithRed:0.118 green:0.447 blue:1 alpha:1];
        __selectedBorder = [UIColor colorWithRed:0.243 green:0.047 blue:1 alpha:1];
        __unreadColor = [self colorFromHexString:@"1E72FF"];
        __bufferTextColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __inactiveBufferTextColor = [UIColor colorWithRed:0.612 green:0.78 blue:1 alpha:1];
        __iPadBordersColor = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __navbarSubheadingTextColor = [UIColor colorWithWhite:0.467 alpha:1.0];
        __chatterBarTextColor = [UIColor colorWithRed:0 green:0.129 blue:0.475 alpha:1];
        __linkColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __highlightTimestampColor = [UIColor colorWithRed:0.376 green:0 blue:0 alpha:1];
        __highlightBackgroundColor = [UIColor colorWithRed:0.753 green:0.859 blue:1 alpha:1];
        __selfBackgroundColor = [UIColor colorWithRed:0.886 green:0.929 blue:1 alpha:1];
        
        __color_opers_border = [UIColor colorWithRed:0.878 green:0.137 blue:0.02 alpha:1];
        __color_owners_border = [UIColor colorWithRed:0.906 green:0.667 blue:0 alpha:1];
        __color_admins_border = [UIColor colorWithRed:0.396 green:0 blue:0.647 alpha:1];
        __color_ops_border = [UIColor colorWithRed:0.729 green:0.09 blue:0.098 alpha:1];
        __color_halfops_border = [UIColor colorWithRed:0.71 green:0.349 blue:0 alpha:1];
        __color_voiced_border = [UIColor colorWithRed:0.145 green:0.694 blue:0 alpha:1];
        __color_member_border = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        
        __color_opers_bg = [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
        __color_owners_bg = [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
        __color_admins_bg = [UIColor colorWithRed:0.929 green:0.8 blue:1 alpha:1];
        __color_ops_bg = [UIColor colorWithRed:0.996 green:0.949 blue:0.949 alpha:1];
        __color_halfops_bg = [UIColor colorWithRed:1 green:0.98 blue:0.949 alpha:1];
        __color_voiced_bg = [UIColor colorWithRed:0.957 green:1 blue:0.929 alpha:1];
        __color_member_bg = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        
        [[UITableView appearance] setBackgroundColor:[UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1]];
        [[UITableView appearance] setSeparatorColor:nil];
        [[UITableViewCell appearance] setBackgroundColor:[UIColor whiteColor]];
        [[UITableViewCell appearance] setTextLabelColor:nil];
        [[UITableViewCell appearance] setDetailTextLabelColor:[UIColor colorWithRed:0.557 green:0.557 blue:0.576 alpha:1]];
        [[UITableViewCell appearance] setTintColor:nil];
        [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:nil];
        [[UISwitch appearance] setOnTintColor:nil];
        [[UISlider appearance] setTintColor:nil];
        
        [[UITextField appearance] setTintColor:nil];
        [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDefault];
        
        [[UITextView appearance] setTintColor:nil];
        [[UITextView appearance] setTextColor:nil];
        
        [[UIScrollView appearance] setIndicatorStyle:UIScrollViewIndicatorStyleDefault];
        
        [[UITableViewCell appearanceWhenContainedIn:[UIImagePickerController class], nil] setBackgroundColor:nil];
        [[UIScrollView appearanceWhenContainedIn:[UIImagePickerController class], nil] setIndicatorStyle:UIScrollViewIndicatorStyleDefault];
        
        [[UINavigationBar appearance] setBackgroundImage:[self navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [self navBarHeadingColor]}];
        [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0 green:0.478 blue:1 alpha:1]];
    } else {
        __color_theme_is_dark = YES;
        
        CGFloat hue = 210.0f/360.0f;
        CGFloat saturation = 0.55f;
        CGFloat selectedSaturation = 1.0f;
        
        if([theme isEqualToString:@"ash"]) {
            hue = 210.0f/360.0f;
            saturation = 0.0f;
            selectedSaturation = 0.0f;
        } else if([theme isEqualToString:@"dusk"]) {
            hue = 210.0f/360.0f;
            saturation = 0.55f;
            selectedSaturation = 1.0f;
        } else if([theme isEqualToString:@"emerald"]) {
            hue = 110.0f/360.0f;
            saturation = 0.55f;
            selectedSaturation = 1.0f;
        } else if([theme isEqualToString:@"orchid"]) {
            hue = 314.0f/360.0f;
            saturation = 0.55f;
            selectedSaturation = 1.0f;
        } else if([theme isEqualToString:@"rust"]) {
            hue = 0.0f;
            saturation = 0.55f;
            selectedSaturation = 1.0f;
        } else if([theme isEqualToString:@"sand"]) {
            hue = 45.0f/360.0f;
            saturation = 0.55f;
            selectedSaturation = 1.0f;
        } else if([theme isEqualToString:@"tropic"]) {
            hue = 180.0f/360.0f;
            saturation = 0.55f;
            selectedSaturation = 0.0f;
        }
        
        __color_border1 = [UIColor colorWithHue:hue saturation:saturation lightness:0.55f alpha:1.0f];
        __color_border2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        __color_border3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        __color_border4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.40f alpha:1.0f];
        __color_border5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.35f alpha:1.0f];
        __color_border6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.30f alpha:1.0f];
        __color_border7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.25f alpha:1.0f];
        __color_border8 = [UIColor colorWithHue:hue saturation:saturation lightness:0.20f alpha:1.0f];
        __color_border9 = [UIColor colorWithHue:hue saturation:saturation lightness:0.15f alpha:1.0f];
        __color_border10 = [UIColor colorWithHue:hue saturation:saturation lightness:0.10f alpha:1.0f];
        __color_border11 = [UIColor colorWithHue:hue saturation:saturation lightness:0.05f alpha:1.0f];
        
        __color_text1 = [UIColor colorWithHue:hue saturation:saturation lightness:1.0f alpha:1.0f];
        __color_text2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.95f alpha:1.0f];
        __color_text3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.90f alpha:1.0f];
        __color_text4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.85f alpha:1.0f];
        __color_text5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.80f alpha:1.0f];
        __color_text6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.75f alpha:1.0f];
        __color_text7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.70f alpha:1.0f];
        __color_text8 = [UIColor colorWithHue:hue saturation:saturation lightness:0.65f alpha:1.0f];
        __color_text9 = [UIColor colorWithHue:hue saturation:saturation lightness:0.60f alpha:1.0f];
        __color_text10 = [UIColor colorWithHue:hue saturation:saturation lightness:0.55f alpha:1.0f];
        __color_text11 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        __color_text12 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        
        __color_background0 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        __color_background1 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        __color_background2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.40f alpha:1.0f];
        __color_background3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.35f alpha:1.0f];
        __color_background4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.30f alpha:1.0f];
        __color_background5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.25f alpha:1.0f];
        __color_background5a = [UIColor colorWithHue:hue saturation:saturation lightness:0.23f alpha:1.0f];
        __color_background6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.20f alpha:1.0f];
        __color_background6a = [UIColor colorWithHue:hue saturation:saturation lightness:0.17f alpha:1.0f];
        __color_background7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.15f alpha:1.0f];
        
        __selectedColor = [UIColor colorWithHue:hue saturation:selectedSaturation lightness:0.40f alpha:1.0f];
        __selectedBorder = [UIColor colorWithHue:hue saturation:selectedSaturation lightness:0.30f alpha:1.0f];
        __unreadColor = [self colorFromHexString:@"1E72FF"];
        
        __color_opers_border = [UIColor colorWithHue:30.0/360.0 saturation:0.85 lightness:0.25 alpha:1.0];
        __color_owners_border = [UIColor colorWithHue:47.0/360.0 saturation:0.68 lightness:0.25 alpha:1.0];
        __color_admins_border = [UIColor colorWithHue:265.0/360.0 saturation:0.44 lightness:0.36 alpha:1.0];
        __color_ops_border = [UIColor colorWithHue:0 saturation:0.36 lightness:0.38 alpha:1.0];
        __color_halfops_border = [UIColor colorWithHue:37.0/360.0 saturation:0.45 lightness:0.28 alpha:1.0];
        __color_voiced_border = [UIColor colorWithHue:85.0/360.0 saturation:1.0 lightness:0.17 alpha:1.0];
        __color_member_border = [UIColor colorWithHue:221.0/360.0 saturation:0.55 lightness:0.23 alpha:1.0];

        __color_opers_bg = [UIColor colorWithHue:27.0/360.0 saturation:0.64 lightness:0.16 alpha:1.0];
        __color_owners_bg = [UIColor colorWithHue:45.0/360.0 saturation:0.29 lightness:0.19 alpha:1.0];
        __color_admins_bg = [UIColor colorWithHue:276.0/360.0 saturation:0.27 lightness:0.15 alpha:1.0];
        __color_ops_bg = [UIColor colorWithHue:0 saturation:0.42 lightness:0.19 alpha:1.0];
        __color_halfops_bg = [UIColor colorWithHue:37.0/360.0 saturation:0.26 lightness:0.17 alpha:1.0];
        __color_voiced_bg = [UIColor colorWithHue:94.0/360.0 saturation:0.25 lightness:0.16 alpha:1.0];
        __color_member_bg = [UIColor colorWithHue:217.0/360.0 saturation:0.30 lightness:0.15 alpha:1.0];
        
        [[UITableView appearance] setBackgroundColor:__color_background7];
        [[UITableView appearance] setSeparatorColor:__color_border11];
        [[UITableViewCell appearance] setBackgroundColor:__color_background6];
        [[UITableViewCell appearance] setTextLabelColor:__color_text4];
        [[UITableViewCell appearance] setDetailTextLabelColor:__color_text7];
        [[UITableViewCell appearance] setTintColor:__color_text7];
        [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:__color_text8];
        [[UISwitch appearance] setOnTintColor:__color_text7];
        [[UISlider appearance] setTintColor:__color_text7];
        
        [[UITextField appearance] setTintColor:[self textareaTextColor]];
        [[UITextField appearance] setKeyboardAppearance:UIKeyboardAppearanceDark];
        
        [[UITextView appearance] setTintColor:[self textareaTextColor]];
        [[UITextView appearance] setTextColor:[self textareaTextColor]];
        
        [[UIScrollView appearance] setIndicatorStyle:UIScrollViewIndicatorStyleWhite];

        [[UITableViewCell appearanceWhenContainedIn:[UIImagePickerController class], nil] setBackgroundColor:nil];
        [[UIScrollView appearanceWhenContainedIn:[UIImagePickerController class], nil] setIndicatorStyle:UIScrollViewIndicatorStyleDefault];

        [[UINavigationBar appearance] setBackgroundImage:[self navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [self navBarHeadingColor]}];
        [[UINavigationBar appearance] setTintColor:[UIColor navBarSubheadingColor]];

        __iPadBordersColor = [self contentBackgroundColor];
        __bufferTextColor = __navbarSubheadingTextColor = __color_text4;
        __inactiveBufferTextColor = __color_text9;
        __chatterBarTextColor = __color_text5;
        __linkColor = __color_text1;
        __highlightTimestampColor = [UIColor colorWithRed:1 green:0.878 blue:0.878 alpha:1];
        __highlightBackgroundColor = __color_background5;
        __selfBackgroundColor = __color_background6;
    }
    
    __timestampBackgroundImage = nil;
    __newMsgsBackgroundImage = nil;
    __navbarBackgroundImage = nil;
    __textareaBackgroundImage = nil;
    __buffersDrawerBackgroundImage = nil;
    __usersDrawerBackgroundImage = nil;
}

+(UIColor *)contentBackgroundColor {
    return __color_background7;
}

+(UIColor *)messageTextColor {
    return __color_text4;
}

+(UIColor *)backgroundBlueColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
    return c;
}
+(UIColor *)unreadBlueColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.322 green:0.49 blue:1 alpha:1];
    return c;
}
+(UIColor *)blueBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.753 green:0.824 blue:1 alpha:1]; /*#c0d2ff*/
    return c;
}
+(UIColor *)opersGroupColor {
    return __color_opers_bg;
}
+(UIColor *)ownersGroupColor {
    return __color_owners_bg;
}
+(UIColor *)adminsGroupColor {
    return __color_admins_bg;
}
+(UIColor *)opsGroupColor {
    return __color_ops_bg;
}
+(UIColor *)halfopsGroupColor {
    return __color_halfops_bg;
}
+(UIColor *)voicedGroupColor {
    return __color_voiced_bg;
}
+(UIColor *)membersGroupColor {
    return __color_member_bg;
}
+(UIColor *)opersBorderColor {
    return __color_opers_border;
}
+(UIColor *)ownersBorderColor {
    return __color_owners_border;
}
+(UIColor *)adminsBorderColor {
    return __color_admins_border;
}
+(UIColor *)opsBorderColor {
    return __color_ops_border;
}
+(UIColor *)halfopsBorderColor {
    return __color_halfops_border;
}
+(UIColor *)voicedBorderColor {
    return __color_voiced_border;
}
+(UIColor *)membersBorderColor {
    return __color_member_border;
}
+(UIColor *)memberListTextColor {
    return __color_text5;
}
+(UIColor *)memberListAwayTextColor {
    return __color_text9;
}
+(UIColor *)timestampColor {
    return __color_text10;
}
+(UIColor *)darkBlueColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.094 green:0.247 blue:0.553 alpha:1.0]; /*#183f8d*/
    return c;
}
+(UIColor *)networkErrorBackgroundColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
    return c;
}
+(UIColor *)networkErrorColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
    return c;
}
+(UIColor *)serverBackgroundColor {
    return __color_background6;
}
+(UIColor *)bufferBackgroundColor {
    return __color_background4;
}
+(UIColor *) colorFromHexString:(NSString *)hexString {
    //From: http://stackoverflow.com/a/3805354
    
    NSString *cleanString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if([cleanString length] == 3) {
        cleanString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                       [cleanString substringWithRange:NSMakeRange(0, 1)],[cleanString substringWithRange:NSMakeRange(0, 1)],
                       [cleanString substringWithRange:NSMakeRange(1, 1)],[cleanString substringWithRange:NSMakeRange(1, 1)],
                       [cleanString substringWithRange:NSMakeRange(2, 1)],[cleanString substringWithRange:NSMakeRange(2, 1)]];
    }
    if([cleanString length] == 6) {
        cleanString = [cleanString stringByAppendingString:@"ff"];
    }
    
    unsigned int baseValue;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&baseValue];
    
    float red = ((baseValue >> 24) & 0xFF)/255.0f;
    float green = ((baseValue >> 16) & 0xFF)/255.0f;
    float blue = ((baseValue >> 8) & 0xFF)/255.0f;
    float alpha = ((baseValue >> 0) & 0xFF)/255.0f;
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
+(UIColor *)mIRCColor:(int)color {
    switch(color) {
        case 0:
            return [UIColor colorFromHexString:@"FFFFFF"]; //white
        case 1:
            return [UIColor colorFromHexString:@"000000"]; //black
        case 2:
            return [UIColor colorFromHexString:@"000080"]; //navy
        case 3:
            return [UIColor colorFromHexString:@"008000"]; //green
        case 4:
            return [UIColor colorFromHexString:@"FF0000"]; //red
        case 5:
            return [UIColor colorFromHexString:@"800000"]; //maroon
        case 6:
            return [UIColor colorFromHexString:@"DA70D6"]; //purple (light = 800080) or orchird for dark
        case 7:
            return [UIColor colorFromHexString:@"FFA500"]; //orange
        case 8:
            return [UIColor colorFromHexString:@"FFFF00"]; //yellow
        case 9:
            return [UIColor colorFromHexString:@"00FF00"]; //lime
        case 10:
            return [UIColor colorFromHexString:@"008080"]; //teal
        case 11:
            return [UIColor colorFromHexString:@"00FFFF"]; //cyan
        case 12:
            return [UIColor colorFromHexString:@"00BFFF"]; //blue (light = 0000FF) or #00bfff for dark
        case 13:
            return [UIColor colorFromHexString:@"FF00FF"]; //magenta
        case 14:
            return [UIColor colorFromHexString:@"808080"]; //grey
        case 15:
            return [UIColor colorFromHexString:@"C0C0C0"]; //silver
    }
    return nil;
}
+(UIColor *)errorBackgroundColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:1 green:0.933 blue:0.592 alpha:1];
    return c;
}
+(UIColor *)highlightBackgroundColor {
    return __highlightBackgroundColor;
}
+(UIColor *)statusBackgroundColor {
    return __color_background6a;
}
+(UIColor *)selfBackgroundColor {
    return __selfBackgroundColor;
}
+(UIColor *)noticeBackgroundColor {
    return __color_background5a;
}
+(UIColor *)highlightTimestampColor {
    return __highlightTimestampColor;
}
+(UIColor *)timestampBackgroundColor {
    if(!__timestampBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 26 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, __color_background6.CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,26));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, __color_border6.CGColor);
        CGContextSetLineWidth(context, 4.0);
        CGContextMoveToPoint(context, 0.0, 0.0);
        CGContextAddLineToPoint(context, width, 0.0);
        CGContextStrokePath(context);
        CGContextSetStrokeColorWithColor(context, __color_border9.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, 0.0, 26.0);
        CGContextAddLineToPoint(context, width, 26.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __timestampBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(1, 0, 1, 0)];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return [UIColor colorWithPatternImage:__timestampBackgroundImage];
}
+(UIColor *)newMsgsBackgroundColor {
    if(!__newMsgsBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 26 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, [self contentBackgroundColor].CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,26));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, [UIColor timestampColor].CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, 0.0, 13.0);
        CGContextAddLineToPoint(context, width, 13.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __newMsgsBackgroundImage = [UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return [UIColor colorWithPatternImage:__newMsgsBackgroundImage];
}
+(UIColor *)collapsedRowTextColor {
    return __color_text7;
}
+(UIColor *)collapsedHeadingBackgroundColor {
    return __color_background6;
}
+(UIColor *)navBarColor {
    return __color_background5;
}
+(UIImage *)navBarBackgroundImage {
    if(!__navbarBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 88 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, __color_background5.CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,88));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, __color_border10.CGColor);
        CGContextSetLineWidth(context, 4.0);
        CGContextMoveToPoint(context, 0.0, 0.0);
        CGContextAddLineToPoint(context, width, 0.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __navbarBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return __navbarBackgroundImage;
}
+(UIColor *)textareaTextColor {
    return __color_text3;
}
+(UIColor *)textareaBackgroundColor {
    return __color_theme_is_dark?__color_background3:__navbarSubheadingTextColor;
}
+(UIImage *)textareaBackgroundImage {
    if(!__textareaBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 44 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, [self textareaBackgroundColor].CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,44));
        if(!__color_theme_is_dark) {
            CGContextSetFillColorWithColor(context, [self contentBackgroundColor].CGColor);
            CGContextFillRect(context, CGRectMake(1,1,width-2,42));
        }
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __textareaBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return __textareaBackgroundImage;
}
+(UIColor *)navBarHeadingColor {
    return __color_text1;
}
+(UIColor *)navBarSubheadingColor {
    return __navbarSubheadingTextColor;
}
+(UIColor *)linkColor {
    return __linkColor;
}
+(UIColor *)lightLinkColor {
    return __color_text9;
}
+(UIColor *)unreadBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.071 green:0.243 blue:0.573 alpha:1];
    return c;
}
+(UIColor *)highlightBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.824 green:0 blue:0.016 alpha:1];
    return c;
}
+(UIColor *)networkErrorBorderColor{
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.859 green:0.702 blue:0 alpha:1];
    return c;
}
+(UIColor *)bufferTextColor {
    return __bufferTextColor;
}
+(UIColor *)inactiveBufferTextColor {
    return __inactiveBufferTextColor;
}
+(UIColor *)unreadBufferTextColor {
    return __color_text2;
}
+(UIColor *)selectedBufferTextColor {
    return __color_border8;
}
+(UIColor *)selectedBufferBackgroundColor {
    return __color_text3;
}
+(UIColor *)bufferBorderColor {
    return __color_border9;
}
+(UIColor *)selectedBufferBorderColor {
    return __color_border4;
}
+(UIColor *)backlogDividerColor {
    return __color_border1;
}
+(UIColor *)chatterBarTextColor {
    return __chatterBarTextColor;
}
+(UIColor *)chatterBarColor {
    return __color_background3;
}
+(UIColor *)awayBarTextColor {
    return __color_text7;
}
+(UIColor *)awayBarColor {
    return __color_background6;
}
+(UIColor *)connectionBarTextColor {
    return __color_text4;
}
+(UIColor *)connectionBarColor {
    return __color_background4;
}
+(UIColor *)connectionErrorBarTextColor {
    return __color_text4;
}
+(UIColor *)connectionErrorBarColor {
    return __color_background5;
}
+(UIColor *)buffersDrawerBackgroundColor {
    if(!__buffersDrawerBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 16 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, [self bufferBackgroundColor].CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,16));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, [self bufferBorderColor].CGColor);
        CGContextSetLineWidth(context, 6.0);
        CGContextMoveToPoint(context, 3.0, 0.0);
        CGContextAddLineToPoint(context, 3.0, 16.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __buffersDrawerBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return [UIColor colorWithPatternImage:__buffersDrawerBackgroundImage];
}
+(UIColor *)usersDrawerBackgroundColor {
    if(!__usersDrawerBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 16 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, [self membersGroupColor].CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,16));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, [self membersBorderColor].CGColor);
        CGContextSetLineWidth(context, 3.0);
        CGContextMoveToPoint(context, 1.0, 0.0);
        CGContextAddLineToPoint(context, 1.0, 16.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __usersDrawerBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return [UIColor colorWithPatternImage:__usersDrawerBackgroundImage];
}
+(UIColor *)iPadBordersColor {
    return __iPadBordersColor;
}
@end
