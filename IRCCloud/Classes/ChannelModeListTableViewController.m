//
//  ChannelModeListTableViewController.m
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


#import "ChannelModeListTableViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"

@interface MaskTableCell : UITableViewCell {
    UILabel *_mask;
    UILabel *_setBy;
}
@property (readonly) UILabel *mask,*setBy;
@end

@implementation MaskTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self->_mask = [[UILabel alloc] init];
        self->_mask.font = [UIFont boldSystemFontOfSize:16];
        self->_mask.textColor = [UITableViewCell appearance].textLabelColor;
        self->_mask.lineBreakMode = NSLineBreakByCharWrapping;
        self->_mask.numberOfLines = 0;
        [self.contentView addSubview:self->_mask];
        
        self->_setBy = [[UILabel alloc] init];
        self->_setBy.font = [UIFont systemFontOfSize:14];
        self->_setBy.textColor = [UITableViewCell appearance].detailTextLabelColor;
        self->_setBy.lineBreakMode = NSLineBreakByCharWrapping;
        self->_setBy.numberOfLines = 0;
        [self.contentView addSubview:self->_setBy];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = frame.origin.y = 6;
    frame.size.width -= 12;
    
    float maskHeight = ceil([self->_mask.text boundingRectWithSize:CGSizeMake(frame.size.width, INT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:self->_mask.font} context:nil].size.height) + 2;
    self->_mask.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, maskHeight);
    self->_setBy.frame = CGRectMake(frame.origin.x, frame.origin.y + maskHeight - 2, frame.size.width, frame.size.height - maskHeight - 8);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation ChannelModeListTableViewController

-(id)initWithList:(int)list mode:(NSString *)mode param:(NSString *)param placeholder:(NSString *)placeholder bid:(int)bid {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self->_addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        self->_placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        self->_placeholder.text = placeholder;
        self->_placeholder.numberOfLines = 0;
        self->_placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self->_placeholder.attributedText = [ColorFormatter format:[self->_placeholder.text insertCodeSpans] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil];
        self->_placeholder.textAlignment = NSTextAlignmentCenter;

        self->_list = list;
        self->_bid = bid;
        self->_mode = mode;
        self->_param = param;
        self->_mask = @"mask";
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationItem.leftBarButtonItem = self->_addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    self->_placeholder.frame = CGRectInset(self.tableView.frame, 12, 0);
    if(self->_data.count)
        [self->_placeholder removeFromSuperview];
    else
        [self.tableView.superview addSubview:self->_placeholder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    Event *e = nil;

    if(event == self->_list) {
        o = notification.object;
        if(o.cid == self->_event.cid && [[o objectForKey:@"channel"] isEqualToString:[self->_event objectForKey:@"channel"]]) {
            self->_event = o;
            self->_data = [o objectForKey:self->_param];
            if(self->_data.count)
                [self->_placeholder removeFromSuperview];
            else
                [self.tableView.superview addSubview:self->_placeholder];
            [self.tableView reloadData];
        }
    } else if(event == kIRCEventBufferMsg) {
        e = notification.object;
        if(e.cid == self->_event.cid && e.bid == self->_bid && [e.type isEqualToString:@"channel_mode_list_change"]) {
            [[NetworkConnection sharedInstance] mode:self->_mode chan:[self->_event objectForKey:@"channel"] cid:self->_event.cid handler:nil];
        }
    }
}

-(void)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)addButtonPressed {
    [self.view endEditing:YES];
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_event.cid];
    self->_alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Add this hostmask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add", nil];
    self->_alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [self->_alertView textFieldAtIndex:0].delegate = self;
    [self->_alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
    [self->_alertView show];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self->_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:self->_alertView clickedButtonAtIndex:1];
    return NO;
}

-(NSString *)setByTextForRow:(NSDictionary *)row {
    NSString *msg = @"Set ";
    double seconds = [[NSDate date] timeIntervalSince1970] - [[row objectForKey:@"time"] doubleValue];
    double minutes = seconds / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    if(days >= 1) {
        if(days - (int)days > 0.5)
            days++;
        
        if(days == 1)
            msg = [msg stringByAppendingFormat:@"%i day ago", (int)days];
        else
            msg = [msg stringByAppendingFormat:@"%i days ago", (int)days];
    } else if(hours >= 1) {
        if(hours - (int)hours > 0.5)
            hours++;
        
        if(hours < 2)
            msg = [msg stringByAppendingFormat:@"%i hour ago", (int)hours];
        else
            msg = [msg stringByAppendingFormat:@"%i hours ago", (int)hours];
    } else if(minutes >= 1) {
        if(minutes - (int)minutes > 0.5)
            minutes++;
        
        if(minutes == 1)
            msg = [msg stringByAppendingFormat:@"%i minute ago", (int)minutes];
        else
            msg = [msg stringByAppendingFormat:@"%i minutes ago", (int)minutes];
    } else {
        msg = [msg stringByAppendingString:@"less than a minute ago"];
    }
    if([row objectForKey:@"author"])
        return [msg stringByAppendingFormat:@" by %@", [row objectForKey:@"author"]];
    else
        return [msg stringByAppendingFormat:@" by %@", [row objectForKey:@"usermask"]];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
    return ceil([[row objectForKey:self->_mask] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 12, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:16]} context:nil].size.height + [[self setByTextForRow:row] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - 12, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]} context:nil].size.height) + 12;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self->_data count])
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    @synchronized(self->_data) {
        return [self->_data count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self->_data) {
        MaskTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"maskcell"];
        if(!cell)
            cell = [[MaskTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"maskcell"];
        NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
        cell.mask.text = [row objectForKey:self->_mask];
        cell.setBy.text = [self setByTextForRow:row];
        return cell;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.row < _data.count) {
        NSDictionary *row = [self->_data objectAtIndex:indexPath.row];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-%@ %@", _mode, [row objectForKey:self->_mask]] chan:[self->_event objectForKey:@"channel"] cid:self->_event.cid handler:nil];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Add"]) {
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+%@ %@", _mode, [alertView textFieldAtIndex:0].text] chan:[self->_event objectForKey:@"channel"] cid:self->_event.cid handler:nil];
    }
    
    self->_alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

@end
