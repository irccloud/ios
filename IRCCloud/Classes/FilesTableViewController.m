//
//  FilesTableViewController.m
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

#import "FilesTableViewController.h"
#import "NetworkConnection.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"
#import "FileMetadataViewController.h"
#import "ImageCache.h"

@interface FilesTableCell : UITableViewCell {
    UILabel *_date;
    UILabel *_name;
    UILabel *_metadata;
    UILabel *_extension;
    YYAnimatedImageView *_thumbnail;
    UIActivityIndicatorView *_spinner;
}
@property (readonly) UILabel *date,*name,*metadata,*extension;
@property (readonly) YYAnimatedImageView *thumbnail;
@property (readonly) UIActivityIndicatorView *spinner;
@end

@implementation FilesTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self->_date = [[UILabel alloc] init];
        self->_date.textColor = [UITableViewCell appearance].detailTextLabelColor;
        self->_date.font = [UIFont systemFontOfSize:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1].pointSize];
        [self.contentView addSubview:self->_date];

        self->_name = [[UILabel alloc] init];
        self->_name.textColor = [UITableViewCell appearance].textLabelColor;
        self->_name.font = [UIFont boldSystemFontOfSize:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1].pointSize];
        [self.contentView addSubview:self->_name];
        
        self->_metadata = [[UILabel alloc] init];
        self->_metadata.textColor = [UITableViewCell appearance].detailTextLabelColor;
        self->_metadata.font = [UIFont systemFontOfSize:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1].pointSize];
        [self.contentView addSubview:self->_metadata];
        
        self->_extension = [[UILabel alloc] init];
        self->_extension.textColor = [UIColor whiteColor];
        self->_extension.backgroundColor = [UIColor unreadBlueColor];
        self->_extension.font = [UIFont boldSystemFontOfSize:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1].pointSize];
        self->_extension.textAlignment = NSTextAlignmentCenter;
        self->_extension.hidden = YES;
        [self.contentView addSubview:self->_extension];

        self->_thumbnail = [[YYAnimatedImageView alloc] init];
        self->_thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        if(@available(iOS 11, *))
            self->_thumbnail.accessibilityIgnoresInvertColors = YES;
        [self.contentView addSubview:self->_thumbnail];
        
        self->_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [self.contentView addSubview:self->_spinner];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = [self.contentView bounds];
    frame.origin.x = 4;
    frame.origin.y = 4;
    frame.size.width -= 8;
    frame.size.height -= 8;
    
    self->_extension.frame = self->_spinner.frame = self->_thumbnail.frame = CGRectMake(frame.origin.x, frame.origin.y, 64, frame.size.height);
    self->_date.frame = CGRectMake(frame.origin.x + 64, frame.origin.y, frame.size.width - 64, frame.size.height / 3);
    self->_name.frame = CGRectMake(frame.origin.x + 64, _date.frame.origin.y + _date.frame.size.height, frame.size.width - 64, frame.size.height / 3);
    self->_metadata.frame = CGRectMake(frame.origin.x + 64, _name.frame.origin.y + _name.frame.size.height, frame.size.width - 64, frame.size.height / 3);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation FilesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
    self.navigationItem.title = @"File Uploads";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    self->_formatter = [[NSDateFormatter alloc] init];
    self->_formatter.dateStyle = NSDateFormatterLongStyle;
    self->_formatter.timeStyle = NSDateFormatterMediumStyle;
    self->_imageViews = [[NSMutableDictionary alloc] init];
    self->_spinners = [[NSMutableDictionary alloc] init];
    self->_extensions = [[NSMutableDictionary alloc] init];
    
    self->_footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    self->_footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    a.center = self->_footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [self->_footerView addSubview:a];
    
    self.tableView.tableFooterView = self->_footerView;
    self->_pages = 0;
    self->_files = nil;
    self->_canLoadMore = YES;
    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
}

-(void)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:self.tableView.isEditing?UIBarButtonSystemItemCancel:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    self->_files = nil;
    self->_canLoadMore = NO;
    [[ImageCache sharedInstance] clear];
}

-(void)_loadMore {
    @synchronized (self) {
        NSDictionary *d = [[NetworkConnection sharedInstance] getFiles:++_pages];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            if([[d objectForKey:@"success"] boolValue]) {
                CLS_LOG(@"Loaded file list for page %i", self->_pages);
                if(self->_files)
                    self->_files = [self->_files arrayByAddingObjectsFromArray:[d objectForKey:@"files"]];
                else
                    self->_files = [d objectForKey:@"files"];
                self->_canLoadMore = self->_files.count < [[d objectForKey:@"total"] intValue];
                self.tableView.tableFooterView = self->_canLoadMore?self->_footerView:nil;
                if(!self->_files.count) {
                    CLS_LOG(@"File list is empty");
                    UILabel *fail = [[UILabel alloc] init];
                    fail.text = @"\nYou haven't uploaded any files yet.\n";
                    fail.numberOfLines = 3;
                    fail.textAlignment = NSTextAlignmentCenter;
                    fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                    [fail sizeToFit];
                    self.tableView.tableFooterView = fail;
                }
            } else {
                CLS_LOG(@"Failed to load file list for page %i: %@", self->_pages, d);
                self->_canLoadMore = NO;
                UILabel *fail = [[UILabel alloc] init];
                fail.text = @"\nUnable to load files.\nPlease try again later.\n";
                fail.numberOfLines = 4;
                fail.textAlignment = NSTextAlignmentCenter;
                fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                [fail sizeToFit];
                self.tableView.tableFooterView = fail;
                return;
            }
            [self.tableView reloadData];
        }];
    }
}

-(void)_refreshFileID:(NSString *)fileID {
    [[self->_spinners objectForKey:fileID] stopAnimating];
    [[self->_spinners objectForKey:fileID] setHidden:YES];
    YYImage *image = [[ImageCache sharedInstance] imageForFileID:fileID width:(self.view.frame.size.width/2) * [UIScreen mainScreen].scale];
    if(image) {
        [[self->_imageViews objectForKey:fileID] setImage:image];
        [[self->_imageViews objectForKey:fileID] setHidden:NO];
        [[self->_extensions objectForKey:fileID] setHidden:YES];
    } else {
        [[self->_extensions objectForKey:fileID] setHidden:NO];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _files.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleCaption1].pointSize * 3) + 32;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self->_files.count && _canLoadMore) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        
        if([[rows lastObject] row] >= self->_files.count - 5) {
            self->_canLoadMore = NO;
            [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"filecell-%li-%li", (long)indexPath.section, (long)indexPath.row]];
    if(!cell)
        cell = [[FilesTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"filecell-%li-%li", (long)indexPath.section, (long)indexPath.row]];

    NSDictionary *file = [self->_files objectAtIndex:indexPath.row];
    
    cell.date.text = [self->_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[file objectForKey:@"date"] intValue]]];
    cell.name.text = [file objectForKey:@"name"];
    int bytes = [[file objectForKey:@"size"] intValue];
    if(bytes < 1024) {
        cell.metadata.text = [NSString stringWithFormat:@"%i B • %@", bytes, [file objectForKey:@"mime_type"]];
    } else {
        int exp = (int)(log(bytes) / log(1024));
        cell.metadata.text = [NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], [file objectForKey:@"mime_type"]];
    }
    
    NSString *e = [file objectForKey:@"extension"];
    if(!e.length && [[file objectForKey:@"mime_type"] rangeOfString:@"/"].location != NSNotFound)
        e = [[file objectForKey:@"mime_type"] substringFromIndex:[[file objectForKey:@"mime_type"] rangeOfString:@"/"].location + 1];
    if([e hasPrefix:@"."])
        e = [e substringFromIndex:1];
    cell.extension.text = [e uppercaseString];

    if([[file objectForKey:@"mime_type"] hasPrefix:@"image/"]) {
        [self->_spinners setObject:cell.spinner forKey:[file objectForKey:@"id"]];
        [self->_imageViews setObject:cell.thumbnail forKey:[file objectForKey:@"id"]];
        [self->_extensions setObject:cell.extension forKey:[file objectForKey:@"id"]];
        YYImage *image = [[ImageCache sharedInstance] imageForFileID:[file objectForKey:@"id"] width:(self.view.frame.size.width/2) * [UIScreen mainScreen].scale];
        if(image) {
            [cell.thumbnail setImage:image];
            cell.thumbnail.hidden = NO;
            cell.extension.hidden = YES;
            cell.spinner.hidden = YES;
            [cell.spinner stopAnimating];
        } else if(cell.extension.hidden) {
            cell.thumbnail.hidden = YES;
            cell.spinner.hidden = NO;
            if(![cell.spinner isAnimating])
                [cell.spinner startAnimating];
            [[ImageCache sharedInstance] fetchFileID:[file objectForKey:@"id"] width:(self.view.frame.size.width/2) * [UIScreen mainScreen].scale completionHandler:^(BOOL success) {
                [self _refreshFileID:[file objectForKey:@"id"]];
            }];
        }
    } else {
        cell.extension.hidden = NO;
        cell.thumbnail.hidden = YES;
        cell.spinner.hidden = YES;
        [cell.spinner stopAnimating];
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            [[NetworkConnection sharedInstance] deleteFile:[[self->_files objectAtIndex:indexPath.row] objectForKey:@"id"] handler:^(IRCCloudJSONObject *result) {
                if([[result objectForKey:@"success"] boolValue]) {
                    CLS_LOG(@"File deleted successfully");
                } else {
                    CLS_LOG(@"Error deleting file: %@", result);
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to delete file, please try again." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];

                    self->_pages = 0;
                    self->_files = nil;
                    self->_canLoadMore = YES;
                    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
                }
            }];
            NSMutableArray *a = self->_files.mutableCopy;
            [a removeObjectAtIndex:indexPath.row];
            self->_files = [NSArray arrayWithArray:a];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            if(!_files.count) {
                UILabel *fail = [[UILabel alloc] init];
                fail.text = @"\nYou haven't uploaded any files yet.\n";
                fail.numberOfLines = 3;
                fail.textAlignment = NSTextAlignmentCenter;
                fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                [fail sizeToFit];
                self.tableView.tableFooterView = fail;
            }
            [self scrollViewDidScroll:self.tableView];
        }
    }
}

-(void)saveButtonPressed:(id)sender {
    if(self->_delegate)
        [self->_delegate filesTableViewControllerDidSelectFile:self->_selectedFile message:((FileMetadataViewController *)self.navigationController.topViewController).msg.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self->_selectedFile = [self->_files objectAtIndex:indexPath.row];
    if(self->_selectedFile) {
        FileMetadataViewController *c = [[FileMetadataViewController alloc] initWithUploader:nil];
        c.navigationItem.title = @"Share a File";
        c.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonPressed:)];
        [c loadView];
        [c viewDidLoad];
        int bytes = [[self->_selectedFile objectForKey:@"size"] intValue];
        int exp = (int)(log(bytes) / log(1024));
        [c setFilename:[self->_selectedFile objectForKey:@"name"] metadata:[NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], [self->_selectedFile objectForKey:@"mime_type"]]];
        [c setImage:[[ImageCache sharedInstance] imageForFileID:[self->_selectedFile objectForKey:@"id"] width:(self.view.frame.size.width/2) * [UIScreen mainScreen].scale]];
        [c setURL:[[NetworkConnection sharedInstance].fileURITemplate relativeStringWithVariables:self->_selectedFile error:nil]];
        [self.navigationController pushViewController:c animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
