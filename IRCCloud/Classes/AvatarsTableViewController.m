//
//  AvatarsTableViewController.m
//
//  Copyright (C) 2018 IRCCloud, Ltd.
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

#import <AssetsLibrary/AssetsLibrary.h>
#import "AvatarsTableViewController.h"
#import "YYAnimatedImageView.h"
#import "ImageCache.h"
#import "UIColor+IRCCloud.h"

@interface AvatarTableCell : UITableViewCell {
    YYAnimatedImageView *_avatar;
}
@property (readonly) YYAnimatedImageView *avatar;
@end

@implementation AvatarTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        _avatar = [[YYAnimatedImageView alloc] initWithFrame:CGRectZero];
        _avatar.layer.cornerRadius = 5.0;
        _avatar.layer.masksToBounds = YES;
        
        [self.contentView addSubview:_avatar];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = [self.contentView bounds];
    frame.origin.x = frame.origin.y = 6;
    frame.size.width -= 12;
    frame.size.height -= 12;
    
    _avatar.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.height, frame.size.height);
    self.textLabel.frame = CGRectMake(frame.origin.x + frame.size.height + 6, frame.origin.y, frame.size.width - frame.size.height, frame.size.height);
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end


@implementation AvatarsTableViewController

-(id)initWithServer:(int)cid {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        _server = [[ServersDataSource sharedInstance] getServer:cid];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"Choose An Avatar";
    self.navigationController.navigationBar.clipsToBounds = YES;
    if(self.navigationController.viewControllers.count == 1)
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(addButtonPressed)];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
}

-(void)cancelButtonPressed {
    [_uploader cancel];
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)addButtonPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Take a Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self _choosePhoto:UIImagePickerControllerSourceTypeCamera];
        }]];
    }
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [alert addAction:[UIAlertAction actionWithTitle:@"Choose Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self _choosePhoto:UIImagePickerControllerSourceTypePhotoLibrary];
        }]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *alert) {}]];
    alert.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    alert.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_choosePhoto:(UIImagePickerControllerSourceType)sourceType {
    [_uploader cancel];
    _uploader = nil;
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.delegate = (id)self;
    [UIColor clearTheme];
    if(sourceType == UIImagePickerControllerSourceTypeCamera) {
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        picker.modalPresentationStyle = UIModalPresentationPopover;
        picker.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [picker dismissViewControllerAnimated:YES completion:nil];

    NSURL *refURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    NSURL *mediaURL = [info valueForKey:UIImagePickerControllerMediaURL];
    UIImage *img = [info objectForKey:UIImagePickerControllerEditedImage];
    if(!img)
        img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    CLS_LOG(@"Image file chosen: %@ %@", refURL, mediaURL);
    if(img || refURL || mediaURL) {
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera && [[NSUserDefaults standardUserDefaults] boolForKey:@"saveToCameraRoll"]) {
            if(img)
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
            else if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(mediaURL.path))
                UISaveVideoAtPathToSavedPhotosAlbum(mediaURL.path, nil, nil, nil);
        }
        FileUploader *u = [[FileUploader alloc] init];
        u.delegate = self;
        u.avatar = YES;
        if(_server)
            u.orgId = _server.orgId;
        else
            u.orgId = -1;
        
        if(refURL) {
            CLS_LOG(@"Loading metadata from asset library");
            ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *imageAsset) {
                ALAssetRepresentation *imageRep = [imageAsset defaultRepresentation];
                CLS_LOG(@"Got filename: %@", imageRep.filename);
                u.originalFilename = imageRep.filename;
                if([imageRep.filename.lowercaseString hasSuffix:@".gif"] || [imageRep.filename.lowercaseString hasSuffix:@".png"]) {
                    CLS_LOG(@"Uploading file data");
                    NSMutableData *data = [[NSMutableData alloc] initWithCapacity:(NSUInteger)imageRep.size];
                    uint8_t buffer[4096];
                    long long len = 0;
                    while(len < imageRep.size) {
                        long long i = [imageRep getBytes:buffer fromOffset:len length:4096 error:nil];
                        [data appendBytes:buffer length:(NSUInteger)i];
                        len += i;
                    }
                    [u uploadFile:imageRep.filename UTI:imageRep.UTI data:data];
                } else {
                    CLS_LOG(@"Uploading UIImage");
                    [u uploadImage:img];
                }
            };
            
            ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
            [assetslibrary assetForURL:refURL resultBlock:resultblock failureBlock:^(NSError *e) {
                CLS_LOG(@"Error getting asset: %@", e);
                if(img) {
                    [u uploadImage:img];
                } else {
                    [u uploadFile:mediaURL];
                }
            }];
        } else {
            CLS_LOG(@"no asset library URL, uploading image data instead");
            if(img) {
                [u uploadImage:img];
            } else {
                [u uploadFile:mediaURL];
            }
        }
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)fileUploadProgress:(float)progress {
    NSLog(@"Upload progress: %f", progress);
}

-(void)fileUploadDidFail:(NSString *)reason {
    NSLog(@"Upload failed: %@", reason);
}

-(void)fileUploadDidFinish {
    NSLog(@"Upload finished");
}

-(void)fileUploadWasCancelled {
    NSLog(@"Upload cancelled");
}

-(void)fileUploadTooLarge {
    NSLog(@"Upload too large");
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    
    switch(event) {
        case kIRCEventMakeServer:
        case kIRCEventAvatarChange:
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self viewWillAppear:NO];
            }];
            break;
        }
        default:
            break;
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if(animated)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];

    NSMutableArray *data = [[NSMutableArray alloc] init];
    for(Server *s in [ServersDataSource sharedInstance].getServers) {
        if(s.avatar.length && ![s.avatar isEqualToString:[[NetworkConnection sharedInstance].userInfo objectForKey:@"avatar"]]) {
            NSURL *url = [NSURL URLWithString:[[NetworkConnection sharedInstance].avatarURITemplate relativeStringWithVariables:@{@"id":s.avatar, @"modifiers":[NSString stringWithFormat:@"w%i", (int)(64 * [UIScreen mainScreen].scale)]} error:nil]];
            if(![[ImageCache sharedInstance] imageForURL:url]) {
                [[ImageCache sharedInstance] fetchURL:url completionHandler:^(BOOL success) {
                    if(success) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.tableView reloadData];
                        }];
                    }
                }];
            }
            [data addObject:@{@"label":[NSString stringWithFormat:@"%@ on %@", s.nick, s.name.length?s.name:s.hostname],
                              @"id":s.avatar,
                              @"url":url,
                              @"orgId":@(s.orgId),
                              }];
        }
    }
    if([[[NetworkConnection sharedInstance].userInfo objectForKey:@"avatar"] length]) {
        NSURL *url = [NSURL URLWithString:[[NetworkConnection sharedInstance].avatarURITemplate relativeStringWithVariables:@{@"id":[[NetworkConnection sharedInstance].userInfo objectForKey:@"avatar"], @"modifiers":[NSString stringWithFormat:@"w%i", (int)(64 * [UIScreen mainScreen].scale)]} error:nil]];
        if(![[ImageCache sharedInstance] imageForURL:url]) {
            [[ImageCache sharedInstance] fetchURL:url completionHandler:^(BOOL success) {
                if(success) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self.tableView reloadData];
                    }];
                }
            }];
        }
        [data addObject:@{@"label":@"Public avatar",
                          @"id":[[NetworkConnection sharedInstance].userInfo objectForKey:@"avatar"],
                          @"url":url,
                          @"orgId":@(-1),
                          }];
    }

    _avatars = data;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _avatars.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_avatars) {
        AvatarTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"avatarcell"];
        if(!cell)
            cell = [[AvatarTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"avatarcell"];
        NSDictionary *row = [_avatars objectAtIndex:[indexPath row]];
        cell.textLabel.text = [row objectForKey:@"label"];
        cell.avatar.image = [[ImageCache sharedInstance] imageForURL:[row objectForKey:@"url"]];
        if([_server.avatar isEqualToString:[row objectForKey:@"id"]])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[NetworkConnection sharedInstance] setAvatar:nil orgId:[[[_avatars objectAtIndex:indexPath.row] objectForKey:@"orgId"] intValue] handler:nil];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    @synchronized(_avatars) {
        NSDictionary *row = [_avatars objectAtIndex:[indexPath row]];
        [[NetworkConnection sharedInstance] setAvatar:[row objectForKey:@"id"] orgId:_server.orgId handler:nil];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
