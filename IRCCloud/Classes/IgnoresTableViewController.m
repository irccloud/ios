//
//  IgnoresTableViewController.m
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


#import "IgnoresTableViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"

@implementation IgnoresTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self->_addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        self->_placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        self->_placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self->_placeholder.numberOfLines = 0;
        self->_placeholder.text = @"You're not ignoring anyone at the moment.\n\nYou can ignore someone by tapping their nickname in the user list, long-pressing a message, or by using `/ignore`.\n";
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
    if(self->_ignores.count)
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
    Server *s = nil;
    
    switch(event) {
        case kIRCEventSetIgnores:
            s = [[ServersDataSource sharedInstance] getServer:self->_cid];
            self->_ignores = s.ignores;
            if(self->_ignores.count)
                [self->_placeholder removeFromSuperview];
            else
                [self.tableView.superview addSubview:self->_placeholder];
            [self.tableView reloadData];
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
    Server *s = [[ServersDataSource sharedInstance] getServer:self->_cid];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ignore this hostmask" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ignore" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
            [[NetworkConnection sharedInstance] ignore:((UITextField *)[alert.textFields objectAtIndex:0]).text cid:self->_cid handler:nil];
        }
    }]];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
    }];
    
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self->_ignores objectAtIndex:indexPath.row] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]} context:nil].size.height + 16;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self->_ignores count])
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    @synchronized(self->_ignores) {
        return [self->_ignores count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self->_ignores) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ignorescell"];
        if(!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ignorescell"];
        cell.textLabel.text = [self->_ignores objectAtIndex:[indexPath row]];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:18];
        cell.textLabel.numberOfLines = 0;
        cell.textLabel.lineBreakMode = NSLineBreakByCharWrapping;
        return cell;
    }
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete && indexPath.row < _ignores.count) {
        NSString *mask = [self->_ignores objectAtIndex:indexPath.row];
        [[NetworkConnection sharedInstance] unignore:mask cid:self->_cid handler:nil];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
