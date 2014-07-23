//
//  ShareViewController.m
//  ShareExtension
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "ShareViewController.h"
#import "BuffersTableView.h"

@interface ShareViewController ()

@end

@implementation ShareViewController

- (void)presentationAnimationDidFinish {
    if(_conn.state != kIRCCloudStateConnected) {
        //[_conn connect];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
    _conn = [NetworkConnection sharedInstance];
    _splash = [self.storyboard instantiateViewControllerWithIdentifier:@"splash"];
    [self pushConfigurationViewController:_splash];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogComplete:)
                                                 name:kIRCCloudBacklogCompletedNotification object:nil];
    if(_conn.state == kIRCCloudStateConnected) {
        _buffer = [[BuffersDataSource sharedInstance] getBuffer:[[_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
    }
}

- (void)backlogComplete:(NSNotification *)n {
    if(!_buffer)
        _buffer = [[BuffersDataSource sharedInstance] getBuffer:[[_conn.userInfo objectForKey:@"last_selected_bid"] intValue]];
    [self reloadConfigurationItems];
    [self validateContent];
}

- (BOOL)isContentValid {
    return _buffer != nil;
}

- (void)didSelectPost {
    NSExtensionItem *input = self.extensionContext.inputItems.firstObject;
    NSExtensionItem *output = [input copy];
    output.attributedContentText = [[NSAttributedString alloc] initWithString:self.contentText attributes:nil];

    if(output.attachments.count) {
        NSItemProvider *i = output.attachments.firstObject;
        if([i hasItemConformingToTypeIdentifier:@"public.url"]) {
            [i loadItemForTypeIdentifier:@"public.url" options:nil completionHandler:^(NSURL *item, NSError *error) {
               [_conn say:[NSString stringWithFormat:@"%@ [%@]",self.contentText,item.absoluteString] to:_buffer.name cid:_buffer.cid];
               [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
           }];
        } else if([i.registeredTypeIdentifiers indexOfObject:@"public.image"] != NSNotFound) {
            
        }
    } else {
        [_conn say:self.contentText to:_buffer.name cid:_buffer.cid];
        [self.extensionContext completeRequestReturningItems:@[output] completionHandler:nil];
    }
}

- (NSArray *)configurationItems {
    SLComposeSheetConfigurationItem *bufferConfigItem = [[SLComposeSheetConfigurationItem alloc] init];
    bufferConfigItem.title = @"Conversation";
    if(_buffer)
        bufferConfigItem.value = _buffer.name;
    else
        bufferConfigItem.valuePending = YES;
    
    bufferConfigItem.tapHandler = ^() {
        BuffersTableView *b = [[BuffersTableView alloc] initWithStyle:UITableViewStylePlain];
        b.navigationItem.title = @"Conversations";
        b.delegate = self;
        [self pushConfigurationViewController:b];
    };
    return @[bufferConfigItem];
}

-(void)bufferSelected:(int)bid {
    _buffer = [[BuffersDataSource sharedInstance] getBuffer:bid];
    [self reloadConfigurationItems];
    [self validateContent];
    [self popConfigurationViewController];
}

-(void)bufferLongPressed:(int)bid rect:(CGRect)rect {
    
}

-(void)dismissKeyboard {
    
}


@end
