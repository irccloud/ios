//
//  SettingsViewController.h
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

@interface FontSizeCell : UITableViewCell {
    UILabel *_small;
    UILabel *_large;
    UILabel *_fontSample;
    UISlider *_fontSize;
}
@property (readonly) UILabel *fontSample;
-(void)setFontSize:(UISlider *)fontSize;
@end

@interface SettingsViewController : UITableViewController<UITextFieldDelegate,UITextViewDelegate> {
    UITextField *_email;
    UITextField *_name;
    UITextView *_highlights;
    UISwitch *_autoaway;
    UISwitch *_24hour;
    UISwitch *_seconds;
    UISwitch *_symbols;
    UISwitch *_colors;
    UISwitch *_screen;
    UISwitch *_autoCaps;
    UISwitch *_emocodes;
    UISwitch *_saveToCameraRoll;
    UISwitch *_notificationSound;
    UISwitch *_tabletMode;
    UISwitch *_pastebin;
    UISwitch *_mono;
    UISwitch *_hideJoinPart;
    UISwitch *_expandJoinPart;
    UISwitch *_notifyAll;
    UISwitch *_showUnread;
    UISwitch *_markAsRead;
    UISwitch *_oneLine;
    UISwitch *_noRealName;
    UISwitch *_timeLeft;
    UISwitch *_avatarsOff;
    UISwitch *_browserWarning;
    UISwitch *_compact;
    UISwitch *_imageViewer;
    UISwitch *_videoViewer;
    UISwitch *_disableInlineFiles;
    UISwitch *_disableBigEmoji;
    UISwitch *_inlineWifiOnly;
    UISwitch *_defaultSound;
    UISwitch *_notificationPreviews;
    UISwitch *_thirdPartyNotificationPreviews;
    UISwitch *_disableCodeSpan;
    UISwitch *_disableCodeBlock;
    UISwitch *_disableQuote;
    UISwitch *_inlineImages;
    UISwitch *_clearFormattingAfterSending;
    UISwitch *_avatarImages;
    UISwitch *_colorizeMentions;
    UISwitch *_hiddenMembers;
    UISwitch *_muteNotifications;
    UISwitch *_noColor;
    UISwitch *_disableTypingStatus;
    UISwitch *_showDeleted;
    NSString *_version;
    UISlider *_fontSize;
    NSString *_oldTheme;
    NSArray *_data;
    FontSizeCell *_fontSizeCell;
}
@property BOOL scrollToNotifications;
@end
