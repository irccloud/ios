//
//  URLHandler.h
//  IRCCloud
//
//  Created by Aditya KD on 03/07/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface URLHandler : NSObject <UIAlertViewDelegate>

@property (nonatomic, copy) NSURL *appCallbackURL;

- (void)launchURL:(NSURL *)url;

@end
