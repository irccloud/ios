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

@implementation UIColor (IRCCloud)
+(UIColor *)backgroundBlueColor {
    return [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
}
+(UIColor *)selectedBlueColor {
    return [UIColor colorWithRed:0.322 green:0.49 blue:1 alpha:1];
}
+(UIColor *)blueBorderColor {
    return [UIColor colorWithRed:0.753 green:0.824 blue:1 alpha:1]; /*#c0d2ff*/
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
+(UIColor *)ownersBorderColor {
    return [UIColor colorWithRed:0.996 green:0.89 blue:0.455 alpha:1]; /*#fee374*/
}
+(UIColor *)ownersLightColor {
    return [UIColor colorWithRed:0.996 green:0.847 blue:0.361 alpha:1]; /*#fed85c*/
}
+(UIColor *)adminsBorderColor {
    return [UIColor colorWithRed:0.776 green:0.616 blue:1 alpha:1]; /*#c69dff*/
}
+(UIColor *)adminsLightColor {
    return [UIColor colorWithRed:0.71 green:0.502 blue:1 alpha:1]; /*#b580ff*/
}
+(UIColor *)opsBorderColor {
    return [UIColor colorWithRed:0.98 green:0.788 blue:0.796 alpha:1]; /*#fac9cb*/
}
+(UIColor *)opsLightColor {
    return [UIColor colorWithRed:0.988 green:0.678 blue:0.686 alpha:1]; /*#fcadaf*/
}
+(UIColor *)halfopsBorderColor {
    return [UIColor colorWithRed:0.969 green:0.843 blue:0.671 alpha:1]; /*#f7d7ab*/
}
+(UIColor *)halfopsLightColor {
    return [UIColor colorWithRed:0.992 green:0.8 blue:0.604 alpha:1]; /*#fdcc9a*/
}
+(UIColor *)voicedBorderColor {
    return [UIColor colorWithRed:0.557 green:0.992 blue:0.537 alpha:1]; /*#8efd89*/
}
+(UIColor *)voicedLightColor {
    return [UIColor colorWithRed:0.62 green:0.922 blue:0.29 alpha:1]; /*#9eeb4a*/
}
+(UIColor *)timestampColor {
    return [UIColor colorWithRed:0.667 green:0.667 blue:0.667 alpha:1];
}
+(UIColor *)darkBlueColor {
    return [UIColor colorWithRed:0.094 green:0.247 blue:0.553 alpha:1.0]; /*#183f8d*/
}
+(UIColor *)networkErrorBackgroundColor {
    return [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
}
+(UIColor *)networkErrorColor {
    return [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
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
            return [UIColor colorFromHexString:@"800080"]; //purple
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
            return [UIColor colorFromHexString:@"0000FF"]; //blue
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
    return [UIColor colorWithRed:1 green:0.933 blue:0.592 alpha:1];
}
+(UIColor *)highlightBackgroundColor {
    return [UIColor colorWithRed:0.753 green:0.859 blue:1 alpha:1];
}
+(UIColor *)statusBackgroundColor {
    return [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
}
+(UIColor *)selfBackgroundColor {
    return [UIColor colorWithRed:0.886 green:0.929 blue:1 alpha:1];
}
+(UIColor *)noticeBackgroundColor {
    return [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
}
+(UIColor *)highlightTimestampColor {
    return [UIColor colorWithRed:0.376 green:0 blue:0 alpha:1];
}
+(UIColor *)timestampBackgroundColor {
    if(!__timestampBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 26 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1].CGColor, (id)[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1].CGColor, nil];
        CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)(colors), NULL);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0.0f, 26.0f), CGPointMake(0.0f, 0.0f), 0);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __timestampBackgroundImage = [UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp];
        CFRelease(cgImage);
        CFRelease(gradient);
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
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
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
+(UIColor *)collapsedRowBackgroundColor {
    return [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1];
}
+(UIColor *)collapsedHeadingBackgroundColor {
    return [UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1];
}
+(UIColor *)navBarColor {
    return [UIColor colorWithRed:242.0/255.0 green:247.0/255.0 blue:252.0/255.0 alpha:1];
}
+(UIColor *)lightLinkColor {
    return [UIColor colorWithRed:0.612 green:0.78 blue:1 alpha:1];
}
@end
