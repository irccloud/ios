//
//  EditConnectionViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 4/29/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EditConnectionViewController : UITableViewController<UITextFieldDelegate> {
    UITextField *_server;
    UITextField *_port;
    UISwitch *_ssl;
    UITextField *_nickname;
    UITextField *_realname;
    UITextField *_nspass;
    UITextField *_serverpass;
    UITextView *_commands;
    int _cid;
    int _reqid;
    NSString *_netname;
}
-(void)setServer:(int)cid;
@end
