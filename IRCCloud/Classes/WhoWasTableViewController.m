//
//  WhoWasTableViewController.h
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

#import "WhoWasTableViewController.h"
#import "LinkTextView.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"

@interface ThenWhoWasTableCell : UITableViewCell {
    LinkTextView *_label;
}
@property (readonly) LinkTextView *label;
@end

@implementation ThenWhoWasTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self->_label = [[LinkTextView alloc] init];
        self->_label.font = [UIFont systemFontOfSize:FONT_SIZE];
        self->_label.backgroundColor = [UIColor clearColor];
        self->_label.textColor = [UIColor messageTextColor];
        self->_label.selectable = YES;
        self->_label.editable = NO;
        self->_label.scrollEnabled = NO;
        self->_label.textContainerInset = UIEdgeInsetsZero;
        self->_label.dataDetectorTypes = UIDataDetectorTypeNone;
        self->_label.textContainer.lineFragmentPadding = 0;
        [self.contentView addSubview:self->_label];
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
    
    self->_label.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation WhoWasTableViewController

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];

    self->_placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
    self->_placeholder.backgroundColor = [UIColor clearColor];
    self->_placeholder.font = [UIFont systemFontOfSize:FONT_SIZE];
    self->_placeholder.numberOfLines = 0;
    self->_placeholder.textAlignment = NSTextAlignmentCenter;
    self->_placeholder.textColor = [UIColor messageTextColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGRect frame = self.tableView.frame;
    frame.size.height = self->_placeholder.font.pointSize * 2;
    self->_placeholder.frame = frame;
    [self.tableView.superview addSubview:self->_placeholder];
    [self refresh];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    if([[self->_event objectForKey:@"lines"] count] == 1 && [[[self->_event objectForKey:@"lines"] objectAtIndex:0] objectForKey:@"no_such_nick"]) {
        self->_data = nil;
        self->_placeholder.text = @"There was no such nickname";
    } else {
        self->_placeholder.text = nil;
        
        for(NSDictionary *line in [self->_event objectForKey:@"lines"]) {
            NSMutableDictionary *c = [[NSMutableDictionary alloc] init];
            NSMutableString *text = [[NSMutableString alloc] init];
            [text appendFormat:@"%c%c%@Nick%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"nick"]];
            if([line objectForKey:@"user"] && [line objectForKey:@"host"])
                [text appendFormat:@"%c%c%@Usermask%c\n%@@%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"user"], [line objectForKey:@"host"]];
            [text appendFormat:@"%c%c%@Real Name%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"realname"]];
            [text appendFormat:@"%c%c%@Last Seen%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"last_seen"]];
            [text appendFormat:@"%c%c%@Connecting Via%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"ircserver"]];
            if([line objectForKey:@"connecting_from"])
                [text appendFormat:@"%c%c%@Info%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"connecting_from"]];
            if([line objectForKey:@"actual_host"])
                [text appendFormat:@"%c%c%@Actual Host%c\n%@\n", BOLD, COLOR_RGB, [[UIColor navBarHeadingColor] toHexString], CLEAR, [line objectForKey:@"actual_host"]];
            [c setObject:[ColorFormatter format:text defaultColor:[UITableViewCell appearance].detailTextLabelColor mono:NO linkify:NO server:nil links:nil] forKey:@"text"];
            [c setObject:@([LinkTextView heightOfString:[c objectForKey:@"text"] constrainedToWidth:self.tableView.bounds.size.width - 6 - 12]) forKey:@"height"];
            [data addObject:c];
        }
        
        self->_data = data;
    }
    [self.tableView reloadData];
    
    self.navigationItem.title = [NSString stringWithFormat:@"WHOWAS response for %@", [self->_event objectForKey:@"nick"]];
}

-(void)doneButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
    return [[row objectForKey:@"height"] floatValue];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self->_data count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ThenWhoWasTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"whowascell"];
    if(!cell)
        cell = [[ThenWhoWasTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"whowascell"];
    NSDictionary *row = [self->_data objectAtIndex:[indexPath section]];
    cell.label.attributedText = [row objectForKey:@"text"];
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
