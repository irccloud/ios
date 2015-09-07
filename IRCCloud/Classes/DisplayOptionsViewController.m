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

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
    NSMutableDictionary *disableTrackUnread = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notifyAll = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *hideJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *expandJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *expandDisco = [[NSMutableDictionary alloc] init];
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

        if([[prefs objectForKey:@"channel-notifications-all"] isKindOfClass:[NSDictionary class]])
            [notifyAll addEntriesFromDictionary:[prefs objectForKey:@"channel-notifications-all"]];
        if(_notifyAll.on)
            [notifyAll setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [notifyAll removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(notifyAll.count)
            [prefs setObject:notifyAll forKey:@"channel-notifications-all"];
        else
            [prefs removeObjectForKey:@"channel-notifications-all"];
        
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

        if([[prefs objectForKey:@"channel-expandJoinPart"] isKindOfClass:[NSDictionary class]])
            [expandJoinPart addEntriesFromDictionary:[prefs objectForKey:@"channel-expandJoinPart"]];
        if(_collapseJoinPart.on)
            [expandJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [expandJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(expandJoinPart.count)
            [prefs setObject:expandJoinPart forKey:@"channel-expandJoinPart"];
        else
            [prefs removeObjectForKey:@"channel-expandJoinPart"];
        
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

            if([[prefs objectForKey:@"buffer-expandJoinPart"] isKindOfClass:[NSDictionary class]])
                [expandJoinPart addEntriesFromDictionary:[prefs objectForKey:@"buffer-expandJoinPart"]];
            if(_collapseJoinPart.on)
                [expandJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [expandJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(expandJoinPart.count)
                [prefs setObject:expandJoinPart forKey:@"buffer-expandJoinPart"];
            else
                [prefs removeObjectForKey:@"buffer-expandJoinPart"];
        }
        
        if([_buffer.type isEqualToString:@"console"]) {
            if([[prefs objectForKey:@"buffer-expandDisco"] isKindOfClass:[NSDictionary class]])
                [expandDisco addEntriesFromDictionary:[prefs objectForKey:@"buffer-expandDisco"]];
            if(_expandDisco.on)
                [expandDisco removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [expandDisco setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(expandDisco.count)
                [prefs setObject:expandDisco forKey:@"buffer-expandDisco"];
            else
                [prefs removeObjectForKey:@"buffer-expandDisco"];
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
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventUserInfo:
            if(_reqid == 0)
                [self refresh];
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save settings, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
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
        
        if([[[prefs objectForKey:@"channel-notifications-all"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _notifyAll.on = YES;
        else
            _notifyAll.on = NO;
        
        if([[[prefs objectForKey:@"channel-hideJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _showJoinPart.on = NO;
        else
            _showJoinPart.on = YES;

        if([[[prefs objectForKey:@"channel-expandJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _collapseJoinPart.on = NO;
        else
            _collapseJoinPart.on = YES;
        
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

        if([[[prefs objectForKey:@"buffer-expandJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _collapseJoinPart.on = NO;
        else
            _collapseJoinPart.on = YES;
        
        if([[[prefs objectForKey:@"buffer-expandDisco"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            _expandDisco.on = NO;
        else
            _expandDisco.on = YES;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.clipsToBounds = YES;
        
    _showMembers = [[UISwitch alloc] init];
    _notifyAll = [[UISwitch alloc] init];
    _trackUnread = [[UISwitch alloc] init];
    _showJoinPart = [[UISwitch alloc] init];
    _collapseJoinPart = [[UISwitch alloc] init];
    _expandDisco = [[UISwitch alloc] init];

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
        return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)?4:5;
    else if([_buffer.type isEqualToString:@"console"])
        return 2;
    else
        return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingscell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingscell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    
    if(![_buffer.type isEqualToString:@"channel"] && row > 0)
        row+=2;
    else if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && row > 0)
        row++;
    
    switch(row) {
        case 0:
            cell.textLabel.text = @"Track unread messages";
            cell.accessoryView = _trackUnread;
            break;
        case 1:
            cell.textLabel.text = @"Member list";
            cell.accessoryView = _showMembers;
            break;
        case 2:
            cell.textLabel.text = @"Notify on all messages";
            cell.accessoryView = _notifyAll;
            break;
        case 3:
            if([_buffer.type isEqualToString:@"console"]) {
                cell.textLabel.text = @"Group repeated disconnects";
                cell.accessoryView = _expandDisco;
            } else {
                cell.textLabel.text = @"Show joins/parts";
                cell.accessoryView = _showJoinPart;
            }
            break;
        case 4:
            cell.textLabel.text = @"Collapse joins/parts";
            cell.accessoryView = _collapseJoinPart;
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
