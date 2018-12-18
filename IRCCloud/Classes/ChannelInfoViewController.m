//
//  ChannelInfoViewController.m
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

#import <MobileCoreServices/UTCoreTypes.h>
#import <MobileCoreServices/UTType.h>
#import "ChannelInfoViewController.h"
#import "ColorFormatter.h"
#import "NetworkConnection.h"
#import "AppDelegate.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "UIColor+IRCCloud.h"

@implementation ChannelInfoViewController

-(id)initWithChannel:(Channel *)channel {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self->_channel = channel;
        self->_modeHints = [[NSMutableArray alloc] init];
        self->_topicChanged = NO;
        Server *s = [[ServersDataSource sharedInstance] getServer:channel.cid];
        self->_topiclen = [[s.isupport objectForKey:@"TOPICLEN"] longValue];
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        offset = 40;
    } else {
        offset = 80;
    }
    self.navigationItem.title = [NSString stringWithFormat:@"%@ Info", _channel.name];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    self->_topicLabel = [[LinkTextView alloc] initWithFrame:CGRectZero];
    self->_topicLabel.editable = NO;
    self->_topicLabel.scrollEnabled = NO;
    self->_topicLabel.textContainerInset = UIEdgeInsetsZero;
    self->_topicLabel.dataDetectorTypes = UIDataDetectorTypeNone;
    self->_topicLabel.linkDelegate = self;
    self->_topicLabel.backgroundColor = [UIColor clearColor];
    self->_topicLabel.textColor = [UIColor messageTextColor];
    self->_topicLabel.textContainer.lineFragmentPadding = 0;

    self->_url = [[LinkTextView alloc] initWithFrame:CGRectZero];
    self->_url.editable = NO;
    self->_url.scrollEnabled = NO;
    self->_url.textContainerInset = UIEdgeInsetsZero;
    self->_url.dataDetectorTypes = UIDataDetectorTypeNone;
    self->_url.linkDelegate = self;
    self->_url.backgroundColor = [UIColor clearColor];
    self->_url.textColor = [UIColor messageTextColor];
    self->_url.textContainer.lineFragmentPadding = 0;
    
    self->_topicEdit = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_topicEdit.font = [UIFont systemFontOfSize:14];
    self->_topicEdit.returnKeyType = UIReturnKeyDone;
    self->_topicEdit.delegate = self;
    self->_topicEdit.textStorage.delegate = self;
    self->_topicEdit.backgroundColor = [UIColor clearColor];
    self->_topicEdit.textColor = [UIColor textareaTextColor];
    self->_topicEdit.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    self->_topicEdit.allowsEditingTextAttributes = YES;
    
    self->_colorPickerView = [[IRCColorPickerView alloc] initWithFrame:CGRectZero];
    self->_colorPickerView.frame = CGRectMake(self.view.bounds.size.width / 2 - _colorPickerView.intrinsicContentSize.width / 2,20,_colorPickerView.intrinsicContentSize.width,_colorPickerView.intrinsicContentSize.height);
    self->_colorPickerView.delegate = self;
    self->_colorPickerView.alpha = 0;
    [self->_colorPickerView updateButtonColors:YES];
    [self.navigationController.view addSubview:self->_colorPickerView];

    [self refresh];
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)LinkTextView:(LinkTextView *)label didSelectLinkWithTextCheckingResult:(NSTextCheckingResult *)result {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:result.URL];
    if([result.URL.scheme hasPrefix:@"irc"])
        [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    
    switch(event) {
        case kIRCEventChannelInit:
        case kIRCEventChannelTopic:
        case kIRCEventChannelMode:
        case kIRCEventUserChannelMode:
            o = notification.object;
            if(o.bid == self->_channel.bid && !self.tableView.editing)
                [self refresh];
            break;
        default:
            break;
    }
}

-(void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    self->_topicChanged = YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(action == @selector(chooseFGColor:) || action == @selector(chooseBGColor:) || action == @selector(resetColors:)) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

-(void)resetColors:(id)sender {
    if(self->_topicEdit.selectedRange.length) {
        NSRange selection = self->_topicEdit.selectedRange;
        NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
        [msg removeAttribute:NSForegroundColorAttributeName range:self->_topicEdit.selectedRange];
        [msg removeAttribute:NSBackgroundColorAttributeName range:self->_topicEdit.selectedRange];
        self->_topicEdit.attributedText = msg;
        self->_topicEdit.selectedRange = selection;
    } else {
        self->_currentMessageAttributes = self->_topicEdit.typingAttributes = @{NSForegroundColorAttributeName:[UIColor textareaTextColor], NSFontAttributeName:self->_topicEdit.font };
    }
}

-(void)chooseFGColor:(id)sender {
    [self->_colorPickerView updateButtonColors:NO];
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 1; } completion:nil];
}

-(void)chooseBGColor:(id)sender {
    [self->_colorPickerView updateButtonColors:YES];
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 1; } completion:nil];
}

-(void)foregroundColorPicked:(UIColor *)color {
    if(self->_topicEdit.selectedRange.length) {
        NSRange selection = self->_topicEdit.selectedRange;
        NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
        [msg addAttribute:NSForegroundColorAttributeName value:color range:self->_topicEdit.selectedRange];
        self->_topicEdit.attributedText = msg;
        self->_topicEdit.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:self->_topicEdit.typingAttributes];
        [d setObject:color forKey:NSForegroundColorAttributeName];
        self->_topicEdit.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)backgroundColorPicked:(UIColor *)color {
    if(self->_topicEdit.selectedRange.length) {
        NSRange selection = self->_topicEdit.selectedRange;
        NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
        [msg addAttribute:NSBackgroundColorAttributeName value:color range:self->_topicEdit.selectedRange];
        self->_topicEdit.attributedText = msg;
        self->_topicEdit.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:self->_topicEdit.typingAttributes];
        [d setObject:color forKey:NSBackgroundColorAttributeName];
        self->_topicEdit.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)closeColorPicker {
    [UIView animateWithDuration:0.25 animations:^{ self->_colorPickerView.alpha = 0; } completion:nil];
}

-(void)textViewDidChangeSelection:(UITextView *)textView {
    [self closeColorPicker];
}

-(void)textViewDidChange:(UITextView *)textView {
    if(self->_currentMessageAttributes)
        textView.typingAttributes = self->_currentMessageAttributes;
    else
        self->_currentMessageAttributes = textView.typingAttributes;
    topicHeader.text = [self tableView:self.tableView titleForHeaderInSection:0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.location == textView.text.length)
        self->_currentMessageAttributes = textView.typingAttributes;
    else
        self->_currentMessageAttributes = nil;

    if(text.length && [text isEqualToString:[UIPasteboard generalPasteboard].string]) {
        if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"]) {
            NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
            if(self->_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter format:[[NSString alloc] initWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"] encoding:NSUTF8StringEncoding] defaultColor:self->_topicEdit.textColor mono:NO linkify:NO server:nil links:nil] atIndex:self->_topicEdit.selectedRange.location];
            
            [self->_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF]) {
            NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
            if(self->_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF] options:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_topicEdit.font.pointSize] atIndex:self->_topicEdit.selectedRange.location];
            
            [self->_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD]) {
            NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
            if(self->_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD] options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_topicEdit.font.pointSize] atIndex:self->_topicEdit.selectedRange.location];
            
            [self->_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"]) {
            NSDictionary *d = [NSPropertyListSerialization propertyListWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"] options:NSPropertyListImmutable format:NULL error:NULL];
            NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
            if(self->_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[d objectForKey:@"WebMainResource"] objectForKey:@"WebResourceData"] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil] fontSize:self->_topicEdit.font.pointSize] atIndex:self->_topicEdit.selectedRange.location];
            
            [self->_topicEdit setAttributedText:msg];
        } else if([UIPasteboard generalPasteboard].string) {
            NSMutableAttributedString *msg = self->_topicEdit.attributedText.mutableCopy;
            if(self->_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:self->_topicEdit.selectedRange];
            
            [msg insertAttributedString:[[NSAttributedString alloc] initWithString:[UIPasteboard generalPasteboard].string attributes:@{NSFontAttributeName:self->_topicEdit.font,NSForegroundColorAttributeName:self->_topicEdit.textColor}] atIndex:self->_topicEdit.selectedRange.location];
            
            [self->_topicEdit setAttributedText:msg];
        }
        return NO;
    } else if([text isEqualToString:@"\n"]) {
        [self setEditing:NO animated:YES];
        return NO;
    }
    self->_topicChanged = YES;
    return YES;
}

-(void)refresh {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self->_modeHints removeAllObjects];
    self->_topicChanged = NO;
    Server *server = [[ServersDataSource sharedInstance] getServer:self->_channel.cid];
    if([self->_channel.topic_text isKindOfClass:[NSString class]] && _channel.topic_text.length) {
        NSArray *links;
        self->_topic = [ColorFormatter format:self->_channel.topic_text defaultColor:[UIColor textareaTextColor] mono:NO linkify:YES server:[[ServersDataSource sharedInstance] getServer:self->_channel.cid] links:&links];
        self->_topicLabel.attributedText = self->_topic;
        self->_topicLabel.linkAttributes = [UIColor linkAttributes];
        
        for(NSTextCheckingResult *result in links) {
            if(result.resultType == NSTextCheckingTypeLink) {
                [self->_topicLabel addLinkWithTextCheckingResult:result];
            } else {
                NSString *url = [[self->_topic attributedSubstringFromRange:result.range] string];
                if(![url hasPrefix:@"irc"]) {
                    CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                    if(url_escaped != NULL) {
                        url = [NSString stringWithFormat:@"irc://%i/%@", server.cid, url_escaped];
                        CFRelease(url_escaped);
                    }
                }
                [self->_topicLabel addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
            }
        }
        self->_topicEdit.attributedText = self->_topic;
        
        if(self->_channel.topic_author) {
            self->_topicSetBy = [NSString stringWithFormat:@"Set by %@", _channel.topic_author];
            if(self->_channel.topic_time > 0) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                
                self->_topicSetBy = [self->_topicSetBy stringByAppendingFormat:@" on %@", [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self->_channel.topic_time]]];
            }
        } else {
            self->_topicSetBy = nil;
        }
    } else {
        self->_topic = [ColorFormatter format:@"(No topic set)" defaultColor:[UIColor textareaTextColor] mono:NO linkify:NO server:nil links:nil];
        self->_topicLabel.attributedText = self->_topic;
        self->_topicEdit.text = @"";
        self->_topicSetBy = nil;
    }
    if(([self->_channel.url isKindOfClass:[NSString class]] && _channel.url.length) || server.isSlack) {
        NSString *url = server.isSlack ? [NSString stringWithFormat:@"%@/messages/%@/details", server.slackBaseURL, [[BuffersDataSource sharedInstance] getBuffer:self->_channel.bid].normalizedName] : _channel.url;
        NSArray *links;
        self->_url.attributedText = [ColorFormatter format:url defaultColor:[UIColor textareaTextColor] mono:NO linkify:YES server:[[ServersDataSource sharedInstance] getServer:self->_channel.cid] links:&links];
        self->_url.linkAttributes = [UIColor linkAttributes];
        
        for(NSTextCheckingResult *result in links) {
            if(result.resultType == NSTextCheckingTypeLink) {
                [self->_url addLinkWithTextCheckingResult:result];
            } else {
                NSString *url = [[self->_topic attributedSubstringFromRange:result.range] string];
                if(![url hasPrefix:@"irc"]) {
                    CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                    if(url_escaped != NULL) {
                        url = [NSString stringWithFormat:@"irc://%i/%@", server.cid, url_escaped];
                        CFRelease(url_escaped);
                    }
                }
                [self->_url addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
            }
        }
    } else {
        self->_url.attributedText = nil;
    }
    if(self->_channel.mode.length) {
        for(NSDictionary *mode in _channel.modes) {
            unichar m = [[mode objectForKey:@"mode"] characterAtIndex:0];
            switch(m) {
                case 'i':
                    [self->_modeHints addObject:@{@"mode":@"Invite Only (+i)", @"hint":@"Members must be invited to join this channel."}];
                    break;
                case 'k':
                    [self->_modeHints addObject:@{@"mode":@"Password (+k)", @"hint":[mode objectForKey:@"param"]}];
                    break;
                case 'm':
                    [self->_modeHints addObject:@{@"mode":@"Moderated (+m)", @"hint":@"Only ops and voiced members may talk."}];
                    break;
                case 'n':
                    [self->_modeHints addObject:@{@"mode":@"No External Messages (+n)", @"hint":@"No messages allowed from outside the channel."}];
                    break;
                case 'p':
                    [self->_modeHints addObject:@{@"mode":@"Private (+p)", @"hint":@"Membership is only visible to other members."}];
                    break;
                case 's':
                    [self->_modeHints addObject:@{@"mode":@"Secret (+s)", @"hint":@"This channel is unlisted and membership is only visible to other members."}];
                    break;
                case 't':
                    [self->_modeHints addObject:@{@"mode":@"Topic Control (+t)", @"hint":@"Only ops can set the topic."}];
                    User *u = [[UsersDataSource sharedInstance] getUser:server.nick cid:self->_channel.cid bid:self->_channel.bid];
                    if(u && [u.mode rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:server?[NSString stringWithFormat:@"%@%@%@%@%@",server.MODE_OPER, server.MODE_OWNER, server.MODE_ADMIN, server.MODE_OP, server.MODE_HALFOP]:@"Yqaoh"]].location == NSNotFound)
                        self.navigationItem.rightBarButtonItem = nil;
                    break;
            }
        }
    }
    if(self->_channel.bid == -1)
        self.navigationItem.rightBarButtonItem = nil;
    [self.tableView reloadData];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,48)];

    if(!topicHeader) {
        if(@available(iOS 11, *)) {
            topicHeader = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,24,self.view.frame.size.width - 32, 20)];
        } else {
            topicHeader = [[UILabel alloc] initWithFrame:CGRectMake(16,24,self.view.frame.size.width - 32, 20)];
        }
        topicHeader.font = [UIFont systemFontOfSize:14];
        topicHeader.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    }
    if(!urlHeader) {
        if(@available(iOS 11, *)) {
            urlHeader = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,24,self.view.frame.size.width - 32, 20)];
        } else {
            urlHeader = [[UILabel alloc] initWithFrame:CGRectMake(16,24,self.view.frame.size.width - 32, 20)];
        }
        urlHeader.font = [UIFont systemFontOfSize:14];
        urlHeader.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    }
    if(!modesHeader) {
        if(@available(iOS 11, *)) {
            modesHeader = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,24,self.view.frame.size.width - 32, 20)];
        } else {
            modesHeader = [[UILabel alloc] initWithFrame:CGRectMake(16,24,self.view.frame.size.width - 32, 20)];
        }
        modesHeader.font = [UIFont systemFontOfSize:14];
        modesHeader.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    }
    
    if(section == 1 && !_url.attributedText.length)
        section++;
    
    switch (section) {
        case 0:
            [topicHeader removeFromSuperview];
            topicHeader.text = [self tableView:tableView titleForHeaderInSection:section];
            [header addSubview:topicHeader];
            break;
        case 1:
            [urlHeader removeFromSuperview];
            urlHeader.text = [self tableView:tableView titleForHeaderInSection:section];
            [header addSubview:urlHeader];
            break;
        case 2:
            [modesHeader removeFromSuperview];
            modesHeader.text = [self tableView:tableView titleForHeaderInSection:section];
            [header addSubview:modesHeader];
            break;
    }
    
    return header;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,24)];
    UILabel *label;
    if(@available(iOS 11, *)) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16 + self.view.safeAreaInsets.left,4,self.view.frame.size.width - 32, 20)];
    } else {
        label = [[UILabel alloc] initWithFrame:CGRectMake(16,4,self.view.frame.size.width - 32, 20)];
    }
    label.text = [self tableView:tableView titleForFooterInSection:section];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [header addSubview:label];
    return header;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self->_channel.mode isKindOfClass:[NSString class]] && _channel.mode.length)
        return 2 + (self->_url.attributedText.length ? 1 : 0);
    else
        return 1 + (self->_url.attributedText.length ? 1 : 0);
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if(section == 1 && !_url.attributedText.length)
        section++;

    switch(section) {
        case 2:
            if(self->_modeHints.count)
                return _modeHints.count;
        default:
            return 1;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if(self.tableView.editing && !editing && _topicChanged) {
        [[NetworkConnection sharedInstance] topic:[ColorFormatter toIRC:self->_topicEdit.attributedText] chan:self->_channel.name cid:self->_channel.cid handler:nil];
    }
    [super setEditing:editing animated:animated];
    [self.tableView reloadData];
    if(editing) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_topicEdit becomeFirstResponder];
        }];
        self->_topicChanged = NO;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(tableView.isEditing)
            return 148;
        CGFloat height = [LinkTextView heightOfString:self->_topic constrainedToWidth:self.tableView.bounds.size.width - offset];
        self->_topicLabel.frame = CGRectMake(8,8,self.tableView.bounds.size.width - offset,height);
        self->_topicEdit.frame = CGRectMake(4,4,self.tableView.bounds.size.width - offset,140);
        return height + 20;
    } else if(indexPath.section == 1 && _url.attributedText.length) {
        CGFloat height = [LinkTextView heightOfString:self->_url.attributedText constrainedToWidth:self.tableView.bounds.size.width - offset];
        self->_url.frame = CGRectMake(8,8,self.tableView.bounds.size.width - offset,height);
        return height + 20;
    } else {
        if(indexPath.row == 0 && _modeHints.count == 0) {
            return 48;
        } else {
            NSString *hint = [[self->_modeHints objectAtIndex:indexPath.row] objectForKey:@"hint"];
            return ceil([hint boundingRectWithSize:CGSizeMake(self.tableView.bounds.size.width - offset,CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]} context:nil].size.height) + 32;
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if(section == 0 && _topicSetBy.length)
        return _topicSetBy;
    return nil;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if(section == 1 && !_url.attributedText.length)
        section++;
    switch(section) {
        case 0:
            if(tableView.isEditing && _topiclen) {
                return [NSString stringWithFormat:@"TOPIC (%li CHARS)", (self->_topiclen - [ColorFormatter toIRC:self->_topicEdit.attributedText].length)];
            } else {
                return @"TOPIC";
            }
        case 1:
            return @"CHANNEL URL";
        case 2:
            if(self->_modeHints.count)
                return [NSString stringWithFormat:@"MODE: +%@", _channel.mode];
            else
                return @"MODE";
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 48;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger section = indexPath.section;
    if(section == 1 && !_url.attributedText.length)
        section++;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infocell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"infocell"];
    
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    switch(section) {
        case 0:
            if(tableView.isEditing) {
                [cell.contentView addSubview:self->_topicEdit];
            } else {
                [cell.contentView addSubview:self->_topicLabel];
            }
            break;
        case 1:
            [cell.contentView addSubview:self->_url];
            break;
        case 2:
            if(self->_modeHints.count) {
                cell.textLabel.text = [[self->_modeHints objectAtIndex:indexPath.row] objectForKey:@"mode"];
                cell.detailTextLabel.text = [[self->_modeHints objectAtIndex:indexPath.row] objectForKey:@"hint"];
                cell.detailTextLabel.numberOfLines = 0;
            } else {
                cell.textLabel.text = [NSString stringWithFormat:@"+%@", _channel.mode];
            }
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

@end
