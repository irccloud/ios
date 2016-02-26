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
#import "ColorFormatter.h"

#define TYPE_HEADING 0
#define TYPE_USER 1

@interface UsersTableCell : UITableViewCell {
    UILabel *_label;
    UILabel *_count;
    UIView *_border1;
    UIView *_border2;
    int _type;
    UIColor *_bgColor;
    UIColor *_fgColor;
}
@property int type;
@property (readonly) UILabel *label,*count;
@property (readonly) UIView *border1, *border2;
@property UIColor *bgColor, *fgColor;
@end

@implementation UsersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.backgroundColor = [UIColor membersGroupColor];
        
        _label = self.textLabel;
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor blackColor];
        _label.font = [UIFont systemFontOfSize:16];

        _count = [[UILabel alloc] init];
        _count.backgroundColor = [UIColor clearColor];
        _count.textColor = [UIColor grayColor];
        _count.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:_count];
        
        _border1 = [[UIView alloc] init];
        [self.contentView addSubview:_border1];
        
        _border2 = [[UIView alloc] init];
        [self.contentView addSubview:_border2];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	CGRect frame = [self.contentView bounds];
    _border1.frame = CGRectMake(0,frame.size.height - 1,frame.size.width,1);
    _border2.frame = CGRectMake(0,0,3,frame.size.height);

    frame.origin.x = 12;
    frame.size.width -= 24;
    
    if(_type == TYPE_HEADING) {
        float countWidth = [_count.text sizeWithAttributes:@{NSFontAttributeName:_count.font}].width;
        _count.frame = CGRectMake(frame.origin.x + frame.size.width - countWidth, frame.origin.y, countWidth, frame.size.height);
        _count.hidden = NO;
        _label.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - countWidth - 6, frame.size.height);
    } else {
        _count.hidden = YES;
        _label.frame = frame;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if(self.selected || _type == TYPE_HEADING)
        highlighted = NO;
    self.contentView.backgroundColor = highlighted?_border1.backgroundColor:_bgColor;
    _label.textColor = highlighted?[UIColor whiteColor]:_fgColor;
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
    _refreshTimer = nil;
    [self refresh];
}

- (void)_addUsersFromList:(NSArray *)users heading:(NSString *)heading symbol:(NSString*)symbol groupColor:(UIColor *)groupColor borderColor:(UIColor *)borderColor data:(NSMutableArray *)data sectionTitles:(NSMutableArray *)sectionTitles sectionIndexes:(NSMutableArray *)sectionIndexes sectionSizes:(NSMutableArray *)sectionSizes {
    if(users.count && symbol) {
        unichar lastChar = 0;
        [data addObject:@{
         @"type":@TYPE_HEADING,
         @"text":heading,
         @"color":[UIColor whiteColor],
         @"bgColor":borderColor,
         @"count":@(users.count),
         @"countColor":[UIColor whiteColor],
         @"symbol":symbol
         }];
        NSUInteger size = data.count;
        for(User *user in users) {
            if(sectionTitles != nil) {
                if(user.nick.length && [[user.nick lowercaseString] characterAtIndex:0] != lastChar) {
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
             @"color":user.away?[UIColor memberListAwayTextColor]:[UIColor memberListTextColor],
             @"bgColor":groupColor,
             @"last":@(user == users.lastObject && ![heading isEqualToString:@"Members"]),
             @"borderColor":borderColor
             }];
        }
        if(sectionSizes != nil)
            [sectionSizes addObject:@(size)];
    }
}

- (void)setBuffer:(Buffer *)buffer {
    _buffer = buffer;
    _refreshTimer = nil;
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
    if(!PREFIX || PREFIX.count == 0) {
        PREFIX = @{s?s.MODE_OWNER:@"q":@"~",
                   s?s.MODE_ADMIN:@"a":@"&",
                   s?s.MODE_OP:@"o":@"@",
                   s?s.MODE_HALFOP:@"h":@"%",
                   s?s.MODE_VOICED:@"v":@"+"};
    }
    
    NSMutableArray *data = [[NSMutableArray alloc] init];
    NSMutableArray *opers = [[NSMutableArray alloc] init];
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
        if(user.nick.length) {
            NSString *mode = user.mode.lowercaseString;
            if([mode rangeOfString:s?s.MODE_OPER.lowercaseString:@"y"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_OPER:@"y"])
                [opers addObject:user];
            else if([mode rangeOfString:s?s.MODE_OWNER.lowercaseString:@"q"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_OWNER:@"q"])
                [owners addObject:user];
            else if([mode rangeOfString:s?s.MODE_ADMIN.lowercaseString:@"a"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_ADMIN:@"a"])
                [admins addObject:user];
            else if([mode rangeOfString:s?s.MODE_OP.lowercaseString:@"o"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_OP:@"o"])
                [ops addObject:user];
            else if([mode rangeOfString:s?s.MODE_HALFOP.lowercaseString:@"h"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_HALFOP:@"h"])
                [halfops addObject:user];
            else if([mode rangeOfString:s?s.MODE_VOICED.lowercaseString:@"v"].location != NSNotFound && [PREFIX objectForKey:s?s.MODE_VOICED:@"v"])
                [voiced addObject:user];
            else
                [members addObject:user];
        }
    }
    
    NSString *operPrefix = [PREFIX objectForKey:s?s.MODE_OPER:@"Y"];
    if(!operPrefix)
        operPrefix = [PREFIX objectForKey:s?s.MODE_OPER.lowercaseString:@"y"];
    
    [self _addUsersFromList:opers heading:@"Opers" symbol:operPrefix groupColor:[UIColor opersGroupColor] borderColor:[UIColor opersBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:owners heading:@"Owners" symbol:[PREFIX objectForKey:s?s.MODE_OWNER:@"q"] groupColor:[UIColor ownersGroupColor] borderColor:[UIColor ownersBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:admins heading:@"Admins" symbol:[PREFIX objectForKey:s?s.MODE_ADMIN:@"a"] groupColor:[UIColor adminsGroupColor] borderColor:[UIColor adminsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:ops heading:@"Ops" symbol:[PREFIX objectForKey:s?s.MODE_OP:@"o"] groupColor:[UIColor opsGroupColor] borderColor:[UIColor opsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:halfops heading:@"Half Ops" symbol:[PREFIX objectForKey:s?s.MODE_HALFOP:@"h"] groupColor:[UIColor halfopsGroupColor] borderColor:[UIColor halfopsBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [self _addUsersFromList:voiced heading:@"Voiced" symbol:[PREFIX objectForKey:s?s.MODE_VOICED:@"v"] groupColor:[UIColor voicedGroupColor] borderColor:[UIColor voicedBorderColor] data:data sectionTitles:nil sectionIndexes:nil sectionSizes:nil];
    [sectionIndexes addObject:@(0)];
    [self _addUsersFromList:members heading:@"Members" symbol:@"" groupColor:[UIColor membersGroupColor] borderColor:[UIColor membersBorderColor] data:data sectionTitles:sectionTitles sectionIndexes:sectionIndexes sectionSizes:sectionSizes];
    if(sectionSizes.count == 0)
        [sectionSizes addObject:@(data.count)];
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([[[NetworkConnection sharedInstance].prefs objectForKey:@"font"] isEqualToString:@"mono"]) {
            _headingFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
            _countFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
            _userFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
        } else {
            UIFontDescriptor *d = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
            _headingFont = _countFont = _userFont = [UIFont fontWithDescriptor:d size:FONT_SIZE];
        }
        
        _refreshTimer = nil;
        _data = data;
        _sectionTitles = sectionTitles;
        _sectionIndexes = sectionIndexes;
        _sectionSizes = sectionSizes;
        [self.tableView reloadData];
        self.tableView.backgroundColor = [UIColor usersDrawerBackgroundColor];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = NO;

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self.tableView addGestureRecognizer:lp];

    if(!delegate)
        delegate = (id<UsersTableViewDelegate>)[(UINavigationController *)(self.slidingViewController.topViewController) topViewController];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = [UIColor usersDrawerBackgroundColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kIRCCloudBacklogCompletedNotification object:nil];
    
    _refreshTimer = nil;

    if([[[NetworkConnection sharedInstance].prefs objectForKey:@"font"] isEqualToString:@"mono"]) {
        _headingFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
        _countFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
        _userFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
    } else {
        UIFontDescriptor *d = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        _headingFont = _countFont = _userFont = [UIFont fontWithDescriptor:d size:FONT_SIZE];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    if([[[NetworkConnection sharedInstance].prefs objectForKey:@"font"] isEqualToString:@"mono"]) {
        _headingFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
        _countFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
        _userFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE];
    } else {
        UIFontDescriptor *d = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        _headingFont = _countFont = _userFont = [UIFont fontWithDescriptor:d size:FONT_SIZE];
    }
    [self.tableView reloadData];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [self refresh];
    _refreshTimer = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _refreshTimer = nil;
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
    NSUInteger idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
    NSDictionary *row = [_data objectAtIndex:idx];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.type = [[row objectForKey:@"type"] intValue];
    cell.bgColor = [row objectForKey:@"bgColor"];
    cell.label.text = [row objectForKey:@"text"];
    cell.fgColor = [row objectForKey:@"color"];
    if([[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"mode-showsymbol"] boolValue])
        cell.count.text = [NSString stringWithFormat:@"%@ %@", [row objectForKey:@"symbol"], [row objectForKey:@"count"]];
    else
        cell.count.text = [NSString stringWithFormat:@"%@", [row objectForKey:@"count"]];
    cell.count.textColor = [row objectForKey:@"countColor"];
    if(cell.type == TYPE_HEADING) {
        if(_headingFont)
            cell.label.font = _headingFont;
        
        if(_countFont)
            cell.count.font = _countFont;
    } else {
        if(_userFont)
            cell.label.font = _userFont;
    }
    if(cell.type == TYPE_HEADING || ![[row objectForKey:@"last"] intValue]) {
        cell.border1.hidden = YES;
    } else {
        cell.border1.hidden = ![UIColor isDarkTheme];
    }
    cell.border1.backgroundColor = [row objectForKey:@"borderColor"];
    cell.border2.hidden = ![UIColor isDarkTheme];
    cell.border2.backgroundColor = [row objectForKey:@"borderColor"];
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
    if([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        [delegate dismissKeyboard];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSUInteger idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
    if([[[_data objectAtIndex:idx] objectForKey:@"type"] intValue] == TYPE_USER)
        [delegate userSelected:[[_data objectAtIndex:idx] objectForKey:@"text"] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                NSUInteger idx = [[_sectionIndexes objectAtIndex:indexPath.section] intValue] + indexPath.row;
                if([[[_data objectAtIndex:idx] objectForKey:@"type"] intValue] == TYPE_USER)
                    [delegate userSelected:[[_data objectAtIndex:idx] objectForKey:@"text"] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    }
}

@end
