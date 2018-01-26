//
//  NickCompletionView.h
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

#import <UIKit/UIKit.h>

@protocol NickCompletionViewDelegate<NSObject>
-(void)nickSelected:(NSString *)nick;
@end

@interface NickCompletionView : UIView<UIInputViewAudioFeedback,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout> {
    UICollectionView *_collectionView;
    NSArray *_suggestions;
    UIFont *_font;
    NSInteger _selection;
}
@property (readonly) UIFont *font;
@property (nonatomic, assign) id<NickCompletionViewDelegate> completionDelegate;
@property NSInteger selection;
-(void)setSuggestions:(NSArray *)suggestions;
-(NSUInteger)count;
-(NSString *)suggestion;
@end
