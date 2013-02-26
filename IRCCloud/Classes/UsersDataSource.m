//
//  UsersDataSource.m
//  IRCCloud
//
//  Created by Sam Steele on 2/26/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

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
    _users = [[NSMutableArray alloc] init];
    return self;
}

-(void)clear {
    @synchronized(_users) {
        [_users removeAllObjects];
    }
}

-(void)addUser:(User *)user {
    @synchronized(_users) {
        [_users addObject:user];
    }
}

-(NSArray *)usersForBuffer:(int)bid {
    @synchronized(_users) {
        NSMutableArray *users = [[NSMutableArray alloc] init];
        for(User *user in _users) {
            if(user.bid == bid)
                [users addObject:user];
        }
        return [users sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(User *)getUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        for(User *user in _users) {
            if(user.cid == cid && user.bid == bid && [user.nick isEqualToString:nick])
                return user;
        }
        return nil;
    }
}

-(User *)getUser:(NSString *)nick cid:(int)cid {
    @synchronized(_users) {
        for(User *user in _users) {
            if(user.cid == cid && [user.nick isEqualToString:nick])
                return user;
        }
        return nil;
    }
}

-(void)removeUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user)
            [_users removeObject:user];
    }
}

-(void)removeUsersForBuffer:(int)bid {
    @synchronized(_users) {
        for(User *user in [_users copy]) {
            if(user.bid == bid)
                [_users removeObject:user];
        }
    }
}

-(void)updateNick:(NSString *)nick oldNick:(NSString *)oldNick cid:(int)cid bid:(int)bid {
    @synchronized(_users) {
        User *user = [self getUser:oldNick cid:cid bid:bid];
        if(user) {
            user.nick = nick;
            user.old_nick = oldNick;
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
