//
//  UsersDataSource.h
//  IRCCloud
//
//  Created by Sam Steele on 2/26/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject {
    int _cid;
    int _bid;
    NSString *_nick;
    NSString *_old_nick;
    NSString *_hostmask;
    NSString *_mode;
    int _away;
    NSString *_away_msg;
}
@property int cid, bid, away;
@property NSString *nick, *old_nick, *hostmask, *mode, *away_msg;
-(NSComparisonResult)compare:(User *)aUser;
@end

@interface UsersDataSource : NSObject {
    NSMutableArray *_users;
}
+(UsersDataSource *)sharedInstance;
-(void)clear;
-(void)addUser:(User *)user;
-(NSArray *)usersForBuffer:(int)bid;
-(User *)getUser:(NSString *)nick cid:(int)cid bid:(int)bid;
-(User *)getUser:(NSString *)nick cid:(int)cid;
-(void)removeUser:(NSString *)nick cid:(int)cid bid:(int)bid;
-(void)removeUsersForBuffer:(int)bid;
-(void)updateNick:(NSString *)nick oldNick:(NSString *)oldNick cid:(int)cid bid:(int)bid;
-(void)updateAway:(int)away msg:(NSString *)msg nick:(NSString *)nick cid:(int)cid bid:(int)bid;
-(void)updateAway:(int)away nick:(NSString *)nick cid:(int)cid bid:(int)bid;
-(void)updateHostmask:(NSString *)hostmask nick:(NSString *)nick cid:(int)cid bid:(int)bid;
-(void)updateMode:(NSString *)mode nick:(NSString *)nick cid:(int)cid bid:(int)bid;
@end
