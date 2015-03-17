//
//  FileUplaoder.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
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

#import "FileUploader.h"
#import "SBJson.h"
#import "NSData+Base64.h"
#import "config.h"
#import "NetworkConnection.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileUploader

-(void)setFilename:(NSString *)filename message:(NSString *)message {
    _filename = filename;
    _msg = message;
    _filenameSet = YES;
    if(_finished && _id.length) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
        _reqid = [[NetworkConnection sharedInstance] finalizeUpload:_id filename:_filename originalFilename:_originalFilename];
    } else {
        [self _updateBackgroundUploadMetadata];
    }
}

-(void)cancel {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    _cancelled = YES;
    _bid = -1;
    _msg = _filename = _originalFilename = _mimeType = nil;
    [_connection cancel];
    if(_delegate)
        [_delegate fileUploadWasCancelled];
}

- (void)handleEvent:(NSNotification *)notification {
    Buffer *b = nil;
    IRCCloudJSONObject *o = nil;
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventSuccess:
            o = notification.object;
            if(_reqid && [[o objectForKey:@"_reqid"] intValue] == _reqid) {
                b = [[BuffersDataSource sharedInstance] getBuffer:_bid];
                if(b) {
                    if(_msg.length)
                        _msg = [_msg stringByAppendingString:@" "];
                    else
                        _msg = @"";
                    _msg = [_msg stringByAppendingFormat:@"%@", [[o objectForKey:@"file"] objectForKey:@"url"]];
                    [[NetworkConnection sharedInstance] say:_msg to:b.name cid:b.cid];
                    [_delegate fileUploadDidFinish];
                }
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            if(_reqid && [[o objectForKey:@"_reqid"] intValue] == _reqid) {
                [_delegate fileUploadDidFail];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
            break;
        default:
            break;
    }
}

-(void)uploadFile:(NSURL *)file {
    CFStringRef extension = (__bridge CFStringRef)[file pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    if(!_mimeType)
        _mimeType = @"application/octet-stream";
    CFRelease(UTI);
    
    if(!_originalFilename)
        _originalFilename = [file.pathComponents lastObject];
    
    NSData *data = [NSData dataWithContentsOfURL:file];
    
    [self performSelectorInBackground:@selector(_upload:) withObject:data];
}

-(void)uploadFile:(NSString *)filename UTI:(NSString *)UTI data:(NSData *)data {
    _originalFilename = filename;
    _mimeType = UTI;
    [self performSelectorInBackground:@selector(_upload:) withObject:data];
}


-(void)uploadImage:(UIImage *)img {
    _mimeType = @"image/jpeg";
    if(_originalFilename) {
        if([_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location != NSNotFound) {
            _originalFilename = [NSString stringWithFormat:@"%@.JPG", [_originalFilename substringToIndex:[_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location]];
        } else {
            _originalFilename = [_originalFilename stringByAppendingString:@".JPG"];
        }
    } else {
        _originalFilename = [NSString stringWithFormat:@"%li.JPG", time(NULL)];
    }
    [self performSelectorInBackground:@selector(_uploadImage:) withObject:img];
}

-(void)_uploadImage:(UIImage *)img {
    NSUserDefaults *d;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        d = [NSUserDefaults standardUserDefaults];
    } else {
#ifdef ENTERPRISE
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    }
    int size = [[d objectForKey:@"photoSize"] intValue];
    NSData *file = UIImageJPEGRepresentation((size != -1)?[self image:img scaledCopyOfSize:CGSizeMake(size,size)]:img, 0.8);
    [self _upload:file];
}

//http://stackoverflow.com/a/19697172
- (UIImage *)image:(UIImage *)image scaledCopyOfSize:(CGSize)newSize {
    if(image.size.width <= newSize.width && image.size.height <= newSize.height)
        return image;

    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > newSize.width || height > newSize.height) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = newSize.width;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = newSize.height;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

- (NSString *)boundaryString
{
    // generate boundary string
    //
    // adapted from http://developer.apple.com/library/ios/#samplecode/SimpleURLConnections
    
    CFUUIDRef  uuid;
    NSString  *uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);
    
    CFRelease(uuid);
    
    return [NSString stringWithFormat:@"Boundary-%@", uuidStr];
}

-(void)_upload:(NSData *)file {
    if(file.length > 15000000) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_delegate fileUploadTooLarge];
        }];
        return;
    }
    if(!_originalFilename)
        _originalFilename = [NSString stringWithFormat:@"%li", time(NULL)];
    NSString *boundary = [self boundaryString];
    _response = [[NSMutableData alloc] init];
    _body = [[NSMutableData alloc] init];
    
    [_body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", _originalFilename] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", _mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:file];
    [_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    CLS_LOG(@"Uploading %@ with boundary %@ (%lu bytes)", _originalFilename, boundary, (unsigned long)_body.length);
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/upload", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
    [request setValue:[NetworkConnection sharedInstance].session forHTTPHeaderField:@"x-irccloud-session"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:_body];
    
    if(_metadatadelegate)
        [_metadatadelegate fileUploadWillUpload:file.length mimeType:_mimeType];

    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _connection = [NSURLConnection connectionWithRequest:request delegate:self];
            [_connection start];
#ifndef EXTENSION
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
        }];
    } else {
        NSURLSession *session;
        NSURLSessionConfiguration *config;
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            config = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"com.irccloud.share.file.%li", time(NULL)]];
#pragma GCC diagnostic pop
        } else {
            config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
#ifdef ENTERPRISE
            config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
            config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
        }
        config.HTTPCookieStorage = nil;
        config.URLCache = nil;
        config.requestCachePolicy = NSURLCacheStorageNotAllowed;
        config.discretionary = NO;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionTask *task = [session downloadTaskWithRequest:request];
        
        if(session.configuration.identifier) {
            _backgroundID = session.configuration.identifier;
            [self _updateBackgroundUploadMetadata];
        }

        [task resume];
    }
}

-(void)_updateBackgroundUploadMetadata {
    NSUserDefaults *d;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        d = [NSUserDefaults standardUserDefaults];
    } else {
#ifdef ENTERPRISE
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    }
    NSMutableDictionary *tasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    if(!tasks)
        tasks = [[NSMutableDictionary alloc] init];
    
    [tasks setObject:@{@"service":@"irccloud", @"bid":@(_bid), @"original_filename":_originalFilename, @"msg":_msg?_msg:@"", @"filename":_filename?_filename:@""} forKey:_backgroundID];
    
    [d setObject:tasks forKey:@"uploadtasks"];
    [d synchronize];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(_delegate && !_cancelled)
        [_delegate fileUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    CLS_LOG(@"Error: %@", error);
    [_delegate fileUploadDidFail];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    if(_cancelled)
        return;
    NSDictionary *d = [[[SBJsonParser alloc] init] objectWithData:_response];
    if(d) {
        CLS_LOG(@"Upload finished: %@", d);
        if([[d objectForKey:@"success"] intValue] == 1) {
            _id = [d objectForKey:@"id"];
            _finished = YES;
            if(_filenameSet) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
                _reqid = [[NetworkConnection sharedInstance] finalizeUpload:_id filename:_filename originalFilename:_originalFilename];
            }
        } else {
            [_delegate fileUploadDidFail];
        }
    } else {
        CLS_LOG(@"UPLOAD: Invalid JSON response: %@", [[NSString alloc] initWithData:_response encoding:NSUTF8StringEncoding]);
        [_delegate fileUploadDidFail];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    [self connection:nil didSendBodyData:(NSInteger)bytesSent totalBytesWritten:(NSInteger)totalBytesSent totalBytesExpectedToWrite:(NSInteger)_body.length];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    _response = [NSData dataWithContentsOfURL:location].mutableCopy;
    [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
    [self connectionDidFinishLoading:nil];
    NSUserDefaults *d;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        d = [NSUserDefaults standardUserDefaults];
    } else {
#ifdef ENTERPRISE
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    }
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"uploadtasks"];
    [d synchronize];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        CLS_LOG(@"Upload error: %@", error);
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_delegate fileUploadDidFail];
        }];
    }
    [session finishTasksAndInvalidate];
}
@end
