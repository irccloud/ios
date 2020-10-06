//
//  SpamViewController.h
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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


#import "SpamViewController.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"

@implementation SpamViewController

- (id)initWithCid:(int)cid {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self) {
        self->_cid = cid;
        self->_buffersToDelete = [[NSMutableArray alloc] init];
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteButtonPressed:)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSMutableArray *buffers = [[NSMutableArray alloc] init];
    
    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:self->_cid]) {
        if([b.type isEqualToString:@"conversation"] && !b.archived) {
            [buffers addObject:b];
            [self->_buffersToDelete addObject:b];
        }
    }
    
    self->_buffers = buffers;
    
    self->_header = [[UILabel alloc] init];
    self->_header.frame = CGRectMake(8,0,self.tableView.frame.size.width - 16,64);
    self->_header.text = @"Uncheck any conversations you'd prefer to keep before continuing.";
    self->_header.numberOfLines = 0;
    self->_header.lineBreakMode = NSLineBreakByWordWrapping;
    self->_header.textAlignment = NSTextAlignmentCenter;
    self->_header.textColor = [UIColor timestampColor];

    [self.tableView reloadData];
}

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)deleteButtonPressed:(id)sender {
    for(Buffer *b in _buffersToDelete) {
        [[NetworkConnection sharedInstance] deleteBuffer:b.bid cid:b.cid handler:nil];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if(self->_buffersToDelete.count) {
            Server *s = [[ServersDataSource sharedInstance] getServer:self->_cid];
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:[NSString stringWithFormat:@"%lu conversations were deleted", (unsigned long)self->_buffersToDelete.count] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    CGRect frame = self->_header.frame;
    frame.origin.x = self.view.safeAreaInsets.left + 8;
    self->_header.frame = frame;

    return _header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return _header.frame.size.height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _buffers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buffercell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"buffercell"];
    
    Buffer *b = [self->_buffers objectAtIndex:indexPath.row];
    cell.textLabel.text = b.name;
    
    if([self->_buffersToDelete containsObject:b])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Buffer *b = [self->_buffers objectAtIndex:indexPath.row];
    if([self->_buffersToDelete containsObject:b])
        [self->_buffersToDelete removeObject:b];
    else
        [self->_buffersToDelete addObject:b];
    
    [self.tableView reloadData];
}
@end
