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

@implementation Server
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
    _servers = [[NSMutableArray alloc] init];
    return self;
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

-(int)count {
    @synchronized(_servers) {
        return _servers.count;
    }
}

-(void)updateLag:(long)lag server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.lag = lag;
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
    if(server)
        server.isupport = isupport;
}

-(void)updateIgnores:(NSArray *)ignores server:(int)cid {
    Server *server = [self getServer:cid];
    if(server)
        server.ignores = ignores;
}

-(void)finalize {
    NSLog(@"ServersDataSource: HALP! I'm being garbage collected!");
}
@end
