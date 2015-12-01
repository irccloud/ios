//
//  UIColor+IRCCloud.h
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


#import <UIKit/UIKit.h>

@interface UITableViewCell (IRCCloudAppearanceHax) <UIAppearance>
@property (strong, nonatomic) UIColor *textLabelColor UI_APPEARANCE_SELECTOR;
@property (strong, nonatomic) UIColor *detailTextLabelColor UI_APPEARANCE_SELECTOR;
@end

@interface UIColor (IRCCloud)
+(UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation lightness:(CGFloat)brightness alpha:(CGFloat)alpha;
+(BOOL)isDarkTheme;
+(void)setTheme:(NSString *)theme;
+(UIColor *)contentBackgroundColor;
+(UIColor *)messageTextColor;
+(UIColor *)opersGroupColor;
+(UIColor *)ownersGroupColor;
+(UIColor *)adminsGroupColor;
+(UIColor *)opsGroupColor;
+(UIColor *)halfopsGroupColor;
+(UIColor *)voicedGroupColor;
+(UIColor *)membersGroupColor;
+(UIColor *)opersBorderColor;
+(UIColor *)ownersBorderColor;
+(UIColor *)adminsBorderColor;
+(UIColor *)opsBorderColor;
+(UIColor *)halfopsBorderColor;
+(UIColor *)voicedBorderColor;
+(UIColor *)membersBorderColor;
+(UIColor *)memberListTextColor;
+(UIColor *)memberListAwayTextColor;
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
+(UIColor *)highlightTimestampColor;
+(UIColor *)noticeBackgroundColor;
+(UIColor *)timestampBackgroundColor;
+(UIColor *)newMsgsBackgroundColor;
+(UIColor *)collapsedRowTextColor;
+(UIColor *)collapsedHeadingBackgroundColor;
+(UIColor *)navBarColor;
+(UIColor *)navBarHeadingColor;
+(UIColor *)navBarSubheadingColor;
+(UIImage *)navBarBackgroundImage;
+(UIColor *)textareaTextColor;
+(UIImage *)textareaBackgroundImage;
+(UIColor *)textareaBackgroundColor;
+(UIColor *)linkColor;
+(UIColor *)lightLinkColor;
+(UIColor *)serverBackgroundColor;
+(UIColor *)bufferBackgroundColor;
+(UIColor *)unreadBorderColor;
+(UIColor *)highlightBorderColor;
+(UIColor *)networkErrorBorderColor;
+(UIColor *)bufferTextColor;
+(UIColor *)inactiveBufferTextColor;
+(UIColor *)unreadBufferTextColor;
+(UIColor *)selectedBufferTextColor;
+(UIColor *)selectedBufferBackgroundColor;
+(UIColor *)bufferBorderColor;
+(UIColor *)selectedBufferBorderColor;
+(UIColor *)serverBorderColor;
+(UIColor *)failedServerBorderColor;
+(UIColor *)backlogDividerColor;
+(UIColor *)chatterBarTextColor;
+(UIColor *)chatterBarColor;
+(UIColor *)awayBarTextColor;
+(UIColor *)awayBarColor;
+(UIColor *)connectionBarTextColor;
+(UIColor *)connectionBarColor;
+(UIColor *)connectionErrorBarTextColor;
+(UIColor *)connectionErrorBarColor;
+(UIColor *)buffersDrawerBackgroundColor;
+(UIColor *)usersDrawerBackgroundColor;
+(UIColor *)iPadBordersColor;
+(UIColor *)unreadBlueColor;
+(UIColor *)archivesHeadingTextColor;
+(UIColor *)archivedChannelTextColor;
+(UIColor *)archivedBufferTextColor;
+(UIColor *)selectedArchivesHeadingColor;
+(UIColor *)timestampTopBorderColor;
+(UIColor *)timestampBottomBorderColor;
+(UIActivityIndicatorViewStyle)activityIndicatorViewStyle;
+(UIColor *)expandCollapseIndicatorColor;
+(UIColor *)bufferHighlightColor;
+(UIColor *)selectedBufferHighlightColor;
+(UIColor *)archivedBufferHighlightColor;
+(UIColor *)selectedArchivedBufferHighlightColor;
+(UIColor *)selectedArchivedBufferBackgroundColor;
+(UIColor *)socketClosedBackgroundColor;
+(NSString *)currentTheme;
@end
