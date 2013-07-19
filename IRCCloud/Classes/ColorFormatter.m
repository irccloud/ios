//
//  ColorFormatter.m
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


#import <CoreText/CoreText.h>
#import "ColorFormatter.h"
#import "TTTAttributedLabel.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"

@implementation ColorFormatter

+(NSRegularExpression *)email {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
        //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
        NSString *pattern = @"[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}\\@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+";
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:0
                    error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)webURL {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
    //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
    NSString *TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL = @"(?:\
(?:aero|arpa|asia|a[cdefgilmnoqrstuwxz])\
|(?:biz|b[abdefghijmnorstvwyz])\
|(?:cat|com|coop|c[acdfghiklmnoruvxyz])\
|d[ejkmoz]\
|(?:edu|e[cegrstu])\
|f[ijkmor]\
|(?:gov|g[abdefghilmnpqrstuwy])\
|h[kmnrtu]\
|(?:info|int|i[delmnoqrst])\
|(?:jobs|j[emop])\
|k[eghimnprwyz]\
|l[abcikrstuvy]\
|(?:mil|mobi|museum|m[acdeghklmnopqrstuvwxyz])\
|(?:name|net|n[acefgilopruz])\
|(?:org|om)\
|(?:pro|p[aefghklmnrstwy])\
|qa\
|r[eosuw]\
|s[abcdeghijklmnortuvyz]\
|(?:tel|travel|t[cdfghjklmnoprtvwz])\
|u[agksyz]\
|v[aceginu]\
|w[fs]\
|(?:\u03b4\u03bf\u03ba\u03b9\u03bc\u03ae|\u0438\u0441\u043f\u044b\u0442\u0430\u043d\u0438\u0435|\u0440\u0444|\u0441\u0440\u0431|\u05d8\u05e2\u05e1\u05d8|\u0622\u0632\u0645\u0627\u06cc\u0634\u06cc|\u0625\u062e\u062a\u0628\u0627\u0631|\u0627\u0644\u0627\u0631\u062f\u0646|\u0627\u0644\u062c\u0632\u0627\u0626\u0631|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0644\u0645\u063a\u0631\u0628|\u0627\u0645\u0627\u0631\u0627\u062a|\u0628\u06be\u0627\u0631\u062a|\u062a\u0648\u0646\u0633|\u0633\u0648\u0631\u064a\u0629|\u0641\u0644\u0633\u0637\u064a\u0646|\u0642\u0637\u0631|\u0645\u0635\u0631|\u092a\u0930\u0940\u0915\u094d\u0937\u093e|\u092d\u093e\u0930\u0924|\u09ad\u09be\u09b0\u09a4|\u0a2d\u0a3e\u0a30\u0a24|\u0aad\u0abe\u0ab0\u0aa4|\u0b87\u0ba8\u0bcd\u0ba4\u0bbf\u0baf\u0bbe|\u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8|\u0b9a\u0bbf\u0b99\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0bc2\u0bb0\u0bcd|\u0baa\u0bb0\u0bbf\u0b9f\u0bcd\u0b9a\u0bc8|\u0c2d\u0c3e\u0c30\u0c24\u0c4d|\u0dbd\u0d82\u0d9a\u0dcf|\u0e44\u0e17\u0e22|\u30c6\u30b9\u30c8|\u4e2d\u56fd|\u4e2d\u570b|\u53f0\u6e7e|\u53f0\u7063|\u65b0\u52a0\u5761|\u6d4b\u8bd5|\u6e2c\u8a66|\u9999\u6e2f|\ud14c\uc2a4\ud2b8|\ud55c\uad6d|xn\\-\\-0zwm56d|xn\\-\\-11b5bs3a9aj6g|xn\\-\\-3e0b707e|xn\\-\\-45brj9c|xn\\-\\-80akhbyknj4f|xn\\-\\-90a3ac|xn\\-\\-9t4b11yi5a|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-deba0ad|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-g6w251d|xn\\-\\-gecrj9c|xn\\-\\-h2brj9c|xn\\-\\-hgbk6aj7f53bba|xn\\-\\-hlcj6aya9esc7a|xn\\-\\-j6w193g|xn\\-\\-jxalpdlp|xn\\-\\-kgbechtv|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgberp4a5d4ar|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-p1ai|xn\\-\\-pgbs0dh|xn\\-\\-s9brj9c|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zckzah|xxx)\
|y[et]\
|z[amw]))";
    NSString *GOOD_IRI_CHAR = @"a-zA-Z0-9\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF";
    NSString *pattern = [NSString stringWithFormat:@"((?:(http|https|Http|Https|rtsp|Rtsp|irc|ircs):\\/\\/(?:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\
\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_\
\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,25})?\\@)?)?\
((?:(?:[%@][%@\\-]{0,64}\\.)+%@\
|(?:(?:25[0-5]|2[0-4]\
[0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(?:25[0-5]|2[0-4][0-9]\
|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1]\
[0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}\
|[1-9][0-9]|[0-9])))\
(?:\\:\\d{1,5})?)\
(\\/(?:(?:[%@\\;\\/\\?\\:\\@\\&\\=\\#\\~\
\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_])|(?:\\%%[a-fA-F0-9]{2}))*)?\
(?:\\b|$)", GOOD_IRI_CHAR, GOOD_IRI_CHAR, TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL, GOOD_IRI_CHAR];
    _pattern = [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:0
            error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)ircChannelRegexForServer:(Server *)s {
    NSString *pattern;
    if(s && s.isupport && [[s.isupport objectForKey:@"CHANTYPES"] isKindOfClass:[NSString class]]) {
        pattern = [NSString stringWithFormat:@"(\\B)[%@][^<>!?\"()\\[\\],\\s]+(\\b)", [s.isupport objectForKey:@"CHANTYPES"]];
    } else {
        pattern = [NSString stringWithFormat:@"(\\B)[#][^<>!?\"()\\[\\],\\s]+(\\b)"];
    }
    
    return [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:0
            error:nil];
}

+(NSString *)formatNick:(NSString *)nick mode:(NSString *)mode {
    NSString *output = [NSString stringWithFormat:@"%c%@%c", BOLD, nick, CLEAR];
    BOOL showSymbol = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"mode-showsymbol"] boolValue];

    if(mode) {
        if(showSymbol) {
            if([mode rangeOfString:@"q"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cE7AA00%c~%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"a"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%c6500A5%c&%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"o"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cBA1719%c@%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"h"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cB55900%c%%%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"v"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%c25B100%c+%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
        } else {
            if([mode rangeOfString:@"q"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cE7AA00%c•%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"a"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%c6500A5%c•%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"o"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cBA1719%c•%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"h"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%cB55900%c•%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
            else if([mode rangeOfString:@"v"].location != NSNotFound)
                output = [NSString stringWithFormat:@"%c25B100%c•%c %@%c", COLOR_RGB, BOLD, COLOR_RGB, nick, CLEAR];
        }
    }
    return output;
}
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links {
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1;
    UIColor *fgColor = nil, *bgColor = nil;
    static CTFontRef Courier, CourierBold, CourierOblique,CourierBoldOblique;
    static CTFontRef Helvetica, HelveticaBold, HelveticaOblique,HelveticaBoldOblique;
    static CTFontRef arrowFont;
    static NSDataDetector *dataDetector;
    CTFontRef font, boldFont, italicFont, boldItalicFont;
    float lineSpacing = 6;
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    
    if(!Courier) {
        arrowFont = CTFontCreateWithName((CFStringRef)@"HiraMinProN-W3", FONT_SIZE, NULL);
        Courier = CTFontCreateWithName((CFStringRef)@"Courier", FONT_SIZE, NULL);
        CourierBold = CTFontCreateWithName((CFStringRef)@"Courier-Bold", FONT_SIZE, NULL);
        CourierOblique = CTFontCreateWithName((CFStringRef)@"Courier-Oblique", FONT_SIZE, NULL);
        CourierBoldOblique = CTFontCreateWithName((CFStringRef)@"Courier-BoldOblique", FONT_SIZE, NULL);
        Helvetica = CTFontCreateWithName((CFStringRef)@"Helvetica", FONT_SIZE, NULL);
        HelveticaBold = CTFontCreateWithName((CFStringRef)@"Helvetica-Bold", FONT_SIZE, NULL);
        HelveticaOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-Oblique", FONT_SIZE, NULL);
        HelveticaBoldOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-BoldOblique", FONT_SIZE, NULL);
        
        dataDetector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeLink error:nil];
    }
    if(mono) {
        font = Courier;
        boldFont = CourierBold;
        italicFont = CourierOblique;
        boldItalicFont = CourierBoldOblique;
    } else {
        font = Helvetica;
        boldFont = HelveticaBold;
        italicFont = HelveticaOblique;
        boldItalicFont = HelveticaBoldOblique;
    }
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    NSMutableArray *arrowIndex = [[NSMutableArray alloc] init];
    
    NSMutableString *text = [[NSMutableString alloc] initWithFormat:@"%@%c", input, CLEAR];
    for(int i = 0; i < text.length; i++) {
        switch([text characterAtIndex:i]) {
            case 0x2190:
            case 0x2192:
            case 0x2194:
            case 0x21D0:
                [arrowIndex addObject:@(i)];
                break;
            case BOLD:
                if(bold == -1) {
                    bold = i;
                } else {
                    if(italics != -1) {
                        if(italics < bold - 1) {
                            [attributes addObject:@{
                             (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                             @"start":@(italics),
                             @"length":@(bold - italics)
                             }];
                        }
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                        italics = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                    }
                    bold = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case ITALICS:
            case 29:
                if(italics == -1) {
                    italics = i;
                } else {
                    if(bold != -1) {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                         @"start":@(bold),
                         @"length":@(italics - bold)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                        bold = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                    }
                    italics = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case UNDERLINE:
                if(underline == -1) {
                    underline = i;
                } else {
                    [attributes addObject:@{
                     (NSString *)kCTUnderlineStyleAttributeName:@1,
                     @"start":@(underline),
                     @"length":@(i - underline)
                     }];
                    underline = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case COLOR_MIRC:
            case COLOR_RGB:
                if(fg != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTForegroundColorAttributeName:(__bridge id)[fgColor CGColor],
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:(__bridge id)[bgColor CGColor],
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                BOOL rgb = [text characterAtIndex:i] == COLOR_RGB;
                int count = 0;
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                if(i < text.length) {
                    while(i+count < text.length && (([text characterAtIndex:i+count] >= '0' && [text characterAtIndex:i+count] <= '9') ||
                                                    (rgb && (([text characterAtIndex:i+count] >= 'a' && [text characterAtIndex:i+count] <= 'f')||
                                                            ([text characterAtIndex:i+count] >= 'A' && [text characterAtIndex:i+count] <= 'F'))))) {
                        if(++count == 2 && !rgb)
                            break;
                    }
                    if(count > 0) {
                        if(count < 3 && !rgb) {
                            int color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(color > 15) {
                                count--;
                                color /= 10;
                            }
                            fgColor = [UIColor mIRCColor:color];
                        } else {
                            fgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        fg = i;
                    }
                }
                if(i < text.length && [text characterAtIndex:i] == ',') {
                    [text deleteCharactersInRange:NSMakeRange(i,1)];
                    count = 0;
                    while(i+count < text.length && (([text characterAtIndex:i+count] >= '0' && [text characterAtIndex:i+count] <= '9') ||
                                                    (rgb && (([text characterAtIndex:i+count] >= 'a' && [text characterAtIndex:i+count] <= 'f')||
                                                             ([text characterAtIndex:i+count] >= 'A' && [text characterAtIndex:i+count] <= 'F'))))) {
                        if(++count == 2 && !rgb)
                            break;
                    }
                    if(count > 0) {
                        if(count < 3 && !rgb) {
                            int color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(color > 15) {
                                count--;
                                color /= 10;
                            }
                            bgColor = [UIColor mIRCColor:color];
                        } else {
                            bgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        bg = i;
                    }
                }
                i--;
                continue;
            case CLEAR:
                if(fg != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTForegroundColorAttributeName:(__bridge id)[fgColor CGColor],
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:(__bridge id)[bgColor CGColor],
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                if(bold != -1 && italics != -1) {
                    if(bold < italics) {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                         @"start":@(bold),
                         @"length":@(italics - bold)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                         @"start":@(italics),
                         @"length":@(bold - italics)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                    }
                } else if(bold != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                     @"start":@(bold),
                     @"length":@(i - bold)
                     }];
                } else if(italics != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                     @"start":@(italics),
                     @"length":@(i - italics)
                     }];
                } else if(underline != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTUnderlineStyleAttributeName:@1,
                     @"start":@(underline),
                     @"length":@(i - underline)
                     }];
                }
                bold = -1;
                italics = -1;
                underline = -1;
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
        }
    }
    
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:text];
    [output addAttributes:@{(NSString *)kCTFontAttributeName:(__bridge id)font} range:NSMakeRange(0, text.length)];
    [output addAttributes:@{(NSString *)kCTForegroundColorAttributeName:(__bridge id)[color CGColor]} range:NSMakeRange(0, text.length)];

    for(NSNumber *i in arrowIndex) {
        [output addAttributes:@{(NSString *)kCTFontAttributeName:(__bridge id)arrowFont} range:NSMakeRange([i intValue], 1)];
    }
    
    CTParagraphStyleSetting paragraphStyle;
    paragraphStyle.spec = kCTParagraphStyleSpecifierLineSpacing;
    paragraphStyle.valueSize = sizeof(CGFloat);
    paragraphStyle.value = &lineSpacing;
    
    CTParagraphStyleRef style = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &paragraphStyle, 1);
    [output addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(__bridge id)style range:NSMakeRange(0, [output length])];
    CFRelease(style);
    
    for(NSDictionary *dict in attributes) {
        [output addAttributes:dict range:NSMakeRange([[dict objectForKey:@"start"] intValue], [[dict objectForKey:@"length"] intValue])];
    }
    
    if(linkify) {
        NSArray *results = [[self email] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];;
        for(NSTextCheckingResult *result in results) {
            NSString *url = [[output string] substringWithRange:result.range];
            url = [NSString stringWithFormat:@"mailto:%@", url];
            [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
        }
        if(server) {
            results = [[self ircChannelRegexForServer:server] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
            if(results.count) {
                [matches addObjectsFromArray:results];
            }
        }
        results = [[self webURL] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];;
        for(NSTextCheckingResult *result in results) {
            BOOL overlap = NO;
            for(NSTextCheckingResult *match in matches) {
                if(result.range.location >= match.range.location && result.range.location <= match.range.location + match.range.length) {
                    overlap = YES;
                    break;
                }
            }
            if(!overlap) {
                NSString *url = [[output string] substringWithRange:result.range];
                if([url rangeOfString:@"://"].location == NSNotFound)
                    url = [NSString stringWithFormat:@"http://%@", url];
                [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
            }
            overlap = NO;
        }
    }
    if(links)
        *links = [NSArray arrayWithArray:matches];
    return output;
}
@end
