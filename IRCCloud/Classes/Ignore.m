//
//  Ignore.m
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


#import "Ignore.h"

@implementation Ignore
-(void)addMask:(NSString *)mask {
    @synchronized(self) {
        if(!_ignores)
            self->_ignores = [[NSMutableArray alloc] init];
        if(!_ignoreCache)
            self->_ignoreCache = [[NSMutableDictionary alloc] init];
        [self->_ignores addObject:mask];
        [self->_ignoreCache removeAllObjects];
    }
}

-(void)setIgnores:(NSArray *)ignores {
    @synchronized(self) {
        if(!_ignores)
            self->_ignores = [[NSMutableArray alloc] init];
        if(!_ignoreCache)
            self->_ignoreCache = [[NSMutableDictionary alloc] init];
        [self->_ignores removeAllObjects];
        [self->_ignoreCache removeAllObjects];
    }
    for(NSString *ignore in ignores) {
        NSString *mask = [ignore lowercaseString];
        mask = [mask stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
        mask = [mask stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
        mask = [mask stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
        mask = [mask stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
        mask = [mask stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
        mask = [mask stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
        mask = [mask stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
        mask = [mask stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"];
        mask = [mask stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
        mask = [mask stringByReplacingOccurrencesOfString:@"$" withString:@"\\$"];
        mask = [mask stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"];
        mask = [mask stringByReplacingOccurrencesOfString:@"?" withString:@"\\?"];
        mask = [mask stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
        mask = [mask stringByReplacingOccurrencesOfString:@"," withString:@"\\,"];
        mask = [mask stringByReplacingOccurrencesOfString:@"#" withString:@"\\#"];
        mask = [mask stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
        mask = [mask stringByReplacingOccurrencesOfString:@"*" withString:@".*"];
        mask = [mask stringByReplacingOccurrencesOfString:@"!~" withString:@"!"];
        if([mask rangeOfString:@"!"].location == NSNotFound) {
            if([mask rangeOfString:@"@"].location == NSNotFound) {
                mask = [mask stringByAppendingString:@"!.*"];
            } else {
                mask = [NSString stringWithFormat:@".*!%@", mask];
            }
        }
        if([mask rangeOfString:@"@"].location == NSNotFound) {
            if([mask rangeOfString:@"!"].location == NSNotFound) {
                mask = [mask stringByAppendingString:@"@.*"];
            } else {
                mask = [mask stringByReplacingOccurrencesOfString:@"!" withString:@"!.*@"];
            }
        }
        if([mask isEqualToString:@".*!.*@.*"])
            continue;
        @synchronized(self) {
            [self->_ignores addObject:mask];
        }
    }
}

-(BOOL)match:(NSString *)usermask {
    @synchronized(self) {
        if(usermask && [self->_ignoreCache objectForKey:usermask])
            return [[self->_ignoreCache objectForKey:usermask] boolValue];
        if(usermask && _ignores.count) {
            for(NSString *ignore in _ignores) {
                if(ignore) {
                    usermask = [[usermask stringByReplacingOccurrencesOfString:@"!~" withString:@"!"] lowercaseString];
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"^%@$",ignore] options:0 error:NULL];
                    if([regex rangeOfFirstMatchInString:usermask options:0 range:NSMakeRange(0, [usermask length])].location != NSNotFound) {
                        [self->_ignoreCache setObject:@(YES) forKey:usermask];
                        return YES;
                    }
                }
            }
            [self->_ignoreCache setObject:@(NO) forKey:usermask];
        }
        return NO;
    }
}
@end
