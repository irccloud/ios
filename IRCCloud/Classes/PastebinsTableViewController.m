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
#import "PastebinEditorViewController.h"

#define MAX_LINES 6

@interface PastebinsTableCell : UITableViewCell {
    UILabel *_name;
    UILabel *_date;
    UILabel *_text;
}
@property (readonly) UILabel *name,*date,*text;
@end

@implementation PastebinsTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self->_name = [[UILabel alloc] init];
        self->_name.backgroundColor = [UIColor clearColor];
        self->_name.textColor = [UITableViewCell appearance].textLabelColor;
        self->_name.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        self->_name.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self->_name];
        
        self->_date = [[UILabel alloc] init];
        self->_date.backgroundColor = [UIColor clearColor];
        self->_date.textColor = [UITableViewCell appearance].textLabelColor;
        self->_date.font = [UIFont systemFontOfSize:FONT_SIZE];
        self->_date.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:self->_date];
        
        self->_text = [[UILabel alloc] init];
        self->_text.backgroundColor = [UIColor clearColor];
        self->_text.textColor = [UITableViewCell appearance].detailTextLabelColor;
        self->_text.font = [UIFont systemFontOfSize:FONT_SIZE];
        self->_text.lineBreakMode = NSLineBreakByTruncatingTail;
        self->_text.numberOfLines = 0;
        [self.contentView addSubview:self->_text];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = [self.contentView bounds];
    frame.origin.x = 16;
    frame.origin.y = 8;
    frame.size.width -= 20;
    frame.size.height -= 16;
    
    [self->_date sizeToFit];
    self->_date.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - FONT_SIZE - 6, _date.frame.size.width, FONT_SIZE + 6);

    if(self->_name.text.length) {
        self->_name.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - 4, FONT_SIZE + 6);
        self->_text.frame = CGRectMake(frame.origin.x, _name.frame.origin.y + _name.frame.size.height, frame.size.width, frame.size.height - _date.frame.size.height - _name.frame.size.height);
    } else {
        self->_text.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - _date.frame.size.height);
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation PastebinsTableViewController

-(instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.navigationItem.title = @"Text Snippets";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        self->_extensions = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;

    self->_footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    self->_footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    a.center = self->_footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [self->_footerView addSubview:a];
    
    self.tableView.tableFooterView = self->_footerView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self->_pages = 0;
    self->_pastes = nil;
    self->_canLoadMore = YES;
    [self _loadMore];
}

-(void)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:self.tableView.isEditing?UIBarButtonSystemItemCancel:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    self->_pastes = nil;
    self->_canLoadMore = NO;
}

-(void)setFooterView:(UIView *)v {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.tableView.tableFooterView = v;
    }];
}

-(void)_loadMore {
    [[NetworkConnection sharedInstance] getPastebins:++_pages handler:^(IRCCloudJSONObject *d) {
        if([[d objectForKey:@"success"] boolValue]) {
            CLS_LOG(@"Loaded pastebin list for page %i", self->_pages);
            if(self->_pastes)
                self->_pastes = [self->_pastes arrayByAddingObjectsFromArray:[d objectForKey:@"pastebins"]];
            else
                self->_pastes = [d objectForKey:@"pastebins"];
            
            self->_canLoadMore = self->_pastes.count < [[d objectForKey:@"total"] intValue];
            [self setFooterView:self->_canLoadMore?self->_footerView:nil];
            if(!self->_pastes.count) {
                CLS_LOG(@"Pastebin list is empty");
                UILabel *fail = [[UILabel alloc] init];
                fail.text = @"\nYou haven't created any\ntext snippets yet.\n";
                fail.numberOfLines = 3;
                fail.textAlignment = NSTextAlignmentCenter;
                fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                fail.textColor = [UIColor messageTextColor];
                [fail sizeToFit];
                [self setFooterView:fail];
            }
        } else {
            CLS_LOG(@"Failed to load pastebin list for page %i: %@", self->_pages, d);
            self->_canLoadMore = NO;
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nUnable to load snippet.\nPlease try again later.\n";
            fail.numberOfLines = 4;
            fail.textAlignment = NSTextAlignmentCenter;
            fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            fail.textColor = [UIColor messageTextColor];
            [fail sizeToFit];
            [self setFooterView:fail];
            return;
        }

        [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)fileType:(NSString *)extension {
    if([self->_extensions objectForKey:extension.lowercaseString])
        return [self->_extensions objectForKey:extension.lowercaseString];
    
    NSString *type = [PastebinEditorViewController pastebinType:extension];
    [self->_extensions setObject:type forKey:extension.lowercaseString];
    return type;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _pastes.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FONT_SIZE + 24 + ([[[self->_pastes objectAtIndex:indexPath.row] objectForKey:@"body"] boundingRectWithSize:CGRectMake(0,0,self.tableView.frame.size.width - 26,(FONT_SIZE + 4) * MAX_LINES).size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:FONT_SIZE]} context:nil].size.height) + ([[[self->_pastes objectAtIndex:indexPath.row] objectForKey:@"name"] length]?(FONT_SIZE + 6):0);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(self->_pastes.count && _canLoadMore) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        
        if([[rows lastObject] row] >= self->_pastes.count - 5) {
            self->_canLoadMore = NO;
            [self _loadMore];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PastebinsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pastebincell"];
    if(!cell)
        cell = [[PastebinsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pastebincell"];

    NSDictionary *pastebin = [self->_pastes objectAtIndex:indexPath.row];
    
    NSString *date = nil;
    double seconds = [[NSDate date] timeIntervalSince1970] - [[pastebin objectForKey:@"date"] doubleValue];
    double minutes = seconds / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / 31.0;
    double years = months / 12.0;
    
    if(years >= 1) {
        if(years - (int)years > 0.5)
            years++;
        
        if((int)years == 1)
            date = [NSString stringWithFormat:@"%i year ago", (int)years];
        else
            date = [NSString stringWithFormat:@"%i years ago", (int)years];
    } else if(months >= 1) {
        if(months - (int)months > 0.5)
            months++;
        
        if((int)months == 1)
            date = [NSString stringWithFormat:@"%i month ago", (int)months];
        else
            date = [NSString stringWithFormat:@"%i months ago", (int)months];
    } else if(days >= 1) {
        if(days - (int)days > 0.5)
            days++;
        
        if((int)days == 1)
            date = [NSString stringWithFormat:@"%i day ago", (int)days];
        else
            date = [NSString stringWithFormat:@"%i days ago", (int)days];
    } else if(hours >= 1) {
        if(hours - (int)hours > 0.5)
            hours++;
        
        if((int)hours < 2)
            date = [NSString stringWithFormat:@"%i hour ago", (int)hours];
        else
            date = [NSString stringWithFormat:@"%i hours ago", (int)hours];
    } else if(minutes >= 1) {
        if(minutes - (int)minutes > 0.5)
            minutes++;
        
        if((int)minutes == 1)
            date = [NSString stringWithFormat:@"%i minute ago", (int)minutes];
        else
            date = [NSString stringWithFormat:@"%i minutes ago", (int)minutes];
    } else {
        if((int)seconds == 1)
            date = [NSString stringWithFormat:@"%i second ago", (int)seconds];
        else
            date = [NSString stringWithFormat:@"%i seconds ago", (int)seconds];
    }

    cell.name.text = [pastebin objectForKey:@"name"];
    cell.date.text = [NSString stringWithFormat:@"%@ • %@ line%@ • %@", date, [pastebin objectForKey:@"lines"], ([[pastebin objectForKey:@"lines"] intValue] == 1)?@"":@"s", [self fileType:[pastebin objectForKey:@"extension"]]];
    cell.text.text = [pastebin objectForKey:@"body"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell layoutSubviews];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[NetworkConnection sharedInstance] deletePaste:[[self->_pastes objectAtIndex:indexPath.row] objectForKey:@"id"] handler:^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                CLS_LOG(@"Pastebin deleted successfully");
            } else {
                CLS_LOG(@"Error deleting pastebin: %@", result);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to delete snippet, please try again." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self->_pages = 0;
                self->_pastes = nil;
                self->_canLoadMore = YES;
                [self _loadMore];
            }
        }];
        NSMutableArray *a = self->_pastes.mutableCopy;
        [a removeObjectAtIndex:indexPath.row];
        self->_pastes = [NSArray arrayWithArray:a];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if(!_pastes.count) {
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nYou haven't created any text snippets yet.\n";
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
    self->_selectedPaste = [self->_pastes objectAtIndex:indexPath.row];
    if(self->_selectedPaste) {
        NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:self->_selectedPaste error:nil];
        url = [url stringByAppendingFormat:@"?id=%@", [self->_selectedPaste objectForKey:@"id"]];
        PastebinViewController *c = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PastebinViewController"];
        [c setUrl:[NSURL URLWithString:url]];
        [self.navigationController pushViewController:c animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
