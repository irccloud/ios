//
//  Ignore.m
//  IRCCloud
//
//  Created by Sam Steele on 4/10/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "Ignore.h"

@implementation Ignore
-(void)addMask:(NSString *)mask {
    if(!_ignores)
        _ignores = [[NSMutableArray alloc] init];
    [_ignores addObject:mask];
}

-(void)setIgnores:(NSArray *)ignores {
    if(!_ignores)
        _ignores = [[NSMutableArray alloc] init];
    [_ignores removeAllObjects];
    [_ignores addObjectsFromArray:ignores];
}

-(BOOL)match:(NSString *)usermask {
    if(_ignores.count) {
        for(NSString *ignore in _ignores) {
            NSString *mask = [ignore lowercaseString];
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
            usermask = [[usermask stringByReplacingOccurrencesOfString:@"!~" withString:@"!"] lowercaseString];
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:mask options:0 error:NULL];
            if([regex rangeOfFirstMatchInString:usermask options:0 range:NSMakeRange(0, [usermask length])].location != NSNotFound)
                return YES;
        }
    }
    return NO;
}
@end
