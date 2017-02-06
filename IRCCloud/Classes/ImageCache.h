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

typedef void (^imageCompletionHandler)(UIImage *);

@interface ImageCache : NSObject {
    NSURLSession *_session;
    CSURITemplate *_template;
    NSMutableDictionary *_tasks;
    NSMutableDictionary *_images;
}

+(ImageCache *)sharedInstance;
-(void)clear;
-(UIImage *)imageForURL:(NSURL *)url;
-(UIImage *)imageForFileID:(NSString *)fileID;
-(UIImage *)thumbnailForFileID:(NSString *)fileID;
-(void)fetchURL:(NSURL *)url completionHandler:(imageCompletionHandler)handler;
-(void)fetchFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler;
-(void)fetchThumbnailForFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler;
@end
