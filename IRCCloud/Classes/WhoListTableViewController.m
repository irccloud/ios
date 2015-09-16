//
//  WhoListTableViewController.m
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

#import <MobileCoreServices/UTCoreTypes.h>
#import "WhoListTableViewController.h"
#import "TTTAttributedLabel.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@interface WhoTableCell : UITableViewCell {
    TTTAttributedLabel *_info;
}
@property (readonly) UILabel *info;
@end

@implementation WhoTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _info = [[TTTAttributedLabel alloc] init];
        _info.font = [UIFont systemFontOfSize:FONT_SIZE];
        _info.lineBreakMode = NSLineBreakByCharWrapping;
        _info.numberOfLines = 0;
        [self.contentView addSubview:_info];
    }
    return self;
}

-(void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.origin.x = 6;
    frame.size.width -= 12;
    
    _info.frame = frame;
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation WhoListTableViewController

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
    
    for(NSDictionary *user in [_event objectForKey:@"users"]) {
        NSMutableDictionary *u = [[NSMutableDictionary alloc] initWithDictionary:user];
        NSString *name;
        if([[user objectForKey:@"realname"] length])
            name = [NSString stringWithFormat:@"%c%@%c (%@)", BOLD, [user objectForKey:@"nick"], BOLD, [user objectForKey:@"realname"]];
        else
            name = [NSString stringWithFormat:@"%c%@", BOLD, [user objectForKey:@"nick"]];
        NSAttributedString *formatted = [ColorFormatter format:[NSString stringWithFormat:@"%@%c%@%cConnected via %@\n%@",name,CLEAR,[[user objectForKey:@"away"] intValue]?@" [away]\n":@"\n", ITALICS,[user objectForKey:@"ircserver"], [user objectForKey:@"usermask"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil];
        [u setObject:formatted forKey:@"formatted"];
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(formatted));
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.tableView.bounds.size.width - 6 - 12,CGFLOAT_MAX), NULL);
        [u setObject:@(ceilf(suggestedSize.height) + 16) forKey:@"height"];
        CFRelease(framesetter);
        [data addObject:u];
    }
    
    _data = data;
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
    WhoTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"whocell"];
    if(!cell)
        cell = [[WhoTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"whocell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.info.attributedText = [row objectForKey:@"formatted"];
    return cell;
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    _selectedRow = [_data objectAtIndex:[indexPath row]];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Send a message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self actionSheet:(UIActionSheet *)alert clickedButtonAtIndex:0];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Whois" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self actionSheet:(UIActionSheet *)alert clickedButtonAtIndex:1];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Copy hostmask" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self actionSheet:(UIActionSheet *)alert clickedButtonAtIndex:2];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *alert) {}]];
        alert.popoverPresentationController.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = self.view;
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Send a message", "Whois", "Copy hostmask", nil];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            [sheet showInView:self.view];
        } else {
            [sheet showFromRect:[self.tableView rectForRowAtIndexPath:indexPath] inView:self.view animated:YES];
        }
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch(buttonIndex) {
        case 0:
            [self dismissViewControllerAnimated:YES completion:nil];
            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/query %@", [_selectedRow objectForKey:@"nick"]] to:nil cid:_event.cid];
            break;
        case 1:
            [self dismissViewControllerAnimated:YES completion:nil];
            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/whois %@", [_selectedRow objectForKey:@"nick"]] to:nil cid:_event.cid];
            break;
        case 2:
        {
            UIPasteboard *pb = [UIPasteboard generalPasteboard];
            [pb setValue:[NSString stringWithFormat:@"%@!%@", [_selectedRow objectForKey:@"nick"], [_selectedRow objectForKey:@"usermask"]] forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
        }
            break;
        default:
            break;
    }
}
@end
