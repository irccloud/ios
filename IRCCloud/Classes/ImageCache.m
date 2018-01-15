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
#ifdef ENTERPRISE
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
        _cachePath = [sharedcontainer URLByAppendingPathComponent:@"imagecache"];
        _session = [NSURLSession sharedSession];
        _tasks = [[NSMutableDictionary alloc] init];
        _images = [[NSMutableDictionary alloc] init];
        _failures = [[NSMutableDictionary alloc] init];
        [self clear];
    }
    return self;
}

-(void)prune {
    @synchronized (self) {
        CLS_LOG(@"Pruning image cache directory: %@", _cachePath.path);
        
        NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:_cachePath includingPropertiesForKeys:@[NSURLContentModificationDateKey] options:0 errorHandler:nil];
        
        NSDate *lastWeek = [NSDate dateWithTimeIntervalSinceNow:(-60*60*24*7)];
        
        for (NSURL *fileURL in directoryEnumerator) {
            NSDate *modificationDate = nil;
            [fileURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];
            
            if([lastWeek compare:modificationDate] == NSOrderedDescending) {
                CLS_LOG(@"Removing stale image cache file: %@", fileURL.path);
                [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
            }
        }
    }
}

-(void)clear {
    @synchronized(_tasks) {
        [_tasks.allValues makeObjectsPerformSelector:@selector(cancel)];
        [_tasks removeAllObjects];
    }
    @synchronized(_images) {
        [_images removeAllObjects];
    }
}

-(void)clearFailedURLs {
    @synchronized(_failures) {
        [_failures removeAllObjects];
    }
}

-(void)purge {
    [[NSFileManager defaultManager] removeItemAtURL:_cachePath error:nil];
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

-(BOOL)isValidURL:(NSURL *)url {
    @synchronized(_failures) {
        return [_failures objectForKey:url.absoluteString] == nil;
    }
}

-(BOOL)isValidFileID:(NSString *)fileID {
    return [self isValidURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID} error:nil]]];
}

-(BOOL)isValidFileID:(NSString *)fileID width:(int)width {
    return [self isValidURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%i", width]} error:nil]]];
}

-(BOOL)isLoaded:(NSURL *)url {
    @synchronized(_images) {
        return [_images objectForKey:url.absoluteString] != nil || [_failures objectForKey:url.absoluteString] != nil;
    }
}

-(BOOL)isLoaded:(NSString *)fileID width:(int)width {
    return [self isLoaded:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%i", width]} error:nil]]];
}

-(UIImage *)imageForURL:(NSURL *)url {
    @synchronized(_failures) {
        if([_failures objectForKey:url.absoluteString])
            return nil;
    }
    YYImage *img;
    @synchronized(_images) {
        img = [_images objectForKey:url.absoluteString];
    }
    if(!img) {
        NSURL *cache = [self pathForURL:url];
        if([[NSFileManager defaultManager] fileExistsAtPath:cache.path]) {
            NSData *data = [NSData dataWithContentsOfURL:cache];
            img = [YYImage imageWithData:data scale:[UIScreen mainScreen].scale];
            if(img.size.width) {
                @synchronized(_images) {
                    [_images setObject:img forKey:url.absoluteString];
                }
            } else {
                CLS_LOG(@"Unable to load %@ from cache", url);
                @synchronized(_failures) {
                    [_failures setObject:@(YES) forKey:url.absoluteString];
                }
            }
        }
    }
    if([img isKindOfClass:UIImage.class])
        return img;
    else
        return nil;
}

-(UIImage *)imageForFileID:(NSString *)fileID {
    return [self imageForURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID} error:nil]]];
}

-(UIImage *)imageForFileID:(NSString *)fileID width:(int)width {
    return [self imageForURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%i", width]} error:nil]]];
}

-(void)fetchURL:(NSURL *)url completionHandler:(imageCompletionHandler)handler {
    @synchronized (_tasks) {
        if([_tasks objectForKey:url] || [_failures objectForKey:url]) {
            return;
        }
        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:url completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            [_tasks removeObjectForKey:url];
            if(error) {
                CLS_LOG(@"Download failed: %@", error);
                @synchronized(_failures) {
                    [_failures setObject:@(YES) forKey:url.absoluteString];
                }
            } else if(location) {
                NSURL *cache = [self pathForURL:url];
                [[NSFileManager defaultManager] createDirectoryAtURL:_cachePath withIntermediateDirectories:YES attributes:nil error:nil];
                [[NSFileManager defaultManager] copyItemAtURL:location toURL:cache error:nil];
                NSLog(@"Downloaded %@ to %@", url, cache);
                NSData *data = [NSData dataWithContentsOfURL:cache];
                YYImage *img = [YYImage imageWithData:data scale:[UIScreen mainScreen].scale];
                if(img.size.width) {
                    @synchronized(_images) {
                        [_images setObject:img forKey:url.absoluteString];
                    }
                } else {
                    @synchronized(_failures) {
                        [_failures setObject:@(YES) forKey:url.absoluteString];
                    }
                }
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                handler([_images objectForKey:url.absoluteString] != nil);
            }];
        }];
        [_tasks setObject:task forKey:url];
        [task resume];
    }
}

-(void)fetchFileID:(NSString *)fileID completionHandler:(imageCompletionHandler)handler {
    return [self fetchURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID} error:nil]] completionHandler:handler];
}

-(void)fetchFileID:(NSString *)fileID width:(int)width completionHandler:(imageCompletionHandler)handler {
    return [self fetchURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%i", width]} error:nil]] completionHandler:handler];
}

-(NSURL *)pathForURL:(NSURL *)url {
    if(url)
        return [_cachePath URLByAppendingPathComponent:[self md5:url.absoluteString]];
    else
        return nil;
}

-(NSURL *)pathForFileID:(NSString *)fileID {
    return [self pathForURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID} error:nil]]];
}

-(NSURL *)pathForFileID:(NSString *)fileID width:(int)width {
    return [self pathForURL:[NSURL URLWithString:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%i", width]} error:nil]]];
}

-(NSTimeInterval)ageOfCache:(NSURL *)url {
    NSString *path = [self pathForURL:url].path;
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return fabs([[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileCreationDate] timeIntervalSinceNow]);
    }
    return -1;
}

@end
