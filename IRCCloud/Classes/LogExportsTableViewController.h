//
//  LogExportsTableViewController.h
//
//  Copyright (C) 2017 IRCCloud, Ltd.
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
#import "BuffersDataSource.h"
#import "ServersDataSource.h"

@interface LogExportsTableViewController : UITableViewController<NSURLSessionDownloadDelegate> {
    NSArray *_available;
    NSArray *_inprogress;
    NSArray *_expired;
    NSMutableDictionary *_downloadingURLs;
    UIDocumentInteractionController *_interactionController;
    
    Buffer *_buffer;
    Server *_server;
}

@property Buffer *buffer;
@property Server *server;

-(void)download:(NSURL *)url;

@end
