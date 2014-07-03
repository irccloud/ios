//
//  SettingsViewController.m
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

#import "SettingsViewController.h"
#import "NetworkConnection.h"
#import "LicenseViewController.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"
#import "OpenInChromeController.h"
#import "ImgurLoginViewController.h"

@interface BGTimeoutViewController : UITableViewController
@end

@implementation BGTimeoutViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Background Timeout";
    }
    return self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"timeoutcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"timeoutcell"];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch(indexPath.row) {
        case 0:
            cell.textLabel.text = @"30 seconds";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] == 30)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 1:
            cell.textLabel.text = @"1 minute";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] == 60)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 2:
            cell.textLabel.text = @"5 minutes";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] == 300)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 3:
            cell.textLabel.text = @"10 minutes";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] == 600)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:@(30) forKey:@"bgTimeout"];
            break;
        case 1:
            [[NSUserDefaults standardUserDefaults] setObject:@(60) forKey:@"bgTimeout"];
            break;
        case 2:
            [[NSUserDefaults standardUserDefaults] setObject:@(300) forKey:@"bgTimeout"];
            break;
        case 3:
            [[NSUserDefaults standardUserDefaults] setObject:@(600) forKey:@"bgTimeout"];
            break;
    }
    [tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Settings";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        OpenInChromeController *c = [[OpenInChromeController alloc] init];
        _chromeInstalled = [c isChromeInstalled];
    }
    return self;
}

-(void)saveButtonPressed:(id)sender {
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
    
    [prefs setObject:@(_24hour.isOn) forKey:@"time-24hr"];
    [prefs setObject:@(_seconds.isOn) forKey:@"time-seconds"];
    [prefs setObject:@(_symbols.isOn) forKey:@"mode-showsymbol"];
    [prefs setObject:@(_colors.isOn) forKey:@"nick-colors"];
    [prefs setObject:@(!_emocodes.isOn) forKey:@"emoji-disableconvert"];
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSString *json = [writer stringWithObject:prefs];
    
    _userinfosaved = NO;
    _prefssaved = NO;
    _userinforeqid = [[NetworkConnection sharedInstance] setEmail:_email.text realname:_name.text highlights:_highlights.text autoaway:_autoaway.isOn];
    _prefsreqid = [[NetworkConnection sharedInstance] setPrefs:json];
    
    [[NSUserDefaults standardUserDefaults] setBool:_screen.on forKey:@"keepScreenOn"];
    [[NSUserDefaults standardUserDefaults] setBool:_chrome.on forKey:@"useChrome"];
    [[NSUserDefaults standardUserDefaults] setBool:_autoCaps.on forKey:@"autoCaps"];
    [[NSUserDefaults standardUserDefaults] setBool:_saveToCameraRoll.on forKey:@"saveToCameraRoll"];
    [[NSUserDefaults standardUserDefaults] setBool:_resize.on forKey:@"resize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    int width;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            width = [UIScreen mainScreen].applicationFrame.size.width - 300;
        else
            width = [UIScreen mainScreen].applicationFrame.size.height - 560;
    } else {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            width = [UIScreen mainScreen].applicationFrame.size.width - 26;
        else
            width = [UIScreen mainScreen].applicationFrame.size.height - 26;
    }
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        width += 50;
    }
#endif
    
    _highlights.frame = CGRectMake(0, 0, width, 70);
    [self refresh];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventUserInfo:
            if(_userinforeqid == 0 && _prefsreqid == 0)
                [self refresh];
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _userinforeqid || reqid == _prefsreqid) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save settings, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _userinforeqid)
                _userinfosaved = YES;
            if(reqid == _prefsreqid)
                _prefssaved = YES;
            if(_userinfosaved == YES && _prefssaved == YES) {
                [self.tableView endEditing:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            break;
        default:
            break;
    }
}

-(void)refresh {
    NSDictionary *userInfo = [NetworkConnection sharedInstance].userInfo;
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    if([[userInfo objectForKey:@"name"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"name"] length])
        _name.text = [userInfo objectForKey:@"name"];
    else
        _name.text = @"";
    
    if([[userInfo objectForKey:@"email"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"email"] length])
        _email.text = [userInfo objectForKey:@"email"];
    else
        _email.text = @"";
    
    if([[userInfo objectForKey:@"autoaway"] isKindOfClass:[NSNumber class]]) {
        _autoaway.on = [[userInfo objectForKey:@"autoaway"] boolValue];
    }
    
    if([[userInfo objectForKey:@"highlights"] isKindOfClass:[NSArray class]] && [(NSArray *)[userInfo objectForKey:@"highlights"] count])
        _highlights.text = [[userInfo objectForKey:@"highlights"] componentsJoinedByString:@", "];
    else if([[userInfo objectForKey:@"highlights"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"highlights"] length])
        _highlights.text = [userInfo objectForKey:@"highlights"];
    else
        _highlights.text = @"";
    
    if([[prefs objectForKey:@"time-24hr"] isKindOfClass:[NSNumber class]]) {
        _24hour.on = [[prefs objectForKey:@"time-24hr"] boolValue];
    } else {
        _24hour.on = NO;
    }
    
    if([[prefs objectForKey:@"time-seconds"] isKindOfClass:[NSNumber class]]) {
        _seconds.on = [[prefs objectForKey:@"time-seconds"] boolValue];
    } else {
        _seconds.on = NO;
    }
    
    if([[prefs objectForKey:@"mode-showsymbol"] isKindOfClass:[NSNumber class]]) {
        _symbols.on = [[prefs objectForKey:@"mode-showsymbol"] boolValue];
    } else {
        _symbols.on = NO;
    }
    
    if([[prefs objectForKey:@"nick-colors"] isKindOfClass:[NSNumber class]]) {
        _colors.on = [[prefs objectForKey:@"nick-colors"] boolValue];
    } else {
        _colors.on = NO;
    }
    
    if([[prefs objectForKey:@"emoji-disableconvert"] isKindOfClass:[NSNumber class]]) {
        _emocodes.on = ![[prefs objectForKey:@"emoji-disableconvert"] boolValue];
    } else {
        _emocodes.on = YES;
    }
    
    _screen.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"];
    _chrome.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"];
    _autoCaps.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"];
    _saveToCameraRoll.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"];
    _resize.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"resize"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int padding = 80;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        padding = 26;
        
#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
        padding = 0;
    }
#endif

    _email = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _email.placeholder = @"john@example.com";
    _email.text = @"";
    _email.textAlignment = NSTextAlignmentRight;
    _email.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _email.autocorrectionType = UITextAutocorrectionTypeNo;
    _email.keyboardType = UIKeyboardTypeEmailAddress;
    _email.adjustsFontSizeToFitWidth = YES;
    _email.returnKeyType = UIReturnKeyDone;
    _email.delegate = self;
    
    _name = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _name.placeholder = @"John Appleseed";
    _name.text = @"";
    _name.textAlignment = NSTextAlignmentRight;
    _name.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _name.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _name.autocorrectionType = UITextAutocorrectionTypeNo;
    _name.keyboardType = UIKeyboardTypeDefault;
    _name.adjustsFontSizeToFitWidth = YES;
    _name.returnKeyType = UIReturnKeyDone;
    _name.delegate = self;
    
    _autoaway = [[UISwitch alloc] init];
    _24hour = [[UISwitch alloc] init];
    _seconds = [[UISwitch alloc] init];
    _symbols = [[UISwitch alloc] init];
    _colors = [[UISwitch alloc] init];
    _screen = [[UISwitch alloc] init];
    _chrome = [[UISwitch alloc] init];
    _autoCaps = [[UISwitch alloc] init];
    _emocodes = [[UISwitch alloc] init];
    _saveToCameraRoll = [[UISwitch alloc] init];
    _resize = [[UISwitch alloc] init];

    int width;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            width = [UIScreen mainScreen].applicationFrame.size.width - 300;
        else
            width = [UIScreen mainScreen].applicationFrame.size.height - 560;
    } else {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            width = [UIScreen mainScreen].applicationFrame.size.width - 26;
        else
            width = [UIScreen mainScreen].applicationFrame.size.height - 26;
    }

#ifdef __IPHONE_7_0
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7 && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        width += 50;
    }
#endif
    _highlights = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, width, 70)];
    _highlights.text = @"";
    _highlights.backgroundColor = [UIColor clearColor];
    _highlights.returnKeyType = UIReturnKeyDone;
    _highlights.delegate = self;

    _version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#ifdef BRAND_NAME
    _version = [_version stringByAppendingFormat:@"-%@", BRAND_NAME];
#endif
#ifndef APPSTORE
    _version = [_version stringByAppendingFormat:@" (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
#endif
    [self refresh];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if([text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1)
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return 3;
        case 1:
            return 1;
        case 2:
            return 5;
        case 3:
            return (_chromeInstalled)?4:3;
        case 4:
            return 3;
        case 5:
            return 4;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Account";
        case 1:
            return @"Highlight Words";
        case 2:
            return @"Display";
        case 3:
            return @"Device";
        case 4:
            return @"Photo Uploads";
        case 5:
            return @"About";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSString *identifier = [NSString stringWithFormat:@"settingscell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = nil;
    
    switch(indexPath.section) {
        case 0:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"Email Address";
                    cell.accessoryView = _email;
                    break;
                case 1:
                    cell.textLabel.text = @"Full Name";
                    cell.accessoryView = _name;
                    break;
                case 2:
                    cell.textLabel.text = @"Auto Away";
                    cell.accessoryView = _autoaway;
                    break;
            }
            break;
        case 1:
            cell.textLabel.text = nil;
            cell.accessoryView = _highlights;
            break;
        case 2:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"24-hour Clock";
                    cell.accessoryView = _24hour;
                    break;
                case 1:
                    cell.textLabel.text = @"Show Seconds";
                    cell.accessoryView = _seconds;
                    break;
                case 2:
                    cell.textLabel.text = @"Usermode Symbols";
                    cell.accessoryView = _symbols;
                    break;
                case 3:
                    cell.textLabel.text = @"Colourise Nicknames";
                    cell.accessoryView = _colors;
                    break;
                case 4:
                    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
                        cell.textLabel.text = @"Convert :emocodes:";
                    else
                        cell.textLabel.text = @"Convert :emocodes: to Emoji";
                    cell.accessoryView = _emocodes;
                    break;
            }
            break;
        case 3:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"Prevent Auto-Lock";
                    cell.accessoryView = _screen;
                    break;
                case 1:
                    cell.textLabel.text = @"Background Disconnect Timer";
                    int seconds = [[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue];
                    if(seconds < 60)
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%is", seconds];
                    else
                        cell.detailTextLabel.text = [NSString stringWithFormat:@"%im", seconds/60];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 2:
                    cell.textLabel.text = @"Auto-capitalization";
                    cell.accessoryView = _autoCaps;
                    break;
                case 3:
                    cell.textLabel.text = @"Open URLs in Chrome";
                    cell.accessoryView = _chrome;
                    break;
            }
            break;
        case 4:
            switch (row) {
                case 0:
                    cell.textLabel.text = @"Imgur.com Account";
                    cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_account_username"];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    break;
                case 1:
                    cell.textLabel.text = @"Save to Camera Roll";
                    cell.accessoryView = _saveToCameraRoll;
                    break;
                case 2:
                    cell.textLabel.text = @"Resize Before Upload";
                    cell.accessoryView = _resize;
                    break;
            }
            break;
        case 5:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"FAQ";
                    break;
                case 1:
                    cell.textLabel.text = @"Feedback Channel";
                    break;
                case 2:
                    cell.textLabel.text = @"Open-Source Licenses";
                    break;
                case 3:
                    cell.textLabel.text = @"Version";
                    cell.detailTextLabel.text = _version;
                    break;
            }
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    if(indexPath.section == 3 && indexPath.row == 1) {
        [self.navigationController pushViewController:[[BGTimeoutViewController alloc] init] animated:YES];
    }
    if(indexPath.section == 4 && indexPath.row == 0) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self.navigationController pushViewController:[[ImgurLoginViewController alloc] init] animated:YES];
    }
    if(indexPath.section == 5 && indexPath.row == 0) {
        [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://www.irccloud.com/faq"]];
    }
    if(indexPath.section == 5 && indexPath.row == 1) {
        [self.tableView endEditing:YES];
        [self dismissViewControllerAnimated:YES completion:^{
            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"irc://irc.irccloud.com/%23feedback"]];
        }];
    }
    if(indexPath.section == 5 && indexPath.row == 2) {
        [self.navigationController pushViewController:[[LicenseViewController alloc] init] animated:YES];
    }
}

@end
