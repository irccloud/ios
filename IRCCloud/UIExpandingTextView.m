/*
 *  UIExpandingTextView.m
 *  
 *  Created by Brandon Hamilton on 2011/05/03.
 *  Copyright 2011 Brandon Hamilton.
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

/* 
 *  This class is based on growingTextView by Hans Pickaers 
 *  http://www.hanspinckaers.com/multi-line-uitextview-similar-to-sms
 */

#import "UIExpandingTextView.h"

#define kTextInsetX ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)?2:4
#define kTextInsetBottom 0

@implementation UIExpandingTextView

@synthesize internalTextView;
@synthesize delegate;

@synthesize text;
@synthesize font;
@synthesize textColor;
@synthesize textAlignment; 
@synthesize selectedRange;
@synthesize editable;
@synthesize dataDetectorTypes; 
@synthesize animateHeightChange;
@synthesize returnKeyType;
@synthesize textViewBackgroundImage;
@synthesize placeholder;
@synthesize minimumHeight;

- (void)setPlaceholder:(NSString *)placeholders
{
    placeholder = placeholders;
    placeholderLabel.text = placeholders;
}

- (int)minimumNumberOfLines
{
    return minimumNumberOfLines;
}

- (int)maximumNumberOfLines
{
    return maximumNumberOfLines;
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {
        forceSizeUpdate = NO;
		CGRect backgroundFrame = frame;
        backgroundFrame.origin.y = 0;
		backgroundFrame.origin.x = 0;
        
        CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0);

        /* Internal Text View component */
		internalTextView = [[UIExpandingTextViewInternal alloc] initWithFrame:textViewFrame];
		internalTextView.delegate        = self;
		internalTextView.font            = [UIFont systemFontOfSize:15.0]; 
		internalTextView.contentInset    = UIEdgeInsetsMake(-1,0,-1,0);
        internalTextView.text            = @"-";
		internalTextView.scrollEnabled   = NO;
        internalTextView.opaque          = NO;
        internalTextView.backgroundColor = [UIColor clearColor];
        internalTextView.showsHorizontalScrollIndicator = NO;
        [internalTextView sizeToFit];
        
        /* set placeholder */
        placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(8,3,self.bounds.size.width - 16,self.bounds.size.height)];
        placeholderLabel.text = placeholder;
        placeholderLabel.font = internalTextView.font;
        placeholderLabel.backgroundColor = [UIColor clearColor];
        placeholderLabel.textColor = [UIColor grayColor];
        [internalTextView addSubview:placeholderLabel];
        
        /* Custom Background image */
        textViewBackgroundImage = [[UIImageView alloc] initWithFrame:backgroundFrame];
        textViewBackgroundImage.image          = [UIImage imageNamed:@"textbg"];
        textViewBackgroundImage.contentMode    = UIViewContentModeScaleToFill;
        textViewBackgroundImage.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
        
        [self addSubview:textViewBackgroundImage];
        [self addSubview:internalTextView];

		[self setMinimumNumberOfLines:1];
		animateHeightChange = YES;
		internalTextView.text = @"";
		[self setMaximumNumberOfLines:13];
        internalTextView.scrollEnabled = YES;
        
        [self sizeToFit];
    }
    return self;
}

-(void)sizeToFit
{
    CGRect r = self.frame;
    if ([self.text length] > 0) 
    {
        /* No need to resize is text is not empty */
        return;
    }
    r.size.height = minimumHeight + kTextInsetBottom;
    self.frame = r;
}

-(void)setFrame:(CGRect)aframe
{
    CGRect backgroundFrame   = aframe;
    backgroundFrame.origin.y = 0;
    backgroundFrame.origin.x = 0;
    backgroundFrame.size.height  -= 8;
    textViewBackgroundImage.frame = backgroundFrame;
    backgroundFrame.origin.x -= 4;
    backgroundFrame.size.width += 4;
    CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0);
	internalTextView.frame   = textViewFrame;
    forceSizeUpdate = YES;
	[super setFrame:aframe];
}

-(void)clearText
{
    self.text = @"";
    [self textViewDidChange:self.internalTextView];
}
     
-(void)setMaximumNumberOfLines:(int)n
{
    if (maximumNumberOfLines == n)
        return;
    
    NSRange saveSelection     = internalTextView.selectedRange;
    NSString *saveText        = internalTextView.text;
    NSString *newText         = @"-";
    BOOL oldScrollEnabled     = internalTextView.scrollEnabled;
    internalTextView.hidden   = YES;
    internalTextView.delegate = nil;
    internalTextView.scrollEnabled = NO;
    for (int i = 2; i < n; ++i)
    {
        newText = [newText stringByAppendingString:@"\n|W|"];
    }
    internalTextView.text     = newText;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
        maximumHeight             = internalTextView.contentSize.height;
    else
        maximumHeight             = internalTextView.intrinsicContentSize.height;
    maximumNumberOfLines      = n;
    internalTextView.scrollEnabled = ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)?oldScrollEnabled:YES;
    internalTextView.text     = saveText;
    internalTextView.hidden   = NO;
    internalTextView.selectedRange = saveSelection;
    internalTextView.delegate = self;
    forceSizeUpdate = YES;
    [self textViewDidChange:self.internalTextView];
}

-(void)setMinimumNumberOfLines:(int)m
{
    if (minimumNumberOfLines == m)
        return;
    
    NSRange saveSelection     = internalTextView.selectedRange;
    NSString *saveText        = internalTextView.text;
    NSString *newText         = @"-";
    BOOL oldScrollEnabled     = internalTextView.scrollEnabled;
    internalTextView.hidden   = YES;
    internalTextView.delegate = nil;
    internalTextView.scrollEnabled = NO;
    for (int i = 2; i < m; ++i)
    {
        newText = [newText stringByAppendingString:@"\n|W|"];
    }
    internalTextView.text     = newText;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
        minimumHeight             = internalTextView.contentSize.height;
    else
        minimumHeight             = internalTextView.intrinsicContentSize.height;
    internalTextView.scrollEnabled = ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)?oldScrollEnabled:YES;
    internalTextView.text     = saveText;
    internalTextView.hidden   = NO;
    internalTextView.selectedRange = saveSelection;
    internalTextView.delegate = self;
    [self sizeToFit];
    minimumNumberOfLines = m;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if(textView.text.length == 0) {
        internalTextView.contentOffset = CGPointMake(0,0);
        placeholderLabel.alpha = 1;
    } else {
        placeholderLabel.alpha = 0;
    }
    
    NSInteger newHeight = ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)?internalTextView.contentSize.height:[textView.text sizeWithFont:textView.font constrainedToSize:CGSizeMake(internalTextView.bounds.size.width - 12, maximumHeight) lineBreakMode:NSLineBreakByWordWrapping].height + 17;
    
	if(newHeight < minimumHeight || !internalTextView.hasText)
    {
        newHeight = minimumHeight;
    }
    
	if (internalTextView.frame.size.height != newHeight || forceSizeUpdate)
	{
        forceSizeUpdate = NO;
        if (newHeight > maximumHeight && internalTextView.frame.size.height <= maximumHeight)
        {
            newHeight = maximumHeight;
        }

        if(animateHeightChange)
        {
            [UIView beginAnimations:@"" context:nil];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(growDidStop)];
            [UIView setAnimationBeginsFromCurrentState:YES];
        }
        
        if ([delegate respondsToSelector:@selector(expandingTextView:willChangeHeight:)]) 
        {
            [delegate expandingTextView:self willChangeHeight:(newHeight+ kTextInsetBottom)];
        }
        
        /* Resize the frame */
        CGRect r = self.frame;
        r.size.height = (newHeight<maximumHeight)?newHeight:maximumHeight + kTextInsetBottom;
        self.frame = r;
        r.origin.y = 0;
        r.origin.x = 0;
        r.size.height -= 8;
        textViewBackgroundImage.frame = r;
        r.origin.x -= 4;
        r.size.width += 4;
        internalTextView.frame = CGRectInset(r, kTextInsetX, 0);
        internalTextView.contentInset = UIEdgeInsetsMake(-1,0,-1,0);
        
        if(animateHeightChange)
        {
            [UIView commitAnimations];
        }
        else if ([delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)]) 
        {
            [delegate expandingTextView:self didChangeHeight:(newHeight+ kTextInsetBottom)];
        }
		
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
            if (newHeight >= maximumHeight)
            {
                if(!internalTextView.scrollEnabled)
                {
                    internalTextView.scrollEnabled = YES;
                    [internalTextView flashScrollIndicators];
                }
            } 
            else 
            {
                internalTextView.scrollEnabled = NO;
            }
        } else {
            internalTextView.scrollEnabled = YES;
        }
	}
	
	if ([delegate respondsToSelector:@selector(expandingTextViewDidChange:)]) 
    {
		[delegate expandingTextViewDidChange:self];
	}
}

-(void)growDidStop
{
	if ([delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)]) 
    {
		[delegate expandingTextView:self didChangeHeight:self.frame.size.height];
	}
}

-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [internalTextView resignFirstResponder];
}

#pragma mark UITextView properties

-(void)setText:(NSString *)atext
{
	internalTextView.text = atext;
    [self performSelector:@selector(textViewDidChange:) withObject:internalTextView];
}

-(NSString*)text
{
	return internalTextView.text;
}

-(void)setFont:(UIFont *)afont
{
	internalTextView.font= afont;
	[self setMaximumNumberOfLines:maximumNumberOfLines];
	[self setMinimumNumberOfLines:minimumNumberOfLines];
}

-(UIFont *)font
{
	return internalTextView.font;
}	

-(void)setTextColor:(UIColor *)color
{
	internalTextView.textColor = color;
}

-(UIColor*)textColor
{
	return internalTextView.textColor;
}

-(void)setTextAlignment:(NSTextAlignment)aligment
{
	internalTextView.textAlignment = aligment;
}

-(NSTextAlignment)textAlignment
{
	return internalTextView.textAlignment;
}

-(void)setSelectedRange:(NSRange)range
{
	internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
	return internalTextView.selectedRange;
}

-(void)setEditable:(BOOL)beditable
{
	internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
	return internalTextView.editable;
}

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
	internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
	return internalTextView.returnKeyType;
}

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
	internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
	return internalTextView.dataDetectorTypes;
}

- (BOOL)hasText
{
	return [internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
	[internalTextView scrollRangeToVisible:range];
}

#pragma mark -
#pragma mark UIExpandingTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewShouldBeginEditing:)]) 
    {
		return [delegate expandingTextViewShouldBeginEditing:self];
	} 
    else 
    {
		return YES;
	}
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewShouldEndEditing:)]) 
    {
		return [delegate expandingTextViewShouldEndEditing:self];
	} 
    else 
    {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewDidBeginEditing:)]) 
    {
		[delegate expandingTextViewDidBeginEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView 
{		
	if ([delegate respondsToSelector:@selector(expandingTextViewDidEndEditing:)]) 
    {
		[delegate expandingTextViewDidEndEditing:self];
	}
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext 
{
	if(![textView hasText] && [atext isEqualToString:@""]) 
    {
        return NO;
	}
    
	if ([atext isEqualToString:@"\n"]) 
    {
		if ([delegate respondsToSelector:@selector(expandingTextViewShouldReturn:)]) 
        {
			return [delegate expandingTextViewShouldReturn:self];
        }
	}

    if ([delegate respondsToSelector:@selector(expandingTextView:shouldChangeTextInRange:replacementText:)])
    {
        return [delegate expandingTextView:self shouldChangeTextInRange:range replacementText:atext];
    }
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView 
{
	if ([delegate respondsToSelector:@selector(expandingTextViewDidChangeSelection:)]) 
    {
		[delegate expandingTextViewDidChangeSelection:self];
	}
}

- (BOOL)becomeFirstResponder {
    return [internalTextView becomeFirstResponder];
}

- (CGSize)intrinsicContentSize		// suport  autolayout
{
    return internalTextView.intrinsicContentSize;
}

@end
