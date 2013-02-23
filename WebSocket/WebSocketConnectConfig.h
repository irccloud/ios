//
//  WebSocketConnectConfig.h
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


enum 
{
    WebSocketVersion07 = 7,
    WebSocketVersion08 = 8,
    WebSocketVersion10 = 10,
    WebSocketVersionRFC6455 = 6455
};
typedef NSUInteger WebSocketVersion;


@interface WebSocketConnectConfig : NSObject
{
@private
    NSTimeInterval keepAlive;
    NSURL* url;
    NSString* origin;
    NSString* host;
    NSTimeInterval timeout;
    NSMutableDictionary* tlsSettings;
    NSMutableArray* protocols;
    NSString* serverProtocol;
    BOOL verifySecurityKey;
    NSUInteger maxPayloadSize;
    NSTimeInterval closeTimeout;
    WebSocketVersion version;
    BOOL isSecure;
    NSMutableArray* headers;
    NSMutableArray* serverHeaders;
    NSMutableArray* extensions;
    NSMutableArray* serverExtensions;
    BOOL activeExtensionModifiesReservedBits;
}

/**
 * String name/value pairs to be provided in the websocket handshake as 
 * http headers.
 **/
@property(nonatomic,retain) NSMutableArray* headers;

/**
 * String name/value pairs provided by the server in the websocket handshake 
 * as http headers.
 **/
@property(nonatomic,retain) NSMutableArray* serverHeaders;

/**
 * Version of the websocket specification.
 **/
@property(nonatomic,assign) WebSocketVersion version;

/**
 * Max size of the payload. Any messages larger will be sent as fragments.
 **/
@property(nonatomic,assign) NSUInteger maxPayloadSize;

/**
 * Timeout used for sending messages, not establishing the socket connection. A
 * value of -1 will result in no timeouts being applied.
 **/
@property(nonatomic,assign) NSTimeInterval timeout;

/**
 * Timeout used for the closing handshake. If this timeout is exceeded, the socket
 * will be forced closed. A value of -1 will result in no timeouts being applied.
 **/
@property(nonatomic,assign) NSTimeInterval closeTimeout;

/**
 * URL of the websocket
 **/
@property(nonatomic,retain) NSURL* url;

/**
 * Indicates whether the websocket will be opened over a secure connection
 **/
@property(nonatomic,assign) BOOL isSecure;

/**
 * Indicates whether the websocket will try to reconnect using a different version if the specified
 * one is not supported.
 **/
@property(nonatomic,assign) BOOL retryOtherVersion;

/**
 * Origin is used more in a browser setting, but it is intended to prevent cross-site scripting. If
 * nil, the client will fill this in using the url provided by the websocket.
 **/
@property(nonatomic,copy) NSString* origin;

/**
* Specifies whether to include the origin in the handshake request. Defaults to YES.
*/
@property(nonatomic,assign) BOOL useOrigin;

/**
 * The host string is created from the url.
 **/
@property(nonatomic,copy) NSString* host;

/**
 * The list of extensions accepted by the host.
 **/
@property(nonatomic,retain) NSMutableArray* serverExtensions;

/**
 * The list of extensions supported by the client. An item can contain an ordered list of extensions as
 * an array of extensions. To add an ordered list of extensions, add an the array or call the addExtensions:
 * operation (unavailable in versions prior to the standard).
 **/
@property(nonatomic,retain) NSMutableArray* extensions;

/**
 * Settings for securing the connection using SSL/TLS.
 * 
 * The possible keys and values for the TLS settings are well documented.
 * Some possible keys are:
 * - kCFStreamSSLLevel
 * - kCFStreamSSLAllowsExpiredCertificates
 * - kCFStreamSSLAllowsExpiredRoots
 * - kCFStreamSSLAllowsAnyRoot
 * - kCFStreamSSLValidatesCertificateChain
 * - kCFStreamSSLPeerName
 * - kCFStreamSSLCertificates
 * - kCFStreamSSLIsServer
 * 
 * Please refer to Apple's documentation for associated values, as well as other possible keys.
 * 
 * If the value is nil or an empty dictionary, then the websocket cannot be secured.
 **/
@property(nonatomic,retain) NSMutableDictionary* tlsSettings;

/**
 * The subprotocols supported by the client. Each subprotocol is represented by an NSString.
 **/
@property(nonatomic,retain) NSMutableArray* protocols;

/**
 * True if the client should verify the handshake security key sent by the server. Since many of
 * the web socket servers may not have been updated to support this, set to false to ignore
 * and simply accept the connection to the server.
 **/
@property(nonatomic,assign) BOOL verifySecurityKey; 

/**
 * The subprotocol selected by the server, nil if none was selected
 **/
@property(nonatomic,copy) NSString* serverProtocol;

/**
* The time interval to send pings on. If zero, no automated pings will be sent. Default is zero.
**/
@property(nonatomic, assign) NSTimeInterval keepAlive;

/**
* Indicates whether an active extension should be allowed to modify the reserved bits. Default is false;
*/
@property(nonatomic, assign) BOOL activeExtensionModifiesReservedBits;


+ (id) config;
+ (id) configWithURLString:(NSString*) aUrlString origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings headers:(NSArray*) aHeaders verifySecurityKey:(BOOL) aVerifySecurityKey extensions:(NSArray*) aExtensions;
- (id) initWithURLString:(NSString *) aUrlString origin:(NSString*) aOrigin protocols:(NSArray*) aProtocols tlsSettings:(NSDictionary*) aTlsSettings headers:(NSArray*) aHeaders verifySecurityKey:(BOOL) aVerifySecurityKey extensions:(NSArray*) aExtensions;

/**
* Add a supported extension.
*/
- (void) addExtension:(NSString*) aExtension;

/**
* Add an ordered set of supported extensions.
*/
- (void) addExtensions:(NSArray*) aExtensions;


@end

extern NSString *const WebSocketConnectConfigException;
extern NSString *const WebSocketConnectConfigErrorDomain;

