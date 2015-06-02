//
//  FilesTableViewController.h
//
//  Copyright (C) 2014 IRCCloud, Ltd.
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
#import "CSURITemplate.h"

@protocol FilesTableViewDelegate<NSObject>
-(void)filesTableViewControllerDidSelectFile:(NSDictionary *)file message:(NSString *)message;
@end

@protocol ImageFetcherDelegate<NSObject>
-(void)imageFetcher:(id)imageFetcher downloadedImage:(NSData *)img;
-(void)imageFetcherDidFail:(id)imageFetcher;
@end

@interface ImageFetcher : NSObject<NSURLConnectionDelegate> {
    NSString *_url;
    NSString *_fileID;
    BOOL _cancelled;
    BOOL _running;
    NSURLConnection *_connection;
    NSMutableData *_data;
    id<ImageFetcherDelegate> _delegate;
}
@property (readonly) NSString *fileID;
@property id<ImageFetcherDelegate> delegate;
-(id)initWithURL:(NSString *)URL fileID:(NSString *)fileID;
-(void)cancel;
-(void)start;
@end

@interface FilesTableViewController : UITableViewController<ImageFetcherDelegate> {
    int _pages;
    NSArray *_files;
    NSMutableDictionary *_thumbnails;
    NSMutableDictionary *_imageViews;
    NSMutableDictionary *_spinners;
    NSMutableDictionary *_extensions;
    NSMutableDictionary *_imageFetchers;
    NSDateFormatter *_formatter;
    int _reqid;
    BOOL _canLoadMore;
    id<FilesTableViewDelegate> _delegate;
    UIView *_footerView;
    NSDictionary *_selectedFile;
    CSURITemplate *_url_template;
}
@property id<FilesTableViewDelegate> delegate;
@end
