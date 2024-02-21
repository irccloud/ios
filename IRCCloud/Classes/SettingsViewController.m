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
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "ColorFormatter.h"
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#import "AvatarsDataSource.h"
#import "AvatarsTableViewController.h"
@import Firebase;

@interface BrowserViewController : UITableViewController {
    NSMutableArray *_browsers;
}
@end

@implementation BrowserViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Browser";
        self->_browsers = [[NSMutableArray alloc] init];
        if([SFSafariViewController class])
            [self->_browsers addObject:@"IRCCloud"];
        [self->_browsers addObject:@"Safari"];
        if([[OpenInChromeController sharedInstance] isChromeInstalled])
            [self->_browsers addObject:@"Chrome"];
        if([[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled])
            [self->_browsers addObject:@"Firefox"];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"browserservicecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"browserservicecell"];
    
    cell.textLabel.text = [self->_browsers objectAtIndex:indexPath.row];
    cell.accessoryType = [[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:[self->_browsers objectAtIndex:indexPath.row]]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [[NSUserDefaults standardUserDefaults] setObject:[self->_browsers objectAtIndex:indexPath.row] forKey:@"browser"];
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
        
        self->_small = [[UILabel alloc] init];
        self->_small.font = [UIFont boldSystemFontOfSize:FONT_MIN];
        self->_small.lineBreakMode = NSLineBreakByCharWrapping;
        self->_small.textAlignment = NSTextAlignmentCenter;
        self->_small.numberOfLines = 0;
        self->_small.text = @"Aa";
        self->_small.textColor = [[UITableViewCell appearance] textLabelColor];
        [self.contentView addSubview:self->_small];
        
        self->_large = [[UILabel alloc] init];
        self->_large.font = [UIFont systemFontOfSize:FONT_MAX];
        self->_large.lineBreakMode = NSLineBreakByCharWrapping;
        self->_large.textAlignment = NSTextAlignmentCenter;
        self->_large.numberOfLines = 0;
        self->_large.text = @"Aa";
        self->_large.textColor = [[UITableViewCell appearance] textLabelColor];
        [self.contentView addSubview:self->_large];
        
        self->_fontSample = [[UILabel alloc] initWithFrame:CGRectZero];
        self->_fontSample.textAlignment = NSTextAlignmentCenter;
        self->_fontSample.text = @"Example";
        [self.contentView addSubview:self->_fontSample];
    }
    return self;
}

-(void)setFontSize:(UISlider *)fontSize {
    [self->_fontSize removeFromSuperview];
    self->_fontSize = fontSize;
    
    [self.contentView addSubview:self->_fontSize];
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = CGRectInset([self.contentView bounds], 6, 6);
    
    self->_small.frame = CGRectMake(frame.origin.x, frame.origin.y, 32, frame.size.height/2);
    self->_large.frame = CGRectMake(frame.origin.x + frame.size.width - 32, frame.origin.y, 32, frame.size.height/2);
    [self->_fontSize sizeToFit];
    self->_fontSize.frame = CGRectMake(frame.origin.x + 32, 0, frame.size.width - 64 - frame.origin.x, _fontSize.frame.size.height/2);
    CGPoint p = self->_fontSize.center;
    p.y = self.contentView.center.y/2;
    self->_fontSize.center = p;
    self->_fontSample.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height / 2, frame.size.width, frame.size.height / 2);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
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
        if (@available(iOS 13, *)) {
            self->_themes = @[@"Automatic", @"Dawn", @"Dusk", @"Tropic", @"Emerald", @"Sand", @"Rust", @"Orchid", @"Ash", @"Midnight"];
        } else {
            self->_themes = @[@"Dawn", @"Dusk", @"Tropic", @"Emerald", @"Sand", @"Rust", @"Orchid", @"Ash", @"Midnight"];
        }

        NSMutableArray *previews = [[NSMutableArray alloc] init];
        
        if (@available(iOS 13, *)) {
            UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
            if([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
                v.backgroundColor = [UIColor blackColor];
            } else {
                v.backgroundColor = [UIColor colorWithRed:0.851 green:0.906 blue:1 alpha:1];
            }
            v.layer.borderColor = [UIColor blackColor].CGColor;
            v.layer.borderWidth = 1.0f;
            [previews addObject:v];
        }
        
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
        
        self->_themePreviews = previews;
        
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
    cell.textLabel.text = [self->_themes objectAtIndex:indexPath.row];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"] isEqualToString:[[self->_themes objectAtIndex:indexPath.row] lowercaseString]] || (![[NSUserDefaults standardUserDefaults] objectForKey:@"theme"] && indexPath.row == 0))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    UIView *v = [self->_themePreviews objectAtIndex:indexPath.row];
    [v removeFromSuperview];
    v.frame = CGRectMake(self.view.window.safeAreaInsets.left?-12:8,cell.contentView.frame.size.height / 2 - 12,24,24);
    v.layer.cornerRadius = v.frame.size.width / 2;
    [cell.contentView addSubview:v];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[NSUserDefaults standardUserDefaults] setObject:[[self->_themes objectAtIndex:indexPath.row] lowercaseString] forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [UIColor setTheme];
    [[EventsDataSource sharedInstance] reformat];
    [tableView reloadData];
    UIView *v = self.navigationController.view.superview;
    [self.navigationController.view removeFromSuperview];
    [v addSubview: self.navigationController.view];
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.view.backgroundColor = [UIColor navBarColor];
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *a = [[UINavigationBarAppearance alloc] init];
        a.backgroundImage = [UIColor navBarBackgroundImage];
        a.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor navBarHeadingColor]};
        self.navigationController.navigationBar.standardAppearance = a;
        self.navigationController.navigationBar.compactAppearance = a;
        self.navigationController.navigationBar.scrollEdgeAppearance = a;
        if (@available(iOS 15.0, *)) {
#if !TARGET_OS_MACCATALYST
            self.navigationController.navigationBar.compactScrollEdgeAppearance = a;
#endif
        }
    }

    [self.navigationController setNeedsStatusBarAppearanceUpdate];
}
@end

@implementation SettingsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.title = @"Settings";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        self->_oldTheme = [[NSUserDefaults standardUserDefaults] objectForKey:@"theme"];
    }
    return self;
}

-(void)saveButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    
    if(sender && [NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"email"] && ![self->_email.text isEqualToString:[[NetworkConnection sharedInstance].userInfo objectForKey:@"email"]]) {
        [self.view endEditing:YES];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Your Email Address" message:@"Please enter your current password to confirm this change" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(((UITextField *)[alert.textFields objectAtIndex:0]).text.length) {
                UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                [spinny startAnimating];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
                
                [[NetworkConnection sharedInstance] changeEmail:self->_email.text password:((UITextField *)[alert.textFields objectAtIndex:0]).text handler:^(IRCCloudJSONObject *result) {
                    if([[result objectForKey:@"success"] boolValue]) {
                        [self saveButtonPressed:nil];
                    } else {
                        if([[result objectForKey:@"message"] isEqualToString:@"oldpassword"]) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Incorrect password, please try again." preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        } else {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }
                }];
            }
        }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.secureTextEntry = YES;
            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
        }];
        
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
        NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
        
        [prefs setObject:[NSNumber numberWithBool:self->_24hour.isOn] forKey:@"time-24hr"];
        [prefs setObject:[NSNumber numberWithBool:self->_seconds.isOn] forKey:@"time-seconds"];
        [prefs setObject:[NSNumber numberWithBool:self->_symbols.isOn] forKey:@"mode-showsymbol"];
        [prefs setObject:[NSNumber numberWithBool:self->_colors.isOn] forKey:@"nick-colors"];
        [prefs setObject:[NSNumber numberWithBool:self->_colorizeMentions.isOn] forKey:@"mention-colors"];
        [prefs setObject:[NSNumber numberWithBool:!_emocodes.isOn] forKey:@"emoji-disableconvert"];
        [prefs setObject:[NSNumber numberWithBool:!_pastebin.isOn] forKey:@"pastebin-disableprompt"];
        if([prefs objectForKey:@"font"]) {
            if(self->_mono.isOn)
                [prefs setObject:@"mono" forKey:@"font"];
            else if([[prefs objectForKey:@"font"] isEqualToString:@"mono"])
                [prefs setObject:@"sans" forKey:@"font"];
        } else {
            [prefs setObject:self->_mono.isOn?@"mono":@"sans" forKey:@"font"];
        }
        [prefs setObject:[NSNumber numberWithBool:!_hideJoinPart.isOn] forKey:@"hideJoinPart"];
        [prefs setObject:[NSNumber numberWithBool:!_expandJoinPart.isOn] forKey:@"expandJoinPart"];
        [prefs setObject:[NSNumber numberWithBool:self->_notifyAll.isOn] forKey:@"notifications-all"];
        [prefs setObject:[NSNumber numberWithBool:!_showUnread.isOn] forKey:@"disableTrackUnread"];
        [prefs setObject:[NSNumber numberWithBool:self->_markAsRead.isOn] forKey:@"enableReadOnSelect"];
        [prefs setObject:[NSNumber numberWithBool:self->_compact.isOn] forKey:@"ascii-compact"];
        [prefs setObject:[NSNumber numberWithBool:!_disableInlineFiles.isOn] forKey:@"files-disableinline"];
        [prefs setObject:[NSNumber numberWithBool:self->_inlineImages.isOn] forKey:@"inlineimages"];
        [prefs setObject:[NSNumber numberWithBool:!_disableBigEmoji.isOn] forKey:@"emoji-nobig"];
        [prefs setObject:[NSNumber numberWithBool:!_disableCodeSpan.isOn] forKey:@"chat-nocodespan"];
        [prefs setObject:[NSNumber numberWithBool:!_disableCodeBlock.isOn] forKey:@"chat-nocodeblock"];
        [prefs setObject:[NSNumber numberWithBool:!_disableQuote.isOn] forKey:@"chat-noquote"];
        [prefs setObject:[NSNumber numberWithBool:_muteNotifications.isOn] forKey:@"notifications-mute"];
        [prefs setObject:[NSNumber numberWithBool:!_noColor.isOn] forKey:@"chat-nocolor"];
        [prefs setObject:[NSNumber numberWithBool:!_disableTypingStatus.isOn] forKey:@"disableTypingStatus"];

        SBJson5Writer *writer = [[SBJson5Writer alloc] init];
        NSString *json = [writer stringWithObject:prefs];
        
        [[NetworkConnection sharedInstance] setRealname:self->_name.text highlights:self->_highlights.text autoaway:self->_autoaway.isOn handler:^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                [[NetworkConnection sharedInstance] setPrefs:json handler:^(IRCCloudJSONObject *result) {
                    if([[result objectForKey:@"success"] boolValue]) {
                        [self.tableView endEditing:YES];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
                    }
                }];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save settings, please try again." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
            }
        }];
        
        [[NSUserDefaults standardUserDefaults] setBool:self->_screen.on forKey:@"keepScreenOn"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_autoCaps.on forKey:@"autoCaps"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_saveToCameraRoll.on forKey:@"saveToCameraRoll"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_notificationSound.on forKey:@"notificationSound"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_tabletMode.on forKey:@"tabletMode"];
        [[NSUserDefaults standardUserDefaults] setFloat:ceilf(self->_fontSize.value) forKey:@"fontSize"];
        [[NSUserDefaults standardUserDefaults] setBool:!_oneLine.isOn forKey:@"chat-oneline"];
        [[NSUserDefaults standardUserDefaults] setBool:!_noRealName.isOn forKey:@"chat-norealname"];
        [[NSUserDefaults standardUserDefaults] setBool:!_timeLeft.isOn forKey:@"time-left"];
        [[NSUserDefaults standardUserDefaults] setBool:!_avatarsOff.isOn forKey:@"avatars-off"];
        [[NSUserDefaults standardUserDefaults] setBool:!_browserWarning.isOn forKey:@"warnBeforeLaunchingBrowser"];
        [[NSUserDefaults standardUserDefaults] setBool:!_imageViewer.isOn forKey:@"imageViewer"];
        [[NSUserDefaults standardUserDefaults] setBool:!_videoViewer.isOn forKey:@"videoViewer"];
        [[NSUserDefaults standardUserDefaults] setBool:!_inlineWifiOnly.isOn forKey:@"inlineWifiOnly"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_defaultSound.isOn forKey:@"defaultSound"];
        [[NSUserDefaults standardUserDefaults] setBool:!_notificationPreviews.isOn forKey:@"disableNotificationPreviews"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_thirdPartyNotificationPreviews.isOn forKey:@"thirdPartyNotificationPreviews"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_clearFormattingAfterSending.isOn forKey:@"clearFormattingAfterSending"];
        [[NSUserDefaults standardUserDefaults] setBool:self->_avatarImages.isOn forKey:@"avatarImages"];
        [[NSUserDefaults standardUserDefaults] setBool:!_hiddenMembers.isOn forKey:@"hiddenMembers"];
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
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"defaultSound"] forKey:@"defaultSound"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"disableNotificationPreviews"] forKey:@"disableNotificationPreviews"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"thirdPartyNotificationPreviews"] forKey:@"thirdPartyNotificationPreviews"];
        [d synchronize];
        
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [ColorFormatter loadFonts];
        }
        [[EventsDataSource sharedInstance] clearFormattingCache];
        [[AvatarsDataSource sharedInstance] invalidate];
        
        [((AppDelegate *)[UIApplication sharedApplication].delegate).mainViewController viewWillAppear:YES];
//#if TARGET_OS_MACCATALYST
        //[(AppDelegate *)UIApplication.sharedApplication.delegate closeWindow:self.view.window];
//#endif
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
    [[NSUserDefaults standardUserDefaults] setObject:self->_oldTheme forKey:@"theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [UIColor setTheme:self->_oldTheme];
    if([ColorFormatter shouldClearFontCache]) {
        [ColorFormatter clearFontCache];
        [ColorFormatter loadFonts];
    }
    [[EventsDataSource sharedInstance] clearFormattingCache];
    [[AvatarsDataSource sharedInstance] invalidate];
    [[EventsDataSource sharedInstance] reformat];
//#if TARGET_OS_MACCATALYST
//    [(AppDelegate *)UIApplication.sharedApplication.delegate closeWindow:self.view.window];
//#else
    UIView *v = self.navigationController.view.superview;
    [self.navigationController.view removeFromSuperview];
    [v addSubview: self.navigationController.view];
    [self.navigationController.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.view.backgroundColor = [UIColor navBarColor];
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *a = [[UINavigationBarAppearance alloc] init];
        a.backgroundImage = [UIColor navBarBackgroundImage];
        a.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor navBarHeadingColor]};
        self.navigationController.navigationBar.standardAppearance = a;
        self.navigationController.navigationBar.compactAppearance = a;
        self.navigationController.navigationBar.scrollEdgeAppearance = a;
        if (@available(iOS 15.0, *)) {
#if !TARGET_OS_MACCATALYST
            self.navigationController.navigationBar.compactScrollEdgeAppearance = a;
#endif
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
//#endif
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    self->_email.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_name.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_highlights.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_email.frame = CGRectMake(0, 0, self.tableView.frame.size.width / 3, 22);
    self->_name.frame = CGRectMake(0, 0, self.tableView.frame.size.width / 3, 22);
    [self refresh];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    
    switch(event) {
        case kIRCEventUserInfo:
            [self setFromPrefs];
            [self refresh];
            break;
        default:
            break;
    }
}

-(NSString *)accountMsg:(NSString *)msg {
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
    return msg;
}

-(void)refresh {
    BOOL isCatalyst = NO;
    if (@available(iOS 13.0, *)) {
        isCatalyst = [NSProcessInfo processInfo].macCatalystApp;
    }
    
    NSArray *account;
#ifdef ENTERPRISE
    if([[[NetworkConnection sharedInstance].config objectForKey:@"auth_mechanism"] isEqualToString:@"internal"]) {
#endif
        account = @[
                    @{@"title":@"Email Address", @"accessory":self->_email},
                    @{@"title":@"Full Name", @"accessory":self->_name},
                    @{@"title":@"Auto Away", @"accessory":self->_autoaway},
#ifndef ENTERPRISE
                    @{@"title":@"Public Avatar", @"value":@"", @"selected":^{
                        AvatarsTableViewController *atv = [[AvatarsTableViewController alloc] initWithServer:-1];
                        [self.navigationController pushViewController:atv animated:YES];
                    }},
                    @{@"title":@"Avatars FAQ", @"selected":^{[(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://www.irccloud.com/faq#faq-avatars"]];}},
#endif
                    @{@"title":@"Change Password", @"selected":^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Password" message:nil preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"Current Password";
                            textField.textContentType = UITextContentTypePassword;
                            textField.secureTextEntry = YES;
                            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                        }];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"New Password";
                            textField.textContentType = UITextContentTypeNewPassword;
                            textField.secureTextEntry = YES;
                            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                        }];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Change Password" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                            [spinny startAnimating];
                            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];

                            [[NetworkConnection sharedInstance] changePassword:[alert.textFields objectAtIndex:0].text newPassword:[alert.textFields objectAtIndex:0].text handler:^(IRCCloudJSONObject *result) {
                                if([[result objectForKey:@"success"] boolValue]) {
                                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Password Changed" message:@"Your password has been successfully updated and all your other sessions have been logged out" preferredStyle:UIAlertControllerStyleAlert];
                                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                                    [self presentViewController:alert animated:YES completion:nil];
                                } else {
                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Changing Password" message:[self accountMsg:[result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                                    [self presentViewController:alert animated:YES completion:nil];
                                    CLS_LOG(@"Password not changed: %@", [result objectForKey:@"message"]);
                                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
                                }
                            }];
                        }]];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                    }},
                    @{@"title":@"Delete Account", @"selected":^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Account" message:@"Re-enter your password to confirm" preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                            textField.placeholder = @"Password";
                            textField.secureTextEntry = YES;
                            textField.tintColor = [UIColor isDarkTheme]?[UIColor whiteColor]:[UIColor blackColor];
                        }];

                        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                            UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
                            [spinny startAnimating];
                            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
                            
                            [[NetworkConnection sharedInstance] deleteAccount:[alert.textFields objectAtIndex:0].text handler:^(IRCCloudJSONObject *result) {
                                if([[result objectForKey:@"success"] boolValue]) {
                                    [self.tableView endEditing:YES];
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                } else {
                                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error Deleting Account" message:[self accountMsg:[result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                                    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                                    [self presentViewController:alert animated:YES completion:nil];
                                    CLS_LOG(@"Account not deleted: %@", [result objectForKey:@"message"]);
                                    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
                                }
                            }];
                        }]];
                        
                        [self presentViewController:alert animated:YES completion:nil];
                        
                    }}
                    ];
        
#ifdef ENTERPRISE
    } else {
        account = @[
                    @{@"title":@"Full Name", @"accessory":self->_name},
                    @{@"title":@"Auto Away", @"accessory":self->_autoaway},
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
    [device addObject:@{@"title":@"Monospace Font", @"accessory":self->_mono}];
    [device addObject:@{@"title":@"Prevent Auto-Lock", @"accessory":self->_screen}];
    [device addObject:@{@"title":@"Auto-capitalization", @"accessory":self->_autoCaps}];
    if(!isCatalyst)
        [device addObject:@{@"title":@"Preferred Browser", @"value":[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"], @"selected":^{ [self.navigationController pushViewController:[[BrowserViewController alloc] init] animated:YES]; }}];
    if([[UIDevice currentDevice] isBigPhone] || [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [device addObject:@{@"title":@"Show Sidebars In Landscape", @"accessory":self->_tabletMode}];
        [device addObject:@{@"title":@"Always show channel members", @"accessory":self->_hiddenMembers}];
    }
    [device addObject:@{@"title":@"Ask To Post A Snippet", @"accessory":self->_pastebin}];
    if(!isCatalyst) {
        [device addObject:@{@"title":@"Open Images in Browser", @"accessory":self->_imageViewer}];
        [device addObject:@{@"title":@"Open Videos in Browser", @"accessory":self->_videoViewer}];
        [device addObject:@{@"title":@"Retry Failed Images in Browser", @"accessory":self->_browserWarning}];
    }
    
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    if(!isCatalyst) {
        [photos addObject:@{@"title":@"Save to Camera Roll", @"accessory":self->_saveToCameraRoll}];
    }
    [photos addObject:@{@"title":@"Image Size", @"value":imageSize, @"selected":^{[self.navigationController pushViewController:[[PhotoSizeViewController alloc] init] animated:YES];}}];

    NSMutableArray *notifications = [[NSMutableArray alloc] init];
    [notifications addObject:@{@"title":@"Default Alert Sound", @"accessory":self->_defaultSound}];
    [notifications addObject:@{@"title":@"Preview Uploaded Files", @"accessory":self->_notificationPreviews}];
    [notifications addObject:@{@"title":@"Preview External URLs", @"accessory":self->_thirdPartyNotificationPreviews}];
    [notifications addObject:@{@"title":@"Notify On All Messages", @"accessory":self->_notifyAll}];
    [notifications addObject:@{@"title":@"Show Unread Indicators", @"accessory":self->_showUnread}];
    [notifications addObject:@{@"title":@"Mark As Read Automatically", @"accessory":self->_markAsRead}];
#ifndef ENTERPRISE
    [notifications addObject:@{@"title":@"Mute Notifications", @"accessory":self->_muteNotifications}];
#endif
    
    self->_data = @[
              @{@"title":@"Account", @"items":account},
              @{@"title":@"Highlight Words", @"items":@[
                        @{@"configure":^(UITableViewCell *cell) {
                            cell.textLabel.text = nil;
                            [self->_highlights removeFromSuperview];
                            self->_highlights.frame = CGRectInset(cell.contentView.bounds, 4, 4);
                            [cell.contentView addSubview:self->_highlights];
                        }, @"style":@(UITableViewCellStyleDefault)}
                        ]},
              @{@"title":@"Message Layout", @"items":@[
                         @{@"title":@"Nicknames on Separate Line", @"accessory":self->_oneLine},
                         @{@"title":@"Show Real Names", @"accessory":self->_noRealName},
                         @{@"title":@"Right Hand Side Timestamps", @"accessory":self->_timeLeft},
                         @{@"title":@"User Icons", @"accessory":self->_avatarsOff},
#ifndef ENTERPRISE
                         @{@"title":@"Avatars", @"accessory":self->_avatarImages},
#endif
                         @{@"title":@"Compact Spacing", @"accessory":self->_compact},
                         @{@"title":@"24-Hour Clock", @"accessory":self->_24hour},
                         @{@"title":@"Show Seconds", @"accessory":self->_seconds},
                         @{@"title":@"Usermode Symbols", @"accessory":self->_symbols, @"subtitle":@"@, +, etc."},
                         @{@"title":@"Colourise Nicknames", @"accessory":self->_colors},
                         @{@"title":@"Colourise Mentions", @"accessory":self->_colorizeMentions},
                         @{@"title":@"Convert :emocodes: to Emoji", @"accessory":self->_emocodes, @"subtitle":@":thumbsup: → 👍"},
                         @{@"title":@"Enlarge Emoji Messages", @"accessory":self->_disableBigEmoji},
                         ]},
              @{@"title":@"Chat & Embeds", @"items":@[
                        @{@"title":@"Show Joins, Parts, Quits", @"accessory":self->_hideJoinPart},
                        @{@"title":@"Collapse Joins, Parts, Quits", @"accessory":self->_expandJoinPart},
                        @{@"title":@"Embed Uploaded Files", @"accessory":self->_disableInlineFiles},
                        @{@"title":@"Embed External Media", @"accessory":self->_inlineImages},
                        @{@"title":@"Embed Using Mobile Data", @"accessory":self->_inlineWifiOnly},
                        @{@"title":@"Format inline code", @"accessory":self->_disableCodeSpan},
                        @{@"title":@"Format code blocks", @"accessory":self->_disableCodeBlock},
                        @{@"title":@"Format quoted text", @"accessory":self->_disableQuote},
                        @{@"title":@"Format colours", @"accessory":self->_noColor},
                        @{@"title":@"Clear colours after sending", @"accessory":self->_clearFormattingAfterSending},
                        @{@"title":@"Share typing status", @"accessory":self->_disableTypingStatus},
                        ]},
              @{@"title":@"Device", @"items":device},
              @{@"title":@"Notifications", @"items":notifications},
              @{@"title":@"Font Size", @"items":@[
                        @{@"special":^UITableViewCell *(UITableViewCell *cell, NSString *identifier) {
                            self->_fontSizeCell.fontSample.textColor = [UIColor messageTextColor];
                            [self monoToggled:nil];
                            return self->_fontSizeCell;
                        }}
                        ]},
              @{@"title":@"Photo Sharing", @"items":photos},
              @{@"title":@"About", @"items":@[
                        @{@"title":@"Feedback Channel", @"selected":^{[self dismissViewControllerAnimated:YES completion:^{
                            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"irc://irc.irccloud.com/%23feedback"]];
                        }];}},
#ifndef ENTERPRISE
                        @{@"title":@"Become a Beta Tester", @"selected":^{
                            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://testflight.apple.com/join/MApr7Une"]];}},
#endif
                        @{@"title":@"FAQ", @"selected":^{
                            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://www.irccloud.com/faq"]];}},
                        @{@"title":@"Version History", @"selected":^{
                            [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:@"https://github.com/irccloud/ios/releases"]];}},
                        @{@"title":@"Open-Source Licenses", @"selected":^{[self.navigationController pushViewController:[[LicenseViewController alloc] init] animated:YES];}},
                        @{@"title":@"Version", @"subtitle":self->_version}
                        ]}
              ];
    
    [self.tableView reloadData];
    if(self.scrollToNotifications) {
        self.scrollToNotifications = NO;
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:device.count - 1 inSection:4] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;

    self->_email = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 3, 22)];
    self->_email.text = @"";
    self->_email.textAlignment = NSTextAlignmentRight;
    self->_email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_email.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_email.keyboardType = UIKeyboardTypeEmailAddress;
    self->_email.adjustsFontSizeToFitWidth = YES;
    self->_email.returnKeyType = UIReturnKeyDone;
    self->_email.delegate = self;
    
    self->_name = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 3, 22)];
    self->_name.text = @"";
    self->_name.textAlignment = NSTextAlignmentRight;
    self->_name.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self->_name.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_name.keyboardType = UIKeyboardTypeDefault;
    self->_name.adjustsFontSizeToFitWidth = YES;
    self->_name.returnKeyType = UIReturnKeyDone;
    self->_name.delegate = self;
    
    self->_autoaway = [[UISwitch alloc] init];
    _24hour = [[UISwitch alloc] init];
    self->_seconds = [[UISwitch alloc] init];
    self->_symbols = [[UISwitch alloc] init];
    self->_colors = [[UISwitch alloc] init];
    self->_screen = [[UISwitch alloc] init];
    self->_autoCaps = [[UISwitch alloc] init];
    self->_emocodes = [[UISwitch alloc] init];
    self->_saveToCameraRoll = [[UISwitch alloc] init];
    self->_notificationSound = [[UISwitch alloc] init];
    self->_tabletMode = [[UISwitch alloc] init];
    self->_pastebin = [[UISwitch alloc] init];
    self->_mono = [[UISwitch alloc] init];
    [self->_mono addTarget:self action:@selector(monoToggled:) forControlEvents:UIControlEventValueChanged];
    self->_hideJoinPart = [[UISwitch alloc] init];
    [self->_hideJoinPart addTarget:self action:@selector(hideJoinPartToggled:) forControlEvents:UIControlEventValueChanged];
    self->_expandJoinPart = [[UISwitch alloc] init];
    self->_notifyAll = [[UISwitch alloc] init];
    self->_showUnread = [[UISwitch alloc] init];
    self->_markAsRead = [[UISwitch alloc] init];
    self->_oneLine = [[UISwitch alloc] init];
    [self->_oneLine addTarget:self action:@selector(oneLineToggled:) forControlEvents:UIControlEventValueChanged];
    self->_noRealName = [[UISwitch alloc] init];
    self->_timeLeft = [[UISwitch alloc] init];
    self->_avatarsOff = [[UISwitch alloc] init];
    [self->_avatarsOff addTarget:self action:@selector(oneLineToggled:) forControlEvents:UIControlEventValueChanged];
    self->_browserWarning = [[UISwitch alloc] init];
    self->_compact = [[UISwitch alloc] init];
    self->_imageViewer = [[UISwitch alloc] init];
    self->_videoViewer = [[UISwitch alloc] init];
    self->_disableInlineFiles = [[UISwitch alloc] init];
    self->_disableBigEmoji = [[UISwitch alloc] init];
    self->_inlineWifiOnly = [[UISwitch alloc] init];
    self->_defaultSound = [[UISwitch alloc] init];
    self->_notificationPreviews = [[UISwitch alloc] init];
    [self->_notificationPreviews addTarget:self action:@selector(notificationPreviewsToggled:) forControlEvents:UIControlEventValueChanged];
    self->_thirdPartyNotificationPreviews = [[UISwitch alloc] init];
    [self->_thirdPartyNotificationPreviews addTarget:self action:@selector(thirdPartyNotificationPreviewsToggled:) forControlEvents:UIControlEventValueChanged];
    self->_disableCodeSpan = [[UISwitch alloc] init];
    self->_disableCodeBlock = [[UISwitch alloc] init];
    self->_disableQuote = [[UISwitch alloc] init];
    self->_inlineImages = [[UISwitch alloc] init];
    [self->_inlineImages addTarget:self action:@selector(thirdPartyNotificationPreviewsToggled:) forControlEvents:UIControlEventValueChanged];
    self->_clearFormattingAfterSending = [[UISwitch alloc] init];
    self->_avatarImages = [[UISwitch alloc] init];
    self->_colorizeMentions = [[UISwitch alloc] init];
    self->_hiddenMembers = [[UISwitch alloc] init];
    self->_muteNotifications = [[UISwitch alloc] init];
    self->_noColor = [[UISwitch alloc] init];
    self->_disableTypingStatus = [[UISwitch alloc] init];

    self->_highlights = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_highlights.text = @"";
    self->_highlights.backgroundColor = [UIColor clearColor];
    self->_highlights.returnKeyType = UIReturnKeyDone;
    self->_highlights.delegate = self;
    self->_highlights.font = self->_email.font;
    self->_highlights.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_highlights.keyboardAppearance = [UITextField appearance].keyboardAppearance;

    self->_version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
#ifdef BRAND_NAME
    self->_version = [self->_version stringByAppendingFormat:@"-%@", BRAND_NAME];
#endif
#ifndef APPSTORE
    self->_version = [self->_version stringByAppendingFormat:@" (%@)", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
#endif
    
    self->_fontSize = [[UISlider alloc] init];
    self->_fontSize.minimumValue = FONT_MIN;
    self->_fontSize.maximumValue = FONT_MAX;
    self->_fontSize.continuous = YES;
    [self->_fontSize addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    
    self->_fontSizeCell = [[FontSizeCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    self->_fontSizeCell.fontSize = self->_fontSize;
    
    [self setFromPrefs];
    [self refresh];
}

-(void)setFromPrefs {
    NSDictionary *userInfo = [NetworkConnection sharedInstance].userInfo;
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    if([[userInfo objectForKey:@"name"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"name"] length])
        self->_name.text = [userInfo objectForKey:@"name"];
    else
        self->_name.text = @"";
    
    if([[userInfo objectForKey:@"email"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"email"] length])
        self->_email.text = [userInfo objectForKey:@"email"];
    else
        self->_email.text = @"";
    
    if([[userInfo objectForKey:@"autoaway"] isKindOfClass:[NSNumber class]]) {
        self->_autoaway.on = [[userInfo objectForKey:@"autoaway"] boolValue];
    }
    
    if([[userInfo objectForKey:@"highlights"] isKindOfClass:[NSArray class]] && [(NSArray *)[userInfo objectForKey:@"highlights"] count])
        self->_highlights.text = [[userInfo objectForKey:@"highlights"] componentsJoinedByString:@", "];
    else if([[userInfo objectForKey:@"highlights"] isKindOfClass:[NSString class]] && [[userInfo objectForKey:@"highlights"] length])
        self->_highlights.text = [userInfo objectForKey:@"highlights"];
    else
        self->_highlights.text = @"";
    
    if([[prefs objectForKey:@"time-24hr"] isKindOfClass:[NSNumber class]]) {
        _24hour.on = [[prefs objectForKey:@"time-24hr"] boolValue];
    } else {
        _24hour.on = NO;
    }
    
    if([[prefs objectForKey:@"time-seconds"] isKindOfClass:[NSNumber class]]) {
        self->_seconds.on = [[prefs objectForKey:@"time-seconds"] boolValue];
    } else {
        self->_seconds.on = NO;
    }
    
    if([[prefs objectForKey:@"mode-showsymbol"] isKindOfClass:[NSNumber class]]) {
        self->_symbols.on = [[prefs objectForKey:@"mode-showsymbol"] boolValue];
    } else {
        self->_symbols.on = NO;
    }
    
    if([[prefs objectForKey:@"nick-colors"] isKindOfClass:[NSNumber class]]) {
        self->_colors.on = [[prefs objectForKey:@"nick-colors"] boolValue];
    } else {
        self->_colors.on = NO;
    }
    
    if([[prefs objectForKey:@"mention-colors"] isKindOfClass:[NSNumber class]]) {
        self->_colorizeMentions.on = [[prefs objectForKey:@"mention-colors"] boolValue];
    } else {
        self->_colorizeMentions.on = NO;
    }
    
    if([[prefs objectForKey:@"emoji-disableconvert"] isKindOfClass:[NSNumber class]]) {
        self->_emocodes.on = ![[prefs objectForKey:@"emoji-disableconvert"] boolValue];
    } else {
        self->_emocodes.on = YES;
    }
    
    if([[prefs objectForKey:@"pastebin-disableprompt"] isKindOfClass:[NSNumber class]]) {
        self->_pastebin.on = ![[prefs objectForKey:@"pastebin-disableprompt"] boolValue];
    } else {
        self->_pastebin.on = YES;
    }
    
    if([[prefs objectForKey:@"hideJoinPart"] isKindOfClass:[NSNumber class]]) {
        self->_hideJoinPart.on = ![[prefs objectForKey:@"hideJoinPart"] boolValue];
    } else {
        self->_hideJoinPart.on = YES;
    }
    
    if([[prefs objectForKey:@"expandJoinPart"] isKindOfClass:[NSNumber class]]) {
        self->_expandJoinPart.on = ![[prefs objectForKey:@"expandJoinPart"] boolValue];
    } else {
        self->_expandJoinPart.on = YES;
    }
    
    self->_expandJoinPart.enabled = self->_hideJoinPart.on;
    
    if([[prefs objectForKey:@"font"] isKindOfClass:[NSString class]]) {
        self->_mono.on = [[prefs objectForKey:@"font"] isEqualToString:@"mono"];
    } else {
        self->_mono.on = NO;
    }
    
    if([[prefs objectForKey:@"notifications-all"] isKindOfClass:[NSNumber class]]) {
        self->_notifyAll.on = [[prefs objectForKey:@"notifications-all"] boolValue];
    } else {
        self->_notifyAll.on = NO;
    }
    
    if([[prefs objectForKey:@"disableTrackUnread"] isKindOfClass:[NSNumber class]]) {
        self->_showUnread.on = ![[prefs objectForKey:@"disableTrackUnread"] boolValue];
    } else {
        self->_showUnread.on = YES;
    }
    
    if([[prefs objectForKey:@"enableReadOnSelect"] isKindOfClass:[NSNumber class]]) {
        self->_markAsRead.on = [[prefs objectForKey:@"enableReadOnSelect"] boolValue];
    } else {
        self->_markAsRead.on = NO;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"chat-oneline"]) {
        self->_oneLine.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"chat-oneline"];
    } else {
        self->_oneLine.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"chat-norealname"]) {
        self->_noRealName.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"chat-norealname"];
    } else {
        self->_noRealName.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"time-left"]) {
        self->_timeLeft.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"time-left"];
    } else {
        self->_timeLeft.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"avatars-off"]) {
        self->_avatarsOff.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"avatars-off"];
    } else {
        self->_avatarsOff.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"warnBeforeLaunchingBrowser"]) {
        self->_browserWarning.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"warnBeforeLaunchingBrowser"];
    } else {
        self->_browserWarning.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"inlineWifiOnly"]) {
        self->_inlineWifiOnly.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"inlineWifiOnly"];
    } else {
        self->_inlineWifiOnly.on = YES;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"hiddenMembers"]) {
        self->_hiddenMembers.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"hiddenMembers"];
    } else {
        self->_hiddenMembers.on = YES;
    }
    
    if(self->_oneLine.on) {
        self->_noRealName.enabled = YES;
        if(self->_avatarsOff.on) {
            self->_timeLeft.enabled = NO;
            self->_timeLeft.on = YES;
        } else {
            self->_timeLeft.enabled = YES;
        }
    } else {
        self->_noRealName.enabled = NO;
        self->_timeLeft.enabled = YES;
    }
    
    if([[prefs objectForKey:@"ascii-compact"] isKindOfClass:[NSNumber class]]) {
        self->_compact.on = [[prefs objectForKey:@"ascii-compact"] boolValue];
    } else {
        self->_compact.on = NO;
    }
    
    if([[prefs objectForKey:@"files-disableinline"] isKindOfClass:[NSNumber class]]) {
        self->_disableInlineFiles.on = ![[prefs objectForKey:@"files-disableinline"] boolValue];
    } else {
        self->_disableInlineFiles.on = YES;
    }
    
    if([[prefs objectForKey:@"inlineimages"] isKindOfClass:[NSNumber class]]) {
        self->_inlineImages.on = [[prefs objectForKey:@"inlineimages"] boolValue];
    } else {
        self->_inlineImages.on = NO;
    }
    
    if([[prefs objectForKey:@"emoji-nobig"] isKindOfClass:[NSNumber class]]) {
        self->_disableBigEmoji.on = ![[prefs objectForKey:@"emoji-nobig"] boolValue];
    } else {
        self->_disableBigEmoji.on = YES;
    }
    
    if([[prefs objectForKey:@"chat-nocodespan"] isKindOfClass:[NSNumber class]]) {
        self->_disableCodeSpan.on = ![[prefs objectForKey:@"chat-nocodespan"] boolValue];
    } else {
        self->_disableCodeSpan.on = YES;
    }
    
    if([[prefs objectForKey:@"chat-nocodeblock"] isKindOfClass:[NSNumber class]]) {
        self->_disableCodeBlock.on = ![[prefs objectForKey:@"chat-nocodeblock"] boolValue];
    } else {
        self->_disableCodeBlock.on = YES;
    }
    
    if([[prefs objectForKey:@"chat-noquote"] isKindOfClass:[NSNumber class]]) {
        self->_disableQuote.on = ![[prefs objectForKey:@"chat-noquote"] boolValue];
    } else {
        self->_disableQuote.on = YES;
    }
    
    if([[prefs objectForKey:@"notifications-mute"] isKindOfClass:[NSNumber class]]) {
        self->_muteNotifications.on = [[prefs objectForKey:@"notifications-mute"] boolValue];
    } else {
        self->_muteNotifications.on = NO;
    }
    
    if([[prefs objectForKey:@"chat-nocolor"] isKindOfClass:[NSNumber class]]) {
        self->_noColor.on = ![[prefs objectForKey:@"chat-nocolor"] boolValue];
    } else {
        self->_noColor.on = YES;
    }
    
    if([[prefs objectForKey:@"disableTypingStatus"] isKindOfClass:[NSNumber class]]) {
        self->_disableTypingStatus.on = ![[prefs objectForKey:@"disableTypingStatus"] boolValue];
    } else {
        self->_disableTypingStatus.on = YES;
    }
    
    self->_screen.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"keepScreenOn"];
    self->_autoCaps.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"];
    self->_saveToCameraRoll.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"];
    self->_notificationSound.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"notificationSound"];
    self->_tabletMode.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"tabletMode"];
    self->_fontSize.value = [[NSUserDefaults standardUserDefaults] floatForKey:@"fontSize"];
    self->_imageViewer.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"imageViewer"];
    self->_videoViewer.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"videoViewer"];
    self->_defaultSound.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"defaultSound"];
    self->_notificationPreviews.on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"disableNotificationPreviews"];
    self->_thirdPartyNotificationPreviews.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"thirdPartyNotificationPreviews"];
    self->_clearFormattingAfterSending.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"clearFormattingAfterSending"];
    self->_avatarImages.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"avatarImages"];
}

-(void)hideJoinPartToggled:(id)sender {
    self->_expandJoinPart.enabled = self->_hideJoinPart.on;
}

-(void)oneLineToggled:(id)sender {
    if(self->_oneLine.on) {
        self->_noRealName.enabled = YES;
        if(self->_avatarsOff.on) {
            self->_timeLeft.enabled = NO;
            self->_timeLeft.on = YES;
        } else {
            self->_timeLeft.enabled = YES;
        }
    } else {
        self->_noRealName.enabled = NO;
        self->_timeLeft.enabled = YES;
    }
}

-(void)monoToggled:(id)sender {
    if(self->_mono.on)
        self->_fontSizeCell.fontSample.font = [UIFont fontWithName:@"Hack" size:self->_fontSize.value - 1];
    else
        self->_fontSizeCell.fontSample.font = [UIFont fontWithDescriptor:[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] size:self->_fontSize.value];
}

-(void)notificationPreviewsToggled:(id)sender {
    self->_thirdPartyNotificationPreviews.enabled = self->_notificationPreviews.on;
}

-(void)thirdPartyNotificationPreviewsToggled:(UISwitch *)sender {
    [self->_inlineImages addTarget:self action:@selector(thirdPartyNotificationPreviewsToggled:) forControlEvents:UIControlEventValueChanged];
    if(sender.on) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Warning" message:@"External URLs may load insecurely and could result in your IP address being revealed to external site operators" preferredStyle:UIAlertControllerStyleAlert];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            sender.on = NO;
        }]];

        [ac addAction:[UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:nil]];

        [self presentViewController:ac animated:YES completion:nil];
    }
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 1 || [[[self->_data objectAtIndex:indexPath.section] objectForKey:@"title"] isEqualToString:@"Font Size"])
        return ([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 2) + 32;
    else
        return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [(NSArray *)[[self->_data objectAtIndex:section] objectForKey:@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self->_data objectAtIndex:section] objectForKey:@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [NSString stringWithFormat:@"settingscell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSDictionary *item = [[[self->_data objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];
    
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
    NSDictionary *item = [[[self->_data objectAtIndex:indexPath.section] objectForKey:@"items"] objectAtIndex:indexPath.row];

    if([item objectForKey:@"selected"]) {
        void (^selected)(void) = [item objectForKey:@"selected"];
        selected();
    }
}

@end
