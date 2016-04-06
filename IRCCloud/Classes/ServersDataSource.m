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
        _MODE_OPER = @"Y";
        _MODE_OWNER = @"q";
        _MODE_ADMIN = @"a";
        _MODE_OP = @"o";
        _MODE_HALFOP = @"h";
        _MODE_VOICED = @"v";
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
    encodeInt(_cid);
    encodeObject(_name);
    encodeObject(_hostname);
    encodeInt(_port);
    encodeObject(_nick);
    encodeObject(_status);
    encodeInt(_ssl);
    encodeObject(_realname);
    encodeObject(_join_commands);
    encodeObject(_fail_info);
    encodeObject(_away);
    encodeObject(_usermask);
    encodeObject(_mode);
    encodeObject(_isupport);
    encodeObject(_ignores);
    encodeObject(_CHANTYPES);
    encodeObject(_PREFIX);
    encodeInt(_order);
    encodeObject(_MODE_OPER);
    encodeObject(_MODE_OWNER);
    encodeObject(_MODE_ADMIN);
    encodeObject(_MODE_OP);
    encodeObject(_MODE_HALFOP);
    encodeObject(_MODE_VOICED);
}
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(_cid);
        decodeObject(_name);
        decodeObject(_hostname);
        decodeInt(_port);
        decodeObject(_nick);
        decodeObject(_status);
        decodeInt(_ssl);
        decodeObject(_realname);
        decodeObject(_join_commands);
        decodeObject(_fail_info);
        decodeObject(_away);
        decodeObject(_usermask);
        decodeObject(_mode);
        decodeObject(_isupport);
        _isupport = _isupport.mutableCopy;
        decodeObject(_ignores);
        decodeObject(_CHANTYPES);
        decodeObject(_PREFIX);
        decodeInt(_order);
        decodeObject(_MODE_OPER);
        decodeObject(_MODE_OWNER);
        decodeObject(_MODE_ADMIN);
        decodeObject(_MODE_OP);
        decodeObject(_MODE_HALFOP);
        decodeObject(_MODE_VOICED);
    }
    return self;
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
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"servers"];
            
            @try {
                _servers = [[NSKeyedUnarchiver unarchiveObjectWithFile:cacheFile] mutableCopy];
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
            _servers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"servers"];
    
    NSArray *servers;
    @synchronized(_servers) {
        servers = [_servers copy];
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
    @synchronized(_servers) {
        [_servers removeAllObjects];
    }
}

-(void)addServer:(Server *)server {
    @synchronized(_servers) {
        [_servers addObject:server];
    }
}

-(NSArray *)getServers {
    @synchronized(_servers) {
        return [_servers sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(Server *)getServer:(int)cid {
    NSArray *copy;
    @synchronized(_servers) {
        copy = _servers.copy;
    }
    for(Server *server in copy) {
        if(server.cid == cid)
            return server;
    }
    return nil;
}

-(Server *)getServer:(NSString *)hostname port:(int)port {
    NSArray *copy;
    @synchronized(_servers) {
        copy = _servers.copy;
    }
    for(Server *server in copy) {
        if([server.hostname isEqualToString:hostname] && (port == -1 || server.port == port))
            return server;
    }
    return nil;
}

-(Server *)getServer:(NSString *)hostname SSL:(BOOL)ssl {
    NSArray *copy;
    @synchronized(_servers) {
        copy = _servers.copy;
    }
    for(Server *server in copy) {
        if([server.hostname isEqualToString:hostname] && ((ssl == YES && server.ssl > 0) || (ssl == NO && server.ssl == 0)))
            return server;
    }
    return nil;
}

-(void)removeServer:(int)cid {
    @synchronized(_servers) {
        Server *server = [self getServer:cid];
        if(server)
            [_servers removeObject:server];
    }
}

-(void)removeAllDataForServer:(int)cid {
    Server *server = [self getServer:cid];
    if(server) {
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:cid]) {
            [[BuffersDataSource sharedInstance] removeAllDataForBuffer:b.bid];
        }
        @synchronized(_servers) {
            [_servers removeObject:server];
        }
    }
}

-(NSUInteger)count {
    @synchronized(_servers) {
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

-(void)finalize {
    NSLog(@"ServersDataSource: HALP! I'm being garbage collected!");
}
@end
