//
//  WebSocket.m
//  UnittWebSocketClient
//
//  Created by Josh Morris on 9/26/11.
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

#import <Security/Security.h>
#import "WebSocket.h"
#import "WebSocketFragment.h"
#import "HandshakeHeader.h"
#include <zlib.h>

enum {
    WebSocketWaitingStateMessage = 0, //Starting on waiting for a new message
    WebSocketWaitingStateHeader = 1, //Waiting for the remaining header bytes
    WebSocketWaitingStatePayload = 2, //Waiting for the remaining payload bytes
    WebSocketWaitingStateFragment = 3 //Waiting for the next fragment
};
typedef NSUInteger WebSocketWaitingState;


@interface WebSocket (Private)
- (void)repeatPing;

- (void)dispatchFailure:(NSError *)aError;

- (void)dispatchClosed:(NSUInteger)aStatusCode message:(NSString *)aMessage error:(NSError *)aError;

- (void)dispatchOpened;

- (void)dispatchTextMessageReceived:(NSString *)aMessage;

- (void)dispatchBinaryMessageReceived:(NSData *)aMessage;

- (void)continueReadingMessageStream;

- (NSString *)getRequest:(NSString *)aRequestPath;

- (NSData *)getSHA1:(NSData *)aPlainText;

- (void)generateSecKeys;

- (NSString *)getExtensionsAsString:(NSArray *)aExtensions;

- (BOOL)supportsAnotherSupportedVersion:(NSString *)aResponse;

- (BOOL)isUpgradeResponse:(NSString *)aResponse;

- (NSMutableArray *)getServerExtensions:(NSMutableArray *)aServerHeaders;

- (BOOL)isValidServerExtension:(NSArray *)aServerExtensions;

- (void)sendClose:(NSUInteger)aStatusCode message:(NSString *)aMessage;

- (void)sendMessage:(NSData *)aMessage messageWithOpCode:(MessageOpCode)aOpCode;

- (void)sendMessage:(WebSocketFragment *)aFragment;

- (NSInteger)handleMessageData:(NSData *)aData offset:(NSUInteger)aOffset;

- (void)handleCompleteFragment:(WebSocketFragment *)aFragment;

- (void)handleCompleteFragments;

- (void)handleClose:(WebSocketFragment *)aFragment;

- (void)handlePing:(NSData *)aMessage;

- (void)closeSocket;

- (void)checkClose:(NSTimer *)aTimer;

- (NSString *)buildStringFromHeaders:(NSMutableArray *)aHeaders resource:(NSString *)aResource;

- (NSMutableArray *)buildHeadersFromString:(NSString *)aHeaders;

- (HandshakeHeader *)headerForKey:(NSString *)aKey inHeaders:(NSMutableArray *)aHeaders;

- (NSArray *)headersForKey:(NSString *)aKey inHeaders:(NSMutableArray *)aHeaders;
@end


@implementation WebSocket {
    BOOL isInContinuation;
}

NSString *const WebSocketException = @"WebSocketException";
NSString *const WebSocketErrorDomain = @"WebSocketErrorDomain";

enum {
    TagHandshake = 0,
    TagMessage = 1
};

WebSocketWaitingState waitingState;

@synthesize config;
@synthesize delegate;
@synthesize readystate;


#pragma mark Public Interface
- (void)open {
    UInt16 port = self.config.isSecure ? 443 : 80;
    if (self.config.url.port) {
        port = [self.config.url.port intValue];
    }
    NSError *error = nil;
    BOOL successful = false;
    @try {
        successful = [socket connectToHost:self.config.url.host onPort:port withTimeout:30 error:&error];
        if (self.config.version == WebSocketVersion07) {
            closeStatusCode = WebSocketCloseStatusNormal;
        }
        else {
            closeStatusCode = 0;
        }
        closeMessage = nil;
    }
    @catch (NSException *exception) {
        error = [NSError errorWithDomain:WebSocketErrorDomain code:0 userInfo:exception.userInfo];
    }
    @finally {
        if (!successful) {
            [self dispatchClosed:WebSocketCloseStatusProtocolError message:nil error:error];
        }
    }
}

- (void)close {
    [self close:WebSocketCloseStatusNormal message:nil];
}

- (void)close:(NSUInteger)aStatusCode message:(NSString *)aMessage {
    readystate = WebSocketReadyStateClosing;
    //any rev before 10 does not perform a UTF8 check
    if (self.config.version < WebSocketVersion10) {
        [self sendClose:aStatusCode message:aMessage];
    }
    else {
        if (aMessage && [aMessage canBeConvertedToEncoding:NSUTF8StringEncoding]) {
            [self sendClose:aStatusCode message:aMessage];
        }
        else {
            [self sendClose:aStatusCode message:nil];
        }
    }
    isClosing = YES;
}

- (void)scheduleForceCloseCheck {
    [NSTimer scheduledTimerWithTimeInterval:self.config.closeTimeout
                                     target:self
                                   selector:@selector(checkClose:)
                                   userInfo:nil repeats:NO];
}

- (void)checkClose:(NSTimer *)aTimer {
    if (self.readystate == WebSocketReadyStateClosing) {
        [self closeSocket];
    }
}

- (void)sendClose:(NSUInteger)aStatusCode message:(NSString *)aMessage {
    //create payload
    NSMutableData *payload = nil;
    if (aStatusCode > 0) {
        closeStatusCode = aStatusCode;
        payload = [NSMutableData data];
        unsigned char current = (unsigned char) (aStatusCode / 0x100);
        [payload appendBytes:&current length:1];
        current = (unsigned char) (aStatusCode % 0x100);
        [payload appendBytes:&current length:1];
        if (aMessage) {
            closeMessage = [aMessage copy];
            [payload appendData:[aMessage dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    //send close message
    [self sendMessage:[WebSocketFragment fragmentWithOpCode:MessageOpCodeClose isFinal:YES payload:payload]];

    //schedule the force close
    if (self.config.closeTimeout >= 0) {
        [self scheduleForceCloseCheck];
    }
}

- (void)sendText:(NSString *)aMessage {
    //no reason to grab data if we won't send it anyways
    if (!isClosing) {
        //only send non-nil data
        if (aMessage) {
            if ([aMessage canBeConvertedToEncoding:NSUTF8StringEncoding]) {
                [self sendMessage:[aMessage dataUsingEncoding:NSUTF8StringEncoding] messageWithOpCode:MessageOpCodeText];
            }
            else if (self.config.version >= WebSocketVersion10) {
                [self close:WebSocketCloseStatusInvalidData message:nil];
            }
        }
    }
}

- (void)sendBinary:(NSData *)aMessage {
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodeBinary];
}

- (void)sendPing:(NSData *)aMessage {
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodePing];
}

- (void)sendMessage:(NSData *)aMessage messageWithOpCode:(MessageOpCode)aOpCode {
    if (!isClosing) {
        BOOL isRSV1 = _deflate;
        if(_deflate) {
            NSData *deflated = [self deflate:aMessage];
            if(deflated) {
                aMessage = deflated;
            } else {
                isRSV1 = NO;
                NSLog(@"An error occured while compressing fragment, sending uncompressed");
            }
        }
        NSUInteger messageLength = [aMessage length];
        if (messageLength <= self.config.maxPayloadSize) {
            //create and send fragment
            WebSocketFragment *fragment = [WebSocketFragment fragmentWithOpCode:aOpCode isFinal:YES payload:aMessage];
            if(_deflate)
                fragment.isRSV1 = isRSV1;
            [fragment buildFragment];
            [self sendMessage:fragment];
        }
        else {
            NSMutableArray *fragments = [NSMutableArray array];
            NSUInteger fragmentCount = messageLength / self.config.maxPayloadSize;
            if (messageLength % self.config.maxPayloadSize) {
                fragmentCount++;
            }

            //build fragments
            for (int i = 0; i < fragmentCount; i++) {
                WebSocketFragment *fragment;
                NSUInteger fragmentLength = self.config.maxPayloadSize;
                if (i == 0) {
                    fragment = [WebSocketFragment fragmentWithOpCode:aOpCode isFinal:NO payload:[aMessage subdataWithRange:NSMakeRange(i * self.config.maxPayloadSize, fragmentLength)]];
                }
                else if (i == fragmentCount - 1) {
                    fragmentLength = messageLength % self.config.maxPayloadSize;
                    if (fragmentLength == 0) {
                        fragmentLength = self.config.maxPayloadSize;
                    }
                    fragment = [WebSocketFragment fragmentWithOpCode:MessageOpCodeContinuation isFinal:YES payload:[aMessage subdataWithRange:NSMakeRange(i * self.config.maxPayloadSize, fragmentLength)]];
                }
                else {
                    fragment = [WebSocketFragment fragmentWithOpCode:MessageOpCodeContinuation isFinal:NO payload:[aMessage subdataWithRange:NSMakeRange(i * self.config.maxPayloadSize, fragmentLength)]];
                }
                if(_deflate)
                    fragment.isRSV1 = YES;
                [fragments addObject:fragment];
            }

            //send fragments
            for (WebSocketFragment *fragment in fragments) {
                [self sendMessage:fragment];
            }
        }
    }
}

- (void)sendMessage:(WebSocketFragment *)aFragment {
    if (!isClosing || aFragment.opCode == MessageOpCodeClose) {
        [socket writeData:aFragment.fragment withTimeout:self.config.timeout tag:TagMessage];
    }
}


#pragma mark Internal Web Socket Logic
- (void)continueReadingMessageStream {
    [socket readDataWithTimeout:self.config.timeout tag:TagMessage];
}

- (void)repeatPing {
    if (readystate == WebSocketReadyStateOpen) {
        [self sendPing:nil];
    }
}

- (void)startPingTimer {
    if (self.config.keepAlive) {
        pingTimer = [NSTimer scheduledTimerWithTimeInterval:self.config.keepAlive target:self selector:@selector(repeatPing) userInfo:nil repeats:YES];
    }
}

- (void)stopPingTimer {
    if (pingTimer) {
        [pingTimer invalidate];
    }
}

- (void)closeSocket {
    readystate = WebSocketReadyStateClosing;
    [socket disconnectAfterWriting];
}

- (void)handleCompleteFragment:(WebSocketFragment *)aFragment {
    //if we are not in continuation and its final, dequeue
    if (aFragment.isFinal && aFragment.opCode != MessageOpCodeContinuation) {
        [pendingFragments removeLastObject];
    }

    //continue to process
    switch (aFragment.opCode) {
        case MessageOpCodeContinuation:
            if (aFragment.isFinal) {
                [self handleCompleteFragments];
            }
            break;
        case MessageOpCodeText:
            /*if (aFragment.isFinal) {
                if (aFragment.payloadData.length) {
                    NSString *textMsg = [[NSString alloc] initWithData:aFragment.payloadData encoding:NSUTF8StringEncoding];
                    if (textMsg) {
                        [self dispatchTextMessageReceived:textMsg];
                    }
                    else if (self.config.version >= WebSocketVersion10) {
                        [self close:WebSocketCloseStatusInvalidData message:nil];
                    }
                }
                else {
                    [self dispatchTextMessageReceived:@""];
                }
            }
            break;*/
        case MessageOpCodeBinary:
            if (aFragment.isFinal) {
                if(&deflate && aFragment.isRSV1)
                    [self dispatchBinaryMessageReceived:[self inflate:aFragment.payloadData]];
                else
                    [self dispatchBinaryMessageReceived:aFragment.payloadData];
            }
            break;
        case MessageOpCodeClose:
            [self handleClose:aFragment];
            break;
        case MessageOpCodePing:
            if (aFragment.payloadLength > 125) {
                [self close:WebSocketCloseStatusProtocolError message:@"Pings cannot have payloads longer than 125 octets."];
            } else {
                [self handlePing:aFragment.payloadData];
            }
            break;
    }
}

//Based on http://stackoverflow.com/a/11389847
- (NSData *)inflate:(NSData*)d
{
    @synchronized(zlibLock) {
        if([d length] == 0)
            return d;

        //Append 0x00 0x00 0xFF 0xFF
        unsigned char tail[4] = {0,0,255,255};
        NSMutableData *data = [d mutableCopy];
        [data appendBytes:tail length:4];
        
        NSUInteger full_length = [data length];
        NSUInteger half_length = [data length] / 2;
        
        NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
        BOOL done = NO;
        int status;
        
        zstrm_in.next_in = (Bytef *)[data bytes];
        zstrm_in.avail_in = (unsigned int)[data length];
        zstrm_in.total_out = 0;
        
        while (!done) {
            // Make sure we have enough room and reset the lengths.
            if (zstrm_in.total_out >= [decompressed length])
                [decompressed increaseLengthBy: half_length];
            zstrm_in.next_out = [decompressed mutableBytes] + zstrm_in.total_out;
            zstrm_in.avail_out = (unsigned int)([decompressed length] - zstrm_in.total_out);
            
            // Inflate another chunk.
            status = inflate(&zstrm_in, Z_FULL_FLUSH);
            if(zstrm_in.avail_in == 0)
                done = YES;
            else if (status != Z_OK && status != Z_BUF_ERROR)
                break;
        }
        
        // Set real length.
        if (done) {
            [decompressed setLength: zstrm_in.total_out];
            return [NSData dataWithData: decompressed];
        } else
            return nil;
    }
}

- (NSData *)deflate:(NSData*)data
{
    @synchronized(zlibLock) {
        if ([data length] == 0)
            return nil;
        
        zstrm_out.next_in=(Bytef *)[data bytes];
        zstrm_out.avail_in = (unsigned int)[data length];
        zstrm_out.total_out = 0;
        
        NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
        
        do {
            if (zstrm_out.total_out >= [compressed length])
                [compressed increaseLengthBy: 16384];
            
            zstrm_out.next_out = [compressed mutableBytes] + zstrm_out.total_out;
            zstrm_out.avail_out = (unsigned int)([compressed length] - zstrm_out.total_out);
            
            deflate(&zstrm_out, Z_FULL_FLUSH);
            
        } while (zstrm_out.avail_out == 0);
        
        //Chop off the 0x00 0x00 0xFF 0xFF from the tail
        if(zstrm_out.total_out)
            [compressed setLength: zstrm_out.total_out - 4];
        else
            return nil;
        return [NSData dataWithData:compressed];
    }
}

- (void)handleCompleteFragments {
    WebSocketFragment *fragment = [pendingFragments dequeue];
    if (fragment != nil) {
        //init
        NSMutableData *messageData = [NSMutableData data];
        MessageOpCode messageOpCode = fragment.opCode;

        //loop through, constructing single message
        while (fragment != nil) {
            if (fragment.payloadLength > 0) {
                if(&deflate && fragment.isRSV1)
                    [messageData appendData:[self inflate:fragment.payloadData]];
                else
                    [messageData appendData:fragment.payloadData];
            }
            fragment = [pendingFragments dequeue];
        }

        //handle final message contents        
        switch (messageOpCode) {
            case MessageOpCodeText: {
                if (messageData.length) {
                    NSString *textMsg = [[NSString alloc] initWithData:messageData encoding:NSUTF8StringEncoding];
                    if (textMsg) {
                        [self dispatchTextMessageReceived:textMsg];
                    }
                    else if (self.config.version >= WebSocketVersion10) {
                        [self close:WebSocketCloseStatusInvalidData message:nil];
                    }
                } else {
                    [self dispatchTextMessageReceived:@""];
                }
                break;
            }
            case MessageOpCodeBinary:
                [self dispatchBinaryMessageReceived:messageData];
                break;
        }
    }
}

- (void)handleClose:(WebSocketFragment *)aFragment {
    //close status & message
    BOOL invalidUTF8 = NO;
    if (aFragment.payloadData) {
        NSUInteger length = aFragment.payloadData.length;
        if (length >= 2) {
            //get status code
            unsigned char buffer[2];
            [aFragment.payloadData getBytes:&buffer length:2];
            closeStatusCode = buffer[0] << 8 | buffer[1];

            //get message
            if (length > 2) {
                closeMessage = [[NSString alloc] initWithData:[aFragment.payloadData subdataWithRange:NSMakeRange(2, length - 2)] encoding:NSUTF8StringEncoding];
                if (!closeMessage) {
                    invalidUTF8 = YES;
                }
            }
        }
    }

    //handle close
    if (isClosing) {
        [self closeSocket];
    }
    else {
        isClosing = YES;
        if (!invalidUTF8 || self.config.version < WebSocketVersion10) {
            [self close:0 message:nil];
        }
        else {
            [self close:WebSocketCloseStatusInvalidData message:nil];
        }
    }
}

- (void)handlePing:(NSData *)aMessage {
    [self sendMessage:aMessage messageWithOpCode:MessageOpCodePong];
    if ([delegate respondsToSelector:@selector(didSendPong:)]) {
        [delegate didSendPong:aMessage];
    }
}

// TODO: use a temporary buffer for the fragment payload instead of a queue of fragments
- (NSInteger)handleMessageData:(NSData *)aData offset:(NSUInteger)aOffset {
    //init
    NSUInteger lengthOfRemainder = 0;
    NSUInteger existingLength = 0;
    NSInteger offset = -1;

    //grab last fragment, use if not complete
    WebSocketFragment *fragment = [pendingFragments lastObject];
    if (!fragment || fragment.isValid) {
        //assign web socket fragment since the last one was complete
        fragment = [[WebSocketFragment alloc] init];
        [pendingFragments enqueue:fragment];
    }
    else {
        //grab existing length
        existingLength = fragment.fragment.length;
    }
    NSAssert(fragment != nil, @"Websocket fragment should never be nil");

    //if we dont know the length - try to figure it out
    if (!fragment.isHeaderValid) {
        [fragment parseHeader];

        //if we still don't have a length, see if we have enough
        if (!fragment.isHeaderValid) {
            if (![fragment parseHeader:aData from:aOffset]) {
                //if we still don't have a valid length, append all data and return
                if (fragment.fragment) {
                    [fragment.fragment appendData:[aData subdataWithRange:NSMakeRange(aOffset, aData.length - aOffset)]];
                } else {
                    fragment.fragment = [NSMutableData dataWithData:[aData subdataWithRange:NSMakeRange(aOffset, aData.length - aOffset)]];
                }
                return offset;
            }
        }
    }

    //validate reserved bits
    if (!self.config.activeExtensionModifiesReservedBits) {
        if (!&deflate || fragment.isRSV2 || fragment.isRSV3) {
            [self close:WebSocketCloseStatusProtocolError message:[NSString stringWithFormat:@"No extension is defined that modifies reserved bits: RSV1=%@, RSV2=%@, RSV3=%@", fragment.isRSV1 ? @"YES" : @"NO", fragment.isRSV2 ? @"YES" : @"NO", fragment.isRSV3 ? @"YES" : @"NO"]];
        }
    }

    //make sure we have a valid op code
    if (fragment.opCode != MessageOpCodeContinuation && fragment.opCode != MessageOpCodeText && fragment.opCode != MessageOpCodeBinary && fragment.opCode != MessageOpCodeClose && fragment.opCode != MessageOpCodePing && fragment.opCode != MessageOpCodePong) {
        [self close:WebSocketCloseStatusProtocolError message:@"Illegal Opcode"];
    }

    //disallow fragmented control op codes
    if (fragment.opCode == MessageOpCodePing || fragment.opCode == MessageOpCodePong) {
        if (!fragment.isFinal) {
            [self close:WebSocketCloseStatusProtocolError message:@"Control frames cannot be fragmented"];
        }
    }

    //validate continuation state
    if (fragment.isFinal) {
        if (fragment.opCode == MessageOpCodeContinuation && !isInContinuation) {
            [self close:WebSocketCloseStatusProtocolError message:[NSString stringWithFormat:@"Cannot send the final fragment without a fragmented stream: isFinal=%@, opCode=%li", fragment.isFinal ? @"YES" : @"NO", (long)fragment.opCode]];
        } else if (isInContinuation && !fragment.isControlFrame && fragment.opCode != MessageOpCodeContinuation) {
            [self close:WebSocketCloseStatusProtocolError message:[NSString stringWithFormat:@"Cannot embed complete messages in a fragmented stream: isFinal=%@, opCode=%li", fragment.isFinal ? @"YES" : @"NO", (long)fragment.opCode]];
        }
    } else if (isInContinuation && fragment.opCode != MessageOpCodeContinuation) {
        [self close:WebSocketCloseStatusProtocolError message:[NSString stringWithFormat:@"Cannot embed non-control, non-continuation frames in a fragmented stream: isFinal=%@, opCode=%li", fragment.isFinal ? @"YES" : @"NO", (long)fragment.opCode]];
    } else if (!isInContinuation && fragment.opCode != MessageOpCodeText && fragment.opCode != MessageOpCodeBinary) {
        [self close:WebSocketCloseStatusProtocolError message:@"Illegal continuation start frame"];
    }

    //determine data length
    NSUInteger possibleDataLength = aData.length - aOffset;
    NSUInteger actualDataLength = possibleDataLength;
    if ((possibleDataLength + existingLength > fragment.messageLength)) {
        lengthOfRemainder = possibleDataLength - (fragment.messageLength - existingLength);
        actualDataLength = possibleDataLength - lengthOfRemainder;
    }

    unsigned char *actualData = malloc(actualDataLength);
    [aData getBytes:actualData range:NSMakeRange(aOffset, actualDataLength)];
    
    if (fragment.fragment) {
        [fragment.fragment appendBytes:actualData length:actualDataLength];
    } else {
        fragment.fragment = [NSMutableData dataWithBytes:actualData length:actualDataLength];
    }
    free(actualData);

    //parse the data, if possible
    if (fragment.canBeParsed) {
        if (fragment.hasMask) {
            //client is not allowed to receive data that is masked and must fail the connection
            [self close:WebSocketCloseStatusProtocolError message:@"Server cannot mask data."];
            return offset;
        }
        [fragment parseContent];

        //if we have a complete fragment, handle it
        if (fragment.isValid && fragment.isFinal) {
            [self handleCompleteFragment:fragment];
        }
    }

    //if we have extra data, handle it
    if (fragment.messageLength > 0) {
        //if we have an offset, trim the data and call back into
        if (lengthOfRemainder > 0) {
            offset = actualDataLength + aOffset;
        }
    }

    //set continuation state, if we have a valid fragment
    if (fragment.isValid) {
        if (fragment.isFinal && fragment.opCode == MessageOpCodeContinuation && isInContinuation) {
            isInContinuation = NO;
        } else if (!fragment.isFinal && (fragment.opCode == MessageOpCodeText || fragment.opCode == MessageOpCodeBinary)) {
            isInContinuation = YES;
        }
    }

    return offset;
}

- (NSData *)getSHA1:(NSData *)aPlainText {
    CC_SHA1_CTX ctx;
    uint8_t *hashBytes;
    NSData *hash;

    // Malloc a buffer to hold hash.
    hashBytes = malloc(CC_SHA1_DIGEST_LENGTH * sizeof(uint8_t));
    memset((void *) hashBytes, 0x0, CC_SHA1_DIGEST_LENGTH);

    // Initialize the context.
    CC_SHA1_Init(&ctx);
    // Perform the hash.
    CC_SHA1_Update(&ctx, (void *) [aPlainText bytes], (CC_LONG)[aPlainText length]);
    // Finalize the output.
    CC_SHA1_Final(hashBytes, &ctx);

    // Build up the SHA1 blob.
    hash = [NSData dataWithBytes:(const void *) hashBytes length:(NSUInteger) CC_SHA1_DIGEST_LENGTH];

    if (hashBytes) free(hashBytes);

    return hash;
}

- (NSString *)getRequest:(NSString *)aRequestPath {
    //create headers if they are missing
    NSMutableArray *headers = self.config.headers;
    if (headers == nil) {
        headers = [NSMutableArray array];
        self.config.headers = headers;
    }

    //handle security keys
    [self generateSecKeys];
    [headers addObject:[HandshakeHeader headerWithValue:wsSecKey forKey:@"Sec-WebSocket-Key"]];

    //handle host
    [headers addObject:[HandshakeHeader headerWithValue:self.config.host forKey:@"Host"]];

    //handle origin
    if (self.config.useOrigin) {
        if (self.config.version < WebSocketVersionRFC6455) {
            [headers addObject:[HandshakeHeader headerWithValue:self.config.origin forKey:@"Sec-WebSocket-Origin"]];
        } else {
            [headers addObject:[HandshakeHeader headerWithValue:self.config.origin forKey:@"Origin"]];
        }
    }

    //handle version
    if (self.config.version == WebSocketVersion10) {
        [headers addObject:[HandshakeHeader headerWithValue:[NSString stringWithFormat:@"%i", 8] forKey:@"Sec-WebSocket-Version"]];
    } else if (self.config.version == WebSocketVersionRFC6455) {
        [headers addObject:[HandshakeHeader headerWithValue:[NSString stringWithFormat:@"%i", 13] forKey:@"Sec-WebSocket-Version"]];
    } else {
        [headers addObject:[HandshakeHeader headerWithValue:[NSString stringWithFormat:@"%lu", (unsigned long)self.config.version] forKey:@"Sec-WebSocket-Version"]];
    }

    //handle protocol
    if (self.config.protocols && self.config.protocols.count > 0) {
        //build protocol fragment
        NSMutableString *protocolFragment = [NSMutableString string];
        for (NSString *item in self.config.protocols) {
            if ([protocolFragment length] > 0) {
                [protocolFragment appendString:@", "];
            }
            [protocolFragment appendString:item];
        }

        //include protocols, if any
        if ([protocolFragment length] > 0) {
            [headers addObject:[HandshakeHeader headerWithValue:protocolFragment forKey:@"Sec-WebSocket-Protocol"]];
        }
    }

    //handle extensions
    if (self.config.extensions && self.config.extensions.count > 0) {
        //build extensions fragment
        NSString *extensionFragment = [self getExtensionsAsString:self.config.extensions];

        //return request with extensions
        if ([extensionFragment length] > 0) {
            [headers addObject:[HandshakeHeader headerWithValue:extensionFragment forKey:@"Sec-WebSocket-Extensions"]];
        }
    }

    return [self buildStringFromHeaders:headers resource:aRequestPath];
}

- (NSString *)getExtensionsAsString:(NSArray *)aExtensions {
    NSMutableString *extensionFragment = [NSMutableString string];
    for (id item in aExtensions) {
        if ([item isKindOfClass:[NSString class]]) {
            if ([extensionFragment length] > 0) {
                [extensionFragment appendString:@"; "];
            }
            [extensionFragment appendString:(NSString *) item];
        }
        else if ([item isKindOfClass:[NSArray class]]) {
            //build ordered list of extensions
            NSArray *items = (NSArray *) item;
            NSMutableString *itemFragment = [NSMutableString string];
            for (NSString *childItem in items) {
                if ([itemFragment length] > 0) {
                    [itemFragment appendString:@", "];
                }
                [itemFragment appendString:childItem];
            }

            //add to list of extensions
            if ([extensionFragment length] > 0) {
                [extensionFragment appendString:@"; "];
            }
            [extensionFragment appendString:itemFragment];
        }
    }
    return extensionFragment;
}

- (NSString *)buildStringFromHeaders:(NSMutableArray *)aHeaders resource:(NSString *)aResource {
    //init
    NSMutableString *result = [NSMutableString stringWithFormat:@"GET %@ HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n", aResource];

    //add headers
    if (aHeaders) {
        for (HandshakeHeader *header in aHeaders) {
            if (header) {
                [result appendFormat:@"%@: %@\r\n", header.key, header.value];
            }
        }
    }

    //add terminator
    [result appendFormat:@"\r\n"];

    return result;
}

- (NSMutableArray *)buildHeadersFromString:(NSString *)aHeaders {
    NSMutableArray *results = [NSMutableArray array];
    NSArray *listItems = [aHeaders componentsSeparatedByString:@"\r\n"];
    for (NSString *item in listItems) {
        NSRange range = [item rangeOfString:@":" options:NSLiteralSearch];
        if (range.location != NSNotFound) {
            NSString *key = [item substringWithRange:NSMakeRange(0, range.location)];
            key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *value = [item substringFromIndex:range.length + range.location];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [results addObject:[HandshakeHeader headerWithValue:value forKey:key]];
        }
    }
    return results;
}

- (void)generateSecKeys {
    NSString *initialString = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    NSData *data = [initialString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *key = [data base64EncodedString];
    wsSecKey = [key copy];
    key = [NSString stringWithFormat:@"%@%@", wsSecKey, @"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"];
    data = [self getSHA1:[key dataUsingEncoding:NSUTF8StringEncoding]];
    key = [data base64EncodedString];
    wsSecKeyHandshake = [key copy];
}

- (HandshakeHeader *)headerForKey:(NSString *)aKey inHeaders:(NSMutableArray *)aHeaders {
    for (HandshakeHeader *header in aHeaders) {
        if (header) {
            if ([header keyMatchesCaseInsensitiveString:aKey]) {
                return header;
            }
        }
    }

    return nil;
}

- (NSArray *)headersForKey:(NSString *)aKey inHeaders:(NSMutableArray *)aHeaders {
    NSMutableArray *results = [NSMutableArray array];

    for (HandshakeHeader *header in aHeaders) {
        if (header) {
            if ([header keyMatchesCaseInsensitiveString:aKey]) {
                [results addObject:header];
            }
        }
    }

    return results;
}

- (BOOL)supportsAnotherSupportedVersion:(NSString *)aResponse {
    //a HTTP 400 response is the only valid one
    if ([aResponse hasPrefix:@"HTTP/1.1 400"]) {
        return [aResponse rangeOfString:@"Sec-WebSocket-Version"].location != NSNotFound;
    }

    return false;
}

- (BOOL)isUpgradeResponse:(NSString *)aResponse {
    //a HTTP 101 response is the only valid one
    if ([aResponse hasPrefix:@"HTTP/1.1 101"]) {
        //build headers
        self.config.serverHeaders = [self buildHeadersFromString:aResponse];

        //check security key, if requested
        if (self.config.verifySecurityKey) {
            HandshakeHeader *header = [self headerForKey:@"Sec-WebSocket-Accept" inHeaders:self.config.serverHeaders];
            if (![wsSecKeyHandshake isEqualToString:header.value]) {
                return false;
            }
        }

        //verify we have a "Upgrade: websocket" header
        HandshakeHeader *header = [self headerForKey:@"Upgrade" inHeaders:self.config.serverHeaders];
        if (header.value && [@"websocket" caseInsensitiveCompare:header.value] != NSOrderedSame) {
            return false;
        }

        //verify we have a "Connection: Upgrade" header
        header = [self headerForKey:@"Connection" inHeaders:self.config.serverHeaders];
        if (header.value && [@"Upgrade" caseInsensitiveCompare:header.value] != NSOrderedSame) {
            return false;
        }

        //verify that version specified matches the version we requested


        return true;
    }

    return false;
}

- (void)sendHandshake:(GCDAsyncSocket*)aSocket {
    //continue with handshake
    NSString *requestPath = self.config.url.path;
    if (requestPath == nil || requestPath.length == 0) {
        requestPath = @"/";
    }
    if (self.config.url.query) {
        requestPath = [requestPath stringByAppendingFormat:@"?%@", self.config.url.query];
    }
    NSString *getRequest = [self getRequest:requestPath];
    [aSocket writeData:[getRequest dataUsingEncoding:NSASCIIStringEncoding] withTimeout:self.config.timeout tag:TagHandshake];
}

- (NSMutableArray *)getServerVersions:(NSMutableArray *)aServerHeaders {
    NSMutableArray *results = [NSMutableArray array];
    NSMutableArray *tempResults = [NSMutableArray array];

    //find all entries keyed by Sec-WebSocket-Version or Sec-WebSocket-Version-Server
//    [tempResults addObjectsFromArray:[self headersForKey:@"Sec-WebSocket-Version" inHeaders:self.config.serverHeaders]];
//    [tempResults addObjectsFromArray:[self headersForKey:@"Sec-WebSocket-Version-Server" inHeaders:self.config.serverHeaders]];
    [tempResults addObjectsFromArray:[self headersForKey:@"Sec-WebSocket-Version" inHeaders:aServerHeaders]];
    [tempResults addObjectsFromArray:[self headersForKey:@"Sec-WebSocket-Version-Server" inHeaders:aServerHeaders]];

    //loop through values trimming and adding to versions
    for (HandshakeHeader *header in tempResults) {
        NSString *extensionValues = header.value;
        NSArray *listItems = [extensionValues componentsSeparatedByString:@","];
        for (NSString *item in listItems) {
            if (item) {
                NSString *value = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (value && value.length) {
                    [results addObject:value];
                }
            }
        }
    }

    return results;
}

- (NSMutableArray *)getServerExtensions:(NSMutableArray *)aServerHeaders {
    NSMutableArray *results = [NSMutableArray array];

    //loop through values trimming and adding to extensions 
//    HandshakeHeader *header = [self headerForKey:@"Sec-WebSocket-Extensions" inHeaders:self.config.serverHeaders];
    HandshakeHeader *header = [self headerForKey:@"Sec-WebSocket-Extensions" inHeaders:aServerHeaders];
    if (header) {
        NSString *extensionValues = header.value;
        NSArray *listItems = [extensionValues componentsSeparatedByString:@","];
        for (NSString *item in listItems) {
            if (item) {
                NSString *value = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                if (value && value.length) {
                    [results addObject:value];
                }
            }
        }
    }

    return results;
}

- (BOOL)isValidServerExtension:(NSArray *)aServerExtensions {
    if (self.config.extensions && self.config.extensions.count > 0) {
        //if we only have one extension, see if its in our list of accepted extensions
        if (aServerExtensions.count == 1) {
            NSString *serverExtension = [aServerExtensions objectAtIndex:0];
            for (id item in self.config.extensions) {
                if ([item isKindOfClass:[NSString class]]) {
                    if ([serverExtension isEqualToString:(NSString *) item]) {
                        return YES;
                    }
                }
            }
        }

        //if we have a list of extensions, see if this exact ordered list exists in our list of accepted extensions
        for (id item in self.config.extensions) {
            if ([item isKindOfClass:[NSArray class]]) {
                if ([aServerExtensions isEqualToArray:(NSArray *) item]) {
                    return YES;
                }
            }
        }

        return NO;
    }

    return (aServerExtensions == nil || aServerExtensions.count == 0);
}


#pragma mark Web Socket Delegate
- (void)dispatchFailure:(NSError *)aError {
    if (delegate) {
        [delegate webSocket:self didReceiveError:aError];
       /* if (delegateQueue) {
            dispatch_async(delegateQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [delegate didReceiveError:aError];
                [pool drain];
            });

        } else {
            [delegate didReceiveError:aError];
        }*/
    }
}

- (void)dispatchClosed:(NSUInteger)aStatusCode message:(NSString *)aMessage error:(NSError *)aError {
    [self stopPingTimer];
    if (delegate) {
        [delegate webSocket:self didClose:aStatusCode message:aMessage error:aError];
        /*if (delegateQueue) {
            dispatch_async(delegateQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [delegate didClose:aStatusCode message:aMessage error:aError];
                [pool drain];
            });

        } else {
            [delegate didClose:aStatusCode message:aMessage error:aError];
        }*/
    }
}

- (void)dispatchOpened {
    if (delegate) {
        [delegate webSocketDidOpen:self];
        /*if (delegateQueue) {
            dispatch_async(delegateQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [delegate didOpen];
                [pool drain];
            });

        } else {
            [delegate didOpen];
        }*/
    }
    [self startPingTimer];
}

- (void)dispatchTextMessageReceived:(NSString *)aMessage {
    if (delegate) {
        [delegate webSocket:self didReceiveTextMessage:aMessage];
        /*if (delegateQueue) {
            dispatch_async(delegateQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [delegate didReceiveTextMessage:aMessage];
                [pool drain];
            });

        } else {
            [delegate didReceiveTextMessage:aMessage];
        }*/
    }
}

- (void)dispatchBinaryMessageReceived:(NSData *)aMessage {
    if (delegate) {
        [delegate webSocket:self didReceiveBinaryMessage:aMessage];
        /*if (delegateQueue) {
            dispatch_async(delegateQueue, ^{
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                [delegate didReceiveBinaryMessage:aMessage];
                [pool drain];
            });

        } else {
            [delegate didReceiveBinaryMessage:aMessage];
        }*/
    }
}


#pragma mark GCDAsyncSocket Delegate
- (void)socketDidDisconnect:(GCDAsyncSocket*)aSocket withError:(NSError*)aError {
    if (readystate != WebSocketReadyStateClosing && readystate != WebSocketReadyStateClosed) {
        closingError = aError;
    } else {
        closingError = nil;
    }
    readystate = WebSocketReadyStateClosed;
    if (self.config.version > WebSocketVersion07) {
        if (closeStatusCode == 0) {
            if (closingError != nil) {
                closeStatusCode = WebSocketCloseStatusAbnormalButMissingStatus;
            }
            else {
                closeStatusCode = WebSocketCloseStatusNormalButMissingStatus;
            }
        }
    }
    //End the zlib session
    inflateEnd(&zstrm_in);
    deflateEnd(&zstrm_out);
    zstrm_in.total_out = 0;
    zstrm_out.total_out = 0;
    
    [self dispatchClosed:closeStatusCode message:closeMessage error:closingError];
}

- (void)socketDidSecure:(GCDAsyncSocket*)aSocket;{
    [aSocket performBlock:^{
        if (self.config.isSecure) {
            if(self.config.tlsSettings && [self.config.tlsSettings objectForKey:@"fingerprints"]) {
                SSLContextRef ctx = socket.sslContext;
                if(ctx != NULL) {
                    SecTrustRef tm;
                    SSLCopyPeerTrust(ctx, &tm);
                    if(tm != NULL) {
                        SecCertificateRef cert = SecTrustGetCertificateAtIndex(tm, 0);
                        CFDataRef data = SecCertificateCopyData(cert);
                        const unsigned char *bytes = CFDataGetBytePtr(data);
                        CFIndex len = CFDataGetLength(data);
                        unsigned char sha1[CC_SHA1_DIGEST_LENGTH];
                        CC_SHA1(bytes, (CC_LONG)len, sha1);
                        NSMutableString *hex = [[NSMutableString alloc] initWithCapacity:len*2];
                        for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
                            [hex appendFormat:@"%02X", sha1[i]];
                        }
                        CFRelease(data);
                        CFRelease(tm);
                        BOOL matched = NO;
                        for(NSString *fingerprint in [self.config.tlsSettings objectForKey:@"fingerprints"]) {
                            if([fingerprint isEqualToString:hex]) {
                                matched = YES;
                                break;
                            }
                        }
                        if(!matched) {
                            [self close:WebSocketCloseStatusTlsHandshakeError message:@"Fingerprint mismatch"];
                            [self dispatchClosed:WebSocketCloseStatusTlsHandshakeError message:@"Fingerprint mismatch" error:[NSError errorWithDomain:WebSocketErrorDomain code:WebSocketCloseStatusTlsHandshakeError userInfo:nil]];
                            return;
                        }
                    }
                }
            }
            [self sendHandshake:aSocket];
        }
    }];
}

- (NSTimeInterval)socket:(GCDAsyncSocket*)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    return self.config.timeout;
}

- (NSTimeInterval)socket:(GCDAsyncSocket*)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    return self.config.timeout;
}

- (void)socket:(GCDAsyncSocket*)aSocket didConnectToHost:(NSString *)aHost port:(UInt16)aPort {
    //start TLS if this is a secure websocket
    if (self.config.isSecure) {
        // Configure SSL/TLS settings
        NSDictionary *settings = self.config.tlsSettings;

        //seed with defaults if missing
        if (!settings) {
            settings = [NSMutableDictionary dictionaryWithCapacity:3];
        }

        [socket startTLS:settings];
    }
    else {
        [self sendHandshake:aSocket];
    }
}

- (void)socket:(GCDAsyncSocket*)aSocket didWriteDataWithTag:(long)aTag {
    if (aTag == TagHandshake) {
        [aSocket readDataToData:[@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding] withTimeout:self.config.timeout tag:TagHandshake];
    }
}

- (void)socket:(GCDAsyncSocket*)aSocket didReadData:(NSData *)aData withTag:(long)aTag {
    if (aTag == TagHandshake) {
        NSString *response = [[NSString alloc] initWithData:aData encoding:NSASCIIStringEncoding];
        if ([self isUpgradeResponse:response]) {
            //grab protocol from server
            HandshakeHeader *header = [self headerForKey:@"Sec-WebSocket-Protocol" inHeaders:self.config.serverHeaders];
            if (!header) {
                header = [self headerForKey:@"Sec-WebSocket-Protocol-Server" inHeaders:self.config.serverHeaders];
            }
            if (header) {
                //if version is rfc6455 or later, null out value if it was not a requested protocol
                if (self.config.version < WebSocketVersionRFC6455 || [self.config.protocols containsObject:header]) {
                    self.config.serverProtocol = header.value;
                }
            }

            //grab extensions from the server
            _deflate = NO;
            NSMutableArray *extensions = [self getServerExtensions:self.config.serverHeaders];
            if (extensions) {
                self.config.serverExtensions = extensions;
                for(NSString *extension in extensions) {
                    if([extension hasPrefix:@"x-webkit-deflate-frame"]) {
                        if(zstrm_in.total_out > 0)
                            inflateEnd(&zstrm_in);
                        memset(&zstrm_in, 0, sizeof(zstrm_in));
                        zstrm_in.zalloc = Z_NULL;
                        zstrm_in.zfree = Z_NULL;
                        inflateInit2(&zstrm_in,-15);
                        if(zstrm_out.total_out > 0)
                            deflateEnd(&zstrm_out);
                        memset(&zstrm_out, 0, sizeof(zstrm_out));
                        zstrm_out.zalloc = Z_NULL;
                        zstrm_out.zfree = Z_NULL;
                        deflateInit2(&zstrm_out, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -15, 8, Z_DEFAULT_STRATEGY);
                        _deflate = YES;
                    }
                }
            }

            //handle state & delegates
            readystate = WebSocketReadyStateOpen;
            [self dispatchOpened];
            [self continueReadingMessageStream];
        }
        else if ([self supportsAnotherSupportedVersion:response]) {
            //use property to determine if we try a different version
            BOOL retry = NO;
            NSArray *versions = [self getServerVersions:self.config.serverHeaders];
            if (self.config.retryOtherVersion) {
                for (NSString *version in versions) {
                    if (version && version.length) {
                        switch ([version intValue]) {
                            case WebSocketVersion07:
                                self.config.version = WebSocketVersion07;
                                retry = YES;
                                break;
                            case WebSocketVersion10:
                                self.config.version = WebSocketVersion10;
                                retry = YES;
                                break;
                        }
                    }
                }
            }

            //retry if able
            if (retry) {
                [self open];
            }
            else {
                //send failure since we can't retry a supported version
                [self dispatchFailure:[NSError errorWithDomain:WebSocketErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unsupported Version", NSLocalizedDescriptionKey, response, NSLocalizedFailureReasonErrorKey, nil]]];
            }
        }
        else {
            [self dispatchFailure:[NSError errorWithDomain:WebSocketErrorDomain code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Bad handshake", NSLocalizedDescriptionKey, response, NSLocalizedFailureReasonErrorKey, nil]]];
        }
    }
    else if (aTag == TagMessage) {
        //handle data
        NSInteger offset = 0;
        do {
            offset = [self handleMessageData:aData offset:offset];
        } while (offset >= 0);

        //keep reading
        [self continueReadingMessageStream];
    }
}


#pragma mark Lifecycle
+ (id)webSocketWithConfig:(WebSocketConnectConfig *)aConfig delegate:(id <WebSocketDelegate>)aDelegate {
    return [[[self class] alloc] initWithConfig:aConfig delegate:aDelegate];
}

+ (id)webSocketWithConfig:(WebSocketConnectConfig *)aConfig queue:(dispatch_queue_t)aDispatchQueue delegate:(id <WebSocketDelegate>)aDelegate {
    return [[[self class] alloc] initWithConfig:aConfig queue:aDispatchQueue delegate:aDelegate];
}

- (id)initWithConfig:(WebSocketConnectConfig *)aConfig delegate:(id <WebSocketDelegate>)aDelegate {
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    NSString *uuidString = (NSString *) CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    NSString *gcdDelegateQueueName = [NSString stringWithFormat:@"com.unitt.ws.delegate:%@", uuidString];
    dispatch_queue_t gcdDelegateQueue = dispatch_queue_create([gcdDelegateQueueName cStringUsingEncoding:NSASCIIStringEncoding], NULL);
    id result = [self initWithConfig:aConfig queue:gcdDelegateQueue delegate:aDelegate];
    return result;
}

- (id)initWithConfig:(WebSocketConnectConfig *)aConfig queue:(dispatch_queue_t)aDispatchQueue delegate:(id <WebSocketDelegate>)aDelegate {
    self = [super init];
    if (self) {
        //apply properties
        self.delegate = aDelegate;
        self.config = aConfig;
        delegateQueue = aDispatchQueue;
        socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:delegateQueue];
        pendingFragments = [[MutableQueue alloc] init];
        isClosing = NO;
        isInContinuation = NO;
        zlibLock = [[NSObject alloc] init];
    }
    return self;
}

@end
