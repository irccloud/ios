//
//  FileMetadataViewController.h
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


#import <UIKit/UIKit.h>
#import "FileUploader.h"

@interface FileMetadataViewController : UITableViewController<UITextFieldDelegate,UITextViewDelegate,FileUploaderMetadataDelegate> {
    UITextField *_filename;
    UITextView *_msg;
    NSString *_metadata;
    FileUploader *_uploader;
    UIImageView *_imageView;
    CGFloat _imageHeight;
    BOOL _done;
    NSString *_url;
}
@property (readonly) UITextView *msg;
- (id)initWithUploader:(FileUploader *)uploader;
- (void)setURL:(NSString *)url;
- (void)setImage:(UIImage *)image;
- (void)setFilename:(NSString *)filename metadata:(NSString *)metadata;
- (void)showCancelButton;
@end
