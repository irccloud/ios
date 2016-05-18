//
//  NickCompletionView.m
//  IRCCloud
//
//  Created by Sam Steele on 1/13/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "NickCompletionView.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"

@implementation NickCompletionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selection = -1;
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.layer.masksToBounds = YES;
        _scrollView.layer.cornerRadius = 4;
        [self addSubview:_scrollView];
        [self addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:1.0f constant:-2.0f],
                               [NSLayoutConstraint constraintWithItem:_scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:1.0f constant:-3.0f]
                               ]];
        [self setSuggestions:@[]];
    }
    return self;
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, 36);
}

-(void)setSuggestions:(NSArray *)suggestions {
    _suggestions = suggestions;
    
    [[_scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    int x = 0;
    for(NSString *label in _suggestions) {
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.titleLabel.font = _font;
        [b setTitle:label forState:UIControlStateNormal];
        [b setTitleColor:[UIColor bufferTextColor] forState:UIControlStateNormal];
        [b addTarget:self action:@selector(suggestionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [b sizeToFit];
        CGRect frame = b.frame;
        frame.origin.x = x;
        if(frame.size.width < 32)
            frame.size.width = 32;
        frame.size.width += 20;
        frame.size.height = _scrollView.frame.size.height;
        b.frame = frame;
        [_scrollView addSubview:b];
        x += frame.size.width;
    }
    if(_scrollView.frame.size.width < x) {
        [_scrollView setContentInset:UIEdgeInsetsMake(0, 6, 0, 6)];
    } else {
        [_scrollView setContentInset:UIEdgeInsetsMake(0, (_scrollView.frame.size.width - x) / 2, 0, 0)];
    }
    [_scrollView setContentSize:CGSizeMake(x,_scrollView.frame.size.height)];
    _selection = -1;
    _font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.backgroundColor = [UIColor bufferBorderColor];
    _scrollView.backgroundColor = [UIColor bufferBackgroundColor];
}

-(NSString *)suggestion {
    if(_selection == -1 || _selection >= _suggestions.count)
        return nil;
    return [_suggestions objectAtIndex:_selection];
}


-(NSUInteger)count {
    return _suggestions.count;
}

-(int)selection {
    return _selection;
}

-(void)setSelection:(int)selection {
    _selection = selection;
    
    if(_selection >= 0) {
        int i = 0;
        for(UIButton *b in [_scrollView subviews]) {
            if([b isKindOfClass:[UIButton class]]) {
                if(i == selection) {
                    [b setTitleColor:[UIColor selectedBufferTextColor] forState:UIControlStateNormal];
                    b.titleLabel.superview.backgroundColor = [UIColor selectedBufferBackgroundColor];
                    [_scrollView scrollRectToVisible:b.frame animated:YES];
                } else {
                    [b setTitleColor:[UIColor bufferTextColor] forState:UIControlStateNormal];
                    b.titleLabel.superview.backgroundColor = [UIColor clearColor];
                }
                i++;
            }
        }
    }
}

-(void)suggestionTapped:(UIButton *)sender {
    [[UIDevice currentDevice] playInputClick];
    [_completionDelegate nickSelected:sender.titleLabel.text];
}

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}
@end
