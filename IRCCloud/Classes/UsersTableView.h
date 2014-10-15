//
//  UsersTableView.h
//
//  Copyright (C) 2013 IRCCloud, Ltd.
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
#import "BuffersDataSource.h"

@protocol UsersTableViewDelegate<NSObject>
-(void)userSelected:(NSString *)nick rect:(CGRect)rect;
-(void)dismissKeyboard;
@end

@interface UsersTableView : UITableViewController<UIGestureRecognizerDelegate> {
    NSArray *_data;
    NSMutableArray *_sectionTitles;
    NSMutableArray *_sectionIndexes;
    NSMutableArray *_sectionSizes;
    Buffer *_buffer;
    IBOutlet id<UsersTableViewDelegate> delegate;
    NSTimer *_refreshTimer;
    UIFont *_headingFont;
    UIFont *_countFont;
    UIFont *_userFont;
}
-(void)setBuffer:(Buffer *)buffer;
-(void)refresh;
@end
