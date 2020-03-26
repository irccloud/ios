//
//  PinReorderViewController.m
//
//  Copyright (C) 2020 IRCCloud, Ltd.
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

#import "PinReorderViewController.h"
#import "BuffersDataSource.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"
#import "FontAwesome.h"

@interface ReorderCell : UITableViewCell {
    UILabel *_icon;
}
@property (readonly) UILabel *icon;
@end

@implementation PinReorderViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Pinned Channels";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)doneButtonPressed:(id)sender {
    NSMutableDictionary *mutablePrefs = [[NetworkConnection sharedInstance] prefs].mutableCopy;
    [mutablePrefs setObject:buffers forKey:@"pinnedBuffers"];
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *json = [writer stringWithObject:mutablePrefs];

    [[NetworkConnection sharedInstance] setPrefs:json handler:^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] boolValue]) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.editing = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
    [self refresh];
}

-(void)refresh {
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    if([[prefs objectForKey:@"pinnedBuffers"] isKindOfClass:NSArray.class] && [(NSArray *)[prefs objectForKey:@"pinnedBuffers"] count] > 0) {
        buffers = ((NSArray *)[prefs objectForKey:@"pinnedBuffers"]).mutableCopy;
    } else {
        buffers = [[NSMutableArray alloc] init];
    }
    nameCounts = [[NSMutableDictionary alloc] init];
    for(NSNumber *bid in buffers) {
        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid.intValue];
        if(b) {
            int count = [[nameCounts objectForKey:b.displayName] intValue];
            [nameCounts setObject:@(count + 1) forKey:b.displayName];
        }
    }
    [self.tableView reloadData];
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventUserInfo:
            [self refresh];
            break;
        default:
            break;
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [buffers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ReorderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reordercell"];
    if(!cell)
        cell = [[ReorderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reordercell"];

    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[buffers objectAtIndex:indexPath.row] intValue]];
    NSString *name = b.displayName;
    if([[nameCounts objectForKey:b.displayName] intValue] > 1) {
        Server *s = [[ServersDataSource sharedInstance] getServer:b.cid];
        if(s) {
            NSString *serverName = s.name;
            if(!serverName || serverName.length == 0)
                serverName = s.hostname;

            name = [name stringByAppendingFormat:@" (%@)", serverName];
        }
    }
    
    cell.textLabel.text = name;
    cell.icon.text = nil;
    if([b.type isEqualToString:@"channel"]) {
        Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:b.bid];
        if(channel) {
            if(channel.key || (b.serverIsSlack && !b.isMPDM && [channel hasMode:@"s"]))
                cell.icon.text = FA_LOCK;
        }
    }

    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    NSNumber *bid = [buffers objectAtIndex:fromIndexPath.row];
    [buffers removeObjectAtIndex:fromIndexPath.row];
    if (toIndexPath.row >= buffers.count) {
        [buffers addObject:bid];
    } else {
        [buffers insertObject:bid atIndex:toIndexPath.row];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

@end
