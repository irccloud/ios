//
//  WhoisViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/24/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TTTAttributedLabel.h"
#import "IRCCloudJSONObject.h"

@interface WhoisViewController : UIViewController<TTTAttributedLabelDelegate> {
    UIScrollView *_scrollView;
    TTTAttributedLabel *_label;
}
-(id)initWithJSONObject:(IRCCloudJSONObject*)object;
@end
