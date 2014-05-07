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
-(void)upload:(UIImage *)img {
    [self performSelectorInBackground:@selector(_upload:) withObject:img];
}

-(void)_upload:(UIImage *)img {
    NSData *data = UIImageJPEGRepresentation(img, 0.8);
    CFStringRef data_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)[data base64EncodedString], NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.imgur.com/3/image"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
#endif
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"image=%@", data_escaped] dataUsingEncoding:NSUTF8StringEncoding]];
    
    CFRelease(data_escaped);
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _response = [[NSMutableData alloc] init];
        _connection = [NSURLConnection connectionWithRequest:request delegate:self];
        [_connection start];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }];
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    if(_delegate)
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_delegate imageUploadProgress:(float)totalBytesWritten / (float)totalBytesExpectedToWrite];
        }];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_response appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_delegate imageUploadDidFail];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    NSDictionary *d = [[[SBJsonParser alloc] init] objectWithData:_response];
    [_delegate imageUploadDidFinish:d];
}
@end
