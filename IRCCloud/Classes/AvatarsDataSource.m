//
//  AvatarsDataSource.m
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

#import "AvatarsDataSource.h"
#import "UIColor+IRCCloud.h"

@implementation Avatar
-(id)init {
    self = [super init];
    if(self) {
        self->_images = [[NSMutableDictionary alloc] init];
        self->_selfImages = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(UIImage *)getImage:(int)size isSelf:(BOOL)isSelf {
    self->_lastAccessTime = [[NSDate date] timeIntervalSince1970];
    NSMutableDictionary *images = isSelf?_selfImages:self->_images;
    if(![images objectForKey:@(size)]) {
        UIFont *font = [UIFont fontWithName:@"SourceSansPro-Semibold" size:(size * 0.65)];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIColor *color = isSelf?[UIColor selfNickColor]:[UIColor colorFromHexString:[UIColor colorForNick:self->_nick]];
        if([UIColor isDarkTheme]) {
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(1,1,size-2,size-2));
        } else {
            CGFloat h, s, b, a;
            [color getHue:&h saturation:&s brightness:&b alpha:&a];
            
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithHue:h saturation:s brightness:b * 0.8 alpha:a].CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(1,1,size-2,size-2));
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(1,1,size-2,size-3));
        }
        
        NSRegularExpression *r = [NSRegularExpression regularExpressionWithPattern:@"[_\\W]+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *text = [r stringByReplacingMatchesInString:[self->_displayName uppercaseString] options:0 range:NSMakeRange(0, _displayName.length) withTemplate:@""];
        if(!text.length)
            text = [self->_displayName uppercaseString];
        text = [text substringToIndex:1];
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor contentBackgroundColor]}];
        CGPoint p = CGPointMake((size / 2) - (textSize.width / 2),(size / 2) - (textSize.height / 2) - 0.5);
        [text drawAtPoint:p withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor contentBackgroundColor]}];
        
        [images setObject:UIGraphicsGetImageFromCurrentImageContext() forKey:@(size)];
        UIGraphicsEndImageContext();
    }
    return [images objectForKey:@(size)];
}
@end

@implementation AvatarsDataSource
+(AvatarsDataSource *)sharedInstance {
    static AvatarsDataSource *sharedInstance;
    
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[AvatarsDataSource alloc] init];
        
        return sharedInstance;
    }
    return nil;
}

-(id)init {
    self = [super init];
    if(self) {
        self->_avatars = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(Avatar *)getAvatar:(NSString *)displayName nick:(NSString *)nick bid:(int)bid {
    if(!displayName.length)
        return nil;
    
    if(!nick.length)
        nick = displayName;
    
    if(![self->_avatars objectForKey:@(bid)]) {
        [self->_avatars setObject:[[NSMutableDictionary alloc] init] forKey:@(bid)];
    }
    
    if(![[self->_avatars objectForKey:@(bid)] objectForKey:nick]) {
        Avatar *a = [[Avatar alloc] init];
        a.bid = bid;
        a.nick = nick;
        a.displayName = displayName;
        [[self->_avatars objectForKey:@(bid)] setObject:a forKey:displayName];
    }
    
    return [[self->_avatars objectForKey:@(bid)] objectForKey:displayName];
}

-(void)clear {
    [self->_avatars removeAllObjects];
}
@end
