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

@implementation UITableViewCell (IRCCloudAppearanceHax)
- (UIColor *)textLabelColor {
    return self.textLabel.textColor;
}

- (void)setTextLabelColor:(UIColor *)textLabelColor {
    self.textLabel.textColor = textLabelColor;
}

- (UIColor *)detailTextLabelColor {
    return self.detailTextLabel.textColor;
}

- (void)setDetailTextLabelColor:(UIColor *)detailTextLabelColor {
    self.detailTextLabel.textColor = detailTextLabelColor;
}
@end

@implementation UIColor (IRCCloud)
+(UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)light alpha:(CGFloat)alpha {
    saturation *= (light < 0.5)?light:(1-light);
    
    return [UIColor colorWithHue:hue saturation:(2*saturation)/(light+saturation) brightness:light+saturation alpha:alpha];
}

+(void)setDarkTheme:(NSString *)theme {
    __timestampBackgroundImage = nil;
    __newMsgsBackgroundImage = nil;
    __navbarBackgroundImage = nil;
    __textareaBackgroundImage = nil;

    //Default to Dusk
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
    
    [[UINavigationBar appearance] setBackgroundImage:[self navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [self navBarHeadingColor]}];
    [[UINavigationBar appearance] setTintColor:[UIColor navBarSubheadingColor]];

    [[UITableView appearance] setBackgroundColor:__color_background7];
    [[UITableView appearance] setSeparatorColor:__color_border11];
    [[UITableViewCell appearance] setBackgroundColor:__color_background6];
    [[UITableViewCell appearance] setTextLabelColor:__color_text4];
    [[UITableViewCell appearance] setDetailTextLabelColor:__color_text7];
    [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:__color_text8];
    [[UISwitch appearance] setOnTintColor:__color_text7];
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
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:1 green:0.859 blue:0.78 alpha:1];
    return c;
}
+(UIColor *)ownersGroupColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
    return c;
}
+(UIColor *)adminsGroupColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.929 green:0.8 blue:1 alpha:1];
    return c;
}
+(UIColor *)opsGroupColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.949 blue:0.949 alpha:1];
    return c;
}
+(UIColor *)halfopsGroupColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.929 blue:0.855 alpha:1];
    return c;
}
+(UIColor *)voicedGroupColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.957 green:1 blue:0.929 alpha:1];
    return c;
}
+(UIColor *)opersHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.878 green:0.137 blue:0.02 alpha:1];
    return c;
}
+(UIColor *)ownersHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.906 green:0.667 blue:0 alpha:1];
    return c;
}
+(UIColor *)adminsHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.396 green:0 blue:0.647 alpha:1];
    return c;
}
+(UIColor *)opsHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.729 green:0.09 blue:0.098 alpha:1];
    return c;
}
+(UIColor *)halfopsHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.71 green:0.349 blue:0 alpha:1];
    return c;
}
+(UIColor *)voicedHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.145 green:0.694 blue:0 alpha:1];
    return c;
}
+(UIColor *)membersHeadingColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    return c;
}
+(UIColor *)opersBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.686 blue:0.384 alpha:1];
    return c;
}
+(UIColor *)ownersBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.89 blue:0.455 alpha:1]; /*#fee374*/
    return c;
}
+(UIColor *)opersLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.847 blue:0.361 alpha:1];
    return c;
}
+(UIColor *)ownersLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.996 green:0.847 blue:0.361 alpha:1]; /*#fed85c*/
    return c;
}
+(UIColor *)adminsBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.776 green:0.616 blue:1 alpha:1]; /*#c69dff*/
    return c;
}
+(UIColor *)adminsLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.71 green:0.502 blue:1 alpha:1]; /*#b580ff*/
    return c;
}
+(UIColor *)opsBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.98 green:0.788 blue:0.796 alpha:1]; /*#fac9cb*/
    return c;
}
+(UIColor *)opsLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.988 green:0.678 blue:0.686 alpha:1]; /*#fcadaf*/
    return c;
}
+(UIColor *)halfopsBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.969 green:0.843 blue:0.671 alpha:1]; /*#f7d7ab*/
    return c;
}
+(UIColor *)halfopsLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.992 green:0.8 blue:0.604 alpha:1]; /*#fdcc9a*/
    return c;
}
+(UIColor *)voicedBorderColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.557 green:0.992 blue:0.537 alpha:1]; /*#8efd89*/
    return c;
}
+(UIColor *)voicedLightColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:0.62 green:0.922 blue:0.29 alpha:1]; /*#9eeb4a*/
    return c;
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
    return __color_background5;
}
+(UIColor *)statusBackgroundColor {
    return __color_background6a;
}
+(UIColor *)selfBackgroundColor {
    return __color_background6;
}
+(UIColor *)noticeBackgroundColor {
    return __color_background5a;
}
+(UIColor *)highlightTimestampColor {
    static UIColor *c = nil;
    if(!c)
        c = [UIColor colorWithRed:1 green:0.878 blue:0.878 alpha:1];
    return c;
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
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __timestampBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)];
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
        CGContextMoveToPoint(context, 0.0, 11.0);
        CGContextAddLineToPoint(context, width, 11.0);
        CGContextStrokePath(context);
        CGContextMoveToPoint(context, 0.0, 15.0);
        CGContextAddLineToPoint(context, width, 15.0);
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
    return __color_background3;
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
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __textareaBackgroundImage = [[UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)];
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
    return __color_text4;
}
+(UIColor *)linkColor {
    return __color_text1;
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
    return __color_text4;
}
+(UIColor *)inactiveBufferTextColor {
    return __color_text9;
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

@end
