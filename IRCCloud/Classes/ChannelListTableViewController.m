//
//  ChannelListTableViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 6/18/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "ChannelListTableViewController.h"
#import "NetworkConnection.h"
#import "TTTAttributedLabel.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"

@interface ChannelTableCell : UITableViewCell {
    TTTAttributedLabel *_channel;
    TTTAttributedLabel *_topic;
}
@property (readonly) UILabel *channel,*topic;
@end

@implementation ChannelTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _channel = [[TTTAttributedLabel alloc] init];
        _channel.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        _channel.lineBreakMode = NSLineBreakByCharWrapping;
        _channel.numberOfLines = 1;
        [self.contentView addSubview:_channel];
        
        _topic = [[TTTAttributedLabel alloc] init];
        _topic.font = [UIFont systemFontOfSize:FONT_SIZE];
        _topic.textColor = [UIColor grayColor];
        _topic.lineBreakMode = NSLineBreakByCharWrapping;
        _topic.numberOfLines = 0;
        [self.contentView addSubview:_topic];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.origin.y = 6;
    frame.size.width -= 12;
    frame.size.height -= 8;
    
    _channel.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, FONT_SIZE + 2);
    _topic.frame = CGRectMake(frame.origin.x, frame.origin.y + FONT_SIZE + 2, frame.size.width, frame.size.height - FONT_SIZE - 2);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation ChannelListTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        //_addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        _placeholder = [[UITextView alloc] initWithFrame:CGRectZero];
        _placeholder.backgroundColor = [UIColor whiteColor];
        _placeholder.font = [UIFont systemFontOfSize:18];
        _placeholder.textAlignment = UITextAlignmentCenter;
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activity.hidesWhenStopped = YES;
        [_placeholder addSubview:_activity];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 7) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
    }
    //self.navigationItem.leftBarButtonItem = _addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _placeholder.frame = self.tableView.frame;
    if(_channels.count) {
        [self refresh];
        [_activity stopAnimating];
        [_placeholder removeFromSuperview];
    } else {
        _placeholder.text = [NSString stringWithFormat:@"\nLoading channel list for %@", [_event objectForKey:@"server"]];
        _activity.frame = CGRectMake((_placeholder.frame.size.width - _activity.frame.size.width)/2,6,_activity.frame.size.width,_activity.frame.size.height);
        [_activity startAnimating];
        [self.tableView.superview addSubview:_placeholder];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    for(NSDictionary *channel in _channels) {
        NSMutableDictionary *c = [[NSMutableDictionary alloc] initWithDictionary:channel];
        NSAttributedString *topic = [ColorFormatter format:[c objectForKey:@"topic"] defaultColor:[UIColor lightGrayColor] mono:NO linkify:NO server:nil links:nil];
        [c setObject:topic forKey:@"formatted_topic"];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(topic));
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.tableView.bounds.size.width - 6 - 12,CGFLOAT_MAX), NULL);
        [c setObject:@(ceilf(suggestedSize.height) + 16 + FONT_SIZE + 2) forKey:@"height"];
        CFRelease(framesetter);
        [data addObject:c];
    }
    
    _data = data;
    [self.tableView reloadData];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    
    switch(event) {
        case kIRCEventListResponse:
            o = notification.object;
            if(o.cid == _event.cid) {
                _event = o;
                _channels = [o objectForKey:@"channels"];
                [self refresh];
                [_activity stopAnimating];
                [_placeholder removeFromSuperview];
            }
            break;
        case kIRCEventListResponseTooManyChannels:
            o = notification.object;
            if(o.cid == _event.cid) {
                _event = o;
                _placeholder.text = [NSString stringWithFormat:@"Too many channels to list for %@", [o objectForKey:@"server"]];
                [_activity stopAnimating];
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
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    return [[row objectForKey:@"height"] floatValue];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"channelcell"];
    if(!cell)
        cell = [[ChannelTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"channelcell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.channel.attributedText = [ColorFormatter format:[NSString stringWithFormat:@"%c%@%c (%i member%@)",BOLD,[row objectForKey:@"name"],CLEAR, [[row objectForKey:@"num_members"] intValue],[[row objectForKey:@"num_members"] intValue]==1?@"":@"s"] defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil];
    cell.topic.attributedText = [row objectForKey:@"formatted_topic"];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *row = [_data objectAtIndex:indexPath.row];
    [[NetworkConnection sharedInstance] join:[row objectForKey:@"name"] key:nil cid:_event.cid];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
    return NO;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    _alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

@end
