//
//  FileUploader.h
//  IRCCloud
//
//  Created by Sam Steele on 11/10/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FileUploaderDelegate<NSObject>
-(void)fileUploadProgress:(float)progress;
-(void)fileUploadDidFail;
-(void)fileUploadDidFinish:(NSDictionary *)response bid:(int)bid filename:(NSString *)filename;
@end

@interface FileUploader : NSObject<NSURLConnectionDelegate,NSURLConnectionDataDelegate,NSURLSessionDataDelegate,NSURLSessionDownloadDelegate> {
    NSURLConnection *_connection;
    NSMutableData *_response;
    NSObject<FileUploaderDelegate> *_delegate;
    int _bid;
    NSString *_msg;
    NSMutableData *_body;
    NSString *_filename;
    NSString *_mimeType;
}
@property NSObject<FileUploaderDelegate> *delegate;
@property int bid;
@property NSString *msg;
-(void)uploadFile:(NSURL *)file;
-(void)uploadImage:(UIImage *)image;
@end
