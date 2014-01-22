//
//  ServerReorderViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 1/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "ServerReorderViewController.h"
#import "ServersDataSource.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"

@implementation ServerReorderViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Network Order";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    }
    return self;
}

- (void)doneButtonPressed:(id)sender {
    [self. presentingViewController dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    }
#endif
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.editing = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
    [self refresh];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)refresh {
    servers = [[ServersDataSource sharedInstance] getServers].mutableCopy;
    [self.tableView reloadData];
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventMakeServer:
        case kIRCEventReorderConnections:
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
    return [servers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"servercell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"servercell"];

    Server *s = [servers objectAtIndex:indexPath.row];
    
    if(s.name.length)
        cell.textLabel.text = s.name;
    else
        cell.textLabel.text = s.hostname;
    
    [[cell.textLabel subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIImageView *v = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(s.ssl > 0)?@"world_shield":@"world"]];
    v.frame = CGRectMake(-20,14,16,16);
    [cell.textLabel addSubview:v];
    cell.textLabel.clipsToBounds = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    Server *s = [servers objectAtIndex:fromIndexPath.row];
    [servers removeObjectAtIndex:fromIndexPath.row];
    if (toIndexPath.row >= servers.count) {
        [servers addObject:s];
    } else {
        [servers insertObject:s atIndex:toIndexPath.row];
    }
    
    NSString *cids = @"";
    for(int i = 0; i < servers.count; i++) {
        s = [servers objectAtIndex:i];
        s.order = i + 1;
        if(cids.length)
            cids = [cids stringByAppendingString:@","];
        cids = [cids stringByAppendingFormat:@"%i", s.cid];
    }
    [[NetworkConnection sharedInstance] reorderConnections:cids];
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
