//
//  ImageUploader.m
//  IRCCloud
//
//  Created by Sam Steele on 5/7/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "ImageUploader.h"
#import "SBJson.h"
#import "NSData+Base64.h"
#import "config.h"

@implementation ImageUploader

-(id)init {
    self = [super init];
    if(self) {
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
#if 0 //This seems to be broken on beta 4
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
#ifdef ENTERPRISE
            config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
            config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
#else
            NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
#endif
            config.HTTPCookieStorage = nil;
            config.URLCache = nil;
            config.requestCachePolicy = NSURLCacheStorageNotAllowed;
            config.discretionary = NO;
            _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
        }
    }
    return self;
}

-(void)upload:(UIImage *)img {
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
#endif
    _image = img;
    if([d objectForKey:@"imgur_access_token"])
        [self performSelectorOnMainThread:@selector(_authorize) withObject:nil waitUntilDone:NO];
    else
        [self performSelectorInBackground:@selector(_upload:) withObject:img];
}

-(void)_authorize {
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
#endif
#ifdef IMGUR_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/oauth2/token"]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"refresh_token=%@&client_id=%@&client_secret=%@&grant_type=refresh_token", [d objectForKey:@"imgur_refresh_token"], @IMGUR_KEY, @IMGUR_SECRET] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error renewing token. Error %li : %@", (long)error.code, error.userInfo);
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [_delegate imageUploadDidFail];
            }];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([dict objectForKey:@"access_token"]) {
                for(NSString *key in dict.allKeys) {
                    if([[dict objectForKey:key] isKindOfClass:[NSString class]])
                        [d setObject:[dict objectForKey:key] forKey:[NSString stringWithFormat:@"imgur_%@", key]];
                }
                [d synchronize];
                [self performSelectorInBackground:@selector(_upload:) withObject:_image];
            } else {
                [_delegate performSelector:@selector(imageUploadNotAuthorized) withObject:nil afterDelay:0.25];
            }
        }
    }];
#else
    [_delegate performSelector:@selector(imageUploadNotAuthorized) withObject:nil afterDelay:0.25];
#endif
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

-(void)_upload:(UIImage *)img {
    _response = [[NSMutableData alloc] init];
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
#endif
    int size = [[d objectForKey:@"photoSize"] intValue];
    NSData *data = UIImageJPEGRepresentation((size != -1)?[self image:img scaledCopyOfSize:CGSizeMake(size,size)]:img, 0.8);
    CFStringRef data_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[data base64EncodedString], NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
#ifdef MASHAPE_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://imgur-apiv3.p.mashape.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    if([d objectForKey:@"imgur_access_token"]) {
        [request setValue:[NSString stringWithFormat:@"Bearer %@", [d objectForKey:@"imgur_access_token"]] forHTTPHeaderField:@"Authorization"];
    } else {
        [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
    }
#endif
    [request setHTTPMethod:@"POST"];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
        [request setHTTPBody:[[NSString stringWithFormat:@"image=%@", data_escaped] dataUsingEncoding:NSUTF8StringEncoding]];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _connection = [NSURLConnection connectionWithRequest:request delegate:self];
            [_connection start];
#ifndef EXTENSION
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#endif
        }];
    } else {
        _body = [[NSString stringWithFormat:@"image=%@", data_escaped] dataUsingEncoding:NSUTF8StringEncoding];
        NSURLSessionTask *task = [_session uploadTaskWithStreamedRequest:request];
        
        if(_session.configuration.identifier) {
            NSMutableDictionary *tasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
            if(!tasks)
                tasks = [[NSMutableDictionary alloc] init];
            
            if(_msg)
                [tasks setObject:@{@"bid":@(_bid), @"msg":_msg} forKey:_session.configuration.identifier];
            else
                [tasks setObject:@{@"bid":@(_bid)} forKey:_session.configuration.identifier];

            [d setObject:tasks forKey:@"uploadtasks"];
            [d synchronize];
        }

        [task resume];
    }
    CFRelease(data_escaped);
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(_delegate)
        [_delegate imageUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
#ifndef EXTENSION
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    [_delegate imageUploadDidFail];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifdef EXTENSION
#ifdef ENTERPRISE
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
#else
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
#endif
    
    NSDictionary *d = [[[SBJsonParser alloc] init] objectWithData:_response];
#ifdef IMGUR_KEY
    if([defaults objectForKey:@"imgur_access_token"] && [[d objectForKey:@"success"] intValue] == 0 && [[d objectForKey:@"status"] intValue] == 403) {
        [self _authorize];
        return;
    }
#endif
    [_delegate imageUploadDidFinish:d bid:_bid];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    [self connection:nil didSendBodyData:(NSInteger)bytesSent totalBytesWritten:(NSInteger)totalBytesSent totalBytesExpectedToWrite:(NSInteger)_body.length];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [self connection:nil didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [self connectionDidFinishLoading:nil];
    if(session.configuration.identifier && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
        [uploadtasks removeObjectForKey:session.configuration.identifier];
        [d setObject:uploadtasks forKey:@"uploadtasks"];
        [d synchronize];
    }
    [session finishTasksAndInvalidate];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *))completionHandler {
    completionHandler([NSInputStream inputStreamWithData:_body]);
}
@end
