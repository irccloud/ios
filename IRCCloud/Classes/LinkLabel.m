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

#import <CoreText/CoreText.h>
#import "LinkLabel.h"

@implementation LinkLabel

- (void)viewTapped:(UITapGestureRecognizer *)sender {
    if(sender.state == UIGestureRecognizerStateEnded) {
        NSTextCheckingResult *r = [self linkAtPoint:[sender locationInView:self]];
        if(r && _linkDelegate) {
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

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    NSTextCheckingResult *r = [self linkAtPoint:[touch locationInView:self]];
    return (r && _linkDelegate);
}

- (void)addLinkToURL:(NSURL *)url withRange:(NSRange)range {
    [self addLinkWithTextCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:url]];
}

- (void)addLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    if(!_links) {
        _links = [[NSMutableArray alloc] init];
    }
    if(!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
        _tapGesture.delegate = self;
        [self addGestureRecognizer:_tapGesture];
    }
    NSMutableAttributedString *s = self.attributedText.mutableCopy;
    [s addAttributes:self.linkAttributes range:result.range];
    [super setAttributedText:s];
    [_links addObject:result];
}

-(void)setText:(NSString *)text {
    [_links removeAllObjects];
    [super setText:text];
}

-(void)setAttributedText:(NSAttributedString *)attributedText {
    [_links removeAllObjects];
    [super setAttributedText:attributedText];
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
    if(text) {
        CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
        CFRange fitRange;
        CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), NULL, CGSizeMake(width, CGFLOAT_MAX), &fitRange);
        
        CFRelease(framesetter);
        
        return frameSize.height;
    } else {
        return 0;
    }
}

@end
