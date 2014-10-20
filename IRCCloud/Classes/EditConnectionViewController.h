//
//  EditConnectionViewController.h
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

@protocol NetworkListDelegate <NSObject>
-(void)setNetwork:(NSString *)network host:(NSString *)host port:(int)port SSL:(BOOL)SSL;
@end

@interface EditConnectionViewController : UITableViewController<UITextFieldDelegate,NetworkListDelegate,UITextViewDelegate,UIAlertViewDelegate,UIGestureRecognizerDelegate> {
    UITextField *_server;
    UITextField *_port;
    UISwitch *_ssl;
    UITextField *_nickname;
    UITextField *_realname;
    UITextField *_nspass;
    UITextField *_serverpass;
    UITextField *_network;
    UITextView *_commands;
    UITextView *_channels;
    int _cid;
    int _reqid;
    NSString *_netname;
    NSURL *_url;
    BOOL keyboardShown;
    CGFloat keyboardOverlap;
    NSIndexPath *_activeCellIndexPath;
}
-(void)setServer:(int)cid;
-(void)setURL:(NSURL *)url;
@end
