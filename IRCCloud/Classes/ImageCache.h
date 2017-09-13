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
#import "CSURITemplate.h"
#import "FLAnimatedImage.h"

typedef void (^imageCompletionHandler)(BOOL);

@interface ImageCache : NSObject {
    NSURL *_cachePath;
    NSURLSession *_session;
    CSURITemplate *_template;
    NSMutableDictionary *_tasks;
    NSMutableDictionary *_images;
    NSMutableDictionary *_failures;
}

+(ImageCache *)sharedInstance;
-(void)prune;
-(void)clear;
-(void)purge;
-(BOOL)isValidURL:(NSURL *)url;
-(NSURL *)pathForURL:(NSURL *)url;
-(NSURL *)pathForFileID:(NSString *)fileID;
-(NSURL *)pathForFileID:(NSString *)fileID width:(int)width;
-(UIImage *)imageForURL:(NSURL *)url;
-(UIImage *)imageForFileID:(NSString *)fileID;
-(UIImage *)imageForFileID:(NSString *)fileID width:(int)width;
-(FLAnimatedImage *)animatedImageForURL:(NSURL *)url;
-(FLAnimatedImage *)animatedImageForFileID:(NSString *)fileID;
-(FLAnimatedImage *)animatedImageForFileID:(NSString *)fileID width:(int)width;
-(void)fetchURL:(NSURL *)url completionHandler:(imageCompletionHandler)handler;
-(void)fetchFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler;
-(void)fetchFileID:(NSString *)fileID width:(int)width completionHandler:(imageCompletionHandler)handler;
@end
