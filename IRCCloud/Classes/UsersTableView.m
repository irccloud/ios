//
//  UsersTableView.m
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "UsersTableView.h"
#import "NetworkConnection.h"
#import "UsersDataSource.h"
#import "UIColor+IRCCloud.h"
#import "ECSlidingViewController.h"

#define TYPE_HEADING 0
#define TYPE_USER 1

@interface UsersTableCell : UITableViewCell {
    UILabel *_label;
    UILabel *_count;
    UIView *_border;
    int _type;
}
@property int type;
@property (readonly) UILabel *label,*count;
@property (readonly) UIView *border;
@end

@implementation UsersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor backgroundBlueColor];
        
        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor blackColor];
        _label.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_label];

        _count = [[UILabel alloc] init];
        _count.backgroundColor = [UIColor clearColor];
        _count.textColor = [UIColor grayColor];
        _count.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_count];
        
        _border = [[UIView alloc] init];
        [self.contentView addSubview:_border];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    _border.frame = CGRectMake(0,0,frame.size.width,1);

    frame.origin.x = 12;
    frame.size.width -= 24;
    
    if(_type == TYPE_HEADING) {
        float countWidth = [_count.text sizeWithFont:_count.font].width;
        _count.frame = CGRectMake(frame.origin.x + frame.size.width - countWidth, frame.origin.y, countWidth, frame.size.height);
        _count.hidden = NO;
        _label.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - countWidth - 6, frame.size.height);
    } else {
        _count.hidden = YES;
        _label.frame = frame;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation UsersTableView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.15];
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    switch(event) {
        case kIRCEventUserInfo:
        case kIRCEventChannelInit:
        case kIRCEventJoin:
        case kIRCEventPart:
        case kIRCEventQuit:
        case kIRCEventNickChange:
        case kIRCEventMemberUpdates:
        case kIRCEventUserChannelMode:
        case kIRCEventKick:
            //[self refresh];
            break;
        default:
            break;
    }
}

- (void)_addUsersFromList:(NSArray *)users heading:(NSString *)heading headingColor:(UIColor *)headingColor countColor:(UIColor *)countColor headingBgColor:(UIColor *)headingBgColor groupColor:(UIColor *)groupColor borderColor:(UIColor *)borderColor data:(NSMutableArray *)data {
    int first;
    if(users.count) {
        [data addObject:@{
         @"type":@TYPE_HEADING,
         @"text":heading,
         @"color":headingColor,
         @"bgColor":headingBgColor,
         @"count":@(users.count),
         @"countColor":countColor
         }];
        first = 1;
        for(User *user in users) {
            [data addObject:@{
             @"type":@TYPE_USER,
             @"text":user.nick,
             @"color":[UIColor blackColor],
             @"bgColor":groupColor,
             @"first":@(first),
             @"borderColor":borderColor
             }];
            first = 0;
        }
    }
}

- (void)setBuffer:(Buffer *)buffer {
    _buffer = buffer;
    [self refresh];
}

- (void)refresh {
    @synchronized(_data) {
        NSMutableArray *data = [[NSMutableArray alloc] init];
        NSMutableArray *owners = [[NSMutableArray alloc] init];
        NSMutableArray *admins = [[NSMutableArray alloc] init];
        NSMutableArray *ops = [[NSMutableArray alloc] init];
        NSMutableArray *halfops = [[NSMutableArray alloc] init];
        NSMutableArray *voiced = [[NSMutableArray alloc] init];
        NSMutableArray *members = [[NSMutableArray alloc] init];
        
        for(User *user in [[UsersDataSource sharedInstance] usersForBuffer:_buffer.bid]) {
            if([user.mode rangeOfString:@"q"].location != NSNotFound)
                [owners addObject:user];
            else if([user.mode rangeOfString:@"a"].location != NSNotFound)
                [admins addObject:user];
            else if([user.mode rangeOfString:@"o"].location != NSNotFound)
                [ops addObject:user];
            else if([user.mode rangeOfString:@"h"].location != NSNotFound)
                [halfops addObject:user];
            else if([user.mode rangeOfString:@"v"].location != NSNotFound)
                [voiced addObject:user];
            else
                [members addObject:user];
        }
        
        [self _addUsersFromList:owners heading:@"Owners" headingColor:[UIColor whiteColor] countColor:[UIColor ownersLightColor] headingBgColor:[UIColor ownersHeadingColor] groupColor:[UIColor ownersGroupColor] borderColor:[UIColor ownersBorderColor] data:data];
        [self _addUsersFromList:admins heading:@"Admins" headingColor:[UIColor whiteColor] countColor:[UIColor adminsLightColor] headingBgColor:[UIColor adminsHeadingColor] groupColor:[UIColor adminsGroupColor] borderColor:[UIColor adminsBorderColor] data:data];
        [self _addUsersFromList:ops heading:@"Ops" headingColor:[UIColor whiteColor] countColor:[UIColor opsLightColor] headingBgColor:[UIColor opsHeadingColor] groupColor:[UIColor opsGroupColor] borderColor:[UIColor opsBorderColor] data:data];
        [self _addUsersFromList:halfops heading:@"Half Ops" headingColor:[UIColor whiteColor] countColor:[UIColor halfopsLightColor] headingBgColor:[UIColor halfopsHeadingColor] groupColor:[UIColor halfopsGroupColor] borderColor:[UIColor halfopsBorderColor] data:data];
        [self _addUsersFromList:voiced heading:@"Voiced" headingColor:[UIColor whiteColor] countColor:[UIColor voicedLightColor] headingBgColor:[UIColor voicedHeadingColor] groupColor:[UIColor voicedGroupColor] borderColor:[UIColor voicedBorderColor] data:data];
        [self _addUsersFromList:members heading:@"Members" headingColor:[UIColor whiteColor] countColor:[UIColor whiteColor] headingBgColor:[UIColor selectedBlueColor] groupColor:[UIColor backgroundBlueColor] borderColor:[UIColor lightGrayColor] data:data];
        
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            _data = data;
            [self.tableView reloadData];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = NO;
    
    if(self.slidingViewController) {
        delegate = (id<UsersTableViewDelegate>)[(UINavigationController *)(self.slidingViewController.topViewController) topViewController];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.view.backgroundColor = [UIColor backgroundBlueColor];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    return 32;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UsersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userscell"];
    if(!cell)
        cell = [[UsersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"userscell"];
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    cell.type = [[row objectForKey:@"type"] intValue];
    cell.contentView.backgroundColor = [row objectForKey:@"bgColor"];
    cell.label.text = [row objectForKey:@"text"];
    cell.label.textColor = [row objectForKey:@"color"];
    cell.count.text = [[row objectForKey:@"count"] description];
    cell.count.textColor = [row objectForKey:@"countColor"];
    if(cell.type == TYPE_HEADING || [[row objectForKey:@"first"] intValue]) {
        cell.border.hidden = YES;
    } else {
        cell.border.hidden = NO;
        cell.border.backgroundColor = [row objectForKey:@"borderColor"];
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

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [delegate dismissKeyboard];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if([[[_data objectAtIndex:[indexPath row]] objectForKey:@"type"] intValue] == TYPE_USER)
        [delegate userSelected:[[_data objectAtIndex:[indexPath row]] objectForKey:@"text"] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
}

@end
