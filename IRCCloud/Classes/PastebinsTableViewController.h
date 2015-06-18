//
//  PastebinsTableViewController.h
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
#import "CSURITemplate.h"

@protocol PastebinsTableViewDelegate<NSObject>
-(void)pastebinsTableViewControllerDidSelectFile:(NSDictionary *)file message:(NSString *)message;
@end

@interface PastebinsTableViewController : UITableViewController {
    int _pages;
    NSArray *_pastes;
    int _reqid;
    BOOL _canLoadMore;
    id<PastebinsTableViewDelegate> _delegate;
    UIView *_footerView;
    NSDictionary *_selectedPaste;
    CSURITemplate *_url_template;
    NSDictionary *_fileTypeMap;
    NSMutableDictionary *_extensions;
}
@property id<PastebinsTableViewDelegate> delegate;
@end
