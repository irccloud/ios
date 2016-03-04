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
UIImage *__socketClosedBackgroundImage;

UIColor *__contentBackgroundColor;
UIColor *__messageTextColor;
UIColor *__opersGroupColor;
UIColor *__ownersGroupColor;
UIColor *__adminsGroupColor;
UIColor *__opsGroupColor;
UIColor *__halfopsGroupColor;
UIColor *__voicedGroupColor;
UIColor *__membersGroupColor;
UIColor *__opersBorderColor;
UIColor *__ownersBorderColor;
UIColor *__adminsBorderColor;
UIColor *__opsBorderColor;
UIColor *__halfopsBorderColor;
UIColor *__voicedBorderColor;
UIColor *__membersBorderColor;
UIColor *__memberListTextColor;
UIColor *__memberListAwayTextColor;
UIColor *__timestampColor;
UIColor *__darkBlueColor;
UIColor *__networkErrorBackgroundColor;
UIColor *__networkErrorColor;
UIColor *__errorBackgroundColor;
UIColor *__statusBackgroundColor;
UIColor *__selfBackgroundColor;
UIColor *__highlightBackgroundColor;
UIColor *__highlightTimestampColor;
UIColor *__noticeBackgroundColor;
UIColor *__timestampBackgroundColor;
UIColor *__newMsgsBackgroundColor;
UIColor *__collapsedRowTextColor;
UIColor *__collapsedHeadingBackgroundColor;
UIColor *__navBarColor;
UIColor *__navBarHeadingColor;
UIColor *__navBarSubheadingColor;
UIColor *__navBarBorderColor;
UIColor *__textareaTextColor;
UIColor *__textareaBackgroundColor;
UIColor *__linkColor;
UIColor *__lightLinkColor;
UIColor *__serverBackgroundColor;
UIColor *__bufferBackgroundColor;
UIColor *__unreadBorderColor;
UIColor *__highlightBorderColor;
UIColor *__networkErrorBorderColor;
UIColor *__bufferTextColor;
UIColor *__inactiveBufferTextColor;
UIColor *__unreadBufferTextColor;
UIColor *__selectedBufferTextColor;
UIColor *__selectedBufferBackgroundColor;
UIColor *__bufferBorderColor;
UIColor *__selectedBufferBorderColor;
UIColor *__backlogDividerColor;
UIColor *__chatterBarTextColor;
UIColor *__chatterBarColor;
UIColor *__awayBarTextColor;
UIColor *__awayBarColor;
UIColor *__connectionBarTextColor;
UIColor *__connectionBarColor;
UIColor *__connectionErrorBarTextColor;
UIColor *__connectionErrorBarColor;
UIColor *__buffersDrawerBackgroundColor;
UIColor *__usersDrawerBackgroundColor;
UIColor *__iPadBordersColor;
UIColor *__placeholderColor;
UIColor *__unreadBlueColor;
UIColor *__serverBorderColor;
UIColor *__failedServerBorderColor;
UIColor *__archivesHeadingTextColor;
UIColor *__archivedChannelTextColor;
UIColor *__archivedBufferTextColor;
UIColor *__selectedArchivesHeadingColor;
UIColor *__timestampTopBorderColor;
UIColor *__timestampBottomBorderColor;
UIColor *__expandCollapseIndicatorColor;
UIColor *__bufferHighlightColor;
UIColor *__selectedBufferHighlightColor;
UIColor *__archivedBufferHighlightColor;
UIColor *__selectedArchivedBufferHighlightColor;
UIColor *__selectedArchivedBufferBackgroundColor;

BOOL __color_theme_is_dark;

NSString *__current_theme;

@implementation UITextField (IRCCloudAppearanceHax)
-(void)setPlaceholder:(NSString *)placeholder {
    [self setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:placeholder?placeholder:@"" attributes:@{NSForegroundColorAttributeName:__placeholderColor}]];
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
    if([theme isEqualToString:@"dawn"] || theme == nil) {
        __color_theme_is_dark = NO;
        
        __bufferTextColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __inactiveBufferTextColor = [UIColor colorWithRed:0.612 green:0.78 blue:1 alpha:1];
        __iPadBordersColor = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __navBarSubheadingColor = [UIColor colorWithWhite:0.467 alpha:1.0];
        __chatterBarTextColor = [UIColor colorWithRed:0 green:0.129 blue:0.475 alpha:1];
        __linkColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __highlightTimestampColor = [UIColor colorWithRed:0.376 green:0 blue:0 alpha:1];
        __highlightBackgroundColor = [UIColor colorWithRed:0.753 green:0.859 blue:1 alpha:1];
        __selfBackgroundColor = [UIColor colorWithRed:0.886 green:0.929 blue:1 alpha:1];
        
        __contentBackgroundColor = [UIColor whiteColor];
        __messageTextColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        __serverBackgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __bufferBackgroundColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __memberListTextColor = [UIColor colorWithWhite:0.133 alpha:1.0];
        __memberListAwayTextColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __timestampColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __timestampBackgroundColor = [UIColor whiteColor];
        __statusBackgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __noticeBackgroundColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __collapsedRowTextColor = [UIColor colorWithWhite:0.686 alpha:1.0];
        __collapsedHeadingBackgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __navBarColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __navBarBorderColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __textareaTextColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        __textareaBackgroundColor = __navBarSubheadingColor;
        __navBarHeadingColor = [UIColor colorWithWhite:0.133 alpha:1.0];
        __lightLinkColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __unreadBufferTextColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        __selectedBufferTextColor = [UIColor whiteColor];
        __selectedBufferBackgroundColor = [UIColor colorWithRed:0.118 green:0.447 blue:1 alpha:1];
        __bufferBorderColor = [UIColor colorWithRed:0.702 green:0.812 blue:1 alpha:1];
        __selectedBufferBorderColor = [UIColor colorWithRed:0.243 green:0.047 blue:1 alpha:1];
        __serverBorderColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __failedServerBorderColor = [UIColor colorWithRed:0.906 green:0.667 blue:0 alpha:1];
        __backlogDividerColor = [UIColor colorWithRed:0.404 green:0.624 blue:1 alpha:1];
        __chatterBarColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __awayBarTextColor = [UIColor colorWithWhite:0.686 alpha:1.0];
        __awayBarColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
        __connectionBarTextColor = [UIColor colorWithRed:0.071 green:0.243 blue:0.573 alpha:1];
        __connectionBarColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __connectionErrorBarTextColor = [UIColor colorWithRed:0.388 green:0.157 blue:0 alpha:1];
        __connectionErrorBarColor = [UIColor colorWithRed:0.973 green:0.875 blue:0.149 alpha:1];
        __errorBackgroundColor = [UIColor colorWithRed:1 green:0.996 blue:0.914 alpha:1];
        __archivesHeadingTextColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        __archivedChannelTextColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __archivedBufferTextColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        __selectedArchivesHeadingColor = [UIColor colorWithRed:0.867 green:0.867 blue:0.867 alpha:1];
        __timestampTopBorderColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __timestampBottomBorderColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        __placeholderColor = [UIColor colorWithRed:0.78 green:0.78 blue:0.804 alpha:1];
        __expandCollapseIndicatorColor = [UIColor colorWithRed:0.702 green:0.812 blue:1 alpha:1];
        __bufferHighlightColor = [UIColor colorWithRed:0.776 green:0.855 blue:1 alpha:1];
        __selectedBufferHighlightColor = [UIColor colorWithRed:0.118 green:0.447 blue:1 alpha:1];
        __archivedBufferHighlightColor = [UIColor colorWithRed:0.776 green:0.855 blue:1 alpha:1];
        __selectedArchivedBufferHighlightColor = [UIColor colorWithWhite:0.667 alpha:1];
        __selectedArchivedBufferBackgroundColor = [UIColor colorWithWhite:0.667 alpha:1];
        
        __opersBorderColor = [UIColor colorWithRed:0.878 green:0.137 blue:0.02 alpha:1];
        __ownersBorderColor = [UIColor colorWithRed:0.906 green:0.667 blue:0 alpha:1];
        __adminsBorderColor = [UIColor colorWithRed:0.396 green:0 blue:0.647 alpha:1];
        __opsBorderColor = [UIColor colorWithRed:0.729 green:0.09 blue:0.098 alpha:1];
        __halfopsBorderColor = [UIColor colorWithRed:0.71 green:0.349 blue:0 alpha:1];
        __voicedBorderColor = [UIColor colorWithRed:0.145 green:0.694 blue:0 alpha:1];
        __membersBorderColor = [UIColor colorWithRed:0.114 green:0.251 blue:1 alpha:1];
        
        __opersGroupColor = [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
        __ownersGroupColor = [UIColor colorWithRed:1 green:1 blue:0.82 alpha:1];
        __adminsGroupColor = [UIColor colorWithRed:0.929 green:0.8 blue:1 alpha:1];
        __opsGroupColor = [UIColor colorWithRed:0.996 green:0.949 blue:0.949 alpha:1];
        __halfopsGroupColor = [UIColor colorWithRed:1 green:0.98 blue:0.949 alpha:1];
        __voicedGroupColor = [UIColor colorWithRed:0.957 green:1 blue:0.929 alpha:1];
        __membersGroupColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        
        [[UITableView appearance] setBackgroundColor:[UIColor colorWithRed:0.937 green:0.937 blue:0.957 alpha:1]];
        [[UITableView appearance] setSeparatorColor:nil];
        [[UITableViewCell appearance] setBackgroundColor:[UIColor whiteColor]];
        [[UITableViewCell appearance] setSelectedBackgroundView:nil];
        [[UITableViewCell appearance] setTextLabelColor:__messageTextColor];
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
        UIColor *color_border1;
        UIColor *color_border2;
        UIColor *color_border3;
        UIColor *color_border4;
        UIColor *color_border5;
        UIColor *color_border6;
        UIColor *color_border7;
        UIColor *color_border8;
        UIColor *color_border9;
        UIColor *color_border10;
        UIColor *color_border11;
        
        UIColor *color_text1;
        UIColor *color_text2;
        UIColor *color_text3;
        UIColor *color_text4;
        UIColor *color_text5;
        UIColor *color_text6;
        UIColor *color_text7;
        UIColor *color_text8;
        UIColor *color_text9;
        UIColor *color_text10;
        UIColor *color_text11;
        UIColor *color_text12;
        
        UIColor *color_background0;
        UIColor *color_background1;
        UIColor *color_background2;
        UIColor *color_background3;
        UIColor *color_background4;
        UIColor *color_background5;
        UIColor *color_background5a;
        UIColor *color_background6;
        UIColor *color_background6a;
        UIColor *color_background7;
        
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
        
        color_border1 = [UIColor colorWithHue:hue saturation:saturation lightness:0.55f alpha:1.0f];
        color_border2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        color_border3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        color_border4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.40f alpha:1.0f];
        color_border5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.35f alpha:1.0f];
        color_border6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.30f alpha:1.0f];
        color_border7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.25f alpha:1.0f];
        color_border8 = [UIColor colorWithHue:hue saturation:saturation lightness:0.20f alpha:1.0f];
        color_border9 = [UIColor colorWithHue:hue saturation:saturation lightness:0.15f alpha:1.0f];
        color_border10 = [UIColor colorWithHue:hue saturation:saturation lightness:0.10f alpha:1.0f];
        color_border11 = [UIColor colorWithHue:hue saturation:saturation lightness:0.05f alpha:1.0f];
        
        color_text1 = [UIColor colorWithHue:hue saturation:saturation lightness:1.0f alpha:1.0f];
        color_text2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.95f alpha:1.0f];
        color_text3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.90f alpha:1.0f];
        color_text4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.85f alpha:1.0f];
        color_text5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.80f alpha:1.0f];
        color_text6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.75f alpha:1.0f];
        color_text7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.70f alpha:1.0f];
        color_text8 = [UIColor colorWithHue:hue saturation:saturation lightness:0.65f alpha:1.0f];
        color_text9 = [UIColor colorWithHue:hue saturation:saturation lightness:0.60f alpha:1.0f];
        color_text10 = [UIColor colorWithHue:hue saturation:saturation lightness:0.55f alpha:1.0f];
        color_text11 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        color_text12 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        
        color_background0 = [UIColor colorWithHue:hue saturation:saturation lightness:0.50f alpha:1.0f];
        color_background1 = [UIColor colorWithHue:hue saturation:saturation lightness:0.45f alpha:1.0f];
        color_background2 = [UIColor colorWithHue:hue saturation:saturation lightness:0.40f alpha:1.0f];
        color_background3 = [UIColor colorWithHue:hue saturation:saturation lightness:0.35f alpha:1.0f];
        color_background4 = [UIColor colorWithHue:hue saturation:saturation lightness:0.30f alpha:1.0f];
        color_background5 = [UIColor colorWithHue:hue saturation:saturation lightness:0.25f alpha:1.0f];
        color_background5a = [UIColor colorWithHue:hue saturation:saturation lightness:0.23f alpha:1.0f];
        color_background6 = [UIColor colorWithHue:hue saturation:saturation lightness:0.20f alpha:1.0f];
        color_background6a = [UIColor colorWithHue:hue saturation:saturation lightness:0.17f alpha:1.0f];
        color_background7 = [UIColor colorWithHue:hue saturation:saturation lightness:0.15f alpha:1.0f];
        
        __color_theme_is_dark = YES;

        __iPadBordersColor = color_background7;
        __bufferTextColor = __navBarSubheadingColor = color_text4;
        __inactiveBufferTextColor = __archivesHeadingTextColor = color_text9;
        __chatterBarTextColor = color_text5;
        __linkColor = color_text1;
        __highlightTimestampColor = [UIColor colorWithRed:1 green:0.878 blue:0.878 alpha:1];
        __highlightBackgroundColor = color_background5;
        __selfBackgroundColor = color_background6;
        
        __contentBackgroundColor = color_background7;
        __messageTextColor = color_text4;
        __serverBackgroundColor = color_background6;
        __bufferBackgroundColor = color_background4;
        __memberListTextColor = color_text5;
        __memberListAwayTextColor = color_text9;
        __timestampColor = color_text10;
        __timestampBackgroundColor = color_background6;
        __statusBackgroundColor = color_background6a;
        __noticeBackgroundColor = color_background5a;
        __collapsedRowTextColor = color_text7;
        __collapsedHeadingBackgroundColor = color_background6;
        __navBarColor = color_background5;
        __navBarBorderColor = color_border10;
        __textareaTextColor = color_text3;
        __textareaBackgroundColor = color_background3;
        __navBarHeadingColor = color_text1;
        __lightLinkColor = color_text9;
        __unreadBufferTextColor = color_text2;
        __selectedBufferTextColor = color_border8;
        __selectedBufferBackgroundColor = color_text3;
        __bufferBorderColor = __serverBorderColor = __failedServerBorderColor = color_border9;
        __selectedBufferBorderColor = color_border4;
        __backlogDividerColor = color_border1;
        __chatterBarColor = color_background3;
        __awayBarTextColor = color_text7;
        __awayBarColor = color_background6;
        __connectionBarTextColor = color_text4;
        __connectionBarColor = color_background4;
        __connectionErrorBarTextColor = color_text4;
        __connectionErrorBarColor = color_background5;
        __errorBackgroundColor = [UIColor colorWithRed:0.698 green:0.698 blue:0.204 alpha:1];
        __archivedChannelTextColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __archivedBufferTextColor = [UIColor colorWithWhite:0.667 alpha:1.0];
        __selectedArchivesHeadingColor = [UIColor colorWithRed:0.867 green:0.867 blue:0.867 alpha:1];
        __timestampTopBorderColor = color_border9;
        __timestampBottomBorderColor = color_border6;
        __placeholderColor = color_text12;
        __expandCollapseIndicatorColor = color_text12;
        __bufferHighlightColor = color_background5;
        __selectedBufferHighlightColor = color_text4;
        __archivedBufferHighlightColor = color_background5;
        __selectedArchivedBufferHighlightColor = color_text6;
        __selectedArchivedBufferBackgroundColor = color_text6;

        __opersBorderColor = [UIColor colorWithHue:30.0/360.0 saturation:0.85 lightness:0.25 alpha:1.0];
        __ownersBorderColor = [UIColor colorWithHue:47.0/360.0 saturation:0.68 lightness:0.25 alpha:1.0];
        __adminsBorderColor = [UIColor colorWithHue:265.0/360.0 saturation:0.44 lightness:0.36 alpha:1.0];
        __opsBorderColor = [UIColor colorWithHue:0 saturation:0.36 lightness:0.38 alpha:1.0];
        __halfopsBorderColor = [UIColor colorWithHue:37.0/360.0 saturation:0.45 lightness:0.28 alpha:1.0];
        __voicedBorderColor = [UIColor colorWithHue:85.0/360.0 saturation:1.0 lightness:0.17 alpha:1.0];
        __membersBorderColor = [UIColor colorWithHue:221.0/360.0 saturation:0.55 lightness:0.23 alpha:1.0];

        __opersGroupColor = [UIColor colorWithHue:27.0/360.0 saturation:0.64 lightness:0.16 alpha:1.0];
        __ownersGroupColor = [UIColor colorWithHue:45.0/360.0 saturation:0.29 lightness:0.19 alpha:1.0];
        __adminsGroupColor = [UIColor colorWithHue:276.0/360.0 saturation:0.27 lightness:0.15 alpha:1.0];
        __opsGroupColor = [UIColor colorWithHue:0 saturation:0.42 lightness:0.19 alpha:1.0];
        __halfopsGroupColor = [UIColor colorWithHue:37.0/360.0 saturation:0.26 lightness:0.17 alpha:1.0];
        __voicedGroupColor = [UIColor colorWithHue:94.0/360.0 saturation:0.25 lightness:0.16 alpha:1.0];
        __membersGroupColor = [UIColor colorWithHue:217.0/360.0 saturation:0.30 lightness:0.15 alpha:1.0];
        
        [[UITableView appearance] setBackgroundColor:color_background7];
        [[UITableView appearance] setSeparatorColor:color_border11];
        [[UITableViewCell appearance] setBackgroundColor:color_background6];
        UIView *v = [[UIView alloc]initWithFrame:CGRectZero];
        v.backgroundColor = color_background7;
        [[UITableViewCell appearance] setSelectedBackgroundView:v];
        [[UITableViewCell appearance] setTextLabelColor:color_text4];
        [[UITableViewCell appearance] setDetailTextLabelColor:color_text7];
        [[UITableViewCell appearance] setTintColor:color_text7];
        [[UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil] setTextColor:color_text8];
        [[UISwitch appearance] setOnTintColor:color_text7];
        [[UISlider appearance] setTintColor:color_text7];
        
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
    }
    
    __timestampBackgroundImage = nil;
    __newMsgsBackgroundImage = nil;
    __navbarBackgroundImage = nil;
    __textareaBackgroundImage = nil;
    __buffersDrawerBackgroundImage = nil;
    __usersDrawerBackgroundImage = nil;
    __socketClosedBackgroundImage = nil;
    __unreadBlueColor = [UIColor colorWithRed:0.118 green:0.447 blue:1 alpha:1];
    
    __current_theme = theme?theme:@"dawn";
}

+(NSString *)currentTheme {
    return __current_theme;
}

+(UIColor *)contentBackgroundColor {
    return __contentBackgroundColor;
}

+(UIColor *)messageTextColor {
    return __messageTextColor;
}

+(UIColor *)opersGroupColor {
    return __opersGroupColor;
}
+(UIColor *)ownersGroupColor {
    return __ownersGroupColor;
}
+(UIColor *)adminsGroupColor {
    return __adminsGroupColor;
}
+(UIColor *)opsGroupColor {
    return __opsGroupColor;
}
+(UIColor *)halfopsGroupColor {
    return __halfopsGroupColor;
}
+(UIColor *)voicedGroupColor {
    return __voicedGroupColor;
}
+(UIColor *)membersGroupColor {
    return __membersGroupColor;
}
+(UIColor *)opersBorderColor {
    return __opersBorderColor;
}
+(UIColor *)ownersBorderColor {
    return __ownersBorderColor;
}
+(UIColor *)adminsBorderColor {
    return __adminsBorderColor;
}
+(UIColor *)opsBorderColor {
    return __opsBorderColor;
}
+(UIColor *)halfopsBorderColor {
    return __halfopsBorderColor;
}
+(UIColor *)voicedBorderColor {
    return __voicedBorderColor;
}
+(UIColor *)membersBorderColor {
    return __membersBorderColor;
}
+(UIColor *)memberListTextColor {
    return __memberListTextColor;
}
+(UIColor *)memberListAwayTextColor {
    return __memberListAwayTextColor;
}
+(UIColor *)timestampColor {
    return __timestampColor;
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
    return __serverBackgroundColor;
}
+(UIColor *)bufferBackgroundColor {
    return __bufferBackgroundColor;
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
            return __color_theme_is_dark?[UIColor colorFromHexString:@"4682B4"]:[UIColor colorFromHexString:@"000080"]; //steelblue or navy
        case 3:
            return __color_theme_is_dark?[UIColor colorFromHexString:@"32CD32"]:[UIColor colorFromHexString:@"008000"]; //limegreen or green
        case 4:
            return [UIColor colorFromHexString:@"FF0000"]; //red
        case 5:
            return __color_theme_is_dark?[UIColor colorFromHexString:@"FA8072"]:[UIColor colorFromHexString:@"800000"]; //salmon or maroon
        case 6:
            return __color_theme_is_dark?[UIColor colorFromHexString:@"DA70D6"]:[UIColor colorFromHexString:@"800080"]; //orchird or purple
        case 7:
            return [UIColor colorFromHexString:@"FFA500"]; //orange
        case 8:
            return [UIColor colorFromHexString:@"FFFF00"]; //yellow
        case 9:
            return [UIColor colorFromHexString:@"00FF00"]; //lime
        case 10:
            return __color_theme_is_dark?[UIColor colorFromHexString:@"20B2AA"]:[UIColor colorFromHexString:@"008080"]; //lightseagreen or teal
        case 11:
            return [UIColor colorFromHexString:@"00FFFF"]; //cyan
        case 12:
            return __color_theme_is_dark?[UIColor colorFromHexString:@"00BFFF"]:[UIColor colorFromHexString:@"0000FF"]; //deepskyblue or blue
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
    return __errorBackgroundColor;
}
+(UIColor *)highlightBackgroundColor {
    return __highlightBackgroundColor;
}
+(UIColor *)statusBackgroundColor {
    return __statusBackgroundColor;
}
+(UIColor *)selfBackgroundColor {
    return __selfBackgroundColor;
}
+(UIColor *)noticeBackgroundColor {
    return __noticeBackgroundColor;
}
+(UIColor *)highlightTimestampColor {
    return __highlightTimestampColor;
}
+(UIColor *)timestampBackgroundColor {
    return __timestampBackgroundColor;
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
+(UIColor *)socketClosedBackgroundColor {
    if(!__socketClosedBackgroundImage) {
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
        CGContextMoveToPoint(context, 0.0, 12.0);
        CGContextAddLineToPoint(context, width, 12.0);
        CGContextMoveToPoint(context, 0.0, 14.0);
        CGContextAddLineToPoint(context, width, 14.0);
        CGContextStrokePath(context);
        CGImageRef cgImage = CGBitmapContextCreateImage(context);
        __socketClosedBackgroundImage = [UIImage imageWithCGImage:cgImage scale:scaleFactor orientation:UIImageOrientationUp];
        CFRelease(cgImage);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
    }
    return [UIColor colorWithPatternImage:__socketClosedBackgroundImage];
}
+(UIColor *)collapsedRowTextColor {
    return __collapsedRowTextColor;
}
+(UIColor *)collapsedHeadingBackgroundColor {
    return __collapsedHeadingBackgroundColor;
}
+(UIColor *)navBarColor {
    return __navBarColor;
}
+(UIImage *)navBarBackgroundImage {
    if(!__navbarBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 88 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, __navBarColor.CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,88));
        CGContextSetLineCap(context, kCGLineCapSquare);
        CGContextSetStrokeColorWithColor(context, __navBarBorderColor.CGColor);
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
    return __textareaTextColor;
}
+(UIColor *)textareaBackgroundColor {
    return __textareaBackgroundColor;
}
+(UIImage *)textareaBackgroundImage {
    if(!__textareaBackgroundImage) {
        float scaleFactor = [[UIScreen mainScreen] scale];
        int width = [[UIScreen mainScreen] bounds].size.width;
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(NULL, width * scaleFactor, 44 * scaleFactor, 8, 4 * width * scaleFactor, colorSpace, (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
        CGContextScaleCTM(context, scaleFactor, scaleFactor);
        CGContextSetFillColorWithColor(context, __textareaBackgroundColor.CGColor);
        CGContextFillRect(context, CGRectMake(0,0,width,44));
        if(!__color_theme_is_dark) {
            CGContextSetFillColorWithColor(context, __contentBackgroundColor.CGColor);
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
    return __navBarHeadingColor;
}
+(UIColor *)navBarSubheadingColor {
    return __navBarSubheadingColor;
}
+(UIColor *)linkColor {
    return __linkColor;
}
+(UIColor *)lightLinkColor {
    return __lightLinkColor;
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
    return __unreadBufferTextColor;
}
+(UIColor *)selectedBufferTextColor {
    return __selectedBufferTextColor;
}
+(UIColor *)selectedBufferBackgroundColor {
    return __selectedBufferBackgroundColor;
}
+(UIColor *)bufferBorderColor {
    return __bufferBorderColor;
}
+(UIColor *)selectedBufferBorderColor {
    return __selectedBufferBorderColor;
}
+(UIColor *)backlogDividerColor {
    return __backlogDividerColor;
}
+(UIColor *)chatterBarTextColor {
    return __chatterBarTextColor;
}
+(UIColor *)chatterBarColor {
    return __chatterBarColor;
}
+(UIColor *)awayBarTextColor {
    return __awayBarTextColor;
}
+(UIColor *)awayBarColor {
    return __awayBarColor;
}
+(UIColor *)connectionBarTextColor {
    return __connectionBarTextColor;
}
+(UIColor *)connectionBarColor {
    return __connectionBarColor;
}
+(UIColor *)connectionErrorBarTextColor {
    return __connectionErrorBarTextColor;
}
+(UIColor *)connectionErrorBarColor {
    return __connectionErrorBarColor;
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
    if(!__color_theme_is_dark)
        return [self membersGroupColor];
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
+(UIColor *)unreadBlueColor {
    return __unreadBlueColor;
}
+(UIColor *)serverBorderColor {
    return __serverBorderColor;
}
+(UIColor *)failedServerBorderColor {
    return __failedServerBorderColor;
}
+(UIColor *)archivesHeadingTextColor {
    return __archivesHeadingTextColor;
}
+(UIColor *)archivedChannelTextColor {
    return __archivedChannelTextColor;
}
+(UIColor *)archivedBufferTextColor {
    return __archivedBufferTextColor;
}
+(UIColor *)selectedArchivesHeadingColor {
    return __selectedArchivesHeadingColor;
}
+(UIColor *)timestampTopBorderColor {
    return __timestampTopBorderColor;
}
+(UIColor *)timestampBottomBorderColor {
    return __timestampBottomBorderColor;
}
+(UIActivityIndicatorViewStyle)activityIndicatorViewStyle {
    return __color_theme_is_dark?UIActivityIndicatorViewStyleWhite:UIActivityIndicatorViewStyleGray;
}
+(UIColor *)expandCollapseIndicatorColor {
    return __expandCollapseIndicatorColor;
}
+(UIColor *)bufferHighlightColor {
    return __bufferHighlightColor;
}
+(UIColor *)selectedBufferHighlightColor {
    return __selectedBufferHighlightColor;
}
+(UIColor *)archivedBufferHighlightColor {
    return __archivedBufferHighlightColor;
}
+(UIColor *)selectedArchivedBufferHighlightColor {
    return __selectedArchivedBufferHighlightColor;
}
+(UIColor *)selectedArchivedBufferBackgroundColor {
    return __selectedArchivedBufferBackgroundColor;
}

@end
