//
//  CallerIDTableViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 6/20/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "CallerIDTableViewController.h"
#import "NetworkConnection.h"

@implementation CallerIDTableViewController

-(id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed)];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItem = _addButton;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    
    switch(event) {
        case kIRCEventAcceptList:
            o = notification.object;
            if(o.cid == _event.cid) {
                _event = o;
                _nicks = [o objectForKey:@"nicks"];
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
    Server *s = [[ServersDataSource sharedInstance] getServer:_event.cid];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"Allow messages from this user" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Allow", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_nicks count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"calleridcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"calleridcell"];
    cell.textLabel.text = [[_nicks objectAtIndex:[indexPath row]] objectAtIndex:0];
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSString *nick = [[_nicks objectAtIndex:indexPath.row] objectAtIndex:0];
        [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/accept -%@", nick] to:nil cid:_event.cid];
        [[NetworkConnection sharedInstance] say:@"/accept *" to:nil cid:_event.cid];
    }
}

#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Allow"]) {
        [[NetworkConnection sharedInstance] say:[NSString stringWithFormat:@"/accept %@", [alertView textFieldAtIndex:0].text] to:nil cid:_event.cid];
        [[NetworkConnection sharedInstance] say:@"/accept *" to:nil cid:_event.cid];
    }
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStylePlainTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

@end
