//
//  ChannelModeListTableViewController.h
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
#import "IRCCloudJSONObject.h"

@interface ChannelModeListTableViewController : UITableViewController<UIAlertViewDelegate,UITextFieldDelegate> {
    NSArray *_data;
    IRCCloudJSONObject *_event;
    UIBarButtonItem *_addButton;
    int _bid;
    int _list;
    UILabel *_placeholder;
    UIAlertView *_alertView;
    NSString *_mode;
    NSString *_param;
    NSString *_mask;
}
@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) IRCCloudJSONObject *event;
@property NSString *mask;

-(id)initWithList:(int)list mode:(NSString *)mode param:(NSString *)param placeholder:(NSString *)placeholder bid:(int)bid;
@end
