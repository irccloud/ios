//
//  ChannelListTableViewController.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
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
        _placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholder.backgroundColor = [UIColor contentBackgroundColor];
        _placeholder.font = [UIFont systemFontOfSize:18];
        _placeholder.numberOfLines = 0;
        _placeholder.textAlignment = NSTextAlignmentCenter;
        _placeholder.textColor = [UIColor messageTextColor];
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        _activity.hidesWhenStopped = YES;
        [_placeholder addSubview:_activity];
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _placeholder.frame = CGRectInset(self.tableView.frame, 12, 0);;
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
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    for(NSDictionary *channel in _channels) {
        NSMutableDictionary *c = [[NSMutableDictionary alloc] initWithDictionary:channel];
        NSAttributedString *topic = [ColorFormatter format:[c objectForKey:@"topic"] defaultColor:[UITableViewCell appearance].detailTextLabelColor mono:NO linkify:NO server:nil links:nil];
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
                _placeholder.text = [NSString stringWithFormat:@"Too many channels to list for %@\n\nTry limiting the list to only respond with channels that have more than e.g. 50 members: /LIST >50", [o objectForKey:@"server"]];
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
    cell.channel.attributedText = [ColorFormatter format:[NSString stringWithFormat:@"%c%@%c (%i member%@)",BOLD,[row objectForKey:@"name"],CLEAR, [[row objectForKey:@"num_members"] intValue],[[row objectForKey:@"num_members"] intValue]==1?@"":@"s"] defaultColor:[UITableViewCell appearance].textLabelColor mono:NO linkify:NO server:nil links:nil];
    cell.topic.attributedText = [row objectForKey:@"formatted_topic"];
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *row = [_data objectAtIndex:indexPath.row];
    [[NetworkConnection sharedInstance] join:[row objectForKey:@"name"] key:nil cid:_event.cid];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
