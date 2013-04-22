//
//  BuffersTableView.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "BuffersTableView.h"
#import "NetworkConnection.h"
#import "ServersDataSource.h"
#import "UIColor+IRCCloud.h"
#import "HighlightsCountView.h"

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
    HighlightsCountView *_highlights;
}
@property int type;
@property (readonly) UILabel *label;
@property (readonly) UIImageView *icon;
@property (readonly) UIView *unreadIndicator, *bg;
@property (readonly) HighlightsCountView *highlights;
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
        
        _highlights = [[HighlightsCountView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_highlights];
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
    _icon.frame = CGRectMake(frame.origin.x + 12, frame.origin.y + 12, 16, 16);
    if(!_highlights.hidden) {
        CGSize size = [_highlights.count sizeWithFont:_highlights.font];
        size.width += 4;
        size.height = frame.size.height - 12;
        if(size.width < size.height)
            size.width = size.height;
        frame.size.width -= size.width + 12;
        _highlights.frame = CGRectMake(frame.origin.x + 6 + frame.size.width, frame.origin.y + 6, size.width, size.height);
    }
    _label.frame = CGRectMake(frame.origin.x + 12 + _icon.frame.size.height + 6, frame.origin.y, frame.size.width - 6 - _icon.frame.size.height - 8, frame.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation BuffersTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _data = nil;
        _selectedRow = -1;
        _expandedArchives = [[NSMutableDictionary alloc] init];
        _firstHighlightPosition = -1;
        _firstUnreadPosition = -1;
        _lastHighlightPosition = -1;
        _lastUnreadPosition = -1;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)refresh {
    NSMutableArray *data = [[NSMutableArray alloc] init];
    int archiveCount = 0;
    _firstHighlightPosition = -1;
    _firstUnreadPosition = -1;
    _lastHighlightPosition = -1;
    _lastUnreadPosition = -1;

    if(_selectedBuffer.archived)
        [_expandedArchives setObject:@YES forKey:@(_selectedBuffer.cid)];
    
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    for(Server *server in [[ServersDataSource sharedInstance] getServers]) {
        NSArray *buffers = [[BuffersDataSource sharedInstance] getBuffersForServer:server.cid];
        for(Buffer *buffer in buffers) {
            if([buffer.type isEqualToString:@"console"]) {
                int unread = 0;
                int highlights = 0;
                NSString *name = server.name;
                if(!name || name.length == 0)
                    name = server.hostname;
                unread = [[EventsDataSource sharedInstance] unreadCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                    unread = 0;
                [data addObject:@{
                 @"type":@TYPE_SERVER,
                 @"cid":@(buffer.cid),
                 @"bid":@(buffer.bid),
                 @"name":name,
                 @"unread":@(unread),
                 @"highlights":@(highlights),
                 @"archived":@0,
                 }];
                
                if(unread > 0 && _firstUnreadPosition == -1)
                    _firstUnreadPosition = data.count - 1;
                if(unread > 0 && (_lastUnreadPosition == -1 || _lastUnreadPosition < data.count - 1))
                    _lastUnreadPosition = data.count - 1;
                if(highlights > 0 && _firstHighlightPosition == -1)
                    _firstHighlightPosition = data.count - 1;
                if(highlights > 0 && (_lastHighlightPosition == -1 || _lastHighlightPosition < data.count - 1))
                    _lastHighlightPosition = data.count - 1;

                if(buffer.bid == _selectedBuffer.bid)
                    _selectedRow = data.count - 1;
                break;
            }
        }
        for(Buffer *buffer in buffers) {
            int type = -1;
            int key = 0;
            int joined = 1;
            if([buffer.type isEqualToString:@"channel"]) {
                type = TYPE_CHANNEL;
                Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:buffer.bid];
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
                int unread = 0;
                int highlights = 0;
                unread = [[EventsDataSource sharedInstance] unreadCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                if(type == TYPE_CHANNEL) {
                    if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                } else {
                    if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                    if(type == TYPE_CONVERSATION && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        highlights = 0;
                }
                [data addObject:@{
                 @"type":@(type),
                 @"cid":@(buffer.cid),
                 @"bid":@(buffer.bid),
                 @"name":buffer.name,
                 @"unread":@(unread),
                 @"highlights":@(highlights),
                 @"archived":@0,
                 @"key":@(key),
                 }];
                if(unread > 0 && _firstUnreadPosition == -1)
                    _firstUnreadPosition = data.count - 1;
                if(unread > 0 && (_lastUnreadPosition == -1 || _lastUnreadPosition < data.count - 1))
                    _lastUnreadPosition = data.count - 1;
                if(highlights > 0 && _firstHighlightPosition == -1)
                    _firstHighlightPosition = data.count - 1;
                if(highlights > 0 && (_lastHighlightPosition == -1 || _lastHighlightPosition < data.count - 1))
                    _lastHighlightPosition = data.count - 1;

                if(buffer.bid == _selectedBuffer.bid)
                    _selectedRow = data.count - 1;
            }
            if(buffer.archived > 0)
                archiveCount++;
        }
        if(archiveCount > 0) {
            [data addObject:@{@"type":@(TYPE_ARCHIVES_HEADER), @"name":@"Archives", @"cid":@(server.cid)}];
            if([_expandedArchives objectForKey:@(server.cid)]) {
                for(Buffer *buffer in buffers) {
                    int type = -1;
                    if(buffer.archived && ![buffer.type isEqualToString:@"console"]) {
                        if([buffer.type isEqualToString:@"channel"]) {
                            type = TYPE_CHANNEL;
                        } else if([buffer.type isEqualToString:@"conversation"]) {
                            type = TYPE_CONVERSATION;
                        }
                        [data addObject:@{
                         @"type":@(type),
                         @"cid":@(buffer.cid),
                         @"bid":@(buffer.bid),
                         @"name":buffer.name,
                         @"unread":@0,
                         @"highlights":@0,
                         @"archived":@1,
                         @"key":@0,
                         }];
                        if(buffer.bid == _selectedBuffer.bid)
                            _selectedRow = data.count - 1;
                    }
                }
            }
        }
    }
    _data = data;
    [self.tableView reloadData];
    [self _updateUnreadIndicators];
    if(_firstHighlightPosition != -1 && _firstHighlightPosition != _selectedRow)
        self.parentViewController.navigationItem.leftBarButtonItem.tintColor = [UIColor redColor];
    else if(_firstUnreadPosition != -1 && _firstUnreadPosition != _selectedRow)
        self.parentViewController.navigationItem.leftBarButtonItem.tintColor = [UIColor selectedBlueColor];
    else
        self.parentViewController.navigationItem.leftBarButtonItem.tintColor = nil;
}

-(void)_updateUnreadIndicators {
    NSArray *rows = [self.tableView indexPathsForVisibleRows];
    int first = [[rows objectAtIndex:0] row];
    int last = [[rows lastObject] row];
    
    if(_firstUnreadPosition != -1 && first > _firstUnreadPosition) {
        topUnreadIndicator.hidden = NO;
        topUnreadIndicator.alpha = 1; //TODO: animate this
        topUnreadIndicatorColor.backgroundColor = [UIColor selectedBlueColor];
    } else {
        topUnreadIndicator.hidden = YES;
        topUnreadIndicator.alpha = 0; //TODO: animate this
    }
    if((_lastHighlightPosition != -1 && first > _lastHighlightPosition) ||
       (_firstHighlightPosition != -1 && first > _firstHighlightPosition)) {
        topUnreadIndicator.hidden = NO;
        topUnreadIndicator.alpha = 1; //TODO: animate this
        topUnreadIndicatorColor.backgroundColor = [UIColor redColor];
    }

    if(_lastUnreadPosition != -1 && last < _lastUnreadPosition) {
        bottomUnreadIndicator.hidden = NO;
        bottomUnreadIndicator.alpha = 1; //TODO: animate this
        bottomUnreadIndicatorColor.backgroundColor = [UIColor selectedBlueColor];
    } else {
        bottomUnreadIndicator.hidden = YES;
        bottomUnreadIndicator.alpha = 0; //TODO: animate this
    }
    if((_firstHighlightPosition != -1 && last < _firstHighlightPosition) ||
       (_lastHighlightPosition != -1 && last < _lastHighlightPosition)) {
        bottomUnreadIndicator.hidden = NO;
        bottomUnreadIndicator.alpha = 1; //TODO: animate this
        bottomUnreadIndicatorColor.backgroundColor = [UIColor redColor];
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SERVER) {
        return 46;
    } else {
        return 40;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL selected = (indexPath.row == _selectedRow);
    BuffersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bufferscell"];
    if(!cell)
        cell = [[BuffersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bufferscell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.type = [[row objectForKey:@"type"] intValue];
    cell.label.text = [row objectForKey:@"name"];
    if([[row objectForKey:@"highlights"] intValue]) {
        cell.highlights.hidden = NO;
        cell.highlights.count = [NSString stringWithFormat:@"%@",[row objectForKey:@"highlights"]];
    } else {
        cell.highlights.hidden = YES;
    }
    if([[row objectForKey:@"unread"] intValue] || (selected && cell.type != TYPE_ARCHIVES_HEADER)) {
        if([[row objectForKey:@"archived"] intValue]) {
            cell.unreadIndicator.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        } else {
            cell.unreadIndicator.backgroundColor = [UIColor selectedBlueColor];
        }
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
                if([[row objectForKey:@"archived"] intValue]) {
                    cell.label.textColor = [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1];
                    cell.bg.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
                } else {
                    cell.label.textColor = [UIColor whiteColor];
                    cell.bg.backgroundColor = [UIColor selectedBlueColor];
                }
            } else {
                if([[row objectForKey:@"archived"] intValue]) {
                    cell.label.textColor = [UIColor timestampColor];
                    cell.bg.backgroundColor = [UIColor colorWithRed:0.957 green:0.957 blue:0.957 alpha:1];
                } else {
                    cell.label.textColor = [UIColor selectedBlueColor];
                    cell.bg.backgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
                }
            }
            break;
        case TYPE_ARCHIVES_HEADER:
            cell.icon.image = nil;
            cell.icon.hidden = YES;
            if([_expandedArchives objectForKey:[row objectForKey:@"cid"]]) {
                cell.label.textColor = [UIColor blackColor];
                cell.bg.backgroundColor = [UIColor timestampColor];
            } else {
                cell.label.textColor = [UIColor colorWithRed:0.133 green:0.133 blue:0.133 alpha:1];
                cell.bg.backgroundColor = [UIColor colorWithRed:0.949 green:0.969 blue:0.988 alpha:1];
            }
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
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER) {
        if([_expandedArchives objectForKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]])
            [_expandedArchives removeObjectForKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]];
        else
            [_expandedArchives setObject:@YES forKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]];
        [self refresh];
    } else {
        _selectedRow = indexPath.row;
        if(_delegate)
            [_delegate bufferSelected:[[[_data objectAtIndex:_selectedRow] objectForKey:@"bid"] intValue]];
    }
    [tableView reloadData];
}

-(void)setBuffer:(Buffer *)buffer {
    _selectedBuffer = buffer;
    [self refresh];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _updateUnreadIndicators];
}

-(IBAction)topUnreadIndicatorClicked:(id)sender {
    int first = [[[self.tableView indexPathsForVisibleRows] objectAtIndex:0] row] - 1;
    int pos = 0;
    
    for(int i = first; i >= 0; i--) {
        NSDictionary *d = [_data objectAtIndex:i];
        if([[d objectForKey:@"unread"] intValue] || [[d objectForKey:@"highlights"] intValue]) {
            pos = i - 1;
            break;
        }
    }

    if(pos < 0)
        pos = 0;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

-(IBAction)bottomUnreadIndicatorClicked:(id)sender {
    int last = [[[self.tableView indexPathsForVisibleRows] lastObject] row] + 1;
    int pos = _data.count - 1;
    
    for(int i = last; i  < _data.count; i++) {
        NSDictionary *d = [_data objectAtIndex:i];
        if([[d objectForKey:@"unread"] intValue] || [[d objectForKey:@"highlights"] intValue]) {
            pos = i + 1;
            break;
        }
    }

    if(pos > _data.count - 1)
        pos = _data.count - 1;
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

@end
