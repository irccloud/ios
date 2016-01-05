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

#define BOLD 2
#define COLOR_MIRC 3
#define COLOR_RGB 4
#define CLEAR 15
#define ITALICS 22
#define UNDERLINE 31

#define FONT_SIZE [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"]

@interface ColorFormatter : NSObject
+(NSRegularExpression*)ircChannelRegexForServer:(Server *)s;
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links;
+(BOOL)shouldClearFontCache;
+(void)clearFontCache;
+(void)loadFonts;
+(UIFont *)timestampFont;
+(UIFont *)monoTimestampFont;
+(UIFont *)awesomeFont;
@end

@interface NSString (ColorFormatter)
-(NSString *)stripIRCFormatting;
@end