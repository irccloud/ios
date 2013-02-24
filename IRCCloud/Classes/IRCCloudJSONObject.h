//
//  IRCCloudJSONObject.h
//  IRCCloud
//
//  Created by Sam Steele on 2/22/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IRCCloudJSONObject : NSObject {
    NSDictionary *_dict;
    NSString *_type;
    int _cid;
    int _bid;
    NSTimeInterval _eid;
}
-(id)initWithDictionary:(NSDictionary *)dict;
-(NSString *)type;
-(int)cid;
-(int)bid;
-(NSTimeInterval)eid;
-(id)objectForKey:(NSString *)key;
-(NSDictionary *)dictionary;
@end
