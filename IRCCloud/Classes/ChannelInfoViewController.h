//
//  ChannelInfoViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/4/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChannelsDataSource.h"
#import "TTTAttributedLabel.h"
#import "OpenInChromeController.h"

@interface ChannelInfoViewController : UITableViewController<UITextViewDelegate,TTTAttributedLabelDelegate> {
    Channel *_channel;
    UITextView *_topicEdit;
    NSAttributedString *_topic;
    TTTAttributedLabel *_topicLabel;
    OpenInChromeController *_openInChromeController;
    NSMutableArray *_modeHints;
    BOOL _topicChanged;
    int offset;
}
-(id)initWithBid:(int)bid;
@end
