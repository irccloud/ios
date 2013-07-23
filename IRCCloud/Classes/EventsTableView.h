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

@protocol EventsTableViewDelegate<NSObject>
-(void)rowSelected:(Event *)event;
-(void)rowLongPressed:(Event *)event rect:(CGRect)rect;
-(void)dismissKeyboard;
@end

@interface EventsTableView : UITableViewController<TTTAttributedLabelDelegate,UIGestureRecognizerDelegate> {
    IBOutlet UIView *_headerView;
    
    IBOutlet UIView *_topUnreadView;
    IBOutlet UILabel *_topUnreadlabel;
    IBOutlet HighlightsCountView *_topHighlightsCountView;
    IBOutlet UIView *_bottomUnreadView;
    IBOutlet UILabel *_bottomUndreadlabel;
    IBOutlet HighlightsCountView *_bottomHighlightsCountView;
    
    NSDateFormatter *_formatter;
    NSMutableArray *_data;
    NSMutableArray *_unseenHighlightPositions;
    NSMutableDictionary *_expandedSectionEids;
    Buffer *_buffer;
    Server *_server;
    CollapsedEvents *_collapsedEvents;
    NetworkConnection *_conn;
    
    NSTimeInterval _maxEid, _minEid, _currentCollapsedEid, _earliestEid, _eidToOpen;
    int _currentGroupPosition, _newMsgs, _newHighlights, _lastSeenEidPos, _bottomRow;
    NSString *_lastCollpasedDay;
    BOOL _requestingBacklog, _ready, _scrolledUp;
    NSTimer *_heartbeatTimer;
    NSTimer *_scrollTimer;
    Ignore *_ignore;
    NSRecursiveLock *_lock;
    NSTimeInterval _scrolledUpFrom;
    
    IBOutlet id<EventsTableViewDelegate> _delegate;
}
@property (readonly) UIView *topUnreadView;
@property (readonly) UIView *bottomUnreadView;
@property (nonatomic) NSTimeInterval eidToOpen;
-(void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped;
-(void)setBuffer:(Buffer *)buffer;
-(IBAction)topUnreadBarClicked:(id)sender;
-(IBAction)bottomUnreadBarClicked:(id)sender;
-(IBAction)dismissButtonPressed:(id)sender;
-(void)scrollToBottom;
-(void)clearLastSeenMarker;
@end
