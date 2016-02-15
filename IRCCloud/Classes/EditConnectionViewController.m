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
#import "SBJson.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "FontAwesome.h"

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
        _delegate = delegate;
        self.navigationItem.title = @"Networks";
        [self fetchServerList];
    }
    return self;
}
         
- (void)fetchServerList
{
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    _activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    _activityIndicator.center = (CGPoint){(self.view.bounds.size.width * 0.5), (self.view.bounds.size.height * 0.5)};
    [_activityIndicator startAnimating];
    [self.view addSubview:_activityIndicator];

#ifdef DEBUG
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
#endif
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:NetworksListLink]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching remote networks list, falling back to default. Error %li : %@", (long)error.code, error.userInfo);
            
            _networks = @[
                          @{@"network":@"IRCCloud", @"host":@"irc.irccloud.com", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"Freenode", @"host":@"irc.freenode.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"QuakeNet", @"host":@"blacklotus.ca.us.quakenet.org", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"IRCNet", @"host":@"ircnet.blacklotus.net", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"Undernet", @"host":@"losangeles.ca.us.undernet.org", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"DALNet", @"host":@"irc.dal.net", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"OFTC", @"host":@"irc.oftc.net", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"GameSurge", @"host":@"irc.gamesurge.net", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"Efnet", @"host":@"efnet.port80.se", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"Mozilla", @"host":@"irc.mozilla.org", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Rizon", @"host":@"irc6.rizon.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Espernet", @"host":@"irc.esper.net", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"ReplayIRC", @"host":@"irc.replayirc.com", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"synIRC", @"host":@"naamia.fl.eu.synirc.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"fossnet", @"host":@"irc.fossnet.info", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"P2P-NET", @"host":@"irc.p2p-network.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"euIRCnet", @"host":@"irc.euirc.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"SlashNET", @"host":@"irc.slashnet.org", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Atrum", @"host":@"irc.atrum.org", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Indymedia", @"host":@"irc.indymedia.org", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"TWiT", @"host":@"irc.twit.tv", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Snoonet", @"host":@"irc.snoonet.org", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"BrasIRC", @"host":@"irc.brasirc.org", @"port":@(6667), @"SSL":@(NO)},
                          @{@"network":@"darkscience", @"host":@"irc.darkscience.net", @"port":@(6697), @"SSL":@(YES)},
                          @{@"network":@"Techman's World", @"host":@"irc.techmansworld.com", @"port":@(6697), @"SSL":@(YES)}
                          ];
        }
        else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
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
            _networks = networks;
        }
        
        [_activityIndicator stopAnimating];
        [_activityIndicator removeFromSuperview];
        
        [self.tableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_networks count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"networkcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"networkcell"];
    
    NSDictionary *row = [_networks objectAtIndex:indexPath.row];
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
    
    if([_selection isEqualToString:cell.textLabel.text])
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
    _selection = [self tableView:tableView cellForRowAtIndexPath:indexPath].textLabel.text;
    [tableView reloadData];
    NSDictionary *row = [_networks objectAtIndex:indexPath.row];
    [_delegate setNetwork:[row objectForKey:@"network"] host:[row objectForKey:@"host"] port:[[row objectForKey:@"port"] intValue] SSL:[[row objectForKey:@"SSL"] boolValue]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end

@implementation EditConnectionViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _cid = -1;
        self.navigationItem.title = @"New Connection";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
    }
    return self;
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
    if(_activeCellIndexPath) {
        [self.tableView scrollToRowAtIndexPath:_activeCellIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
//        [self.tableView selectRowAtIndexPath:_activeCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
    }
}

-(void)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    if(_cid == -1) {
        _reqid = [[NetworkConnection sharedInstance] addServer:_server.text port:[_port.text intValue] ssl:(_ssl.on)?1:0 netname:_netname nick:_nickname.text realname:_realname.text serverPass:_serverpass.text nickservPass:_nspass.text joinCommands:_commands.text channels:_channels.text];
    } else {
        _netname = _network.text;
        if([_netname.lowercaseString isEqualToString:_server.text.lowercaseString])
            _netname = nil;
        _reqid = [[NetworkConnection sharedInstance] editServer:_cid hostname:_server.text port:[_port.text intValue] ssl:(_ssl.on)?1:0 netname:_netname nick:_nickname.text realname:_realname.text serverPass:_serverpass.text nickservPass:_nspass.text joinCommands:_commands.text];
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
    _cid = cid;
    [self refresh];
}

-(void)setNetwork:(NSString *)network host:(NSString *)host port:(int)port SSL:(BOOL)SSL {
    _network.text = _netname = network;
    _server.text = host;
    _port.text = [NSString stringWithFormat:@"%i", port];
    _ssl.on = SSL;
    [self.tableView reloadData];
}

-(void)setURL:(NSURL *)url {
    _url = url;
    _network.text = _netname = url.host;
    [self refresh];
}

-(void)refresh {
    if(_url) {
        int port = [_url.port intValue];
        int ssl = [_url.scheme hasSuffix:@"s"]?1:0;
        if(port == 0)
            port = (ssl == 1)?6697:6667;
        
        _server.text = _url.host;
        _port.text = [NSString stringWithFormat:@"%i", port];
        if(ssl == 1)
            _ssl.on = YES;
        else
            _ssl.on = NO;
        
        if(_url.path && _url.path.length > 1)
            _channels.text = [_url.path substringFromIndex:1];
    } else {
        Server *server = [[ServersDataSource sharedInstance] getServer:_cid];
        if(server) {
            _network.text = _netname = server.name;
            if(_netname.length == 0)
                _network.text = _netname = server.hostname;
            
            if([server.hostname isKindOfClass:[NSString class]] && server.hostname.length)
                _server.text = server.hostname;
            else
                _server.text = @"";
            
            _port.text = [NSString stringWithFormat:@"%i", server.port];
            
            _ssl.on = (server.ssl > 0);

            if([server.nick isKindOfClass:[NSString class]] && server.nick.length)
                _nickname.text = server.nick;
            else
                _nickname.text = @"";
            
            if([server.realname isKindOfClass:[NSString class]] && server.realname.length)
                _realname.text = server.realname;
            else
                _realname.text = @"";
            
            if([server.nickserv_pass isKindOfClass:[NSString class]] && server.nickserv_pass.length)
                _nspass.text = server.nickserv_pass;
            else
                _nspass.text = @"";
            
            if([server.server_pass isKindOfClass:[NSString class]] && server.server_pass.length)
                _serverpass.text = server.server_pass;
            else
                _serverpass.text = @"";
            
            if([server.join_commands isKindOfClass:[NSString class]] && server.join_commands.length)
                _commands.text = server.join_commands;
            else
                _commands.text = @"";
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if(textField == _server)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    else if(textField == _port)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    if(textField == _nickname)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    if(textField == _realname)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    if(textField == _nspass)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:2];
    if(textField == _serverpass)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:1 inSection:2];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(touch.view.tag == 1) {
        [[NetworkConnection sharedInstance] resendVerifyEmail];
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Confirmation Sent" message:@"You should shortly receive an email with a link to confirm your address." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
        [av show];
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

    if(self.presentingViewController) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logoutButtonPressed:)];
    }
    NSDictionary *userInfo = [NetworkConnection sharedInstance].userInfo;
    NSString *name = [userInfo objectForKey:@"name"];
    
    self.navigationController.navigationBar.clipsToBounds = YES;

    _network = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _network.placeholder = @"Network";
    _network.text = @"";
    _network.textAlignment = NSTextAlignmentRight;
    _network.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _network.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _network.autocorrectionType = UITextAutocorrectionTypeNo;
    _network.keyboardType = UIKeyboardTypeDefault;
    _network.adjustsFontSizeToFitWidth = YES;
    _network.returnKeyType = UIReturnKeyDone;
    _network.delegate = self;
    
    _server = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _server.placeholder = @"irc.example.net";
    _server.text = @"";
    _server.textAlignment = NSTextAlignmentRight;
    _server.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _server.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _server.autocorrectionType = UITextAutocorrectionTypeNo;
    _server.keyboardType = UIKeyboardTypeURL;
    _server.adjustsFontSizeToFitWidth = YES;
    _server.returnKeyType = UIReturnKeyDone;
    _server.delegate = self;
    
    _port = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _port.text = @"6667";
    _port.textAlignment = NSTextAlignmentRight;
    _port.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _port.keyboardType = UIKeyboardTypeNumberPad;
    _port.returnKeyType = UIReturnKeyDone;
    _port.delegate = self;
    
    _ssl = [[UISwitch alloc] init];
    
    _nickname = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _nickname.placeholder = @"john";
    _nickname.text = @"";
    _nickname.textAlignment = NSTextAlignmentRight;
    _nickname.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _nickname.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _nickname.autocorrectionType = UITextAutocorrectionTypeNo;
    _nickname.keyboardType = UIKeyboardTypeDefault;
    _nickname.adjustsFontSizeToFitWidth = YES;
    _nickname.returnKeyType = UIReturnKeyDone;
    _nickname.delegate = self;
    if(name && [name isKindOfClass:[NSString class]] && name.length) {
        NSRange range = [name rangeOfString:@" "];
        if(range.location != NSNotFound && range.location > 0)
            _nickname.text = [[name substringToIndex:range.location] lowercaseString];
    }
    
    _realname = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _realname.placeholder = @"John Appleseed";
    _realname.text = @"";
    _realname.textAlignment = NSTextAlignmentRight;
    _realname.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _realname.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _realname.autocorrectionType = UITextAutocorrectionTypeDefault;
    _realname.keyboardType = UIKeyboardTypeDefault;
    _realname.adjustsFontSizeToFitWidth = YES;
    _realname.returnKeyType = UIReturnKeyDone;
    _realname.delegate = self;
    if(name && [name isKindOfClass:[NSString class]] && name.length) {
        _realname.text = name;
    }
    
    _nspass = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _nspass.text = @"";
    _nspass.textAlignment = NSTextAlignmentRight;
    _nspass.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _nspass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _nspass.autocorrectionType = UITextAutocorrectionTypeNo;
    _nspass.keyboardType = UIKeyboardTypeDefault;
    _nspass.adjustsFontSizeToFitWidth = YES;
    _nspass.returnKeyType = UIReturnKeyDone;
    _nspass.delegate = self;
    _nspass.secureTextEntry = YES;

    _serverpass = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2, 22)];
    _serverpass.text = @"";
    _serverpass.textAlignment = NSTextAlignmentRight;
    _serverpass.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _serverpass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _serverpass.autocorrectionType = UITextAutocorrectionTypeNo;
    _serverpass.keyboardType = UIKeyboardTypeDefault;
    _serverpass.adjustsFontSizeToFitWidth = YES;
    _serverpass.returnKeyType = UIReturnKeyDone;
    _serverpass.delegate = self;
    _serverpass.secureTextEntry = YES;

    _commands = [[UITextView alloc] initWithFrame:CGRectZero];
    _commands.text = @"";
    _commands.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _commands.backgroundColor = [UIColor clearColor];
    _commands.delegate = self;
    _commands.font = _server.font;
    _commands.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _commands.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    
    _channels = [[UITextView alloc] initWithFrame:CGRectZero];
    _channels.text = @"";
    _channels.textColor = [UITableViewCell appearance].detailTextLabelColor;
    _channels.backgroundColor = [UIColor clearColor];
    _channels.delegate = self;
    _channels.font = _server.font;
    _channels.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _channels.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    
    if([NetworkConnection sharedInstance].userInfo && [[NetworkConnection sharedInstance].userInfo objectForKey:@"verified"] && [[[NetworkConnection sharedInstance].userInfo objectForKey:@"verified"] intValue] == 0) {
        UILabel *unverified = [[UILabel alloc] init];
        unverified.backgroundColor = [UIColor clearColor];
        unverified.textAlignment = NSTextAlignmentCenter;
        unverified.numberOfLines = 0;
        unverified.textColor = [UIColor messageTextColor];
        unverified.text = @"\nYou can't connect to external servers until you confirm your email address.\n\nIf you're still waiting for the email, you can tap here to send yourself another confirmation.";
        unverified.tag = 1;
        unverified.userInteractionEnabled = YES;
        CGSize size = [unverified sizeThatFits:self.tableView.bounds.size];
        unverified.frame = CGRectMake(0,0,self.tableView.bounds.size.width,size.height + 12);

        self.tableView.tableHeaderView = unverified;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    
    [self refresh];
}

-(void)finalize {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if(textView == _channels || (textView == _commands && _cid != -1))
        _activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:3];
    else if(textView == _commands)
        _activeCellIndexPath = [NSIndexPath indexPathForRow:0 inSection:4];
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
    IRCCloudJSONObject *o;
    Server *s;
    int reqid;
    
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
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                NSString *msg = [o objectForKey:@"message"];
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
                } else if([msg isEqualToString:@"unverified"]) {
                    msg = @"You can’t connect to external servers until you confirm your email address";
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                if(self.presentingViewController) {
                    [self.tableView endEditing:YES];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                } else {
                    _cid = [[o objectForKey:@"cid"] intValue];
                }
            }
            break;
        case kIRCEventMakeServer:
            s = notification.object;
            if(s.cid == _cid) {
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
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (_cid==-1)?5:4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return 4;
        case 1:
            return 2;
        case 2:
            return 2;
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
            return (_cid==-1)?@"Channels To Join":@"Commands To Run On Connect";
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
                    if(_cid!=-1 || _url) {
                        cell.textLabel.text = @"Network";
                        cell.accessoryView = _network;
                    } else {
                        cell.textLabel.text = @"Network";
                        if(_netname.length)
                            cell.detailTextLabel.text = _netname;
                        else
                            cell.detailTextLabel.text = @"Choose a Network";
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    break;
                case 1:
                    cell.textLabel.text = @"Hostname";
                    cell.accessoryView = _server;
                    break;
                case 2:
                    cell.textLabel.text = @"Port";
                    cell.accessoryView = _port;
                    break;
                case 3:
                    cell.textLabel.text = @"Use SSL";
                    cell.accessoryView = _ssl;
                    break;
            }
            break;
        case 1:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"Nickname";
                    cell.accessoryView = _nickname;
                    break;
                case 1:
                    cell.textLabel.text = @"Real name";
                    cell.accessoryView = _realname;
                    break;
            }
            break;
        case 2:
            switch(row) {
                case 0:
                    cell.textLabel.text = @"NickServ";
                    cell.accessoryView = _nspass;
                    break;
                case 1:
                    cell.textLabel.text = @"Server";
                    cell.accessoryView = _serverpass;
                    break;
            }
            break;
        case 3:
            cell.textLabel.text = nil;
            [((_cid==-1)?_channels:_commands) removeFromSuperview];
            ((_cid==-1)?_channels:_commands).frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:(_cid==-1)?_channels:_commands];
            break;
        case 4:
            cell.textLabel.text = nil;
            [_commands removeFromSuperview];
            _commands.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:_commands];
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
    _activeCellIndexPath = indexPath;
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    if(_cid == -1 && indexPath.section == 0 && indexPath.row == 0) {
        NetworkListViewController *nvc = [[NetworkListViewController alloc] initWithDelegate:self];
        nvc.selection = _netname;
        [self.navigationController pushViewController:nvc animated:YES];
    } else {
        UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryView)
            [cell.accessoryView becomeFirstResponder];
    }
}

@end
