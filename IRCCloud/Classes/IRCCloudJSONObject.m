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
        _dict = dict;
        _type = [_dict objectForKey:@"type"];
        if([_dict objectForKey:@"cid"])
            _cid = [[_dict objectForKey:@"cid"] intValue];
        else
            _cid = -1;
        if([_dict objectForKey:@"bid"])
            _bid = [[_dict objectForKey:@"bid"] intValue];
        else
            _bid = -1;
        if([_dict objectForKey:@"eid"])
            _eid = [[_dict objectForKey:@"eid"] doubleValue];
        else
            _eid = -1;
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
    return [_dict objectForKey:key];
}
-(NSString *)description {
    return [_dict description];
}
-(NSDictionary *)dictionary {
    return _dict;
}
@end
