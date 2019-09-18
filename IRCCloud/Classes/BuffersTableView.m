//
//  BuffersTableView.m
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


#import "BuffersTableView.h"
#import "NetworkConnection.h"
#import "ServersDataSource.h"
#import "UIColor+IRCCloud.h"
#import "HighlightsCountView.h"
#import "ECSlidingViewController.h"
#import "EditConnectionViewController.h"
#import "ServerReorderViewController.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "ColorFormatter.h"
#import "FontAwesome.h"
#import "EventsTableView.h"
#import "MainViewController.h"

#define TYPE_SERVER 0
#define TYPE_CHANNEL 1
#define TYPE_CONVERSATION 2
#define TYPE_ARCHIVES_HEADER 3
#define TYPE_JOIN_CHANNEL 4
#define TYPE_SPAM 5
#define TYPE_COLLAPSED 6

@interface BuffersTableCell : UITableViewCell {
    UILabel *_label;
    UILabel *_icon;
    UILabel *_spamHint;
    int _type;
    UIView *_unreadIndicator;
    UIView *_bg;
    UIView *_border;
    HighlightsCountView *_highlights;
    UIActivityIndicatorView *_activity;
    UIColor *_bgColor;
    UIColor *_highlightColor;
    CGFloat _borderInset;
}
@property int type;
@property UIColor *bgColor, *highlightColor;
@property CGFloat borderInset;
@property (readonly) UILabel *label, *icon;
@property (readonly) UIView *unreadIndicator, *bg, *border;
@property (readonly) HighlightsCountView *highlights;
@property (readonly) UIActivityIndicatorView *activity;
@end

@implementation BuffersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self->_type = 0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self->_bg = [[UIView alloc] init];
        [self.contentView addSubview:self->_bg];
        
        self->_border = [[UIView alloc] init];
        [self.contentView addSubview:self->_border];
        
        self->_unreadIndicator = [[UIView alloc] init];
        self->_unreadIndicator.backgroundColor = [UIColor unreadBlueColor];
        [self.contentView addSubview:self->_unreadIndicator];
        
        self->_icon = [[UILabel alloc] init];
        self->_icon.backgroundColor = [UIColor clearColor];
        self->_icon.textColor = [UIColor bufferTextColor];
        self->_icon.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self->_icon];

        self->_label = [[UILabel alloc] init];
        self->_label.backgroundColor = [UIColor clearColor];
        self->_label.textColor = [UIColor bufferTextColor];
        [self.contentView addSubview:self->_label];
        
        self->_highlights = [[HighlightsCountView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:self->_highlights];
        
        self->_activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        self->_activity.hidden = YES;
        [self.contentView addSubview:self->_activity];
        
        self->_spamHint = [[UILabel alloc] init];
        self->_spamHint.text = @"Tap here to choose conversations to delete";
        self->_spamHint.numberOfLines = 0;
        [self.contentView addSubview:self->_spamHint];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
    CGRect frame = [self.contentView bounds];
    frame.origin.x += self->_borderInset;
    frame.size.width -= self->_borderInset;
    self->_border.frame = CGRectMake(frame.origin.x - _borderInset, frame.origin.y, 6 + _borderInset, frame.size.height);
    frame.size.width -= 8;
    if(self->_type == TYPE_SERVER) {
        frame.origin.y += 6;
        frame.size.height -= 6;
    }
    self->_bg.frame = CGRectMake(frame.origin.x + 6, frame.origin.y, frame.size.width - 6, frame.size.height);
    self->_unreadIndicator.frame = CGRectMake(frame.origin.x, frame.origin.y, 6, frame.size.height);
    self->_icon.frame = CGRectMake(frame.origin.x + 12, frame.origin.y + ((self->_type == TYPE_COLLAPSED)?8:10), 16, 18);
    if(!_activity.hidden) {
        frame.size.width -= self->_activity.frame.size.width + 12;
        self->_activity.frame = CGRectMake(frame.origin.x + 6 + frame.size.width, frame.origin.y + 10, _activity.frame.size.width, _activity.frame.size.height);
    }
    if(!_highlights.hidden) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        CGSize size = [self->_highlights.count sizeWithFont:self->_highlights.font];
#pragma GCC diagnostic pop
        size.width += 0;
        size.height = frame.size.height - 16;
        if(size.width < size.height)
            size.width = size.height;
        frame.size.width -= size.width + 12;
        self->_highlights.frame = CGRectMake(frame.origin.x + 6 + frame.size.width, frame.origin.y + 6, size.width, size.height);
    }
    self->_label.frame = CGRectMake(frame.origin.x + 12 + _icon.frame.size.width + 6, (self->_type == TYPE_SPAM)?_icon.frame.origin.y-1:frame.origin.y, frame.size.width - 6 - _icon.frame.size.width - 16, (self->_type == TYPE_SPAM)?_icon.frame.size.width:frame.size.height);
    
    if(self->_type == TYPE_SPAM) {
        self->_spamHint.textColor = self->_label.textColor;
        self->_spamHint.font = [self->_label.font fontWithSize:self->_label.font.pointSize - 2];
        self->_spamHint.frame = CGRectMake(self->_label.frame.origin.x, _label.frame.origin.y + _label.frame.size.height, _label.frame.size.width, frame.size.height - _label.frame.size.height - _label.frame.origin.y);
        self->_spamHint.hidden = NO;
    } else {
        self->_spamHint.hidden = YES;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if(!self.selected)
        self->_bg.backgroundColor = highlighted?_highlightColor:self->_bgColor;
}

@end

@implementation BuffersTableView

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self->_data = nil;
        self->_expandedCids = [[NSMutableDictionary alloc] init];
        self->_selectedRow = -1;
        self->_expandedArchives = [[NSMutableDictionary alloc] init];
        self->_firstHighlightPosition = -1;
        self->_firstUnreadPosition = -1;
        self->_lastHighlightPosition = -1;
        self->_lastUnreadPosition = -1;
        self->_servers = [ServersDataSource sharedInstance];
        self->_buffers = [BuffersDataSource sharedInstance];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self->_data = nil;
        self->_expandedCids = [[NSMutableDictionary alloc] init];
        self->_selectedRow = -1;
        self->_expandedArchives = [[NSMutableDictionary alloc] init];
        self->_firstHighlightPosition = -1;
        self->_firstUnreadPosition = -1;
        self->_lastHighlightPosition = -1;
        self->_lastUnreadPosition = -1;
        self->_servers = [ServersDataSource sharedInstance];
        self->_buffers = [BuffersDataSource sharedInstance];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadData];
        [self _updateUnreadIndicators];
    }
     ];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [self performSelectorInBackground:@selector(refresh) withObject:nil];
}

- (void)refresh {
    @synchronized(self->_data) {
        NSMutableArray *data = [[NSMutableArray alloc] init];
        NSInteger archiveCount = 0;
        NSInteger firstHighlightPosition = -1;
        NSInteger firstUnreadPosition = -1;
        NSInteger firstFailurePosition = -1;
        NSInteger lastHighlightPosition = -1;
        NSInteger lastUnreadPosition = -1;
        NSInteger lastFailurePosition = -1;
        NSInteger selectedRow = -1;
        
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        
        for(Server *server in [self->_servers getServers]) {
            NSMutableDictionary *collapsed;
            int collapsed_unread = 0;
            int collapsed_highlights = 0;
#ifndef EXTENSION
            NSUInteger collapsed_row = data.count;
            int spamCount = 0;
#endif
            archiveCount = server.deferred_archives;
            NSArray *buffers = [self->_buffers getBuffersForServer:server.cid];
            for(Buffer *buffer in buffers) {
                if([buffer.type isEqualToString:@"console"]) {
                    int unread = 0;
                    int highlights = 0;
                    NSString *name = server.name;
                    if(!name || name.length == 0)
                        name = server.hostname;
                    unread = [[EventsDataSource sharedInstance] unreadStateForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                    highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
                    if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                        unread = 0;
                    [data addObject:@{
                     @"type":@TYPE_SERVER,
                     @"cid":@(buffer.cid),
                     @"bid":@(buffer.bid),
                     @"name":name,
                     @"hint":name,
                     @"unread":@(unread),
                     @"highlights":@(highlights),
                     @"archived":@0,
                     @"status":server.status ? server.status : @"",
                     @"fail_info":server.fail_info ? server.fail_info : @{},
                     @"ssl":@(server.ssl),
                     @"slack":@(server.isSlack),
                     @"count":@(buffers.count)
                     }];
                    
                    if(unread > 0 && firstUnreadPosition == -1)
                        firstUnreadPosition = data.count - 1;
                    if(unread > 0 && (lastUnreadPosition == -1 || lastUnreadPosition < data.count - 1))
                        lastUnreadPosition = data.count - 1;
                    if(highlights > 0 && firstHighlightPosition == -1)
                        firstHighlightPosition = data.count - 1;
                    if(highlights > 0 && (lastHighlightPosition == -1 || lastHighlightPosition < data.count - 1))
                        lastHighlightPosition = data.count - 1;
                    if(server.fail_info.count > 0 && firstFailurePosition == -1)
                        firstFailurePosition = data.count - 1;
                    if(server.fail_info.count > 0 && (lastFailurePosition == -1 || lastFailurePosition < data.count - 1))
                        lastFailurePosition = data.count - 1;

                    if(buffer.bid == self->_selectedBuffer.bid)
                        selectedRow = data.count - 1;
                    
#ifndef ENTERPRISE
#ifndef EXTENSION
                    if(buffer.archived || [self->_expandedCids objectForKey:@(buffer.cid)]) {
                        collapsed = [[NSMutableDictionary alloc] init];
                        [collapsed setObject:@TYPE_COLLAPSED forKey:@"type"];
                        [collapsed setObject:@(buffer.cid) forKey:@"cid"];
                        [collapsed setObject:@(buffer.bid) forKey:@"bid"];
                        [collapsed setObject:@(buffer.archived) forKey:@"archived"];
                        [collapsed setObject:@(collapsed_row) forKey:@"row"];
                        server.collapsed = collapsed;
                    }
#endif
#endif
                    break;
                }
            }
            if(collapsed)
                [data addObject:collapsed];
            for(Buffer *buffer in buffers) {
                int type = -1;
                int key = 0;
                int joined = 1;
                if([buffer.type isEqualToString:@"channel"] || buffer.isMPDM) {
                    type = buffer.isMPDM ? TYPE_CONVERSATION : TYPE_CHANNEL;
                    Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:buffer.bid];
                    if(channel) {
                        if(channel.key || (buffer.serverIsSlack && !buffer.isMPDM && [channel hasMode:@"s"]))
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
                    unread = [[EventsDataSource sharedInstance] unreadStateForBuffer:buffer.bid lastSeenEid:buffer.last_seen_eid type:buffer.type];
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
                    if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
                        if(type == TYPE_CHANNEL) {
                            if([[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] != 1)
                                unread = 0;
                        }
                    }
                    
                    if(buffer.bid == self->_selectedBuffer.bid || !collapsed || [self->_expandedCids objectForKey:@(buffer.cid)]) {
                        [data addObject:@{
                         @"type":@(type),
                         @"cid":@(buffer.cid),
                         @"bid":@(buffer.bid),
                         @"name":buffer.displayName?buffer.displayName:buffer.name,
                         @"unread":@(unread),
                         @"highlights":@(highlights),
                         @"archived":@0,
                         @"joined":@(joined),
                         @"key":@(key),
                         @"timeout":@(buffer.timeout),
                         @"hint":buffer.accessibilityValue?buffer.accessibilityValue:@"",
                         @"status":server.status
                         }];
                    }
                    if(unread > 0 && firstUnreadPosition == -1)
                        firstUnreadPosition = data.count - 1;
                    if(unread > 0 && (lastUnreadPosition == -1 || lastUnreadPosition < data.count - 1))
                        lastUnreadPosition = data.count - 1;
                    if(highlights > 0 && firstHighlightPosition == -1)
                        firstHighlightPosition = data.count - 1;
                    if(highlights > 0 && (lastHighlightPosition == -1 || lastHighlightPosition < data.count - 1))
                        lastHighlightPosition = data.count - 1;
#ifndef EXTENSION
                    if(type == TYPE_CONVERSATION && unread == 1 && [[EventsDataSource sharedInstance] sizeOfBuffer:buffer.bid] == 1)
                        spamCount++;
#endif
                    collapsed_unread += unread;
                    collapsed_highlights += highlights;

                    if(buffer.bid == self->_selectedBuffer.bid)
                        selectedRow = data.count - 1;
                    
                }
                if(type > 0 && buffer.archived > 0)
                    archiveCount++;
            }
#ifndef EXTENSION
            if(spamCount > 3 && (!collapsed || [self->_expandedCids objectForKey:@(server.cid)])) {
                for(int i = 0; i < data.count; i++) {
                    NSDictionary *d = [data objectAtIndex:i];
                    if([[d objectForKey:@"cid"] intValue] == server.cid && [[d objectForKey:@"type"] intValue] == TYPE_CONVERSATION) {
                        [data insertObject:@{@"type":@(TYPE_SPAM), @"name":@"Spam Detected", @"cid":@(server.cid)} atIndex:i];
                        break;
                    }
                }
            }
            
            if(collapsed) {
                if([self->_expandedCids objectForKey:@(server.cid)]) {
                    [collapsed setObject:@"Collapse" forKey:@"name"];
                    [collapsed setObject:FA_MINUS_SQUARE_O forKey:@"icon"];
                } else {
                    [collapsed setObject:@"Expand" forKey:@"name"];
                    [collapsed setObject:FA_PLUS_SQUARE_O forKey:@"icon"];
                    [collapsed setObject:@(collapsed_unread) forKey:@"unread"];
                    [collapsed setObject:@(collapsed_highlights) forKey:@"highlights"];
                }

                if(collapsed_unread > 0 && firstUnreadPosition == -1)
                    firstUnreadPosition = collapsed_row;
                if(collapsed_unread > 0 && (lastUnreadPosition == -1 || lastUnreadPosition < collapsed_row))
                    lastUnreadPosition = collapsed_row;
                if(collapsed_highlights > 0 && firstHighlightPosition == -1)
                    firstHighlightPosition = collapsed_row;
                if(collapsed_highlights > 0 && (lastHighlightPosition == -1 || lastHighlightPosition < collapsed_row))
                    lastHighlightPosition = collapsed_row;

            }
            collapsed_unread = collapsed_highlights = 0;
#endif
            if((!collapsed || [self->_expandedCids objectForKey:@(server.cid)]) && archiveCount > 0) {
                [data addObject:@{@"type":@(TYPE_ARCHIVES_HEADER), @"name":@"Archives", @"cid":@(server.cid)}];
                if([self->_expandedArchives objectForKey:@(server.cid)]) {
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
                             @"name":buffer.displayName?buffer.displayName:buffer.name,
                             @"unread":@0,
                             @"highlights":@0,
                             @"archived":@1,
                             @"hint":buffer.accessibilityValue?buffer.accessibilityValue:@"",
                             @"key":@0,
                             }];
                            if(buffer.bid == self->_selectedBuffer.bid)
                                selectedRow = data.count - 1;
                        }
                    }
                }
            }
            if(buffers.count == 1 && [server.status isEqualToString:@"connected_ready"] && archiveCount == 0) {
                [data addObject:@{
                 @"type":@TYPE_JOIN_CHANNEL,
                 @"cid":@(server.cid),
                 @"bid":@-1,
                 @"name":@"Join a channel",
                 @"unread":@0,
                 @"highlights":@0,
                 @"archived":@0,
                 }];
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_boldFont = [UIFont boldSystemFontOfSize:FONT_SIZE];
            self->_normalFont = [UIFont systemFontOfSize:FONT_SIZE];
            self->_smallFont = [UIFont systemFontOfSize:FONT_SIZE - 2];

            if(data.count <= 1) {
                CLS_LOG(@"The buffer list doesn't have any buffers: %@", data);
                CLS_LOG(@"I should have %lu servers with %lu buffers", (unsigned long)[self->_servers count], (unsigned long)[self->_buffers count]);
            }
            self->_data = data;
            self->_selectedRow = selectedRow;
            self->_firstUnreadPosition = firstUnreadPosition;
            self->_firstHighlightPosition = firstHighlightPosition;
            self->_firstFailurePosition = firstFailurePosition;
            self->_lastUnreadPosition = lastUnreadPosition;
            self->_lastHighlightPosition = lastHighlightPosition;
            self->_lastFailurePosition = lastFailurePosition;
            self.view.backgroundColor = [UIColor buffersDrawerBackgroundColor];
            [self.tableView reloadData];
            [self _updateUnreadIndicators];
        }];
    }
}

-(void)_updateUnreadIndicators {
#ifndef EXTENSION
    [self.tableView visibleCells];
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.scrollIndicatorInsets)];
    if(rows.count) {
        NSInteger first = [[rows objectAtIndex:0] row];
        NSInteger last = [[rows lastObject] row];
        
        if(self->_firstFailurePosition != -1 && first > _firstFailurePosition) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor networkErrorBackgroundColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor networkErrorBorderColor];
        } else {
            topUnreadIndicator.hidden = YES;
            topUnreadIndicator.alpha = 0;
        }
        if(self->_firstUnreadPosition != -1 && first > _firstUnreadPosition) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        }
        if((self->_lastHighlightPosition != -1 && first > _lastHighlightPosition) ||
           (self->_firstHighlightPosition != -1 && first > _firstHighlightPosition)) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor redColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor highlightBorderColor];
        }
        
        if(last < _data.count) {
            if(self->_lastFailurePosition != -1 && last < _lastFailurePosition) {
                bottomUnreadIndicator.hidden = NO;
                bottomUnreadIndicator.alpha = 1;
                bottomUnreadIndicatorColor.backgroundColor = [UIColor networkErrorBackgroundColor];
                bottomUnreadIndicatorBorder.backgroundColor = [UIColor networkErrorBorderColor];
            } else {
                bottomUnreadIndicator.hidden = YES;
                bottomUnreadIndicator.alpha = 0;
            }
            if(self->_lastUnreadPosition != -1 && last < _lastUnreadPosition) {
                bottomUnreadIndicator.hidden = NO;
                bottomUnreadIndicator.alpha = 1;
                bottomUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
                bottomUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
            }
            if((self->_firstHighlightPosition != -1 && last < _firstHighlightPosition) ||
               (self->_lastHighlightPosition != -1 && last < _lastHighlightPosition)) {
                bottomUnreadIndicator.hidden = NO;
                bottomUnreadIndicator.alpha = 1;
                bottomUnreadIndicatorColor.backgroundColor = [UIColor redColor];
                bottomUnreadIndicatorBorder.backgroundColor = [UIColor highlightBorderColor];
            }
        } else {
            bottomUnreadIndicator.hidden = YES;
            bottomUnreadIndicator.alpha = 0;
        }
    }
    topUnreadIndicator.frame = CGRectMake(0,self.tableView.contentOffset.y + self.tableView.contentInset.top,self.view.frame.size.width, 40);
    bottomUnreadIndicator.frame = CGRectMake(0,self.view.frame.size.height - 40 + self.tableView.contentOffset.y - self.tableView.scrollIndicatorInsets.bottom,self.view.frame.size.width, 40);
#endif
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self->_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:self->_alertView clickedButtonAtIndex:1];
    return NO;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self->_delegate dismissKeyboard];
    [self->_alertView endEditing:YES];
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Join"]) {
        if([alertView textFieldAtIndex:0].text.length) {
            NSString *channel = [alertView textFieldAtIndex:0].text;
            NSString *key = nil;
            NSUInteger pos = [channel rangeOfString:@" "].location;
            if(pos != NSNotFound) {
                key = [channel substringFromIndex:pos + 1];
                channel = [channel substringToIndex:pos];
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [[NetworkConnection sharedInstance] join:channel key:key cid:(int)alertView.tag handler:nil];
            }];
        }
    }
    
    self->_alertView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    if(@available(iOS 11, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        self.tableView.insetsLayoutMarginsFromSafeArea = NO;
        self.tableView.insetsContentViewsToSafeArea = NO;
    }

    UIFontDescriptor *d = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    self->_boldFont = [UIFont fontWithDescriptor:d size:d.pointSize];
    
    d = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    self->_normalFont = [UIFont fontWithDescriptor:d size:d.pointSize - 2];
    self->_awesomeFont = [UIFont fontWithName:@"FontAwesome" size:18];

    lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self.tableView addGestureRecognizer:lp];
    
#ifndef EXTENSION
    if(!_delegate) {
        self->_delegate = (UIViewController<BuffersTableViewDelegate> *)[(UINavigationController *)(self.slidingViewController.topViewController) topViewController];
    }
    
    if(!topUnreadIndicatorColor) {
        topUnreadIndicatorColor = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,15)];
        topUnreadIndicatorColor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        topUnreadIndicatorColor.userInteractionEnabled = NO;
        topUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
    }

    if(!topUnreadIndicatorBorder) {
        topUnreadIndicatorBorder = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,16)];
        topUnreadIndicatorBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        topUnreadIndicatorBorder.userInteractionEnabled = NO;
        topUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        [topUnreadIndicatorBorder addSubview:topUnreadIndicatorColor];
    }
    
    if(!topUnreadIndicator) {
        topUnreadIndicator = [[UIControl alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,40)];
        topUnreadIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        topUnreadIndicator.autoresizesSubviews = YES;
        topUnreadIndicator.userInteractionEnabled = YES;
        topUnreadIndicator.backgroundColor = [UIColor clearColor];
        [topUnreadIndicator addSubview: topUnreadIndicatorBorder];
        [topUnreadIndicator addTarget:self action:@selector(topUnreadIndicatorClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview: topUnreadIndicator];
    }

    if(!bottomUnreadIndicatorColor) {
        bottomUnreadIndicatorColor = [[UIView alloc] initWithFrame:CGRectMake(0,1,self.view.frame.size.width,45)];
        bottomUnreadIndicatorColor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bottomUnreadIndicatorColor.userInteractionEnabled = NO;
        bottomUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
    }

    if(!bottomUnreadIndicatorBorder) {
        bottomUnreadIndicatorBorder = [[UIView alloc] initWithFrame:CGRectMake(0,24,self.view.frame.size.width,46)];
        bottomUnreadIndicatorBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bottomUnreadIndicatorBorder.userInteractionEnabled = NO;
        bottomUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        [bottomUnreadIndicatorBorder addSubview:bottomUnreadIndicatorColor];
    }
    
    if(!bottomUnreadIndicator) {
        bottomUnreadIndicator = [[UIControl alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,80)];
        bottomUnreadIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        bottomUnreadIndicator.autoresizesSubviews = YES;
        bottomUnreadIndicator.userInteractionEnabled = YES;
        bottomUnreadIndicator.backgroundColor = [UIColor clearColor];
        [bottomUnreadIndicator addSubview: bottomUnreadIndicatorBorder];
        [bottomUnreadIndicator addTarget:self action:@selector(bottomUnreadIndicatorClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview: bottomUnreadIndicator];
    }
#endif

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.view.backgroundColor = [UIColor buffersDrawerBackgroundColor];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backlogCompleted:) name:kIRCCloudBacklogCompletedNotification object:nil];

#ifndef EXTENSION
    if([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
        __previewer = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
    }
#endif
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
#ifndef EXTENSION
    NSDictionary *d = [self->_data objectAtIndex:[self.tableView indexPathForRowAtPoint:location].row];

    if(d) {
        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[d objectForKey:@"bid"] intValue]];
        if(b) {
            previewingContext.sourceRect = [self.tableView cellForRowAtIndexPath:[self.tableView indexPathForRowAtPoint:location]].frame;
            EventsTableView *e = [[EventsTableView alloc] init];
            e.navigationItem.title = [d objectForKey:@"name"];
            [e setBuffer:b];
            e.modalPresentationStyle = UIModalPresentationCurrentContext;
            e.preferredContentSize = ((MainViewController *)((UINavigationController *)self.slidingViewController.topViewController).topViewController).eventsView.view.bounds.size;
            lp.enabled = NO;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self->lp.enabled = YES;
            }];
            return e;
        }
    }
#endif
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [viewControllerToCommit viewWillDisappear:NO];
    [self->_delegate bufferSelected:((EventsTableView *)viewControllerToCommit).buffer.bid];
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(notification.object == nil || [notification.object bid] < 1) {
        _requestingArchives = NO;
        [self performSelectorInBackground:@selector(refresh) withObject:nil];
    } else {
        [self performSelectorInBackground:@selector(refreshBuffer:) withObject:[self->_buffers getBuffer:[notification.object bid]]];
    }
}

- (void)refreshBuffer:(Buffer *)b {
    @synchronized(self->_data) {
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        NSMutableArray *data = self->_data;
        for(int i = 0; i < data.count; i++) {
            NSDictionary *d = [data objectAtIndex:i];
            if(b.bid == [[d objectForKey:@"bid"] intValue]) {
                NSMutableDictionary *m = [d mutableCopy];
                int unread = [[EventsDataSource sharedInstance] unreadStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
                int highlights = [[EventsDataSource sharedInstance] highlightCountForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
                if([b.type isEqualToString:@"channel"]) {
                    if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                        unread = 0;
                } else {
                    if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                        unread = 0;
                    if([b.type isEqualToString:@"conversation"] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                        highlights = 0;
                }
                if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
                    if([b.type isEqualToString:@"channel"]) {
                        if([[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] != 1)
                            unread = 0;
                    }
                }
                if([b.type isEqualToString:@"channel"]) {
                    Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:b.bid];
                    if(channel) {
                        if(channel.key || (b.serverIsSlack && !b.isMPDM && [channel hasMode:@"s"]))
                            [m setObject:@1 forKey:@"key"];
                        else
                            [m setObject:@0 forKey:@"key"];
                        [m setObject:@1 forKey:@"joined"];
                    } else {
                        [m setObject:@0 forKey:@"joined"];
                    }
                }
                [m setObject:@(b.timeout) forKey:@"timeout"];
                Server *s = [[ServersDataSource sharedInstance] getServer:[[m objectForKey:@"cid"] intValue]];
                [m setObject:@(unread) forKey:@"unread"];
                [m setObject:@(highlights) forKey:@"highlights"];
                if(s.status)
                    [m setObject:s.status forKey:@"status"];
                if(s.fail_info)
                    [m setObject:s.fail_info forKey:@"fail_info"];
                [data setObject:[NSDictionary dictionaryWithDictionary:m] atIndexedSubscript:i];
                if(unread) {
                    if(self->_firstUnreadPosition == -1 || _firstUnreadPosition > i)
                        self->_firstUnreadPosition = i;
                    if(self->_lastUnreadPosition == -1 || _lastUnreadPosition < i)
                        self->_lastUnreadPosition = i;
                } else {
                    if(self->_firstUnreadPosition == i) {
                        self->_firstUnreadPosition = -1;
                        for(int j = i; j < _data.count; j++) {
                            if([[[self->_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                                self->_firstUnreadPosition = j;
                                break;
                            }
                        }
                    }
                    if(self->_lastUnreadPosition == i) {
                        self->_lastUnreadPosition = -1;
                        for(int j = i; j >= 0; j--) {
                            if([[[self->_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                                self->_lastUnreadPosition = j;
                                break;
                            }
                        }
                    }
                }
                if(highlights) {
                    if(self->_firstHighlightPosition == -1 || _firstHighlightPosition > i)
                        self->_firstHighlightPosition = i;
                    if(self->_lastHighlightPosition == -1 || _lastHighlightPosition < i)
                        self->_lastHighlightPosition = i;
                } else {
                    if(self->_firstHighlightPosition == i) {
                        self->_firstHighlightPosition = -1;
                        for(int j = i; j < _data.count; j++) {
                            if([[[self->_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                                self->_firstHighlightPosition = j;
                                break;
                            }
                        }
                    }
                    if(self->_lastHighlightPosition == i) {
                        self->_lastHighlightPosition = -1;
                        for(int j = i; j >= 0; j--) {
                            if([[[self->_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                                self->_lastHighlightPosition = j;
                                break;
                            }
                        }
                    }
                }
                if([[m objectForKey:@"type"] intValue] == TYPE_SERVER) {
                    if(s.fail_info.count) {
                        if(self->_firstFailurePosition == -1 || _firstFailurePosition > i)
                            self->_firstFailurePosition = i;
                        if(self->_lastFailurePosition == -1 || _lastFailurePosition < i)
                            self->_lastFailurePosition = i;
                    } else {
                        if(self->_firstFailurePosition == i) {
                            self->_firstFailurePosition = -1;
                            for(int j = i; j < _data.count; j++) {
                                if([[[self->_data objectAtIndex:j] objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[[self->_data objectAtIndex:j] objectForKey:@"fail_info"] count]) {
                                    self->_firstFailurePosition = j;
                                    break;
                                }
                            }
                        }
                        if(self->_lastFailurePosition == i) {
                            self->_lastFailurePosition = -1;
                            for(int j = i; j >= 0; j--) {
                                if([[[self->_data objectAtIndex:j] objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[[self->_data objectAtIndex:j] objectForKey:@"fail_info"] count]) {
                                    self->_lastFailurePosition = j;
                                    break;
                                }
                            }
                        }
                        
                    }
                }
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView reloadData];
                    [self _updateUnreadIndicators];
                }];
            }
        }
    }
}

- (void)refreshCollapsed:(Server *)s {
    @synchronized(self->_data) {
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        
        int unread = 0, highlights = 0;
        for(Buffer *b in [self->_buffers getBuffersForServer:s.cid]) {
            int u = [[EventsDataSource sharedInstance] unreadStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
            int h = [[EventsDataSource sharedInstance] highlightCountForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type];
            if([b.type isEqualToString:@"channel"]) {
                if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                    u = 0;
            } else {
                if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                    u = 0;
                if([b.type isEqualToString:@"conversation"] && [[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                    h = 0;
            }
            if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
                if([b.type isEqualToString:@"channel"]) {
                    if([[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] != 1)
                        u = 0;
                }
            }
            unread += u;
            highlights += h;
        }
        
        [s.collapsed setObject:@(unread) forKey:@"unread"];
        [s.collapsed setObject:@(highlights) forKey:@"highlights"];
        
        int row = [[s.collapsed objectForKey:@"row"] intValue];
        if(unread) {
            if(self->_firstUnreadPosition == -1 || _firstUnreadPosition > row)
                self->_firstUnreadPosition = row;
            if(self->_lastUnreadPosition == -1 || _lastUnreadPosition < row)
                self->_lastUnreadPosition = row;
        } else {
            if(self->_firstUnreadPosition == row) {
                self->_firstUnreadPosition = -1;
                for(int j = row; j < _data.count; j++) {
                    if([[[self->_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                        self->_firstUnreadPosition = j;
                        break;
                    }
                }
            }
            if(self->_lastUnreadPosition == row) {
                self->_lastUnreadPosition = -1;
                for(int j = row; j >= 0; j--) {
                    if([[[self->_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                        self->_lastUnreadPosition = j;
                        break;
                    }
                }
            }
        }
        if(highlights) {
            if(self->_firstHighlightPosition == -1 || _firstHighlightPosition > row)
                self->_firstHighlightPosition = row;
            if(self->_lastHighlightPosition == -1 || _lastHighlightPosition < row)
                self->_lastHighlightPosition = row;
        } else {
            if(self->_firstHighlightPosition == row) {
                self->_firstHighlightPosition = -1;
                for(int j = row; j < _data.count; j++) {
                    if([[[self->_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                        self->_firstHighlightPosition = j;
                        break;
                    }
                }
            }
            if(self->_lastHighlightPosition == row) {
                self->_lastHighlightPosition = -1;
                for(int j = row; j >= 0; j--) {
                    if([[[self->_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                        self->_lastHighlightPosition = j;
                        break;
                    }
                }
            }
        }
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadData];
            [self _updateUnreadIndicators];
        }];
    }
}

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = notification.object;
    Event *e = notification.object;
    switch(event) {
        case kIRCEventUserInfo:
        case kIRCEventChannelTopic:
        case kIRCEventNickChange:
        case kIRCEventMemberUpdates:
        case kIRCEventUserChannelMode:
        case kIRCEventAway:
        case kIRCEventSelfBack:
        case kIRCEventChannelTimestamp:
        case kIRCEventSelfDetails:
        case kIRCEventUserMode:
        case kIRCEventSetIgnores:
        case kIRCEventBadChannelKey:
        case kIRCEventOpenBuffer:
        case kIRCEventBanList:
        case kIRCEventWhoList:
        case kIRCEventWhois:
        case kIRCEventNamesList:
        case kIRCEventLinkChannel:
        case kIRCEventListResponseFetching:
        case kIRCEventListResponse:
        case kIRCEventListResponseTooManyChannels:
        case kIRCEventConnectionLag:
        case kIRCEventGlobalMsg:
        case kIRCEventAcceptList:
        case kIRCEventChannelTopicIs:
        case kIRCEventServerMap:
        case kIRCEventSessionDeleted:
        case kIRCEventQuietList:
        case kIRCEventBanExceptionList:
        case kIRCEventInviteList:
        case kIRCEventWhoSpecialResponse:
        case kIRCEventModulesList:
        case kIRCEventChannelQuery:
        case kIRCEventLinksResponse:
        case kIRCEventWhoWas:
        case kIRCEventAuthFailure:
        case kIRCEventAlert:
        case kIRCEventAvatarChange:
        case kIRCEventMessageChanged:
            break;
        case kIRCEventJoin:
        case kIRCEventPart:
        case kIRCEventKick:
        case kIRCEventQuit:
            if([o.type hasPrefix:@"you_"])
                [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
        case kIRCEventHeartbeatEcho:
        {
            NSDictionary *seenEids = [o objectForKey:@"seenEids"];
            for(NSNumber *cid in seenEids.allKeys) {
#ifndef ENTERPRISE
                Buffer *b = [self->_buffers getBufferWithName:@"*" server:cid.intValue];
                if(b.archived) {
                    [self performSelectorInBackground:@selector(refreshCollapsed:) withObject:[self->_servers getServer:[cid intValue]]];
                    break;
                } else {
#endif
                    NSDictionary *eids = [seenEids objectForKey:cid];
                    for(NSNumber *bid in eids.allKeys) {
                        [self performSelectorInBackground:@selector(refreshBuffer:) withObject:[self->_buffers getBuffer:[bid intValue]]];
                    }
#ifndef ENTERPRISE
                }
#endif
            }
        }
            break;
        case kIRCEventBufferMsg:
            if(e) {
                Buffer *b = [self->_buffers getBuffer:e.bid];
                if([e isImportant:b.type]) {
#ifndef ENTERPRISE
                    Buffer *c = [self->_buffers getBufferWithName:@"*" server:e.cid];
                    if(c.archived) {
                        [self performSelectorInBackground:@selector(refreshCollapsed:) withObject:[self->_servers getServer:e.cid]];
                    } else {
#endif
                        [self refreshBuffer:b];
#ifndef ENTERPRISE
                    }
#endif
                }
            }
            break;
        case kIRCEventStatusChanged:
            if(o) {
                NSArray *buffers = [self->_buffers getBuffersForServer:o.cid];
                for(Buffer *b in buffers) {
                    [self refreshBuffer:b];
                }
            }
            break;
        case kIRCEventChannelMode:
            if(o) {
                Buffer *b = [self->_buffers getBuffer:o.bid];
                if(b)
                    [self refreshBuffer:b];
            }
            break;
        case kIRCEventRefresh:
            if([notification.object isKindOfClass:NSSet.class]) {
                for(Buffer *b in notification.object) {
                    [self refreshBuffer:b];
                }
                break;
            }
        case kIRCEventBufferArchived:
            [self->_expandedCids removeObjectForKey:@(o.cid)];
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
        case kIRCEventMakeServer:
        case kIRCEventMakeBuffer:
        case kIRCEventDeleteBuffer:
        case kIRCEventChannelInit:
        case kIRCEventBufferUnarchived:
        case kIRCEventRenameConversation:
        case kIRCEventConnectionDeleted:
        case kIRCEventReorderConnections:
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
        default:
            NSLog(@"Slow event: %i", event);
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
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
    @synchronized(self->_data) {
        return _data.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self->_data) {
       if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SERVER) {
           return 46;
       } else if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SPAM) {
           return 64;
       } else if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_COLLAPSED) {
           return 32;
       } else {
           return 40;
       }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self->_data) {
        BOOL selected = (indexPath.row == self->_selectedRow);
        BuffersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bufferscell"];
        if(!cell) {
            cell = [[BuffersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bufferscell"];
        }
        NSDictionary *row = [self->_data objectAtIndex:[indexPath row]];
        NSString *status = [row objectForKey:@"status"];
        cell.type = [[row objectForKey:@"type"] intValue];
        cell.label.text = [row objectForKey:@"name"];
        cell.activity.hidden = YES;
        cell.activity.activityIndicatorViewStyle = [UIColor isDarkTheme]?UIActivityIndicatorViewStyleWhite:[UIColor activityIndicatorViewStyle];
        cell.accessibilityValue = [row objectForKey:@"hint"];
        cell.highlightColor = [UIColor bufferHighlightColor];
        cell.border.backgroundColor = [UIColor bufferBorderColor];
        cell.contentView.backgroundColor = [UIColor bufferBackgroundColor];
        cell.icon.font = self->_awesomeFont;
#ifndef EXTENSION
        if(@available(iOS 11, *))
            cell.borderInset = self.slidingViewController.view.safeAreaInsets.left;
#endif
        if([[row objectForKey:@"unread"] intValue] || (selected && cell.type != TYPE_ARCHIVES_HEADER)) {
            if([[row objectForKey:@"archived"] intValue])
                cell.unreadIndicator.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
            else
                cell.unreadIndicator.backgroundColor = selected?[UIColor selectedBufferBorderColor]:[UIColor unreadBlueColor];
            cell.unreadIndicator.hidden = NO;
            cell.label.font = self->_boldFont;
            cell.accessibilityValue = [cell.accessibilityValue stringByAppendingString:@", unread"];
        } else {
            if(cell.type == TYPE_SERVER) {
                if([status isEqualToString:@"waiting_to_retry"] || [status isEqualToString:@"pool_unavailable"] || [(NSDictionary *)[row objectForKey:@"fail_info"] count])
                    cell.unreadIndicator.backgroundColor = [UIColor failedServerBorderColor];
                else
                    cell.unreadIndicator.backgroundColor = [UIColor serverBorderColor];
                cell.unreadIndicator.hidden = NO;
            } else {
                cell.unreadIndicator.hidden = YES;
            }
            cell.label.font = self->_normalFont;
        }
        if([[row objectForKey:@"highlights"] intValue]) {
            cell.highlights.hidden = NO;
            cell.highlights.count = [NSString stringWithFormat:@"%@",[row objectForKey:@"highlights"]];
            cell.accessibilityValue = [cell.accessibilityValue stringByAppendingFormat:@", %@ highlights", [row objectForKey:@"highlights"]];
        } else {
            cell.highlights.hidden = YES;
        }
        switch(cell.type) {
            case TYPE_SERVER:
                cell.accessibilityLabel = @"Network";
                if([[row objectForKey:@"slack"] intValue]) {
                    cell.icon.text = FA_SLACK;
                } else {
                    if([[row objectForKey:@"ssl"] intValue])
                        cell.icon.text = FA_SHIELD;
                    else
                        cell.icon.text = FA_GLOBE;
                }

                cell.icon.hidden = NO;
                if(selected) {
                    cell.highlightColor = [UIColor selectedBufferHighlightColor];
                    cell.icon.textColor = cell.label.textColor = [UIColor selectedBufferTextColor];
                    if([status isEqualToString:@"waiting_to_retry"] || [status isEqualToString:@"pool_unavailable"] || [(NSDictionary *)[row objectForKey:@"fail_info"] count]) {
                        cell.icon.tintColor = cell.label.textColor = [UIColor networkErrorColor];
                        cell.unreadIndicator.backgroundColor = cell.bgColor = cell.highlightColor = [UIColor networkErrorBackgroundColor];
                    } else {
                        cell.bgColor = [UIColor selectedBufferBackgroundColor];
                    }
                } else {
                    if([status isEqualToString:@"waiting_to_retry"] || [status isEqualToString:@"pool_unavailable"] || [(NSDictionary *)[row objectForKey:@"fail_info"] count])
                        cell.icon.textColor = cell.label.textColor = [UIColor ownersBorderColor];
                    else if(![status isEqualToString:@"connected_ready"])
                        cell.icon.textColor = cell.label.textColor = [UIColor inactiveBufferTextColor];
                    else if([[row objectForKey:@"unread"] intValue])
                        cell.icon.textColor = cell.label.textColor = [UIColor unreadBufferTextColor];
                    else
                        cell.icon.textColor = cell.label.textColor = [UIColor bufferTextColor];
                    if([status isEqualToString:@"waiting_to_retry"] || [status isEqualToString:@"pool_unavailable"] || [(NSDictionary *)[row objectForKey:@"fail_info"] count])
                        cell.bgColor = cell.highlightColor = [UIColor colorWithRed:1 green:0.933 blue:0.592 alpha:1];
                    else
                        cell.bgColor = [UIColor serverBackgroundColor];
                }
                if(![status isEqualToString:@"connected_ready"] && ![status isEqualToString:@"quitting"] && ![status isEqualToString:@"disconnected"]) {
                    [cell.activity startAnimating];
                    cell.activity.hidden = NO;
                    cell.activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
                } else {
                    [cell.activity stopAnimating];
                    cell.activity.hidden = YES;
                }
                break;
            case TYPE_CHANNEL:
            case TYPE_CONVERSATION:
                if(cell.type == TYPE_CONVERSATION)
                    cell.accessibilityLabel = @"Conversation with";
                else
                    cell.accessibilityLabel = @"Channel";
                if([[row objectForKey:@"key"] intValue]) {
                    cell.icon.text = FA_LOCK;
                    cell.icon.hidden = NO;
                } else {
                    cell.icon.text = nil;
                    cell.icon.hidden = YES;
                }
                if(selected) {
                    cell.label.textColor = [UIColor selectedBufferTextColor];
                    if([[row objectForKey:@"archived"] intValue]) {
                        cell.bgColor = [UIColor selectedArchivedBufferBackgroundColor];
                        cell.highlightColor = [UIColor selectedArchivedBufferHighlightColor];
                        cell.accessibilityValue = [cell.accessibilityValue stringByAppendingString:@", archived"];
                    } else {
                        cell.icon.textColor = cell.label.textColor = [UIColor selectedBufferTextColor];
                        cell.bgColor = [UIColor selectedBufferBackgroundColor];
                        cell.highlightColor = [UIColor selectedBufferHighlightColor];
                    }
                } else {
                    if([[row objectForKey:@"archived"] intValue]) {
                        cell.label.textColor = (cell.type == TYPE_CHANNEL)?[UIColor archivedChannelTextColor]:[UIColor archivedBufferTextColor];
                        cell.bgColor = [UIColor bufferBackgroundColor];
                        cell.highlightColor = [UIColor archivedBufferHighlightColor];
                        cell.accessibilityValue = [cell.accessibilityValue stringByAppendingString:@", archived"];
                    } else {
                        if([[row objectForKey:@"joined"] intValue] == 0 || ![status isEqualToString:@"connected_ready"])
                            cell.icon.textColor = cell.label.textColor = [UIColor inactiveBufferTextColor];
                        else if([[row objectForKey:@"unread"] intValue])
                            cell.icon.textColor = cell.label.textColor = [UIColor unreadBufferTextColor];
                        else
                            cell.icon.textColor = cell.label.textColor = [UIColor bufferTextColor];
                        cell.bgColor = [UIColor bufferBackgroundColor];
                    }
                }
                if([[row objectForKey:@"timeout"] intValue]) {
                    [cell.activity startAnimating];
                    cell.activity.hidden = NO;
                    cell.activity.activityIndicatorViewStyle = selected?UIActivityIndicatorViewStyleWhite:[UIColor activityIndicatorViewStyle];
                } else {
                    [cell.activity stopAnimating];
                    cell.activity.hidden = YES;
                }
                break;
            case TYPE_ARCHIVES_HEADER:
                cell.icon.text = nil;
                cell.icon.hidden = YES;
                if([self->_expandedArchives objectForKey:[row objectForKey:@"cid"]]) {
                    cell.label.textColor = [UIColor blackColor];
                    cell.bgColor = [UIColor timestampColor];
                    cell.accessibilityHint = @"Hides archive list";
                    if(_requestingArchives && [[ServersDataSource sharedInstance] getServer:[[row objectForKey:@"cid"] intValue]].deferred_archives) {
                        [cell.activity startAnimating];
                        cell.activity.hidden = NO;
                        cell.activity.activityIndicatorViewStyle = selected?UIActivityIndicatorViewStyleWhite:[UIColor activityIndicatorViewStyle];
                    } else {
                        [cell.activity stopAnimating];
                        cell.activity.hidden = YES;
                    }
                } else {
                    cell.label.textColor = [UIColor archivesHeadingTextColor];
                    cell.bgColor = [UIColor bufferBackgroundColor];
                    cell.accessibilityHint = @"Shows archive list";
                }
                break;
            case TYPE_JOIN_CHANNEL:
                cell.label.textColor = [UIColor colorWithRed:0.361 green:0.69 blue:0 alpha:1];
                cell.bgColor = [UIColor bufferBackgroundColor];
                cell.icon.text = nil;
                cell.icon.hidden = YES;
                break;
            case TYPE_SPAM:
                cell.icon.textColor = cell.label.textColor = [UIColor ownersBorderColor];
                cell.bgColor = cell.highlightColor = [UIColor colorWithRed:1 green:0.933 blue:0.592 alpha:1];
                cell.icon.text = FA_EXCLAMATION_TRIANGLE;
                cell.icon.hidden = NO;
                cell.accessibilityLabel = @"Spam detected. Double tap to choose conversations to delete";
                break;
            case TYPE_COLLAPSED:
                cell.bgColor = cell.highlightColor = [UIColor bufferBackgroundColor];
                cell.icon.textColor = cell.label.textColor = [UIColor archivesHeadingTextColor];
                cell.icon.text = [row objectForKey:@"icon"];
                cell.icon.hidden = NO;
                cell.label.font = self->_smallFont;
                cell.accessibilityLabel = [row objectForKey:@"name"];
                cell.unreadIndicator.backgroundColor = [UIColor unreadCollapsedColor];
                cell.unreadIndicator.hidden = ([[row objectForKey:@"unread"] intValue] == 0);
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

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        [self->_delegate dismissKeyboard];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(self->_data) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        if(indexPath.row >= self->_data.count)
            return;
        
        if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER) {
            int cid = [[[self->_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue];
            if([self->_expandedArchives objectForKey:@(cid)])
                [self->_expandedArchives removeObjectForKey:@(cid)];
            else
                [self->_expandedArchives setObject:@YES forKey:@(cid)];
            if([[ServersDataSource sharedInstance] getServer:cid].deferred_archives) {
                [[NetworkConnection sharedInstance] requestArchives:cid];
                _requestingArchives = YES;
            }
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
    #ifndef EXTENSION
        } else if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SPAM) {
            if(self->_delegate)
                [self->_delegate spamSelected:[[[self->_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue]];
        } else if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL) {
            [self->_delegate dismissKeyboard];
            Server *s = [self->_servers getServer:[[[self->_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue]];
            self->_alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"What channel do you want to join?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
            self->_alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            self->_alertView.tag = [[[self->_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue];
            [self->_alertView textFieldAtIndex:0].placeholder = @"#example";
            [self->_alertView textFieldAtIndex:0].text = @"#";
            [self->_alertView textFieldAtIndex:0].delegate = self;
            [self->_alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
            [self->_alertView show];
        } else if([[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_COLLAPSED) {
            NSDictionary *d = [self->_data objectAtIndex:indexPath.row];
            if([[d objectForKey:@"archived"] intValue]) {
                [[NetworkConnection sharedInstance] unarchiveBuffer:[[d objectForKey:@"bid"] intValue] cid:[[d objectForKey:@"cid"] intValue] handler:nil];
                [self->_expandedCids setObject:@(1) forKey:[d objectForKey:@"cid"]];
            } else {
                [[NetworkConnection sharedInstance] archiveBuffer:[[d objectForKey:@"bid"] intValue] cid:[[d objectForKey:@"cid"] intValue] handler:nil];
                [self->_expandedCids removeObjectForKey:[d objectForKey:@"cid"]];
            }
            return;
    #endif
        } else {
    #ifndef EXTENSION
            self->_selectedRow = indexPath.row;
            if([self->_delegate isKindOfClass:MainViewController.class])
                [(MainViewController *)_delegate clearMsgId];
    #endif
            [self.tableView reloadData];
            [self _updateUnreadIndicators];
            if(self->_delegate)
                [self->_delegate bufferSelected:[[[self->_data objectAtIndex:indexPath.row] objectForKey:@"bid"] intValue]];
        }
    }
}

-(void)setBuffer:(Buffer *)buffer {
    if(self->_selectedBuffer.bid != buffer.bid)
        self->_selectedRow = -1;
    self->_selectedBuffer = buffer;
#ifndef ENTERPRISE
    if(self->_selectedBuffer.archived && ![self->_selectedBuffer.type isEqualToString:@"console"]) {
        if(![self->_expandedArchives objectForKey:@(self->_selectedBuffer.cid)]) {
            [self->_expandedArchives setObject:@YES forKey:@(self->_selectedBuffer.cid)];
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            return;
        }
    }
#endif
    @synchronized(self->_data) {
        if(self->_data.count) {
            for(int i = 0; i < _data.count; i++) {
                if([[[self->_data objectAtIndex:i] objectForKey:@"bid"] intValue] == self->_selectedBuffer.bid) {
                    self->_selectedRow = i;
                    break;
                }
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.tableView reloadData];
                [self _updateUnreadIndicators];
                if(self->_selectedRow != -1) {
                    NSArray *a = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.scrollIndicatorInsets)];
                    if(a.count) {
                        if([[a objectAtIndex:0] row] > self->_selectedRow || [[a lastObject] row] < self->_selectedRow)
                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self->_selectedRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
                    }
                }
            }];
        } else {
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
        }
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self _updateUnreadIndicators];
}

-(IBAction)topUnreadIndicatorClicked:(id)sender {
    @synchronized(self->_data) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        if(rows.count) {
            NSInteger first = [[rows objectAtIndex:0] row] - 1;
            NSInteger pos = 0;
            
            for(NSInteger i = first; i >= 0; i--) {
                NSDictionary *d = [self->_data objectAtIndex:i];
                if([[d objectForKey:@"unread"] intValue] || [[d objectForKey:@"highlights"] intValue] || ([[d objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[d objectForKey:@"fail_info"] count])) {
                    pos = i - 1;
                    break;
                }
            }

            if(pos < 0)
                pos = 0;
            
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
}

-(IBAction)bottomUnreadIndicatorClicked:(id)sender {
    @synchronized(self->_data) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        if(rows.count) {
            NSInteger last = [[rows lastObject] row] + 1;
            NSInteger pos = self->_data.count - 1;
            
            for(NSInteger i = last; i  < _data.count; i++) {
                NSDictionary *d = [self->_data objectAtIndex:i];
                if([[d objectForKey:@"unread"] intValue] || [[d objectForKey:@"highlights"] intValue] || ([[d objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[d objectForKey:@"fail_info"] count])) {
                    pos = i + 1;
                    break;
                }
            }

            if(pos > _data.count - 1)
                pos = self->_data.count - 1;
            
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    @synchronized(self->_data) {
        if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
            NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
            if(indexPath) {
                if(indexPath.row < _data.count) {
                    int type = [[[self->_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue];
                    if(type == TYPE_SERVER || type == TYPE_CHANNEL || type == TYPE_CONVERSATION)
                        [self->_delegate bufferLongPressed:[[[self->_data objectAtIndex:indexPath.row] objectForKey:@"bid"] intValue] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
                }
            }
        }
    }
}

-(void)next {
    @synchronized(self->_data) {
        NSDictionary *d;
        NSInteger row = self->_selectedRow + 1;
        
        do {
            if(row < _data.count)
                d = [self->_data objectAtIndex:row];
            else
                d = nil;
            row++;
        } while(d && ([[d objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER || [[d objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL));
        
        if(d) {
            [self->_delegate bufferSelected:[[d objectForKey:@"bid"] intValue]];
        }
    }
}

-(void)prev {
    @synchronized(self->_data) {
        NSDictionary *d;
        NSInteger row = self->_selectedRow - 1;
        
        do {
            if(row >= 0)
                d = [self->_data objectAtIndex:row];
            else
                d = nil;
            row--;
        } while(d && ([[d objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER || [[d objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL));
        
        if(d) {
            [self->_delegate bufferSelected:[[d objectForKey:@"bid"] intValue]];
        }
    }
}

-(void)nextUnread {
    @synchronized(self->_data) {
        NSDictionary *d;
        NSInteger row = self->_selectedRow + 1;
        
        do {
            if(row < _data.count)
                d = [self->_data objectAtIndex:row];
            else
                d = nil;
            row++;
        } while(d && ([[d objectForKey:@"unread"] intValue] == 0 || [[d objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER || [[d objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL));
        
        if(d) {
            [self->_delegate bufferSelected:[[d objectForKey:@"bid"] intValue]];
        }
    }
}

-(void)prevUnread {
    @synchronized(self->_data) {
        NSDictionary *d;
        NSInteger row = self->_selectedRow - 1;
        
        do {
            if(row >= 0)
                d = [self->_data objectAtIndex:row];
            else
                d = nil;
            row--;
        } while(d && ([[d objectForKey:@"unread"] intValue] == 0 || [[d objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER || [[d objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL));
        
        if(d) {
            [self->_delegate bufferSelected:[[d objectForKey:@"bid"] intValue]];
        }
    }
}

@end
