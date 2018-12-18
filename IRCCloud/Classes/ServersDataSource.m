//
//  ServersDataSource.m
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

#import "ServersDataSource.h"
#import "BuffersDataSource.h"
#import "ChannelsDataSource.h"
#import "UsersDataSource.h"
#import "EventsDataSource.h"

@implementation Server
-(id)init {
    self = [super init];
    if(self) {
        self->_MODE_OPER = @"Y";
        self->_MODE_OWNER = @"q";
        self->_MODE_ADMIN = @"a";
        self->_MODE_OP = @"o";
        self->_MODE_HALFOP = @"h";
        self->_MODE_VOICED = @"v";
        self->_ignore = [[Ignore alloc] init];
    }
    return self;
}
-(NSComparisonResult)compare:(Server *)aServer {
    if(aServer.order > _order)
        return NSOrderedAscending;
    else if(aServer.order < _order)
        return NSOrderedDescending;
    else if(aServer.cid > _cid)
        return NSOrderedAscending;
    else if(aServer.cid < _cid)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}
-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, name: %@, hostname: %@, port: %i}", _cid, _name, _hostname, _port];
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(self->_cid);
    encodeObject(self->_name);
    encodeObject(self->_hostname);
    encodeInt(self->_port);
    encodeObject(self->_nick);
    encodeObject(self->_status);
    encodeInt(self->_ssl);
    encodeObject(self->_realname);
    encodeObject(self->_join_commands);
    encodeObject(self->_fail_info);
    encodeObject(self->_away);
    encodeObject(self->_usermask);
    encodeObject(self->_mode);
    encodeObject(self->_isupport);
    encodeObject(self->_ignores);
    encodeObject(self->_CHANTYPES);
    encodeObject(self->_PREFIX);
    encodeInt(self->_order);
    encodeObject(self->_MODE_OPER);
    encodeObject(self->_MODE_OWNER);
    encodeObject(self->_MODE_ADMIN);
    encodeObject(self->_MODE_OP);
    encodeObject(self->_MODE_HALFOP);
    encodeObject(self->_MODE_VOICED);
    encodeObject(self->_ircserver);
    encodeInt(self->_orgId);
    encodeObject(self->_avatar);
    encodeInt(self->_avatars_supported);
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(self->_cid);
        decodeObject(self->_name);
        decodeObject(self->_hostname);
        decodeInt(self->_port);
        decodeObject(self->_nick);
        decodeObject(self->_status);
        decodeInt(self->_ssl);
        decodeObject(self->_realname);
        decodeObject(self->_join_commands);
        decodeObject(self->_fail_info);
        decodeObject(self->_away);
        decodeObject(self->_usermask);
        decodeObject(self->_mode);
        decodeObject(self->_isupport);
        self->_isupport = self->_isupport.mutableCopy;
        decodeObject(self->_ignores);
        decodeObject(self->_CHANTYPES);
        decodeObject(self->_PREFIX);
        decodeInt(self->_order);
        decodeObject(self->_MODE_OPER);
        decodeObject(self->_MODE_OWNER);
        decodeObject(self->_MODE_ADMIN);
        decodeObject(self->_MODE_OP);
        decodeObject(self->_MODE_HALFOP);
        decodeObject(self->_MODE_VOICED);
        decodeObject(self->_ircserver);
        decodeInt(self->_orgId);
        decodeObject(self->_avatar);
        decodeInt(self->_avatars_supported);
        self->_ignore = [[Ignore alloc] init];
        [self->_ignore setIgnores:self->_ignores];
    }
    return self;
}
-(NSArray *)ignores {
    return _ignores;
}
-(void)setIgnores:(NSArray *)ignores {
    self->_ignores = ignores;
    [self->_ignore setIgnores:self->_ignores];
}

-(BOOL)isSlack {
    return _slack || [self->_hostname hasSuffix:@".slack.com"] || [self->_ircserver hasSuffix:@".slack.com"];
}

-(NSString *)slackBaseURL {
    NSString *host = self->_hostname;
    if(![host hasSuffix:@".slack.com"])
        host = self->_ircserver;
    if([host hasSuffix:@".slack.com"])
        return [NSString stringWithFormat:@"https://%@", host];
    return nil;
}
@end

@implementation ServersDataSource
+(ServersDataSource *)sharedInstance {
    static ServersDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[ServersDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    if(self) {
        [NSKeyedArchiver setClassName:@"IRCCloud.Server" forClass:Server.class];
        [NSKeyedUnarchiver setClass:Server.class forClassName:@"IRCCloud.Server"];

        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"servers"];
            
            @try {
                self->_servers = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
            } @catch(NSException *e) {
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[BuffersDataSource sharedInstance] clear];
                [[ChannelsDataSource sharedInstance] clear];
                [[EventsDataSource sharedInstance] clear];
                [[UsersDataSource sharedInstance] clear];
            }
        }
        if(!_servers)
            self->_servers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"servers"];
    
    NSArray *servers;
    @synchronized(self->_servers) {
        servers = [self->_servers copy];
    }
    
    @synchronized(self) {
        @try {
            [NSKeyedArchiver archiveRootObject:servers toFile:cacheFile];
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
}

-(void)clear {
    @synchronized(self->_servers) {
        [self->_servers removeAllObjects];
    }
}

-(void)addServer:(Server *)server {
    @synchronized(self->_servers) {
        [self->_servers addObject:server];
    }
}

-(NSArray *)getServers {
    @synchronized(self->_servers) {
        return [self->_servers sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(Server *)getServer:(int)cid {
    NSArray *copy;
    @synchronized(self->_servers) {
        copy = self->_servers.copy;
    }
    for(Server *server in copy) {
        if(server.cid == cid)
            return server;
    }
    return nil;
}

-(Server *)getServer:(NSString *)hostname port:(int)port {
    NSArray *copy;
    @synchronized(self->_servers) {
        copy = self->_servers.copy;
    }
    for(Server *server in copy) {
        if([server.hostname isEqualToString:hostname] && (port == -1 || server.port == port))
            return server;
    }
    return nil;
}

-(Server *)getServer:(NSString *)hostname SSL:(BOOL)ssl {
    NSArray *copy;
    @synchronized(self->_servers) {
        copy = self->_servers.copy;
    }
    for(Server *server in copy) {
        if([server.hostname isEqualToString:hostname] && ((ssl == YES && server.ssl > 0) || (ssl == NO && server.ssl == 0)))
            return server;
    }
    return nil;
}

-(void)removeServer:(int)cid {
    @synchronized(self->_servers) {
        Server *server = [self getServer:cid];
        if(server)
            [self->_servers removeObject:server];
    }
}

-(void)removeAllDataForServer:(int)cid {
    Server *server = [self getServer:cid];
    if(server) {
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:cid]) {
            [[BuffersDataSource sharedInstance] removeAllDataForBuffer:b.bid];
        }
        @synchronized(self->_servers) {
            [self->_servers removeObject:server];
        }
    }
}

-(NSUInteger)count {
    @synchronized(self->_servers) {
        return _servers.count;
    }
}

-(void)updateNick:(NSString *)nick server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.nick = nick;
}

-(void)updateStatus:(NSString *)status failInfo:(NSDictionary *)failInfo server:(int)cid {
    Server *server = [self getServer:cid];
    if(server) {
        server.status = status;
        server.fail_info = failInfo;
    }
}

-(void)updateAway:(NSString *)away server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.away = away;
}

-(void)updateUsermask:(NSString *)usermask server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.usermask = usermask;
}

-(void)updateMode:(NSString *)mode server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.mode = mode;
}

-(void)updateIsupport:(NSDictionary *)isupport server:(int)cid {
    Server *server = [self getServer:cid];
    if(server) {
        if([isupport isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:server.isupport];
            [d addEntriesFromDictionary:isupport];
            server.isupport = d;
        } else {
            server.isupport = [[NSMutableDictionary alloc] init];
        }

        if([[server.isupport objectForKey:@"PREFIX"] isKindOfClass:[NSDictionary class]])
            server.PREFIX = [server.isupport objectForKey:@"PREFIX"];
        else
            server.PREFIX = nil;
        if([[server.isupport objectForKey:@"CHANTYPES"] isKindOfClass:[NSString class]])
            server.CHANTYPES = [server.isupport objectForKey:@"CHANTYPES"];
        else
            server.CHANTYPES = nil;
        
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:cid]) {
            b.chantypes = server.CHANTYPES;
        }
    }
}

-(void)updateIgnores:(NSArray *)ignores server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.ignores = ignores;
}

-(void)updateUserModes:(NSString *)modes server:(int)cid {
    if([modes isKindOfClass:[NSString class]] && modes.length) {
        Server *server = [self getServer:cid];
        if(server) {
            if([[modes.lowercaseString substringToIndex:1] isEqualToString:[server.isupport objectForKey:@"OWNER"]]) {
                server.MODE_OWNER = [modes substringToIndex:1];
                if([server.MODE_OWNER.lowercaseString isEqualToString:server.MODE_OPER.lowercaseString])
                    server.MODE_OPER = @"";
            }
        }
    }
}
@end
