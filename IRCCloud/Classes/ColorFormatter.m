//
//  ColorFormatter.m
//  IRCCloud
//
//  Created by Sam Steele on 3/1/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <CoreText/CoreText.h>
#import "ColorFormatter.h"
#import "TTTAttributedLabel.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"

@implementation ColorFormatter

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
        NSArray *results = [dataDetector matchesInString:[output string] options:0 range:NSMakeRange(0, [output length])];
        if(results.count) {
            [matches addObjectsFromArray:results];
        }
        if(server) {
            results = [[self ircChannelRegexForServer:server] matchesInString:[output string] options:0 range:NSMakeRange(0, [output length])];
            if(results.count) {
                [matches addObjectsFromArray:results];
            }
        }
    }
    if(links)
        *links = [NSArray arrayWithArray:matches];
    return output;
}
@end
