//
//  UsersTableView.m
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
        
        self.backgroundColor = [UIColor backgroundBlueColor];
        
        _label = self.textLabel;
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor blackColor];
        _label.font = [UIFont systemFontOfSize:16];

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
@end

@implementation UsersTableView

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
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
        case kIRCEventWhoList:
            if(!_refreshTimer) {
                _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_refreshTimer) userInfo:nil repeats:NO];
            }
            break;
        default:
            break;
    }
}

- (void)_refreshTimer {
    [self refresh];
    _refreshTimer = nil;
}

- (void)_addUsersFromList:(NSArray *)users heading:(NSString *)heading symbol:(NSString*)symbol headingColor:(UIColor *)headingColor countColor:(UIColor *)countColor headingBgColor:(UIColor *)headingBgColor groupColor:(UIColor *)groupColor borderColor:(UIColor *)borderColor data:(NSMutableArray *)data sectionTitles:(NSMutableArray *)sectionTitles sectionIndexes:(NSMutableArray *)sectionIndexes sectionSizes:(NSMutableArray *)sectionSizes {
    int first;
    if(users.count) {
        unichar lastChar = 0;
        [data addObject:@{
         @"type":@TYPE_HEADING,
         @"text":heading,
         @"color":headingColor,
         @"bgColor":headingBgColor,
         @"count":@(users.count),
         @"countColor":countColor,
         @"symbol":symbol
         }];
        int size = data.count;
        first = 1;
        for(User *user in users) {
            if(sectionTitles != nil) {
                if([[user.nick lowercaseString] characterAtIndex:0] != lastChar) {
                    lastChar = [[user.nick lowercaseString] characterAtIndex:0];
                    [sectionIndexes addObject:@(data.count)];
                    [sectionTitles addObject:[[user.nick uppercaseString] substringToIndex:1]];
                    [sectionSizes addObject:@(size)];
                    size = 1;
                } else {
                    size++;
                }
            }
            [data addObject:@{
             @"type":@TYPE_USER,
             @"text":user.nick,
             @"color":user.away?[UIColor timestampColor]:[UIColor blackColor],
             @"bgColor":groupColor,
             @"first":@(first),
             @"borderColor":borderColor
             }];
            first = 0;
        }
        if(sectionSizes != nil)
            [sectionSizes addObject:@(size)];
    }
}

- (void)setBuffer:(Buffer *)buffer {
    _buffer = buffer;
    [self refresh];
    if(_data.count)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)refresh {
    NSDictionary *PREFIX;
    Server *s = [[ServersDataSource sharedInstance] getServer:_buffer.cid];
    if(s) {
        PREFIX = s.PREFIX;
    }
    if(!PREFIX || PREFIX.count == 0)
        PREFIX = @{@"q":@"~", @"a":@"&", @"o":@"@", @"h":@"%", @"v":@"+"};
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    NSMutableArray *owners = [[NSMutableArray alloc] init];
    NSMutableArray *admins = [[NSMutableArray alloc] init];
    NSMutableArray *ops = [[NSMutableArray alloc] init];
    NSMutableArray *halfops = [[NSMutableArray alloc] init];
    NSMutableArray *voiced = [[NSMutableArray alloc] init];
    NSMutableArray *members = [[NSMutableArray alloc] init];
    NSMutableArray *sectionTitles = [[NSMutableArray alloc] init];
    NSMutableArray *sectionIndexes = [[NSMutableArray alloc] init];
    NSMutableArray *sectionSizes = [[NSMutableArray alloc] init];
    
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
    
    [self _addUsersFromList:owners heading:@"Owners" symbol:[PREFIX objectForKey:@"q"] headingColor:[UIColor whiteColor] countColor:[UIColor ownersLightColor] headingBgColor:[UIColor ownersHeadingColor] groupColor:[UIColor ownersGroupColor] borderColor:[UIColor ownersBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:admins heading:@"Admins" symbol:[PREFIX objectForKey:@"a"] headingColor:[UIColor whiteColor] countColor:[UIColor adminsLightColor] headingBgColor:[UIColor adminsHeadingColor] groupColor:[UIColor adminsGroupColor] borderColor:[UIColor adminsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:ops heading:@"Ops" symbol:[PREFIX objectForKey:@"o"] headingColor:[UIColor whiteColor] countColor:[UIColor opsLightColor] headingBgColor:[UIColor opsHeadingColor] groupColor:[UIColor opsGroupColor] borderColor:[UIColor opsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:halfops heading:@"Half Ops" symbol:[PREFIX objectForKey:@"h"] headingColor:[UIColor whiteColor] countColor:[UIColor halfopsLightColor] headingBgColor:[UIColor halfopsHeadingColor] groupColor:[UIColor halfopsGroupColor] borderColor:[UIColor halfopsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:voiced heading:@"Voiced" symbol:[PREFIX objectForKey:@"v"] headingColor:[UIColor whiteColor] countColor:[UIColor voicedLightColor] headingBgColor:[UIColor voicedHeadingColor] groupColor:[UIColor voicedGroupColor] borderColor:[UIColor voicedBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [sectionIndexes addObject:@(0)];
    [self _addUsersFromList:members heading:@"Members" symbol:@"" headingColor:[UIColor whiteColor] countColor:[UIColor whiteColor] headingBgColor:[UIColor selectedBlueColor] groupColor:[UIColor backgroundBlueColor] borderColor:[UIColor blueBorderColor] data:data sectionTitles:sectionTitles sectionIndexes:sectionIndexes sectionSizes:sectionSizes];
    if(sectionSizes.count == 0)
        [sectionSizes addObject:@(data.count)];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _data = data;
        _sectionTitles = sectionTitles;
        _sectionIndexes = sectionIndexes;
        _sectionSizes = sectionSizes;
        [self.tableView reloadData];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = YES;

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self.tableView addGestureRecognizer:lp];

    if(!delegate)
        delegate = (id<UsersTableViewDelegate>)[(UINavigationController *)(self.slidingViewController.topViewController) topViewController];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = [UIColor backgroundBlueColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [self refresh];
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
/*    if(_data.count > 20)
        return _sectionIndexes.count;
    else*/
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
/*    if(_data.count > 20)
        return [[_sectionSizes objectAtIndex:section] intValue];
    else*/
        return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 32;
}

/*-(NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if(_data.count > 20)
        return _sectionTitles;
    else
        return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 0)
        return nil;
    else
        return [_sectionTitles objectAtIndex:section - 1];
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UsersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"userscell"];
    if(!cell)
        cell = [[UsersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"userscell"];
    int idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
    NSDictionary *row = [_data objectAtIndex:idx];
    cell.type = [[row objectForKey:@"type"] intValue];
    cell.contentView.backgroundColor = [row objectForKey:@"bgColor"];
    cell.label.text = [row objectForKey:@"text"];
    cell.label.textColor = [row objectForKey:@"color"];
    if([[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"mode-showsymbol"] boolValue])
        cell.count.text = [NSString stringWithFormat:@"%@ %@", [row objectForKey:@"symbol"], [row objectForKey:@"count"]];
    else
        cell.count.text = [NSString stringWithFormat:@"%@", [row objectForKey:@"count"]];
    cell.count.textColor = [row objectForKey:@"countColor"];
    if(cell.type == TYPE_HEADING) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
#ifdef __IPHONE_7_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.label.font = [UIFont fontWithName:cell.label.font.fontName size:cell.label.font.pointSize * 0.8];
            cell.count.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.count.font = [UIFont fontWithName:cell.count.font.fontName size:cell.count.font.pointSize * 0.8];
        }
#endif
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
#ifdef __IPHONE_7_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
            cell.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.label.font = [UIFont fontWithName:cell.label.font.fontName size:cell.label.font.pointSize * 0.8];
        }
#endif
    }
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
    int idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
    if([[[_data objectAtIndex:idx] objectForKey:@"type"] intValue] == TYPE_USER)
        [delegate userSelected:[[_data objectAtIndex:idx] objectForKey:@"text"] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                int idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
                if([[[_data objectAtIndex:idx] objectForKey:@"type"] intValue] == TYPE_USER)
                    [delegate userSelected:[[_data objectAtIndex:idx] objectForKey:@"text"] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    }
}

@end
