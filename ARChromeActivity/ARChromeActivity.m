/*
  ARChromeActivity.m

  Copyright (c) 2012 Alex Robinson
 
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "ARChromeActivity.h"

@implementation ARChromeActivity {
    NSURL *_activityURL;
}
@synthesize activityTitle = _title;

static NSString *encodeByAddingPercentEscapes(NSString *input) {
    return [input stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[] "].invertedSet];
}

- (void)commonInit {
    _callbackSource = [[NSBundle mainBundle]objectForInfoDictionaryKey:@"CFBundleName"];
    _title = @"Open in Chrome";
}

- (NSString *)activityTitle
{
    return _title;
}

- (id)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCallbackURL:(NSURL *)callbackURL {
    self = [super init];
    if (self) {
        [self commonInit];
        _callbackURL = callbackURL;
    }
    return self;
}

- (UIImage *)activityImage {
    if ([[UIImage class] respondsToSelector:@selector(imageNamed:inBundle:compatibleWithTraitCollection:)]) {
        return [UIImage imageNamed:@"ARChromeActivity" inBundle:[NSBundle bundleForClass:self.class] compatibleWithTraitCollection:nil];
    } else {
        return [UIImage imageNamed:@"ARChromeActivity"];
    }
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome://"]]) {
        return NO;
    }
    if (_callbackURL && ![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlechrome-x-callback://"]]) {
        return NO;
    }
    for (id item in activityItems){
        if ([item isKindOfClass:NSURL.class]){
            NSURL *url = (NSURL *)item;
            if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:NSURL.class]) {
            NSURL *url = (NSURL *)item;
            if ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]) {
                _activityURL = (NSURL *)item;
                return;
            }
            
        }
    }
}

- (void)performActivity {
    
    BOOL success = NO;
    
    if (_activityURL != nil) {
        
        if (self.callbackURL && self.callbackSource) {
            NSString *openingURL = encodeByAddingPercentEscapes(_activityURL.absoluteString);
            NSString *callbackURL = encodeByAddingPercentEscapes(self.callbackURL.absoluteString);
            NSString *sourceName = encodeByAddingPercentEscapes(self.callbackSource);
            
            NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"googlechrome-x-callback://x-callback-url/open/?url=%@&x-success=%@&x-source=%@", openingURL, callbackURL, sourceName]];
            NSLog(@"AURL: %@", activityURL);
            [[UIApplication sharedApplication] openURL:activityURL];
            success = YES;
        } else {
            
            NSString *scheme = _activityURL.scheme;
            
            NSString *chromeScheme = nil;
            if ([scheme isEqualToString:@"http"]) {
                chromeScheme = @"googlechrome";
            } else if ([scheme isEqualToString:@"https"]) {
                chromeScheme = @"googlechromes";
            }
            
            if (chromeScheme) {
                NSString *absoluteString = [_activityURL absoluteString];
                NSRange rangeForScheme = [absoluteString rangeOfString:@":"];
                NSString *urlNoScheme = [absoluteString substringFromIndex:rangeForScheme.location];
                NSString *chromeURLString = [chromeScheme stringByAppendingString:urlNoScheme];
                NSURL *chromeURL = [NSURL URLWithString:chromeURLString];
                
                [[UIApplication sharedApplication] openURL:chromeURL];
                success = YES;
            }
        }
    }
    
    [self activityDidFinish:success];
}

@end
