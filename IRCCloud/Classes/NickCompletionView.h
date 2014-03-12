//
//  NickCompletionView.h
//  IRCCloud
//
//  Created by Sam Steele on 1/13/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NickCompletionViewDelegate<NSObject>
-(void)nickSelected:(NSString *)nick;
@end


@interface NickCompletionView : UIView<UIInputViewAudioFeedback> {
    UIScrollView *_scrollView;
    NSArray *_suggestions;
    UIFont *_font;
    int _selection;
}
@property (readonly) UIFont *font;
@property (nonatomic, assign) id<NickCompletionViewDelegate> completionDelegate;
@property int selection;
-(void)setSuggestions:(NSArray *)suggestions;
-(NSUInteger)count;
-(NSString *)suggestion;
@end
