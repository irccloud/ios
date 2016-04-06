//
//  EventsTableView.h
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

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"
#import "EventsDataSource.h"
#import "CollapsedEvents.h"
#import "TTTAttributedLabel.h"
#import "NetworkConnection.h"
#import "HighlightsCountView.h"
#import "Ignore.h"
#import "CSURITemplate.h"

@protocol EventsTableViewDelegate<NSObject>
-(void)rowSelected:(Event *)event;
-(void)rowLongPressed:(Event *)event rect:(CGRect)rect link:(NSString *)url;
-(void)dismissKeyboard;
@end

@interface EventsTableView : UIViewController<TTTAttributedLabelDelegate,UIGestureRecognizerDelegate,UIViewControllerPreviewingDelegate,UITableViewDataSource,UITableViewDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UIView *_headerView;
    IBOutlet UIView *_backlogFailedView;
    IBOutlet UIButton *_backlogFailedButton;
    IBOutlet UIView *_topUnreadView;
    IBOutlet UILabel *_topUnreadArrow;
    IBOutlet UILabel *_topUnreadLabel;
    IBOutlet HighlightsCountView *_topHighlightsCountView;
    IBOutlet UIView *_bottomUnreadView;
    IBOutlet UILabel *_bottomUnreadArrow;
    IBOutlet UILabel *_bottomUnreadLabel;
    IBOutlet HighlightsCountView *_bottomHighlightsCountView;
    
    NSDateFormatter *_formatter;
    NSMutableArray *_data;
    NSMutableArray *_unseenHighlightPositions;
    NSMutableDictionary *_expandedSectionEids;
    Buffer *_buffer;
    Server *_server;
    CollapsedEvents *_collapsedEvents;
    NetworkConnection *_conn;
    
    NSTimeInterval _maxEid, _minEid, _currentCollapsedEid, _earliestEid, _eidToOpen, _lastCollapsedEid;
    NSInteger _newMsgs, _newHighlights, _lastSeenEidPos, _bottomRow;
    NSString *_lastCollpasedDay;
    BOOL _requestingBacklog, _ready;
    NSTimer *_heartbeatTimer;
    NSTimer *_scrollTimer;
    Ignore *_ignore;
    NSRecursiveLock *_lock;
    UIInterfaceOrientation _lastOrientation;
    
    IBOutlet id<EventsTableViewDelegate> _delegate;
    
    NSDictionary *_linkAttributes;
    NSDictionary *_lightLinkAttributes;

    CSURITemplate *_file_url_template;
    CSURITemplate *_paste_url_template;
    
    NSString *_groupIndent;
    id<UIViewControllerPreviewing> __previewer;
    UILongPressGestureRecognizer *lp;
    
    NSUInteger _previewingRow;
}
@property (readonly) UITableView *tableView;
@property (readonly) UIView *topUnreadView;
@property (readonly) UIView *bottomUnreadView;
@property (readonly) UILabel *topUnreadArrow;
@property (readonly) UILabel *topUnreadLabel;
@property (readonly) UILabel *bottomUnreadLabel;
@property (readonly) UILabel *bottomUnreadArrow;
@property (nonatomic) NSTimeInterval eidToOpen;
@property Buffer *buffer;
-(void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped;
-(IBAction)topUnreadBarClicked:(id)sender;
-(IBAction)bottomUnreadBarClicked:(id)sender;
-(IBAction)dismissButtonPressed:(id)sender;
-(IBAction)loadMoreBacklogButtonPressed:(id)sender;
-(void)_scrollToBottom;
-(void)scrollToBottom;
-(void)clearLastSeenMarker;
-(void)refresh;
@end
