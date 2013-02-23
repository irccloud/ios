//
//  IRCCloudJSONObject.m
//  IRCCloud
//
//  Created by Sam Steele on 2/22/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "IRCCloudJSONObject.h"

@implementation IRCCloudJSONObject
-(id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
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
        _eid = [[_dict objectForKey:@"eid"] longValue];
    else
        _eid = -1;
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
-(long)eid {
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
