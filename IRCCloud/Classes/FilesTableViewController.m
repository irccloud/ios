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

@implementation ImageFetcher

-(id)initWithURL:(NSString *)URL fileID:(NSString *)fileID {
    self = [super init];
    if(self) {
        _url = URL;
        _fileID = fileID;
        _cancelled = NO;
        _running = NO;
    }
    return self;
}
-(void)cancel {
    _cancelled = YES;
    [_connection cancel];
}
-(void)start {
    if(_cancelled || _running)
        return;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if(_connection) {
        _data = [[NSMutableData alloc] init];
        _running = YES;
    } else {
        CLS_LOG(@"ImageFetcher failed to create NSURLConnection");
    }
}
- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(_cancelled)
        return;
    CLS_LOG(@"ImageFetcher request failed: %@", error);
    _running = NO;
    _cancelled = YES;
    [_delegate imageFetcherDidFail:self];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(_cancelled)
        return;
    _running = NO;
    [_delegate imageFetcher:self downloadedImage:_data];
}
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if(_cancelled)
        return nil;
    return request;
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    if([response statusCode] != 200) {
        CLS_LOG(@"ImageFetcher HTTP status code: %li", (long)[response statusCode]);
        CLS_LOG(@"ImageFetcher HTTP headers: %@", [response allHeaderFields]);
        _cancelled = YES;
        [_delegate imageFetcherDidFail:self];
    }
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_data appendData:data];
}

@end

@interface FilesTableCell : UITableViewCell {
    UILabel *_date;
    UILabel *_name;
    UILabel *_metadata;
    UILabel *_extension;
    UIImageView *_thumbnail;
    UIActivityIndicatorView *_spinner;
}
@property (readonly) UILabel *date,*name,*metadata,*extension;
@property (readonly) UIImageView *thumbnail;
@property (readonly) UIActivityIndicatorView *spinner;
@end

@implementation FilesTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _date = [[UILabel alloc] init];
        _date.textColor = [UITableViewCell appearance].detailTextLabelColor;
        _date.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_date];

        _name = [[UILabel alloc] init];
        _name.textColor = [UITableViewCell appearance].textLabelColor;
        _name.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_name];
        
        _metadata = [[UILabel alloc] init];
        _metadata.textColor = [UITableViewCell appearance].detailTextLabelColor;
        _metadata.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_metadata];
        
        _extension = [[UILabel alloc] init];
        _extension.textColor = [UIColor whiteColor];
        _extension.backgroundColor = [UIColor unreadBlueColor];
        _extension.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        _extension.textAlignment = NSTextAlignmentCenter;
        _extension.hidden = YES;
        [self.contentView addSubview:_extension];

        _thumbnail = [[UIImageView alloc] init];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_thumbnail];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [self.contentView addSubview:_spinner];
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
    
    _extension.frame = _spinner.frame = _thumbnail.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
    _date.frame = CGRectMake(frame.origin.x + 64, frame.origin.y, frame.size.width - 64, frame.size.height / 3);
    _name.frame = CGRectMake(frame.origin.x + 64, _date.frame.origin.y + _date.frame.size.height, frame.size.width - 64, frame.size.height / 3);
    _metadata.frame = CGRectMake(frame.origin.x + 64, _name.frame.origin.y + _name.frame.size.height, frame.size.width - 64, frame.size.height / 3);
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
    self.navigationItem.title = @"File Uploads";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    _url_template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"file_uri_template"] error:nil];
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateStyle = NSDateFormatterLongStyle;
    _formatter.timeStyle = NSDateFormatterMediumStyle;
    _thumbnails = [[NSMutableDictionary alloc] init];
    _imageViews = [[NSMutableDictionary alloc] init];
    _spinners = [[NSMutableDictionary alloc] init];
    _extensions = [[NSMutableDictionary alloc] init];
    _imageFetchers = [[NSMutableDictionary alloc] init];
    
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    _footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    a.center = _footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [_footerView addSubview:a];
    
    self.tableView.tableFooterView = _footerView;
    _pages = 0;
    _files = nil;
    _canLoadMore = YES;
    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
}

-(void)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:self.tableView.isEditing?UIBarButtonSystemItemCancel:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    _files = nil;
    _canLoadMore = NO;
    [_imageFetchers.allValues makeObjectsPerformSelector:@selector(cancel)];
    [_imageFetchers removeAllObjects];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                CLS_LOG(@"Error deleting file: %@", o);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to delete file, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                _pages = 0;
                _files = nil;
                _canLoadMore = YES;
                [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid)
                CLS_LOG(@"File deleted successfully");
            break;
        default:
            break;
    }
}

-(void)_loadMore {
    NSDictionary *d = [[NetworkConnection sharedInstance] getFiles:++_pages];
    if([[d objectForKey:@"success"] boolValue]) {
        CLS_LOG(@"Loaded file list for page %i", _pages);
        if(_files)
            _files = [_files arrayByAddingObjectsFromArray:[d objectForKey:@"files"]];
        else
            _files = [d objectForKey:@"files"];
        
        _canLoadMore = _files.count < [[d objectForKey:@"total"] intValue];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.tableView.tableFooterView = _canLoadMore?_footerView:nil;
            if(!_files.count) {
                CLS_LOG(@"File list is empty");
                UILabel *fail = [[UILabel alloc] init];
                fail.text = @"\nYou haven't uploaded any files yet.\n";
                fail.numberOfLines = 3;
                fail.textAlignment = NSTextAlignmentCenter;
                fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                [fail sizeToFit];
                self.tableView.tableFooterView = fail;
            }
        }];
    } else {
        CLS_LOG(@"Failed to load file list for page %i: %@", _pages, d);
        _canLoadMore = NO;
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nUnable to load files.\nPlease try again later.\n";
            fail.numberOfLines = 4;
            fail.textAlignment = NSTextAlignmentCenter;
            fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [fail sizeToFit];
            self.tableView.tableFooterView = fail;
        }];
        return;
    }

    for(NSDictionary *d in _files) {
        NSString *fileID = [d objectForKey:@"id"];
        if(![_thumbnails objectForKey:fileID]) {
            NSString *url = [_url_template relativeStringWithVariables:@{@"id":fileID, @"modifiers":[NSString stringWithFormat:@"w%.f", self.view.frame.size.width]} error:nil];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                ImageFetcher *i = [[ImageFetcher alloc] initWithURL:url fileID:fileID];
                i.delegate = self;
                [_imageFetchers setObject:i forKey:fileID];
                [i start];
            }];
        }
    }
    
    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

-(void)imageFetcher:(ImageFetcher *)imageFetcher downloadedImage:(NSData *)data {
    UIImage *img = [UIImage imageWithData:data];
    if(img)
        [_thumbnails setObject:img forKey:imageFetcher.fileID];

    [self _refreshFileID:imageFetcher.fileID];
    [_imageFetchers removeObjectForKey:imageFetcher.fileID];
}

-(void)imageFetcherDidFail:(ImageFetcher *)imageFetcher {
    [self _refreshFileID:imageFetcher.fileID];
    [_imageFetchers removeObjectForKey:imageFetcher.fileID];
}

-(void)_refreshFileID:(NSString *)fileID {
    [[_spinners objectForKey:fileID] stopAnimating];
    [[_spinners objectForKey:fileID] setHidden:YES];
    if([_thumbnails objectForKey:fileID]) {
        [[_imageViews objectForKey:fileID] setImage:[_thumbnails objectForKey:fileID]];
        [[_imageViews objectForKey:fileID] setHidden:NO];
        [[_extensions objectForKey:fileID] setHidden:YES];
    } else {
        [[_extensions objectForKey:fileID] setHidden:NO];
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
    return 64;
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_files.count && _canLoadMore) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        
        if([[rows lastObject] row] >= _files.count - 5) {
            _canLoadMore = NO;
            [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FilesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"filecell-%li-%li", (long)indexPath.section, (long)indexPath.row]];
    if(!cell)
        cell = [[FilesTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"filecell-%li-%li", (long)indexPath.section, (long)indexPath.row]];

    NSDictionary *file = [_files objectAtIndex:indexPath.row];
    
    cell.date.text = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[file objectForKey:@"date"] intValue]]];
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
        e = [[file objectForKey:@"mime_type"] substringFromIndex:[[file objectForKey:@"mime_type"] rangeOfString:@"/"].location];
    if([e hasPrefix:@"."])
        e = [e substringFromIndex:1];
    cell.extension.text = [e uppercaseString];

    if([[file objectForKey:@"mime_type"] hasPrefix:@"image/"]) {
        [_spinners setObject:cell.spinner forKey:[file objectForKey:@"id"]];
        [_imageViews setObject:cell.thumbnail forKey:[file objectForKey:@"id"]];
        [_extensions setObject:cell.extension forKey:[file objectForKey:@"id"]];
        if([_thumbnails objectForKey:[file objectForKey:@"id"]]) {
            [cell.thumbnail setImage:[_thumbnails objectForKey:[file objectForKey:@"id"]]];
            cell.thumbnail.hidden = NO;
            cell.extension.hidden = YES;
            cell.spinner.hidden = YES;
            [cell.spinner stopAnimating];
        } else if(cell.extension.hidden) {
            cell.thumbnail.hidden = YES;
            cell.spinner.hidden = NO;
            if(![cell.spinner isAnimating])
                [cell.spinner startAnimating];
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
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _reqid = [[NetworkConnection sharedInstance] deleteFile:[[_files objectAtIndex:indexPath.row] objectForKey:@"id"]];
        [_thumbnails removeObjectForKey:[[_files objectAtIndex:indexPath.row] objectForKey:@"id"]];
        NSMutableArray *a = _files.mutableCopy;
        [a removeObjectAtIndex:indexPath.row];
        _files = [NSArray arrayWithArray:a];
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

-(void)saveButtonPressed:(id)sender {
    if(_delegate)
        [_delegate filesTableViewControllerDidSelectFile:_selectedFile message:((FileMetadataViewController *)self.navigationController.topViewController).msg.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedFile = [_files objectAtIndex:indexPath.row];
    if(_selectedFile) {
        FileMetadataViewController *c = [[FileMetadataViewController alloc] initWithUploader:nil];
        c.navigationItem.title = @"Share a File";
        c.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(saveButtonPressed:)];
        [c loadView];
        [c viewDidLoad];
        int bytes = [[_selectedFile objectForKey:@"size"] intValue];
        int exp = (int)(log(bytes) / log(1024));
        [c setFilename:[_selectedFile objectForKey:@"name"] metadata:[NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], [_selectedFile objectForKey:@"mime_type"]]];
        [c setImage:[_thumbnails objectForKey:[_selectedFile objectForKey:@"id"]]];
        [c setURL:[_url_template relativeStringWithVariables:_selectedFile error:nil]];
        [self.navigationController pushViewController:c animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
