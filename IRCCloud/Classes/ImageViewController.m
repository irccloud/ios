//
//  ImageViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 6/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "ImageViewController.h"
#import "AppDelegate.h"
#import "UIImage+animatedGIF.h"
#import "OpenInChromeController.h"

@implementation ImageViewController

- (id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self) {
        _url = url;
    }
    return self;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll {
    return _imageView;
}

-(void)_setImage:(UIImage *)img {
    _imageView.image = img;
    _imageView.frame = CGRectMake(0,0,img.size.width,img.size.height);
    CGFloat xScale = self.view.bounds.size.width / img.size.width;
    CGFloat yScale = self.view.bounds.size.height / img.size.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    CGFloat maxScale = 4;
    
    if (minScale > maxScale) {
        minScale = maxScale;
    }

    _scrollView.minimumZoomScale = minScale;
    _scrollView.maximumZoomScale = maxScale;
    _scrollView.contentSize = img.size;
    _scrollView.zoomScale = minScale;
    [self scrollViewDidZoom:_scrollView];

    [_activityView stopAnimating];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    _imageView.alpha = 1;
    [UIView commitAnimations];
}

//Some centering magic from: http://stackoverflow.com/a/2189336/1406639
-(void)scrollViewDidZoom:(UIScrollView *)pScrollView {
    CGRect innerFrame = _imageView.frame;
    CGRect scrollerBounds = pScrollView.bounds;
    
    if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height)) {
        CGFloat tempx = _imageView.center.x - (scrollerBounds.size.width / 2);
        CGFloat tempy = _imageView.center.y - (scrollerBounds.size.height / 2);
        CGPoint myScrollViewOffset = CGPointMake(tempx, tempy);
        
        pScrollView.contentOffset = myScrollViewOffset;
        
    }
    
    UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
    if(scrollerBounds.size.width > innerFrame.size.width) {
        anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
        anEdgeInset.right = -anEdgeInset.left;
    }
    if(scrollerBounds.size.height > innerFrame.size.height) {
        anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
        anEdgeInset.bottom = -anEdgeInset.top;
    }
    pScrollView.contentInset = anEdgeInset;
}

-(void)_load {
    UIImage *img = nil;
    NSData *data = [NSData dataWithContentsOfURL:_url];
    if(data) {
        if([[[_url description] lowercaseString] hasSuffix:@"gif"])
            img = [UIImage animatedImageWithAnimatedGIFData:data];
        else
            img = [UIImage imageWithData:data];
        if(img)
            [self performSelectorOnMainThread:@selector(_setImage:) withObject:img waitUntilDone:YES];
    }
    if(!data || !img) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView];
        OpenInChromeController *chrome = [[OpenInChromeController alloc] init];
        if(![chrome openInChrome:_url
                                  withCallbackURL:[NSURL URLWithString:@"irccloud://"]
                                     createNewTab:NO])
            [[UIApplication sharedApplication] openURL:_url];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    } else {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    }
    [self performSelectorInBackground:@selector(_load) withObject:nil];
}

-(IBAction)viewTapped:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
