//
//  CallerIDTableViewController.m
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


#import "CallerIDTableViewController.h"
#import "NetworkConnection.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"

@implementation CallerIDTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self->_addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        self->_placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        self->_placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self->_placeholder.numberOfLines = 0;
        self->_placeholder.text = @"No accepted nicks.\n\nYou can accept someone by tapping their message request or by using `/accept`.\n";
        self->_placeholder.attributedText = [ColorFormatter format:[self->_placeholder.text insertCodeSpans] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil];
        self->_placeholder.textAlignment = NSTextAlignmentCenter;
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
    if(self->_nicks.count)
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
    
    switch(event) {
        case kIRCEventAcceptList:
            o = notification.object;
            if(o.cid == self->_event.cid) {
                self->_event = o;
                self->_nicks = [o objectForKey:@"nicks"];
                if(self->_nicks.count)
                    [self->_placeholder removeFromSuperview];
                else
                    [self.tableView.superview addSubview:self->_placeholder];
                [self.tableView reloadData];
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
    [self.view endEditing:YES];
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_event.cid];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Allow messages from this user" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Allow" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
            [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/accept %@", ((UITextField *)[alert.textFields objectAtIndex:0]).text] to:nil cid:self->_event.cid handler:nil];
            [[NetworkConnection sharedInstance] say:@"/accept *" to:nil cid:self->_event.cid handler:nil];
        }
    }]];
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 9) {
        [self presentViewController:alert animated:YES completion:nil];
    }
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
    }];
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 9)
        [self presentViewController:alert animated:YES completion:nil];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize + 32;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self->_nicks count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"calleridcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"calleridcell"];
    id nick = [self->_nicks objectAtIndex:[indexPath row]];
    if([nick isKindOfClass:[NSArray class]])
        cell.textLabel.text = [nick objectAtIndex:0];
    else
        cell.textLabel.text = nick;
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *nick = [[self->_nicks objectAtIndex:indexPath.row] objectAtIndex:0];
        [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/accept -%@", nick] to:nil cid:self->_event.cid handler:nil];
        [[NetworkConnection sharedInstance] say:@"/accept *" to:nil cid:self->_event.cid handler:nil];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
