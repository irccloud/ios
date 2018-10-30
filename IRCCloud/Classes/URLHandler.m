//
//  URLHandler.m
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

#import <objc/message.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SafariServices/SafariServices.h>
#import "URLHandler.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "ImageViewController.h"
#ifndef EXTENSION
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#endif
#import "PastebinViewController.h"
#import "UIColor+IRCCloud.h"
#import "config.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"

#ifndef EXTENSION
@interface OpenInFirefoxActivity : UIActivity

@end

@implementation OpenInFirefoxActivity {
    NSURL *_URL;
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return @"Open in Firefox";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"Firefox"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    if([[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        for (id activityItem in activityItems) {
            if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            _URL = activityItem;
        }
    }
}

- (void)performActivity {
    BOOL completed = [[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:_URL];
    
    [self activityDidFinish:completed];
}

@end
#endif

@implementation URLHandler

#define HAS_IMAGE_SUFFIX(l) ([l hasSuffix:@"jpg"] || [l hasSuffix:@"jpeg"] || [l hasSuffix:@"png"] || [l hasSuffix:@"gif"] || [l hasSuffix:@"bmp"] || [l hasSuffix:@"webp"])

#define IS_IMGUR(url) (([[url.host lowercaseString] isEqualToString:@"imgur.com"] || [[url.host lowercaseString] isEqualToString:@"m.imgur.com"]) || ([[url.host lowercaseString] isEqualToString:@"i.imgur.com"] && url.path.length > 1 && ([url.path hasSuffix:@".gifv"] || [url.path hasSuffix:@".webm"] || [url.path hasSuffix:@".mp4"])))

#define IS_FLICKR(url) ([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [[url.path lowercaseString] hasPrefix:@"/photos/"])

#define IS_INSTAGRAM(url) (([[url.host lowercaseString] hasSuffix:@"instagram.com"] || \
                            [[url.host lowercaseString] hasSuffix:@"instagr.am"]) \
                           && [[url.path lowercaseString] hasPrefix:@"/p/"])

#define IS_DROPLR(url) (([[url.host lowercaseString] isEqualToString:@"droplr.com"] || \
                         [[url.host lowercaseString] isEqualToString:@"d.pr"]) \
                         && [[url.path lowercaseString] hasPrefix:@"/i/"])

#define IS_CLOUDAPP(url) ([url.host.lowercaseString isEqualToString:@"cl.ly"] \
                          && url.path.length \
                          && ![url.path.lowercaseString isEqualToString:@"/robots.txt"] \
                          && ![url.path.lowercaseString isEqualToString:@"/image"])

#define IS_STEAM(url) (([url.host.lowercaseString hasSuffix:@".steampowered.com"] || [url.host.lowercaseString hasSuffix:@".steamusercontent.com"]) && [url.path.lowercaseString hasPrefix:@"/ugc/"])

#define IS_LEET(url) (([url.host.lowercaseString hasSuffix:@"leetfiles.com"] || [url.host.lowercaseString hasSuffix:@"leetfil.es"]) \
                        && [url.path.lowercaseString hasPrefix:@"/image"])

#define IS_GIPHY(url) ((([url.host.lowercaseString isEqualToString:@"giphy.com"] || [url.host.lowercaseString isEqualToString:@"www.giphy.com"]) && [url.path.lowercaseString hasPrefix:@"/gifs/"]) || [url.host.lowercaseString isEqualToString:@"gph.is"])

#define IS_YOUTUBE(url) ((([url.host.lowercaseString isEqualToString:@"youtube.com"] || [url.host.lowercaseString hasSuffix:@".youtube.com"]) && [url.path.lowercaseString hasPrefix:@"/watch"]) || [url.host.lowercaseString isEqualToString:@"youtu.be"])

#define IS_WIKI(url) ([url.path.lowercaseString hasPrefix:@"/wiki/"] && HAS_IMAGE_SUFFIX(url.absoluteString.lowercaseString))

#define IS_TWIMG(url) ([url.host.lowercaseString hasSuffix:@".twimg.com"] && [url.path.lowercaseString hasPrefix:@"/media/"] && [url.path rangeOfString:@":"].location != NSNotFound && HAS_IMAGE_SUFFIX([url.path substringToIndex:[url.path rangeOfString:@":"].location].lowercaseString))

#define IS_XKCD(url) (([[url.host lowercaseString] hasSuffix:@".xkcd.com"] || [[url.host lowercaseString] isEqualToString:@"xkcd.com"]) && [url.path rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789/"] invertedSet]].location == NSNotFound)


-(instancetype)init {
    self = [super init];
    
    if(self) {
        _tasks = [[NSMutableDictionary alloc] init];
        _mediaURLs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

-(NSDictionary *)MediaURLs:(NSURL *)original_url {
    NSURL *url = original_url;
    if([_mediaURLs objectForKey:url])
        return [_mediaURLs objectForKey:url];
    
    if([[url.host lowercaseString] isEqualToString:@"www.dropbox.com"]) {
        if([url.path hasPrefix:@"/s/"])
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://dl.dropboxusercontent.com%@", [url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?dl=1", url.absoluteString]];
    } else if(([[url.host lowercaseString] isEqualToString:@"d.pr"] || [[url.host lowercaseString] isEqualToString:@"droplr.com"]) && [url.path hasPrefix:@"/i/"] && ![url.path hasSuffix:@"+"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://droplr.com%@+", [url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    } else if([[url.host lowercaseString] isEqualToString:@"imgur.com"] || [[url.host lowercaseString] isEqualToString:@"m.imgur.com"]) {
        return nil;
    } else if([[url.host lowercaseString] isEqualToString:@"i.imgur.com"]) {
        return nil;
    } else if(([[url.host lowercaseString] hasSuffix:@"giphy.com"] || [[url.host lowercaseString] isEqualToString:@"gph.is"]) && url.pathExtension.length == 0) {
        return nil;
    } else if([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [url.host rangeOfString:@"static"].location == NSNotFound) {
        return nil;
    /*} else if(([[url.host lowercaseString] hasSuffix:@"instagram.com"] || [[url.host lowercaseString] hasSuffix:@"instagr.am"]) && [url.path hasPrefix:@"/p/"]) {
        return nil;*/
    } else if([url.host.lowercaseString isEqualToString:@"cl.ly"]) {
        return nil;
    } else if([url.path hasPrefix:@"/wiki/"] && [url.absoluteString containsString:@"/File:"]) {
        return nil;
    } else if([url.host.lowercaseString isEqualToString:@"xkcd.com"] || [url.host.lowercaseString hasSuffix:@".xkcd.com"]) {
        return nil;
    } else if([url.host hasSuffix:@"leetfiles.com"]) {
        NSString *u = url.absoluteString;
        u = [u stringByReplacingOccurrencesOfString:@"www." withString:@""];
        u = [u stringByReplacingOccurrencesOfString:@"leetfiles.com/image" withString:@"i.leetfiles.com/"];
        u = [u stringByReplacingOccurrencesOfString:@"?id=" withString:@""];
        url = [NSURL URLWithString:u];
    } else if([url.host hasSuffix:@"leetfil.es"]) {
        NSString *u = url.absoluteString;
        u = [u stringByReplacingOccurrencesOfString:@"www." withString:@""];
        u = [u stringByReplacingOccurrencesOfString:@"leetfil.es/image" withString:@"i.leetfiles.com/"];
        u = [u stringByReplacingOccurrencesOfString:@"?id=" withString:@""];
        url = [NSURL URLWithString:u];
    }
    
    [_mediaURLs setObject:@{@"thumb":url, @"image":url, @"url":url} forKey:original_url];
    
    return [_mediaURLs objectForKey:url];
}

-(void)fetchMediaURLs:(NSURL *)url result:(mediaURLResult)callback {
    if([_mediaURLs objectForKey:url]) {
        callback(YES, [_mediaURLs objectForKey:url]);
    } else if(![_tasks objectForKey:url]) {
        [_tasks setObject:@(YES) forKey:url];
        
        if(([[url.host lowercaseString] isEqualToString:@"imgur.com"] || [[url.host lowercaseString] isEqualToString:@"m.imgur.com"]) && url.path.length > 1) {
            NSString *imageID = [url.path substringFromIndex:1];
            if([imageID rangeOfString:@"/"].location == NSNotFound) {
                [self _loadImgur:imageID type:@"image" result:callback original_url:url];
            } else if([imageID hasPrefix:@"gallery/"]) {
                [self _loadImgur:[imageID substringFromIndex:8] type:@"gallery" result:callback original_url:url];
            } else if([imageID hasPrefix:@"a/"]) {
                [self _loadImgur:[imageID substringFromIndex:2] type:@"album" result:callback original_url:url];
            } else if([imageID hasPrefix:@"t/"] && [[imageID substringFromIndex:2] rangeOfString:@"/"].location != NSNotFound) {
                [self _loadImgur:[[imageID substringFromIndex:2] substringFromIndex:[[imageID substringFromIndex:2] rangeOfString:@"/"].location] type:@"image" result:callback original_url:url];
            } else {
                callback(NO, @"Invalid URL");
            }
        } else if([[url.host lowercaseString] isEqualToString:@"i.imgur.com"]) {
            [self _loadImgur:[url.path substringToIndex:[url.path rangeOfString:@"."].location] type:@"image" result:callback original_url:url];
        } else if(([[url.host lowercaseString] hasSuffix:@"giphy.com"] || [[url.host lowercaseString] isEqualToString:@"gph.is"]) && url.pathExtension.length == 0) {
            NSString *u = url.absoluteString;
            if([u rangeOfString:@"/gifs/"].location != NSNotFound) {
                u = [NSString stringWithFormat:@"http://giphy.com/gifs/%@", [url.pathComponents objectAtIndex:2]];
            }
            [self _loadOembed:[NSString stringWithFormat:@"https://giphy.com/services/oembed/?url=%@", u] result:callback original_url:url];
        } else if([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [url.host rangeOfString:@"static"].location == NSNotFound) {
            [self _loadOembed:[NSString stringWithFormat:@"https://www.flickr.com/services/oembed/?url=%@&format=json", url.absoluteString] result:callback original_url:url];
        /*} else if(([[url.host lowercaseString] hasSuffix:@"instagram.com"] || [[url.host lowercaseString] hasSuffix:@"instagr.am"]) && [url.path hasPrefix:@"/p/"]) {
            [self _loadOembed:[NSString stringWithFormat:@"http://api.instagram.com/oembed?url=%@", url.absoluteString] result:callback original_url:url];*/
        } else if([url.host.lowercaseString isEqualToString:@"cl.ly"]) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
            [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    NSLog(@"Error fetching cl.ly metadata. Error %li : %@", (long)error.code, error.userInfo);
                    callback(NO,error.localizedDescription);
                } else {
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    if([[dict objectForKey:@"item_type"] isEqualToString:@"image"]) {
                        [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"content_url"]],
                                                @"image":[NSURL URLWithString:[dict objectForKey:@"content_url"]],
                                                @"url":url
                                                } forKey:url];
                        callback(YES, nil);
                    } else {
                        NSLog(@"Invalid type from cl.ly");
                        callback(NO,@"This image type is not supported");
                    }
                }
            }];
        } else if([url.path hasPrefix:@"/wiki/"] && [url.absoluteString containsString:@"/File:"]) {
            NSString *title = [url.absoluteString substringFromIndex:[url.absoluteString rangeOfString:@"/File:"].location + 1];
            NSURL *wikiurl = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@%@", url.scheme, url.host, url.port,[[NSString stringWithFormat:@"/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url&titles=%@", title] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:wikiurl];
            [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    NSLog(@"Error fetching MediaWiki metadata. Error %li : %@", (long)error.code, error.userInfo);
                    callback(NO,error.localizedDescription);
                } else {
                    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                    NSDictionary *page = [[[[dict objectForKey:@"query"] objectForKey:@"pages"] allValues] objectAtIndex:0];
                    if(page && [page objectForKey:@"imageinfo"]) {
                        [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[[[page objectForKey:@"imageinfo"] objectAtIndex:0] objectForKey:@"url"]],
                                                @"image":[NSURL URLWithString:[[[page objectForKey:@"imageinfo"] objectAtIndex:0] objectForKey:@"url"]],
                                                @"url":url
                                                } forKey:url];
                        callback(YES, nil);
                    } else {
                        NSLog(@"Invalid data from MediaWiki");
                        callback(NO,@"This image type is not supported");
                    }
                }
            }];
        } else if([url.host.lowercaseString isEqualToString:@"xkcd.com"] || [url.host.lowercaseString hasSuffix:@".xkcd.com"]) {
            [self _loadXKCD:url result:callback];
        }
    }
}

-(void)_loadOembed:(NSString *)url result:(mediaURLResult)callback original_url:(NSURL *)original_url {
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching oembed. Error %li : %@", (long)error.code, error.userInfo);
            callback(NO,error.localizedDescription);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if([[dict objectForKey:@"type"] isEqualToString:@"photo"]) {
                [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"url"]],
                                        @"image":[NSURL URLWithString:[dict objectForKey:@"url"]],
                                        @"url":original_url
                                        } forKey:original_url];
                callback(YES, nil);
            } else if([[dict objectForKey:@"provider_name"] isEqualToString:@"Instagram"]) {
                [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"thumbnail_url"]],
                                        @"image":[NSURL URLWithString:[dict objectForKey:@"thumbnail_url"]],
                                        @"description":[[dict objectForKey:@"title"] isKindOfClass:NSString.class]?[dict objectForKey:@"title"]:@"",
                                        @"url":original_url
                                        } forKey:original_url];
                callback(YES, nil);
            } else if([[dict objectForKey:@"provider_name"] isEqualToString:@"Giphy"] && [[dict objectForKey:@"url"] rangeOfString:@"/gifs/"].location != NSNotFound) {
                if([dict objectForKey:@"image"] && [[dict objectForKey:@"image"] hasSuffix:@".gif"]) {
                    [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"image"]],
                                            @"image":[NSURL URLWithString:[dict objectForKey:@"image"]],
                                            @"url":original_url
                                            } forKey:original_url];
                    callback(YES, nil);
                } else {
                    [self _loadGiphy:[[dict objectForKey:@"url"] substringFromIndex:[[dict objectForKey:@"url"] rangeOfString:@"/gifs/"].location + 6] result:callback original_url:original_url];
                }
            } else {
                NSLog(@"Invalid type from oembed");
                callback(NO,@"This URL type is not supported");
            }
        }
    }];
}

-(void)_loadGiphy:(NSString *)gifID result:(mediaURLResult)callback original_url:(NSURL *)original_url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.giphy.com/v1/gifs/%@?api_key=dc6zaTOxFJmzC", gifID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching giphy. Error %li : %@", (long)error.code, error.userInfo);
            callback(NO,error.localizedDescription);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if([[[dict objectForKey:@"meta"] objectForKey:@"status"] intValue] == 200 && [[dict objectForKey:@"data"] objectForKey:@"images"]) {
                dict = [[[dict objectForKey:@"data"] objectForKey:@"images"] objectForKey:@"original"];
                if([[dict objectForKey:@"mp4"] length]) {
                    [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"url"]],
                                            @"mp4":[NSURL URLWithString:[dict objectForKey:@"mp4"]],
                                            @"url":original_url
                                            } forKey:original_url];
                    callback(YES, nil);
                } else if([[dict objectForKey:@"url"] hasSuffix:@".gif"]) {
                    [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"url"]],
                                            @"image":[NSURL URLWithString:[dict objectForKey:@"url"]],
                                            @"url":original_url
                                            } forKey:original_url];
                    callback(YES, nil);
                } else {
                    CLS_LOG(@"Invalid type from giphy: %@", dict);
                    callback(NO,@"This image type is not supported");
                }
            } else {
                CLS_LOG(@"giphy failure: %@", dict);
                callback(NO,@"Unexpected response from server");
            }
        }
    }];
}

-(void)_loadImgur:(NSString *)ID type:(NSString *)type result:(mediaURLResult)callback original_url:(NSURL *)original_url {
#ifdef MASHAPE_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://imgur-apiv3.p.mashape.com/3/%@/%@", type, ID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.imgur.com/3/%@/%@", type, ID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
#endif
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            CLS_LOG(@"Error fetching imgur. Error %li : %@", (long)error.code, error.userInfo);
            callback(NO,error.localizedDescription);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if([[dict objectForKey:@"success"] intValue]) {
                dict = [dict objectForKey:@"data"];
                NSString *title = @"";
                if([[dict objectForKey:@"title"] isKindOfClass:NSString.class])
                    title = [dict objectForKey:@"title"];
                if([[dict objectForKey:@"images_count"] intValue] == 1 || [[dict objectForKey:@"is_album"] intValue] == 0) {
                    if([dict objectForKey:@"images"] && [(NSDictionary *)[dict objectForKey:@"images"] count] == 1)
                        dict = [[dict objectForKey:@"images"] objectAtIndex:0];
                    if([[dict objectForKey:@"title"] isKindOfClass:NSString.class] && [[dict objectForKey:@"title"] length])
                        title = [dict objectForKey:@"title"];
                    if([[dict objectForKey:@"type"] hasPrefix:@"image/"] && [[dict objectForKey:@"animated"] intValue] == 0) {
                        NSMutableDictionary *d = @{@"thumb":[NSURL URLWithString:[dict objectForKey:@"link"]],
                                            @"image":[NSURL URLWithString:[dict objectForKey:@"link"]],
                                            @"name":title,
                                            @"description":[[dict objectForKey:@"description"] isKindOfClass:NSString.class]?[dict objectForKey:@"description"]:@"",
                                            @"url":original_url,
                                            }.mutableCopy;
                        if([[dict objectForKey:@"width"] intValue] && [[dict objectForKey:@"height"] intValue]) {
                            [d setObject:@{@"width":[dict objectForKey:@"width"],@"height":[dict objectForKey:@"height"]} forKey:@"properties"];
                        }
                        [_mediaURLs setObject:d forKey:original_url];
                        callback(YES, nil);
                    } else if([[dict objectForKey:@"animated"] intValue] == 1 && [[dict objectForKey:@"mp4"] length] > 0) {
                        if([[dict objectForKey:@"looping"] intValue] == 1) {
                            NSMutableDictionary *d = @{@"thumb":[NSURL URLWithString:[[dict objectForKey:@"mp4"] stringByReplacingOccurrencesOfString:@".mp4" withString:@".gif"]],
                                                       @"mp4_loop":[NSURL URLWithString:[dict objectForKey:@"mp4"]],
                                                       @"name":title,
                                                       @"description":[[dict objectForKey:@"description"] isKindOfClass:NSString.class]?[dict objectForKey:@"description"]:@"",
                                                       @"url":original_url,
                                                       }.mutableCopy;
                            if([[dict objectForKey:@"width"] intValue] && [[dict objectForKey:@"height"] intValue]) {
                                [d setObject:@{@"width":[dict objectForKey:@"width"],@"height":[dict objectForKey:@"height"]} forKey:@"properties"];
                            }
                            [_mediaURLs setObject:d forKey:original_url];
                            callback(YES, nil);
                        } else {
                            NSMutableDictionary *d = @{@"thumb":[NSURL URLWithString:[[dict objectForKey:@"mp4"] stringByReplacingOccurrencesOfString:@".mp4" withString:@".gif"]],
                                                       @"mp4":[NSURL URLWithString:[dict objectForKey:@"mp4"]],
                                                       @"name":title,
                                                       @"description":[[dict objectForKey:@"description"] isKindOfClass:NSString.class]?[dict objectForKey:@"description"]:@"",
                                                       @"url":original_url,
                                                       }.mutableCopy;
                            if([[dict objectForKey:@"width"] intValue] && [[dict objectForKey:@"height"] intValue]) {
                                [d setObject:@{@"width":[dict objectForKey:@"width"],@"height":[dict objectForKey:@"height"]} forKey:@"properties"];
                            }
                            [_mediaURLs setObject:d forKey:original_url];
                            callback(YES, nil);
                        }
                    } else {
                        CLS_LOG(@"Invalid type from imgur: %@", dict);
                        callback(NO,@"This image type is not supported");
                    }
                } else {
                    CLS_LOG(@"Too many images from imgur: %@", dict);
                    callback(NO,@"Albums with multiple images are not supported");
                }
            } else {
                CLS_LOG(@"Imgur failure: %@", dict);
                callback(NO,@"Unexpected response from server");
            }
        }
    }];
}

-(void)_loadXKCD:(NSURL *)original_url result:(mediaURLResult)callback {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/info.0.json", original_url.absoluteString]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching xkcd. Error %li : %@", (long)error.code, error.userInfo);
            callback(NO,error.localizedDescription);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if([dict objectForKey:@"img"]) {
                [_mediaURLs setObject:@{@"thumb":[NSURL URLWithString:[dict objectForKey:@"img"]],
                                        @"image":[NSURL URLWithString:[dict objectForKey:@"img"]],
                                        @"name":[dict objectForKey:@"safe_title"],
                                        @"description":[dict objectForKey:@"alt"],
                                        @"url":original_url
                                        } forKey:original_url];
                callback(YES, nil);
            } else {
                CLS_LOG(@"xkcd failure: %@", dict);
                callback(NO,@"Unexpected response from server");
            }
        }
    }];
}

+ (BOOL)isImageURL:(NSURL *)url
{
    NSString *l = [url.path lowercaseString];
    // Use pre-processor macros instead of variables so conditions are still evaluated lazily
    return ([url.scheme.lowercaseString isEqualToString:@"http"] || [url.scheme.lowercaseString isEqualToString:@"https"]) && (HAS_IMAGE_SUFFIX(l) || IS_IMGUR(url) || IS_FLICKR(url) || /*IS_INSTAGRAM(url) ||*/ IS_DROPLR(url) || IS_CLOUDAPP(url) || IS_STEAM(url) || IS_LEET(url) || IS_GIPHY(url) || IS_WIKI(url) || IS_TWIMG(url) || IS_XKCD(url));
}

+ (BOOL)isYouTubeURL:(NSURL *)url
{
    return IS_YOUTUBE(url);
}

- (void)launchURL:(NSURL *)url
{
#ifndef EXTENSION
    if([[UIApplication sharedApplication] respondsToSelector:NSSelectorFromString(@"_deactivateReachability")])
        objc_msgSend([UIApplication sharedApplication], NSSelectorFromString(@"_deactivateReachability"));
    NSLog(@"Launch: %@", url);
    UIApplication *app = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate *)app.delegate;
    MainViewController *mainViewController = [appDelegate mainViewController];
    
    if(mainViewController.slidingViewController.presentedViewController) {
        [mainViewController.slidingViewController dismissViewControllerAnimated:NO completion:^{
            [self launchURL:url];
        }];
        return;
    }
    
    if(mainViewController.presentedViewController) {
        [mainViewController dismissViewControllerAnimated:NO completion:^{
            [self launchURL:url];
        }];
        return;
    }
    
    if([url.host hasSuffix:@"irccloud.com"] && [url.path isEqualToString:@"/invite"]) {
        int port = 6667;
        int ssl = 0;
        NSString *host;
        NSString *channel;
        for(NSString *p in [url.query componentsSeparatedByString:@"&"]) {
            NSArray *args = [p componentsSeparatedByString:@"="];
            if(args.count == 2) {
                if([args[0] isEqualToString:@"channel"])
                    channel = args[1];
                else if([args[0] isEqualToString:@"hostname"])
                    host = args[1];
                else if([args[0] isEqualToString:@"port"])
                    port = [args[1] intValue];
                else if([args[0] isEqualToString:@"ssl"])
                    ssl = [args[1] intValue];
            }
        }
        url = [NSURL URLWithString:[NSString stringWithFormat:@"irc%@://%@:%i/%@",(ssl > 0)?@"s":@"",host,port,channel]];
    }
    
#ifdef ENTERPRISE
    if([url.scheme hasPrefix:@"http"] && [url.host isEqualToString:IRCCLOUD_HOST] && [url.path hasPrefix:@"/pastebin/"]) {
#else
    if([url.scheme hasPrefix:@"http"] && [url.host hasSuffix:@"irccloud.com"] && [url.path hasPrefix:@"/pastebin/"]) {
#endif
        url = [NSURL URLWithString:[NSString stringWithFormat:@"irccloud-paste-%@://%@%@",url.scheme,url.host,url.path]];
    }

    if(![url.scheme hasPrefix:@"irc"]) {
        [mainViewController dismissKeyboard];
    }
    
    if([url.scheme hasPrefix:@"irccloud-paste-"]) {
        PastebinViewController *pvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PastebinViewController"];
        [pvc setUrl:[NSURL URLWithString:[url.absoluteString substringFromIndex:15]]];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pvc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            [mainViewController.slidingViewController presentViewController:nc animated:YES completion:nil];
        }];
    } else if([url.scheme hasPrefix:@"irc"]) {
        [mainViewController launchURL:[NSURL URLWithString:[url.absoluteString stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
    } else if([url.scheme isEqualToString:@"spotify"]) {
        if(![[UIApplication sharedApplication] openURL:url])
            [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://open.spotify.com/%@",[[url.absoluteString substringFromIndex:8] stringByReplacingOccurrencesOfString:@":" withString:@"/"]]]];
    } else if([url.scheme isEqualToString:@"facetime"]) {
        [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"facetime-prompt%@",[url.absoluteString substringFromIndex:8]]]];
    } else if([url.scheme isEqualToString:@"tel"]) {
        [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"telprompt%@",[url.absoluteString substringFromIndex:3]]]];
    } else if([[NSUserDefaults standardUserDefaults] boolForKey:@"imageViewer"] && [[self class] isImageURL:url]) {
        [self showImage:url];
    } else if([[NSUserDefaults standardUserDefaults] boolForKey:@"videoViewer"] && ([url.pathExtension.lowercaseString isEqualToString:@"mov"] || [url.pathExtension.lowercaseString isEqualToString:@"mp4"] || [url.pathExtension.lowercaseString isEqualToString:@"m4v"] || [url.pathExtension.lowercaseString isEqualToString:@"3gp"] || [url.pathExtension.lowercaseString isEqualToString:@"quicktime"])) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
        player.modalPresentationStyle = UIModalPresentationFullScreen;
        player.player = [[AVPlayer alloc] initWithURL:url];
        [mainViewController presentViewController:player animated:YES completion:nil];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        [Answers logContentViewWithName:nil contentType:@"Video" contentId:nil customAttributes:nil];
    } else if([[NSUserDefaults standardUserDefaults] boolForKey:@"videoViewer"] && IS_YOUTUBE(url)) {
        [mainViewController launchURL:url];
    } else {
        [self openWebpage:url];
    }
#endif
}

- (void)showImage:(NSURL *)url
{
#ifndef EXTENSION
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    ImageViewController *ivc = [[ImageViewController alloc] initWithURL:url];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        appDelegate.mainViewController.ignoreVisibilityChanges = YES;
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = ivc;
        appDelegate.slideViewController.view.frame = appDelegate.window.bounds;
        [appDelegate.window insertSubview:appDelegate.slideViewController.view belowSubview:ivc.view];
        appDelegate.mainViewController.ignoreVisibilityChanges = NO;
        ivc.view.alpha = 0;
        [UIView animateWithDuration:0.5f animations:^{
            appDelegate.window.rootViewController.view.alpha = 1;
        } completion:nil];
    }];
#endif
}

- (void)openWebpage:(NSURL *)url
{
#ifndef EXTENSION
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        if([[OpenInChromeController sharedInstance] openInChrome:url withCallbackURL:self.appCallbackURL createNewTab:NO])
            return;
    }
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        if([[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:url])
            return;
    }
    if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Safari"] && [SFSafariViewController class] && [url.scheme hasPrefix:@"http"]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIApplication *app = [UIApplication sharedApplication];
            AppDelegate *appDelegate = (AppDelegate *)app.delegate;
            MainViewController *mainViewController = [appDelegate mainViewController];
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
            [UIApplication sharedApplication].statusBarHidden = NO;
            
            [mainViewController.slidingViewController presentViewController:[[SFSafariViewController alloc] initWithURL:url] animated:YES completion:nil];
        }];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
#endif
}

+ (UIActivityViewController *)activityControllerForItems:(NSArray *)items type:(NSString *)type {
#ifndef EXTENSION
    NSArray *activities;
    
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        activities = @[[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                      @"irccloud-enterprise://"
#else
                                                                      @"irccloud://"
#endif
                                                                      ]]];
    } else if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        activities = @[[[OpenInFirefoxActivity alloc] init]];
    } else {
        activities = @[[[TUSafariActivity alloc] init]];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:activities];
    activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if(completed) {
            if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                activityType = [activityType substringFromIndex:25];
            if([activityType hasPrefix:@"com.apple."])
                activityType = [activityType substringFromIndex:10];
            [Answers logShareWithMethod:activityType contentName:nil contentType:type contentId:nil customAttributes:nil];
        }
    };
    return activityController;
#else
    return nil;
#endif
}

+ (int)URLtoBID:(NSURL *)url {
    if([url.path hasPrefix:@"/irc/"]) {
        NSString *network = [[url.pathComponents objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *type = [url.pathComponents objectAtIndex:3];
        if([type isEqualToString:@"channel"] || [type isEqualToString:@"messages"]) {
            NSString *name = [[url.pathComponents objectAtIndex:4] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            for(Server *s in [[ServersDataSource sharedInstance] getServers]) {
                NSString *serverHost = [s.hostname lowercaseString];
                if([serverHost hasPrefix:@"irc."])
                    serverHost = [serverHost substringFromIndex:4];
                serverHost = [serverHost stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
                
                NSString *serverName = [s.name lowercaseString];
                serverName = [serverName stringByReplacingOccurrencesOfString:@"_" withString:@"-"];

                if([network isEqualToString:serverHost] || [network isEqualToString:serverName]) {
                    for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffersForServer:s.cid]) {
                        if(([type isEqualToString:@"channel"] && [b.type isEqualToString:@"channel"]) || ([type isEqualToString:@"messages"] && [b.type isEqualToString:@"conversation"])) {
                            NSString *bufferName = b.name;
                            
                            if([b.type isEqualToString:@"channel"]) {
                                if([bufferName hasPrefix:@"#"])
                                    bufferName = [bufferName substringFromIndex:1];
                                if(![bufferName isEqualToString:[b accessibilityValue]])
                                    bufferName = b.name;
                            }
                            
                            if([bufferName isEqualToString:name])
                                return b.bid;
                        }
                    }
                }
            }
        }
    }
    return -1;
}

@end
