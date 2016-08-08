//
//  NamesListTableViewController.m
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

#import "NamesListTableViewController.h"
#import "LinkTextView.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@interface NamesTableCell : UITableViewCell {
    LinkTextView *_info;
}
@property (readonly) LinkTextView *info;
@end

@implementation NamesTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _info = [[LinkTextView alloc] init];
        _info.font = [UIFont systemFontOfSize:FONT_SIZE];
        _info.editable = NO;
        _info.scrollEnabled = NO;
        _info.selectable = NO;
        _info.textContainerInset = UIEdgeInsetsZero;
        _info.backgroundColor = [UIColor clearColor];
        _info.textColor = [UIColor messageTextColor];
        [self.contentView addSubview:_info];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.origin.y = 6;
    frame.size.width -= 12;
    _info.frame = frame;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation NamesListTableViewController

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
    [self refresh];
}

-(void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    
    for(NSDictionary *user in [_event objectForKey:@"members"]) {
        NSMutableDictionary *u = [[NSMutableDictionary alloc] initWithDictionary:user];
        NSString *name;
        if([[user objectForKey:@"mode"] length])
            name = [NSString stringWithFormat:@"%c%@%c (+%@)", BOLD, [user objectForKey:@"nick"], CLEAR, [user objectForKey:@"mode"]];
        else
            name = [NSString stringWithFormat:@"%c%@", BOLD, [user objectForKey:@"nick"]];
        NSString *s = [NSString stringWithFormat:@"%@%c%@%c",name,CLEAR,[[user objectForKey:@"away"] intValue]?@" [away]":@"", ITALICS];
        if([[user objectForKey:@"usermask"] length])
            s = [s stringByAppendingFormat:@"\n%@", [user objectForKey:@"usermask"]];
        NSAttributedString *formatted = [ColorFormatter format:s defaultColor:[UITableViewCell appearance].textLabelColor mono:NO linkify:NO server:nil links:nil];
        [u setObject:formatted forKey:@"formatted"];
        [u setObject:@([LinkTextView heightOfString:formatted constrainedToWidth:self.tableView.bounds.size.width - 6 - 12]) forKey:@"height"];
        [data addObject:u];
    }
    
    _data = data;
    [self.tableView reloadData];
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
    return [[row objectForKey:@"height"] floatValue] + 12;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NamesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"namecell"];
    if(!cell)
        cell = [[NamesTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"namecell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.info.attributedText = [row objectForKey:@"formatted"];
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", [row objectForKey:@"nick"]] to:nil cid:_event.cid];
}

@end
