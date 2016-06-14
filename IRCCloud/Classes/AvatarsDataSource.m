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
        _images = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(UIImage *)getImage:(int)size isSelf:(BOOL)isSelf {
    _lastAccessTime = [[NSDate date] timeIntervalSince1970];
    if(![_images objectForKey:@(size)]) {
        UIFont *font = [UIFont fontWithName:@"SourceSansPro-Regular" size:size * 0.6];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        UIColor *color = isSelf?[UIColor messageTextColor]:[UIColor colorFromHexString:[UIColor colorForNick:_nick]];
        if([UIColor isDarkTheme]) {
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(0,0,size,size));
        } else {
            CGFloat h, s, b, a;
            [color getHue:&h saturation:&s brightness:&b alpha:&a];
            
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithHue:h saturation:s brightness:b * 0.8 alpha:a].CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(2,4,size-4,size-4));
            CGContextSetFillColorWithColor(ctx, color.CGColor);
            CGContextFillEllipseInRect(ctx,CGRectMake(2,2,size-4,size-4));
        }
        
        NSRegularExpression *r = [NSRegularExpression regularExpressionWithPattern:@"[_\\W]+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSString *text = [r stringByReplacingMatchesInString:[_nick uppercaseString] options:0 range:NSMakeRange(0, _nick.length) withTemplate:@""];
        if(!text.length)
            text = [_nick uppercaseString];
        text = [text substringToIndex:1];
        CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor contentBackgroundColor]}];
        CGPoint p = CGPointMake((size / 2) - (textSize.width / 2),(size / 2) - (textSize.height / 2));
        [text drawAtPoint:p withAttributes:@{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor contentBackgroundColor]}];
        
        [_images setObject:UIGraphicsGetImageFromCurrentImageContext() forKey:@(size)];
        UIGraphicsEndImageContext();
    }
    return [_images objectForKey:@(size)];
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
        _avatars = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(Avatar *)getAvatar:(NSString *)nick bid:(int)bid {
    if(![_avatars objectForKey:@(bid)]) {
        [_avatars setObject:[[NSMutableDictionary alloc] init] forKey:@(bid)];
    }
    
    if(![[_avatars objectForKey:@(bid)] objectForKey:nick]) {
        Avatar *a = [[Avatar alloc] init];
        a.bid = bid;
        a.nick = nick;
        [[_avatars objectForKey:@(bid)] setObject:a forKey:nick];
    }
    
    return [[_avatars objectForKey:@(bid)] objectForKey:nick];
}

-(void)clear {
    [_avatars removeAllObjects];
}
@end
