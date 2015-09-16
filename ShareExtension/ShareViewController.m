//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "ShareViewController.h"
#import "BuffersTableView.h"
#import "UIColor+IRCCloud.h"

@implementation ShareViewController

- (void)presentationAnimationDidFinish {
    if(_conn.session.length) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        if([d boolForKey:@"uploadsAvailable"]) {
            NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
            NSExtensionItem *output = [input copy];
            output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
            
            if(output.attachments.count) {
                NSItemProvider *i = nil;
                for(NSItemProvider *p in output.attachments) {
                    if(([p hasItemConformingToTypeIdentifier:@"public.file-url"] && ![p hasItemConformingToTypeIdentifier:@"public.image"]) || [p hasItemConformingToTypeIdentifier:@"public.movie"]) {
                        NSLog(@"Attachment is file URL");
                        i = p;
                        break;
                    }
                }
                if(!i) {
                    for(NSItemProvider *p in output.attachments) {
                        if([p hasItemConformingToTypeIdentifier:@"public.image"]) {
                            NSLog(@"Attachment is image");
                            i = p;
                            break;
                        }
                    }
                }
                if(!i)
                    i = output.attachments.firstObject;
                
                NSItemProviderCompletionHandler imageHandler = ^(UIImage *item, NSError *error) {
                    if([[d objectForKey:@"imageService"] isEqualToString:@"IRCCloud"]) {
                        NSLog(@"Uploading image to IRCCloud");
                        _item = item;
                        [_fileUploader uploadImage:item];
                        if(!_filename)
                            _filename = _fileUploader.originalFilename;
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self reloadConfigurationItems];
                            [self validateContent];
                        }];
                    } else {
                        _uploadStarted = YES;
                    }
                };
                
                NSItemProviderCompletionHandler urlHandler = ^(NSURL *item, NSError *error) {
                    if([i hasItemConformingToTypeIdentifier:@"public.image"] && ![item.pathExtension.lowercaseString isEqualToString:@"gif"] && ![item.pathExtension.lowercaseString isEqualToString:@"png"]) {
                            _fileUploader.originalFilename = [[item pathComponents] lastObject];
                        [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                    } else {
                        if([[d objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] || ![i hasItemConformingToTypeIdentifier:@"public.image"]) {
                            NSLog(@"Uploading file to IRCCloud");
                            [i hasItemConformingToTypeIdentifier:@"public.movie"]?[_fileUploader uploadVideo:item]:[_fileUploader uploadFile:item];
                            if(!_filename)
                                _filename = _fileUploader.originalFilename;
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self reloadConfigurationItems];
                                [self validateContent];
                            }];
                        }
                    }
                };
                
                if([i hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                    [i loadItemForTypeIdentifier:@"public.file-url" options:nil completionHandler:urlHandler];
                } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
                    [i loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:urlHandler];
                } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
                    [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                } else {
                    _uploadStarted = YES;
                }
            }
        } else {
            _uploadStarted = YES;
        }
    } else {
        UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Not Logged in" message:@"Please login to the IRCCloud app before sharing." preferredStyle:UIAlertControllerStyleAlert];
        [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [self cancel];
        }]];
        [self presentViewController:c animated:YES completion:nil];
    }
}

- (void)viewDidLoad {
    [UIColor setTheme:@"dawn"];
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogComplete:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    IRCCLOUD_HOST = [d objectForKey:@"host"];
    IRCCLOUD_PATH = [d objectForKey:@"path"];
    _uploader = [[ImageUploader alloc] init];
    _uploader.delegate = self;
    _fileUploader = [[FileUploader alloc] init];
    _fileUploader.delegate = self;
    [[NSUserDefaults standardUserDefaults] setObject:[d objectForKey:@"cacheVersion"] forKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"fontSize":@([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 0.8)}];
    if([d objectForKey:@"fontSize"])
        [[NSUserDefaults standardUserDefaults] setObject:[d objectForKey:@"fontSize"] forKey:@"fontSize"];
    [NetworkConnection sync];
    _conn = [NetworkConnection sharedInstance];
    if(_conn.session.length) {
        if([BuffersDataSource sharedInstance].count && _conn.userInfo) {
            _buffer = [[BuffersDataSource sharedInstance] getBuffer:[[_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
        }
        [_conn connect:YES];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.title = @"IRCCloud";
    _sound = 1001;
    //AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"a" ofType:@"caf"]], &_sound);
}

- (void)backlogComplete:(NSNotification *)n {
    if(!_buffer)
        _buffer = [[BuffersDataSource sharedInstance] getBuffer:[[_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
    if(!_buffer)
        _buffer = [[BuffersDataSource sharedInstance] getBuffer:[BuffersDataSource sharedInstance].firstBid];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self reloadConfigurationItems];
        [self validateContent];
    }];
}

- (BOOL)isContentValid {
    if(_fileUploader && !_uploadStarted)
        return NO;
    return _conn.session.length && _buffer != nil && ![_buffer.type isEqualToString:@"console"];
}

- (void)didSelectPost {
    NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
    NSExtensionItem *output = [input copy];
    output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];

    if(output.attachments.count) {
        if(_fileUploader.originalFilename) {
            NSLog(@"Setting filename, bid, and message for IRCCloud upload");
            _fileUploader.bid = _buffer.bid;
            [_fileUploader setFilename:_filename message:self.contentText];
            if(!_fileUploader.finished) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
                }];
            }
        } else {
            NSItemProvider *i = nil;
            for(NSItemProvider *p in output.attachments) {
                if([p hasItemConformingToTypeIdentifier:@"public.url"] && ![p hasItemConformingToTypeIdentifier:@"public.image"]) {
                    i = p;
                    break;
                }
            }
            if(!i) {
                for(NSItemProvider *p in output.attachments) {
                    if([p hasItemConformingToTypeIdentifier:@"public.image"]) {
                        i = p;
                        break;
                    }
                }
            }
            if(!i)
                i = output.attachments.firstObject;

            NSItemProviderCompletionHandler imageHandler = ^(UIImage *item, NSError *error) {
                NSLog(@"Uploading image to imgur");
                _uploader.bid = _buffer.bid;
                _uploader.msg = self.contentText;
                [_uploader upload:item];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                }];
            };
            
            NSItemProviderCompletionHandler urlHandler = ^(NSURL *item, NSError *error) {
                if([item.scheme isEqualToString:@"file"] && [i hasItemConformingToTypeIdentifier:@"public.image"]) {
                    [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                } else {
                    if(self.contentText.length)
                        [_conn say:[NSString stringWithFormat:@"%@ %@",self.contentText,item.absoluteString] to:_buffer.name cid:_buffer.cid];
                    else
                        [_conn say:item.absoluteString to:_buffer.name cid:_buffer.cid];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                        AudioServicesPlaySystemSound(_sound);
                    }];
                }
            };
            
            if([i hasItemConformingToTypeIdentifier:@"public.url"]) {
                [i loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:urlHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
                [i loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:urlHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
                [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.plain-text"]) {
                [_conn say:self.contentText to:_buffer.name cid:_buffer.cid];
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                AudioServicesPlaySystemSound(_sound);
            } else {
                CLS_LOG(@"Unknown attachment type: %@", output.attachments.firstObject);
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                AudioServicesPlaySystemSound(_sound);
            }
        }
    } else {
        [_conn say:self.contentText to:_buffer.name cid:_buffer.cid];
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
        AudioServicesPlaySystemSound(_sound);
    }
}

- (NSArray *)configurationItems {
    if(_conn.session.length) {
        SLComposeSheetConfigurationItem *bufferConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
        bufferConfigItem.title = @"Conversation";
        if(_buffer) {
            if(![_buffer.type isEqualToString:@"console"])
                bufferConfigItem.value = _buffer.name;
            else
                bufferConfigItem.value = nil;
        } else {
            bufferConfigItem.valuePending = YES;
        }
        
        bufferConfigItem.tapHandler = ^() {
            BuffersTableView *b = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
            [b setPreferredContentSize:CGSizeMake(self.navigationController.preferredContentSize.width, [BuffersDataSource sharedInstance].count * 42)];
            b.navigationItem.title = @"Conversations";
            b.delegate = self;
            [self pushConfigurationViewController:b];
        };

#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        if([d boolForKey:@"uploadsAvailable"]) {
            NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
            NSExtensionItem *output = [input copy];
            output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
            
            if(output.attachments.count && (([[d objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] && [output.attachments.firstObject hasItemConformingToTypeIdentifier:@"public.image"]) || [output.attachments.firstObject hasItemConformingToTypeIdentifier:@"public.movie"])) {
                SLComposeSheetConfigurationItem *filenameConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
                filenameConfigItem.title = @"Filename";
                if(_filename)
                    filenameConfigItem.value = _filename;
                else
                    filenameConfigItem.valuePending = YES;
                
                filenameConfigItem.tapHandler = ^() {
                    [self.view.window endEditing:YES];
                    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Enter a Filename" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [c addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.text = _filename;
                        textField.delegate = self;
                        textField.placeholder = @"Filename";
                    }];
                    [c addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        _filename = [[c.textFields objectAtIndex:0] text];
                        [self reloadConfigurationItems];
                    }]];
                    
                    [self presentViewController:c animated:YES completion:nil];
                };
                
                if(!_uploadStarted) {
                    SLComposeSheetConfigurationItem *exporting = [[SLComposeSheetConfigurationItem alloc] init];
                    exporting.title = [output.attachments.firstObject hasItemConformingToTypeIdentifier:@"public.movie"]?@"Exporting Video":@"Resizing Photo";
                    exporting.valuePending = YES;

                    return @[filenameConfigItem, bufferConfigItem, exporting];
                } else {
                    return @[filenameConfigItem, bufferConfigItem];
                }
            } else {
                return @[bufferConfigItem];
            }
        } else {
            return @[bufferConfigItem];
        }
    } else {
        return nil;
    }
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if(textField.text.length) {
        textField.selectedTextRange = [textField textRangeFromPosition:textField.beginningOfDocument
                                                            toPosition:([textField.text rangeOfString:@"."].location != NSNotFound)?[textField positionFromPosition:textField.beginningOfDocument offset:[textField.text rangeOfString:@"." options:NSBackwardsSearch].location]:textField.endOfDocument];
    }
}

-(void)bufferSelected:(int)bid {
    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
    if(b && ![b.type isEqualToString:@"console"]) {
        _buffer = b;
        [self reloadConfigurationItems];
        [self validateContent];
        [self popConfigurationViewController];
    }
}

-(void)bufferLongPressed:(int)bid rect:(CGRect)rect {
    
}

-(void)dismissKeyboard {
    
}

-(void)fileUploadProgress:(float)progress {
    if(!_uploadStarted) {
        NSLog(@"File upload started");
        _uploadStarted = YES;
        [self reloadConfigurationItems];
        [self validateContent];
    }
}

-(void)fileUploadDidFail {
    NSLog(@"File upload failed");
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"Unable to upload file to IRCCloud. Please try again later." preferredStyle:UIAlertControllerStyleAlert];
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancel];
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }]];
    [self presentViewController:c animated:YES completion:nil];
}

-(void)fileUploadTooLarge {
    NSLog(@"File upload too large");
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"Sorry, you can’t upload files larger than 15 MB" preferredStyle:UIAlertControllerStyleAlert];
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancel];
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }]];
    [self presentViewController:c animated:YES completion:nil];
}

-(void)fileUploadDidFinish {
    NSLog(@"File upload successful");
    [_conn disconnect];
    AudioServicesPlaySystemSound(_sound);
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }];
}

-(void)fileUploadWasCancelled {
}

-(void)imageUploadProgress:(float)progress {
}

-(void)imageUploadDidFail {
    NSLog(@"Image upload failed");
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"Unable to upload photo to imgur. Please try again later." preferredStyle:UIAlertControllerStyleAlert];
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancel];
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }]];
    [self presentViewController:c animated:YES completion:nil];
}

-(void)imageUploadNotAuthorized {
    NSLog(@"Image upload not authorized");
    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:@"Unable to authorize your imgur account. Check your imgur username and password and try again." preferredStyle:UIAlertControllerStyleAlert];
    [c addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [self cancel];
        [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
    }]];
    [self presentViewController:c animated:YES completion:nil];
}

-(void)imageUploadDidFinish:(NSDictionary *)d bid:(int)bid {
    if([[d objectForKey:@"success"] intValue] == 1) {
        NSLog(@"Image upload successful");
        NSString *link = [[[d objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
        if(self.contentText.length)
            [_conn say:[NSString stringWithFormat:@"%@ %@", self.contentText, link] to:_buffer.name cid:_buffer.cid];
        else
            [_conn say:link to:_buffer.name cid:_buffer.cid];
    } else {
        NSLog(@"Image upload failed");
    }
    [_conn disconnect];
    AudioServicesPlaySystemSound(_sound);
}

@end
