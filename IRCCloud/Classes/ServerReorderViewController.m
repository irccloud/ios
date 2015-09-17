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
#import "FontAwesome.h"

@interface ReorderCell : UITableViewCell {
    UILabel *_icon;
}
@property (readonly) UILabel *icon;
@end

@implementation ReorderCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        _icon = [[UILabel alloc] initWithFrame:CGRectMake(0,14,16,16)];
        _icon.textColor = [UITableViewCell appearance].textLabelColor;
        _icon.textAlignment = NSTextAlignmentCenter;
        _icon.font = [UIFont fontWithName:@"FontAwesome" size:self.textLabel.font.pointSize];
        [self.contentView addSubview:_icon];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.contentView.frame;
    frame.origin.x = 10;
    self.contentView.frame = frame;
    self.textLabel.frame = CGRectMake(22,0,self.contentView.frame.size.width - 22,self.contentView.frame.size.height);
}

@end

@implementation ServerReorderViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Connections";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    }
    return self;
}

- (void)doneButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
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
        case kIRCEventConnectionDeleted:
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
    ReorderCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reordercell"];
    if(!cell)
        cell = [[ReorderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reordercell"];

    Server *s = [servers objectAtIndex:indexPath.row];
    
    if(s.name.length)
        cell.textLabel.text = s.name;
    else
        cell.textLabel.text = s.hostname;
    
    cell.icon.text = (s.ssl > 0)?FA_SHIELD:FA_GLOBE;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
