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

@implementation ColorFormatter
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color {
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1;
    UIColor *fgColor = nil, *bgColor = nil;
    UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:16];
    UIFont *italicSystemFont = [UIFont italicSystemFontOfSize:16];
    UIFont *boldItalicSystemFont = [UIFont fontWithName:@"Helvetica-BoldOblique" size:16];
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    
    NSMutableString *text = [[NSMutableString alloc] initWithFormat:@"%@%c", input, CLEAR];
    for(int i = 0; i < text.length; i++) {
        switch([text characterAtIndex:i]) {
            case BOLD:
                if(bold == -1) {
                    bold = i;
                } else {
                    if(italics != -1) {
                        if(italics < bold - 1) {
                            [attributes addObject:@{
                             (NSString *)kCTFontAttributeName:italicSystemFont,
                             @"start":@(italics),
                             @"length":@(bold - italics)
                             }];
                        }
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldItalicSystemFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                        italics = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldSystemFont,
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
                         (NSString *)kCTFontAttributeName:boldSystemFont,
                         @"start":@(bold),
                         @"length":@(italics - bold)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldItalicSystemFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                        bold = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:italicSystemFont,
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
                     (NSString *)kCTForegroundColorAttributeName:fgColor,
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:bgColor,
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
                     (NSString *)kCTForegroundColorAttributeName:fgColor,
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:bgColor,
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                if(bold != -1 && italics != -1) {
                    if(bold < italics) {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldSystemFont,
                         @"start":@(bold),
                         @"length":@(italics - bold)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldItalicSystemFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:italicSystemFont,
                         @"start":@(italics),
                         @"length":@(bold - italics)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:boldItalicSystemFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                    }
                } else if(bold != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:boldSystemFont,
                     @"start":@(bold),
                     @"length":@(i - bold)
                     }];
                } else if(italics != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:italicSystemFont,
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
    [output addAttributes:@{(NSString *)kCTFontAttributeName:[UIFont systemFontOfSize:16]} range:NSMakeRange(0, text.length)];
    [output addAttributes:@{(NSString *)kCTForegroundColorAttributeName:color} range:NSMakeRange(0, text.length)];

    for(NSDictionary *dict in attributes) {
        if([dict objectForKey:kTTTBackgroundFillColorAttributeName]) {
            [output addAttribute:kTTTBackgroundFillColorAttributeName value:(id)[[dict objectForKey:kTTTBackgroundFillColorAttributeName] CGColor] range:NSMakeRange([[dict objectForKey:@"start"] intValue], [[dict objectForKey:@"length"] intValue])];
        } else {
            [output addAttributes:dict range:NSMakeRange([[dict objectForKey:@"start"] intValue], [[dict objectForKey:@"length"] intValue])];
        }
    }
    
    return output;
}
@end
