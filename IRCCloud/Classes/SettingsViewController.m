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

#import <SafariServices/SafariServices.h>
#import "SettingsViewController.h"
#import "NetworkConnection.h"
#import "LicenseViewController.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"
#import "OpenInChromeController.h"
#import "ImgurLoginViewController.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "ColorFormatter.h"
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#import "AvatarsDataSource.h"

@interface BrowserViewController : UITableViewController {
    NSMutableArray *_browsers;
}
@end

@implementation BrowserViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Browser";
        _browsers = [[NSMutableArray alloc] init];
        if([SFSafariViewController class])
            [_browsers addObject:@"IRCCloud"];
        [_browsers addObject:@"Safari"];
        if([[OpenInChromeController sharedInstance] isChromeInstalled])
            [_browsers addObject:@"Chrome"];
        if([[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled])
            [_browsers addObject:@"Firefox"];
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
    return _browsers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageservicecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"imageservicecell"];
    
    cell.textLabel.text = [_browsers objectAtIndex:indexPath.row];
    cell.accessoryType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:[_browsers objectAtIndex:indexPath.row]]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [[NSUserDefaults standardUserDefaults] setObject:[_browsers objectAtIndex:indexPath.row] forKey:@"browser"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation FontSizeCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _small = [[UILabel alloc] init];
        _small.font = [UIFont boldSystemFontOfSize:FONT_MIN];
        _small.lineBreakMode = NSLineBreakByCharWrapping;
        _small.textAlignment = NSTextAlignmentCenter;
        _small.numberOfLines = 0;
        _small.text = @"Aa";
        _small.textColor = [[UITableViewCell appearance] textLabelColor];
        [self.contentView addSubview:_small];
        
        _large = [[UILabel alloc] init];
        _large.font = [UIFont systemFontOfSize:FONT_MAX];
        _large.lineBreakMode = NSLineBreakByCharWrapping;
        _large.textAlignment = NSTextAlignmentCenter;
        _large.numberOfLines = 0;
        _large.text = @"Aa";
        _large.textColor = [[UITableViewCell appearance] textLabelColor];
        [self.contentView addSubview:_large];
        
        _fontSample = [[UILabel alloc] initWithFrame:CGRectZero];
        _fontSample.textAlignment = NSTextAlignmentCenter;
        _fontSample.text = @"Example";
        [self.contentView addSubview:_fontSample];
    }
    return self;
}

-(void)setFontSize:(UISlider *)fontSize {
    [_fontSize removeFromSuperview];
    _fontSize = fontSize;
    
    [self.contentView addSubview:_fontSize];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = CGRectInset([self.contentView bounds], 6, 6);
    
    _small.frame = CGRectMake(frame.origin.x, frame.origin.y, 32, frame.size.height/2);
    _large.frame = CGRectMake(frame.origin.x + frame.size.width - 32, frame.origin.y, 32, frame.size.height/2);
    [_fontSize sizeToFit];
    _fontSize.frame = CGRectMake(frame.origin.x + 32, 0, frame.size.width - 64 - frame.origin.x, _fontSize.frame.size.height/2);
    CGPoint p = _fontSize.center;
    p.y = self.contentView.center.y/2;
    _fontSize.center = p;
    _fontSample.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height / 2, frame.size.width, frame.size.height / 2);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@interface ImageServiceViewController : UITableViewController
@end

@implementation ImageServiceViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Image Service";
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageservicecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"imageservicecell"];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch(indexPath.row) {
        case 0:
            cell.textLabel.text = @"IRCCloud";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"IRCCloud"])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 1:
            cell.textLabel.text = @"imgur";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"imgur"])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:@"IRCCloud" forKey:@"imageService"];
            break;
        case 1:
            [[NSUserDefaults standardUserDefaults] setObject:@"imgur" forKey:@"imageService"];
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@interface PhotoSizeViewController : UITableViewController
@end

@implementation PhotoSizeViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Photo Size";
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photosizecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"photosizecell"];
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch(indexPath.row) {
        case 0:
            cell.textLabel.text = @"Small";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] intValue] == 512)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 1:
            cell.textLabel.text = @"Medium";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] intValue] == 1024)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 2:
            cell.textLabel.text = @"Large";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] intValue] == 2048)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
        case 3:
            cell.textLabel.text = @"Original";
            if([[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] intValue] == -1)
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch(indexPath.row) {
        case 0:
            [[NSUserDefaults standardUserDefaults] setObject:@(512) forKey:@"photoSize"];
            break;
        case 1:
            [[NSUserDefaults standardUserDefaults] setObject:@(1024) forKey:@"photoSize"];
            break;
        case 2:
            [[NSUserDefaults standardUserDefaults] setObject:@(2048) forKey:@"photoSize"];
            break;
        case 3:
            [[NSUserDefaults standardUserDefaults] setObject:@(-1) forKey:@"photoSize"];
            break;
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [tableView reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@interface ThemesViewController : UITableViewController {
    NSArray *_themes;
    NSArray *_themePreviews;
}
@end

@implementation ThemesViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Theme";
        _themes = @[@"Dawn", @"Dusk", @"Tropic", @"Emerald", @"Sand", @"Rust", @"Orchid", @"Ash", @"Midnight"];
        
        NSMutableArray *previews = [[NSMutableArray alloc] init];
        
        UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0 green:0.4 blue:0.8 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0 green:0.8 blue:0.8 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.133 green:0.8 blue:0 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.8 green:0.6 blue:0 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.8 green:0 blue:0.612 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        v = [[UIView alloc] initWithFrame:CGRectZero];
        v.backgroundColor = [UIColor blackColor];
        v.layer.borderColor = [UIColor blackColor].CGColor;
        v.layer.borderWidth = 1.0f;
        [previews addObject:v];
        
        _themePreviews = previews;
        
        self.tableView.separatorInset = UIEdgeInsetsMake(0, 40, 0, 0);
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
    return _themes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"themecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"themecell"];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [_themes objectAtIndex:indexPath.row];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"] isEqualToString:[[_themes objectAtIndex:indexPath.row] lowercaseString]] || (![[NSUserDefaults standardUserDefaults] objectForKey:@"theme"] && indexPath.row == 0))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    UIView *v = [_themePreviews objectAtIndex:indexPath.row];
    [v removeFromSuperview];
    v.frame = CGRectMake(8,cell.contentView.frame.size.height / 2 - 12,24,24);
    v.layer.cornerRadius = v.frame.size.width / 2;
    [cell.contentView addSubview:v];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NSUserDefaults standardUserDefaults] setObject:[[_themes objectAtIndex:indexPath.row] lowercaseString] forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [UIColor setTheme:[[_themes objectAtIndex:indexPath.row] lowercaseString]];
    [[EventsDataSource sharedInstance] reformat];
    [tableView reloadData];
    UIView *v = self.navigationController.view.superview;
    [self.navigationController.view removeFromSuperview];
    [v addSubview: self.navigationController.view];
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.view.backgroundColor = [UIColor navBarColor];
    [[UIApplication sharedApplication] setStatusBarStyle:[UIColor isDarkTheme]?UIStatusBarStyleLightContent:UIStatusBarStyleDefault];
}
@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Settings";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        _oldTheme = [[NSUserDefaults standardUserDefaults] objectForKey:@"theme"];
    }
    return self;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

    if([title isEqualToString:@"Confirm"]) {
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
        
        _emailreqid = [[NetworkConnection sharedInstance] changeEmail:_email.text password:[alertView textFieldAtIndex:0].text];
    }
    
    _alertView = nil;
}

-(BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(alertView.alertViewStyle == UIAlertViewStyleSecureTextInput && [alertView textFieldAtIndex:0].text.length == 0)
        return NO;
    else
        return YES;
}

-(void)saveButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    
    if(sender && [NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"email"] && ![_email.text isEqualToString:[[NetworkConnection sharedInstance].userInfo objectForKey:@"email"]]) {
        [self.view endEditing:YES];
        _alertView = [[UIAlertView alloc] initWithTitle:@"Change Your Email Address" message:@"Please enter your current password to confirm this change" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Confirm", nil];
        _alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [_alertView textFieldAtIndex:0].delegate = self;
        [_alertView textFieldAtIndex:0].tintColor = [UIColor blackColor];
        [_alertView show];
    } else {
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
        
        [prefs setObject:[NSNumber numberWithBool:_24hour.isOn] forKey:@"time-24hr"];
        [prefs setObject:[NSNumber numberWithBool:_seconds.isOn] forKey:@"time-seconds"];
        [prefs setObject:[NSNumber numberWithBool:_symbols.isOn] forKey:@"mode-showsymbol"];
        [prefs setObject:[NSNumber numberWithBool:_colors.isOn] forKey:@"nick-colors"];
        [prefs setObject:[NSNumber numberWithBool:!_emocodes.isOn] forKey:@"emoji-disableconvert"];
        [prefs setObject:[NSNumber numberWithBool:!_pastebin.isOn] forKey:@"pastebin-disableprompt"];
        if([prefs objectForKey:@"font"]) {
            if(_mono.isOn)
                [prefs setObject:@"mono" forKey:@"font"];
            else if([[prefs objectForKey:@"font"] isEqualToString:@"mono"])
                [prefs setObject:@"sans" forKey:@"font"];
        } else {
            [prefs setObject:_mono.isOn?@"mono":@"sans" forKey:@"font"];
        }
        [prefs setObject:[NSNumber numberWithBool:!_hideJoinPart.isOn] forKey:@"hideJoinPart"];
        [prefs setObject:[NSNumber numberWithBool:!_expandJoinPart.isOn] forKey:@"expandJoinPart"];
        [prefs setObject:[NSNumber numberWithBool:_notifyAll.isOn] forKey:@"notifications-all"];
        [prefs setObject:[NSNumber numberWithBool:!_showUnread.isOn] forKey:@"disableTrackUnread"];
        [prefs setObject:[NSNumber numberWithBool:_markAsRead.isOn] forKey:@"enableReadOnSelect"];
        [prefs setObject:[NSNumber numberWithBool:_compact.isOn] forKey:@"ascii-compact"];
        [prefs setObject:[NSNumber numberWithBool:!_disableInlineFiles.isOn] forKey:@"files-disableinline"];
        [prefs setObject:[NSNumber numberWithBool:!_disableBigEmoji.isOn] forKey:@"emoji-nobig"];
        
        SBJson5Writer *writer = [[SBJson5Writer alloc] init];
        NSString *json = [writer stringWithObject:prefs];
        
        _userinfosaved = NO;
        _prefssaved = NO;
        _userinforeqid = [[NetworkConnection sharedInstance] setRealname:_name.text highlights:_highlights.text autoaway:_autoaway.isOn];
        _prefsreqid = [[NetworkConnection sharedInstance] setPrefs:json];
        
        [[NSUserDefaults standardUserDefaults] setBool:_screen.on forKey:@"keepScreenOn"];
        [[NSUserDefaults standardUserDefaults] setBool:_autoCaps.on forKey:@"autoCaps"];
        [[NSUserDefaults standardUserDefaults] setBool:_saveToCameraRoll.on forKey:@"saveToCameraRoll"];
        [[NSUserDefaults standardUserDefaults] setBool:_notificationSound.on forKey:@"notificationSound"];
        [[NSUserDefaults standardUserDefaults] setBool:_tabletMode.on forKey:@"tabletMode"];
        [[NSUserDefaults standardUserDefaults] setFloat:_fontSize.value forKey:@"fontSize"];
        [[NSUserDefaults standardUserDefaults] setBool:!_oneLine.isOn forKey:@"chat-oneline"];
        [[NSUserDefaults standardUserDefaults] setBool:!_noRealName.isOn forKey:@"chat-norealname"];
        [[NSUserDefaults standardUserDefaults] setBool:!_timeLeft.isOn forKey:@"time-left"];
        [[NSUserDefaults standardUserDefaults] setBool:!_avatarsOff.isOn forKey:@"avatars-off"];
        [[NSUserDefaults standardUserDefaults] setBool:!_browserWarning.isOn forKey:@"warnBeforeLaunchingBrowser"];
        [[NSUserDefaults standardUserDefaults] setBool:!_imageViewer.isOn forKey:@"imageViewer"];
        [[NSUserDefaults standardUserDefaults] setBool:!_videoViewer.isOn forKey:@"videoViewer"];
        [[NSUserDefaults standardUserDefaults] setBool:_inlineWifiOnly.isOn forKey:@"inlineWifiOnly"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] forKey:@"photoSize"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] forKey:@"imageService"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"fontSize"] forKey:@"fontSize"];
        [d synchronize];
        
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [ColorFormatter loadFonts];
        }
        [[EventsDataSource sharedInstance] clearFormattingCache];
        [[AvatarsDataSource sharedInstance] clear];
        
        [((AppDelegate *)[UIApplication sharedApplication].delegate).mainViewController viewWillAppear:YES];
    }
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
#ifdef ENTERPRISE
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] forKey:@"photoSize"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
    [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] forKey:@"imageService"];
    [d synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:_oldTheme forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [UIColor setTheme:_oldTheme];
    [[EventsDataSource sharedInstance] reformat];
    UIView *v = self.navigationController.view.superview;
    [self.navigationController.view removeFromSuperview];
    [v addSubview: self.navigationController.view];
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.view.backgroundColor = [UIColor navBarColor];
    [[UIApplication sharedApplication] setStatusBarStyle:[UIColor isDarkTheme]?UIStatusBarStyleLightContent:UIStatusBarStyleDefault];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    _email.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _name.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _highlights.textColor = [UITableViewCell appearance].detailTextLabelColor;
    [self refresh];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventUserInfo:
            if(_userinforeqid == 0 && _prefsreqid == 0 && _emailreqid == 0) {
                [self setFromPrefs];
                [self refresh];
            }
            break;
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _userinforeqid || reqid == _prefsreqid || reqid == _emailreqid) {
                if([[o objectForKey:@"message"] isEqualToString:@"oldpassword"]) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Incorrect password, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save settings, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                }
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
            } else if(reqid == _changepasswordreqid || reqid == _deleteaccountreqid) {
                NSString *msg = [o objectForKey:@"message"];
                if([msg isEqualToString:@"oldpassword"]) {
                    msg = @"Current password incorrect";
                } else if([msg isEqualToString:@"bad_pass"]) {
                    msg = @"Incorrect password, please try again";
                } else if([msg isEqualToString:@"rate_limited"]) {
                    msg = @"Rate limited, try again in a few minutes";
                } else if([msg isEqualToString:@"newpassword"] || [msg isEqualToString:@"password_error"]) {
                    msg = @"Invalid password, please try again";
                } else if([msg isEqualToString:@"last_admin_cant_leave"]) {
                    msg = @"You can’t delete your account as the last admin of a team.  Please transfer ownership before continuing.";
                }
                if(reqid == _changepasswordreqid) {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Changing Password" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    CLS_LOG(@"Password not changed: %@", [o objectForKey:@"message"]);
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Deleting Account" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    CLS_LOG(@"Account not deleted: %@", [o objectForKey:@"message"]);
                }
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _emailreqid) {
                _emailreqid = 0;
                [self saveButtonPressed:nil];
            } else if(reqid == _changepasswordreqid) {
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Changed" message:@"Your password has been successfully updated and all your other sessions have been logged out" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                return;
            } else if(reqid == _deleteaccountreqid) {
                [self.tableView endEditing:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
                return;
            }
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
    NSArray *account;
#ifdef ENTERPRISE
    if([[[NetworkConnection sharedInstance].config objectForKey:@"auth_mechanism"] isEqualToString:@"internal"]) {
#endif
        account = @[
                    @{@"title":@"Email Address", @"accessory":_email},
                    @{@"title":@"Full Name", @"accessory":_name},
                    @{@"title":@"Auto Away", @"accessory":_autoaway},
                    @{@"title":@"Change Password", @"selected":^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password" message:nil preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"Current Password";
                            textField.secureTextEntry = YES;
                        }];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"New Password";
                            textField.secureTextEntry = YES;
                        }];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Change Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                            [spinny startAnimating];
                            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];

                            _changepasswordreqid = [[NetworkConnection sharedInstance] changePassword:[alert.textFields objectAtIndex:0].text newPassword:[alert.textFields objectAtIndex:0].text];
                        }]];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                    }},
                    @{@"title":@"Delete Account", @"selected":^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Account" message:@"Re-enter your password to confirm" preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"Password";
                            textField.secureTextEntry = YES;
                        }];

                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                            UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                            [spinny startAnimating];
                            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
                            
                            _deleteaccountreqid = [[NetworkConnection sharedInstance] deleteAccount:[alert.textFields objectAtIndex:0].text];
                        }]];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                    }}
                    ];
        
#ifdef ENTERPRISE
    } else {
        account = @[
                    @{@"title":@"Full Name", @"accessory":_name},
                    @{@"title":@"Auto Away", @"accessory":_autoaway},
                    ];
    }
#endif
    
    NSString *imageSize;
    switch([[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] intValue]) {
        case 512:
            imageSize = @"Small";
            break;
        case 1024:
            imageSize = @"Medium";
            break;
        case 2048:
            imageSize = @"Large";
            break;
        default:
            imageSize = @"Original";
            break;
    }
    
    NSMutableArray *device = [[NSMutableArray alloc] init];
    [device addObject:@{@"title":@"Theme", @"value":[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]?[[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"] capitalizedString]:@"Dawn", @"selected":^{ [self.navigationController pushViewController:[[ThemesViewController alloc] init] animated:YES]; }}];
    [device addObject:@{@"title":@"Monospace Font", @"accessory":_mono}];
    [device addObject:@{@"title":@"Prevent Auto-Lock", @"accessory":_screen}];
    [device addObject:@{@"title":@"Auto-capitalization", @"accessory":_autoCaps}];
    [device addObject:@{@"title":@"Preferred Browser", @"value":[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"], @"selected":^{ [self.navigationController pushViewController:[[BrowserViewController alloc] init] animated:YES]; }}];
    if([[UIDevice currentDevice] isBigPhone] || [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [device addObject:@{@"title":@"Show Sidebars In Landscape", @"accessory":_tabletMode}];
    }
    [device addObject:@{@"title":@"Ask To Post A Snippet", @"accessory":_pastebin}];
    [device addObject:@{@"title":@"Open Images in Browser", @"accessory":_imageViewer}];
    [device addObject:@{@"title":@"Open Videos in Browser", @"accessory":_videoViewer}];
    [device addObject:@{@"title":@"Retry Failed Images in Browser", @"accessory":_browserWarning}];
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"]) {
        [photos addObject:@{@"title":@"Image Service", @"value":[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"], @"selected":^{[self.navigationController pushViewController:[[ImageServiceViewController alloc] init] animated:YES];}}];
    }
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"uploadsAvailable"] || [[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] isEqualToString:@"imgur"]) {
        [photos addObject:@{@"title":@"Imgur.com Account", @"value":[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_account_username"]?[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_account_username"]:@"", @"selected":^{
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_access_token"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_refresh_token"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_account_username"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_token_type"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"imgur_expires_in"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.navigationController pushViewController:[[ImgurLoginViewController alloc] init] animated:YES];
        }}];
    }
    [photos addObject:@{@"title":@"Save to Camera Roll", @"accessory":_saveToCameraRoll}];
    [photos addObject:@{@"title":@"Image Size", @"value":imageSize, @"selected":^{[self.navigationController pushViewController:[[PhotoSizeViewController alloc] init] animated:YES];}}];
    
    NSMutableArray *notifications = [[NSMutableArray alloc] init];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 10) {
        [notifications addObject:@{@"title":@"Background Alert Sounds", @"accessory":_notificationSound}];
    }
    [notifications addObject:@{@"title":@"Notify On All Messages", @"accessory":_notifyAll}];
    [notifications addObject:@{@"title":@"Show Unread Indicators", @"accessory":_showUnread}];
    [notifications addObject:@{@"title":@"Mark As Read Automatically", @"accessory":_markAsRead}];
    
    _data = @[
              @{@"title":@"Account", @"items":account},
              @{@"title":@"Highlight Words", @"items":@[
                        @{@"configure":^(UITableViewCell *cell) {
                            cell.textLabel.text = nil;
                            [_highlights removeFromSuperview];
                            _highlights.frame = CGRectInset(cell.contentView.bounds, 4, 4);
                            [cell.contentView addSubview:_highlights];
                        }, @"style":@(UITableViewCellStyleDefault)}
                        ]},
              @{@"title":@"Message Layout", @"items":@[
                         @{@"title":@"Nicknames on Separate Line", @"accessory":_oneLine},
                         @{@"title":@"Show Real Names", @"accessory":_noRealName},
                         @{@"title":@"Right Hand Side Timestamps", @"accessory":_timeLeft},
                         @{@"title":@"User Icons", @"accessory":_avatarsOff},
                         @{@"title":@"Compact Spacing", @"accessory":_compact},
                         @{@"title":@"24-Hour Clock", @"accessory":_24hour},
                         @{@"title":@"Show Seconds", @"accessory":_seconds},
                         @{@"title":@"Usermode Symbols", @"accessory":_symbols, @"subtitle":@"@, +, etc."},
                         @{@"title":@"Colourise Nicknames", @"accessory":_colors},
                         @{@"title":@"Enlarge Emoji Messages", @"accessory":_disableBigEmoji},
                         @{@"title":@"Convert :emocodes: to Emoji", @"accessory":_emocodes, @"subtitle":@":thumbsup: → 👍"},
                         @{@"title":@"Show Joins, Parts, Quits", @"accessory":_hideJoinPart},
                         @{@"title":@"Collapse Joins, Parts, Quits", @"accessory":_expandJoinPart},
                         @{@"title":@"Embed Uploaded Files", @"accessory":_disableInlineFiles},
                         @{@"title":@"Embed Files Only Over Wi-Fi", @"accessory":_inlineWifiOnly},
                         ]},
              @{@"title":@"Device", @"items":device},
              @{@"title":@"Notifications", @"items":notifications},
              @{@"title":@"Font Size", @"items":@[
                        @{@"special":^UITableViewCell *(UITableViewCell *cell, NSString *identifier) {
                            _fontSizeCell.fontSample.textColor = [UIColor messageTextColor];
                            [self monoToggled:nil];
                            return _fontSizeCell;
                        }}
                        ]},
              @{@"title":@"Photo Sharing", @"items":photos},
              @{@"title":@"About", @"items":@[
                        @{@"title":@"Feedback Channel", @"selected":^{[self dismissViewControllerAnimated:YES completion:^{
                            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"irc://irc.irccloud.com/%23feedback"]];
                        }];}},
                        @{@"title":@"FAQ", @"selected":^{[(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://www.irccloud.com/faq"]];}},
                        @{@"title":@"Version History", @"selected":^{[(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://github.com/irccloud/ios/releases"]];}},
                        @{@"title":@"Open-Source Licenses", @"selected":^{[self.navigationController pushViewController:[[LicenseViewController alloc] init] animated:YES];}},
                        @{@"title":@"Version", @"subtitle":_version}
                        ]}
              ];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.clipsToBounds = YES;

    _email = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _email.placeholder = @"john@example.com";
    _email.text = @"";
    _email.textAlignment = NSTextAlignmentRight;
    _email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _email.autocorrectionType = UITextAutocorrectionTypeNo;
    _email.keyboardType = UIKeyboardTypeEmailAddress;
    _email.adjustsFontSizeToFitWidth = YES;
    _email.returnKeyType = UIReturnKeyDone;
    _email.delegate = self;
    
    _name = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _name.placeholder = @"John Appleseed";
    _name.text = @"";
    _name.textAlignment = NSTextAlignmentRight;
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
    _autoCaps = [[UISwitch alloc] init];
    _emocodes = [[UISwitch alloc] init];
    _saveToCameraRoll = [[UISwitch alloc] init];
    _notificationSound = [[UISwitch alloc] init];
    _tabletMode = [[UISwitch alloc] init];
    _pastebin = [[UISwitch alloc] init];
    _mono = [[UISwitch alloc] init];
    [_mono addTarget:self action:@selector(monoToggled:) forControlEvents:UIControlEventValueChanged];
    _hideJoinPart = [[UISwitch alloc] init];
    [_hideJoinPart addTarget:self action:@selector(hideJoinPartToggled:) forControlEvents:UIControlEventValueChanged];
    _expandJoinPart = [[UISwitch alloc] init];
    _notifyAll = [[UISwitch alloc] init];
    _showUnread = [[UISwitch alloc] init];
    _markAsRead = [[UISwitch alloc] init];
    _oneLine = [[UISwitch alloc] init];
    [_oneLine addTarget:self action:@selector(oneLineToggled:) forControlEvents:UIControlEventValueChanged];
    _noRealName = [[UISwitch alloc] init];
    _timeLeft = [[UISwitch alloc] init];
    _avatarsOff = [[UISwitch alloc] init];
    [_avatarsOff addTarget:self action:@selector(oneLineToggled:) forControlEvents:UIControlEventValueChanged];
    _browserWarning = [[UISwitch alloc] init];
    _compact = [[UISwitch alloc] init];
    _imageViewer = [[UISwitch alloc] init];
    _videoViewer = [[UISwitch alloc] init];
    _disableInlineFiles = [[UISwitch alloc] init];
    _disableBigEmoji = [[UISwitch alloc] init];
    _inlineWifiOnly = [[UISwitch alloc] init];

    _highlights = [[UITextView alloc] initWithFrame:CGRectZero];
    _highlights.text = @"";
    _highlights.backgroundColor = [UIColor clearColor];
    _highlights.returnKeyType = UIReturnKeyDone;
    _highlights.delegate = self;
    _highlights.font = _email.font;
    _highlights.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _highlights.keyboardAppearance = [UITextField appearance].keyboardAppearance;

    _version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#ifdef BRAND_NAME
    _version = [_version stringByAppendingFormat:@"-%@", BRAND_NAME];
#endif
#ifndef APPSTORE
    _version = [_version stringByAppendingFormat:@" (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
#endif
    
    _fontSize = [[UISlider alloc] init];
    _fontSize.minimumValue = FONT_MIN;
    _fontSize.maximumValue = FONT_MAX;
    _fontSize.continuous = YES;
    [_fontSize addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    _fontSizeCell = [[FontSizeCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    _fontSizeCell.fontSize = _fontSize;
    
    [self setFromPrefs];
    [self refresh];
}

-(void)setFromPrefs {
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
    
    if([[prefs objectForKey:@"pastebin-disableprompt"] isKindOfClass:[NSNumber class]]) {
        _pastebin.on = ![[prefs objectForKey:@"pastebin-disableprompt"] boolValue];
    } else {
        _pastebin.on = YES;
    }
    
    if([[prefs objectForKey:@"hideJoinPart"] isKindOfClass:[NSNumber class]]) {
        _hideJoinPart.on = ![[prefs objectForKey:@"hideJoinPart"] boolValue];
    } else {
        _hideJoinPart.on = YES;
    }
    
    if([[prefs objectForKey:@"expandJoinPart"] isKindOfClass:[NSNumber class]]) {
        _expandJoinPart.on = ![[prefs objectForKey:@"expandJoinPart"] boolValue];
    } else {
        _expandJoinPart.on = YES;
    }
    
    _expandJoinPart.enabled = _hideJoinPart.on;
    
    if([[prefs objectForKey:@"font"] isKindOfClass:[NSString class]]) {
        _mono.on = [[prefs objectForKey:@"font"] isEqualToString:@"mono"];
    } else {
        _mono.on = NO;
    }
    
    if([[prefs objectForKey:@"notifications-all"] isKindOfClass:[NSNumber class]]) {
        _notifyAll.on = [[prefs objectForKey:@"notifications-all"] boolValue];
    } else {
        _notifyAll.on = NO;
    }
    
    if([[prefs objectForKey:@"disableTrackUnread"] isKindOfClass:[NSNumber class]]) {
        _showUnread.on = ![[prefs objectForKey:@"disableTrackUnread"] boolValue];
    } else {
        _showUnread.on = YES;
    }
    
    if([[prefs objectForKey:@"enableReadOnSelect"] isKindOfClass:[NSNumber class]]) {
        _markAsRead.on = [[prefs objectForKey:@"enableReadOnSelect"] boolValue];
    } else {
        _markAsRead.on = NO;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"chat-oneline"]) {
        _oneLine.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"chat-oneline"];
    } else {
        _oneLine.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"chat-norealname"]) {
        _noRealName.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"chat-norealname"];
    } else {
        _noRealName.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"time-left"]) {
        _timeLeft.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"time-left"];
    } else {
        _timeLeft.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"avatars-off"]) {
        _avatarsOff.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"avatars-off"];
    } else {
        _avatarsOff.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"warnBeforeLaunchingBrowser"]) {
        _browserWarning.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"warnBeforeLaunchingBrowser"];
    } else {
        _browserWarning.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"inlineWifiOnly"]) {
        _inlineWifiOnly.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"inlineWifiOnly"];
    } else {
        _inlineWifiOnly.on = NO;
    }
    
    if(_oneLine.on) {
        _noRealName.enabled = YES;
        if(_avatarsOff.on) {
            _timeLeft.enabled = NO;
            _timeLeft.on = YES;
        } else {
            _timeLeft.enabled = YES;
        }
    } else {
        _noRealName.enabled = NO;
        _timeLeft.enabled = YES;
    }
    
    if([[prefs objectForKey:@"ascii-compact"] isKindOfClass:[NSNumber class]]) {
        _compact.on = [[prefs objectForKey:@"ascii-compact"] boolValue];
    } else {
        _compact.on = NO;
    }
    
    if([[prefs objectForKey:@"files-disableinline"] isKindOfClass:[NSNumber class]]) {
        _disableInlineFiles.on = ![[prefs objectForKey:@"files-disableinline"] boolValue];
    } else {
        _disableInlineFiles.on = YES;
    }
    
    if([[prefs objectForKey:@"emoji-nobig"] isKindOfClass:[NSNumber class]]) {
        _disableBigEmoji.on = ![[prefs objectForKey:@"emoji-nobig"] boolValue];
    } else {
        _disableBigEmoji.on = YES;
    }
    
    _screen.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"];
    _autoCaps.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"];
    _saveToCameraRoll.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"];
    _notificationSound.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSound"];
    _tabletMode.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"];
    _fontSize.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"];
    _imageViewer.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"imageViewer"];
    _videoViewer.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"videoViewer"];
}

-(void)hideJoinPartToggled:(id)sender {
    _expandJoinPart.enabled = _hideJoinPart.on;
}

-(void)oneLineToggled:(id)sender {
    if(_oneLine.on) {
        _noRealName.enabled = YES;
        if(_avatarsOff.on) {
            _timeLeft.enabled = NO;
            _timeLeft.on = YES;
        } else {
            _timeLeft.enabled = YES;
        }
    } else {
        _noRealName.enabled = NO;
        _timeLeft.enabled = YES;
    }
}

-(void)monoToggled:(id)sender {
    if(_mono.on)
        _fontSizeCell.fontSample.font = [UIFont fontWithName:@"Hack" size:_fontSize.value - 1];
    else
        _fontSizeCell.fontSample.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] size:_fontSize.value];
}

-(void)sliderChanged:(UISlider *)slider {
    [slider setValue:(int)slider.value animated:NO];
    [self monoToggled:nil];
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
    if(_alertView) {
        [_alertView dismissWithClickedButtonIndex:1 animated:YES];
        [self alertView:_alertView clickedButtonAtIndex:1];
    }
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1 || [[[_data objectAtIndex:indexPath.section] objectForKey:@"title"] isEqualToString:@"Font Size"])
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[[_data objectAtIndex:section] objectForKey:@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[_data objectAtIndex:section] objectForKey:@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [NSString stringWithFormat:@"settingscell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSDictionary *item = [[[_data objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    
    if([item objectForKey:@"special"]) {
        UITableViewCell *(^special)(UITableViewCell *cell, NSString *identifier) = [item objectForKey:@"special"];
        return special(cell,identifier);
    }

    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:([item objectForKey:@"subtitle"])?UITableViewCellStyleSubtitle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = [item objectForKey:@"title"];
    cell.accessoryView = [item objectForKey:@"accessory"];
    cell.accessoryType = [item objectForKey:@"value"]?UITableViewCellAccessoryDisclosureIndicator:UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = [item objectForKey:@"value"]?[item objectForKey:@"value"]:[item objectForKey:@"subtitle"];
    
    if([item objectForKey:@"configure"]) {
        void (^configure)(UITableViewCell *cell) = [item objectForKey:@"configure"];
        configure(cell);
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    NSDictionary *item = [[[_data objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];

    if([item objectForKey:@"selected"]) {
        void (^selected)(void) = [item objectForKey:@"selected"];
        selected();
    }
}

@end
