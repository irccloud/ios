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

#if TARGET_IPHONE_SIMULATOR
//Private API for testing force touch from https://gist.github.com/jamesfinley/7e2009dd87b223c69190
@interface UIPreviewForceInteractionProgress : NSObject

- (void)endInteraction:(BOOL)arg1;

@end

@interface UIPreviewInteractionController : NSObject

@property (nonatomic, readonly) UIPreviewForceInteractionProgress *interactionProgressForPresentation;

- (BOOL)startInteractivePreviewAtLocation:(CGPoint)point inView:(UIView *)view;
- (void)cancelInteractivePreview;
- (void)commitInteractivePreview;

@end

@interface _UIViewControllerPreviewSourceViewRecord : NSObject <UIViewControllerPreviewing>

@property (nonatomic, readonly) UIPreviewInteractionController *previewInteractionController;

@end

void WFSimulate3DTouchPreview(id<UIViewControllerPreviewing> previewer, CGPoint sourceLocation);
#endif

#define TYPE_SERVER 0
#define TYPE_CHANNEL 1
#define TYPE_CONVERSATION 2
#define TYPE_ARCHIVES_HEADER 3
#define TYPE_JOIN_CHANNEL 4

@interface BuffersTableCell : UITableViewCell {
    UILabel *_label;
    UILabel *_icon;
    int _type;
    UIView *_unreadIndicator;
    UIView *_bg;
    UIView *_border;
    HighlightsCountView *_highlights;
    UIActivityIndicatorView *_activity;
    UIColor *_bgColor;
    UIColor *_highlightColor;
}
@property int type;
@property UIColor *bgColor, *highlightColor;
@property (readonly) UILabel *label, *icon;
@property (readonly) UIView *unreadIndicator, *bg, *border;
@property (readonly) HighlightsCountView *highlights;
@property (readonly) UIActivityIndicatorView *activity;
@end

@implementation BuffersTableCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _type = 0;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _bg = [[UIView alloc] init];
        [self.contentView addSubview:_bg];
        
        _border = [[UIView alloc] init];
        [self.contentView addSubview:_border];
        
        _unreadIndicator = [[UIView alloc] init];
        _unreadIndicator.backgroundColor = [UIColor unreadBlueColor];
        [self.contentView addSubview:_unreadIndicator];
        
        _icon = [[UILabel alloc] init];
        _icon.backgroundColor = [UIColor clearColor];
        _icon.textColor = [UIColor bufferTextColor];
        _icon.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:_icon];

        _label = [[UILabel alloc] init];
        _label.backgroundColor = [UIColor clearColor];
        _label.textColor = [UIColor bufferTextColor];
        [self.contentView addSubview:_label];
        
        _highlights = [[HighlightsCountView alloc] initWithFrame:CGRectZero];
        [self.contentView addSubview:_highlights];
        
        _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        _activity.hidden = YES;
        [self.contentView addSubview:_activity];
    }
    return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
    CGRect frame = [self.contentView bounds];
    _border.frame = CGRectMake(frame.origin.x, frame.origin.y, 6, frame.size.height);
    frame.size.width -= 8;
    if(_type == TYPE_SERVER) {
        frame.origin.y += 6;
        frame.size.height -= 6;
    }
    _bg.frame = CGRectMake(frame.origin.x + 6, frame.origin.y, frame.size.width - 6, frame.size.height);
    _unreadIndicator.frame = CGRectMake(frame.origin.x, frame.origin.y, 6, frame.size.height);
    _icon.frame = CGRectMake(frame.origin.x + 12, frame.origin.y + 12, 16, 16);
    if(!_activity.hidden) {
        frame.size.width -= _activity.frame.size.width + 12;
        _activity.frame = CGRectMake(frame.origin.x + 6 + frame.size.width, frame.origin.y + 10, _activity.frame.size.width, _activity.frame.size.height);
    }
    if(!_highlights.hidden) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        CGSize size = [_highlights.count sizeWithFont:_highlights.font];
#pragma GCC diagnostic pop
        size.width += 0;
        size.height = frame.size.height - 16;
        if(size.width < size.height)
            size.width = size.height;
        frame.size.width -= size.width + 12;
        _highlights.frame = CGRectMake(frame.origin.x + 6 + frame.size.width, frame.origin.y + 6, size.width, size.height);
    }
    _label.frame = CGRectMake(frame.origin.x + 12 + _icon.frame.size.height + 6, frame.origin.y, frame.size.width - 6 - _icon.frame.size.height - 16, frame.size.height);
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    if(!self.selected)
        _bg.backgroundColor = highlighted?_highlightColor:_bgColor;
}

@end

@implementation BuffersTableView

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _data = nil;
        _selectedRow = -1;
        _expandedArchives = [[NSMutableDictionary alloc] init];
        _firstHighlightPosition = -1;
        _firstUnreadPosition = -1;
        _lastHighlightPosition = -1;
        _lastUnreadPosition = -1;
        _servers = [ServersDataSource sharedInstance];
        _buffers = [BuffersDataSource sharedInstance];
    }
    return self;
}

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
        _servers = [ServersDataSource sharedInstance];
        _buffers = [BuffersDataSource sharedInstance];
    }
    return self;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self.tableView reloadData];
    [self _updateUnreadIndicators];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    [self performSelectorInBackground:@selector(refresh) withObject:nil];
}

- (void)refresh {
    @synchronized(_data) {
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
        
        for(Server *server in [_servers getServers]) {
            archiveCount = 0;
            NSArray *buffers = [_buffers getBuffersForServer:server.cid];
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
                     @"status":server.status,
                     @"fail_info":server.fail_info,
                     @"ssl":@(server.ssl),
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

                    if(buffer.bid == _selectedBuffer.bid)
                        selectedRow = data.count - 1;
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
                        if(channel.key)
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
                            if(![[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                                unread = 0;
                        } else {
                            if(![[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                                unread = 0;
                            if(type == TYPE_CONVERSATION && ![[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",buffer.bid]] intValue] == 1)
                                highlights = 0;
                        }
                    }
                    [data addObject:@{
                     @"type":@(type),
                     @"cid":@(buffer.cid),
                     @"bid":@(buffer.bid),
                     @"name":buffer.name,
                     @"unread":@(unread),
                     @"highlights":@(highlights),
                     @"archived":@0,
                     @"joined":@(joined),
                     @"key":@(key),
                     @"timeout":@(buffer.timeout),
                     @"hint":buffer.accessibilityValue,
                     @"status":server.status
                     }];
                    if(unread > 0 && firstUnreadPosition == -1)
                        firstUnreadPosition = data.count - 1;
                    if(unread > 0 && (lastUnreadPosition == -1 || lastUnreadPosition < data.count - 1))
                        lastUnreadPosition = data.count - 1;
                    if(highlights > 0 && firstHighlightPosition == -1)
                        firstHighlightPosition = data.count - 1;
                    if(highlights > 0 && (lastHighlightPosition == -1 || lastHighlightPosition < data.count - 1))
                        lastHighlightPosition = data.count - 1;

                    if(buffer.bid == _selectedBuffer.bid)
                        selectedRow = data.count - 1;
                }
                if(type > 0 && buffer.archived > 0)
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
                             @"hint":buffer.accessibilityValue,
                             @"key":@0,
                             }];
                            if(buffer.bid == _selectedBuffer.bid)
                                selectedRow = data.count - 1;
                        }
                    }
                }
            }
            if(buffers.count == 1 && [server.status isEqualToString:@"connected_ready"]) {
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
            _boldFont = [UIFont boldSystemFontOfSize:FONT_SIZE];
           _normalFont = [UIFont systemFontOfSize:FONT_SIZE];

            if(data.count <= 1) {
                CLS_LOG(@"The buffer list doesn't have any buffers: %@", data);
                CLS_LOG(@"I should have %lu servers with %lu buffers", (unsigned long)[_servers count], (unsigned long)[_buffers count]);
            }
            _data = data;
            _selectedRow = selectedRow;
            _firstUnreadPosition = firstUnreadPosition;
            _firstHighlightPosition = firstHighlightPosition;
            _firstFailurePosition = firstFailurePosition;
            _lastUnreadPosition = lastUnreadPosition;
            _lastHighlightPosition = lastHighlightPosition;
            _lastFailurePosition = lastFailurePosition;
            self.view.backgroundColor = [UIColor buffersDrawerBackgroundColor];
            [self.tableView reloadData];
            [self _updateUnreadIndicators];
        }];
    }
}

-(void)_updateUnreadIndicators {
#ifndef EXTENSION
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
    if(rows.count) {
        NSInteger first = [[rows objectAtIndex:0] row];
        NSInteger last = [[rows lastObject] row];
        
        if(_firstFailurePosition != -1 && first > _firstFailurePosition) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor networkErrorBackgroundColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor networkErrorBorderColor];
        } else {
            topUnreadIndicator.hidden = YES;
            topUnreadIndicator.alpha = 0;
        }
        if(_firstUnreadPosition != -1 && first > _firstUnreadPosition) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        }
        if((_lastHighlightPosition != -1 && first > _lastHighlightPosition) ||
           (_firstHighlightPosition != -1 && first > _firstHighlightPosition)) {
            topUnreadIndicator.hidden = NO;
            topUnreadIndicator.alpha = 1;
            topUnreadIndicatorColor.backgroundColor = [UIColor redColor];
            topUnreadIndicatorBorder.backgroundColor = [UIColor highlightBorderColor];
        }
        
        if(_lastFailurePosition != -1 && last < _lastFailurePosition) {
            bottomUnreadIndicator.hidden = NO;
            bottomUnreadIndicator.alpha = 1;
            bottomUnreadIndicatorColor.backgroundColor = [UIColor networkErrorBackgroundColor];
            bottomUnreadIndicatorBorder.backgroundColor = [UIColor networkErrorBorderColor];
        } else {
            bottomUnreadIndicator.hidden = YES;
            bottomUnreadIndicator.alpha = 0;
        }
        if(_lastUnreadPosition != -1 && last < _lastUnreadPosition) {
            bottomUnreadIndicator.hidden = NO;
            bottomUnreadIndicator.alpha = 1;
            bottomUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
            bottomUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        }
        if((_firstHighlightPosition != -1 && last < _firstHighlightPosition) ||
           (_lastHighlightPosition != -1 && last < _lastHighlightPosition)) {
            bottomUnreadIndicator.hidden = NO;
            bottomUnreadIndicator.alpha = 1;
            bottomUnreadIndicatorColor.backgroundColor = [UIColor redColor];
            bottomUnreadIndicatorBorder.backgroundColor = [UIColor highlightBorderColor];
        }
    }
    topUnreadIndicator.frame = CGRectMake(0,self.tableView.contentOffset.y + self.tableView.contentInset.top,self.view.frame.size.width, 40);
    bottomUnreadIndicator.frame = CGRectMake(0,self.view.frame.size.height - 40 + self.tableView.contentOffset.y,self.view.frame.size.width, 40);
#endif
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_alertView dismissWithClickedButtonIndex:1 animated:YES];
    [self alertView:_alertView clickedButtonAtIndex:1];
    return NO;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [_delegate dismissKeyboard];
    [_alertView endEditing:YES];
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
                [[NetworkConnection sharedInstance] join:channel key:key cid:(int)alertView.tag];
            }];
        }
    }
    
    _alertView = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.scrollsToTop = NO;

    UIFontDescriptor *d = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    _boldFont = [UIFont fontWithDescriptor:d size:d.pointSize];
    
    d = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    _normalFont = [UIFont fontWithDescriptor:d size:d.pointSize];
    _awesomeFont = [UIFont fontWithName:@"FontAwesome" size:d.pointSize];

    lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_longPress:)];
    lp.minimumPressDuration = 1.0;
    lp.delegate = self;
    [self.tableView addGestureRecognizer:lp];
    
#ifndef EXTENSION
    if(!_delegate) {
        _delegate = (UIViewController<BuffersTableViewDelegate> *)[(UINavigationController *)(self.slidingViewController.topViewController) topViewController];
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
        bottomUnreadIndicatorColor = [[UIView alloc] initWithFrame:CGRectMake(0,1,self.view.frame.size.width,15)];
        bottomUnreadIndicatorColor.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bottomUnreadIndicatorColor.userInteractionEnabled = NO;
        bottomUnreadIndicatorColor.backgroundColor = [UIColor unreadBlueColor];
    }

    if(!bottomUnreadIndicatorBorder) {
        bottomUnreadIndicatorBorder = [[UIView alloc] initWithFrame:CGRectMake(0,24,self.view.frame.size.width,16)];
        bottomUnreadIndicatorBorder.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        bottomUnreadIndicatorBorder.userInteractionEnabled = NO;
        bottomUnreadIndicatorBorder.backgroundColor = [UIColor unreadBorderColor];
        [bottomUnreadIndicatorBorder addSubview:bottomUnreadIndicatorColor];
    }
    
    if(!bottomUnreadIndicator) {
        bottomUnreadIndicator = [[UIControl alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,40)];
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
#if !(TARGET_IPHONE_SIMULATOR)
    if([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
#endif
        __previewer = [self registerForPreviewingWithDelegate:self sourceView:self.tableView];
#if !(TARGET_IPHONE_SIMULATOR)
    }
#endif

#if TARGET_IPHONE_SIMULATOR
    //UITapGestureRecognizer *t = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_test3DTouch:)];
    //t.delegate = self;
    //[self.view addGestureRecognizer:t];
#endif
#endif
}

#ifndef EXTENSION
#if TARGET_IPHONE_SIMULATOR
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ([self previewingContext:__previewer viewControllerForLocation:[touch locationInView:self.tableView]] != nil);
}

- (void)_test3DTouch:(UITapGestureRecognizer *)r {
    WFSimulate3DTouchPreview(__previewer, [r locationInView:self.tableView]);
}
#endif
#endif

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
#ifndef EXTENSION
    NSDictionary *d = [_data objectAtIndex:[self.tableView indexPathForRowAtPoint:location].row];

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
                lp.enabled = YES;
            }];
            return e;
        }
    }
#endif
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [viewControllerToCommit viewWillDisappear:NO];
    [_delegate bufferSelected:((EventsTableView *)viewControllerToCommit).buffer.bid];
}

- (void)backlogCompleted:(NSNotification *)notification {
    if(notification.object == nil || [notification.object bid] < 1) {
        [self performSelectorInBackground:@selector(refresh) withObject:nil];
    } else {
        [self performSelectorInBackground:@selector(refreshBuffer:) withObject:[_buffers getBuffer:[notification.object bid]]];
    }
}

- (void)refreshBuffer:(Buffer *)b {
    @synchronized(_data) {
        NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
        NSMutableArray *data = _data;
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
                        if(![[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                            unread = 0;
                    } else {
                        if(![[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                            unread = 0;
                        if([b.type isEqualToString:@"conversation"] && ![[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",b.bid]] intValue] == 1)
                            highlights = 0;
                    }
                }
                if([b.type isEqualToString:@"channel"]) {
                    Channel *channel = [[ChannelsDataSource sharedInstance] channelForBuffer:b.bid];
                    if(channel) {
                        if(channel.key)
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
                    if(_firstUnreadPosition == -1 || _firstUnreadPosition > i)
                        _firstUnreadPosition = i;
                    if(_lastUnreadPosition == -1 || _lastUnreadPosition < i)
                        _lastUnreadPosition = i;
                } else {
                    if(_firstUnreadPosition == i) {
                        _firstUnreadPosition = -1;
                        for(int j = i; j < _data.count; j++) {
                            if([[[_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                                _firstUnreadPosition = j;
                                break;
                            }
                        }
                    }
                    if(_lastUnreadPosition == i) {
                        _lastUnreadPosition = -1;
                        for(int j = i; j >= 0; j--) {
                            if([[[_data objectAtIndex:j] objectForKey:@"unread"] intValue]) {
                                _lastUnreadPosition = j;
                                break;
                            }
                        }
                    }
                }
                if(highlights) {
                    if(_firstHighlightPosition == -1 || _firstHighlightPosition > i)
                        _firstHighlightPosition = i;
                    if(_lastHighlightPosition == -1 || _lastHighlightPosition < i)
                        _lastHighlightPosition = i;
                } else {
                    if(_firstHighlightPosition == i) {
                        _firstHighlightPosition = -1;
                        for(int j = i; j < _data.count; j++) {
                            if([[[_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                                _firstHighlightPosition = j;
                                break;
                            }
                        }
                    }
                    if(_lastHighlightPosition == i) {
                        _lastHighlightPosition = -1;
                        for(int j = i; j >= 0; j--) {
                            if([[[_data objectAtIndex:j] objectForKey:@"highlights"] intValue]) {
                                _lastHighlightPosition = j;
                                break;
                            }
                        }
                    }
                }
                if([[m objectForKey:@"type"] intValue] == TYPE_SERVER) {
                    if(s.fail_info.count) {
                        if(_firstFailurePosition == -1 || _firstFailurePosition > i)
                            _firstFailurePosition = i;
                        if(_lastFailurePosition == -1 || _lastFailurePosition < i)
                            _lastFailurePosition = i;
                    } else {
                        if(_firstFailurePosition == i) {
                            _firstFailurePosition = -1;
                            for(int j = i; j < _data.count; j++) {
                                if([[[_data objectAtIndex:j] objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[[_data objectAtIndex:j] objectForKey:@"fail_info"] count]) {
                                    _firstFailurePosition = j;
                                    break;
                                }
                            }
                        }
                        if(_lastFailurePosition == i) {
                            _lastFailurePosition = -1;
                            for(int j = i; j >= 0; j--) {
                                if([[[_data objectAtIndex:j] objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[[_data objectAtIndex:j] objectForKey:@"fail_info"] count]) {
                                    _lastFailurePosition = j;
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

- (void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = notification.object;
    Event *e = notification.object;
    switch(event) {
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
        case kIRCEventInvalidNick:
        case kIRCEventBanList:
        case kIRCEventWhoList:
        case kIRCEventWhois:
        case kIRCEventNamesList:
        case kIRCEventLinkChannel:
        case kIRCEventListResponseFetching:
        case kIRCEventListResponse:
        case kIRCEventListResponseTooManyChannels:
        case kIRCEventGlobalMsg:
        case kIRCEventAcceptList:
        case kIRCEventChannelTopicIs:
        case kIRCEventServerMap:
        case kIRCEventQuietList:
        case kIRCEventBanExceptionList:
        case kIRCEventInviteList:
        case kIRCEventFailureMsg:
        case kIRCEventSuccess:
        case kIRCEventAlert:
            break;
        case kIRCEventJoin:
        case kIRCEventPart:
        case kIRCEventKick:
        case kIRCEventQuit:
            if([o.type hasPrefix:@"you_"])
                [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
        case kIRCEventHeartbeatEcho:
            @synchronized(_data) {
                NSDictionary *seenEids = [o objectForKey:@"seenEids"];
                for(NSNumber *cid in seenEids.allKeys) {
                    NSDictionary *eids = [seenEids objectForKey:cid];
                    for(NSNumber *bid in eids.allKeys) {
                        [self refreshBuffer:[_buffers getBuffer:[bid intValue]]];
                    }
                }
            }
            break;
        case kIRCEventBufferMsg:
            if(e) {
                Buffer *b = [_buffers getBuffer:e.bid];
                if([e isImportant:b.type]) {
                    [self refreshBuffer:b];
                }
            }
            break;
        case kIRCEventStatusChanged:
            if(o) {
                NSArray *buffers = [_buffers getBuffersForServer:o.cid];
                for(Buffer *b in buffers) {
                    [self refreshBuffer:b];
                }
            }
            break;
        case kIRCEventChannelMode:
            if(o) {
                Buffer *b = [_buffers getBuffer:o.bid];
                if(b)
                    [self refreshBuffer:b];
            }
            break;
        default:
            NSLog(@"Slow event: %i", event);
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            break;
    }
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
    if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_SERVER) {
        return 46;
    } else {
        return 40;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL selected = (indexPath.row == _selectedRow);
    BuffersTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"bufferscell"];
    if(!cell) {
        cell = [[BuffersTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"bufferscell"];
    }
    NSDictionary *row = [_data objectAtIndex:[indexPath row]];
    NSString *status = [row objectForKey:@"status"];
    cell.type = [[row objectForKey:@"type"] intValue];
    cell.label.text = [row objectForKey:@"name"];
    cell.activity.hidden = YES;
    cell.activity.activityIndicatorViewStyle = [UIColor isDarkTheme]?UIActivityIndicatorViewStyleWhite:[UIColor activityIndicatorViewStyle];
    cell.accessibilityValue = [row objectForKey:@"hint"];
    cell.highlightColor = [UIColor bufferHighlightColor];
    cell.border.backgroundColor = [UIColor bufferBorderColor];
    cell.contentView.backgroundColor = [UIColor bufferBackgroundColor];
    cell.icon.font = _awesomeFont;

    if([[row objectForKey:@"unread"] intValue] || (selected && cell.type != TYPE_ARCHIVES_HEADER)) {
        if([[row objectForKey:@"archived"] intValue])
            cell.unreadIndicator.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        else
            cell.unreadIndicator.backgroundColor = selected?[UIColor selectedBufferBorderColor]:[UIColor unreadBlueColor];
        cell.unreadIndicator.hidden = NO;
        cell.label.font = _boldFont;
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
        cell.label.font = _normalFont;
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
            if([[row objectForKey:@"ssl"] intValue])
                cell.icon.text = FA_SHIELD;
            else
                cell.icon.text = FA_GLOBE;
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
            if([_expandedArchives objectForKey:[row objectForKey:@"cid"]]) {
                cell.label.textColor = [UIColor blackColor];
                cell.bgColor = [UIColor timestampColor];
                cell.accessibilityHint = @"Hides archive list";
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
    if([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        [_delegate dismissKeyboard];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if(indexPath.row >= _data.count)
        return;
    
    if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_ARCHIVES_HEADER) {
        if([_expandedArchives objectForKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]])
            [_expandedArchives removeObjectForKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]];
        else
            [_expandedArchives setObject:@YES forKey:[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"]];
        [self performSelectorInBackground:@selector(refresh) withObject:nil];
#ifndef EXTENSION
    } else if([[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue] == TYPE_JOIN_CHANNEL) {
        [_delegate dismissKeyboard];
        Server *s = [_servers getServer:[[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue]];
        _alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%@:%i)", s.name, s.hostname, s.port] message:@"What channel do you want to join?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Join", nil];
        _alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        _alertView.tag = [[[_data objectAtIndex:indexPath.row] objectForKey:@"cid"] intValue];
        [_alertView textFieldAtIndex:0].placeholder = @"#example";
        [_alertView textFieldAtIndex:0].text = @"#";
        [_alertView textFieldAtIndex:0].delegate = self;
        [_alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
        [_alertView show];
#endif
    } else {
#ifndef EXTENSION
        _selectedRow = indexPath.row;
#endif
        [self.tableView reloadData];
        [self _updateUnreadIndicators];
        if(_delegate)
            [_delegate bufferSelected:[[[_data objectAtIndex:indexPath.row] objectForKey:@"bid"] intValue]];
    }
}

-(void)setBuffer:(Buffer *)buffer {
    if(_selectedBuffer.bid != buffer.bid)
        _selectedRow = -1;
    _selectedBuffer = buffer;
    if(_selectedBuffer.archived && ![_selectedBuffer.type isEqualToString:@"console"]) {
        if(![_expandedArchives objectForKey:@(_selectedBuffer.cid)]) {
            [_expandedArchives setObject:@YES forKey:@(_selectedBuffer.cid)];
            [self performSelectorInBackground:@selector(refresh) withObject:nil];
            return;
        }
    }
    @synchronized(_data) {
        if(_data.count) {
            for(int i = 0; i < _data.count; i++) {
                if([[[_data objectAtIndex:i] objectForKey:@"bid"] intValue] == _selectedBuffer.bid) {
                    _selectedRow = i;
                    break;
                }
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.tableView reloadData];
                [self _updateUnreadIndicators];
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
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
    if(rows.count) {
        NSInteger first = [[rows objectAtIndex:0] row] - 1;
        NSInteger pos = 0;
        
        for(NSInteger i = first; i >= 0; i--) {
            NSDictionary *d = [_data objectAtIndex:i];
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

-(IBAction)bottomUnreadIndicatorClicked:(id)sender {
    NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
    if(rows.count) {
        NSInteger last = [[rows lastObject] row] + 1;
        NSInteger pos = _data.count - 1;
        
        for(NSInteger i = last; i  < _data.count; i++) {
            NSDictionary *d = [_data objectAtIndex:i];
            if([[d objectForKey:@"unread"] intValue] || [[d objectForKey:@"highlights"] intValue] || ([[d objectForKey:@"type"] intValue] == TYPE_SERVER && [(NSDictionary *)[d objectForKey:@"fail_info"] count])) {
                pos = i + 1;
                break;
            }
        }

        if(pos > _data.count - 1)
            pos = _data.count - 1;
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

-(void)_longPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:self.tableView]];
        if(indexPath) {
            if(indexPath.row < _data.count) {
                int type = [[[_data objectAtIndex:indexPath.row] objectForKey:@"type"] intValue];
                if(type == TYPE_SERVER || type == TYPE_CHANNEL || type == TYPE_CONVERSATION)
                    [_delegate bufferLongPressed:[[[_data objectAtIndex:indexPath.row] objectForKey:@"bid"] intValue] rect:[self.tableView rectForRowAtIndexPath:indexPath]];
            }
        }
    }
}

@end
