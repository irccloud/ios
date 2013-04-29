//
//  EditConnectionViewController.m
//  IRCCloud
//
//  Created by Sam Steele on 4/29/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "EditConnectionViewController.h"
#import "NetworkConnection.h"

@implementation EditConnectionViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        _cid = -1;
        self.navigationItem.title = @"New Connection";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
        if([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPhone) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        }
    }
    return self;
}

-(void)saveButtonPressed:(id)sender {
    if(_cid != -1) {
        _reqid = [[NetworkConnection sharedInstance] editServer:_cid hostname:_server.text port:[_port.text intValue] ssl:(_ssl.on)?1:0 netname:_netname nick:_nickname.text realname:_realname.text serverPass:_serverpass.text nickservPass:_nspass.text joinCommands:_commands.text];
        //TODO: check the response
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
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

    int padding = 80;
    
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        padding = 26;
        
    _server = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _server.placeholder = @"irc.example.net";
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
    _nickname.textAlignment = NSTextAlignmentRight;
    _nickname.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _nickname.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _nickname.autocorrectionType = UITextAutocorrectionTypeNo;
    _nickname.keyboardType = UIKeyboardTypeDefault;
    _nickname.adjustsFontSizeToFitWidth = YES;
    _nickname.returnKeyType = UIReturnKeyDone;
    _nickname.delegate = self;
    
    _realname = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
    _realname.placeholder = @"John Appleseed";
    _realname.textAlignment = NSTextAlignmentRight;
    _realname.textColor = [UIColor colorWithRed:56.0f/255.0f green:84.0f/255.0f blue:135.0f/255.0f alpha:1.0f];
    _realname.autocapitalizationType = UITextAutocapitalizationTypeWords;
    _realname.autocorrectionType = UITextAutocorrectionTypeDefault;
    _realname.keyboardType = UIKeyboardTypeDefault;
    _realname.adjustsFontSizeToFitWidth = YES;
    _realname.returnKeyType = UIReturnKeyDone;
    _realname.delegate = self;
    
    _nspass = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width / 2 - padding, 22)];
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
            return 3;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"connectioncell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"connectioncell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    switch(indexPath.section) {
        case 0:
            switch(indexPath.row) {
                case 0:
                    cell.textLabel.text = @"Hostname";
                    cell.accessoryView = _server;
                    break;
                case 1:
                    cell.textLabel.text = @"Port";
                    cell.accessoryView = _port;
                    break;
                case 2:
                    cell.textLabel.text = @"Use SSL";
                    cell.accessoryView = _ssl;
                    break;
            }
            break;
        case 1:
            switch(indexPath.row) {
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
            switch(indexPath.row) {
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
}

@end
