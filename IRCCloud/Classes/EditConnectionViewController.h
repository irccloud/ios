//
//  EditConnectionViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 4/29/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NetworkListDelegate <NSObject>
-(void)setNetwork:(NSString *)network host:(NSString *)host port:(int)port SSL:(BOOL)SSL;
@end

@interface EditConnectionViewController : UITableViewController<UITextFieldDelegate,NetworkListDelegate> {
    UITextField *_server;
    UITextField *_port;
    UISwitch *_ssl;
    UITextField *_nickname;
    UITextField *_realname;
    UITextField *_nspass;
    UITextField *_serverpass;
    UITextView *_commands;
    UITextView *_channels;
    int _cid;
    int _reqid;
    NSString *_netname;
    NSURL *_url;
}
-(void)setServer:(int)cid;
-(void)setURL:(NSURL *)url;
@end
