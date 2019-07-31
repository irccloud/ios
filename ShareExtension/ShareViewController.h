//
//  ShareViewController.h
//  ShareExtension
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "BuffersTableView.h"
#import "NetworkConnection.h"
#import "ImageUploader.h"
#import "FileUploader.h"

@interface ShareViewController : SLComposeServiceViewController<BuffersTableViewDelegate,ImageUploaderDelegate,FileUploaderDelegate,UITextFieldDelegate,UITextViewDelegate> {
    NetworkConnection *_conn;
    BuffersTableView *_buffersView;
    UIViewController *_splash;
    Buffer *_buffer;
    ImageUploader *_uploader;
    FileUploader *_fileUploader;
    SystemSoundID _sound;
    NSString *_filename;
    UIImage *_item;
    BOOL _uploadStarted;
    IRCCloudAPIResultHandler _resultHandler;
}
@property SystemSoundID sound;
@end
