//
//  BuffersTableView.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "BuffersTableView.h"
#import "NetworkConnection.h"
#import "BuffersDataSource.h"
#import "ServersDataSource.h"
#import "UIColor+IRCCloud.h"

#define TYPE_SERVER 0
#define TYPE_CHANNEL 1
#define TYPE_CONVERSATION 2
#define TYPE_ARCHIVES_HEADER 3

@interface BuffersTableCell : UITableViewCell {
    UILabel *_label;
    UIImageView *_icon;
    int _type;
    UIView *_unreadIndicator;
    UIView *_bg;
}
@property int type;
@property (readonly) UILabel *label;
@property (readonly) UIImageView *icon;
@property (readonly) UIView *unreadIndicator, *bg;
@end

@implementation BuffersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.contentView.backgroundColor = [UIColor backgroundBlueColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _bg = [[UIView alloc] init];
        [self.contentView addSubview:_bg];
        
        _unreadIndicator = [[UIView alloc] init];
        _unreadIndicator.backgroundColor = [UIColor selectedBlueColor];
        [self.contentView addSubview:_unreadIndicator];
        
        _icon = [[UIImageView alloc] init];
        _icon.contentMode = UIViewContentModeCenter;
        [self.contentView addSubview:_icon];

        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor selectedBlueColor];
        [self.contentView addSubview:_label];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    frame.size.width -= 6;
    if(_type == TYPE_SERVER) {
        frame.origin.y += 6;
        frame.size.height -= 6;
    }
    _bg.frame = CGRectMake(frame.origin.x + 6, frame.origin.y, frame.size.width - 6, frame.size.height);
    _unreadIndicator.frame = CGRectMake(frame.origin.x, frame.origin.y, 6, frame.size.height);
    _icon.frame = CGRectMake(frame.origin.x + 6, frame.origin.y, frame.size.height, frame.size.height);
    _label.frame = CGRectMake(frame.origin.x + 6 + frame.size.height, frame.origin.y, frame.size.width - 6 - frame.size.height, frame.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation BuffersTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _data = [[NSMutableArray alloc] init];
        _selectedRow = -1;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"buffers table appear");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    NSLog(@"buffers table disappear");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventJoin:
        case kIRCEventPart:
            [self refresh];
            break;
        default:
            break;
    }
}

- (void)refresh {
    @synchronized(_data) {
        [_data removeAllObjects];
        int archiveCount = 0;
        
        for(Server *server in [[ServersDataSource sharedInstance] getServers]) {
            NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffersForServer:server.cid];
            for(Buffer *buffer in buffers) {
                if([buffer.type isEqualToString:@"console"]) {
                    int unread = 0;
                    int highlights = 0;
                    NSString *name = server.name;
                    if(!name || name.length == 0)
                        name = server.hostname;
                    [_data addObject:@{
                     @"type":@TYPE_SERVER,
                     @"cid":@(buffer.cid),
                     @"bid":@(buffer.bid),
                     @"name":name,
                     @"unread":@(unread),
                     @"highlights":@(highlights),
                     @"archived":@0,
                     }];
                }
            }
            for(Buffer *buffer in buffers) {
                int type = -1;
                int key = 0;
                int joined = 1;
                if([buffer.type isEqualToString:@"channel"]) {
                    type = TYPE_CHANNEL;
                    Channel *channel = [[ChannelsDataSource sharedIntance] channelForBuffer:buffer.bid];
                    if(channel) {
                        if([channel.mode rangeOfString:@"k"].location != NSNotFound)
                            key = 1;
                    } else {
                        joined = 0;
                    }
                } else if([buffer.type isEqualToString:@"conversation"]) {
                    type = TYPE_CONVERSATION;
                }
                if(type > 0 && buffer.archived == 0) {
                    int unread = (_data.count % 3 == 0)?1:0;
                    int highlights = 0;
                    [_data addObject:@{
                     @"type":@(type),
                     @"cid":@(buffer.cid),
                     @"bid":@(buffer.bid),
                     @"name":buffer.name,
                     @"unread":@(unread),
                     @"highlights":@(highlights),
                     @"archived":@0,
                     @"key":@(key),
                     }];
                }
                if(buffer.archived > 0)
                    archiveCount++;
            }
            if(archiveCount > 0) {
                [_data addObject:@{@"type":@(TYPE_ARCHIVES_HEADER), @"name":@"Archives"}];
                //TODO: iterate again and add the expanded archives
            }
        }
        [self.tableView reloadData];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    @synchronized(_data) {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    @synchronized(_data) {
        return _data.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_data) {
        if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SERVER) {
            return 40;
        } else {
            return 32;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_data) {
        BOOL selected = (indexPath.row == _selectedRow);
        BuffersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bufferscell"];
        if(!cell)
            cell = [[BuffersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bufferscell"];
        NSDictionary *row = [_data objectAtIndex:[indexPath row]];
        cell.type = [[row objectForKey:@"type"] intValue];
        cell.label.text = [row objectForKey:@"name"];
        if([[row objectForKey:@"unread"] intValue] || selected) {
            cell.unreadIndicator.hidden = NO;
            cell.label.font = [UIFont boldSystemFontOfSize:16.0f];
        } else {
            cell.unreadIndicator.hidden = YES;
            cell.label.font = [UIFont systemFontOfSize:16.0f];
        }
        switch(cell.type) {
            case TYPE_SERVER:
                cell.icon.image = [UIImage imageNamed:@"world"];
                cell.icon.hidden = NO;
                if(selected) {
                    cell.label.textColor = [UIColor whiteColor];
                    cell.bg.backgroundColor = [UIColor selectedBlueColor];
                } else {
                    cell.label.textColor = [UIColor selectedBlueColor];
                    cell.bg.backgroundColor = [UIColor colorWithRed:0.886 green:0.929 blue:1 alpha:1];
                }
                break;
            case TYPE_CHANNEL:
            case TYPE_CONVERSATION:
                if([[row objectForKey:@"key"] intValue]) {
                    cell.icon.image = [UIImage imageNamed:@"lock"];
                    cell.icon.hidden = NO;
                } else {
                    cell.icon.image = nil;
                    cell.icon.hidden = YES;
                }
                if(selected) {
                    cell.label.textColor = [UIColor whiteColor];
                    cell.bg.backgroundColor = [UIColor selectedBlueColor];
                } else {
                    cell.label.textColor = [UIColor selectedBlueColor];
                    cell.bg.backgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
                }
                break;
            case TYPE_ARCHIVES_HEADER:
                cell.icon.image = nil;
                cell.icon.hidden = YES;
                cell.label.textColor = [UIColor colorWithRed:0.133 green:0.133 blue:0.133 alpha:1];
                cell.bg.backgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
                break;
        }
        return cell;
    }
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
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    _selectedRow = indexPath.row;
    [tableView reloadData];
}

@end
