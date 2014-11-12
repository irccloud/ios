//
//  FileUploader.m
//  IRCCloud
//
//  Created by Sam Steele on 11/10/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "FileUploader.h"
#import "SBJson.h"
#import "NSData+Base64.h"
#import "config.h"
#import "NetworkConnection.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileUploader

-(void)uploadFile:(NSURL *)file {
    CFStringRef extension = (__bridge CFStringRef)[file pathExtension];
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, extension, NULL);
    _mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType));
    CFRelease(UTI);
    
    _filename = [file.pathComponents lastObject];
    
    NSData *data = [NSData dataWithContentsOfURL:file];
    [self performSelectorInBackground:@selector(_upload:) withObject:data];
}

-(void)uploadImage:(UIImage *)img {
    _mimeType = @"image/jpeg";
    _filename = [NSString stringWithFormat:@"%li.jpg", time(NULL)];
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

    NSString *boundary = [self boundaryString];
    _response = [[NSMutableData alloc] init];
    _body = [[NSMutableData alloc] init];
    
    [_body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", _filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n", _mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:file];
    [_body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
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

    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7 || true) {

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
            config = [NSURLSessionConfiguration backgroundSessionConfiguration:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
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
            NSMutableDictionary *tasks = [[d dictionaryForKey:@"fileuploadtasks"] mutableCopy];
            if(!tasks)
                tasks = [[NSMutableDictionary alloc] init];
            
            if(_msg)
                [tasks setObject:@{@"bid":@(_bid), @"msg":_msg} forKey:session.configuration.identifier];
            else
                [tasks setObject:@{@"bid":@(_bid)} forKey:session.configuration.identifier];

            [d setObject:tasks forKey:@"fileuploadtasks"];
            [d synchronize];
        }

        [task resume];
    }
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(_delegate)
        [_delegate fileUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    NSLog(@"Error: %@", error);
    [_delegate fileUploadDidFail];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    NSDictionary *d = [[[SBJsonParser alloc] init] objectWithData:_response];
    if(!d) {
        NSLog(@"UPLOAD: Invalid JSON response: %@", [[NSString alloc] initWithData:_response encoding:NSUTF8StringEncoding]);
    }
    [_delegate fileUploadDidFinish:d bid:_bid filename:_filename];
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
    NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"fileuploadtasks"] mutableCopy];
    [uploadtasks removeObjectForKey:session.configuration.identifier];
    [d setObject:uploadtasks forKey:@"fileuploadtasks"];
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
