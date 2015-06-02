//
//  PastebinsTableViewController.m
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

#import "PastebinsTableViewController.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"
#import "PastebinViewController.h"

#define MAX_LINES 12

@interface InsetLabel : UILabel
@end

@implementation InsetLabel

- (void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:CGRectInset(rect, 4, 0)];
}

@end

@interface PastebinsTableCell : UITableViewCell {
    InsetLabel *_metadata;
    InsetLabel *_text;
    UIView *_border;
}
@property (readonly) InsetLabel *metadata,*text;
@end

@implementation PastebinsTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _border = [[UIView alloc] init];
        _border.backgroundColor = [UIColor blueBorderColor];
        [self.contentView addSubview:_border];
        
        _metadata = [[InsetLabel alloc] init];
        _metadata.backgroundColor = [UIColor navBarColor];
        _metadata.textColor = [UIColor grayColor];
        _metadata.font = [UIFont systemFontOfSize:FONT_SIZE];
        [self.contentView addSubview:_metadata];
        
        _text = [[InsetLabel alloc] init];
        _text.backgroundColor = [UIColor whiteColor];
        _text.textColor = [UIColor blackColor];
        _text.font = [UIFont systemFontOfSize:FONT_SIZE];
        _text.lineBreakMode = NSLineBreakByTruncatingTail;
        _text.numberOfLines = 0;
        [self.contentView addSubview:_text];
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
    
    _border.frame = CGRectMake(frame.origin.x - 1, frame.origin.y - 1, frame.size.width + 2, frame.size.height + 2);
    _metadata.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, FONT_SIZE + 6);
    _text.frame = CGRectMake(frame.origin.x, _metadata.frame.origin.y + _metadata.frame.size.height + 1, frame.size.width, frame.size.height - _metadata.frame.size.height - 1);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation PastebinsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    }
    self.navigationItem.title = @"Your Pastebins";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    _url_template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"pastebin_uri_template"] error:nil];
    
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    _footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    a.center = _footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [_footerView addSubview:a];
    
    self.tableView.tableFooterView = _footerView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _pages = 0;
    _pastes = nil;
    _canLoadMore = YES;
    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    _pastes = nil;
    _canLoadMore = NO;
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
                CLS_LOG(@"Error deleting pastebin: %@", o);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to delete pastebin, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                _pages = 0;
                _pastes = nil;
                _canLoadMore = YES;
                [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid)
                CLS_LOG(@"Pastebin deleted successfully");
            break;
        default:
            break;
    }
}

-(void)_loadMore {
    NSDictionary *d = [[NetworkConnection sharedInstance] getPastebins:++_pages];
    if([[d objectForKey:@"success"] boolValue]) {
        CLS_LOG(@"Loaded pastebin list for page %i", _pages);
        if(_pastes)
            _pastes = [_pastes arrayByAddingObjectsFromArray:[d objectForKey:@"pastebins"]];
        else
            _pastes = [d objectForKey:@"pastebins"];
        
        _canLoadMore = _pastes.count < [[d objectForKey:@"total"] intValue];
        self.tableView.tableFooterView = _canLoadMore?_footerView:nil;
        if(!_pastes.count) {
            CLS_LOG(@"Pastebin list is empty");
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nYou haven't created any pastebins yet.\n";
            fail.numberOfLines = 3;
            fail.textAlignment = NSTextAlignmentCenter;
            fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [fail sizeToFit];
            self.tableView.tableFooterView = fail;
        }
    } else {
        CLS_LOG(@"Failed to load pastebin list for page %i: %@", _pages, d);
        _canLoadMore = NO;
        UILabel *fail = [[UILabel alloc] init];
        fail.text = @"\nUnable to load pastebins.\nPlease try again later.\n";
        fail.numberOfLines = 4;
        fail.textAlignment = NSTextAlignmentCenter;
        fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [fail sizeToFit];
        self.tableView.tableFooterView = fail;
        return;
    }

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
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
    return _pastes.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FONT_SIZE + 20 + ([[[_pastes objectAtIndex:indexPath.row] objectForKey:@"body"] sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:CGRectMake(0,0,self.tableView.frame.size.width - 16,(FONT_SIZE + 4) * MAX_LINES).size lineBreakMode:NSLineBreakByTruncatingTail].height);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_pastes.count && _canLoadMore) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        
        if([[rows lastObject] row] >= _pastes.count - 5) {
            _canLoadMore = NO;
            [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PastebinsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"pastebincell-%li-%li", (long)indexPath.section, (long)indexPath.row]];
    if(!cell)
        cell = [[PastebinsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[NSString stringWithFormat:@"pastebincell-%li-%li", (long)indexPath.section, (long)indexPath.row]];

    NSDictionary *pastebin = [_pastes objectAtIndex:indexPath.row];
    
    NSString *metadata = @"";
    
    if([[pastebin objectForKey:@"name"] length])
        metadata = [[pastebin objectForKey:@"name"] stringByAppendingString:@" • "];
    
    metadata = [metadata stringByAppendingFormat:@"%@ lines • ", [pastebin objectForKey:@"lines"]];
    double seconds = [[NSDate date] timeIntervalSince1970] - [[pastebin objectForKey:@"date"] doubleValue];
    double minutes = seconds / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / 31.0;
    double years = months / 12.0;
    
    if(years >= 1) {
        if(years - (int)years > 0.5)
            years++;
        
        if(years == 1)
            metadata = [metadata stringByAppendingFormat:@"%i year ago", (int)years];
        else
            metadata = [metadata stringByAppendingFormat:@"%i years ago", (int)years];
    } else if(months >= 1) {
        if(months - (int)months > 0.5)
            months++;
        
        if(months == 1)
            metadata = [metadata stringByAppendingFormat:@"%i month ago", (int)months];
        else
            metadata = [metadata stringByAppendingFormat:@"%i months ago", (int)months];
    } else if(days >= 1) {
        if(days - (int)days > 0.5)
            days++;
        
        if(days == 1)
            metadata = [metadata stringByAppendingFormat:@"%i day ago", (int)days];
        else
            metadata = [metadata stringByAppendingFormat:@"%i days ago", (int)days];
    } else if(hours >= 1) {
        if(hours - (int)hours > 0.5)
            hours++;
        
        if(hours < 2)
            metadata = [metadata stringByAppendingFormat:@"%i hour ago", (int)hours];
        else
            metadata = [metadata stringByAppendingFormat:@"%i hours ago", (int)hours];
    } else if(minutes >= 1) {
        if(minutes - (int)minutes > 0.5)
            minutes++;
        
        if(minutes == 1)
            metadata = [metadata stringByAppendingFormat:@"%i minute ago", (int)minutes];
        else
            metadata = [metadata stringByAppendingFormat:@"%i minutes ago", (int)minutes];
    } else {
        if(seconds == 1)
            metadata = [metadata stringByAppendingFormat:@"%i second ago", (int)seconds];
        else
            metadata = [metadata stringByAppendingFormat:@"%i seconds ago", (int)seconds];
    }

    cell.metadata.text = metadata;
    cell.text.text = [pastebin objectForKey:@"body"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _reqid = [[NetworkConnection sharedInstance] deletePaste:[[_pastes objectAtIndex:indexPath.row] objectForKey:@"id"]];
        NSMutableArray *a = _pastes.mutableCopy;
        [a removeObjectAtIndex:indexPath.row];
        _pastes = [NSArray arrayWithArray:a];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if(!_pastes.count) {
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nYou haven't created any pastebins yet.\n";
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
    _selectedPaste = [_pastes objectAtIndex:indexPath.row];
    if(_selectedPaste) {
        NSString *url = [_url_template relativeStringWithVariables:_selectedPaste error:nil];
        url = [url stringByAppendingFormat:@"?id=%@&own_paste=%@", [_selectedPaste objectForKey:@"id"], [_selectedPaste objectForKey:@"own_paste"]];
        PastebinViewController *c = [[PastebinViewController alloc] initWithURL:[NSURL URLWithString:url]];
        [self.navigationController pushViewController:c animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
