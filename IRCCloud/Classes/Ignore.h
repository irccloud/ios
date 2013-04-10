//
//  Ignore.h
//  IRCCloud
//
//  Created by Sam Steele on 4/10/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Ignore : NSObject {
    NSMutableArray *_ignores;
}
-(void)addMask:(NSString *)mask;
-(void)setIgnores:(NSArray *)ignores;
-(BOOL)match:(NSString *)usermask;
@end
