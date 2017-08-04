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
        _label = [[UILabel alloc] init];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.textColor = [UIColor bufferTextColor];
        [self.contentView addSubview:_label];
    }
    return self;
}

-(void)layoutSubviews {
    _label.frame = self.bounds;
}

-(void)setSelected:(BOOL)selected {
    self.contentView.backgroundColor = selected ? [UIColor selectedBufferBackgroundColor] : [UIColor clearColor];
    _label.textColor = selected ? [UIColor selectedBufferTextColor] : [UIColor bufferTextColor];
}
@end

@implementation NickCompletionView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _selection = -1;
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.sectionInset = UIEdgeInsetsMake(0, 6, 0, 6);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:NickCompletionCell.class forCellWithReuseIdentifier:@"NickCompletionCell"];
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        _collectionView.layer.masksToBounds = YES;
        _collectionView.layer.cornerRadius = 4;
        _collectionView.allowsSelection = YES;
        _collectionView.allowsMultipleSelection = NO;
        _collectionView.scrollEnabled = NO;
        [self addSubview:_collectionView];
        [self addConstraints:@[
                               [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-1.0f],
                               [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0f constant:1.0f],
                               [NSLayoutConstraint constraintWithItem:_collectionView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0f constant:-1.0f]
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
    _selection = -1;
    _font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    CGFloat width = 0;
    for(NSString *s in _suggestions) {
        width += [s sizeWithAttributes:@{NSFontAttributeName:_font}].width + 8;
        if(width > self.bounds.size.width)
            break;
    }
    
    if(width < self.bounds.size.width)
        _collectionView.contentInset = UIEdgeInsetsMake(0, ((self.bounds.size.width - width) / 2) - 4, 0, 0);
    else
        _collectionView.contentInset = UIEdgeInsetsZero;
    _collectionView.scrollEnabled = width > self.bounds.size.width;

    self.backgroundColor = [UIColor bufferBorderColor];
    _collectionView.backgroundColor = [UIColor bufferBackgroundColor];
    [_collectionView reloadData];
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
    [_collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:selection inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _suggestions.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NickCompletionCell *cell = [_collectionView dequeueReusableCellWithReuseIdentifier:@"NickCompletionCell" forIndexPath:indexPath];
    cell.label.font = _font;
    cell.label.text = [_suggestions objectAtIndex:indexPath.row];
    return cell;
}

-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([[_suggestions objectAtIndex:indexPath.row] sizeWithAttributes:@{NSFontAttributeName:_font}].width + 8, _collectionView.frame.size.height - 1);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [[UIDevice currentDevice] playInputClick];
    [_completionDelegate nickSelected:[_suggestions objectAtIndex:indexPath.row]];
}

-(BOOL)enableInputClicksWhenVisible {
    return YES;
}
@end
