//
//  HandshakeHeader.m
//  UnittWebSocketClient
//
//  Created by Josh Morris on 10/2/11.
//  Copyright 2011 UnitT Software. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License. You may obtain a copy of
//  the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "HandshakeHeader.h"

@implementation HandshakeHeader

@synthesize key;
@synthesize value;


#pragma mark - Header
- (BOOL) keyMatchesCaseInsensitiveString:(NSString*) aStringToCompare
{
    if (aStringToCompare && self.key)
    {
        return [self.key caseInsensitiveCompare:aStringToCompare] == NSOrderedSame;
    }
    
    return NO;
}


#pragma mark - Lifecycle
+ (id) header
{
    return [[[self class] alloc] init] ;
}

+ (id) headerWithValue:(NSString*) aValue forKey:(NSString*) aKey
{
    return [[[self class] alloc] initWithValue:aValue forKey:aKey];
}

- (id) initWithValue:(NSString*) aValue forKey:(NSString*) aKey
{
    self = [super init];
    if (self) 
    {
        self.key = aKey;
        self.value = aValue;
    }
    
    return self;    
}

- (id) init
{
    self = [super init];
    if (self) 
    {
    }
    
    return self;
}

- (void) dealloc 
{
    self.key = nil;
    self.value = nil;
}

@end
