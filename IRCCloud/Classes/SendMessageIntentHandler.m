//
//  SendMessageIntentHandler.m
//
//  Copyright (C) 2022 IRCCloud, Ltd.
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

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <IntentsUI/IntentsUI.h>
#import "SendMessageIntentHandler.h"
#import "AvatarsDataSource.h"
#import "NetworkConnection.h"
#import "ImageCache.h"

@interface INSendMessageAttachment (FileAttachments)
@property INFile *file;
@end

@implementation SendMessageIntentHandler
-(instancetype)init {
    self = [super init];

    if(self) {
        self->_fileUploader = [[FileUploader alloc] init];
        self->_fileUploader.delegate = self;
    }
    
    return self;
}

-(INSendMessageRecipientResolutionResult *)resolvePerson:(INPerson *)person {
    if(person && [person.customIdentifier hasPrefix:@"irccloud://"]) {
        INPersonResolutionResult *result = [INPersonResolutionResult successWithResolvedPerson:person];
        return [[INSendMessageRecipientResolutionResult alloc] initWithPersonResolutionResult:result];
    } else if (person.displayName) {
        NSMutableArray *matches = [[NSMutableArray alloc] init];
        NSArray *buffers = [BuffersDataSource sharedInstance].getBuffers;
        NSString *personName = person.displayName.lowercaseString;
        for(Buffer *b in buffers) {
            if([personName isEqualToString:b.name.lowercaseString]) {
                Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
                if(![s.status isEqualToString:@"connected_ready"])
                    continue;
                
                NSString *serverName = s.name;
                if(!serverName.length)
                    serverName = s.hostname;
                
                BOOL exists = NO;
                for(INPerson *p in matches) {
                    if([p.customIdentifier isEqualToString:[NSString stringWithFormat:@"irccloud://%i/%@", s.cid, b.name]]) {
                        exists = YES;
                        break;
                    }
                }
                if(exists)
                    continue;

                INImage *img = nil;
                if([b.type isEqualToString:@"conversation"]) {
                    NSURL *url = [[AvatarsDataSource sharedInstance] URLforBid:b.bid];
                    if(!url) {
                        User *u = [[UsersDataSource sharedInstance] getUser:b.name cid:b.cid];
                        if(u) {
                            Event *e = [[Event alloc] init];
                            e.cid = b.cid;
                            e.bid = b.bid;
                            e.hostmask = u.hostmask;
                            e.from = b.name;
                            e.type = @"buffer_msg";
                            
                            url = [e avatar:512];
                        }
                    }
                    
                    if(url && [[ImageCache sharedInstance] imageForURL:url]) {
                        img = [INImage imageWithURL:[[ImageCache sharedInstance] pathForURL:url]];
                    }
                }

                if(!img) {
                    Avatar *a = [[Avatar alloc] init];
                    a.nick = a.displayName = b.name;
                    img = [INImage imageWithUIImage:[a getImage:512 isSelf:NO]];
                }
                [matches addObject:[[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:b.name type:INPersonHandleTypeUnknown] nameComponents:nil displayName:[NSString stringWithFormat:@"%@ (%@)", b.name, serverName] image:img contactIdentifier:nil customIdentifier:[NSString stringWithFormat:@"irccloud://%i/%@", b.cid, b.name]]];
            }
        }
        NSArray *servers = [ServersDataSource sharedInstance].getServers;
        for(Server *s in servers) {
            if(![s.status isEqualToString:@"connected_ready"])
                continue;
            User *u = [[UsersDataSource sharedInstance] getUser:personName cid:s.cid];
            if(u) {
                BOOL exists = NO;
                for(INPerson *p in matches) {
                    if([p.customIdentifier isEqualToString:[NSString stringWithFormat:@"irccloud://%i/%@", s.cid, u.nick]]) {
                        exists = YES;
                        break;
                    }
                }
                if(exists)
                    continue;
                
                NSString *serverName = s.name;
                if(!serverName.length)
                    serverName = s.hostname;
                
                INImage *img = nil;
                Event *e = [[Event alloc] init];
                e.hostmask = u.hostmask;
                e.from = u.nick;
                e.type = @"buffer_msg";
                NSURL *url = [e avatar:512];
                if(url && [[ImageCache sharedInstance] imageForURL:url]) {
                    img = [INImage imageWithURL:[[ImageCache sharedInstance] pathForURL:url]];
                }

                if(!img) {
                    Avatar *a = [[Avatar alloc] init];
                    a.nick = a.displayName = u.nick;
                    img = [INImage imageWithUIImage:[a getImage:512 isSelf:NO]];
                }
                [matches addObject:[[INPerson alloc] initWithPersonHandle:[[INPersonHandle alloc] initWithValue:u.nick type:INPersonHandleTypeUnknown] nameComponents:nil displayName:[NSString stringWithFormat:@"%@ (%@)", u.display_name, serverName] image:img contactIdentifier:nil customIdentifier:[NSString stringWithFormat:@"irccloud://%i/%@", s.cid, u.nick]]];
            }
        }
        NSLog(@"Matches: %@", matches);
        if(matches.count == 1) {
            INPersonResolutionResult *result = [INPersonResolutionResult successWithResolvedPerson:matches.firstObject];
            return [[INSendMessageRecipientResolutionResult alloc] initWithPersonResolutionResult:result];
        } else if(matches.count) {
            INPersonResolutionResult *result = [INPersonResolutionResult disambiguationWithPeopleToDisambiguate:matches];
            return [[INSendMessageRecipientResolutionResult alloc] initWithPersonResolutionResult:result];
        }
    }
    return [INSendMessageRecipientResolutionResult unsupportedForReason:INSendMessageRecipientUnsupportedReasonNoHandleForLabel];
}

-(void)resolveRecipientsForSendMessage:(INSendMessageIntent *)intent completion:(void (^)(NSArray<INSendMessageRecipientResolutionResult *> * _Nonnull))completion {
    NSLog(@"Resolve intent: %@", intent);
    NSMutableArray *results;
    
    if(intent.recipients.count) {
        results = [[NSMutableArray alloc] init];
        
        for(INPerson *person in intent.recipients) {
            [results addObject:[self resolvePerson:person]];
        }
    } else {
        results = @[[INSendMessageRecipientResolutionResult needsValue]].mutableCopy;
    }
    completion(results);
}

-(void)resolveContentForSendMessage:(INSendMessageIntent *)intent withCompletion:(void (^)(INStringResolutionResult * _Nonnull))completion {
    if (@available(iOS 14.0, *)) {
        if(intent.attachments.count > 1) {
            completion([INStringResolutionResult unsupported]);
            return;
        } else if(intent.attachments.count == 1) {
            completion([INStringResolutionResult successWithResolvedString:intent.content]);
            return;
        }
    }

    if(intent.content.length)
        completion([INStringResolutionResult successWithResolvedString:intent.content]);
    else
        completion([INStringResolutionResult needsValue]);
    
}

-(void)confirmSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse * _Nonnull))completion {
    NSLog(@"Confirm intent: %@", intent);
    int code = INSendMessageIntentResponseCodeReady;
    for(INPerson *person in intent.recipients) {
        if(![person.customIdentifier hasPrefix:@"irccloud://"]) {
            code = INSendMessageIntentResponseCodeFailure;
        }
    }
    completion([[INSendMessageIntentResponse alloc] initWithCode:code userActivity:nil]);
}

-(void)handleSendMessage:(INSendMessageIntent *)intent completion:(void (^)(INSendMessageIntentResponse * _Nonnull))completion {
    NSLog(@"Send intent: %@", intent);
    __block int code = INSendMessageIntentResponseCodeSuccess;
    __block int responseCount = 0;

    if(@available(iOS 14.0, *)) {
        if(intent.attachments.count) {
            NSMutableArray *to = [[NSMutableArray alloc] init];
            for(INPerson *person in intent.recipients) {
                NSString *ident = [person.customIdentifier substringFromIndex:11];
                NSUInteger sep = [ident rangeOfString:@"/"].location;
                [to addObject:@{@"cid":@([ident substringToIndex:sep].intValue), @"to":[ident substringFromIndex:sep + 1]}];
            }
            _completion = completion;
            
            INSendMessageAttachment *attachment = intent.attachments.firstObject;
            INFile *file = attachment.audioMessageFile ? attachment.audioMessageFile : attachment.file;
            if(file && file.data && file.data.length) {
                _fileUploader = [[FileUploader alloc] init];
                _fileUploader.delegate = self;
                _fileUploader.to = to;
                [_fileUploader setFilename:file.filename message:intent.content];
                [_fileUploader uploadFile:file.filename UTI:CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(file.typeIdentifier), kUTTagClassMIMEType)) data:file.data];
            } else {
                _completion([[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeFailure userActivity:nil]);
            }
            return;
        }
    }
    
    for(INPerson *person in intent.recipients) {
        NSString *ident = [person.customIdentifier substringFromIndex:11];
        NSUInteger sep = [ident rangeOfString:@"/"].location;
        int cid = [ident substringToIndex:sep].intValue;
        NSString *to = [ident substringFromIndex:sep + 1];

        [[NetworkConnection sharedInstance] POSTsay:intent.content to:to cid:cid handler:^(IRCCloudJSONObject *result) {
            if(![[result objectForKey:@"success"] boolValue]) {
                CLS_LOG(@"Message failed to send: %@", result);
                code = INSendMessageIntentResponseCodeFailure;
            }
            
            if(++responseCount == intent.recipients.count)
                completion([[INSendMessageIntentResponse alloc] initWithCode:code userActivity:nil]);
        }];
    }
}

- (void)fileUploadDidFail:(NSString *)reason {
    NSLog(@"File upload failed: %@", reason);
    _completion([[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeFailure userActivity:nil]);
}

- (void)fileUploadDidFinish {
    NSLog(@"File upload finished");
    _completion([[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeSuccess userActivity:nil]);
}

- (void)fileUploadProgress:(float)progress {
}

- (void)fileUploadTooLarge {
    _completion([[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeFailure userActivity:nil]);
}

- (void)fileUploadWasCancelled {
    _completion([[INSendMessageIntentResponse alloc] initWithCode:INSendMessageIntentResponseCodeFailure userActivity:nil]);
}

@end
