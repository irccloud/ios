//
//  UsersDataSource.m
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


#import "UsersDataSource.h"

@implementation User

-(NSComparisonResult)compare:(User *)aUser {
    return [[_nick lowercaseString] compare:[aUser.nick lowercaseString]];
}

@end

@implementation UsersDataSource
+(UsersDataSource *)sharedInstance {
    static UsersDataSource *sharedInstance;
	
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[UsersDataSource alloc] init];
		
        return sharedInstance;
    }
	return nil;
}

-(id)init {
    self = [super init];
    _users = [[NSMutableDictionary alloc] init];
    return self;
}

-(void)clear {
    @synchronized(_users) {
        [_users removeAllObjects];
    }
}

-(void)addUser:(User *)user {
    @synchronized(_users) {
        NSMutableDictionary *users = [_users objectForKey:@(user.bid)];
        if(!users) {
            users = [[NSMutableDictionary alloc] init];
            [_users setObject:users forKey:@(user.bid)];
        }
        [users setObject:user forKey:[user.nick lowercaseString]];
    }
}

-(NSArray *)usersForBuffer:(int)bid {
    @synchronized(_users) {
        return [[[_users objectForKey:@(bid)] allValues] sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(User *)getUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        return [[_users objectForKey:@(bid)] objectForKey:[nick lowercaseString]];
    }
}

-(void)removeUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        [[_users objectForKey:@(bid)] removeObjectForKey:[nick lowercaseString]];
    }
}

-(void)removeUsersForBuffer:(int)bid {
    @synchronized(_users) {
        [_users removeObjectForKey:@(bid)];
    }
}

-(void)updateNick:(NSString *)nick oldNick:(NSString *)oldNick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:oldNick cid:cid bid:bid];
        if(user) {
            user.nick = nick;
            user.old_nick = oldNick;
            [[_users objectForKey:@(bid)] removeObjectForKey:[oldNick lowercaseString]];
            [[_users objectForKey:@(bid)] setObject:user forKey:[nick lowercaseString]];
        }
    }
}

-(void)updateAway:(int)away msg:(NSString *)msg nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user) {
            user.away = away;
            user.away_msg = msg;
        }
    }
}

-(void)updateAway:(int)away nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user) {
            user.away = away;
        }
    }
}

-(void)updateHostmask:(NSString *)hostmask nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user)
            user.hostmask = hostmask;
    }
}

-(void)updateMode:(NSString *)mode nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user)
            user.mode = mode;
    }
}
@end
