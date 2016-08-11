//
//  LinkLabel.m
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

#import "LinkLabel.h"

NSTextStorage *__LinkLabelTextStorage;
NSTextContainer *__LinkLabelTextContainer;
NSLayoutManager *__LinkLabelLayoutManager;

@implementation LinkLabel

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _links = [[NSMutableArray alloc] init];
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        [self addGestureRecognizer:_tapGesture];
    }
    return self;
}

- (void)viewTapped:(UITapGestureRecognizer *)sender {
    if(_linkDelegate && sender.state == UIGestureRecognizerStateEnded) {
        NSTextCheckingResult *r = [self linkAtPoint:[sender locationInView:self]];
        if(r) {
            [_linkDelegate LinkLabel:self didSelectLinkWithTextCheckingResult:r];
        } else {
            UIView *obj = self;
            
            do {
                obj = obj.superview;
            } while (obj && ![obj isKindOfClass:[UITableViewCell class]]);
            if(obj) {
                UITableViewCell *cell = (UITableViewCell*)obj;
                
                do {
                    obj = obj.superview;
                } while (![obj isKindOfClass:[UITableView class]]);
                UITableView *tableView = (UITableView*)obj;
                
                NSIndexPath *indePath = [tableView indexPathForCell:cell];
                [[tableView delegate] tableView:tableView didSelectRowAtIndexPath:indePath];
            }
        }
    }
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [_links addObject:result];
    NSMutableAttributedString *s = self.attributedText.mutableCopy;
    [s addAttributes:self.linkAttributes range:result.range];
    self.attributedText = s;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p {
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [textStorage addLayoutManager:layoutManager];
    
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX)];
    textContainer.lineFragmentPadding  = 0;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    textContainer.lineBreakMode        = self.lineBreakMode;
    
    [layoutManager addTextContainer:textContainer];
    
    NSUInteger start = [layoutManager characterIndexForPoint:p inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:NULL];
    if(start == self.attributedText.length - 1) {
        NSRange glyphRange;
        [layoutManager characterRangeForGlyphRange:NSMakeRange(start, 1) actualGlyphRange:&glyphRange];
        CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
        if(!CGRectContainsPoint(rect, p))
            return nil;
    }
    
    for(NSTextCheckingResult *r in _links) {
        if(NSLocationInRange(start, r.range))
            return r;
    }
    return nil;
}

+(CGFloat)heightOfString:(NSAttributedString *)text constrainedToWidth:(CGFloat)width {
    if(!__LinkLabelTextStorage) {
        __LinkLabelTextStorage = [[NSTextStorage alloc] init];
        __LinkLabelLayoutManager = [[NSLayoutManager alloc] init];
        [__LinkLabelTextStorage addLayoutManager:__LinkLabelLayoutManager];
        __LinkLabelTextContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
        __LinkLabelTextContainer.lineFragmentPadding = 0;
        __LinkLabelTextContainer.lineBreakMode = NSLineBreakByWordWrapping;
        [__LinkLabelLayoutManager addTextContainer:__LinkLabelTextContainer];
    }
    @synchronized (__LinkLabelTextStorage) {
        __LinkLabelTextContainer.size = CGSizeMake(width, CGFLOAT_MAX);
        [__LinkLabelTextStorage setAttributedString:text];
        (void) [__LinkLabelLayoutManager glyphRangeForTextContainer:__LinkLabelTextContainer];
        return [__LinkLabelLayoutManager usedRectForTextContainer:__LinkLabelTextContainer].size.height;
    }
}

@end
