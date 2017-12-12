//
//  LogExportsTableViewController.h
//
//  Copyright (C) 2017 IRCCloud, Ltd.
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

#import "LogExportsTableViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@interface LogExportsCell : UITableViewCell {
    UIProgressView *_progress;
}

@property (readonly) UIProgressView *progress;
@end

@implementation LogExportsCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _progress = [[UIProgressView alloc] initWithFrame:CGRectZero];
        _progress.tintColor = UITableViewCell.appearance.detailTextLabelColor;
        _progress.trackTintColor = UITableViewCell.appearance.backgroundColor;
        [self.contentView addSubview:_progress];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    [_progress sizeToFit];
    CGRect frame = _progress.frame;
    frame.origin.x = 0;
    frame.origin.y = self.contentView.bounds.size.height - frame.size.height;
    frame.size.width = self.contentView.bounds.size.width;
    _progress.frame = frame;
}
@end

@implementation LogExportsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _fileSizes = [[NSMutableDictionary alloc] init];
    _downloadingURLs = [[NSMutableDictionary alloc] init];
    _iCloudLogs = [[UISwitch alloc] init];
    _pendingExport = -1;
    [_iCloudLogs addTarget:self action:@selector(iCloudLogsChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.title = @"Download Logs";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)iCloudLogsChanged:(id)sender {
    BOOL on = _iCloudLogs.on;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(self) {
            [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"iCloudLogs"];
            
            NSFileManager *fm = [NSFileManager defaultManager];
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
            NSURL *iCloudPath = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
            NSURL *localPath = [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
            
            NSURL *source,*dest;
            
            if(on) {
                source = localPath;
                dest = iCloudPath;
            } else {
                source = iCloudPath;
                dest = localPath;
            }
            
            for(NSURL *file in [fm contentsOfDirectoryAtURL:source includingPropertiesForKeys:nil options:0 error:nil]) {
                [coordinator coordinateReadingItemAtURL:file options:0 writingItemAtURL:[dest URLByAppendingPathComponent:file.lastPathComponent] options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                    CLS_LOG(@"Moving %@ to %@", newReadingURL, newWritingURL);
                    NSError *error;
                    [fm removeItemAtURL:[dest URLByAppendingPathComponent:file.lastPathComponent] error:nil];
                    [fm setUbiquitous:on itemAtURL:newReadingURL destinationURL:newWritingURL error:&error];
                    if(error)
                        CLS_LOG(@"Error moving file: %@", error);
                }];
            }
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)documentInteractionControllerWillPresentOpenInMenu:(UIDocumentInteractionController *)controller {
    [UIColor clearTheme];
}

-(void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller {
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
}

-(void)cacheFileSize:(NSDictionary *)d {
    NSUInteger bytes = [[[[NSFileManager defaultManager] attributesOfItemAtPath:[[self downloadsPath] URLByAppendingPathComponent:[d objectForKey:@"file_name"]].path error:nil] objectForKey:NSFileSize] intValue];
    if(bytes < 1024) {
        [_fileSizes setObject:[NSString stringWithFormat:@"%li B", (long)bytes] forKey:[d objectForKey:@"file_name"]];
    } else {
        int exp = (int)(log(bytes) / log(1024));
        [_fileSizes setObject:[NSString stringWithFormat:@"%.1f %cB", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp-1]] forKey:[d objectForKey:@"file_name"]];
    }
}

-(void)refresh:(NSDictionary *)logs {
    _inprogress = [logs objectForKey:@"inprogress"];
    NSMutableArray *available = [[logs objectForKey:@"available"] mutableCopy];
    NSMutableArray *expired = [[logs objectForKey:@"expired"] mutableCopy];
    NSMutableArray *downloaded = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < available.count; i++) {
        NSDictionary *d = [available objectAtIndex:i];
        if([self downloadExists:d]) {
            [self cacheFileSize:d];
            [downloaded addObject:d];
            [available removeObject:d];
            i--;
        }
    }
    
    for(int i = 0; i < expired.count; i++) {
        NSDictionary *d = [expired objectAtIndex:i];
        if([self downloadExists:d]) {
            [self cacheFileSize:d];
            [downloaded addObject:d];
            [expired removeObject:d];
            i--;
        }
    }
    
    @synchronized (self.tableView) {
        _available = available;
        _downloaded = downloaded;
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }
}

-(void)refresh {
    @synchronized(self.tableView) {
        NSMutableDictionary *logs = [[NetworkConnection sharedInstance] getLogExports].mutableCopy;
        [logs removeObjectForKey:@"timezones"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:logs] forKey:@"logs_cache"];
        
        [self refresh:logs];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [super viewWillAppear:animated];
    _iCloudLogs.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudLogs"];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"logs_cache"])
        [self refresh:[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"logs_cache"]]];
    [self performSelectorInBackground:@selector(refresh) withObject:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    
    switch(event) {
        case kIRCEventLogExportFinished:
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source

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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    @synchronized (self.tableView) {
        return 1 + (_inprogress.count > 0) + (_downloaded.count > 0) + (_available.count > 0);
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    @synchronized (self.tableView) {
        if(section > 0 && _inprogress.count == 0)
            section++;
        
        if(section > 1 && _downloaded.count == 0)
            section++;

        if(section > 2 && _available.count == 0)
            section++;
        
        switch(section) {
            case 0:
                return [[NSFileManager defaultManager] ubiquityIdentityToken]?4:3;
            case 1:
                return _inprogress.count;
            case 2:
                return _downloaded.count;
            case 3:
                return _available.count;
        }
        return 0;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    @synchronized (self.tableView) {
        if(section > 0 && _inprogress.count == 0)
            section++;
        
        if(section > 1 && _downloaded.count == 0)
            section++;

        if(section > 2 && _available.count == 0)
            section++;
        
        switch(section) {
            case 0:
                return @"Export Logs";
            case 1:
                return @"Pending";
            case 2:
                return @"Downloaded";
            case 3:
                return @"Available";
        }
        return nil;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self.tableView) {
        if(indexPath.section == 0)
            return 44;
        else
            return 64;
    }
}

- (NSString *)relativeTime:(double)seconds {
    NSString *date = nil;
    seconds = fabs(seconds);
    double minutes = fabs(seconds) / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / 31.0;
    double years = months / 12.0;
    
    if(years >= 1) {
        if(years - (int)years > 0.5)
            years++;
        
        if((int)years == 1)
            date = [NSString stringWithFormat:@"%i year", (int)years];
        else
            date = [NSString stringWithFormat:@"%i years", (int)years];
    } else if(months >= 1) {
        if(months - (int)months > 0.5)
            months++;
        
        if((int)months == 1)
            date = [NSString stringWithFormat:@"%i month", (int)months];
        else
            date = [NSString stringWithFormat:@"%i months", (int)months];
    } else if(days >= 1) {
        if(days - (int)days > 0.5)
            days++;
        
        if((int)days == 1)
            date = [NSString stringWithFormat:@"%i day", (int)days];
        else
            date = [NSString stringWithFormat:@"%i days", (int)days];
    } else if(hours >= 1) {
        if(hours - (int)hours > 0.5)
            hours++;
        
        if((int)hours < 2)
            date = [NSString stringWithFormat:@"%i hour", (int)hours];
        else
            date = [NSString stringWithFormat:@"%i hours", (int)hours];
    } else if(minutes >= 1) {
        if(minutes - (int)minutes > 0.5)
            minutes++;
        
        if((int)minutes == 1)
            date = [NSString stringWithFormat:@"%i minute", (int)minutes];
        else
            date = [NSString stringWithFormat:@"%i minutes", (int)minutes];
    } else {
        date = @"less than a minute";
    }
    return date;
}

- (BOOL)downloadExists:(NSDictionary *)row {
    if([row objectForKey:@"file_name"] && ![[row objectForKey:@"file_name"] isKindOfClass:[NSNull class]]) {
        return ([[NSFileManager defaultManager] fileExistsAtPath:[[self downloadsPath] URLByAppendingPathComponent:[row objectForKey:@"file_name"]].path]);
    } else {
        return NO;
    }
}

- (NSURL *)fileForDownload:(NSDictionary *)row {
    return [[self downloadsPath] URLByAppendingPathComponent:[row objectForKey:@"file_name"]];
}

- (NSURL *)downloadsPath {
    NSFileManager *fm = [NSFileManager defaultManager];
    if([fm ubiquityIdentityToken] && [[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudLogs"])
        return [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
    else
        return [[fm URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self.tableView) {
        UIActivityIndicatorView *spinner;
        LogExportsCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogExport"];
        if(!cell)
            cell = [[LogExportsCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LogExport"];
        
        cell.accessoryView = nil;
        cell.progress.hidden = YES;
        
        if(indexPath.section == 0) {
            switch(indexPath.row) {
                case 0:
                    cell.textLabel.text = @"This Network";
                    cell.detailTextLabel.text = _server.name.length ? _server.name : _server.hostname;
                    break;
                case 1:
                    if([_buffer.type isEqualToString:@"channel"])
                        cell.textLabel.text = @"This Channel";
                    else if([_buffer.type isEqualToString:@"console"])
                        cell.textLabel.text = @"This Network Console";
                    else
                        cell.textLabel.text = @"This Conversation";
                    if([_buffer.type isEqualToString:@"console"])
                        cell.detailTextLabel.text = _server.name.length ? _server.name : _server.hostname;
                    else
                        cell.detailTextLabel.text = _buffer.name;
                    break;
                case 2:
                    cell.textLabel.text = @"All Networks";
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu networks", (unsigned long)[ServersDataSource sharedInstance].count];
                    break;
                case 3:
                    cell.textLabel.text = @"iCloud Drive Sync";
                    cell.detailTextLabel.text = nil;
                    cell.accessoryView = _iCloudLogs;
                    break;
            }
            if(_pendingExport == indexPath.row) {
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                [spinner sizeToFit];
                [spinner startAnimating];
                cell.accessoryView = spinner;
            } else {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else {
            NSInteger section = indexPath.section;
            
            if(section > 0 && _inprogress.count == 0)
                section++;
            
            if(section > 1 && _downloaded.count == 0)
                section++;

            if(section > 2 && _available.count == 0)
                section++;
            
            NSDictionary *row = nil;
            switch(section) {
                case 1:
                    if(indexPath.row < _inprogress.count) {
                        row = [_inprogress objectAtIndex:indexPath.row];
                    }
                    break;
                case 2:
                    if(indexPath.row < _downloaded.count) {
                        row = [_downloaded objectAtIndex:indexPath.row];
                    }
                    break;
                case 3:
                    if(indexPath.row < _available.count) {
                        row = [_available objectAtIndex:indexPath.row];
                    }
                    break;
            }
            
            if(row) {
                Server *s = ![[row objectForKey:@"cid"] isKindOfClass:[NSNull class]] ? [[ServersDataSource sharedInstance] getServer:[[row objectForKey:@"cid"] intValue]] : nil;
                Buffer *b = ![[row objectForKey:@"bid"] isKindOfClass:[NSNull class]] ? [[BuffersDataSource sharedInstance] getBuffer:[[row objectForKey:@"bid"] intValue]] : nil;
                
                NSString *serverName = s ? (s.name.length ? s.name : s.hostname) : [NSString stringWithFormat:@"Unknown Network (%@)", [row objectForKey:@"cid"]];
                NSString *bufferName = b ? b.name : [NSString stringWithFormat:@"Unknown Log (%@)", [row objectForKey:@"bid"]];
                
                if(![[row objectForKey:@"bid"] isKindOfClass:[NSNull class]])
                    cell.textLabel.text = [NSString stringWithFormat:@"%@: %@", serverName, bufferName];
                else if(![[row objectForKey:@"cid"] isKindOfClass:[NSNull class]])
                    cell.textLabel.text = serverName;
                else
                    cell.textLabel.text = @"All Networks";

                if(section > 1) {
                    if(section == 2 || [[row objectForKey:@"expirydate"] isKindOfClass:[NSNull class]]) {
                        if([_fileSizes objectForKey:[row objectForKey:@"file_name"]])
                            cell.detailTextLabel.text = [NSString stringWithFormat:@"Exported %@ ago\n%@", [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]], [_fileSizes objectForKey:[row objectForKey:@"file_name"]]];
                        else
                            cell.detailTextLabel.text = [NSString stringWithFormat:@"Exported %@ ago", [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]]];
                    } else {
                        cell.detailTextLabel.text = [NSString stringWithFormat:([NSDate date].timeIntervalSince1970 - [[row objectForKey:@"expirydate"] doubleValue] < 0)?@"Exported %@ ago\nExpires in %@":@"Exported %@ ago\nExpired %@ ago", [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]], [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"expirydate"] doubleValue]]];
                    }
                } else {
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"Started %@ ago", [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]]];
                }
                cell.detailTextLabel.numberOfLines = 0;
                
                if(section == 1 || [_downloadingURLs objectForKey:[row objectForKey:@"redirect_url"]]) {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    [cell.progress setProgress:[[_downloadingURLs objectForKey:[row objectForKey:@"redirect_url"]] floatValue] animated:YES];
                    if(cell.progress.progress > 0) {
                        cell.progress.hidden = NO;
                    } else {
                        spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                        [spinner sizeToFit];
                        [spinner startAnimating];
                        cell.accessoryView = spinner;
                    }
                } else {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            } else {
                CLS_LOG(@"Requested row %li not found for section %li, reloading table", (long)indexPath.row, (long)indexPath.section);
                [self.tableView reloadData];
            }
        }
        
        return cell;
    }
}

#pragma mark - Table view delegate

-(void)requestExport:(int)cid bid:(int)bid {
    for(NSDictionary *d in _inprogress) {
        int e_cid = -1;
        int e_bid = -1;
        if(![[d objectForKey:@"cid"] isKindOfClass:[NSNull class]])
            e_cid = [[d objectForKey:@"cid"] intValue];
        if(![[d objectForKey:@"bid"] isKindOfClass:[NSNull class]])
            e_bid = [[d objectForKey:@"bid"] intValue];
        
        if(cid == e_cid && bid == e_bid) {
            [[[UIAlertView alloc] initWithTitle:@"Export In Progress" message:@"This export is already in progress.  We'll email you when it's ready." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            _pendingExport = -1;
            return;
        }
    }
    
    [[NetworkConnection sharedInstance] exportLog:[NSTimeZone localTimeZone].name cid:cid bid:bid handler:^(IRCCloudJSONObject *result) {
        @synchronized (self.tableView) {
            if([[result objectForKey:@"success"] boolValue]) {
                NSMutableArray *inprogress = _inprogress.mutableCopy;
                [inprogress insertObject:[result objectForKey:@"export"] atIndex:0];
                _inprogress = inprogress;
                [[[UIAlertView alloc] initWithTitle:@"Exporting" message:@"Your log export is in progress.  We'll email you when it's ready." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Export Failed" message:[NSString stringWithFormat:@"Unable to export log: %@.  Please try again shortly.", [result objectForKey:@"message"]] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            }
            _pendingExport = -1;
            [self.tableView reloadData];
        }
    }];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized (self.tableView) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        
        NSInteger section = indexPath.section;
        
        if(section > 0 && _inprogress.count == 0)
            section++;
        
        if(section > 1 && _downloaded.count == 0)
            section++;
        
        if(section > 2 && _available.count == 0)
            section++;
        
        switch(section) {
            case 0:
                if(indexPath.row < 3) {
                    if(_pendingExport != -1)
                        break;
                    _pendingExport = indexPath.row;
                    [self.tableView reloadData];
                }
                switch(indexPath.row) {
                    case 0:
                        [self requestExport:_server.cid bid:-1];
                        break;
                    case 1:
                        [self requestExport:_server.cid bid:_buffer.bid];
                        break;
                    case 2:
                        [self requestExport:-1 bid:-1];
                        break;
                }
                break;
            case 1:
                [[[UIAlertView alloc] initWithTitle:@"Preparing Download" message:@"This export is being prepared.  You will recieve a notification when it is ready for download." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
                break;
            case 2:
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                NSURL *file = [self fileForDownload:[_downloaded objectAtIndex:indexPath.row]];
                NSURL *url = [[_downloaded objectAtIndex:indexPath.row] objectForKey:@"redirect_url"];
                [alert addAction:[UIAlertAction actionWithTitle:@"Open" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        _interactionController = [UIDocumentInteractionController interactionControllerWithURL:file];
                        _interactionController.delegate = self;
                        [_interactionController presentOpenInMenuFromRect:[self.view convertRect:[self.tableView rectForRowAtIndexPath:indexPath] fromView:self.tableView] inView:self.view animated:YES];
                    }];
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Download" message:[[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudLogs"]?@"Are you sure you want to delete this download?  It will be removed from your device and all other devices that are syncing with iCloud Drive.":@"Are you sure you want to delete this download from your device?" preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                        [_downloadingURLs setObject:@(0) forKey:url];
                        [self.tableView reloadData];
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
                            [coordinator coordinateWritingItemAtURL:file options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *writingURL) {
                                NSError *error;
                                [[NSFileManager defaultManager] removeItemAtPath:writingURL.path error:NULL];
                                if(error)
                                    NSLog(@"Error: %@", error);
                                [self refresh:[NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"logs_cache"]]];
                                [_downloadingURLs removeObjectForKey:url];
                                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
                                [self refresh];
                            }];
                        });
                    }]];
                    
                    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                    alert.popoverPresentationController.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
                    alert.popoverPresentationController.sourceView = self.tableView;
                    [self presentViewController:alert animated:YES completion:nil];
                }]];

                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                alert.popoverPresentationController.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
                alert.popoverPresentationController.sourceView = self.tableView;
                [self presentViewController:alert animated:YES completion:nil];
                break;
            }
            case 3:
                [self download:[NSURL URLWithString:[[_available objectAtIndex:indexPath.row] objectForKey:@"redirect_url"]]];
                break;
        }
    }
}

-(void)download:(NSURL *)url {
    if([_downloadingURLs objectForKey:url.absoluteString]) {
        CLS_LOG(@"Ignoring duplicate download request for %@", url);
        return;
    }
    NSURLSession *session;
    NSURLSessionConfiguration *config;
    config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.logs.%li", time(NULL)]];
#ifdef ENTERPRISE
    config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
    config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
    config.HTTPCookieStorage = nil;
    config.URLCache = nil;
    config.requestCachePolicy = NSURLCacheStorageNotAllowed;
    config.discretionary = NO;
    session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:[NSString stringWithFormat:@"session=%@",[NetworkConnection sharedInstance].session] forHTTPHeaderField:@"Cookie"];
    
    [[session downloadTaskWithRequest:request] resume];

    @synchronized (self.tableView) {
        [_downloadingURLs setObject:@(0) forKey:url.absoluteString];
    }
    [self.tableView reloadData];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    [_downloadingURLs setObject:@((float)totalBytesWritten / (float)totalBytesExpectedToWrite) forKey:downloadTask.originalRequest.URL.absoluteString];
    [self.tableView reloadData];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [_downloadingURLs removeObjectForKey:task.originalRequest.URL.absoluteString];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
        UILocalNotification *alert = [[UILocalNotification alloc] init];
        alert.fireDate = [NSDate date];
        alert.soundName = @"a.caf";
        if(error) {
            alert.alertTitle = @"Download Failed";
            alert.alertBody = [NSString stringWithFormat:@"Unable to download logs: %@", error.description];
        } else {
            alert.alertTitle = @"Download Complete";
            alert.alertBody = @"Logs are now available";
            alert.category = @"view_logs";
            alert.userInfo = @{@"view_logs":@(YES)};
        }
        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
        if(self.completionHandler)
            self.completionHandler();
    }];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *dest = [self downloadsPath];
    [coordinator coordinateWritingItemAtURL:dest options:0 error:&error byAccessor:^(NSURL *newURL) {
        [fm createDirectoryAtURL:dest withIntermediateDirectories:YES attributes:nil error:NULL];
    }];
    
    dest = [dest URLByAppendingPathComponent:downloadTask.originalRequest.URL.lastPathComponent];
    
    [coordinator coordinateReadingItemAtURL:location options:0 writingItemAtURL:dest options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        NSError *error;
        [fm removeItemAtPath:newWritingURL.path error:NULL];
        [fm copyItemAtPath:newReadingURL.path toPath:newWritingURL.path error:&error];
        NSUInteger bytes = [[[[NSFileManager defaultManager] attributesOfItemAtPath:newWritingURL.path error:nil] objectForKey:NSFileSize] intValue];
        if(bytes < 1024) {
            [_fileSizes setObject:[NSString stringWithFormat:@"%li B", (long)bytes] forKey:downloadTask.originalRequest.URL.lastPathComponent];
        } else {
            int exp = (int)(log(bytes) / log(1024));
            [_fileSizes setObject:[NSString stringWithFormat:@"%.1f %cB", bytes / pow(1024, exp), [@"KMGTPE" characterAtIndex:exp-1]] forKey:downloadTask.originalRequest.URL.lastPathComponent];
        }
        if(error)
            NSLog(@"Error: %@", error);
    }];
    
    [_downloadingURLs removeObjectForKey:downloadTask.originalRequest.URL];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        @synchronized (self.tableView) {
            NSMutableArray *available = _available.mutableCopy;
            
            for(int i = 0; i < available.count; i++) {
                if([[[available objectAtIndex:i] objectForKey:@"redirect_url"] isEqualToString:downloadTask.originalRequest.URL.absoluteString]) {
                    [_downloaded addObject:[available objectAtIndex:i]];
                    [available removeObjectAtIndex:i];
                    break;
                }
            }
            
            _available = available;
        }
        [self.tableView reloadData];
        if(self.completionHandler)
            self.completionHandler();
    }];
}
@end
