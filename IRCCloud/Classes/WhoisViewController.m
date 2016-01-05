//
//  WhoisViewController.m
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

#import "WhoisViewController.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"

@implementation WhoisViewController

-(id)initWithJSONObject:(IRCCloudJSONObject*)object {
    self = [super init];
    if (self) {
        self.navigationItem.title = [object objectForKey:@"nick"];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = [UIColor contentBackgroundColor];
        _label = [[TTTAttributedLabel alloc] init];
        _label.delegate = self;
        _label.numberOfLines = 0;
        _label.lineBreakMode = NSLineBreakByWordWrapping;
        CGFloat lineSpacing = 6;
        CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
        CTParagraphStyleSetting paragraphStyles[2] = {
            {.spec = kCTParagraphStyleSpecifierLineSpacing, .valueSize = sizeof(CGFloat), .value = &lineSpacing},
            {.spec = kCTParagraphStyleSpecifierLineBreakMode, .valueSize = sizeof(CTLineBreakMode), .value = (const void *)&lineBreakMode}
        };
        CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(paragraphStyles, 2);
        
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setObject:(id)[[UIColor linkColor] CGColor] forKey:(NSString*)kCTForegroundColorAttributeName];
        [mutableLinkAttributes setObject:(__bridge id)paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        _label.linkAttributes = [NSDictionary dictionaryWithDictionary:mutableLinkAttributes];
        
        CFRelease(paragraphStyle);
        
        Server *s = [[ServersDataSource sharedInstance] getServer:[[object objectForKey:@"cid"] intValue]];

        NSArray *matches;
        NSMutableArray *links = [[NSMutableArray alloc] init];
        NSMutableAttributedString *data = [[NSMutableAttributedString alloc] init];
        
        NSString *actualHost = @"";
        if([object objectForKey:@"actual_host"])
            actualHost = [NSString stringWithFormat:@"/%@", [object objectForKey:@"actual_host"]];
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@%c (%@%c@%@%@%c)", [object objectForKey:@"user_realname"], CLEAR,[object objectForKey:@"user_username"], CLEAR, [object objectForKey:@"user_host"], actualHost, CLEAR] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        
        if([[object objectForKey:@"user_logged_in_as"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" is authed as %@", [object objectForKey:@"user_logged_in_as"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        [data appendAttributedString:[ColorFormatter format:@"\n" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];

        if([object objectForKey:@"away"]) {
            NSString *away = @"Away";
            if(![[object objectForKey:@"away"] isEqualToString:@"away"])
                away = [away stringByAppendingFormat:@": %@", [object objectForKey:@"away"]];

            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@\n", away] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"signon_time"] intValue]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"Online for about %@", [self duration:([[NSDate date] timeIntervalSince1970] - [[object objectForKey:@"signon_time"] doubleValue])]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];

            if([[object objectForKey:@"idle_secs"] intValue]) {
                [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" (idle for %@)", [self duration:[[object objectForKey:@"idle_secs"] intValue]]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
            }
            
            [data appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
        }
        
        if([[object objectForKey:@"op_nick"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"op_nick"], [object objectForKey:@"op_msg"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"opername"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"opername"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"userip"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"userip"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"bot_msg"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"bot_msg"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ is connected via: %@", [object objectForKey:@"nick"], [object objectForKey:@"server_addr"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];

        if([[object objectForKey:@"server_extra"] length]) {
            [data appendAttributedString:[ColorFormatter format:@" (" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
            NSUInteger offset = data.length;
            [data appendAttributedString:[ColorFormatter format:[object objectForKey:@"server_extra"] defaultColor:[UIColor messageTextColor] mono:NO linkify:YES server:s links:&matches]];
            [data appendAttributedString:[ColorFormatter format:@")" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
            for(NSTextCheckingResult *result in matches) {
                NSURL *u;
                if(result.resultType == NSTextCheckingTypeLink) {
                    u = result.URL;
                } else {
                    NSString *url = [[data attributedSubstringFromRange:NSMakeRange(result.range.location+offset, result.range.length)] string];
                    if(![url hasPrefix:@"irc"])
                        url = [[NSString stringWithFormat:@"irc%@://%@:%i/%@", (s.ssl==1)?@"s":@"", s.hostname, s.port, url] stringByReplacingOccurrencesOfString:@"#" withString:@"%23"];
                    u = [NSURL URLWithString:url];
                    
                }
                [links addObject:[NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(result.range.location+offset, result.range.length) URL:u]];
            }
        }
        
        [data appendAttributedString:[ColorFormatter format:@"\n" defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];

        if([[object objectForKey:@"host"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"host"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        [self addChannels:[object objectForKey:@"channels_oper"] forGroup:@"Oper" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_owner"] forGroup:@"Owner" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_admin"] forGroup:@"Admin" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_op"] forGroup:@"Operator" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_halfop"] forGroup:@"Half-Operator" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_voiced"] forGroup:@"Voiced" attributedString:data links:links server:s];
        [self addChannels:[object objectForKey:@"channels_member"] forGroup:@"Member" attributedString:data links:links server:s];
        
        if([[object objectForKey:@"secure"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"secure"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"client_cert"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"client_cert"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"cgi"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"cgi"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"help"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"help"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"vworld"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"vworld"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"modes"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"modes"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        
        if([[object objectForKey:@"stats_dline"] length]) {
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ %@\n", [object objectForKey:@"nick"], [object objectForKey:@"stats_dline"]] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:s links:nil]];
        }
        

        _label.attributedText = data;
        for(NSTextCheckingResult *result in links)
            [_label addLinkWithTextCheckingResult:result];
        [_scrollView addSubview:_label];
    }
    return self;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(void)addChannels:(NSArray *)channels forGroup:(NSString *)group attributedString:(NSMutableAttributedString *)data links:(NSMutableArray *)links server:(Server *)s {
    NSArray *matches;
    if(channels.count) {
        [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@"%@ of:\n", group] defaultColor:[UIColor messageTextColor] mono:NO linkify:NO server:nil links:nil]];
        for(NSString *channel in channels) {
            NSUInteger offset = data.length;
            [data appendAttributedString:[ColorFormatter format:[NSString stringWithFormat:@" • %@\n", channel] defaultColor:[UIColor messageTextColor] mono:NO linkify:YES server:s links:&matches]];
            for(NSTextCheckingResult *result in matches) {
                NSURL *u;
                if(result.resultType == NSTextCheckingTypeLink) {
                    u = result.URL;
                } else {
                    NSString *url = [[data attributedSubstringFromRange:NSMakeRange(result.range.location+offset, result.range.length)] string];
                    if(![url hasPrefix:@"irc"]) {
                        CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                        if(url_escaped != NULL) {
                            url = [NSString stringWithFormat:@"irc://%i/%@", s.cid, url_escaped];
                            CFRelease(url_escaped);
                        }
                    }
                    u = [NSURL URLWithString:url];

                }
                [links addObject:[NSTextCheckingResult linkCheckingResultWithRange:NSMakeRange(result.range.location+offset, result.range.length) URL:u]];
            }
        }
    }
}

-(NSString *)duration:(int)seconds {
    int minutes = seconds / 60;
    int hours = minutes / 60;
    int days = hours / 24;
    if(days) {
        if(days == 1)
            return [NSString stringWithFormat:@"%i day", days];
        else
            return [NSString stringWithFormat:@"%i days", days];
    } else if(hours) {
        if(hours == 1)
            return [NSString stringWithFormat:@"%i hour", hours];
        else
            return [NSString stringWithFormat:@"%i hours", hours];
    } else if(minutes) {
        if(minutes == 1)
            return [NSString stringWithFormat:@"%i minute", minutes];
        else
            return [NSString stringWithFormat:@"%i minutes", minutes];
    } else {
        if(seconds == 1)
            return [NSString stringWithFormat:@"%i second", seconds];
        else
            return [NSString stringWithFormat:@"%i seconds", seconds];
    }
}

-(void)loadView {
    [super loadView];
    self.navigationController.navigationBar.clipsToBounds = YES;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(_label.attributedText));
    if(framesetter) {
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0,0), NULL, CGSizeMake(self.view.bounds.size.width - 24,CGFLOAT_MAX), NULL);
        _label.frame = CGRectMake(12,2,self.view.bounds.size.width-24, suggestedSize.height+12);
        CFRelease(framesetter);
    }
    _scrollView.frame = self.view.frame;
    _scrollView.contentSize = _label.frame.size;
    self.view = _scrollView;
}

-(void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [(AppDelegate *)([UIApplication sharedApplication].delegate) launchURL:url];
    if([url.scheme hasPrefix:@"irc"])
        [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
