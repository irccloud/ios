//
//  BansTableViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 4/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "BansTableViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@interface BansTableCell : UITableViewCell {
    UILabel *_mask;
    UILabel *_setBy;
}
@property (readonly) UILabel *mask,*setBy;
@end

@implementation BansTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _mask = [[UILabel alloc] init];
        _mask.font = [UIFont boldSystemFontOfSize:16];
        _mask.lineBreakMode = NSLineBreakByCharWrapping;
        _mask.numberOfLines = 0;
        [self.contentView addSubview:_mask];
        
        _setBy = [[UILabel alloc] init];
        _setBy.font = [UIFont systemFontOfSize:14];
        _setBy.textColor = [UIColor grayColor];
        _setBy.lineBreakMode = NSLineBreakByCharWrapping;
        _setBy.numberOfLines = 0;
        [self.contentView addSubview:_setBy];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.size.width -= 12;
    
    float maskHeight = [_mask.text sizeWithFont:_mask.font forWidth:frame.size.width lineBreakMode:_mask.lineBreakMode].height;
    _mask.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, maskHeight);
    _setBy.frame = CGRectMake(frame.origin.x, frame.origin.y + maskHeight, frame.size.width, frame.size.height - maskHeight);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation BansTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        _placeholder = [[UITextView alloc] initWithFrame:CGRectZero];
        _placeholder.text = @"No bans in effect.\n\nYou can ban someone by tapping their nickname in the user list, long-pressing a message, or by using /ban.";
        _placeholder.backgroundColor = [UIColor whiteColor];
        _placeholder.font = [UIFont systemFontOfSize:18];
        _placeholder.textAlignment = UITextAlignmentCenter;
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 7) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
    }
    self.navigationItem.leftBarButtonItem = _addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _placeholder.frame = self.tableView.frame;
    if(_bans.count)
        [_placeholder removeFromSuperview];
    else
        [self.tableView.superview addSubview:_placeholder];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    Event *e = nil;
    
    switch(event) {
        case kIRCEventBanList:
            o = notification.object;
            if(o.cid == _event.cid && [[o objectForKey:@"channel"] isEqualToString:[_event objectForKey:@"channel"]]) {
                _event = o;
                _bans = [o objectForKey:@"bans"];
                if(_bans.count)
                    [_placeholder removeFromSuperview];
                else
                    [self.tableView.superview addSubview:_placeholder];
                [self.tableView reloadData];
            }
            break;
        case kIRCEventBufferMsg:
            e = notification.object;
            if(e.cid == _event.cid && e.bid == _bid) {
                [[NetworkConnection sharedInstance] mode:@"b" chan:[_event objectForKey:@"channel"] cid:_event.cid];
            }
            break;
        default:
            break;
    }
}

-(void)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)addButtonPressed {
    Server *s = [[ServersDataSource sharedInstance] getServer:_event.cid];
    _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ban this hostmask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ban", nil];
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_alertView textFieldAtIndex:0].delegate = self;
    [_alertView show];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
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
    return [msg stringByAppendingFormat:@" by %@", [row objectForKey:@"usermask"]];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = [_bans objectAtIndex:[indexPath row]];
    return [[row objectForKey:@"mask"] sizeWithFont:[UIFont boldSystemFontOfSize:16] constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 12, CGFLOAT_MAX) lineBreakMode:NSLineBreakByCharWrapping].height + [[self setByTextForRow:row] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.tableView.frame.size.width - 12, CGFLOAT_MAX) lineBreakMode:NSLineBreakByCharWrapping].height;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    @synchronized(_bans) {
        return [_bans count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_bans) {
        BansTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"banscell"];
        if(!cell)
            cell = [[BansTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"banscell"];
        NSDictionary *row = [_bans objectAtIndex:[indexPath row]];
        cell.mask.text = [row objectForKey:@"mask"];
        cell.setBy.text = [self setByTextForRow:row];
        return cell;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *row = [_bans objectAtIndex:indexPath.row];
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"-b %@", [row objectForKey:@"mask"]] chan:[_event objectForKey:@"channel"] cid:_event.cid];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Ban"]) {
        [[NetworkConnection sharedInstance] mode:[NSString stringWithFormat:@"+b %@", [alertView textFieldAtIndex:0].text] chan:[_event objectForKey:@"channel"] cid:_event.cid];
    }
    
    _alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

@end
