//
//  IRCColorPickerView.m
//
//  Copyright (C) 2017 IRCCloud, Ltd.
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

#import "IRCColorPickerView.h"
#import "UIColor+IRCCloud.h"

@implementation IRCColorPickerView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        for(int i = 0; i < 16; i++) {
            self->_fg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            self->_fg[i].layer.borderColor = [UIColor blackColor].CGColor;
            self->_fg[i].layer.borderWidth = 1;
            [self->_fg[i] addTarget:self action:@selector(fgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:self->_fg[i]];
            self->_bg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            self->_bg[i].layer.borderColor = [UIColor blackColor].CGColor;
            self->_bg[i].layer.borderWidth = 1;
            [self->_bg[i] addTarget:self action:@selector(bgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:self->_bg[i]];
        }
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 4;
    }
    return self;
}

-(void)fgButtonPressed:(UIButton *)sender {
    [self->_delegate foregroundColorPicked:sender.backgroundColor];
}

-(void)bgButtonPressed:(UIButton *)sender {
    [self->_delegate backgroundColorPicked:sender.backgroundColor];
}

-(void)close:(id)sender {
    [self->_delegate closeColorPicker];
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(304, 73);
}

-(void)layoutSubviews {
    CGFloat bw = self.bounds.size.width / 8;

    for(int i = 0; i < 8; i++) {
        self->_fg[i].frame = CGRectMake(i*bw + 3, 3, bw - 6, bw - 6);
        self->_fg[i].layer.cornerRadius = (bw - 6) / 2;
        self->_bg[i].frame = CGRectMake(i*bw + 3, 3, bw - 6, bw - 6);
        self->_bg[i].layer.cornerRadius = (bw - 6) / 2;
    }

    for(int i = 0; i < 8; i++) {
        self->_fg[i+8].frame = CGRectMake(i*bw + 3, 38, bw - 6, bw - 6);
        self->_fg[i+8].layer.cornerRadius = (bw - 6) / 2;
        self->_bg[i+8].frame = CGRectMake(i*bw + 3, 38, bw - 6, bw - 6);
        self->_bg[i+8].layer.cornerRadius = (bw - 6) / 2;
    }
}

-(void)updateButtonColors:(BOOL)background {
    self.backgroundColor = [UIColor bufferBackgroundColor];
    //self.layer.borderWidth = 1;
    //self.layer.borderColor = [UIColor bufferBorderColor].CGColor;

    for(int i = 0; i < 16; i++)
        self->_fg[i].backgroundColor = [UIColor mIRCColor:i background:NO];

    for(int i = 0; i < 16; i++)
        self->_bg[i].backgroundColor = [UIColor mIRCColor:i background:YES];
    
    if(background) {
        for(int i = 0; i < 16; i++)
            self->_fg[i].hidden = YES;
        for(int i = 0; i < 16; i++)
            self->_bg[i].hidden = NO;
    } else {
        for(int i = 0; i < 16; i++)
            self->_fg[i].hidden = NO;
        for(int i = 0; i < 16; i++)
            self->_bg[i].hidden = YES;
    }
}

@end
