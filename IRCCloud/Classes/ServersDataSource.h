//
//  ServersDataSource.h
//  IRCCloud
//
//  Created by Sam Steele on 2/24/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Server : NSObject {
    int _cid;
    NSString *_name;
    NSString *_hostname;
    int _port;
    NSString *_nick;
    NSString *_status;
    int _lag;
    int _ssl;
    NSString *_realname;
    NSString *_server_pass;
    NSString *_nickserv_pass;
    NSString *_join_commands;
    NSDictionary *_fail_info;
    NSString *_away;
    NSString *_usermask;
    NSString *_mode;
    NSDictionary *_isupport;
    NSArray *_ignores;
}
@property int cid, port, ssl, lag;
@property NSString *name, *hostname, *nick, *status, *realname, *server_pass, *nickserv_pass, *join_commands, *away, *usermask, *mode;
@property NSDictionary *fail_info, *isupport;
@property NSArray *ignores;
-(NSComparisonResult)compare:(Server *)aServer;
@end

@interface ServersDataSource : NSObject {
    NSMutableArray *_servers;
}
+(ServersDataSource *)sharedInstance;
-(void)clear;
-(void)addServer:(Server *)server;
-(NSArray *)getServers;
-(Server *)getServer:(int)cid;
-(Server *)getServer:(NSString *)hostname port:(int)port;
-(Server *)getServer:(NSString *)hostname SSL:(BOOL)ssl;
-(void)removeServer:(int)cid;
-(void)removeAllDataForServer:(int)cid;
-(int)count;
-(void)updateLag:(long)lag server:(int)cid;
-(void)updateNick:(NSString *)nick server:(int)cid;
-(void)updateStatus:(NSString *)status failInfo:(NSDictionary *)failInfo server:(int)cid;
-(void)updateAway:(NSString *)away server:(int)cid;
-(void)updateUsermask:(NSString *)usermask server:(int)cid;
-(void)updateMode:(NSString *)mode server:(int)cid;
-(void)updateIsupport:(NSDictionary *)isupport server:(int)cid;
-(void)updateIgnores:(NSArray *)ignores server:(int)cid;
@end
