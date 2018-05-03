//
//  ColorFormatter.h
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

#import <Foundation/Foundation.h>
#import "ServersDataSource.h"

#define BOLD 0x02
#define COLOR_MIRC 0x03
#define COLOR_RGB 0x04
#define MONO 0x11
#define CLEAR 0x0f
#define REVERSE 0x16
#define ITALICS 0x1d
#define STRIKETHROUGH 0x1e
#define UNDERLINE 0x1f

#define FONT_MIN 10
#define FONT_MAX 24
#define FONT_SIZE MIN(FONT_MAX, MAX(FONT_MIN, [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"]))
#define MESSAGE_LINE_SPACING 2
#define MESSAGE_LINE_PADDING 4

@interface ColorFormatter : NSObject
+(NSRegularExpression*)email;
+(NSRegularExpression*)ircChannelRegexForServer:(Server *)s;
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links;
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links largeEmoji:(BOOL)largeEmoji mentions:(NSDictionary *)mentions colorizeMentions:(BOOL)colorizeMentions mentionOffset:(NSInteger)mentionOffset;
+(BOOL)shouldClearFontCache;
+(void)clearFontCache;
+(void)loadFonts;
+(UIFont *)timestampFont;
+(UIFont *)monoTimestampFont;
+(UIFont *)awesomeFont;
+(UIFont *)messageFont:(BOOL)mono;
+(UIFont *)replyThreadFont;
+(void)emojify:(NSMutableString *)text;
+(NSString *)toIRC:(NSAttributedString *)string;
+(NSAttributedString *)stripUnsupportedAttributes:(NSAttributedString *)input fontSize:(CGFloat)fontSize;
+(NSArray *)webURLs:(NSString *)string;
@end

@interface NSString (ColorFormatter)
-(NSString *)stripIRCFormatting;
-(NSString *)insertCodeSpans;
-(BOOL)isBlockQuote;
-(BOOL)isEmojiOnly;
@end
