//
//  TextTableViewController.h
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

#import "TextTableViewController.h"
#import "LinkLabel.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "AppDelegate.h"

@implementation TextTableViewController

- (id)initWithData:(NSArray *)data {
    self = [super init];
    if(self) {
        _data = data;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    }
    return self;
}

- (void)appendData:(NSArray *)data {
    _data = [_data arrayByAddingObjectsFromArray:data];
    [self refresh];
}

- (void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)refresh {
    NSMutableString *text = [[NSMutableString alloc] init];
    for(id item in _data) {
        NSString *s;
        if([item isKindOfClass:[NSString class]]) {
            s = item;
        } else if([item isKindOfClass:[NSArray class]]) {
            s = [(NSArray *)item componentsJoinedByString:@"\t"];
        } else {
            s = [item description];
        }
        [text appendFormat:@"%@\n", s];
    }
    
    NSArray *links;
    tv.attributedText = [ColorFormatter format:text defaultColor:[UIColor messageTextColor] mono:YES linkify:YES server:_server links:&links];
    tv.linkAttributes = [UIColor linkAttributes];
    
    for(NSTextCheckingResult *result in links) {
        if(result.resultType == NSTextCheckingTypeLink) {
            [tv addLinkWithTextCheckingResult:result];
        } else {
            NSString *url = [[tv.attributedText attributedSubstringFromRange:result.range] string];
            if(![url hasPrefix:@"irc"]) {
                CFStringRef url_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, NULL, (CFStringRef)@"&+/?=[]();:^", kCFStringEncodingUTF8);
                if(url_escaped != NULL) {
                    url = [NSString stringWithFormat:@"irc://%i/%@", _server.cid, url_escaped];
                    CFRelease(url_escaped);
                }
            }
            [tv addLinkToURL:[NSURL URLWithString:[url stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]] withRange:result.range];
        }
    }
    
    CGSize size = [tv.attributedText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
    if(size.width < self.view.bounds.size.width)
        size.width = self.view.bounds.size.width;
    tv.frame = CGRectMake(0,0,size.width,size.height);
    sv.contentSize = tv.bounds.size;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    tv = [[LinkLabel alloc] initWithFrame:CGRectZero];
    tv.backgroundColor = [UIColor contentBackgroundColor];
    tv.textColor = [UIColor messageTextColor];
    tv.numberOfLines = 0;
    
    sv = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    sv.backgroundColor = [UIColor contentBackgroundColor];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [sv addSubview:tv];
    
    [self.view addSubview:sv];
    
    [self refresh];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
