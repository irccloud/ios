//
//  DisplayOptionsViewController.m
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


#import "DisplayOptionsViewController.h"
#import "NetworkConnection.h"
#import "UIColor+IRCCloud.h"

@implementation DisplayOptionsViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithDictionary:[[NetworkConnection sharedInstance] prefs]];
    NSMutableDictionary *disableTrackUnread = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *enableTrackUnread = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *notifyAll = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *disableNotifyAll = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *hideJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *expandJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *collapseJoinPart = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *expandDisco = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *enableReadOnSelect = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *disableReadOnSelect = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *disableInlineFiles = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *inlineImages = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *disableInlineImages = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *hiddenMembers = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *replyCollapse = [[NSMutableDictionary alloc] init];

    if([self->_buffer.type isEqualToString:@"channel"]) {
        NSMutableDictionary *disableNickSuggestions = [[[NSUserDefaults standardUserDefaults] objectForKey:@"disable-nick-suggestions"] mutableCopy];
        if(!disableNickSuggestions)
            disableNickSuggestions = [[NSMutableDictionary alloc] init];
        
        [disableNickSuggestions setObject:@(!_disableNickSuggestions.on) forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        [[NSUserDefaults standardUserDefaults] setObject:disableNickSuggestions forKey:@"disable-nick-suggestions"];
        
        if([[prefs objectForKey:@"channel-enableReadOnSelect"] isKindOfClass:[NSDictionary class]])
            [enableReadOnSelect addEntriesFromDictionary:[prefs objectForKey:@"channel-enableReadOnSelect"]];
        if([[prefs objectForKey:@"channel-disableReadOnSelect"] isKindOfClass:[NSDictionary class]])
            [disableReadOnSelect addEntriesFromDictionary:[prefs objectForKey:@"channel-disableReadOnSelect"]];
        if([[prefs objectForKey:@"enableReadOnSelect"] intValue] == 1) {
            if(self->_readOnSelect.on)
                [disableReadOnSelect removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableReadOnSelect setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableReadOnSelect.count)
                [prefs setObject:enableReadOnSelect forKey:@"channel-disableReadOnSelect"];
            else
                [prefs removeObjectForKey:@"channel-disableReadOnSelect"];
        } else {
            if(!_readOnSelect.on)
                [enableReadOnSelect removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [enableReadOnSelect setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(enableReadOnSelect.count)
                [prefs setObject:enableReadOnSelect forKey:@"channel-enableReadOnSelect"];
            else
                [prefs removeObjectForKey:@"channel-enableReadOnSelect"];
        }
        
        if([[prefs objectForKey:@"channel-disableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [disableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"channel-disableTrackUnread"]];
        if([[prefs objectForKey:@"channel-enableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [enableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"channel-enableTrackUnread"]];
        if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
            if(!_trackUnread.on)
                [enableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [enableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(enableTrackUnread.count)
                [prefs setObject:enableTrackUnread forKey:@"channel-enableTrackUnread"];
            else
                [prefs removeObjectForKey:@"channel-enableTrackUnread"];
        } else {
            if(self->_trackUnread.on)
                [disableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableTrackUnread.count)
                [prefs setObject:disableTrackUnread forKey:@"channel-disableTrackUnread"];
            else
                [prefs removeObjectForKey:@"channel-disableTrackUnread"];
        }

        if([[prefs objectForKey:@"channel-notifications-all"] isKindOfClass:[NSDictionary class]])
            [notifyAll addEntriesFromDictionary:[prefs objectForKey:@"channel-notifications-all"]];
        if([[prefs objectForKey:@"channel-notifications-all-disable"] isKindOfClass:[NSDictionary class]])
            [disableNotifyAll addEntriesFromDictionary:[prefs objectForKey:@"channel-notifications-all-disable"]];
        if([[prefs objectForKey:@"notifications-all"] intValue] == 1) {
            if(!_notifyAll.on)
                [disableNotifyAll setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableNotifyAll removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableNotifyAll.count)
                [prefs setObject:disableNotifyAll forKey:@"channel-notifications-all-disable"];
            else
                [prefs removeObjectForKey:@"channel-notifications-all-disable"];
        } else {
            if(self->_notifyAll.on)
                [notifyAll setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [notifyAll removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(notifyAll.count)
                [prefs setObject:notifyAll forKey:@"channel-notifications-all"];
            else
                [prefs removeObjectForKey:@"channel-notifications-all"];
        }
        
        if([[prefs objectForKey:@"channel-hideJoinPart"] isKindOfClass:[NSDictionary class]])
            [hideJoinPart addEntriesFromDictionary:[prefs objectForKey:@"channel-hideJoinPart"]];
        if(self->_showJoinPart.on)
            [hideJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [hideJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(hideJoinPart.count)
            [prefs setObject:hideJoinPart forKey:@"channel-hideJoinPart"];
        else
            [prefs removeObjectForKey:@"channel-hideJoinPart"];

        if([[prefs objectForKey:@"channel-expandJoinPart"] isKindOfClass:[NSDictionary class]])
            [expandJoinPart addEntriesFromDictionary:[prefs objectForKey:@"channel-expandJoinPart"]];
        if(self->_collapseJoinPart.on)
            [expandJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [expandJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(expandJoinPart.count)
            [prefs setObject:expandJoinPart forKey:@"channel-expandJoinPart"];
        else
            [prefs removeObjectForKey:@"channel-expandJoinPart"];
        
        if([[prefs objectForKey:@"channel-collapseJoinPart"] isKindOfClass:[NSDictionary class]])
            [collapseJoinPart addEntriesFromDictionary:[prefs objectForKey:@"channel-collapseJoinPart"]];
        if(!_collapseJoinPart.on)
            [collapseJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [collapseJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(collapseJoinPart.count)
            [prefs setObject:collapseJoinPart forKey:@"channel-collapseJoinPart"];
        else
            [prefs removeObjectForKey:@"channel-collapseJoinPart"];
        
        if([[prefs objectForKey:@"channel-hiddenMembers"] isKindOfClass:[NSDictionary class]])
            [hiddenMembers addEntriesFromDictionary:[prefs objectForKey:@"channel-hiddenMembers"]];
        if(self->_showMembers.on)
            [hiddenMembers removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [hiddenMembers setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(hiddenMembers.count)
            [prefs setObject:hiddenMembers forKey:@"channel-hiddenMembers"];
        else
            [prefs removeObjectForKey:@"channel-hiddenMembers"];
        
        if([[prefs objectForKey:@"channel-files-disableinline"] isKindOfClass:[NSDictionary class]])
            [disableInlineFiles addEntriesFromDictionary:[prefs objectForKey:@"channel-files-disableinline"]];
        if(self->_disableInlineFiles.on)
            [disableInlineFiles removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [disableInlineFiles setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(disableInlineFiles.count)
            [prefs setObject:disableInlineFiles forKey:@"channel-files-disableinline"];
        else
            [prefs removeObjectForKey:@"channel-files-disableinline"];

        if([[prefs objectForKey:@"channel-inlineimages"] isKindOfClass:[NSDictionary class]])
            [inlineImages addEntriesFromDictionary:[prefs objectForKey:@"channel-inlineimages"]];
        if(self->_inlineImages.on)
            [inlineImages setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [inlineImages removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(inlineImages.count)
            [prefs setObject:inlineImages forKey:@"channel-inlineimages"];
        else
            [prefs removeObjectForKey:@"channel-inlineimages"];

        if([[prefs objectForKey:@"channel-inlineimages-disable"] isKindOfClass:[NSDictionary class]])
            [disableInlineImages addEntriesFromDictionary:[prefs objectForKey:@"channel-inlineimages-disable"]];
        if(self->_inlineImages.on)
            [disableInlineImages removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [disableInlineImages setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(disableInlineImages.count)
            [prefs setObject:disableInlineImages forKey:@"channel-inlineimages-disable"];
        else
            [prefs removeObjectForKey:@"channel-inlineimages-disable"];
        
        if([[prefs objectForKey:@"channel-reply-collapse"] isKindOfClass:[NSDictionary class]])
            [replyCollapse addEntriesFromDictionary:[prefs objectForKey:@"channel-reply-collapse"]];
        if(self->_replyCollapse.on)
            [replyCollapse setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        else
            [replyCollapse removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
        if(replyCollapse.count)
            [prefs setObject:replyCollapse forKey:@"channel-reply-collapse"];
        else
            [prefs removeObjectForKey:@"channel-reply-collapse"];
} else {
        if([[prefs objectForKey:@"buffer-disableReadOnSelect"] isKindOfClass:[NSDictionary class]])
            [disableReadOnSelect addEntriesFromDictionary:[prefs objectForKey:@"buffer-disableReadOnSelect"]];
        if([[prefs objectForKey:@"enableReadOnSelect"] intValue] == 1) {
            if(self->_readOnSelect.on)
                [disableReadOnSelect removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableReadOnSelect setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableReadOnSelect.count)
                [prefs setObject:enableReadOnSelect forKey:@"buffer-disableReadOnSelect"];
            else
                [prefs removeObjectForKey:@"buffer-disableReadOnSelect"];
        } else {
            if(!_readOnSelect.on)
                [enableReadOnSelect removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [enableReadOnSelect setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(enableReadOnSelect.count)
                [prefs setObject:enableReadOnSelect forKey:@"buffer-enableReadOnSelect"];
            else
                [prefs removeObjectForKey:@"buffer-enableReadOnSelect"];
        }
        
        if([[prefs objectForKey:@"buffer-disableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [disableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"buffer-disableTrackUnread"]];
        if([[prefs objectForKey:@"buffer-enableTrackUnread"] isKindOfClass:[NSDictionary class]])
            [enableTrackUnread addEntriesFromDictionary:[prefs objectForKey:@"buffer-enableTrackUnread"]];
        if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
            if(!_trackUnread.on)
                [enableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [enableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(enableTrackUnread.count)
                [prefs setObject:enableTrackUnread forKey:@"buffer-enableTrackUnread"];
            else
                [prefs removeObjectForKey:@"buffer-enableTrackUnread"];
        } else {
            if(self->_trackUnread.on)
                [disableTrackUnread removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableTrackUnread setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableTrackUnread.count)
                [prefs setObject:disableTrackUnread forKey:@"buffer-disableTrackUnread"];
            else
                [prefs removeObjectForKey:@"buffer-disableTrackUnread"];
        }
        
        if([self->_buffer.type isEqualToString:@"conversation"]) {
            if([[prefs objectForKey:@"buffer-hideJoinPart"] isKindOfClass:[NSDictionary class]])
                [hideJoinPart addEntriesFromDictionary:[prefs objectForKey:@"buffer-hideJoinPart"]];
            if(self->_showJoinPart.on)
                [hideJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [hideJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(hideJoinPart.count)
                [prefs setObject:hideJoinPart forKey:@"buffer-hideJoinPart"];
            else
                [prefs removeObjectForKey:@"buffer-hideJoinPart"];

            if([[prefs objectForKey:@"buffer-expandJoinPart"] isKindOfClass:[NSDictionary class]])
                [expandJoinPart addEntriesFromDictionary:[prefs objectForKey:@"buffer-expandJoinPart"]];
            if(self->_collapseJoinPart.on)
                [expandJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [expandJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(expandJoinPart.count)
                [prefs setObject:expandJoinPart forKey:@"buffer-expandJoinPart"];
            else
                [prefs removeObjectForKey:@"buffer-expandJoinPart"];
            
            if([[prefs objectForKey:@"buffer-collapseJoinPart"] isKindOfClass:[NSDictionary class]])
                [collapseJoinPart addEntriesFromDictionary:[prefs objectForKey:@"buffer-collapseJoinPart"]];
            if(!_collapseJoinPart.on)
                [collapseJoinPart removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [collapseJoinPart setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(collapseJoinPart.count)
                [prefs setObject:expandJoinPart forKey:@"buffer-collapseJoinPart"];
            else
                [prefs removeObjectForKey:@"buffer-collapseJoinPart"];

            if([[prefs objectForKey:@"buffer-files-disableinline"] isKindOfClass:[NSDictionary class]])
                [disableInlineFiles addEntriesFromDictionary:[prefs objectForKey:@"buffer-files-disableinline"]];
            if(self->_disableInlineFiles.on)
                [disableInlineFiles removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [disableInlineFiles setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(disableInlineFiles.count)
                [prefs setObject:disableInlineFiles forKey:@"buffer-files-disableinline"];
            else
                [prefs removeObjectForKey:@"buffer-files-disableinline"];
            
            if([[prefs objectForKey:@"buffer-reply-collapse"] isKindOfClass:[NSDictionary class]])
                [replyCollapse addEntriesFromDictionary:[prefs objectForKey:@"buffer-reply-collapse"]];
            if(self->_replyCollapse.on)
                [replyCollapse setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [replyCollapse removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(replyCollapse.count)
                [prefs setObject:replyCollapse forKey:@"buffer-reply-collapse"];
            else
                [prefs removeObjectForKey:@"buffer-reply-collapse"];
        }
        
        if([self->_buffer.type isEqualToString:@"console"]) {
            if([[prefs objectForKey:@"buffer-expandDisco"] isKindOfClass:[NSDictionary class]])
                [expandDisco addEntriesFromDictionary:[prefs objectForKey:@"buffer-expandDisco"]];
            if(self->_expandDisco.on)
                [expandDisco removeObjectForKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            else
                [expandDisco setObject:@YES forKey:[NSString stringWithFormat:@"%i", _buffer.bid]];
            if(expandDisco.count)
                [prefs setObject:expandDisco forKey:@"buffer-expandDisco"];
            else
                [prefs removeObjectForKey:@"buffer-expandDisco"];
        }
    }
    
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *json = [writer stringWithObject:prefs];
    
    [[NetworkConnection sharedInstance] setPrefs:json handler:^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] boolValue]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save settings, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        }
    }];
}

-(void)cancelButtonPressed:(id)sender {
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
    
    switch(event) {
        case kIRCEventUserInfo:
            [self refresh];
            break;
        default:
            break;
    }
}

-(void)refresh {
    NSDictionary *prefs = [[NetworkConnection sharedInstance] prefs];
    
    if([self->_buffer.type isEqualToString:@"channel"]) {
        if([[prefs objectForKey:@"enableReadOnSelect"] intValue] == 1) {
            if([[[prefs objectForKey:@"channel-disableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_readOnSelect.on = NO;
            else
                self->_readOnSelect.on = YES;
        } else {
            if([[[prefs objectForKey:@"channel-enableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_readOnSelect.on = YES;
            else
                self->_readOnSelect.on = NO;
        }
        
        if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
            if([[[prefs objectForKey:@"channel-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_trackUnread.on = YES;
            else
                self->_trackUnread.on = NO;
        } else {
            if([[[prefs objectForKey:@"channel-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_trackUnread.on = NO;
            else
                self->_trackUnread.on = YES;
        }
        
        if([[prefs objectForKey:@"notifications-all"] intValue] == 1) {
            if([[[prefs objectForKey:@"channel-notifications-all-disable"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_notifyAll.on = NO;
            else
                self->_notifyAll.on = YES;
        } else {
            if([[[prefs objectForKey:@"channel-notifications-all"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_notifyAll.on = YES;
            else
                self->_notifyAll.on = NO;
        }
        
        if([[[prefs objectForKey:@"channel-hideJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_showJoinPart.on = NO;
        else
            self->_showJoinPart.on = YES;

        if([[prefs objectForKey:@"expandJoinPart"] intValue]) {
            if([[[prefs objectForKey:@"channel-collapseJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_collapseJoinPart.on = YES;
            else
                self->_collapseJoinPart.on = NO;
        } else {
            if([[[prefs objectForKey:@"channel-expandJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_collapseJoinPart.on = NO;
            else
                self->_collapseJoinPart.on = YES;
        }
        if([[[prefs objectForKey:@"channel-hiddenMembers"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_showMembers.on = NO;
        else
            self->_showMembers.on = YES;
        
        if([[[prefs objectForKey:@"channel-files-disableinline"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_disableInlineFiles.on = NO;
        else
            self->_disableInlineFiles.on = YES;
        
        self->_inlineImages.on = [[prefs objectForKey:@"inlineimages"] boolValue];
        if(self->_inlineImages.on) {
            NSDictionary *disableMap = [prefs objectForKey:@"channel-inlineimages-disable"];
            
            if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                self->_inlineImages.on = NO;
        } else {
            NSDictionary *enableMap = [prefs objectForKey:@"channel-inlineimages"];
            
            if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                self->_inlineImages.on = YES;
        }
        
        if([[[prefs objectForKey:@"channel-reply-collapse"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_replyCollapse.on = YES;
        else
            self->_replyCollapse.on = NO;
    } else {
        if([[prefs objectForKey:@"enableReadOnSelect"] intValue] == 1) {
            if([[[prefs objectForKey:@"buffer-disableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_readOnSelect.on = NO;
            else
                self->_readOnSelect.on = YES;
        } else {
            if([[[prefs objectForKey:@"buffer-enableReadOnSelect"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_readOnSelect.on = YES;
            else
                self->_readOnSelect.on = NO;
        }
        
        if([[prefs objectForKey:@"disableTrackUnread"] intValue] == 1) {
            if([[[prefs objectForKey:@"buffer-enableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_trackUnread.on = YES;
            else
                self->_trackUnread.on = NO;
        } else {
            if([[[prefs objectForKey:@"buffer-disableTrackUnread"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_trackUnread.on = NO;
            else
                self->_trackUnread.on = YES;
        }
        
        if([[[prefs objectForKey:@"buffer-hideJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_showJoinPart.on = NO;
        else
            self->_showJoinPart.on = YES;

        if([[prefs objectForKey:@"expandJoinPart"] intValue]) {
            if([[[prefs objectForKey:@"buffer-collapseJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_collapseJoinPart.on = YES;
            else
                self->_collapseJoinPart.on = NO;
        } else {
            if([[[prefs objectForKey:@"buffer-expandJoinPart"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
                self->_collapseJoinPart.on = NO;
            else
                self->_collapseJoinPart.on = YES;
        }

        if([[[prefs objectForKey:@"buffer-expandDisco"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_expandDisco.on = NO;
        else
            self->_expandDisco.on = YES;
        
        if([[[prefs objectForKey:@"buffer-files-disableinline"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_disableInlineFiles.on = NO;
        else
            self->_disableInlineFiles.on = YES;
        
        self->_inlineImages.on = [[prefs objectForKey:@"inlineimages"] boolValue];
        if(self->_inlineImages.on) {
            NSDictionary *disableMap = [prefs objectForKey:@"buffer-inlineimages-disable"];
            
            if(disableMap && [[disableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                self->_inlineImages.on = NO;
        } else {
            NSDictionary *enableMap = [prefs objectForKey:@"buffer-inlineimages"];
            
            if(enableMap && [[enableMap objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] boolValue])
                self->_inlineImages.on = YES;
        }

        if([[[prefs objectForKey:@"buffer-reply-collapse"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue] == 1)
            self->_replyCollapse.on = YES;
        else
            self->_replyCollapse.on = NO;
    }
    self->_collapseJoinPart.enabled = self->_showJoinPart.on;
    self->_disableNickSuggestions.on = !([[[[NSUserDefaults standardUserDefaults] objectForKey:@"disable-nick-suggestions"] objectForKey:[NSString stringWithFormat:@"%i",_buffer.bid]] intValue]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
        
    self->_showMembers = [[UISwitch alloc] init];
    self->_notifyAll = [[UISwitch alloc] init];
    self->_trackUnread = [[UISwitch alloc] init];
    self->_showJoinPart = [[UISwitch alloc] init];
    [self->_showJoinPart addTarget:self action:@selector(showJoinPartToggled:) forControlEvents:UIControlEventValueChanged];
    self->_collapseJoinPart = [[UISwitch alloc] init];
    self->_expandDisco = [[UISwitch alloc] init];
    self->_readOnSelect = [[UISwitch alloc] init];
    self->_disableInlineFiles = [[UISwitch alloc] init];
    self->_disableNickSuggestions = [[UISwitch alloc] init];
    self->_replyCollapse = [[UISwitch alloc] init];
    self->_inlineImages = [[UISwitch alloc] init];
    [self->_inlineImages addTarget:self action:@selector(thirdPartyNotificationPreviewsToggled:) forControlEvents:UIControlEventValueChanged];

    [self refresh];
}

-(void)thirdPartyNotificationPreviewsToggled:(UISwitch *)sender {
    if(sender.on) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Warning" message:@"External URLs may load insecurely and could result in your IP address being revealed to external site operators" preferredStyle:UIAlertControllerStyleAlert];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            sender.on = NO;
        }]];
        
        [ac addAction:[UIAlertAction actionWithTitle:@"Enable" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:ac animated:YES completion:nil];
    }
}

-(void)showJoinPartToggled:(id)sender {
    self->_collapseJoinPart.enabled = self->_showJoinPart.on;
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self->_buffer.type isEqualToString:@"channel"])
        return ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)?9:10;
    else if([self->_buffer.type isEqualToString:@"console"])
        return 3;
    else
        return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingscell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingscell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    
    if(![self->_buffer.type isEqualToString:@"channel"] && row > 1)
        row+=3;
    else if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && row > 1)
        row++;
    
    switch(row) {
        case 0:
            cell.textLabel.text = @"Unread message indicator";
            cell.accessoryView = self->_trackUnread;
            break;
        case 1:
            cell.textLabel.text = @"Mark as read automatically";
            cell.accessoryView = self->_readOnSelect;
            break;
        case 2:
            cell.textLabel.text = @"Member list";
            cell.accessoryView = self->_showMembers;
            break;
        case 3:
            cell.textLabel.text = @"Notify on all messages";
            cell.accessoryView = self->_notifyAll;
            break;
        case 4:
            cell.textLabel.text = @"Suggest nicks as you type";
            cell.accessoryView = self->_disableNickSuggestions;
            break;
        case 5:
            if([self->_buffer.type isEqualToString:@"console"]) {
                cell.textLabel.text = @"Group repeated disconnects";
                cell.accessoryView = self->_expandDisco;
            } else {
                cell.textLabel.text = @"Show joins/parts";
                cell.accessoryView = self->_showJoinPart;
            }
            break;
        case 6:
            cell.textLabel.text = @"Collapse joins/parts";
            cell.accessoryView = self->_collapseJoinPart;
            break;
        case 7:
            cell.textLabel.text = @"Collapse reply threads";
            cell.accessoryView = self->_replyCollapse;
            break;
        case 8:
            cell.textLabel.text = @"Embed uploaded files";
            cell.accessoryView = self->_disableInlineFiles;
            break;
        case 9:
            cell.textLabel.text = @"Embed external media";
            cell.accessoryView = self->_inlineImages;
            break;
    }
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
}

@end
