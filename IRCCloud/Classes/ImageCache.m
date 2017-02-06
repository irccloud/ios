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

#import <CommonCrypto/CommonDigest.h>
#import "ImageCache.h"
#import "NetworkConnection.h"

@implementation ImageCache

+(ImageCache *)sharedInstance {
    static ImageCache *sharedInstance;
    
    @synchronized(self) {
        if(!sharedInstance)
            sharedInstance = [[ImageCache alloc] init];
        
        return sharedInstance;
    }
    return nil;
}

-(id)init {
    self = [super init];
    if(self) {
        _session = [NSURLSession sharedSession];
        _tasks = [[NSMutableDictionary alloc] init];
        _images = [[NSMutableDictionary alloc] init];
        [self clear];
    }
    return self;
}

-(void)clear {
    [_tasks.allValues makeObjectsPerformSelector:@selector(cancel)];
    [_tasks removeAllObjects];
    [_images removeAllObjects];
    _template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"file_uri_template"] error:nil];
}

-(void)purge {
    NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"imagecache"];
    [[NSFileManager defaultManager] removeItemAtURL:caches error:nil];
    [self clear];
}

- (NSString *)md5:(NSString *)string {
    const char *cstr = [string UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (unsigned int)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];  
}

-(UIImage *)imageForURL:(NSURL *)url {
    if(![_images objectForKey:url]) {
        NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"imagecache"];
        caches = [caches URLByAppendingPathComponent:[self md5:url.absoluteString]];
        UIImage *img = [UIImage imageWithContentsOfFile:caches.path];
        if(img)
            [_images setObject:img forKey:url.absoluteString];
    }
    return [_images objectForKey:url.absoluteString];
}

-(UIImage *)imageForFileID:(NSString *)fileID {
    return [self imageForURL:[NSURL URLWithString:[_template relativeStringWithVariables:@{@"id":fileID} error:nil]]];
}

-(UIImage *)thumbnailForFileID:(NSString *)fileID {
    return [self imageForURL:[NSURL URLWithString:[_template relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%.f", [UIScreen mainScreen].bounds.size.width/2]} error:nil]]];
}

-(void)fetchURL:(NSURL *)url completionHandler:(imageCompletionHandler)handler {
    @synchronized (_tasks) {
        if([_tasks objectForKey:url]) {
            NSLog(@"Duplicate task for URL: %@", url);
            return;
        }
        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            [_tasks removeObjectForKey:url];
            if(error) {
                NSLog(@"Download failed: %@", error);
            } else if(location) {
                NSLog(@"Downloaded to: %@", location);
                NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"imagecache"];
                [[NSFileManager defaultManager] createDirectoryAtURL:caches withIntermediateDirectories:YES attributes:nil error:nil];
                caches = [caches URLByAppendingPathComponent:[self md5:url.absoluteString]];
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:caches error:nil];
                NSLog(@"Copied to: %@", caches);
                UIImage *img = [UIImage imageWithContentsOfFile:caches.path];
                if(img)
                    [_images setObject:img forKey:url.absoluteString];
            }
            handler([self imageForURL:url]);
        }];
        [_tasks setObject:task forKey:url];
        [task resume];
    }
}

-(void)fetchFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler {
    return [self fetchURL:[NSURL URLWithString:[_template relativeStringWithVariables:@{@"id":fileID} error:nil]] completionHandler:handler];
}

-(void)fetchThumbnailForFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler {
    return [self fetchURL:[NSURL URLWithString:[_template relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%.f", [UIScreen mainScreen].bounds.size.width/2]} error:nil]] completionHandler:handler];
}

@end
