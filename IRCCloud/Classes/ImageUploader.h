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
-(void)imageUploadDidFinish:(NSDictionary *)response;
@end

@interface ImageUploader : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate> {
    NSURLConnection *_connection;
    UIImage *_image;
    NSMutableData *_response;
    id<ImageUploaderDelegate> _delegate;
}
@property id<ImageUploaderDelegate> delegate;
-(void)upload:(UIImage *)image;
@end
