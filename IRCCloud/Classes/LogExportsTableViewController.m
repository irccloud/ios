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

@implementation LogExportsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _downloadingURLs = [[NSMutableDictionary alloc] init];
    self.navigationItem.title = @"Download Logs";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)refresh {
    @synchronized(self) {
        NSDictionary *logs = [[NetworkConnection sharedInstance] getLogExports];
        
        _inprogress = [logs objectForKey:@"inprogress"];
        _available = [logs objectForKey:@"available"];
        _expired = [logs objectForKey:@"expired"];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
        }];
    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16,0,self.view.frame.size.width - 32, 20)];
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
    return 1 + (_inprogress.count > 0) + (_available.count > 0) + (_expired.count > 0);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section > 1 && _available.count == 0)
        section++;
    
    if(section > 0 && _inprogress.count == 0)
        section++;

    switch(section) {
        case 0:
            return 3;
        case 1:
            return _inprogress.count;
        case 2:
            return _available.count;
        case 3:
            return _expired.count;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section > 1 && _available.count == 0)
        section++;
    
    if(section > 0 && _inprogress.count == 0)
        section++;

    switch(section) {
        case 0:
            return @"Export Logs";
        case 1:
            return @"Pending Downloads";
        case 2:
            return @"Available Downloads";
        case 3:
            return @"Expired Downloads";
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return 44;
    else
        return 64;
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
        if((int)seconds == 1)
            date = [NSString stringWithFormat:@"%i second", (int)seconds];
        else
            date = [NSString stringWithFormat:@"%i seconds", (int)seconds];
    }
    return date;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LogExport"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"LogExport"];
    
    cell.accessoryView = nil;
    
    if(indexPath.section == 0) {
        switch(indexPath.row) {
            case 0:
                cell.textLabel.text = @"This Network";
                cell.detailTextLabel.text = _server.name.length ? _server.name : _server.hostname;
                break;
            case 1:
                cell.textLabel.text = @"This Channel";
                cell.detailTextLabel.text = _buffer.name;
                break;
            case 2:
                cell.textLabel.text = @"All Networks";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu networks", (unsigned long)[ServersDataSource sharedInstance].count];
                break;
        }
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        NSInteger section = indexPath.section;
        
        if(section > 1 && _available.count == 0)
            section++;
        
        if(section > 0 && _inprogress.count == 0)
            section++;

        UIActivityIndicatorView *spinner;
        NSDictionary *row = nil;
        switch(section) {
            case 1:
                row = [_inprogress objectAtIndex:indexPath.row];
                cell.accessoryType = UITableViewCellAccessoryNone;
                spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                [spinner sizeToFit];
                [spinner startAnimating];
                cell.accessoryView = spinner;
                break;
            case 2:
                row = [_available objectAtIndex:indexPath.row];
                if([_downloadingURLs objectForKey:[row objectForKey:@"redirect_url"]]) {
                    cell.accessoryType = UITableViewCellAccessoryNone;
                    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                    [spinner sizeToFit];
                    [spinner startAnimating];
                    cell.accessoryView = spinner;
                } else {
                    NSFileManager *fm = [NSFileManager defaultManager];
                    NSURL *docs = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
                    if([fm fileExistsAtPath:[docs URLByAppendingPathComponent:[row objectForKey:@"file_name"]].path])
                        cell.accessoryType = UITableViewCellAccessoryCheckmark;
                    else
                        cell.accessoryType = UITableViewCellAccessoryNone;
                }
                break;
            case 3:
                row = [_expired objectAtIndex:indexPath.row];
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
        }
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

        if([[row objectForKey:@"expirydate"] isKindOfClass:[NSNull class]])
            cell.detailTextLabel.text = [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]];
        else
            cell.detailTextLabel.text = [NSString stringWithFormat:([NSDate date].timeIntervalSince1970 - [[row objectForKey:@"expirydate"] doubleValue] < 0)?@"Exported %@ ago\nExpires in %@":@"Exported %@ ago\nExpired %@ ago", [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"startdate"] doubleValue]], [self relativeTime:[NSDate date].timeIntervalSince1970 - [[row objectForKey:@"expirydate"] doubleValue]]];
        cell.detailTextLabel.numberOfLines = 0;
    }
    
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger section = indexPath.section;
    
    if(section > 1 && _available.count == 0)
        section++;
    
    if(section > 0 && _inprogress.count == 0)
        section++;

    IRCCloudAPIResultHandler exportHandler = ^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] boolValue]) {
            NSMutableArray *inprogress = _inprogress.mutableCopy;
            [inprogress insertObject:[result objectForKey:@"export"] atIndex:0];
            _inprogress = inprogress;
            [self.tableView reloadData];
            [[[UIAlertView alloc] initWithTitle:@"Exporting" message:@"Your log export is in progress.  We'll email you when it's ready." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Export Failed" message:[NSString stringWithFormat:@"Unable to export log: %@.  Please try again shortly.", [result objectForKey:@"message"]] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
        }
    };
    
    switch(section) {
        case 0:
            switch(indexPath.row) {
                case 0:
                    [[NetworkConnection sharedInstance] exportLog:[NSTimeZone localTimeZone].name cid:_server.cid bid:-1 handler:exportHandler];
                    break;
                case 1:
                    [[NetworkConnection sharedInstance] exportLog:[NSTimeZone localTimeZone].name cid:_server.cid bid:_buffer.bid handler:exportHandler];
                    break;
                case 2:
                    [[NetworkConnection sharedInstance] exportLog:[NSTimeZone localTimeZone].name cid:-1 bid:-1 handler:exportHandler];
                    break;
            }
            break;
        case 1:
            [[[UIAlertView alloc] initWithTitle:@"Preparing Download" message:@"This export is being prepared.  You will recieve a notification when it is ready for download." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            break;
        case 2:
            if([[NSFileManager defaultManager] ubiquityIdentityToken]) {
                NSURL *url = [NSURL URLWithString:[[_available objectAtIndex:indexPath.row] objectForKey:@"redirect_url"]];
                [self download:url];
            } else {
                //TODO: add buttons for copy URL and open in Safari
                [[[UIAlertView alloc] initWithTitle:@"iCloud Unavailable" message:@"Downloading logs requires an iCloud account.  Please configure iCloud on your device and try again." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
            }
            break;
    }
}

-(void)download:(NSURL *)url {
    NSURLSession *session;
    NSURLSessionConfiguration *config;
    config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[NSString stringWithFormat:@"com.irccloud.share.image.%li", time(NULL)]];
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

    [_downloadingURLs setObject:@(YES) forKey:url.absoluteString];
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
            alert.alertBody = @"Logs are now available on iCloud Drive";
        }
        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
    }];
}

-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSError *error;
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSURL *dest = [[fm URLForUbiquityContainerIdentifier:nil] URLByAppendingPathComponent:@"Documents"];
    [coordinator coordinateWritingItemAtURL:dest options:0 error:&error byAccessor:^(NSURL *newURL) {
        [fm createDirectoryAtURL:dest withIntermediateDirectories:YES attributes:nil error:NULL];
    }];
    
    dest = [dest URLByAppendingPathComponent:downloadTask.originalRequest.URL.lastPathComponent];
    
    [coordinator coordinateReadingItemAtURL:location options:0 writingItemAtURL:dest options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
        NSError *error;
        [fm removeItemAtPath:newWritingURL.path error:NULL];
        [fm copyItemAtPath:newReadingURL.path toPath:newWritingURL.path error:&error];
        if(error)
            NSLog(@"Error: %@", error);
    }];
    
    [_downloadingURLs removeObjectForKey:downloadTask.originalRequest.URL];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadData];
    }];
}
@end
