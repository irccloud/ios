//
//  SettingsViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/19/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController<UITextFieldDelegate,UITextViewDelegate> {
    UITextField *_email;
    UITextField *_name;
    UITextView *_highlights;
    UISwitch *_autoaway;
    UISwitch *_24hour;
    UISwitch *_seconds;
    UISwitch *_symbols;
    NSString *_version;
    int _userinforeqid;
    int _prefsreqid;
    BOOL _userinfosaved;
    BOOL _prefssaved;
}
@end
