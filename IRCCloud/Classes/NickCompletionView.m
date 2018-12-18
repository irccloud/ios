//
//  NickCompletionView.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
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

#import "NickCompletionView.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"

@interface NickCompletionCell : UICollectionViewCell {
    UILabel *_label;
}
@property (readonly)UILabel *label;
@end

@implementation NickCompletionCell
-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_label = [[UILabel alloc] init];
        self->_label.textAlignment = NSTextAlignmentCenter;
        self->_label.textColor = [UIColor bufferTextColor];
        [self.contentView addSubview:self->_label];
    }
    return self;
}

-(void)layoutSubviews {
    self->_label.frame = self.bounds;
}

-(void)setSelected:(BOOL)selected {
    self.contentView.backgroundColor = selected ? [UIColor selectedBufferBackgroundColor] : [UIColor clearColor];
    self->_label.textColor = selected ? [UIColor selectedBufferTextColor] : [UIColor bufferTextColor];
}
@end

@implementation NickCompletionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self->_selection = -1;
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
        layout.minimumInteritemSpacing = 0;
        layout.minimumLineSpacing = 0;
        self->_collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        self->_collectionView.dataSource = self;
        self->_collectionView.delegate = self;
        [self->_collectionView registerClass:NickCompletionCell.class forCellWithReuseIdentifier:@"NickCompletionCell"];
        self->_collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        self->_collectionView.layer.masksToBounds = YES;
        self->_collectionView.layer.cornerRadius = 4;
        self->_collectionView.allowsSelection = YES;
        self->_collectionView.allowsMultipleSelection = NO;
        self->_collectionView.scrollEnabled = NO;
        [self addSubview:self->_collectionView];
        [self addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:self->_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:self->_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-1.0f],
                               [NSLayoutConstraint constraintWithItem:self->_collectionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:self->_collectionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-1.0f]
                               ]];
        [self setSuggestions:@[]];
    }
    return self;
}

-(CGSize)intrinsicContentSize {
    return CGSizeMake(self.bounds.size.width, 36);
}

-(void)setSuggestions:(NSArray *)suggestions {
    self->_suggestions = suggestions;
    self->_selection = -1;
    self->_font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    CGFloat width = 0;
    for(NSString *s in _suggestions) {
        width += [s sizeWithAttributes:@{NSFontAttributeName:self->_font}].width + 12;
        if(width > self.bounds.size.width)
            break;
    }
    
    if(width < self.bounds.size.width)
        self->_collectionView.contentInset = UIEdgeInsetsMake(0, ((self.bounds.size.width - width) / 2) - 4, 0, 0);
    else
        self->_collectionView.contentInset = UIEdgeInsetsZero;
    self->_collectionView.scrollEnabled = width > self.bounds.size.width;

    self.backgroundColor = [UIColor bufferBorderColor];
    self->_collectionView.backgroundColor = [UIColor bufferBackgroundColor];
    [self->_collectionView reloadData];
}

-(NSString *)suggestion {
    if(self->_selection == -1 || _selection >= self->_suggestions.count)
        return nil;
    NSString *suggestion = [self->_suggestions objectAtIndex:self->_selection];
    if([suggestion rangeOfString:@"\u00a0("].location != NSNotFound) {
        NSUInteger nickIndex = [suggestion rangeOfString:@"(" options:NSBackwardsSearch].location;
        suggestion = [suggestion substringWithRange:NSMakeRange(nickIndex + 1, suggestion.length - nickIndex - 2)];
    }
    
    return suggestion;
}

-(NSUInteger)count {
    return _suggestions.count;
}

-(NSInteger)selection {
    return _selection;
}

-(void)setSelection:(NSInteger)selection {
    self->_selection = selection;
    [self->_collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:selection inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _suggestions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NickCompletionCell *cell = [self->_collectionView dequeueReusableCellWithReuseIdentifier:@"NickCompletionCell" forIndexPath:indexPath];
    cell.label.font = self->_font;
    cell.label.text = [self->_suggestions objectAtIndex:indexPath.row];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([[self->_suggestions objectAtIndex:indexPath.row] sizeWithAttributes:@{NSFontAttributeName:self->_font}].width + 12, _collectionView.frame.size.height - 1);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [[UIDevice currentDevice] playInputClick];
    self->_selection = indexPath.row;
    [self->_completionDelegate nickSelected:self.suggestion];
}

-(BOOL)enableInputClicksWhenVisible {
    return YES;
}
@end
