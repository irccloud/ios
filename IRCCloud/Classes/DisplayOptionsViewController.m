//
//  DisplayOptionsViewController.m
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


#import "DisplayOptionsViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@implementation DisplayOptionsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    }
    return self;
}

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)saveButtonPressed:(id)sender {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
    NSMutableDictionary *disableTrackUnread = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *hideJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *hiddenMembers = [[NSMutableDictionary alloc] init];
    
    if([_buffer.type isEqualToString:@"channel"]) {
        if([[prefs objectForKey:@"channel-disableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [disableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"channel-disableTrackUnread"]];
        if(_trackUnread.on)
            [disableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [disableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(disableTrackUnread.count)
            [prefs setObject:disableTrackUnread forKey:@"channel-disableTrackUnread"];
        else
            [prefs removeObjectForKey:@"channel-disableTrackUnread"];

        if([[prefs objectForKey:@"channel-hideJoinPart"] isKindOfClass:[NSDictionary class]])
            [hideJoinPart addEntriesFromDictionary:[prefs objectForKey:@"channel-hideJoinPart"]];
        if(_showJoinPart.on)
            [hideJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [hideJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(hideJoinPart.count)
            [prefs setObject:hideJoinPart forKey:@"channel-hideJoinPart"];
        else
            [prefs removeObjectForKey:@"channel-hideJoinPart"];

        if([[prefs objectForKey:@"channel-hiddenMembers"] isKindOfClass:[NSDictionary class]])
            [hiddenMembers addEntriesFromDictionary:[prefs objectForKey:@"channel-hiddenMembers"]];
        if(_showMembers.on)
            [hiddenMembers removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [hiddenMembers setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(hiddenMembers.count)
            [prefs setObject:hiddenMembers forKey:@"channel-hiddenMembers"];
        else
            [prefs removeObjectForKey:@"channel-hiddenMembers"];
    } else {
        if([[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [disableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"buffer-disableTrackUnread"]];
        if(_trackUnread.on)
            [disableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [disableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(disableTrackUnread.count)
            [prefs setObject:disableTrackUnread forKey:@"buffer-disableTrackUnread"];
        else
            [prefs removeObjectForKey:@"buffer-disableTrackUnread"];
        
        if([_buffer.type isEqualToString:@"conversation"]) {
            if([[prefs objectForKey:@"buffer-hideJoinPart"] isKindOfClass:[NSDictionary class]])
                [hideJoinPart addEntriesFromDictionary:[prefs objectForKey:@"buffer-hideJoinPart"]];
            if(_showJoinPart.on)
                [hideJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [hideJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(hideJoinPart.count)
                [prefs setObject:hideJoinPart forKey:@"buffer-hideJoinPart"];
            else
                [prefs removeObjectForKey:@"buffer-hideJoinPart"];
        }
    }
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSString *json = [writer stringWithObject:prefs];
    
    _reqid = [[NetworkConnection sharedInstance] setPrefs:json];
}

-(void)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventUserInfo:
            [self refresh];
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save settings, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid)
                [self dismissViewControllerAnimated:YES completion:nil];
            break;
        default:
            break;
    }
}

-(void)refresh {
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    if([_buffer.type isEqualToString:@"channel"]) {
        if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _trackUnread.on = NO;
        else
            _trackUnread.on = YES;
        
        if([[[prefs objectForKey:@"channel-hideJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _showJoinPart.on = NO;
        else
            _showJoinPart.on = YES;

        if([[[prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _showMembers.on = NO;
        else
            _showMembers.on = YES;
    } else {
        if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _trackUnread.on = NO;
        else
            _trackUnread.on = YES;
        
        if([[[prefs objectForKey:@"buffer-hideJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _showJoinPart.on = NO;
        else
            _showJoinPart.on = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 7) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navbar"] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
    }

    int padding = 80;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        padding = 26;
        
    _showMembers = [[UISwitch alloc] init];
    _trackUnread = [[UISwitch alloc] init];
    _showJoinPart = [[UISwitch alloc] init];

    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1)
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_buffer.type isEqualToString:@"channel"])
        return 3;
    else if([_buffer.type isEqualToString:@"console"])
        return 1;
    else
        return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingscell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingscell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    
    switch(row) {
        case 0:
            cell.textLabel.text = @"Unread messages";
            cell.accessoryView = _trackUnread;
            break;
        case 1:
            cell.textLabel.text = @"Joins and parts";
            cell.accessoryView = _showJoinPart;
            break;
        case 2:
            cell.textLabel.text = @"Member list";
            cell.accessoryView = _showMembers;
            break;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
}

@end
