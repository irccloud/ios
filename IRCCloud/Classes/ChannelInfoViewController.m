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
        _channel = channel;
        _modeHints = [[NSMutableArray alloc] init];
        _topicChanged = NO;
        Server *s = [[ServersDataSource sharedInstance] getServer:channel.cid];
        _topiclen = [[s.isupport objectForKey:@"TOPICLEN"] longValue];
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
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
    _topicLabel = [[LinkTextView alloc] initWithFrame:CGRectZero];
    _topicLabel.editable = NO;
    _topicLabel.scrollEnabled = NO;
    _topicLabel.textContainerInset = UIEdgeInsetsZero;
    _topicLabel.dataDetectorTypes = UIDataDetectorTypeNone;
    _topicLabel.linkDelegate = self;
    _topicLabel.backgroundColor = [UIColor clearColor];
    _topicLabel.textColor = [UIColor messageTextColor];
    _topicLabel.textContainer.lineFragmentPadding = 0;

    _topicEdit = [[UITextView alloc] initWithFrame:CGRectZero];
    _topicEdit.font = [UIFont systemFontOfSize:14];
    _topicEdit.returnKeyType = UIReturnKeyDone;
    _topicEdit.delegate = self;
    _topicEdit.textStorage.delegate = self;
    _topicEdit.backgroundColor = [UIColor clearColor];
    _topicEdit.textColor = [UIColor textareaTextColor];
    _topicEdit.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    _topicEdit.allowsEditingTextAttributes = YES;
    
    _colorPickerView = [[IRCColorPickerView alloc] initWithFrame:CGRectZero];
    _colorPickerView.frame = CGRectMake(self.view.bounds.size.width / 2 - _colorPickerView.intrinsicContentSize.width / 2,20,_colorPickerView.intrinsicContentSize.width,_colorPickerView.intrinsicContentSize.height);
    _colorPickerView.delegate = self;
    _colorPickerView.alpha = 0;
    [_colorPickerView updateButtonColors:YES];
    [self.navigationController.view addSubview:_colorPickerView];

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
            if(o.bid == _channel.bid && !self.tableView.editing)
                [self refresh];
            break;
        default:
            break;
    }
}

-(void)textStorage:(NSTextStorage *)textStorage didProcessEditing:(NSTextStorageEditActions)editedMask range:(NSRange)editedRange changeInLength:(NSInteger)delta {
    _topicChanged = YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(action == @selector(chooseFGColor:) || action == @selector(chooseBGColor:) || action == @selector(resetColors:)) {
        return YES;
    }
    
    return [super canPerformAction:action withSender:sender];
}

-(void)resetColors:(id)sender {
    if(_topicEdit.selectedRange.length) {
        NSRange selection = _topicEdit.selectedRange;
        NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
        [msg removeAttribute:NSForegroundColorAttributeName range:_topicEdit.selectedRange];
        [msg removeAttribute:NSBackgroundColorAttributeName range:_topicEdit.selectedRange];
        _topicEdit.attributedText = msg;
        _topicEdit.selectedRange = selection;
    } else {
        _currentMessageAttributes = _topicEdit.typingAttributes = @{NSForegroundColorAttributeName:[UIColor textareaTextColor], NSFontAttributeName:_topicEdit.font };
    }
}

-(void)chooseFGColor:(id)sender {
    [_colorPickerView updateButtonColors:NO];
    [UIView animateWithDuration:0.25 animations:^{ _colorPickerView.alpha = 1; } completion:nil];
}

-(void)chooseBGColor:(id)sender {
    [_colorPickerView updateButtonColors:YES];
    [UIView animateWithDuration:0.25 animations:^{ _colorPickerView.alpha = 1; } completion:nil];
}

-(void)foregroundColorPicked:(UIColor *)color {
    if(_topicEdit.selectedRange.length) {
        NSRange selection = _topicEdit.selectedRange;
        NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
        [msg addAttribute:NSForegroundColorAttributeName value:color range:_topicEdit.selectedRange];
        _topicEdit.attributedText = msg;
        _topicEdit.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:_topicEdit.typingAttributes];
        [d setObject:color forKey:NSForegroundColorAttributeName];
        _topicEdit.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)backgroundColorPicked:(UIColor *)color {
    if(_topicEdit.selectedRange.length) {
        NSRange selection = _topicEdit.selectedRange;
        NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
        [msg addAttribute:NSBackgroundColorAttributeName value:color range:_topicEdit.selectedRange];
        _topicEdit.attributedText = msg;
        _topicEdit.selectedRange = selection;
    } else {
        NSMutableDictionary *d = [[NSMutableDictionary alloc] initWithDictionary:_topicEdit.typingAttributes];
        [d setObject:color forKey:NSBackgroundColorAttributeName];
        _topicEdit.typingAttributes = d;
    }
    [self closeColorPicker];
}

-(void)closeColorPicker {
    [UIView animateWithDuration:0.25 animations:^{ _colorPickerView.alpha = 0; } completion:nil];
}

-(void)textViewDidChangeSelection:(UITextView *)textView {
    [self closeColorPicker];
}

-(void)textViewDidChange:(UITextView *)textView {
    if(_currentMessageAttributes)
        textView.typingAttributes = _currentMessageAttributes;
    else
        _currentMessageAttributes = textView.typingAttributes;
    topicHeader.text = [self tableView:self.tableView titleForHeaderInSection:0];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(range.location == textView.text.length)
        _currentMessageAttributes = textView.typingAttributes;
    else
        _currentMessageAttributes = nil;

    if([text isEqualToString:[UIPasteboard generalPasteboard].string]) {
        if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"]) {
            NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
            if(_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter format:[[NSString alloc] initWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"IRC formatting type"] encoding:NSUTF8StringEncoding] defaultColor:_topicEdit.textColor mono:NO linkify:NO server:nil links:nil] atIndex:_topicEdit.selectedRange.location];
            
            [_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF]) {
            NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
            if(_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeRTF] options:@{NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType} documentAttributes:nil error:nil] fontSize:_topicEdit.font.pointSize] atIndex:_topicEdit.selectedRange.location];
            
            [_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD]) {
            NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
            if(_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[UIPasteboard generalPasteboard] dataForPasteboardType:(NSString *)kUTTypeFlatRTFD] options:@{NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType} documentAttributes:nil error:nil] fontSize:_topicEdit.font.pointSize] atIndex:_topicEdit.selectedRange.location];
            
            [_topicEdit setAttributedText:msg];
        } else if([[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"]) {
            NSDictionary *d = [NSPropertyListSerialization propertyListWithData:[[UIPasteboard generalPasteboard] valueForPasteboardType:@"Apple Web Archive pasteboard type"] options:NSPropertyListImmutable format:NULL error:NULL];
            NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
            if(_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:_topicEdit.selectedRange];
            [msg insertAttributedString:[ColorFormatter stripUnsupportedAttributes:[[NSAttributedString alloc] initWithData:[[d objectForKey:@"WebMainResource"] objectForKey:@"WebResourceData"] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType} documentAttributes:nil error:nil] fontSize:_topicEdit.font.pointSize] atIndex:_topicEdit.selectedRange.location];
            
            [_topicEdit setAttributedText:msg];
        } else if([UIPasteboard generalPasteboard].string) {
            NSMutableAttributedString *msg = _topicEdit.attributedText.mutableCopy;
            if(_topicEdit.selectedRange.length > 0)
                [msg deleteCharactersInRange:_topicEdit.selectedRange];
            
            [msg insertAttributedString:[[NSAttributedString alloc] initWithString:[UIPasteboard generalPasteboard].string attributes:@{NSFontAttributeName:_topicEdit.font,NSForegroundColorAttributeName:_topicEdit.textColor}] atIndex:_topicEdit.selectedRange.location];
            
            [_topicEdit setAttributedText:msg];
        }
        return NO;
    } else if([text isEqualToString:@"\n"]) {
        [self setEditing:NO animated:YES];
        return NO;
    }
    _topicChanged = YES;
    return YES;
}

-(void)refresh {
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [_modeHints removeAllObjects];
    _topicChanged = NO;
    Server *server = [[ServersDataSource sharedInstance] getServer:_channel.cid];
    if([_channel.topic_text isKindOfClass:[NSString class]] && _channel.topic_text.length) {
        NSArray *links;
        _topic = [ColorFormatter format:_channel.topic_text defaultColor:[UIColor textareaTextColor] mono:NO linkify:YES server:[[ServersDataSource sharedInstance] getServer:_channel.cid] links:&links];
        _topicLabel.attributedText = _topic;
        _topicLabel.linkAttributes = [UIColor linkAttributes];
        
        for(NSTextCheckingResult *result in links) {
            if(result.resultType == NSTextCheckingTypeLink) {
                [_topicLabel addLinkWithTextCheckingResult:result];
            } else {
                NSString *url = [[_topic attributedSubstringFromRange:result.range] string];
                if(![url hasPrefix:@"irc"]) {
                    CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                    if(url_escaped != NULL) {
                        url = [NSString stringWithFormat:@"irc://%i/%@", server.cid, url_escaped];
                        CFRelease(url_escaped);
                    }
                }
                [_topicLabel addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
            }
        }
        _topicEdit.attributedText = _topic;
        
        if(_channel.topic_author) {
            _topicSetBy = [NSString stringWithFormat:@"Set by %@", _channel.topic_author];
            if(_channel.topic_time > 0) {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                
                _topicSetBy = [_topicSetBy stringByAppendingFormat:@" on %@", [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_channel.topic_time]]];
            }
        } else {
            _topicSetBy = nil;
        }
    } else {
        _topic = [ColorFormatter format:@"(No topic set)" defaultColor:[UIColor textareaTextColor] mono:NO linkify:NO server:nil links:nil];
        _topicLabel.attributedText = _topic;
        _topicEdit.text = @"";
        _topicSetBy = nil;
    }
    if(_channel.mode.length) {
        for(NSDictionary *mode in _channel.modes) {
            unichar m = [[mode objectForKey:@"mode"] characterAtIndex:0];
            switch(m) {
                case 'i':
                    [_modeHints addObject:@{@"mode":@"Invite Only (+i)", @"hint":@"Members must be invited to join this channel."}];
                    break;
                case 'k':
                    [_modeHints addObject:@{@"mode":@"Password (+k)", @"hint":[mode objectForKey:@"param"]}];
                    break;
                case 'm':
                    [_modeHints addObject:@{@"mode":@"Moderated (+m)", @"hint":@"Only ops and voiced members may talk."}];
                    break;
                case 'n':
                    [_modeHints addObject:@{@"mode":@"No External Messages (+n)", @"hint":@"No messages allowed from outside the channel."}];
                    break;
                case 'p':
                    [_modeHints addObject:@{@"mode":@"Private (+p)", @"hint":@"Membership is only visible to other members."}];
                    break;
                case 's':
                    [_modeHints addObject:@{@"mode":@"Secret (+s)", @"hint":@"This channel is unlisted and membership is only visible to other members."}];
                    break;
                case 't':
                    [_modeHints addObject:@{@"mode":@"Topic Control (+t)", @"hint":@"Only ops can set the topic."}];
                    User *u = [[UsersDataSource sharedInstance] getUser:server.nick cid:_channel.cid bid:_channel.bid];
                    if(u && [u.mode rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:server?[NSString stringWithFormat:@"%@%@%@%@%@",server.MODE_OPER, server.MODE_OWNER, server.MODE_ADMIN, server.MODE_OP, server.MODE_HALFOP]:@"Yqaoh"]].location == NSNotFound)
                        self.navigationItem.rightBarButtonItem = nil;
                    break;
            }
        }
    }
    if(_channel.bid == -1)
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
        topicHeader = [[UILabel alloc] initWithFrame:CGRectMake(16,24,self.view.frame.size.width - 32, 20)];
        topicHeader.font = [UIFont systemFontOfSize:14];
        topicHeader.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    }
    if(!modesHeader) {
        modesHeader = [[UILabel alloc] initWithFrame:CGRectMake(16,24,self.view.frame.size.width - 32, 20)];
        modesHeader.font = [UIFont systemFontOfSize:14];
        modesHeader.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    }
    
    switch (section) {
        case 0:
            [topicHeader removeFromSuperview];
            topicHeader.text = [self tableView:tableView titleForHeaderInSection:section];
            [header addSubview:topicHeader];
            break;
        case 1:
            [modesHeader removeFromSuperview];
            modesHeader.text = [self tableView:tableView titleForHeaderInSection:section];
            [header addSubview:modesHeader];
            break;
    }
    
    return header;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,24)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16,4,self.view.frame.size.width - 32, 20)];
    label.text = [self tableView:tableView titleForFooterInSection:section];
    label.font = [UIFont systemFontOfSize:12];
    label.textColor = [UILabel appearanceWhenContainedIn:[UITableViewHeaderFooterView class], nil].textColor;
    label.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [header addSubview:label];
    return header;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([_channel.mode isKindOfClass:[NSString class]] && _channel.mode.length)
        return 2;
    else
        return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 1:
            if(_modeHints.count)
                return _modeHints.count;
        default:
            return 1;
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    if(self.tableView.editing && !editing && _topicChanged) {
        [[NetworkConnection sharedInstance] topic:[ColorFormatter toIRC:_topicEdit.attributedText] chan:_channel.name cid:_channel.cid handler:nil];
    }
    [super setEditing:editing animated:animated];
    [self.tableView reloadData];
    if(editing) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_topicEdit becomeFirstResponder];
        }];
        _topicChanged = NO;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        if(tableView.isEditing)
            return 148;
        CGFloat height = [LinkTextView heightOfString:_topic constrainedToWidth:self.tableView.bounds.size.width - offset];
        _topicLabel.frame = CGRectMake(8,8,self.tableView.bounds.size.width - offset,height);
        _topicEdit.frame = CGRectMake(4,4,self.tableView.bounds.size.width - offset,140);
        return height + 20;
    } else {
        if(indexPath.row == 0 && _modeHints.count == 0) {
            return 48;
        } else {
            NSString *hint = [[_modeHints objectAtIndex:indexPath.row] objectForKey:@"hint"];
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
    switch(section) {
        case 0:
            if(tableView.isEditing && _topiclen) {
                return [NSString stringWithFormat:@"TOPIC (%li CHARS)", (_topiclen - [ColorFormatter toIRC:_topicEdit.attributedText].length)];
            } else {
                return @"TOPIC";
            }
        case 1:
            if(_modeHints.count)
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infocell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"infocell"];
    
    switch(indexPath.section) {
        case 0:
            if(tableView.isEditing) {
                [_topicLabel removeFromSuperview];
                [cell.contentView addSubview:_topicEdit];
            } else {
                [_topicEdit removeFromSuperview];
                [cell.contentView addSubview:_topicLabel];
            }
            break;
        case 1:
            if(_modeHints.count) {
                cell.textLabel.text = [[_modeHints objectAtIndex:indexPath.row] objectForKey:@"mode"];
                cell.detailTextLabel.text = [[_modeHints objectAtIndex:indexPath.row] objectForKey:@"hint"];
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
