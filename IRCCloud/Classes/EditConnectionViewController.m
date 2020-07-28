//
//  EditConnectionViewController.m
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


#import "EditConnectionViewController.h"
#import "NetworkConnection.h"
#import "AppDelegate.h"
#import "UIColor+IRCCloud.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "FontAwesome.h"
#import "ColorFormatter.h"

@interface NetworkListViewController : UITableViewController {
    id<NetworkListDelegate> _delegate;
    NSString *_selection;
    NSArray *_networks;
    
    UIActivityIndicatorView *_activityIndicator;
}
@property (nonatomic) NSString *selection;
-(id)initWithDelegate:(id)delegate;
- (void)fetchServerList;
@end

static NSString * const NetworksListLink = @"http://irccloud.com/static/networks.json";
static NSString * const FetchedDataNetworksKey = @"networks";
static NSString * const NetworkNameKey = @"name";
static NSString * const NetworkServersKey = @"servers";
static NSString * const ServerHostNameKey = @"hostname";
static NSString * const ServerPortKey = @"port";
static NSString * const ServerHasSSLKey = @"ssl";

@implementation NetworkListViewController

-(id)initWithDelegate:(id)delegate {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self->_delegate = delegate;
        self.navigationItem.title = @"Networks";
        [self fetchServerList];
    }
    return self;
}
         
- (void)fetchServerList
{
    self->_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    self->_activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    self->_activityIndicator.center = (CGPoint){(self.view.bounds.size.width * 0.5), (self.view.bounds.size.height * 0.5)};
    [self->_activityIndicator startAnimating];
    [self.view addSubview:self->_activityIndicator];

#ifdef DEBUG
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
#endif
    
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:NetworksListLink] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            CLS_LOG(@"Error fetching remote networks list. Error %li : %@", (long)error.code, error.userInfo);
            
            self->_networks = @[];
        }
        else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            NSMutableArray *networks = [[NSMutableArray alloc] initWithCapacity:[(NSArray *)dict[FetchedDataNetworksKey] count]];
            for (NSDictionary *network in dict[FetchedDataNetworksKey]) {
                NSDictionary *server = [(NSArray *)network[NetworkServersKey] objectAtIndex:0];
                if(server) {
                    [networks addObject:@{
                        @"network": network[NetworkNameKey],
                        @"host": server[ServerHostNameKey],
                        @"port": server[ServerPortKey],
                        @"SSL": server[ServerHasSSLKey]
                    }];
                }
            }
            self->_networks = networks;
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self->_activityIndicator stopAnimating];
            [self->_activityIndicator removeFromSuperview];
            [self.tableView reloadData];
        }];
    }] resume];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self->_networks count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"networkcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"networkcell"];
    
    NSDictionary *row = [self->_networks objectAtIndex:indexPath.row];
    [[cell.textLabel subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    cell.textLabel.clipsToBounds = NO;
    UILabel *icon = [[UILabel alloc] initWithFrame:CGRectMake(2,2.4,16,16)];
    icon.font = [UIFont fontWithName:@"FontAwesome" size:cell.textLabel.font.pointSize];
    icon.textAlignment = NSTextAlignmentCenter;
    if([[row objectForKey:@"SSL"] boolValue])
        icon.text = FA_SHIELD;
    else
        icon.text = FA_GLOBE;
/* icon on the right instead
     if([[row objectForKey:@"SSL"] boolValue]) {
     UIImageView *icon = [[UIImageView alloc] initWithFrame:CGRectMake([cell.textLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:18]].width + 2,2,16,16)];
     icon.image = [UIImage imageNamed:@"world_shield"];
     [cell.textLabel addSubview:icon];
     }
*/
    [cell.textLabel addSubview:icon];
    icon.textColor = [UITableViewCell appearance].textLabelColor;
    cell.textLabel.text = [NSString stringWithFormat:@"     %@",[row objectForKey:@"network"]];
    cell.detailTextLabel.text = [row objectForKey:@"host"];
    
    if([self->_selection isEqualToString:cell.textLabel.text])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self->_selection = [self tableView:tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    [tableView reloadData];
    NSDictionary *row = [self->_networks objectAtIndex:indexPath.row];
    [self->_delegate setNetwork:[row objectForKey:@"network"] host:[row objectForKey:@"host"] port:[[row objectForKey:@"port"] intValue] SSL:[[row objectForKey:@"SSL"] boolValue]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation EditConnectionViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        self->_cid = -1;
        self.navigationItem.title = @"New Connection";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//From: http://stackoverflow.com/a/13867108/1406639
- (void)keyboardWillShow:(NSNotification *)aNotification
{
    if(keyboardShown)
        return;
    
    keyboardShown = YES;
    
    // Get the keyboard size
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    // Get the keyboard's animation details
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if(self.inputAccessoryView && keyboardOverlap>0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;
        
        tableView.contentInset = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }
    
    if(keyboardOverlap < 0)
        keyboardOverlap = 0;
    
    if(keyboardOverlap != 0)
    {
        tableFrame.size.height -= keyboardOverlap;
        
        NSTimeInterval delay = 0;
        if(keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap/keyboardRect.size.height)*animationDuration;
            animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
        }
        
        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{ tableView.frame = tableFrame; }
                         completion:^(BOOL finished){ [self tableAnimationEnded:nil finished:nil contextInfo:nil]; }];
    }
}

//From: http://stackoverflow.com/a/13867108/1406639
- (void)keyboardWillHide:(NSNotification *)aNotification {
    if(!keyboardShown)
        return;
    
    keyboardShown = NO;
    
    UIScrollView *tableView;
    if([self.tableView.superview isKindOfClass:[UIScrollView class]])
        tableView = (UIScrollView *)self.tableView.superview;
    else
        tableView = self.tableView;
    if(self.inputAccessoryView)
    {
        tableView.contentInset = UIEdgeInsetsZero;
        tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    
    if(keyboardOverlap == 0)
        return;
    
    // Get the size & animation details of the keyboard
    NSDictionary *userInfo = [aNotification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [tableView.superview convertRect:[aValue CGRectValue] fromView:nil];
    
    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    
    CGRect tableFrame = tableView.frame;
    tableFrame.size.height += keyboardOverlap;
    
    if(keyboardRect.size.height)
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    
    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{ tableView.frame = tableFrame; }
                     completion:nil];
}

//From: http://stackoverflow.com/a/13867108/1406639
- (void)tableAnimationEnded:(NSString*)animationID finished:(NSNumber *)finished contextInfo:(void *)context {
    // Scroll to the active cell
    if(self->_activeCellIndexPath) {
        [self.tableView scrollToRowAtIndexPath:self->_activeCellIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
//        [self.tableView selectRowAtIndexPath:self->_activeCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }
}

-(void)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    
    IRCCloudAPIResultHandler handler = ^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] boolValue]) {
            if(self->_cid == -1)
                ((AppDelegate *)([UIApplication sharedApplication].delegate)).mainViewController.cidToOpen = [[result objectForKey:@"cid"] intValue];
            if(self.presentingViewController) {
                [self.tableView endEditing:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            } else if([[result objectForKey:@"cid"] intValue]) {
                self->_cid = [[result objectForKey:@"cid"] intValue];
            }
        } else {
            NSString *msg = [result objectForKey:@"message"];
            if([msg isEqualToString:@"hostname"]) {
                msg = @"Invalid hostname";
            } else if([msg isEqualToString:@"nickname"]) {
                msg = @"Invalid nickname";
            } else if([msg isEqualToString:@"realname"]) {
                msg = @"Invalid real name";
            } else if([msg isEqualToString:@"passworded_servers"]) {
                msg = @"You can’t connect to passworded servers with free accounts";
            } else if([msg isEqualToString:@"networks"]) {
                msg = @"You’ve exceeded the connection limit for free accounts";
            } else if([msg isEqualToString:@"sts_policy"]) {
                msg = @"You can’t disable secure connections to this network because it’s using a strict transport security policy";
            } else if([msg isEqualToString:@"unverified"]) {
                msg = @"You can’t connect to external servers until you confirm your email address";
            }
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];

            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        }
    };
    
    if(self->_cid == -1) {
        [[NetworkConnection sharedInstance] addServer:self->_server.text port:[self->_port.text intValue] ssl:(self->_ssl.on)?1:0 netname:self->_netname nick:self->_nickname.text realname:self->_realname.text serverPass:self->_serverpass.text nickservPass:self->_nspass.text joinCommands:self->_commands.text channels:self->_channels.text handler:handler];
    } else if(self->_slack) {
        [[NetworkConnection sharedInstance] setNetworkName:self->_network.text cid:self->_cid handler:handler];
    } else {
        self->_netname = self->_network.text;
        if([self->_netname.lowercaseString isEqualToString:self->_server.text.lowercaseString])
            self->_netname = nil;
        [[NetworkConnection sharedInstance] editServer:self->_cid hostname:self->_server.text port:[self->_port.text intValue] ssl:(self->_ssl.on)?1:0 netname:self->_netname nick:self->_nickname.text realname:self->_realname.text serverPass:self->_serverpass.text nickservPass:self->_nspass.text joinCommands:self->_commands.text handler:handler];
    }
}

-(void)cancelButtonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)logoutButtonPressed:(id)sender {
    [[NetworkConnection sharedInstance] logout];
    [(AppDelegate *)([UIApplication sharedApplication].delegate) showLoginView];
}

-(void)setServer:(int)cid {
    self.navigationItem.title = @"Edit Connection";
    self->_cid = cid;
    [self refresh];
}

-(void)setNetwork:(NSString *)network host:(NSString *)host port:(int)port SSL:(BOOL)SSL {
    self->_network.text = self->_netname = network;
    self->_server.text = host;
    self->_port.text = [NSString stringWithFormat:@"%i", port];
    self->_ssl.on = SSL;
    [self.tableView reloadData];
}

-(void)setURL:(NSURL *)url {
    self->_url = url;
    self->_network.text = self->_netname = url.host;
    [self refresh];
}

-(void)updateWidth:(float)width view:(UIView *)v {
    v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, width, 22);
}

-(void)refresh {
    float width = self.tableView.frame.size.width / 3;
    [self updateWidth:width view:_server];
    [self updateWidth:width view:_port];
    [self updateWidth:width view:_nickname];
    [self updateWidth:width view:_realname];
    [self updateWidth:width view:_nspass];
    [self updateWidth:width view:_serverpass];
    [self updateWidth:width view:_network];
    [self updateWidth:width view:_commands];
    [self updateWidth:width view:_channels];

    self->_nspass.secureTextEntry = !self->_revealnspass.on;
    self->_serverpass.secureTextEntry = !self->_revealserverpass.on;

    if(self->_url) {
        int port = [self->_url.port intValue];
        int ssl = [self->_url.scheme hasSuffix:@"s"]?1:0;
        if(port == 0)
            port = (ssl == 1)?6697:6667;
        
        self->_server.text = self->_url.host;
        self->_port.text = [NSString stringWithFormat:@"%i", port];
        if(ssl == 1)
            self->_ssl.on = YES;
        else
            self->_ssl.on = NO;
        
        if(self->_url.path && _url.path.length > 1)
            self->_channels.text = [self->_url.path substringFromIndex:1];
    } else {
        Server *server = [[ServersDataSource sharedInstance] getServer:self->_cid];
        if(server) {
            self->_slack = server.slack;
            self->_network.text = self->_netname = server.name;
            if(self->_netname.length == 0)
                self->_network.text = self->_netname = server.hostname;
            
            if([server.hostname isKindOfClass:[NSString class]] && server.hostname.length)
                self->_server.text = server.hostname;
            else
                self->_server.text = @"";
            
            self->_port.text = [NSString stringWithFormat:@"%i", server.port];
            
            self->_ssl.on = (server.ssl > 0);

            if([server.nick isKindOfClass:[NSString class]] && server.nick.length)
                self->_nickname.text = server.nick;
            else
                self->_nickname.text = @"";
            
            if([server.realname isKindOfClass:[NSString class]] && server.realname.length)
                self->_realname.text = server.realname;
            else
                self->_realname.text = @"";
            
            if([server.nickserv_pass isKindOfClass:[NSString class]] && server.nickserv_pass.length)
                self->_nspass.text = server.nickserv_pass;
            else
                self->_nspass.text = @"";
            
            if([server.server_pass isKindOfClass:[NSString class]] && server.server_pass.length)
                self->_serverpass.text = server.server_pass;
            else
                self->_serverpass.text = @"";
            
            if([server.join_commands isKindOfClass:[NSString class]] && server.join_commands.length)
                self->_commands.text = server.join_commands;
            else
                self->_commands.text = @"";
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if(textField == self->_server)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    else if(textField == self->_port)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    if(textField == self->_nickname)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    if(textField == self->_realname)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    if(textField == self->_nspass)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    if(textField == self->_serverpass)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:2];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view.tag == 1) {
        [[NetworkConnection sharedInstance] resendVerifyEmailWithHandler:^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation Sent" message:@"You should shortly receive an email with a link to confirm your address." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation Failed" message:[NSString stringWithFormat:@"Unable to send confirmation message: %@. Please try again shortly.", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    return ![touch.view isKindOfClass:[UIControl class]];
}

- (void)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];

    NSDictionary *userInfo = [NetworkConnection sharedInstance].userInfo;
    NSString *name = [userInfo objectForKey:@"name"];
    
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;

    self->_network = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_network.placeholder = @"Network";
    self->_network.text = @"";
    self->_network.textAlignment = NSTextAlignmentRight;
    self->_network.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_network.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_network.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_network.keyboardType = UIKeyboardTypeDefault;
    self->_network.adjustsFontSizeToFitWidth = YES;
    self->_network.returnKeyType = UIReturnKeyDone;
    self->_network.delegate = self;
    
    self->_server = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_server.placeholder = @"irc.example.net";
    self->_server.text = @"";
    self->_server.textAlignment = NSTextAlignmentRight;
    self->_server.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_server.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_server.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_server.keyboardType = UIKeyboardTypeURL;
    self->_server.adjustsFontSizeToFitWidth = YES;
    self->_server.returnKeyType = UIReturnKeyDone;
    self->_server.delegate = self;
    
    self->_port = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_port.text = @"6667";
    self->_port.textAlignment = NSTextAlignmentRight;
    self->_port.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_port.keyboardType = UIKeyboardTypeNumberPad;
    self->_port.returnKeyType = UIReturnKeyDone;
    self->_port.delegate = self;
    
    self->_ssl = [[UISwitch alloc] init];

    self->_nickname = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_nickname.text = @"";
    self->_nickname.textAlignment = NSTextAlignmentRight;
    self->_nickname.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_nickname.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_nickname.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_nickname.keyboardType = UIKeyboardTypeDefault;
    self->_nickname.adjustsFontSizeToFitWidth = YES;
    self->_nickname.returnKeyType = UIReturnKeyDone;
    self->_nickname.delegate = self;
    if(name && [name isKindOfClass:[NSString class]] && name.length) {
        NSRange range = [name rangeOfString:@" "];
        if(range.location != NSNotFound && range.location > 0)
            self->_nickname.text = [[name substringToIndex:range.location] lowercaseString];
    }
    
    self->_realname = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_realname.text = @"";
    self->_realname.textAlignment = NSTextAlignmentRight;
    self->_realname.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_realname.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self->_realname.autocorrectionType = UITextAutocorrectionTypeDefault;
    self->_realname.keyboardType = UIKeyboardTypeDefault;
    self->_realname.adjustsFontSizeToFitWidth = YES;
    self->_realname.returnKeyType = UIReturnKeyDone;
    self->_realname.delegate = self;
    if(name && [name isKindOfClass:[NSString class]] && name.length) {
        self->_realname.text = name;
    }
    
    self->_nspass = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_nspass.text = @"";
    self->_nspass.textAlignment = NSTextAlignmentRight;
    self->_nspass.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_nspass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_nspass.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_nspass.keyboardType = UIKeyboardTypeDefault;
    self->_nspass.adjustsFontSizeToFitWidth = YES;
    self->_nspass.returnKeyType = UIReturnKeyDone;
    self->_nspass.delegate = self;
    self->_nspass.secureTextEntry = YES;

    self->_revealnspass = [[UISwitch alloc] init];
    [self->_revealnspass addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];

    self->_serverpass = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_serverpass.text = @"";
    self->_serverpass.textAlignment = NSTextAlignmentRight;
    self->_serverpass.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_serverpass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_serverpass.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_serverpass.keyboardType = UIKeyboardTypeDefault;
    self->_serverpass.adjustsFontSizeToFitWidth = YES;
    self->_serverpass.returnKeyType = UIReturnKeyDone;
    self->_serverpass.delegate = self;
    self->_serverpass.secureTextEntry = YES;
    
    self->_revealserverpass = [[UISwitch alloc] init];
    [self->_revealserverpass addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];

    self->_commands = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_commands.text = @"";
    self->_commands.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_commands.backgroundColor = [UIColor clearColor];
    self->_commands.delegate = self;
    self->_commands.font = self->_server.font;
    self->_commands.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_commands.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    
    self->_channels = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_channels.text = @"";
    self->_channels.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_channels.backgroundColor = [UIColor clearColor];
    self->_channels.delegate = self;
    self->_channels.font = self->_server.font;
    self->_channels.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_channels.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    
    if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"verified"] && [[[NetworkConnection sharedInstance].userInfo objectForKey:@"verified"] intValue] == 0) {
        UITextView *unverified = [[UITextView alloc] init];
        unverified.backgroundColor = [UIColor networkErrorBackgroundColor];
        unverified.textAlignment = NSTextAlignmentCenter;
        unverified.textColor = [UIColor networkErrorColor];
        unverified.font = [UIFont systemFontOfSize:FONT_SIZE];
        unverified.text = @"You can't connect to external servers until you confirm your email address.\n\nIf you're still waiting for the email, you can tap here to send yourself another confirmation.";
        unverified.tag = 1;
        unverified.editable = NO;
        unverified.userInteractionEnabled = YES;

        self.tableView.tableHeaderView = unverified;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    
    [self refresh];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(self.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPressed:)];
    }

    UILabel *unverified = (UILabel *)self.tableView.tableHeaderView;
    
    if(unverified) {
        CGSize size = [unverified sizeThatFits:self.tableView.bounds.size];
        unverified.frame = CGRectMake(0,0,self.tableView.bounds.size.width,size.height + 12);
        self.tableView.tableHeaderView = unverified;
    }
    
    [self refresh];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if(textView == self->_channels || (textView == self->_commands && _cid != -1))
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:3];
    else if(textView == self->_commands)
        self->_activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:4];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Server *s;
    
    switch(event) {
        case kIRCEventUserInfo:
            if(self.presentingViewController) {
                [self.tableView endEditing:YES];
                [self dismissViewControllerAnimated:YES completion:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            } else {
                [self refresh];
            }
            break;
        case kIRCEventMakeServer:
            s = notification.object;
            if(s.cid == self->_cid) {
                [(AppDelegate *)([UIApplication sharedApplication].delegate) showMainView:YES];
                [[NSNotificationCenter defaultCenter] removeObserver:self];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section >= 3)
        return ([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 2) + 32;
    else
        return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self->_slack)
        return 1;
    else if(self->_cid == -1)
        return 5;
    else
        return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            if(self->_slack)
                return 1;
            else
                return 4;
        case 1:
            return 2;
        case 2:
            return 4;
        case 3:
            return 1;
        case 4:
            return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"Server Settings";
        case 1:
            return @"Your Identity";
        case 2:
            return @"Passwords";
        case 3:
            return (self->_cid==-1)?@"Channels To Join":@"Commands To Run On Connect";
        case 4:
            return @"Commands To Run On Connect";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSString *identifier = [NSString stringWithFormat:@"connectioncell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.detailTextLabel.text = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    switch(indexPath.section) {
        case 0:
            switch(row) {
                case 0:
                    if(self->_cid!=-1 || _url) {
                        cell.textLabel.text = @"Name";
                        cell.accessoryView = self->_network;
                    } else {
                        cell.textLabel.text = @"Network";
                        if(self->_netname.length)
                            cell.detailTextLabel.text = self->_netname;
                        else
                            cell.detailTextLabel.text = @"Choose a Network";
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    break;
                case 1:
                    cell.textLabel.text = @"Hostname";
                    cell.accessoryView = self->_server;
                    break;
                case 2:
                    cell.textLabel.text = @"Port";
                    cell.accessoryView = self->_port;
                    break;
                case 3:
                    cell.textLabel.text = @"Secure port";
                    cell.accessoryView = self->_ssl;
                    break;
            }
            break;
        case 1:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"Nickname";
                    cell.accessoryView = self->_nickname;
                    break;
                case 1:
                    cell.textLabel.text = @"Full name (optional)";
                    cell.accessoryView = self->_realname;
                    break;
            }
            break;
        case 2:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"NickServ password";
                    cell.accessoryView = self->_nspass;
                    break;
                case 1:
                    cell.textLabel.text = @"Reveal NickServ password";
                    cell.accessoryView = self->_revealnspass;
                    break;
                case 2:
                    cell.textLabel.text = @"Server password";
                    cell.accessoryView = self->_serverpass;
                    break;
                case 3:
                    cell.textLabel.text = @"Reveal server password";
                    cell.accessoryView = self->_revealserverpass;
                    break;
            }
            break;
        case 3:
            cell.textLabel.text = nil;
            [((self->_cid==-1)?_channels:self->_commands) removeFromSuperview];
            ((self->_cid==-1)?_channels:self->_commands).frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:(self->_cid==-1)?_channels:self->_commands];
            break;
        case 4:
            cell.textLabel.text = nil;
            [self->_commands removeFromSuperview];
            self->_commands.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_commands];
            break;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self->_activeCellIndexPath = indexPath;
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    if(self->_cid == -1 && indexPath.section == 0 && indexPath.row == 0) {
        NetworkListViewController *nvc = [[NetworkListViewController alloc] initWithDelegate:self];
        nvc.selection = self->_netname;
        [self.navigationController pushViewController:nvc animated:YES];
    } else {
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryView)
            [cell.accessoryView becomeFirstResponder];
    }
}

@end
