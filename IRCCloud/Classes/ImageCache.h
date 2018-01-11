//
//  ImageCache.h
//
//  Copyright (C) 2017 IRCCloud, Ltd.
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

#import <Foundation/Foundation.h>
#import "YYImage.h"

typedef void (^imageCompletionHandler)(BOOL);

@interface ImageCache : NSObject {
    NSURL *_cachePath;
    NSURLSession *_session;
    NSMutableDictionary *_tasks;
    NSMutableDictionary *_images;
    NSMutableDictionary *_failures;
}

+(ImageCache *)sharedInstance;
-(void)prune;
-(void)clear;
-(void)clearFailedURLs;
-(void)purge;
-(BOOL)isValidURL:(NSURL *)url;
-(BOOL)isValidFileID:(NSString *)url;
-(BOOL)isValidFileID:(NSString *)url width:(int)width;
-(BOOL)isLoaded:(NSURL *)url;
-(BOOL)isLoaded:(NSString *)fileID width:(int)width;
-(NSURL *)pathForURL:(NSURL *)url;
-(NSURL *)pathForFileID:(NSString *)fileID;
-(NSURL *)pathForFileID:(NSString *)fileID width:(int)width;
-(YYImage *)imageForURL:(NSURL *)url;
-(YYImage *)imageForFileID:(NSString *)fileID;
-(YYImage *)imageForFileID:(NSString *)fileID width:(int)width;
-(void)fetchURL:(NSURL *)url completionHandler:(imageCompletionHandler)handler;
-(void)fetchFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler;
-(void)fetchFileID:(NSString *)fileID width:(int)width completionHandler:(imageCompletionHandler)handler;
@end
