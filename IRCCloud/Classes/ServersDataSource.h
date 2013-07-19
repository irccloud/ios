//
//  ServersDataSource.h
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
