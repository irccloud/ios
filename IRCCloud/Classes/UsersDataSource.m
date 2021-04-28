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
#import "ChannelsDataSource.h"
#import "BuffersDataSource.h"
#import "ServersDataSource.h"
#import "EventsDataSource.h"

@implementation User

+ (BOOL)supportsSecureCoding {
    return YES;
}

-(NSString *)nick {
    return _nick;
}

-(void)setNick:(NSString *)nick {
    self->_nick = nick;
    self->_lowercase_nick = self.display_name.lowercaseString;
}

-(NSString *)lowercase_nick {
    if(!_lowercase_nick)
        self->_lowercase_nick = self->_nick.lowercaseString;
    return _lowercase_nick;
}

-(NSString *)display_name {
    if([self->_display_name isKindOfClass:NSString.class] &&_display_name.length)
        return _display_name;
    else
        return _nick;
}

-(void)setDisplay_name:(NSString *)display_name {
    self->_display_name = display_name;
    self->_lowercase_nick = self.display_name.lowercaseString;
}

-(NSComparisonResult)compare:(User *)aUser {
    return [self->_lowercase_nick localizedStandardCompare:aUser.lowercase_nick];
}

-(NSComparisonResult)compareByMentionTime:(User *)aUser {
    if(self->_lastMention < aUser.lastMention) {
        return NSOrderedDescending;
    } else if(self->_lastMention > aUser.lastMention) {
        return NSOrderedAscending;
    } else if(self->_lastMessage < aUser.lastMessage) {
        return NSOrderedDescending;
    } else if(self->_lastMessage > aUser.lastMessage) {
        return NSOrderedAscending;
    } else {
        return [self->_lowercase_nick localizedStandardCompare:aUser.lowercase_nick];
    }
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if(self) {
        decodeInt(self->_cid);
        decodeInt(self->_bid);
        decodeObjectOfClass(NSString.class, self->_nick);
        decodeObjectOfClass(NSString.class, self->_old_nick);
        decodeObjectOfClass(NSString.class, self->_hostmask);
        decodeObjectOfClass(NSString.class, self->_mode);
        decodeInt(self->_away);
        decodeObjectOfClass(NSString.class, self->_away_msg);
        decodeDouble(self->_lastMention);
        decodeDouble(self->_lastMessage);
        decodeObjectOfClass(NSString.class, self->_ircserver);
        decodeObjectOfClass(NSString.class, self->_display_name);
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder {
    encodeInt(self->_cid);
    encodeInt(self->_bid);
    encodeObject(self->_nick);
    encodeObject(self->_old_nick);
    encodeObject(self->_hostmask);
    encodeObject(self->_mode);
    encodeInt(self->_away);
    encodeObject(self->_away_msg);
    encodeDouble(self->_lastMention);
    encodeDouble(self->_lastMessage);
    encodeObject(self->_ircserver);
    encodeObject(self->_display_name);
}

-(NSString *)description {
    return [NSString stringWithFormat:@"{cid: %i, bid: %i, nick: %@, hostmask: %@}", _cid, _bid, _nick, _hostmask];
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
    if(self) {
        [NSKeyedArchiver setClassName:@"IRCCloud.User" forClass:User.class];
        [NSKeyedUnarchiver setClass:User.class forClassName:@"IRCCloud.User"];

        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]) {
            NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"users"];
            
            @try {
                NSError* error = nil;
                self->_users = [[NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithObjects:NSDictionary.class, NSArray.class, User.class, nil] fromData:[NSData dataWithContentsOfFile:cacheFile] error:&error] mutableCopy];
                if(error)
                    @throw [NSException exceptionWithName:@"NSError" reason:error.debugDescription userInfo:@{ @"NSError" : error }];
            } @catch(NSException *e) {
                CLS_LOG(@"Exception: %@", e);
                [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
                [[ServersDataSource sharedInstance] clear];
                [[BuffersDataSource sharedInstance] clear];
                [[ChannelsDataSource sharedInstance] clear];
                [[EventsDataSource sharedInstance] clear];
            }
        }
        if(!_users)
            self->_users = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void)serialize {
    NSString *cacheFile = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"users"];
    
    NSMutableDictionary *users = [[NSMutableDictionary alloc] init];
    @synchronized(self->_users) {
        for(NSNumber *bid in _users) {
            [users setObject:[[self->_users objectForKey:bid] mutableCopy] forKey:bid];
        }
    }
    
    @synchronized(self) {
        @try {
            NSError* error = nil;
            [[NSKeyedArchiver archivedDataWithRootObject:users requiringSecureCoding:YES error:&error] writeToFile:cacheFile atomically:YES];
            if(error)
                CLS_LOG(@"Error archiving: %@", error);
            [[NSURL fileURLWithPath:cacheFile] setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:NULL];
        }
        @catch (NSException *exception) {
            [[NSFileManager defaultManager] removeItemAtPath:cacheFile error:nil];
        }
    }
}

-(void)clear {
    @synchronized(self->_users) {
        [self->_users removeAllObjects];
    }
}

-(void)addUser:(User *)user {
#ifndef EXTENSION
    @synchronized(self->_users) {
        NSMutableDictionary *users = [self->_users objectForKey:@(user.bid)];
        if(!users) {
            users = [[NSMutableDictionary alloc] init];
            [self->_users setObject:users forKey:@(user.bid)];
        }
        [users setObject:user forKey:user.lowercase_nick];
    }
#endif
}

-(NSArray *)usersForBuffer:(int)bid {
    @synchronized(self->_users) {
        return [[[self->_users objectForKey:@(bid)] allValues] sortedArrayUsingSelector:@selector(compare:)];
    }
}

-(User *)getUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(self->_users) {
        return [[self->_users objectForKey:@(bid)] objectForKey:[nick lowercaseString]];
    }
}

-(User *)getUser:(NSString *)nick cid:(int)cid {
    @synchronized(self->_users) {
        for(NSDictionary *buffer in _users.allValues) {
            User *u = [buffer objectForKey:[nick lowercaseString]];
            if(u && u.cid == cid)
                return u;
        }
        return nil;
    }
}

-(NSString *)getDisplayName:(NSString *)nick cid:(int)cid {
    @synchronized(self->_users) {
        for(NSDictionary *buffer in _users.allValues) {
            for(User *u in buffer.allValues) {
                if(u && u.cid != cid)
                    break;
                if(u && u.cid == cid && [u.nick isEqualToString:nick] && u.display_name.length)
                    return u.display_name;
            }
        }
        return nick;
    }
}

-(void)removeUser:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(self->_users) {
        [[self->_users objectForKey:@(bid)] removeObjectForKey:[nick lowercaseString]];
    }
}

-(void)removeUsersForBuffer:(int)bid {
    @synchronized(self->_users) {
        [self->_users removeObjectForKey:@(bid)];
    }
}

-(void)updateNick:(NSString *)nick oldNick:(NSString *)oldNick cid:(int)cid bid:(int)bid {
    @synchronized(self->_users) {
        User *user = [self getUser:oldNick cid:cid bid:bid];
        if(user) {
            user.nick = nick;
            user.old_nick = oldNick;
            [[self->_users objectForKey:@(bid)] removeObjectForKey:[oldNick lowercaseString]];
            [[self->_users objectForKey:@(bid)] setObject:user forKey:[nick lowercaseString]];
        }
    }
}

-(void)updateDisplayName:(NSString *)displayName nick:(NSString *)nick cid:(int)cid {
    @synchronized(self->_users) {
        for(NSDictionary *d in _users.allValues) {
            for(User *u in d.allValues) {
                if(u.cid == cid && [u.nick isEqualToString:nick]) {
                    [[self->_users objectForKey:@(u.bid)] removeObjectForKey:u.lowercase_nick];
                    if([displayName isKindOfClass:NSString.class]) {
                        u.display_name = displayName;
                        [[self->_users objectForKey:@(u.bid)] setObject:u forKey:u.lowercase_nick];
                    }
                    break;
                }
            }
        }
    }
}

-(void)updateAway:(int)away msg:(NSString *)msg nick:(NSString *)nick cid:(int)cid {
    @synchronized(self->_users) {
        for(NSDictionary *buffer in _users.allValues) {
            User *user = [buffer objectForKey:[nick lowercaseString]];
            if(user && user.cid == cid) {
                user.away = away;
                user.away_msg = msg;
            }
        }
    }
}

-(void)updateAway:(int)away nick:(NSString *)nick cid:(int)cid {
    @synchronized(self->_users) {
        for(NSDictionary *buffer in _users.allValues) {
            User *user = [buffer objectForKey:[nick lowercaseString]];
            if(user && user.cid == cid) {
                user.away = away;
            }
        }
    }
}

-(void)updateHostmask:(NSString *)hostmask nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(self->_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user)
            user.hostmask = hostmask;
    }
}

-(void)updateMode:(NSString *)mode nick:(NSString *)nick cid:(int)cid bid:(int)bid {
    @synchronized(self->_users) {
        User *user = [self getUser:nick cid:cid bid:bid];
        if(user)
            user.mode = mode;
    }
}
@end
