//
//  ImageUploader.h
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
