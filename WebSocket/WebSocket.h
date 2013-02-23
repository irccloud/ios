//
//  WebSocket.h
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


#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import "NSData+Base64.h"
#import "MutableQueue.h"
#import "WebSocketConnectConfig.h"


enum 
{
    WebSocketCloseStatusNormal = 1000, //indicates a normal closure, meaning whatever purpose the 
                                       //connection was established for has been fulfilled
    WebSocketCloseStatusEndpointGone = 1001, //indicates that an endpoint is "going away", such as a 
                                             //server going down, or a browser having navigated away from 
                                             //a page
    WebSocketCloseStatusProtocolError = 1002, //indicates that an endpoint is terminating the connection 
                                              //due to a protocol error
    WebSocketCloseStatusInvalidDataType = 1003, //indicates that an endpoint is terminating the connection
                                                //because it has received a type of data it cannot accept 
                                                //(e.g. an endpoint that understands only text data MAY 
                                                //send this if it receives a binary message)
    WebSocketCloseStatusLegacyMessageTooLarge = 1004, //indicates that an endpoint is terminating the connection
                                                //because it has received a message that is too large (prior to rfc6455)
    WebSocketCloseStatusNormalButMissingStatus = 1005, //designated for use in applications expecting a status code 
                                                       //to indicate that no status code was actually present
    WebSocketCloseStatusAbnormalButMissingStatus = 1006, //designated for use in applications expecting a status code
                                                         //to indicate that the connection was closed abnormally, e.g.
                                                         //without sending or receiving a Close control frame.
    WebSocketCloseStatusInvalidData = 1007, //indicates that an endpoint is terminating the connection because it has
                                           //received data that is invalid, ex: supposed be UTF-8 (such as in a text frame)
                                           // that was in fact not valid UTF-8
    WebSocketCloseStatusViolatesPolicy = 1008, //indicates that an endpoint is terminating the connection because it has
                                         // received a message that violates its policy.  This is a generic status code
                                         // that can be returned when there is no other more suitable status code
                                         // or if there is a need to hide specific details about the policy.
    WebSocketCloseStatusMessageTooLarge = 1009, //indicates that an endpoint is terminating the connection
                                                //because it has received a message that is too large
    WebSocketCloseStatusMissingExtensions = 1010, //indicates that an endpoint (client) is terminating the connection because
                                                // it has expected the server to negotiate one or more extension, but the
                                                // server didn't return them in the response message of the WebSocket handshake
    WebSocketCloseStatusServerError = 1011, //indicates that a server is terminating the connection because it encountered an
                                            // unexpected condition that prevented it from fulfilling the request
    WebSocketCloseStatusTlsHandshakeError = 1015 //indicate that the connection was closed due to a failure to perform a TLS handshake
};
typedef NSUInteger WebSocketCloseStatus;

enum 
{
    WebSocketReadyStateConnecting = 0, //The connection has not yet been established.
    WebSocketReadyStateOpen = 1, //The WebSocket connection is established and communication is possible.
    WebSocketReadyStateClosing = 2, //The connection is going through the closing handshake.
    WebSocketReadyStateClosed = 3 //The connection has been closed or could not be opened
};
typedef NSUInteger WebSocketReadyState;


@protocol WebSocketDelegate <NSObject>

/**
 * Called when the web socket connects and is ready for reading and writing.
 **/
- (void) didOpen;

/**
 * Called when the web socket closes. aError will be nil if it closes cleanly.
 **/
- (void) didClose:(NSUInteger) aStatusCode message:(NSString*) aMessage error:(NSError*) aError;

/**
 * Called when the web socket receives an error. Such an error can result in the
 socket being closed.
 **/
- (void) didReceiveError:(NSError*) aError;

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveTextMessage:(NSString*) aMessage;

/**
 * Called when the web socket receives a message.
 **/
- (void) didReceiveBinaryMessage:(NSData*) aMessage;

@optional
/**
 * Called when pong is sent... For keep-alive optimization.
 **/
- (void) didSendPong:(NSData*) aMessage;

@end


@interface WebSocket : NSObject <GCDAsyncSocketDelegate>
{
@protected
    GCDAsyncSocket* socket;
    NSError* closingError;
    NSString* wsSecKey;
    NSString* wsSecKeyHandshake;
    MutableQueue* pendingFragments;
    BOOL isClosing;
    NSUInteger closeStatusCode;
    NSString* closeMessage;
    BOOL sendCloseInfoToListener;
    NSMutableData* fragmentBuffer;
@private
    id<WebSocketDelegate> delegate;
    WebSocketReadyState readystate;
    WebSocketConnectConfig* config;
    dispatch_queue_t delegateQueue;
    NSTimer* pingTimer;
}


/**
 * Callback delegate for websocket events.
 **/
@property(nonatomic,retain) id<WebSocketDelegate> delegate;

/**
 * Config info for the websocket connection.
 **/
@property(nonatomic,retain) WebSocketConnectConfig* config;

/**
 * Represents the state of the connection. It can have the following values:
 * - WebSocketReadyStateConnecting: The connection has not yet been established.
 * - WebSocketReadyStateOpen: The WebSocket connection is established and communication is possible.
 * - WebSocketReadyStateClosing: The connection is going through the closing handshake.
 * - WebSocketReadyStateClosed: The connection has been closed or could not be opened.
 **/
@property(nonatomic,readonly) WebSocketReadyState readystate;


+ (id) webSocketWithConfig:(WebSocketConnectConfig*) aConfig delegate:(id<WebSocketDelegate>) aDelegate;
- (id) initWithConfig:(WebSocketConnectConfig*) aConfig delegate:(id<WebSocketDelegate>) aDelegate;
+ (id) webSocketWithConfig:(WebSocketConnectConfig*) aConfig queue:(dispatch_queue_t) aDispatchQueue delegate:(id<WebSocketDelegate>) aDelegate;
- (id) initWithConfig:(WebSocketConnectConfig*) aConfig queue:(dispatch_queue_t) aDispatchQueue delegate:(id<WebSocketDelegate>) aDelegate;


/**
 * Connect the websocket and prepare it for reading and writing.
 **/
- (void) open;

/**
 * Finish all reads/writes and close the websocket. Sends a status of WebSocketCloseStatusNormal and no message.
 **/
- (void) close;

/**
 * Finish all reads/writes and close the websocket. Sends the specified status and message.
 **/
- (void) close:(NSUInteger) aStatusCode message:(NSString*) aMessage;

/**
 * Write a UTF-8 encoded NSString message to the websocket.
 **/
- (void) sendText:(NSString*)message;

/**
 * Write a binary message to the websocket.
 **/
- (void) sendBinary:(NSData*)message;

/**
 * Send ping message to the websocket
 */
- (void) sendPing:(NSData*)message;


extern NSString *const WebSocketException;
extern NSString *const WebSocketErrorDomain;

@end
