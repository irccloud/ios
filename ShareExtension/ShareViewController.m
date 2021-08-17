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
    if(self->_conn.session.length) {
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
                    if([p hasItemConformingToTypeIdentifier:@"public.url"] && ![p hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                        NSLog(@"Attachment has a public URL");
                        i = p;
                        break;
                    }
                }
                if(!i) {
                    for(NSItemProvider *p in output.attachments) {
                        if(([p hasItemConformingToTypeIdentifier:@"public.file-url"] && ![p hasItemConformingToTypeIdentifier:@"public.image"]) || [p hasItemConformingToTypeIdentifier:@"public.movie"]) {
                            NSLog(@"Attachment is file URL");
                            i = p;
                            break;
                        }
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
                        self->_item = item;
                        if([i hasItemConformingToTypeIdentifier:@"public.png"])
                            [self->_fileUploader uploadPNG:item];
                        else
                            [self->_fileUploader uploadImage:item];
                        if(!self->_filename)
                            self->_filename = self->_fileUploader.originalFilename;
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self reloadConfigurationItems];
                            [self validateContent];
                        }];
                    } else {
                        self->_uploadStarted = YES;
                    }
                };
                
                NSItemProviderCompletionHandler urlHandler = ^(NSURL *item, NSError *error) {
                    if([i hasItemConformingToTypeIdentifier:@"public.image"] && ![item.pathExtension.lowercaseString isEqualToString:@"gif"] && ![item.pathExtension.lowercaseString isEqualToString:@"png"]) {
                            self->_fileUploader.originalFilename = [[item pathComponents] lastObject];
                        [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                    } else {
                        if([[d objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] || ![i hasItemConformingToTypeIdentifier:@"public.image"]) {
                            NSLog(@"Uploading file to IRCCloud");
                            [i hasItemConformingToTypeIdentifier:@"public.movie"]?[self->_fileUploader uploadVideo:item]:[self->_fileUploader uploadFile:item];
                            if(!self->_filename)
                                self->_filename = self->_fileUploader.originalFilename;
                            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                [self reloadConfigurationItems];
                                [self validateContent];
                            }];
                        }
                    }
                };
                
                if([i hasItemConformingToTypeIdentifier:@"public.file-url"]) {
                    [i loadItemForTypeIdentifier:@"public.file-url" options:nil completionHandler:urlHandler];
                } else if([i hasItemConformingToTypeIdentifier:@"public.url"]) {
                    self->_fileUploader = nil;
                    [self reloadConfigurationItems];
                    [self validateContent];
                } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
                    [i loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:urlHandler];
                } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
                    [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                } else {
                    self->_uploadStarted = YES;
                }
            }
        } else {
            self->_uploadStarted = YES;
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
    __weak ShareViewController *weakSelf = self;
    self->_resultHandler = ^(IRCCloudJSONObject *result) {
        NSLog(@"Say result: %@", result);
        [weakSelf.extensionContext completeRequestReturningItems:nil completionHandler:nil];
        AudioServicesPlaySystemSound(weakSelf.sound);
    };
    [UIColor setTheme:@"dawn"];
    if (@available(iOS 13, *)) {
        NSString *theme = [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark?@"midnight":@"dawn";
        [UIColor setTheme:theme];
        self.view.window.overrideUserInterfaceStyle = self.view.overrideUserInterfaceStyle = [theme isEqualToString:@"dawn"]?UIUserInterfaceStyleLight:UIUserInterfaceStyleDark;
    } else {
        [UIColor setTheme:@"dawn"];
    }
    [super viewDidLoad];
    self.textView.superview.superview.superview.superview.backgroundColor = [UIColor contentBackgroundColor];
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
    self->_uploader = [[ImageUploader alloc] init];
    self->_uploader.delegate = self;
    self->_fileUploader = [[FileUploader alloc] init];
    self->_fileUploader.delegate = self;
    [[NSUserDefaults standardUserDefaults] setObject:[d objectForKey:@"cacheVersion"] forKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"fontSize":@([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 0.8)}];
    if([d objectForKey:@"fontSize"])
        [[NSUserDefaults standardUserDefaults] setObject:[d objectForKey:@"fontSize"] forKey:@"fontSize"];
    [NetworkConnection sync];
    self->_conn = [NetworkConnection sharedInstance];
    if(self->_conn.session.length) {
        if([BuffersDataSource sharedInstance].count && _conn.userInfo) {
            self->_buffer = [[BuffersDataSource sharedInstance] getBuffer:[[self->_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
        }
        [self->_conn connect:YES];
    }
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.title = @"IRCCloud";
    self->_sound = 1001;
    self.textView.returnKeyType = UIReturnKeySend;
    self.textView.delegate = self;
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [self didSelectPost];
        return NO;
    }
    return YES;
}

- (void)backlogComplete:(NSNotification *)n {
    if(!self->_buffer)
        self->_buffer = [[BuffersDataSource sharedInstance] getBuffer:[[self->_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
    if(!self->_buffer)
        self->_buffer = [[BuffersDataSource sharedInstance] getBuffer:[BuffersDataSource sharedInstance].mostRecentBid];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self reloadConfigurationItems];
        [self validateContent];
    }];
}

- (BOOL)isContentValid {
    if(self->_fileUploader && !self->_uploadStarted)
        return NO;
    return _conn.session.length && _buffer != nil && ![self->_buffer.type isEqualToString:@"console"];
}

- (void)didSelectPost {
    NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
    NSExtensionItem *output = [input copy];
    output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];

    if(output.attachments.count) {
        if(self->_fileUploader.originalFilename) {
            NSLog(@"Setting filename, bid, and message for IRCCloud upload");
            self->_fileUploader.bid = self->_buffer.bid;
            [self->_fileUploader setFilename:self->_filename message:self.contentText];
            if(!self->_fileUploader.finished) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
                }];
            }
        } else {
            NSItemProvider *i = nil;
            for(NSItemProvider *p in output.attachments) {
                if([p hasItemConformingToTypeIdentifier:@"public.url"] && ![p hasItemConformingToTypeIdentifier:@"public.file-url"]) {
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
                self->_uploader.bid = self->_buffer.bid;
                self->_uploader.msg = self.contentText;
                [self->_uploader upload:item];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                }];
            };
            
            NSItemProviderCompletionHandler urlHandler = ^(NSURL *item, NSError *error) {
                if([item.scheme isEqualToString:@"file"] && [i hasItemConformingToTypeIdentifier:@"public.image"]) {
                    [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
                } else {
                    if(self.contentText.length)
                        [self->_conn say:[NSString stringWithFormat:@"%@ %@",self.contentText,item.absoluteString] to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
                    else
                        [self->_conn say:item.absoluteString to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
                }
            };
            
            if([i hasItemConformingToTypeIdentifier:@"public.url"]) {
                [i loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:urlHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.movie"]) {
                [i loadItemForTypeIdentifier:@"public.movie" options:nil completionHandler:urlHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.image"]) {
                [i loadItemForTypeIdentifier:@"public.image" options:nil completionHandler:imageHandler];
            } else if([i hasItemConformingToTypeIdentifier:@"public.plain-text"]) {
                [self->_conn say:self.contentText to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
            } else {
                NSLog(@"Unknown attachment type: %@", output.attachments.firstObject);
                [self.extensionContext completeRequestReturningItems:nil completionHandler:nil];
                AudioServicesPlaySystemSound(self->_sound);
            }
        }
    } else {
        [self->_conn say:self.contentText to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
    }
}

- (NSArray *)configurationItems {
    if(self->_conn.session.length) {
        SLComposeSheetConfigurationItem *bufferConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
        bufferConfigItem.title = @"Conversation";
        if(self->_buffer) {
            if(![self->_buffer.type isEqualToString:@"console"])
                bufferConfigItem.value = self->_buffer.displayName;
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
        if(self->_fileUploader && [d boolForKey:@"uploadsAvailable"]) {
            NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
            NSExtensionItem *output = [input copy];
            output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];
            
            if(output.attachments.count && (([[d objectForKey:@"imageService"] isEqualToString:@"IRCCloud"] && [output.attachments.firstObject hasItemConformingToTypeIdentifier:@"public.image"]) || [output.attachments.firstObject hasItemConformingToTypeIdentifier:@"public.movie"])) {
                SLComposeSheetConfigurationItem *filenameConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
                filenameConfigItem.title = @"Filename";
                if(self->_filename)
                    filenameConfigItem.value = self->_filename;
                else
                    filenameConfigItem.valuePending = YES;
                
                filenameConfigItem.tapHandler = ^() {
                    [self.view.window endEditing:YES];
                    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Enter a Filename" message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [c addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                        textField.text = self->_filename;
                        textField.delegate = self;
                        textField.placeholder = @"Filename";
                        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                    }];
                    [c addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                        self->_filename = [[c.textFields objectAtIndex:0] text];
                        [self reloadConfigurationItems];
                    }]];
                    
                    [self presentViewController:c animated:YES completion:nil];
                };
                
                if(!self->_uploadStarted) {
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
        self->_buffer = b;
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
    if(!self->_uploadStarted) {
        NSLog(@"File upload started");
        self->_uploadStarted = YES;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self reloadConfigurationItems];
            [self validateContent];
        }];
    }
}

-(void)fileUploadDidFail:(NSString *)reason {
    NSLog(@"File upload failed: %@", reason);
    
    NSString *msg;
    if([reason isEqualToString:@"upload_limit_reached"]) {
        msg = @"Sorry, you can’t upload more than 100 MB of files.  Delete some uploads and try again.";
    } else if([reason isEqualToString:@"upload_already_exists"]) {
        msg = @"You’ve already uploaded this file";
    } else if([reason isEqualToString:@"banned_content"]) {
        msg = @"Banned content";
    } else {
        msg= @"Failed to upload file. Please try again shortly.";
    }

    UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Upload Failed" message:msg preferredStyle:UIAlertControllerStyleAlert];
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
    [self->_conn disconnect];
    AudioServicesPlaySystemSound(self->_sound);
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
            [self->_conn say:[NSString stringWithFormat:@"%@ %@", self.contentText, link] to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
        else
            [self->_conn say:link to:self->_buffer.name cid:self->_buffer.cid handler:self->_resultHandler];
    } else {
        NSLog(@"Image upload failed");
    }
    [self->_conn disconnect];
    AudioServicesPlaySystemSound(self->_sound);
}

-(void)spamSelected:(int)cid {
    
}
@end
