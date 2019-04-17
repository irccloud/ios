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

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "FileUploader.h"
#import "NSData+Base64.h"
#import "config.h"
#import "NetworkConnection.h"
#import "SSZipArchive.h"

@implementation FileUploader

-(void)setFilename:(NSString *)filename message:(NSString *)message {
    self->_filename = filename;
    self->_msg = message;
    self->_filenameSet = YES;
    if(self->_finished && _id.length) {
        [self handleResult:[[NetworkConnection sharedInstance] finalizeUpload:self->_id filename:self->_filename originalFilename:self->_originalFilename avatar:self->_avatar orgId:self->_orgId]];
    } else {
        if(self->_backgroundID)
            [self _updateBackgroundUploadMetadata];
    }
}

-(void)cancel {
#ifndef EXTENSION
    [[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:@(NO) waitUntilDone:YES];
#endif
    CLS_LOG(@"File upload cancelled");
    self->_cancelled = YES;
    self->_bid = -1;
    self->_msg = self->_filename = self->_originalFilename = self->_mimeType = nil;
    [self->_connection cancel];
    if(self->_delegate)
        [self->_delegate fileUploadWasCancelled];
}

- (void)handleResult:(NSDictionary *)result {
    if([[result objectForKey:@"success"] intValue] == 1 && [[result objectForKey:@"file"] objectForKey:@"url"]) {
        CLS_LOG(@"Finalize success: %@", result);
        if(self->_avatar) {
            [self->_delegate fileUploadDidFinish];
        } else {
            Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:self->_bid];
            if(b) {
                if(self->_msg.length) {
                    if(![self->_msg hasSuffix:@" "])
                        self->_msg = [self->_msg stringByAppendingString:@" "];
                } else {
                    self->_msg = @"";
                }
                self->_msg = [self->_msg stringByAppendingFormat:@"%@", [[result objectForKey:@"file"] objectForKey:@"url"]];
                [[NetworkConnection sharedInstance] POSTsay:self->_msg to:b.name cid:b.cid];
                [self->_delegate fileUploadDidFinish];
            }
        }
    } else {
        CLS_LOG(@"Finalize failed: %@", result);
        [self->_delegate fileUploadDidFail:[result objectForKey:@"message"]];
    }
}

//From http://stackoverflow.com/a/23862326
- (BOOL)encodeVideo:(NSURL *)videoURL
{
    CFUUIDRef  uuid;
    NSString  *uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
    assert(uuidStr != NULL);
    
    CFRelease(uuid);
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    // Create the composition and tracks
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSArray *assetVideoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count <= 0)
    {
        NSLog(@"Error reading the transformed video track");
        return NO;
    }

    if(!_originalFilename)
        self->_originalFilename = [[videoURL lastPathComponent] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@".%@", [videoURL pathExtension]] withString:@".mp4"];

    // Insert the tracks in the composition's tracks
    AVAssetTrack *assetVideoTrack = [assetVideoTracks firstObject];
    [videoTrack insertTimeRange:assetVideoTrack.timeRange ofTrack:assetVideoTrack atTime:CMTimeMake(0, 1) error:nil];
    [videoTrack setPreferredTransform:assetVideoTrack.preferredTransform];
    
    // Only add an audio track if the source video contains one
    NSArray *assetAudioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if(assetAudioTracks.count) {
        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *assetAudioTrack = [assetAudioTracks firstObject];
        [audioTrack insertTimeRange:assetAudioTrack.timeRange ofTrack:assetAudioTrack atTime:CMTimeMake(0, 1) error:nil];
    }
    
    // Export to mp4
    NSString *exportPath = [NSString stringWithFormat:@"%@/%@.mp4", NSTemporaryDirectory(), uuidStr];
    
    NSURL *exportUrl = [NSURL fileURLWithPath:exportPath];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = exportUrl;
    CMTime start = CMTimeMakeWithSeconds(0.0, 0);
    CMTimeRange range = CMTimeRangeMake(start, [asset duration]);
    exportSession.timeRange = range;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        switch ([exportSession status])
        {
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"MP4 Successful!");
                [self uploadFile:exportUrl];
                break;
            case AVAssetExportSessionStatusFailed:
                NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                [self->_delegate fileUploadDidFail:[[exportSession error] localizedDescription]];
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"Export canceled");
                [self->_delegate fileUploadDidFail:@"Export cancelled"];
                break;
            default:
                break;
        }
        [[NSFileManager defaultManager] removeItemAtPath:exportPath error:nil];
    }];
    
    return YES;
}

-(void)uploadVideo:(NSURL *)file {
    if(![self encodeVideo:file])
        [self uploadFile:file];
}

-(void)uploadFile:(NSURL *)file {
    CLS_LOG(@"Uploading file: %@", file);
    NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithURL:file options:0 error:nil];
    
    if(wrapper.regularFile) {
        if(!_mimeType) {
            CFStringRef extension = (__bridge CFStringRef)[file pathExtension];
            CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
            self->_mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
            if(!_mimeType)
                self->_mimeType = @"application/octet-stream";
            CFRelease(UTI);
        }
        
        if(!_originalFilename)
            self->_originalFilename = wrapper.filename;
    
        [self performSelectorInBackground:@selector(_upload:) withObject:wrapper.regularFileContents];
    } else {
        CLS_LOG(@"Uploading a bundle requires zipping first");
        NSString *tempFile = [[NSTemporaryDirectory() stringByAppendingPathComponent:wrapper.filename] stringByAppendingString:@".zip"];
        CLS_LOG(@"Creating %@", tempFile);
        
        [SSZipArchive createZipFileAtPath:tempFile withContentsOfDirectory:file.path keepParentDirectory:YES];
        self->_mimeType = @"application/zip";

        if(!_originalFilename)
            self->_originalFilename = wrapper.filename;
        
        self->_originalFilename = [self->_originalFilename stringByAppendingString:@".zip"];
        NSData *data = [NSData dataWithContentsOfFile:tempFile];
        [self performSelectorInBackground:@selector(_upload:) withObject:data];
        
        [[NSFileManager defaultManager] removeItemAtPath:tempFile error:nil];
    }
}

-(void)uploadFile:(NSString *)filename UTI:(NSString *)UTI data:(NSData *)data {
    CLS_LOG(@"Uploading data with filename: %@", filename);
    self->_originalFilename = filename;
    self->_mimeType = UTI;
    [self performSelectorInBackground:@selector(_upload:) withObject:data];
}


-(void)uploadImage:(UIImage *)img {
    CLS_LOG(@"Uploading UIImage");
    self->_mimeType = @"image/jpeg";
    if(self->_originalFilename) {
        if([self->_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location != NSNotFound) {
            self->_originalFilename = [NSString stringWithFormat:@"%@.JPG", [self->_originalFilename substringToIndex:[self->_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location]];
        } else {
            self->_originalFilename = [self->_originalFilename stringByAppendingString:@".JPG"];
        }
    } else {
        self->_originalFilename = [NSString stringWithFormat:@"%li.JPG", time(NULL)];
    }
    [self performSelectorInBackground:@selector(_uploadImage:) withObject:img];
}

-(void)_uploadImage:(UIImage *)img {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    int size = [[d objectForKey:@"photoSize"] intValue];
    if(size == -1 && (img.size.width * img.size.height > 15000000)) {
        CLS_LOG(@"Image dimensions too large, scaling down to 3872x3872");
        size = 3872;
    }
    if(size > 0) {
        img = [FileUploader image:img scaledCopyOfSize:CGSizeMake(size,size)];
    }

    NSData *file = UIImageJPEGRepresentation(img, 0.8);
    [self _upload:file];
}

-(void)uploadPNG:(UIImage *)img {
    CLS_LOG(@"Uploading UIImage");
    self->_mimeType = @"image/png";
    if(self->_originalFilename) {
        if([self->_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location != NSNotFound) {
            self->_originalFilename = [NSString stringWithFormat:@"%@.PNG", [self->_originalFilename substringToIndex:[self->_originalFilename rangeOfString:@"." options:NSBackwardsSearch].location]];
        } else {
            self->_originalFilename = [self->_originalFilename stringByAppendingString:@".PNG"];
        }
    } else {
        self->_originalFilename = [NSString stringWithFormat:@"%li.PNG", time(NULL)];
    }
    [self performSelectorInBackground:@selector(_uploadPNG:) withObject:img];
}

-(void)_uploadPNG:(UIImage *)img {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    int size = [[d objectForKey:@"photoSize"] intValue];
    if(size == -1 && (img.size.width * img.size.height > 15000000)) {
        CLS_LOG(@"Image dimensions too large, scaling down to 3872x3872");
        size = 3872;
    }
    if(size > 0) {
        img = [FileUploader image:img scaledCopyOfSize:CGSizeMake(size,size)];
    }
    
    NSData *file = UIImagePNGRepresentation(img);
    [self _upload:file];
}

//http://stackoverflow.com/a/19697172
+ (UIImage *)image:(UIImage *)image scaledCopyOfSize:(CGSize)newSize {
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
        CLS_LOG(@"File exceeds 15M");
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_delegate fileUploadTooLarge];
        }];
        return;
    }
    if(self->_delegate)
        [self->_delegate fileUploadProgress:0.0f];
    if(!_originalFilename)
        self->_originalFilename = [NSString stringWithFormat:@"%li", time(NULL)];
    self->_boundary = [self boundaryString];
    self->_response = [[NSMutableData alloc] init];
    self->_body = [[NSMutableData alloc] init];
    
    [self->_body appendData:[[NSString stringWithFormat:@"--%@\r\n", _boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [self->_body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", _originalFilename] dataUsingEncoding:NSUTF8StringEncoding]];
    [self->_body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", _mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [self->_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [self->_body appendData:file];
    [self->_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [self->_body appendData:[[NSString stringWithFormat:@"--%@--\r\n", _boundary] dataUsingEncoding:NSUTF8StringEncoding]];

    CLS_LOG(@"Uploading %@ with boundary %@ (%lu bytes)", _originalFilename, _boundary, (unsigned long)_body.length);
    
#ifndef EXTENSION
    [[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:@(YES) waitUntilDone:YES];
#endif
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/%@", IRCCLOUD_HOST, _avatar?@"upload-avatar":@"upload"]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
    [request setValue:[NetworkConnection sharedInstance].session forHTTPHeaderField:@"x-irccloud-session"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:self->_body];
    
    if(self->_metadatadelegate)
        [self->_metadatadelegate fileUploadWillUpload:file.length mimeType:self->_mimeType];

#ifndef APPSTORE
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"backgroundUploads"]) {
#endif
        NSURLSession *session;
        NSURLSessionConfiguration *config;
        config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
#ifdef ENTERPRISE
        config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
        config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
        config.HTTPCookieStorage = nil;
        config.URLCache = nil;
        config.requestCachePolicy = NSURLCacheStorageNotAllowed;
        config.discretionary = NO;
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionTask *task = [session downloadTaskWithRequest:request];
        
        if(session.configuration.identifier) {
            self->_backgroundID = session.configuration.identifier;
            [self _updateBackgroundUploadMetadata];
        }

        [task resume];
#ifndef APPSTORE
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_connection = [NSURLConnection connectionWithRequest:request delegate:self];
            [self->_connection start];
        }];
    }
#endif
}

-(void)_updateBackgroundUploadMetadata {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    NSMutableDictionary *tasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    if(!tasks)
        tasks = [[NSMutableDictionary alloc] init];
    
    [tasks setObject:@{@"service":@"irccloud", @"bid":@(self->_bid), @"original_filename":self->_originalFilename?_originalFilename:@"", @"msg":self->_msg?_msg:@"", @"filename":self->_filename?_filename:@"", @"avatar":@(self->_avatar), @"orgId":@(self->_orgId)} forKey:self->_backgroundID];
    
    [d setObject:tasks forKey:@"uploadtasks"];
    
    CLS_LOG(@"Upload tasks: %@", tasks);
    
    [d synchronize];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(self->_delegate && !_cancelled)
        [self->_delegate fileUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self->_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifndef EXTENSION
    [[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:@(NO) waitUntilDone:YES];
#endif
    CLS_LOG(@"Error: %@", error);
    [self->_delegate fileUploadDidFail:error.localizedDescription];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifndef EXTENSION
    [[UIApplication sharedApplication] performSelectorOnMainThread:@selector(setNetworkActivityIndicatorVisible:) withObject:@(NO) waitUntilDone:YES];
#endif
    if(self->_cancelled) {
        CLS_LOG(@"Upload finished but it was cancelled");
        return;
    }
    NSDictionary *d = [NSJSONSerialization JSONObjectWithData:self->_response options:kNilOptions error:nil];
    if(d) {
        CLS_LOG(@"Upload finished: %@", d);
        if([[d objectForKey:@"success"] intValue] == 1) {
            self->_id = [d objectForKey:@"id"];
            self->_finished = YES;
            if(self->_filenameSet || _avatar) {
                [self handleResult:[[NetworkConnection sharedInstance] finalizeUpload:self->_id filename:self->_filename?_filename:@"" originalFilename:self->_originalFilename?_originalFilename:@"" avatar:self->_avatar orgId:self->_orgId]];
            }
        } else {
            [self->_delegate fileUploadDidFail:[d objectForKey:@"message"]];
        }
    } else {
        CLS_LOG(@"UPLOAD: Invalid JSON response: %@", [[NSString alloc] initWithData:self->_response encoding:NSUTF8StringEncoding]);
        [self->_delegate fileUploadDidFail:nil];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    CLS_LOG(@"Sent body data: %lli / %lli", totalBytesSent, totalBytesExpectedToSend);
    [self connection:self->_connection didSendBodyData:(NSInteger)bytesSent totalBytesWritten:(NSInteger)totalBytesSent totalBytesExpectedToWrite:(NSInteger)_body.length];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    CLS_LOG(@"Got HTTP redirect to: %@ %@", request.URL, response);
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    self->_response = [NSData dataWithContentsOfURL:location].mutableCopy;
    CLS_LOG(@"Did finish downloading to URL: %@", location);
    [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
    [self connectionDidFinishLoading:self->_connection];
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"uploadtasks"];
    [d synchronize];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSUserDefaults *d;
#ifdef ENTERPRISE
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"uploadtasks"];
    [d synchronize];

    CLS_LOG(@"HTTP request completed with status code %i", (int)((NSHTTPURLResponse *)task.response).statusCode);
    
    if(error) {
#ifndef EXTENSION
        if([error.domain isEqualToString:NSURLErrorDomain]) {
            if(error.code == NSURLErrorUnknown || error.code == NSURLErrorBackgroundSessionWasDisconnected) {
                CLS_LOG(@"Lost connection to background upload service, retrying in-process");
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://%@/chat/upload", IRCCLOUD_HOST]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
                [request setHTTPShouldHandleCookies:NO];
                [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary] forHTTPHeaderField:@"Content-Type"];
                [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
                [request setValue:[NetworkConnection sharedInstance].session forHTTPHeaderField:@"x-irccloud-session"];
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:self->_body];
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    self->_connection = [NSURLConnection connectionWithRequest:request delegate:self];
                    [self->_connection start];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                }];
                return;
            }
        }
#endif
        CLS_LOG(@"Upload error: %@", error);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_delegate fileUploadDidFail:error.localizedDescription];
        }];
    }
    [session finishTasksAndInvalidate];
}
@end
