//
//  EventsTableView.h
//  IRCCloud
//
//  Created by Sam Steele on 2/25/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BuffersDataSource.h"
#import "EventsDataSource.h"
#import "CollapsedEvents.h"
#import "TTTAttributedLabel.h"
#import "NetworkConnection.h"
#import "HighlightsCountView.h"

@protocol EventsTableViewDelegate<NSObject>
-(void)rowSelected:(Event *)event;
@end

@interface EventsTableView : UITableViewController<TTTAttributedLabelDelegate> {
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
    CollapsedEvents *_collapsedEvents;
    NetworkConnection *_conn;
    
    NSTimeInterval _maxEid, _minEid, _currentCollapsedEid, _earliestEid;
    int _currentGroupPosition, _newMsgs, _newHighlights, _lastSeenEidPos;
    NSString *_lastCollpasedDay;
    BOOL _requestingBacklog, _ready;
    NSTimer *_heartbeatTimer;
    
    IBOutlet id<EventsTableViewDelegate> _delegate;
}
-(void)insertEvent:(Event *)event backlog:(BOOL)backlog nextIsGrouped:(BOOL)nextIsGrouped;
-(void)setBuffer:(Buffer *)buffer;
-(IBAction)topUnreadBarClicked:(id)sender;
-(IBAction)bottomUnreadBarClicked:(id)sender;
@end
