//
//  PastebinEditorViewController.m
//
//  Copyright (C) 2015 IRCCloud, Ltd.
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

#import "PastebinEditorViewController.h"
#import "NetworkConnection.h"
#import "CSURITemplate.h"
#import "UIColor+IRCCloud.h"
#import "AppDelegate.h"

@interface PastebinEditorCell : UITableViewCell

@end

@implementation PastebinEditorCell
- (void) layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.frame.size.width - self.textLabel.frame.origin.x, self.textLabel.frame.size.height);
}
@end

@implementation PastebinEditorViewController

-(id)initWithBuffer:(Buffer *)buffer {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Text Snippet";
        if(buffer)
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        self->_buffer = buffer;
        self->_sayreqid = -1;
        
        self->_type = [[UISegmentedControl alloc] initWithItems:@[@"Snippet", @"Messages"]];
        self->_type.selectedSegmentIndex = 0;
        [self->_type addTarget:self action:@selector(_typeToggled) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = self->_type;
    }
    return self;
}

-(void)_typeToggled {
    [self.tableView reloadData];
    [self textViewDidChange:self->_text];
}

-(id)initWithPasteID:(NSString *)pasteID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Text Snippet";
        self->_pasteID = pasteID;
        self->_sayreqid = -1;
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    }
    return self;
}

-(void)_fetchPaste {
    NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:@{@"id":self->_pasteID, @"type":@"json"} error:nil];
    
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching pastebin. Error %li : %@", (long)error.code, error.userInfo);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            self->_text.text = [dict objectForKey:@"body"];
            self->_filename.text = [dict objectForKey:@"name"];
            self->_text.editable = self->_filename.enabled = YES;
            self->_extension = [dict objectForKey:@"extension"];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
    }];
}

-(void)sendButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];

    if(self->_type.selectedSegmentIndex == 1) {
        if(self->_message.text.length) {
            self->_buffer.draft = [NSString stringWithFormat:@"%@ %@", _message.text, _text.text];
        } else {
            self->_buffer.draft = self->_text.text;
        }
        self->_sayreqid = [[NetworkConnection sharedInstance] say:self->_buffer.draft to:self->_buffer.name cid:self->_buffer.cid handler:^(IRCCloudJSONObject *result) {
            if(![[result objectForKey:@"success"] boolValue]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        }];
    } else {
        if([self->_filename.text rangeOfString:@"."].location != NSNotFound) {
            NSString *extension = [self->_filename.text substringFromIndex:[self->_filename.text rangeOfString:@"." options:NSBackwardsSearch].location + 1];
            if(extension.length)
                self->_extension = extension;
            else if(!_extension.length)
                self->_extension = @"txt";
                
        } else {
            if(!_extension.length)
                self->_extension = @"txt";
        }
        
        IRCCloudAPIResultHandler pasteHandler = ^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                if(self->_pasteID) {
                    [self.tableView endEditing:YES];
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    if(self->_message.text.length) {
                        self->_buffer.draft = [NSString stringWithFormat:@"%@ %@", self->_message.text, [result objectForKey:@"url"]];
                    } else {
                        self->_buffer.draft = [result objectForKey:@"url"];
                    }
                    self->_sayreqid = [[NetworkConnection sharedInstance] say:self->_buffer.draft to:self->_buffer.name cid:self->_buffer.cid handler:^(IRCCloudJSONObject *result) {
                        if(![result objectForKey:@"success"]) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }];
                }
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save snippet, please try again." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self->_pasteID?@"Save":@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        };
        
        if(self->_pasteID)
            [[NetworkConnection sharedInstance] editPaste:self->_pasteID name:self->_filename.text contents:self->_text.text extension:self->_extension handler:pasteHandler];
        else
            [[NetworkConnection sharedInstance] paste:self->_filename.text contents:self->_text.text extension:self->_extension handler:pasteHandler];
    }
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Event *e;
    
    switch(event) {
        case kIRCEventBufferMsg:
            e = notification.object;
            if(self->_sayreqid > 0 && e.bid == self->_buffer.bid && (e.reqId == self->_sayreqid || (e.isSelf && [e.from isEqualToString:self->_buffer.name]))) {
                self->_buffer.draft = @"";
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView endEditing:YES];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    self->_buffer.draft = @"";
                    [((AppDelegate *)[UIApplication sharedApplication].delegate).mainViewController clearText];
                }];
            }
            break;
        default:
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.clipsToBounds = YES;

    self->_filename = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width - 32, 22)];
    self->_filename.text = @"";
    self->_filename.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_filename.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_filename.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_filename.adjustsFontSizeToFitWidth = YES;
    self->_filename.returnKeyType = UIReturnKeyDone;
    self->_filename.delegate = self;
    self->_filename.enabled = !_pasteID;
    self->_filename.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    self->_message = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_message.text = @"";
    self->_message.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_message.backgroundColor = [UIColor clearColor];
    self->_message.returnKeyType = UIReturnKeyDone;
    self->_message.delegate = self;
    self->_message.font = self->_filename.font;
    self->_message.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_message.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_message.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_message.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }

    self->_messageFooter = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
    self->_messageFooter.backgroundColor = [UIColor clearColor];
    self->_messageFooter.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    self->_messageFooter.textAlignment = NSTextAlignmentCenter;
    self->_messageFooter.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_messageFooter.numberOfLines = 0;
    self->_messageFooter.adjustsFontSizeToFitWidth = YES;
    
    self->_text = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_text.backgroundColor = [UIColor clearColor];
    self->_text.font = self->_filename.font;
    self->_text.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_text.delegate = self;
    self->_text.editable = !_pasteID;
    self->_text.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_text.text = self->_buffer.draft;
    self->_text.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    [self textViewDidChange:self->_text];
    
    if(self->_pasteID)
        [self _fetchPaste];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(textView == self->_message)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(textView != self->_text && [text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = (self->_text.text.length > 0);
    if(textView == self->_text) {
        int count = 0;
        NSArray *lines = [self->_text.text componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            count += ceil((float)line.length / 1080.0f);
        }
        if(self->_type.selectedSegmentIndex == 1)
            self->_messageFooter.text = [NSString stringWithFormat:@"Text will be sent as %i message%@", count, (count == 1)?@"":@"s"];
        else
            self->_messageFooter.text = @"Text snippets are visible to anyone with the URL but are not publicly listed or indexed.";
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return 160;
    else if(indexPath.section == 2)
        return 64;
    else
        return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self->_pasteID)
        return 2;
    else if(self->_type.selectedSegmentIndex == 0)
        return 3;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
        case 1:
            return @"File name (optional)";
        case 2:
            return @"Message (optional)";
    }
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if(section == 0) {
        if(@available(iOS 11, *)) {
            CGRect frame = self->_messageFooter.frame;
            frame.origin.x = self.view.safeAreaInsets.left;
            self->_messageFooter.frame = frame;
        }
        return _messageFooter;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if(section == 0) {
        return 32;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSString *identifier = [NSString stringWithFormat:@"pastecell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    PastebinEditorCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(!cell)
        cell = [[PastebinEditorCell alloc] initWithStyle:(row == 3)?UITableViewCellStyleDefault:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;

    switch(indexPath.section) {
        case 0:
            cell.textLabel.text = nil;
            [self->_text removeFromSuperview];
            self->_text.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_text];
            break;
        case 1:
            cell.accessoryView = self->_filename;
            break;
        case 2:
            cell.textLabel.text = nil;
            [self->_message removeFromSuperview];
            self->_message.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_message];
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
}

@end
