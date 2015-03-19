//
//  FileMetadataViewController.m
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

#import "FileMetadataViewController.h"

@implementation FileMetadataViewController

- (id)initWithUploader:(FileUploader *)uploader {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        uploader.metadatadelegate = self;
        _uploader = uploader;
        self.navigationItem.title = @"Upload a File";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    }
    return self;
}

-(void)fileUploadWillUpload:(NSUInteger)bytes mimeType:(NSString *)mimeType {
    if(bytes < 1024) {
        _metadata = [NSString stringWithFormat:@"%lu B • %@", (unsigned long)bytes, mimeType];
    } else {
        int exp = (int)(log(bytes) / log(1024));
        _metadata = [NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], mimeType];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}

-(void)saveButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [_uploader setFilename:_filename.text message:_msg.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [_uploader cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!_filename.text.length)
        _filename.text = _uploader.originalFilename;
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int padding = 80;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        padding = 26;
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
        padding = 0;
    }
    
    _filename = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _filename.textAlignment = NSTextAlignmentRight;
    _filename.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _filename.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _filename.autocorrectionType = UITextAutocorrectionTypeNo;
    _filename.keyboardType = UIKeyboardTypeDefault;
    _filename.adjustsFontSizeToFitWidth = YES;
    _filename.returnKeyType = UIReturnKeyDone;
    _filename.delegate = self;
    
    _msg = [[UITextView alloc] initWithFrame:CGRectZero];
    _msg.text = @"";
    _msg.backgroundColor = [UIColor clearColor];
    _msg.returnKeyType = UIReturnKeyDone;
    _msg.delegate = self;
    _msg.font = _filename.font;
    _msg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

-(void)setImage:(UIImage *)image {
    CGFloat width = image.size.width, height = image.size.height;
    
    if(width > self.tableView.frame.size.width) {
        height *= self.tableView.frame.size.width / width;
        width = self.tableView.frame.size.width;
    }
    
    if(height > 240) {
        height = 240;
    }
    
    _imageView.image = image;
    _imageHeight = height;
    
    [self.tableView reloadData];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(_imageView)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    else
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if(_imageView)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    else
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];

    if(textField.text.length) {
        textField.selectedTextRange = [textField textRangeFromPosition:textField.beginningOfDocument
                                                            toPosition:([textField.text rangeOfString:@"."].location != NSNotFound)?[textField positionFromPosition:textField.beginningOfDocument offset:[textField.text rangeOfString:@"." options:NSBackwardsSearch].location]:textField.endOfDocument];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int section = indexPath.section;
    if(!_imageView)
        section++;
    
    if(section == 0)
        return _imageHeight;
    else if(section == 2)
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (_imageView)?3:2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(_imageView && section > 0)
        section--;
    
    switch (section) {
        case 1:
            return @"Message (optional)";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == ((_imageView)?1:0))
        return _metadata;
    else
        return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger section = indexPath.section;
    NSString *identifier = [NSString stringWithFormat:@"uploadcell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;
    cell.backgroundView = nil;
    
    if(!_imageView)
        section++;
    
    switch(section) {
        case 0:
            cell.backgroundView = _imageView;
            cell.backgroundColor = [UIColor clearColor];
            break;
        case 1:
            cell.textLabel.text = @"Filename";
            cell.accessoryView = _filename;
            break;
        case 2:
            cell.textLabel.text = nil;
            [_msg removeFromSuperview];
            _msg.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:_msg];
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
