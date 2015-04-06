//
//  FilesTableViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 4/6/15.
//  Copyright (c) 2015 IRCCloud, Ltd. All rights reserved.
//

#import "FilesTableViewController.h"
#import "NetworkConnection.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"

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
        _date.textColor = [UIColor grayColor];
        _date.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_date];

        _name = [[UILabel alloc] init];
        _name.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_name];
        
        _metadata = [[UILabel alloc] init];
        _metadata.textColor = [UIColor grayColor];
        _metadata.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_metadata];
        
        _extension = [[UILabel alloc] init];
        _extension.textColor = [UIColor whiteColor];
        _extension.backgroundColor = [UIColor selectedBlueColor];
        _extension.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        _extension.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_extension];

        _thumbnail = [[UIImageView alloc] init];
        _thumbnail.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:_thumbnail];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
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
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    }
    self.navigationItem.title = @"IRCCloud Files";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    _formatter = [[NSDateFormatter alloc] init];
    _formatter.dateStyle = NSDateFormatterLongStyle;
    _formatter.timeStyle = NSDateFormatterMediumStyle;
    _thumbnails = [[NSMutableDictionary alloc] init];
    _thumbQueue = [[NSOperationQueue alloc] init];
    
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    _footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    a.center = _footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [_footerView addSubview:a];
    
    self.tableView.tableFooterView = _footerView;
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _pages = 0;
    _files = nil;
    _canLoadMore = YES;
    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
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
    } else {
        CLS_LOG(@"Failed to load file list for page %i: %@", _pages, d);
        _canLoadMore = NO;
        UILabel *fail = [[UILabel alloc] init];
        fail.text = @"\nUnable to load files.\nPlease try again later.\n";
        fail.numberOfLines = 4;
        fail.textAlignment = NSTextAlignmentCenter;
        fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [fail sizeToFit];
        self.tableView.tableFooterView = fail;
        return;
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
    
    for(NSDictionary *d in _files) {
        NSString *fileID = [d objectForKey:@"id"];
        if(![_thumbnails objectForKey:fileID]) {
            [_thumbQueue addOperationWithBlock:^{
                NSData *data;
                NSURLResponse *response = nil;
                NSError *error = nil;
                
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[[d objectForKey:@"url_template"] stringByReplacingOccurrencesOfString:@":modifiers" withString:@"h128"]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30];
                [request setHTTPShouldHandleCookies:NO];
                
                data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

                @synchronized(_thumbnails) {
                    UIImage *img = [UIImage imageWithData:data];
                    if(img)
                        [_thumbnails setObject:img forKey:fileID];
                }
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                }];
            }];
        }
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
    FilesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"filecell"];
    if(!cell)
        cell = [[FilesTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"filecell"];

    NSDictionary *file = [_files objectAtIndex:indexPath.row];
    
    cell.date.text = [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[file objectForKey:@"date"] intValue]]];
    cell.name.text = [file objectForKey:@"name"];
    int bytes = [[file objectForKey:@"size"] intValue];
    int exp = (int)(log(bytes) / log(1024));
    cell.metadata.text = [NSString stringWithFormat:@"%.1f %cB • %@", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp -1], [file objectForKey:@"mime_type"]];
    
    if([[file objectForKey:@"mime_type"] hasPrefix:@"image/"]) {
        cell.extension.hidden = YES;
        @synchronized(_thumbnails) {
            if([_thumbnails objectForKey:[file objectForKey:@"id"]]) {
                [cell.thumbnail setImage:[_thumbnails objectForKey:[file objectForKey:@"id"]]];
                cell.thumbnail.hidden = NO;
                cell.spinner.hidden = YES;
                [cell.spinner stopAnimating];
            } else {
                cell.thumbnail.hidden = YES;
                cell.spinner.hidden = NO;
                if(![cell.spinner isAnimating])
                    [cell.spinner startAnimating];
            }
        }
    } else {
        cell.extension.hidden = NO;
        cell.thumbnail.hidden = YES;
        cell.spinner.hidden = YES;
        [cell.spinner stopAnimating];
        NSString *e = [file objectForKey:@"extension"];
        if([e hasPrefix:@"."])
            e = [e substringFromIndex:1];
        cell.extension.text = [e uppercaseString];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(_delegate)
        [_delegate filesTableViewControllerDidSelectFile:[_files objectAtIndex:indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
