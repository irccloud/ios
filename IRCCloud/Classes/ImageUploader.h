//
//  ImageUploader.h
//  IRCCloud
//
//  Created by Sam Steele on 5/7/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ImageUploaderDelegate<NSObject>
-(void)imageUploadProgress:(float)progress;
-(void)imageUploadDidFail;
-(void)imageUploadNotAuthorized;
-(void)imageUploadDidFinish:(NSDictionary *)response bid:(int)bid;
@end

@interface ImageUploader : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate> {
    NSURLConnection *_connection;
    UIImage *_image;
    NSMutableData *_response;
    NSObject<ImageUploaderDelegate> *_delegate;
    int _bid;
    NSString *_msg;
    NSData *_body;
}
@property NSObject<ImageUploaderDelegate> *delegate;
@property int bid;
@property NSString *msg;
-(void)upload:(UIImage *)image;
@end
