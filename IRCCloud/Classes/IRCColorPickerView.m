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
        _background = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:_background];
        for(int i = 0; i < 16; i++) {
            _fg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            [_fg[i] addTarget:self action:@selector(fgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [_background addSubview:_fg[i]];
            _bg[i] = [UIButton buttonWithType:UIButtonTypeCustom];
            [_bg[i] addTarget:self action:@selector(bgButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [_background addSubview:_bg[i]];
        }
        self.layer.masksToBounds = YES;
        self.layer.cornerRadius = 4;
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
    return CGSizeMake(308, 76);
}

-(void)layoutSubviews {
    _background.frame = CGRectInset(self.bounds, 2, 2);
    CGFloat bw = _background.bounds.size.width / 8;

    for(int i = 0; i < 8; i++) {
        _fg[i].frame = CGRectMake(i*bw + 3, 3, bw - 6, bw - 6);
        _fg[i].layer.cornerRadius = (bw - 6) / 2;
        _bg[i].frame = CGRectMake(i*bw + 3, 3, bw - 6, bw - 6);
        _bg[i].layer.cornerRadius = (bw - 6) / 2;
    }

    for(int i = 0; i < 8; i++) {
        _fg[i+8].frame = CGRectMake(i*bw + 3, 38, bw - 6, bw - 6);
        _fg[i+8].layer.cornerRadius = (bw - 6) / 2;
        _bg[i+8].frame = CGRectMake(i*bw + 3, 38, bw - 6, bw - 6);
        _bg[i+8].layer.cornerRadius = (bw - 6) / 2;
    }
}

-(void)updateButtonColors:(BOOL)background {
    self.backgroundColor = [UIColor bufferBorderColor];
    _background.backgroundColor = [UIColor bufferBackgroundColor];
    
    for(int i = 0; i < 16; i++)
        _fg[i].backgroundColor = [UIColor mIRCColor:i background:NO];

    for(int i = 0; i < 16; i++)
        _bg[i].backgroundColor = [UIColor mIRCColor:i background:YES];
    
    if(background) {
        for(int i = 0; i < 16; i++)
            _fg[i].hidden = YES;
        for(int i = 0; i < 16; i++)
            _bg[i].hidden = NO;
    } else {
        for(int i = 0; i < 16; i++)
            _fg[i].hidden = NO;
        for(int i = 0; i < 16; i++)
            _bg[i].hidden = YES;
    }
}

@end
