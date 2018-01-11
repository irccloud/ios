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
        _buffer = buffer;
        _sayreqid = -1;
        
        _type = [[UISegmentedControl alloc] initWithItems:@[@"Snippet", @"Messages"]];
        _type.selectedSegmentIndex = 0;
        [_type addTarget:self action:@selector(_typeToggled) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = _type;
    }
    return self;
}

-(void)_typeToggled {
    [self.tableView reloadData];
    [self textViewDidChange:_text];
}

-(id)initWithPasteID:(NSString *)pasteID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Text Snippet";
        _pasteID = pasteID;
        _sayreqid = -1;
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    }
    return self;
}

-(void)_fetchPaste {
    NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:@{@"id":_pasteID, @"type":@"json"} error:nil];
    
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching pastebin. Error %li : %@", (long)error.code, error.userInfo);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            _text.text = [dict objectForKey:@"body"];
            _filename.text = [dict objectForKey:@"name"];
            _text.editable = _filename.enabled = YES;
            _extension = [dict objectForKey:@"extension"];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
    }];

}

-(void)sendButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];

    if(_type.selectedSegmentIndex == 1) {
        if(_message.text.length) {
            _buffer.draft = [NSString stringWithFormat:@"%@ %@", _message.text, _text.text];
        } else {
            _buffer.draft = _text.text;
        }
        _sayreqid = [[NetworkConnection sharedInstance] say:_buffer.draft to:_buffer.name cid:_buffer.cid handler:^(IRCCloudJSONObject *result) {
            if(![[result objectForKey:@"success"] boolValue]) {
                UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
                [v show];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        }];
    } else {
        if([_filename.text rangeOfString:@"."].location != NSNotFound) {
            NSString *extension = [_filename.text substringFromIndex:[_filename.text rangeOfString:@"." options:NSBackwardsSearch].location + 1];
            if(extension.length)
                _extension = extension;
            else if(!_extension.length)
                _extension = @"txt";
                
        } else {
            if(!_extension.length)
                _extension = @"txt";
        }
        
        IRCCloudAPIResultHandler pasteHandler = ^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                if(_pasteID) {
                    [self.tableView endEditing:YES];
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    if(_message.text.length) {
                        _buffer.draft = [NSString stringWithFormat:@"%@ %@", _message.text, [result objectForKey:@"url"]];
                    } else {
                        _buffer.draft = [result objectForKey:@"url"];
                    }
                    _sayreqid = [[NetworkConnection sharedInstance] say:_buffer.draft to:_buffer.name cid:_buffer.cid handler:^(IRCCloudJSONObject *result) {
                        if(![result objectForKey:@"success"]) {
                            UIAlertView *v = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
                            [v show];
                        }
                    }];
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save snippet, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:_pasteID?@"Save":@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        };
        
        if(_pasteID)
            [[NetworkConnection sharedInstance] editPaste:_pasteID name:_filename.text contents:_text.text extension:_extension handler:pasteHandler];
        else
            [[NetworkConnection sharedInstance] paste:_filename.text contents:_text.text extension:_extension handler:pasteHandler];
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

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Event *e;
    
    switch(event) {
        case kIRCEventBufferMsg:
            e = notification.object;
            if(_sayreqid > 0 && e.bid == _buffer.bid && (e.reqId == _sayreqid || (e.isSelf && [e.from isEqualToString:_buffer.name]))) {
                _buffer.draft = @"";
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView endEditing:YES];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    _buffer.draft = @"";
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

    _filename = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width - 32, 22)];
    _filename.text = @"";
    _filename.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _filename.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _filename.autocorrectionType = UITextAutocorrectionTypeNo;
    _filename.adjustsFontSizeToFitWidth = YES;
    _filename.returnKeyType = UIReturnKeyDone;
    _filename.delegate = self;
    _filename.enabled = !_pasteID;
    _filename.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _message = [[UITextView alloc] initWithFrame:CGRectZero];
    _message.text = @"";
    _message.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _message.backgroundColor = [UIColor clearColor];
    _message.returnKeyType = UIReturnKeyDone;
    _message.delegate = self;
    _message.font = _filename.font;
    _message.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _message.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        _message.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        _message.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }

    _messageFooter = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
    _messageFooter.backgroundColor = [UIColor clearColor];
    _messageFooter.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    _messageFooter.textAlignment = NSTextAlignmentCenter;
    _messageFooter.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _messageFooter.numberOfLines = 0;
    _messageFooter.adjustsFontSizeToFitWidth = YES;
    
    _text = [[UITextView alloc] initWithFrame:CGRectZero];
    _text.backgroundColor = [UIColor clearColor];
    _text.font = _filename.font;
    _text.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _text.delegate = self;
    _text.editable = !_pasteID;
    _text.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _text.text = _buffer.draft;
    _text.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        _text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        _text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    [self textViewDidChange:_text];
    
    if(_pasteID)
        [self _fetchPaste];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(textView == _message)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(textView != _text && [text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = (_text.text.length > 0);
    if(textView == _text) {
        int count = 0;
        NSArray *lines = [_text.text componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            count += ceil((float)line.length / 1080.0f);
        }
        if(_type.selectedSegmentIndex == 1)
            _messageFooter.text = [NSString stringWithFormat:@"Text will be sent as %i message%@", count, (count == 1)?@"":@"s"];
        else
            _messageFooter.text = @"Text snippets are visible to anyone with the URL but are not publicly listed or indexed.";
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
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(_pasteID)
        return 2;
    else if(_type.selectedSegmentIndex == 0)
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

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,24)];
    UILabel *label;
    if(@available(iOS 11, *)) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,0,self.view.frame.size.width - 32, 20)];
    } else {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16,0,self.view.frame.size.width - 32, 20)];
    }
    label.text = [self tableView:tableView titleForHeaderInSection:section].uppercaseString;
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [header addSubview:label];
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 48;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if(section == 0) {
        if(@available(iOS 11, *)) {
            CGRect frame = _messageFooter.frame;
            frame.origin.x = self.view.safeAreaInsets.left;
            _messageFooter.frame = frame;
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
            [_text removeFromSuperview];
            _text.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:_text];
            break;
        case 1:
            cell.accessoryView = _filename;
            break;
        case 2:
            cell.textLabel.text = nil;
            [_message removeFromSuperview];
            _message.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:_message];
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
