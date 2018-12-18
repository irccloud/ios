//
//  IRCCloudJSONObject.m
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


#import "IRCCloudJSONObject.h"

@implementation IRCCloudJSONObject
-(id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {
        self->_dict = dict;
        self->_type = [self->_dict objectForKey:@"type"];
        if([self->_dict objectForKey:@"cid"])
            self->_cid = [[self->_dict objectForKey:@"cid"] intValue];
        else
            self->_cid = -1;
        if([self->_dict objectForKey:@"bid"])
            self->_bid = [[self->_dict objectForKey:@"bid"] intValue];
        else
            self->_bid = -1;
        if([self->_dict objectForKey:@"eid"])
            self->_eid = [[self->_dict objectForKey:@"eid"] doubleValue];
        else
            self->_eid = -1;
    }
    return self;
}
-(NSString *)type {
    return _type;
}
-(int)cid {
    return _cid;
}
-(int)bid {
    return _bid;
}
-(NSTimeInterval)eid {
    return _eid;
}
-(id)objectForKey:(NSString *)key {
    id obj = [self->_dict objectForKey:key];
    if(obj)
        return obj;
    if([key isEqualToString:@"success"])
        return @YES;
    return nil;
}
-(NSString *)description {
    return [self->_dict description];
}
-(NSDictionary *)dictionary {
    return _dict;
}
@end
