//
//  HighlightsCountView.h
//  IRCCloud
//
//  Created by Sam Steele on 3/20/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HighlightsCountView : UIView {
    NSString *_count;
    UIFont *_font;
}
@property NSString *count;
@property UIFont *font;
@end
