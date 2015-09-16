//
//  PastebinsTableViewController.m
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

#import "PastebinsTableViewController.h"
#import "ColorFormatter.h"
#import "UIColor+IRCCloud.h"
#import "NetworkConnection.h"
#import "PastebinViewController.h"

#define MAX_LINES 6

@interface PastebinsTableCell : UITableViewCell {
    UILabel *_name;
    UILabel *_date;
    UILabel *_text;
}
@property (readonly) UILabel *name,*date,*text;
@end

@implementation PastebinsTableCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _name = [[UILabel alloc] init];
        _name.backgroundColor = [UIColor clearColor];
        _name.textColor = [UITableViewCell appearance].textLabelColor;
        _name.font = [UIFont boldSystemFontOfSize:FONT_SIZE];
        _name.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:_name];
        
        _date = [[UILabel alloc] init];
        _date.backgroundColor = [UIColor clearColor];
        _date.textColor = [UITableViewCell appearance].textLabelColor;
        _date.font = [UIFont systemFontOfSize:FONT_SIZE];
        _date.textAlignment = NSTextAlignmentRight;
        [self.contentView addSubview:_date];
        
        _text = [[UILabel alloc] init];
        _text.backgroundColor = [UIColor clearColor];
        _text.textColor = [UITableViewCell appearance].detailTextLabelColor;
        _text.font = [UIFont systemFontOfSize:FONT_SIZE];
        _text.lineBreakMode = NSLineBreakByTruncatingTail;
        _text.numberOfLines = 0;
        [self.contentView addSubview:_text];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = [self.contentView bounds];
    frame.origin.x = 16;
    frame.origin.y = 8;
    frame.size.width -= 20;
    frame.size.height -= 16;
    
    [_date sizeToFit];
    _date.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.size.height - FONT_SIZE - 6, _date.frame.size.width, FONT_SIZE + 6);

    if(_name.text.length) {
        _name.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width - 4, FONT_SIZE + 6);
        _text.frame = CGRectMake(frame.origin.x, _name.frame.origin.y + _name.frame.size.height, frame.size.width, frame.size.height - _date.frame.size.height - _name.frame.size.height);
    } else {
        _text.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height - _date.frame.size.height);
    }
}

-(void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end

@implementation PastebinsTableViewController

-(instancetype)init {
    self = [super initWithStyle:UITableViewStylePlain];
    if(self) {
        self.navigationItem.title = @"Pastebins";
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
        _extensions = [[NSMutableDictionary alloc] init];
        _fileTypeMap = @{
     @"ABAP":        [NSRegularExpression regularExpressionWithPattern:@"abap" options:NSRegularExpressionCaseInsensitive error:nil],
     @"ActionScript":[NSRegularExpression regularExpressionWithPattern:@"as" options:NSRegularExpressionCaseInsensitive error:nil],
     @"ADA":         [NSRegularExpression regularExpressionWithPattern:@"ada|adb" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Apache_Conf": [NSRegularExpression regularExpressionWithPattern:@"^htaccess|^htgroups|^htpasswd|^conf|htaccess|htgroups|htpasswd" options:NSRegularExpressionCaseInsensitive error:nil],
     @"AsciiDoc":    [NSRegularExpression regularExpressionWithPattern:@"asciidoc" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Assembly x86":[NSRegularExpression regularExpressionWithPattern:@"asm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"AutoHotKey":  [NSRegularExpression regularExpressionWithPattern:@"ahk" options:NSRegularExpressionCaseInsensitive error:nil],
     @"BatchFile":   [NSRegularExpression regularExpressionWithPattern:@"bat|cmd" options:NSRegularExpressionCaseInsensitive error:nil],
     @"C9Search":    [NSRegularExpression regularExpressionWithPattern:@"c9search_results" options:NSRegularExpressionCaseInsensitive error:nil],
     @"C/C++":       [NSRegularExpression regularExpressionWithPattern:@"cpp|c|cc|cxx|h|hh|hpp" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Cirru":       [NSRegularExpression regularExpressionWithPattern:@"cirru|cr" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Clojure":     [NSRegularExpression regularExpressionWithPattern:@"clj|cljs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Cobol":       [NSRegularExpression regularExpressionWithPattern:@"CBL|COB" options:NSRegularExpressionCaseInsensitive error:nil],
     @"CoffeeScript":[NSRegularExpression regularExpressionWithPattern:@"coffee|cf|cson|^Cakefile" options:NSRegularExpressionCaseInsensitive error:nil],
     @"ColdFusion":  [NSRegularExpression regularExpressionWithPattern:@"cfm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"C#":          [NSRegularExpression regularExpressionWithPattern:@"cs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"CSS":         [NSRegularExpression regularExpressionWithPattern:@"css" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Curly":       [NSRegularExpression regularExpressionWithPattern:@"curly" options:NSRegularExpressionCaseInsensitive error:nil],
     @"D":           [NSRegularExpression regularExpressionWithPattern:@"d|di" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Dart":        [NSRegularExpression regularExpressionWithPattern:@"dart" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Diff":        [NSRegularExpression regularExpressionWithPattern:@"diff|patch" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Dockerfile":  [NSRegularExpression regularExpressionWithPattern:@"^Dockerfile" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Dot":         [NSRegularExpression regularExpressionWithPattern:@"dot" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Erlang":      [NSRegularExpression regularExpressionWithPattern:@"erl|hrl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"EJS":         [NSRegularExpression regularExpressionWithPattern:@"ejs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Forth":       [NSRegularExpression regularExpressionWithPattern:@"frt|fs|ldr" options:NSRegularExpressionCaseInsensitive error:nil],
     @"FreeMarker":  [NSRegularExpression regularExpressionWithPattern:@"ftl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Gherkin":     [NSRegularExpression regularExpressionWithPattern:@"feature" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Gitignore":   [NSRegularExpression regularExpressionWithPattern:@"^.gitignore" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Glsl":        [NSRegularExpression regularExpressionWithPattern:@"glsl|frag|vert" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Go":          [NSRegularExpression regularExpressionWithPattern:@"go" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Groovy":      [NSRegularExpression regularExpressionWithPattern:@"groovy" options:NSRegularExpressionCaseInsensitive error:nil],
     @"HAML":        [NSRegularExpression regularExpressionWithPattern:@"haml" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Handlebars":  [NSRegularExpression regularExpressionWithPattern:@"hbs|handlebars|tpl|mustache" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Haskell":     [NSRegularExpression regularExpressionWithPattern:@"hs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"haXe":        [NSRegularExpression regularExpressionWithPattern:@"hx" options:NSRegularExpressionCaseInsensitive error:nil],
     @"HTML":        [NSRegularExpression regularExpressionWithPattern:@"html|htm|xhtml" options:NSRegularExpressionCaseInsensitive error:nil],
     @"HTML (Ruby)": [NSRegularExpression regularExpressionWithPattern:@"erb|rhtml|html.erb" options:NSRegularExpressionCaseInsensitive error:nil],
     @"INI":         [NSRegularExpression regularExpressionWithPattern:@"ini|conf|cfg|prefs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Jack":        [NSRegularExpression regularExpressionWithPattern:@"jack" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Jade":        [NSRegularExpression regularExpressionWithPattern:@"jade" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Java":        [NSRegularExpression regularExpressionWithPattern:@"java" options:NSRegularExpressionCaseInsensitive error:nil],
     @"JavaScript":  [NSRegularExpression regularExpressionWithPattern:@"js|jsm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"JSON":        [NSRegularExpression regularExpressionWithPattern:@"json" options:NSRegularExpressionCaseInsensitive error:nil],
     @"JSONiq":      [NSRegularExpression regularExpressionWithPattern:@"jq" options:NSRegularExpressionCaseInsensitive error:nil],
     @"JSP":         [NSRegularExpression regularExpressionWithPattern:@"jsp" options:NSRegularExpressionCaseInsensitive error:nil],
     @"JSX":         [NSRegularExpression regularExpressionWithPattern:@"jsx" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Julia":       [NSRegularExpression regularExpressionWithPattern:@"jl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LaTeX":       [NSRegularExpression regularExpressionWithPattern:@"tex|latex|ltx|bib" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LESS":        [NSRegularExpression regularExpressionWithPattern:@"less" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Liquid":      [NSRegularExpression regularExpressionWithPattern:@"liquid" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Lisp":        [NSRegularExpression regularExpressionWithPattern:@"lisp" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LiveScript":  [NSRegularExpression regularExpressionWithPattern:@"ls" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LogiQL":      [NSRegularExpression regularExpressionWithPattern:@"logic|lql" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LSL":         [NSRegularExpression regularExpressionWithPattern:@"lsl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Lua":         [NSRegularExpression regularExpressionWithPattern:@"lua" options:NSRegularExpressionCaseInsensitive error:nil],
     @"LuaPage":     [NSRegularExpression regularExpressionWithPattern:@"lp" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Lucene":      [NSRegularExpression regularExpressionWithPattern:@"lucene" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Makefile":    [NSRegularExpression regularExpressionWithPattern:@"^Makefile|^GNUmakefile|^makefile|^OCamlMakefile|make" options:NSRegularExpressionCaseInsensitive error:nil],
     @"MATLAB":      [NSRegularExpression regularExpressionWithPattern:@"matlab" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Markdown":    [NSRegularExpression regularExpressionWithPattern:@"md|markdown" options:NSRegularExpressionCaseInsensitive error:nil],
     @"MEL":         [NSRegularExpression regularExpressionWithPattern:@"mel" options:NSRegularExpressionCaseInsensitive error:nil],
     @"MySQL":       [NSRegularExpression regularExpressionWithPattern:@"mysql" options:NSRegularExpressionCaseInsensitive error:nil],
     @"MUSHCode":    [NSRegularExpression regularExpressionWithPattern:@"mc|mush" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Nix":         [NSRegularExpression regularExpressionWithPattern:@"nix" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Objective-C": [NSRegularExpression regularExpressionWithPattern:@"m|mm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"OCaml":       [NSRegularExpression regularExpressionWithPattern:@"ml|mli" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Pascal":      [NSRegularExpression regularExpressionWithPattern:@"pas|p" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Perl":        [NSRegularExpression regularExpressionWithPattern:@"pl|pm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"pgSQL":       [NSRegularExpression regularExpressionWithPattern:@"pgsql" options:NSRegularExpressionCaseInsensitive error:nil],
     @"PHP":         [NSRegularExpression regularExpressionWithPattern:@"php|phtml" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Powershell":  [NSRegularExpression regularExpressionWithPattern:@"ps1" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Prolog":      [NSRegularExpression regularExpressionWithPattern:@"plg|prolog" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Properties":  [NSRegularExpression regularExpressionWithPattern:@"properties" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Protobuf":    [NSRegularExpression regularExpressionWithPattern:@"proto" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Python":      [NSRegularExpression regularExpressionWithPattern:@"py" options:NSRegularExpressionCaseInsensitive error:nil],
     @"R":           [NSRegularExpression regularExpressionWithPattern:@"r" options:NSRegularExpressionCaseInsensitive error:nil],
     @"RDoc":        [NSRegularExpression regularExpressionWithPattern:@"Rd" options:NSRegularExpressionCaseInsensitive error:nil],
     @"RHTML":       [NSRegularExpression regularExpressionWithPattern:@"Rhtml" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Ruby":        [NSRegularExpression regularExpressionWithPattern:@"rb|ru|gemspec|rake|^Guardfile|^Rakefile|^Gemfile" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Rust":        [NSRegularExpression regularExpressionWithPattern:@"rs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SASS":        [NSRegularExpression regularExpressionWithPattern:@"sass" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SCAD":        [NSRegularExpression regularExpressionWithPattern:@"scad" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Scala":       [NSRegularExpression regularExpressionWithPattern:@"scala" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Smarty":      [NSRegularExpression regularExpressionWithPattern:@"smarty|tpl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Scheme":      [NSRegularExpression regularExpressionWithPattern:@"scm|rkt" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SCSS":        [NSRegularExpression regularExpressionWithPattern:@"scss" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SH":          [NSRegularExpression regularExpressionWithPattern:@"sh|bash|^.bashrc" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SJS":         [NSRegularExpression regularExpressionWithPattern:@"sjs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Space":       [NSRegularExpression regularExpressionWithPattern:@"space" options:NSRegularExpressionCaseInsensitive error:nil],
     @"snippets":    [NSRegularExpression regularExpressionWithPattern:@"snippets" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Soy Template":[NSRegularExpression regularExpressionWithPattern:@"soy" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SQL":         [NSRegularExpression regularExpressionWithPattern:@"sql" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Stylus":      [NSRegularExpression regularExpressionWithPattern:@"styl|stylus" options:NSRegularExpressionCaseInsensitive error:nil],
     @"SVG":         [NSRegularExpression regularExpressionWithPattern:@"svg" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Tcl":         [NSRegularExpression regularExpressionWithPattern:@"tcl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Tex":         [NSRegularExpression regularExpressionWithPattern:@"tex" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Text":        [NSRegularExpression regularExpressionWithPattern:@"txt" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Textile":     [NSRegularExpression regularExpressionWithPattern:@"textile" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Toml":        [NSRegularExpression regularExpressionWithPattern:@"toml" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Twig":        [NSRegularExpression regularExpressionWithPattern:@"twig" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Typescript":  [NSRegularExpression regularExpressionWithPattern:@"ts|typescript|str" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Vala":        [NSRegularExpression regularExpressionWithPattern:@"vala" options:NSRegularExpressionCaseInsensitive error:nil],
     @"VBScript":    [NSRegularExpression regularExpressionWithPattern:@"vbs" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Velocity":    [NSRegularExpression regularExpressionWithPattern:@"vm" options:NSRegularExpressionCaseInsensitive error:nil],
     @"Verilog":     [NSRegularExpression regularExpressionWithPattern:@"v|vh|sv|svh" options:NSRegularExpressionCaseInsensitive error:nil],
     @"XML":         [NSRegularExpression regularExpressionWithPattern:@"xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl" options:NSRegularExpressionCaseInsensitive error:nil],
     @"XQuery":      [NSRegularExpression regularExpressionWithPattern:@"xq" options:NSRegularExpressionCaseInsensitive error:nil],
     @"YAML":        [NSRegularExpression regularExpressionWithPattern:@"yaml|yml" options:NSRegularExpressionCaseInsensitive error:nil]
                         };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor = [[UITableViewCell appearance] backgroundColor];
    self.navigationController.navigationBar.clipsToBounds = YES;
    _url_template = [CSURITemplate URITemplateWithString:[[NetworkConnection sharedInstance].config objectForKey:@"pastebin_uri_template"] error:nil];
    
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,64,64)];
    _footerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    a.center = _footerView.center;
    a.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [a startAnimating];
    [_footerView addSubview:a];
    
    self.tableView.tableFooterView = _footerView;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _pages = 0;
    _pastes = nil;
    _canLoadMore = YES;
    [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
}

-(void)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.isEditing animated:YES];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:self.tableView.isEditing?UIBarButtonSystemItemCancel:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
}

-(void)doneButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
    _pastes = nil;
    _canLoadMore = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o;
    int reqid;
    
    switch(event) {
        case kIRCEventFailureMsg:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid) {
                CLS_LOG(@"Error deleting pastebin: %@", o);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to delete pastebin, please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
                _pages = 0;
                _pastes = nil;
                _canLoadMore = YES;
                [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
            }
            break;
        case kIRCEventSuccess:
            o = notification.object;
            reqid = [[o objectForKey:@"_reqid"] intValue];
            if(reqid == _reqid)
                CLS_LOG(@"Pastebin deleted successfully");
            break;
        default:
            break;
    }
}

-(void)setFooterView:(UIView *)v {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.tableView.tableFooterView = v;
    }];
}

-(void)_loadMore {
    NSDictionary *d = [[NetworkConnection sharedInstance] getPastebins:++_pages];
    if([[d objectForKey:@"success"] boolValue]) {
        CLS_LOG(@"Loaded pastebin list for page %i", _pages);
        if(_pastes)
            _pastes = [_pastes arrayByAddingObjectsFromArray:[d objectForKey:@"pastebins"]];
        else
            _pastes = [d objectForKey:@"pastebins"];
        
        _canLoadMore = _pastes.count < [[d objectForKey:@"total"] intValue];
        [self setFooterView:_canLoadMore?_footerView:nil];
        if(!_pastes.count) {
            CLS_LOG(@"Pastebin list is empty");
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nYou haven't created any pastebins yet.\n";
            fail.numberOfLines = 3;
            fail.textAlignment = NSTextAlignmentCenter;
            fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [fail sizeToFit];
            [self setFooterView:fail];
        }
    } else {
        CLS_LOG(@"Failed to load pastebin list for page %i: %@", _pages, d);
        _canLoadMore = NO;
        UILabel *fail = [[UILabel alloc] init];
        fail.text = @"\nUnable to load pastebins.\nPlease try again later.\n";
        fail.numberOfLines = 4;
        fail.textAlignment = NSTextAlignmentCenter;
        fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [fail sizeToFit];
        [self setFooterView:fail];
        return;
    }

    [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)fileType:(NSString *)extension {
    if([_extensions objectForKey:extension.lowercaseString])
        return [_extensions objectForKey:extension.lowercaseString];
    
    if(extension.length) {
        NSRange range = NSMakeRange(0, extension.length);
        for(NSString *type in _fileTypeMap.allKeys) {
            NSRegularExpression *regex = [_fileTypeMap objectForKey:type];
            NSArray *matches = [regex matchesInString:extension options:NSMatchingAnchored range:range];
            for(NSTextCheckingResult *result in matches) {
                if(result.range.location == 0 && result.range.length == range.length) {
                    [_extensions setObject:type forKey:extension.lowercaseString];
                    return type;
                }
            }
        }
    }
    return @"Text";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _pastes.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return FONT_SIZE + 24 + ([[[_pastes objectAtIndex:indexPath.row] objectForKey:@"body"] boundingRectWithSize:CGRectMake(0,0,self.tableView.frame.size.width - 26,(FONT_SIZE + 4) * MAX_LINES).size options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:FONT_SIZE]} context:nil].size.height) + ([[[_pastes objectAtIndex:indexPath.row] objectForKey:@"name"] length]?(FONT_SIZE + 6):0);
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(_pastes.count && _canLoadMore) {
        NSArray *rows = [self.tableView indexPathsForRowsInRect:UIEdgeInsetsInsetRect(self.tableView.bounds, self.tableView.contentInset)];
        
        if([[rows lastObject] row] >= _pastes.count - 5) {
            _canLoadMore = NO;
            [self performSelectorInBackground:@selector(_loadMore) withObject:nil];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PastebinsTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pastebincell"];
    if(!cell)
        cell = [[PastebinsTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pastebincell"];

    NSDictionary *pastebin = [_pastes objectAtIndex:indexPath.row];
    
    NSString *date = nil;
    double seconds = [[NSDate date] timeIntervalSince1970] - [[pastebin objectForKey:@"date"] doubleValue];
    double minutes = seconds / 60.0;
    double hours = minutes / 60.0;
    double days = hours / 24.0;
    double months = days / 31.0;
    double years = months / 12.0;
    
    if(years >= 1) {
        if(years - (int)years > 0.5)
            years++;
        
        if((int)years == 1)
            date = [NSString stringWithFormat:@"%i year ago", (int)years];
        else
            date = [NSString stringWithFormat:@"%i years ago", (int)years];
    } else if(months >= 1) {
        if(months - (int)months > 0.5)
            months++;
        
        if((int)months == 1)
            date = [NSString stringWithFormat:@"%i month ago", (int)months];
        else
            date = [NSString stringWithFormat:@"%i months ago", (int)months];
    } else if(days >= 1) {
        if(days - (int)days > 0.5)
            days++;
        
        if((int)days == 1)
            date = [NSString stringWithFormat:@"%i day ago", (int)days];
        else
            date = [NSString stringWithFormat:@"%i days ago", (int)days];
    } else if(hours >= 1) {
        if(hours - (int)hours > 0.5)
            hours++;
        
        if((int)hours < 2)
            date = [NSString stringWithFormat:@"%i hour ago", (int)hours];
        else
            date = [NSString stringWithFormat:@"%i hours ago", (int)hours];
    } else if(minutes >= 1) {
        if(minutes - (int)minutes > 0.5)
            minutes++;
        
        if((int)minutes == 1)
            date = [NSString stringWithFormat:@"%i minute ago", (int)minutes];
        else
            date = [NSString stringWithFormat:@"%i minutes ago", (int)minutes];
    } else {
        if((int)seconds == 1)
            date = [NSString stringWithFormat:@"%i second ago", (int)seconds];
        else
            date = [NSString stringWithFormat:@"%i seconds ago", (int)seconds];
    }

    cell.name.text = [pastebin objectForKey:@"name"];
    cell.date.text = [NSString stringWithFormat:@"%@ • %@ line%@ • %@", date, [pastebin objectForKey:@"lines"], ([[pastebin objectForKey:@"lines"] intValue] == 1)?@"":@"s", [self fileType:[pastebin objectForKey:@"extension"]]];
    cell.text.text = [pastebin objectForKey:@"body"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    [cell layoutSubviews];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        _reqid = [[NetworkConnection sharedInstance] deletePaste:[[_pastes objectAtIndex:indexPath.row] objectForKey:@"id"]];
        NSMutableArray *a = _pastes.mutableCopy;
        [a removeObjectAtIndex:indexPath.row];
        _pastes = [NSArray arrayWithArray:a];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        if(!_pastes.count) {
            UILabel *fail = [[UILabel alloc] init];
            fail.text = @"\nYou haven't created any pastebins yet.\n";
            fail.numberOfLines = 3;
            fail.textAlignment = NSTextAlignmentCenter;
            fail.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [fail sizeToFit];
            self.tableView.tableFooterView = fail;
        }
        [self scrollViewDidScroll:self.tableView];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _selectedPaste = [_pastes objectAtIndex:indexPath.row];
    if(_selectedPaste) {
        NSString *url = [_url_template relativeStringWithVariables:_selectedPaste error:nil];
        url = [url stringByAppendingFormat:@"?id=%@&own_paste=%@", [_selectedPaste objectForKey:@"id"], [_selectedPaste objectForKey:@"own_paste"]];
        PastebinViewController *c = [[PastebinViewController alloc] initWithURL:[NSURL URLWithString:url]];
        [self.navigationController pushViewController:c animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
