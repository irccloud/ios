//
//  UIDevice+UIDevice_iPhone6Hax.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
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

#import "UIDevice+UIDevice_iPhone6Hax.h"

BOOL __isBigPhone = NO;
BOOL __isBigPhone_set = NO;

@implementation UIDevice (UIDevice_iPhone6Hax)
-(BOOL)isBigPhone {
    if(__isBigPhone_set)
        return __isBigPhone;
    
    if(![[UIScreen mainScreen] respondsToSelector:@selector(nativeScale)])
        __isBigPhone = NO;
    else
        __isBigPhone = [self userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] nativeScale] > 2.0f;
    
    __isBigPhone_set = YES;
    return __isBigPhone;
}
@end
