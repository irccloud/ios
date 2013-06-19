//
//  EditConnectionViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 4/29/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "EditConnectionViewController.h"
#import "NetworkConnection.h"

@interface NetworkListViewController : UITableViewController {
    id<NetworkListDelegate> _delegate;
    NSString *_selection;
}
@property (nonatomic) NSString *selection;
-(id)initWithDelegate:(id)delegate;
@end

@implementation NetworkListViewController

-(id)initWithDelegate:(id)delegate {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _delegate = delegate;
        self.navigationItem.title = @"Networks";
    }
    return self;
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
    return 21;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"networkcell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"networkcell"];
    

    switch(indexPath.row) {
        case 0:
            cell.textLabel.text = @"IRCCloud";
            break;
        case 1:
            cell.textLabel.text = @"Freenode";
            break;
        case 2:
            cell.textLabel.text = @"QuakeNet";
            break;
        case 3:
            cell.textLabel.text = @"IRCNet";
            break;
        case 4:
            cell.textLabel.text = @"Undernet";
            break;
        case 5:
            cell.textLabel.text = @"DALNet";
            break;
        case 6:
            cell.textLabel.text = @"OFTC";
            break;
        case 7:
            cell.textLabel.text = @"GameSurge";
            break;
        case 8:
            cell.textLabel.text = @"Efnet";
            break;
        case 9:
            cell.textLabel.text = @"Mozilla";
            break;
        case 10:
            cell.textLabel.text = @"Rizon";
            break;
        case 11:
            cell.textLabel.text = @"Espernet";
            break;
        case 12:
            cell.textLabel.text = @"ReplayIRC";
            break;
        case 13:
            cell.textLabel.text = @"synIRC";
            break;
        case 14:
            cell.textLabel.text = @"fossnet";
            break;
        case 15:
            cell.textLabel.text = @"P2P-NET";
            break;
        case 16:
            cell.textLabel.text = @"euIRCnet";
            break;
        case 17:
            cell.textLabel.text = @"SlashNET";
            break;
        case 18:
            cell.textLabel.text = @"Atrum";
            break;
        case 19:
            cell.textLabel.text = @"Indymedia";
            break;
        case 20:
            cell.textLabel.text = @"TWiT";
            break;
    }
    
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
    switch(indexPath.row) {
        case 0:
            [_delegate setNetwork:@"IRCCloud" host:@"irc.irccloud.com" port:6667 SSL:NO];
            break;
        case 1:
            [_delegate setNetwork:@"Freenode" host:@"irc.freenode.net" port:6697 SSL:YES];
            break;
        case 2:
            [_delegate setNetwork:@"QuakeNet" host:@"irc.quakenet.org" port:6667 SSL:NO];
            break;
        case 3:
            [_delegate setNetwork:@"IRCNet" host:@"irc.otw-inter.net" port:6667 SSL:NO];
            break;
        case 4:
            [_delegate setNetwork:@"Undernet" host:@"irc.undernet.org" port:6667 SSL:NO];
            break;
        case 5:
            [_delegate setNetwork:@"DALNet" host:@"irc.dal.net" port:6667 SSL:NO];
            break;
        case 6:
            [_delegate setNetwork:@"OFTC" host:@"irc.oftc.net" port:6667 SSL:NO];
            break;
        case 7:
            [_delegate setNetwork:@"GameSurge" host:@"irc.gamesurge.net" port:6667 SSL:NO];
            break;
        case 8:
            [_delegate setNetwork:@"Efnet" host:@"efnet.xs4all.nl" port:6667 SSL:NO];
            break;
        case 9:
            [_delegate setNetwork:@"Mozilla" host:@"irc.mozilla.org" port:6697 SSL:YES];
            break;
        case 10:
            [_delegate setNetwork:@"Rizon" host:@"irc6.rizon.net" port:6697 SSL:YES];
            break;
        case 11:
            [_delegate setNetwork:@"Espernet" host:@"irc.esper.net" port:6667 SSL:NO];
            break;
        case 12:
            [_delegate setNetwork:@"ReplayIRC" host:@"irc.replayirc.com" port:6667 SSL:NO];
            break;
        case 13:
            [_delegate setNetwork:@"synIRC" host:@"naamia.fl.eu.synirc.net" port:6697 SSL:YES];
            break;
        case 14:
            [_delegate setNetwork:@"fossnet" host:@"irc.fossnet.info" port:6697 SSL:YES];
            break;
        case 15:
            [_delegate setNetwork:@"P2P-NET" host:@"irc.p2p-network.net" port:6697 SSL:YES];
            break;
        case 16:
            [_delegate setNetwork:@"euIRCnet" host:@"irc.euirc.net" port:6697 SSL:YES];
            break;
        case 17:
            [_delegate setNetwork:@"SlashNET" host:@"irc.slashnet.org" port:6697 SSL:YES];
            break;
        case 18:
            [_delegate setNetwork:@"Atrum" host:@"irc.atrum.org" port:6697 SSL:YES];
            break;
        case 19:
            [_delegate setNetwork:@"Indymedia" host:@"irc.indymedia.org" port:6697 SSL:YES];
            break;
        case 20:
            [_delegate setNetwork:@"TWiT" host:@"irc.twit.tv" port:6697 SSL:YES];
            break;
    }
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
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    }
    return self;
}

-(void)saveButtonPressed:(id)sender {
    if(_cid == -1) {
        _reqid = [[NetworkConnection sharedInstance] addServer:_server.text port:[_port.text intValue] ssl:(_ssl.on)?1:0 netname:_netname nick:_nickname.text realname:_realname.text serverPass:_serverpass.text nickservPass:_nspass.text joinCommands:_commands.text channels:@""];
        //TODO: check the response
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        _reqid = [[NetworkConnection sharedInstance] editServer:_cid hostname:_server.text port:[_port.text intValue] ssl:(_ssl.on)?1:0 netname:_netname nick:_nickname.text realname:_realname.text serverPass:_serverpass.text nickservPass:_nspass.text joinCommands:_commands.text];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)cancelButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)setServer:(int)cid {
    self.navigationItem.title = @"Edit Connection";
    _cid = cid;
    [self refresh];
}

-(void)setNetwork:(NSString *)network host:(NSString *)host port:(int)port SSL:(BOOL)SSL {
    _netname = network;
    _server.text = host;
    _port.text = [NSString stringWithFormat:@"%i", port];
    _ssl.on = SSL;
    [self.tableView reloadData];
}


-(void)refresh {
    Server *server = [[ServersDataSource sharedInstance] getServer:_cid];
    if(server) {
        _netname = server.name;
        
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

- (void)viewDidLoad {
    [super viewDidLoad];

    NSDictionary *userInfo = [NetworkConnection sharedInstance].userInfo;
    NSString *name = [userInfo objectForKey:@"name"];
    int padding = 80;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        padding = 26;
        
    _server = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _server.placeholder = @"irc.example.net";
    _server.text = @"";
    _server.textAlignment = NSTextAlignmentRight;
    _server.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _server.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _server.autocorrectionType = UITextAutocorrectionTypeNo;
    _server.keyboardType = UIKeyboardTypeURL;
    _server.adjustsFontSizeToFitWidth = YES;
    _server.returnKeyType = UIReturnKeyDone;
    _server.delegate = self;
    
    _port = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _port.text = @"6667";
    _port.textAlignment = NSTextAlignmentRight;
    _port.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _port.keyboardType = UIKeyboardTypeNumberPad;
    _port.returnKeyType = UIReturnKeyDone;
    _port.delegate = self;
    
    _ssl = [[UISwitch alloc] init];
    
    _nickname = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _nickname.placeholder = @"john";
    _nickname.text = @"";
    _nickname.textAlignment = NSTextAlignmentRight;
    _nickname.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
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
    
    _realname = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _realname.placeholder = @"John Appleseed";
    _realname.text = @"";
    _realname.textAlignment = NSTextAlignmentRight;
    _realname.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _realname.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _realname.autocorrectionType = UITextAutocorrectionTypeDefault;
    _realname.keyboardType = UIKeyboardTypeDefault;
    _realname.adjustsFontSizeToFitWidth = YES;
    _realname.returnKeyType = UIReturnKeyDone;
    _realname.delegate = self;
    if(name && [name isKindOfClass:[NSString class]] && name.length) {
        _realname.text = name;
    }
    
    _nspass = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _nspass.text = @"";
    _nspass.textAlignment = NSTextAlignmentRight;
    _nspass.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _nspass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _nspass.autocorrectionType = UITextAutocorrectionTypeNo;
    _nspass.keyboardType = UIKeyboardTypeDefault;
    _nspass.adjustsFontSizeToFitWidth = YES;
    _nspass.returnKeyType = UIReturnKeyDone;
    _nspass.delegate = self;
    _nspass.secureTextEntry = YES;

    _serverpass = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _serverpass.text = @"";
    _serverpass.textAlignment = NSTextAlignmentRight;
    _serverpass.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _serverpass.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _serverpass.autocorrectionType = UITextAutocorrectionTypeNo;
    _serverpass.keyboardType = UIKeyboardTypeDefault;
    _serverpass.adjustsFontSizeToFitWidth = YES;
    _serverpass.returnKeyType = UIReturnKeyDone;
    _serverpass.delegate = self;
    _serverpass.secureTextEntry = YES;

    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        _commands = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width - padding, 70)];
    else
        _commands = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width - 280, 70)];
    _commands.text = @"";
    _commands.backgroundColor = [UIColor clearColor];
    
    [self refresh];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.tableView endEditing:YES];
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 3)
        return 80;
    else
        return 48;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case 0:
            return (_cid==-1)?4:3;
        case 1:
            return 2;
        case 2:
            return 2;
        case 3:
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
            return @"Commands To Run On Connect";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int row = indexPath.row;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"connectioncell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"connectioncell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch(indexPath.section) {
        case 0:
            if(_cid!=-1)
                row++;
            switch(row) {
                case 0:
                    cell.textLabel.text = @"Network";
                    if(_netname.length)
                        cell.detailTextLabel.text = _netname;
                    else
                        cell.detailTextLabel.text = @"Choose a Network";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
            cell.accessoryView = _commands;
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
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    if(_cid == -1 && indexPath.section == 0 && indexPath.row == 0) {
        NetworkListViewController *nvc = [[NetworkListViewController alloc] initWithDelegate:self];
        nvc.selection = _netname;
        [self.navigationController pushViewController:nvc animated:YES];
    }
}

@end
