//
//  LinksListTableViewController.m
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

#import "LinksListTableViewController.h"
#import "LinkTextView.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@interface LinkTableCell : UITableViewCell {
    LinkTextView *_info;
}
@property (readonly) LinkTextView *info;
@end

@implementation LinkTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self->_info = [[LinkTextView alloc] init];
        self->_info.font = [UIFont systemFontOfSize:FONT_SIZE];
        self->_info.editable = NO;
        self->_info.scrollEnabled = NO;
        self->_info.textContainerInset = UIEdgeInsetsZero;
        self->_info.backgroundColor = [UIColor clearColor];
        self->_info.textColor = [UIColor messageTextColor];
        [self.contentView addSubview:self->_info];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.size.width -= 12;
    
    self->_info.frame = frame;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation LinksListTableViewController

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
    [self refresh];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    for(NSDictionary *link in [self->_event objectForKey:@"links"]) {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] init];
        NSAttributedString *formatted = [ColorFormatter format:[NSString stringWithFormat:@"%c%@%c\n%@\nHops: %@", BOLD, [link objectForKey:@"server"], CLEAR, [link objectForKey:@"info"], [link objectForKey:@"hopcount"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil];
        [d setObject:formatted forKey:@"formatted"];
        [d setObject:@([LinkTextView heightOfString:formatted constrainedToWidth:self.tableView.bounds.size.width - 6 - 12] + 16) forKey:@"height"];
        [data addObject:d];
    }
    
    self->_data = data;
    [self.tableView reloadData];
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
    NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
    return [[row objectForKey:@"height"] floatValue];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self->_data count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LinkTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"linkcell"];
    if(!cell)
        cell = [[LinkTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"linkcell"];
    NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
    cell.info.attributedText = [row objectForKey:@"formatted"];
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}
@end
