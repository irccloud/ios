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
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
        _placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
        _placeholder.text = @"You're not ignoring anyone at the moment.\n\nYou can ignore someone by tapping their nickname in the user list, long-pressing a message, or by using /ignore.";
        _placeholder.numberOfLines = 0;
        _placeholder.backgroundColor = [UIColor contentBackgroundColor];
        _placeholder.font = [UIFont systemFontOfSize:FONT_SIZE];
        _placeholder.textAlignment = NSTextAlignmentCenter;
        _placeholder.textColor = [UIColor messageTextColor];
        _placeholder.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    self.navigationItem.leftBarButtonItem = _addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _placeholder.frame = CGRectInset(self.tableView.frame, 12, 0);
    if(_ignores.count)
        [_placeholder removeFromSuperview];
    else
        [self.tableView.superview addSubview:_placeholder];
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
            s = [[ServersDataSource sharedInstance] getServer:_cid];
            _ignores = s.ignores;
            if(_ignores.count)
                [_placeholder removeFromSuperview];
            else
                [self.tableView.superview addSubview:_placeholder];
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
    Server *s = [[ServersDataSource sharedInstance] getServer:_cid];
    _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Ignore this hostmask" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ignore", nil];
    _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_alertView textFieldAtIndex:0].delegate = self;
    [_alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
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

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[_ignores objectAtIndex:indexPath.row] boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]} context:nil].size.height + 16;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_ignores count])
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    @synchronized(_ignores) {
        return [_ignores count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_ignores) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ignorescell"];
        if(!cell)
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ignorescell"];
        cell.textLabel.text = [_ignores objectAtIndex:[indexPath row]];
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
        NSString *mask = [_ignores objectAtIndex:indexPath.row];
        [[NetworkConnection sharedInstance] unignore:mask cid:_cid];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Ignore"]) {
        [[NetworkConnection sharedInstance] ignore:[alertView textFieldAtIndex:0].text cid:_cid];
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
