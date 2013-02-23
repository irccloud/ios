//
//  WebSocketFragment.h
//  UnittWebSocketClient
//
//  Created by Josh Morris on 6/12/11.
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

#import <Foundation/Foundation.h>


enum 
{
    MessageOpCodeIllegal = -1,
    MessageOpCodeContinuation = 0x0,
    MessageOpCodeText = 0x1,
    MessageOpCodeBinary = 0x2,
    MessageOpCodeClose = 0x8,
    MessageOpCodePing = 0x9,
    MessageOpCodePong = 0xA
};
typedef NSInteger MessageOpCode;

enum 
{
    PayloadTypeUnknown = 0,
    PayloadTypeText = 1,
    PayloadTypeBinary = 2
};
typedef NSInteger PayloadType;

enum 
{
    PayloadLengthIllegal = -1,
    PayloadLengthMinimum = 0,
    PayloadLengthShort = 1,
    PayloadLengthLong = 2
};
typedef NSInteger PayloadLength;


@interface WebSocketFragment : NSObject 
{
    BOOL isFinal;
    int mask;
    int payloadStart;
    int payloadLength;
    BOOL isRSV1;
    BOOL isRSV2;
    BOOL isRSV3;
    PayloadType payloadType;
    NSData* payloadData;
    MessageOpCode opCode;
    NSMutableData* fragment;
}

@property (nonatomic,assign) BOOL isFinal;
@property (nonatomic,readonly) BOOL hasMask;
@property (nonatomic,readonly) BOOL isControlFrame;
@property (nonatomic,readonly) BOOL isDataFrame;
@property (nonatomic,readonly) BOOL isValid;
@property (nonatomic,readonly) BOOL canBeParsed;
@property (nonatomic,readonly) BOOL isHeaderValid;
@property (nonatomic,assign) BOOL isRSV1;
@property (nonatomic,assign) BOOL isRSV2;
@property (nonatomic,assign) BOOL isRSV3;
@property (nonatomic,assign) int mask;
@property (nonatomic,assign) MessageOpCode opCode;
@property (nonatomic,retain) NSData* payloadData;
@property (nonatomic,assign) PayloadType payloadType;
@property (nonatomic,retain) NSMutableData* fragment;
@property (nonatomic,readonly) NSUInteger messageLength;
@property (nonatomic,readonly) int payloadLength;
@property (nonatomic,readonly) int payloadStart;

@property (nonatomic,readonly) BOOL isDataValid;

- (int) generateMask;
- (NSData*) mask:(int) aMask data:(NSData*) aData;
- (NSData*) mask:(int) aMask data:(NSData*) aData range:(NSRange) aRange;
- (void) maskInPlace:(int) aMask data:(NSMutableData*) aData range:(NSRange) aRange;
- (NSData*) unmask:(int) aMask data:(NSData*) aData;
- (NSData*) unmask:(int) aMask data:(NSData*) aData range:(NSRange) aRange;
- (void) unmaskInPlace:(int) aMask data:(NSMutableData*) aData range:(NSRange) aRange;

- (void) parseHeader;
- (BOOL) parseHeader:(NSData*) aData from:(NSUInteger) aOffset;
- (void) parseContent;

- (BOOL) parseContent:(NSData*) aData;

- (void) buildFragment;

+ (id) fragmentWithOpCode:(MessageOpCode) aOpCode isFinal:(BOOL) aIsFinal payload:(NSData*) aPayload;
+ (id) fragmentWithData:(NSData*) aData;
- (id) initWithOpCode:(MessageOpCode) aOpCode isFinal:(BOOL) aIsFinal payload:(NSData*) aPayload;
- (id) initWithData:(NSData*) aData;

@end
