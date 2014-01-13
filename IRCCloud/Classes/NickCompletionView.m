//
//  NickCompletionView.m
//  IRCCloud
//
//  Created by Sam Steele on 1/13/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "NickCompletionView.h"

@implementation NickCompletionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setSuggestions:@[@"/", @"#"]];
    }
    return self;
}

-(void)setSuggestions:(NSArray *)suggestions {
    _suggestions = suggestions;
    
    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    int x = 0;
    float height = 0;
    for(NSString *label in _suggestions) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        [b setTitle:label forState:UIControlStateNormal];
        [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(suggestionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [b sizeToFit];
        CGRect frame = b.frame;
        frame.origin.x = x;
        x += frame.size.width + 8;
        if(height == 0)
            height = frame.size.height;
        b.frame = frame;
        [self addSubview:b];
    }
    CGRect frame = self.frame;
    if(frame.size.height == 0) {
        frame.size.height = height;
        self.frame = frame;
    }
    if(frame.size.width < x) {
        [self setContentInset:UIEdgeInsetsMake(0, 6, 0, 6)];
    } else {
        [self setContentInset:UIEdgeInsetsMake(0, (frame.size.width - x) / 2, 0, 0)];
    }
    [self setContentSize:CGSizeMake(x,height)];
}

-(void)suggestionTapped:(UIButton *)sender {
    [_completionDelegate nickSelected:sender.titleLabel.text];
}
@end
