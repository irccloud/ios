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
            _fgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _fgLabel.font = [UIFont boldSystemFontOfSize:14];
            _fgLabel.text = @"Foreground Color";
            [self addSubview:_fgLabel];
            _fg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            [_fg[i] addTarget:self action:@selector(fgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_fg[i]];
            _bgLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            _bgLabel.font = [UIFont boldSystemFontOfSize:14];
            _bgLabel.text = @"Background Color";
            [self addSubview:_bgLabel];
            _bg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            [_bg[i] addTarget:self action:@selector(bgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:_bg[i]];
            [self addTarget:self action:@selector(close:) forControlEvents:UIControlEventTouchUpOutside];
        }
        [self updateButtonColors];
    }
    return self;
}

-(void)fgButtonPressed:(UIButton *)sender {
    [_delegate foregroundColorPicked:sender.backgroundColor];
}

-(void)bgButtonPressed:(UIButton *)sender {
    [_delegate backgroundColorPicked:sender.backgroundColor];
}

-(void)close:(id)sender {
    [_delegate closeColorPicker];
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(272, 176);
}

-(void)layoutSubviews {
    CGFloat bw = self.frame.size.width / 8;
    _fgLabel.frame = CGRectMake(0,2,self.frame.size.width,16);
    
    for(int i = 0; i < 8; i++) {
        _fg[i].frame = CGRectMake(i*bw + 1, 20, bw - 2, 32);
    }

    for(int i = 0; i < 8; i++) {
        _fg[i+8].frame = CGRectMake(i*bw + 1, 54, bw - 2, 32);
    }
    
    _bgLabel.frame = CGRectMake(0,88,self.frame.size.width,16);
    
    for(int i = 0; i < 8; i++) {
        _bg[i].frame = CGRectMake(i*bw + 1, 108, bw - 2, 32);
    }
    
    for(int i = 0; i < 8; i++) {
        _bg[i+8].frame = CGRectMake(i*bw + 1, 142, bw - 2, 32);
    }
}

-(void)updateButtonColors {
    self.backgroundColor = [UIColor textareaBackgroundColor];
    _fgLabel.textColor = _bgLabel.textColor = [UIColor navBarHeadingColor];
    
    for(int i = 0; i < 16; i++)
        _fg[i].backgroundColor = [UIColor mIRCColor:i background:NO];

    for(int i = 0; i < 16; i++)
        _bg[i].backgroundColor = [UIColor mIRCColor:i background:YES];
}

@end
