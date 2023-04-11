//
//  PastebinEditorViewController.m
//
//  Copyright (C) 2015 IRCCloud, Ltd.
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

#import "PastebinEditorViewController.h"
#import "NetworkConnection.h"
#import "CSURITemplate.h"
#import "UIColor+IRCCloud.h"
#import "AppDelegate.h"

@interface PastebinTypeViewController : UITableViewController {
    NSArray *_pastebinTypes;
}
@property PastebinEditorViewController *delegate;
@end

@implementation PastebinTypeViewController

-(id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Mode";
        self->_pastebinTypes = @[
            @{@"name": @"ABAP", @"extension": @"abap"},
            @{@"name": @"ABC", @"extension": @"abc"},
            @{@"name": @"ActionScript", @"extension": @"as"},
            @{@"name": @"ADA", @"extension": @"ada"},
            @{@"name": @"Apache Conf", @"extension": @"htaccess"},
            @{@"name": @"AsciiDoc", @"extension": @"asciidoc"},
            @{@"name": @"Assembly x86", @"extension": @"asm"},
            @{@"name": @"AutoHotKey", @"extension": @"ahk"},
            @{@"name": @"BatchFile", @"extension": @"bat"},
            @{@"name": @"Bro", @"extension": @"bro"},
            @{@"name": @"C and C++", @"extension": @"cpp"},
            @{@"name": @"C9Search", @"extension": @"c9search_results"},
            @{@"name": @"Cirru", @"extension": @"cirru"},
            @{@"name": @"Clojure", @"extension": @"clj"},
            @{@"name": @"Cobol", @"extension": @"CBL"},
            @{@"name": @"CoffeeScript", @"extension": @"coffee"},
            @{@"name": @"ColdFusion", @"extension": @"cfm"},
            @{@"name": @"C#", @"extension": @"cs"},
            @{@"name": @"Csound Document", @"extension": @"csd"},
            @{@"name": @"Csound", @"extension": @"orc"},
            @{@"name": @"Csound Score", @"extension": @"sco"},
            @{@"name": @"CSS", @"extension": @"css"},
            @{@"name": @"Curly", @"extension": @"curly"},
            @{@"name": @"D", @"extension": @"d"},
            @{@"name": @"Dart", @"extension": @"dart"},
            @{@"name": @"Diff", @"extension": @"diff"},
            @{@"name": @"Dockerfile", @"extension": @"Dockerfile"},
            @{@"name": @"Dot", @"extension": @"dot"},
            @{@"name": @"Drools", @"extension": @"drl"},
            @{@"name": @"Dummy", @"extension": @"dummy"},
            @{@"name": @"DummySyntax", @"extension": @"dummy"},
            @{@"name": @"Eiffel", @"extension": @"e"},
            @{@"name": @"EJS", @"extension": @"ejs"},
            @{@"name": @"Elixir", @"extension": @"ex"},
            @{@"name": @"Elm", @"extension": @"elm"},
            @{@"name": @"Erlang", @"extension": @"erl"},
            @{@"name": @"Forth", @"extension": @"frt"},
            @{@"name": @"Fortran", @"extension": @"f"},
            @{@"name": @"FreeMarker", @"extension": @"ftl"},
            @{@"name": @"Gcode", @"extension": @"gcode"},
            @{@"name": @"Gherkin", @"extension": @"feature"},
            @{@"name": @"Gitignore", @"extension": @"gitignore"},
            @{@"name": @"Glsl", @"extension": @"glsl"},
            @{@"name": @"Gobstones", @"extension": @"gbs"},
            @{@"name": @"Go", @"extension": @"go"},
            @{@"name": @"GraphQLSchema", @"extension": @"gql"},
            @{@"name": @"Groovy", @"extension": @"groovy"},
            @{@"name": @"HAML", @"extension": @"haml"},
            @{@"name": @"Handlebars", @"extension": @"hbs"},
            @{@"name": @"Haskell", @"extension": @"hs"},
            @{@"name": @"Haskell Cabal", @"extension": @"cabal"},
            @{@"name": @"haXe", @"extension": @"hx"},
            @{@"name": @"Hjson", @"extension": @"hjson"},
            @{@"name": @"HTML", @"extension": @"html"},
            @{@"name": @"HTML (Elixir)", @"extension": @"eex"},
            @{@"name": @"HTML (Ruby)", @"extension": @"erb"},
            @{@"name": @"INI", @"extension": @"ini"},
            @{@"name": @"Io", @"extension": @"io"},
            @{@"name": @"Jack", @"extension": @"jack"},
            @{@"name": @"Jade", @"extension": @"jade"},
            @{@"name": @"Java", @"extension": @"java"},
            @{@"name": @"JavaScript", @"extension": @"js"},
            @{@"name": @"JSON", @"extension": @"json"},
            @{@"name": @"JSONiq", @"extension": @"jq"},
            @{@"name": @"JSP", @"extension": @"jsp"},
            @{@"name": @"JSSM", @"extension": @"jssm"},
            @{@"name": @"JSX", @"extension": @"jsx"},
            @{@"name": @"Julia", @"extension": @"jl"},
            @{@"name": @"Kotlin", @"extension": @"kt"},
            @{@"name": @"LaTeX", @"extension": @"tex"},
            @{@"name": @"LESS", @"extension": @"less"},
            @{@"name": @"Liquid", @"extension": @"liquid"},
            @{@"name": @"Lisp", @"extension": @"lisp"},
            @{@"name": @"LiveScript", @"extension": @"ls"},
            @{@"name": @"LogiQL", @"extension": @"logic"},
            @{@"name": @"LSL", @"extension": @"lsl"},
            @{@"name": @"Lua", @"extension": @"lua"},
            @{@"name": @"LuaPage", @"extension": @"lp"},
            @{@"name": @"Lucene", @"extension": @"lucene"},
            @{@"name": @"Makefile", @"extension": @"Makefile"},
            @{@"name": @"Markdown", @"extension": @"md"},
            @{@"name": @"Mask", @"extension": @"mask"},
            @{@"name": @"MATLAB", @"extension": @"matlab"},
            @{@"name": @"Maze", @"extension": @"mz"},
            @{@"name": @"MEL", @"extension": @"mel"},
            @{@"name": @"MUSHCode", @"extension": @"mc"},
            @{@"name": @"MySQL", @"extension": @"mysql"},
            @{@"name": @"Nix", @"extension": @"nix"},
            @{@"name": @"NSIS", @"extension": @"nsi"},
            @{@"name": @"Objective-C", @"extension": @"m"},
            @{@"name": @"OCaml", @"extension": @"ml"},
            @{@"name": @"Pascal", @"extension": @"pas"},
            @{@"name": @"Perl", @"extension": @"pl"},
            @{@"name": @"pgSQL", @"extension": @"pgsql"},
            @{@"name": @"PHP", @"extension": @"php"},
            @{@"name": @"Pig", @"extension": @"pig"},
            @{@"name": @"Powershell", @"extension": @"ps1"},
            @{@"name": @"Praat", @"extension": @"praat"},
            @{@"name": @"Prolog", @"extension": @"plg"},
            @{@"name": @"Properties", @"extension": @"properties"},
            @{@"name": @"Protobuf", @"extension": @"proto"},
            @{@"name": @"Python", @"extension": @"py"},
            @{@"name": @"R", @"extension": @"r"},
            @{@"name": @"Razor", @"extension": @"cshtml"},
            @{@"name": @"RDoc", @"extension": @"Rd"},
            @{@"name": @"Red", @"extension": @"red"},
            @{@"name": @"RHTML", @"extension": @"Rhtml"},
            @{@"name": @"RST", @"extension": @"rst"},
            @{@"name": @"Ruby", @"extension": @"rb"},
            @{@"name": @"Rust", @"extension": @"rs"},
            @{@"name": @"SASS", @"extension": @"sass"},
            @{@"name": @"SCAD", @"extension": @"scad"},
            @{@"name": @"Scala", @"extension": @"scala"},
            @{@"name": @"Scheme", @"extension": @"scm"},
            @{@"name": @"SCSS", @"extension": @"scss"},
            @{@"name": @"SH", @"extension": @"sh"},
            @{@"name": @"SJS", @"extension": @"sjs"},
            @{@"name": @"Smarty", @"extension": @"smarty"},
            @{@"name": @"snippets", @"extension": @"snippets"},
            @{@"name": @"Soy Template", @"extension": @"soy"},
            @{@"name": @"Space", @"extension": @"space"},
            @{@"name": @"SQL", @"extension": @"sql"},
            @{@"name": @"SQLServer", @"extension": @"sqlserver"},
            @{@"name": @"Stylus", @"extension": @"styl"},
            @{@"name": @"SVG", @"extension": @"svg"},
            @{@"name": @"Swift", @"extension": @"swift"},
            @{@"name": @"Tcl", @"extension": @"tcl"},
            @{@"name": @"Tex", @"extension": @"tex"},
            @{@"name": @"Text", @"extension": @"txt"},
            @{@"name": @"Textile", @"extension": @"textile"},
            @{@"name": @"Toml", @"extension": @"toml"},
            @{@"name": @"TSX", @"extension": @"tsx"},
            @{@"name": @"Twig", @"extension": @"twig"},
            @{@"name": @"Typescript", @"extension": @"ts"},
            @{@"name": @"Vala", @"extension": @"vala"},
            @{@"name": @"VBScript", @"extension": @"vbs"},
            @{@"name": @"Velocity", @"extension": @"vm"},
            @{@"name": @"Verilog", @"extension": @"v"},
            @{@"name": @"VHDL", @"extension": @"vhd"},
            @{@"name": @"Wollok", @"extension": @"wlk"},
            @{@"name": @"XML", @"extension": @"xml"},
            @{@"name": @"XQuery", @"extension": @"xq"},
            @{@"name": @"YAML", @"extension": @"yaml"},
            @{@"name": @"Django", @"extension": @"html"},
        ];
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
    return _pastebinTypes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"pastebintypecell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"pastebintypecell"];
    
    cell.textLabel.text = [[self->_pastebinTypes objectAtIndex:indexPath.row] objectForKey:@"name"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    _delegate.extension = [[self->_pastebinTypes objectAtIndex:indexPath.row] objectForKey:@"extension"];
    [self.navigationController popViewControllerAnimated:YES];
}

@end


@interface PastebinEditorCell : UITableViewCell

@end

@implementation PastebinEditorCell
- (void) layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y, self.frame.size.width - self.textLabel.frame.origin.x, self.textLabel.frame.size.height);
}
@end

NSDictionary *__pastebinTypeMap = nil;

@implementation PastebinEditorViewController

+(NSString *)pastebinType:(NSString *)extension {
    if(extension.length) {
        if (!__pastebinTypeMap) {
            __pastebinTypeMap = @{
                @"ABAP": [NSRegularExpression regularExpressionWithPattern:@"abap" options:NSRegularExpressionCaseInsensitive error:nil],
                @"ABC": [NSRegularExpression regularExpressionWithPattern:@"abc" options:NSRegularExpressionCaseInsensitive error:nil],
                @"ActionScript": [NSRegularExpression regularExpressionWithPattern:@"as" options:NSRegularExpressionCaseInsensitive error:nil],
                @"ADA": [NSRegularExpression regularExpressionWithPattern:@"ada|adb" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Apache Conf": [NSRegularExpression regularExpressionWithPattern:@"^htaccess|^htgroups|^htpasswd|^conf|htaccess|htgroups|htpasswd" options:NSRegularExpressionCaseInsensitive error:nil],
                @"AsciiDoc": [NSRegularExpression regularExpressionWithPattern:@"asciidoc|adoc" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Assembly x86": [NSRegularExpression regularExpressionWithPattern:@"asm|a" options:NSRegularExpressionCaseInsensitive error:nil],
                @"AutoHotKey": [NSRegularExpression regularExpressionWithPattern:@"ahk" options:NSRegularExpressionCaseInsensitive error:nil],
                @"BatchFile": [NSRegularExpression regularExpressionWithPattern:@"bat|cmd" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Bro": [NSRegularExpression regularExpressionWithPattern:@"bro" options:NSRegularExpressionCaseInsensitive error:nil],
                @"C and C++": [NSRegularExpression regularExpressionWithPattern:@"cpp|c|cc|cxx|h|hh|hpp|ino" options:NSRegularExpressionCaseInsensitive error:nil],
                @"C9Search": [NSRegularExpression regularExpressionWithPattern:@"c9search_results" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Cirru": [NSRegularExpression regularExpressionWithPattern:@"cirru|cr" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Clojure": [NSRegularExpression regularExpressionWithPattern:@"clj|cljs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Cobol": [NSRegularExpression regularExpressionWithPattern:@"CBL|COB" options:NSRegularExpressionCaseInsensitive error:nil],
                @"CoffeeScript": [NSRegularExpression regularExpressionWithPattern:@"coffee|cf|cson|^Cakefile" options:NSRegularExpressionCaseInsensitive error:nil],
                @"ColdFusion": [NSRegularExpression regularExpressionWithPattern:@"cfm" options:NSRegularExpressionCaseInsensitive error:nil],
                @"C#": [NSRegularExpression regularExpressionWithPattern:@"cs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Csound Document": [NSRegularExpression regularExpressionWithPattern:@"csd" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Csound": [NSRegularExpression regularExpressionWithPattern:@"orc" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Csound Score": [NSRegularExpression regularExpressionWithPattern:@"sco" options:NSRegularExpressionCaseInsensitive error:nil],
                @"CSS": [NSRegularExpression regularExpressionWithPattern:@"css" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Curly": [NSRegularExpression regularExpressionWithPattern:@"curly" options:NSRegularExpressionCaseInsensitive error:nil],
                @"D": [NSRegularExpression regularExpressionWithPattern:@"d|di" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Dart": [NSRegularExpression regularExpressionWithPattern:@"dart" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Diff": [NSRegularExpression regularExpressionWithPattern:@"diff|patch" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Dockerfile": [NSRegularExpression regularExpressionWithPattern:@"^Dockerfile" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Dot": [NSRegularExpression regularExpressionWithPattern:@"dot" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Drools": [NSRegularExpression regularExpressionWithPattern:@"drl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Dummy": [NSRegularExpression regularExpressionWithPattern:@"dummy" options:NSRegularExpressionCaseInsensitive error:nil],
                @"DummySyntax": [NSRegularExpression regularExpressionWithPattern:@"dummy" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Eiffel": [NSRegularExpression regularExpressionWithPattern:@"e|ge" options:NSRegularExpressionCaseInsensitive error:nil],
                @"EJS": [NSRegularExpression regularExpressionWithPattern:@"ejs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Elixir": [NSRegularExpression regularExpressionWithPattern:@"ex|exs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Elm": [NSRegularExpression regularExpressionWithPattern:@"elm" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Erlang": [NSRegularExpression regularExpressionWithPattern:@"erl|hrl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Forth": [NSRegularExpression regularExpressionWithPattern:@"frt|fs|ldr|fth|4th" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Fortran": [NSRegularExpression regularExpressionWithPattern:@"f|f90" options:NSRegularExpressionCaseInsensitive error:nil],
                @"FreeMarker": [NSRegularExpression regularExpressionWithPattern:@"ftl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Gcode": [NSRegularExpression regularExpressionWithPattern:@"gcode" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Gherkin": [NSRegularExpression regularExpressionWithPattern:@"feature" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Gitignore": [NSRegularExpression regularExpressionWithPattern:@"^.gitignore" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Glsl": [NSRegularExpression regularExpressionWithPattern:@"glsl|frag|vert" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Gobstones": [NSRegularExpression regularExpressionWithPattern:@"gbs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Go": [NSRegularExpression regularExpressionWithPattern:@"go" options:NSRegularExpressionCaseInsensitive error:nil],
                @"GraphQLSchema": [NSRegularExpression regularExpressionWithPattern:@"gql" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Groovy": [NSRegularExpression regularExpressionWithPattern:@"groovy" options:NSRegularExpressionCaseInsensitive error:nil],
                @"HAML": [NSRegularExpression regularExpressionWithPattern:@"haml" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Handlebars": [NSRegularExpression regularExpressionWithPattern:@"hbs|handlebars|tpl|mustache" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Haskell": [NSRegularExpression regularExpressionWithPattern:@"hs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Haskell Cabal": [NSRegularExpression regularExpressionWithPattern:@"cabal" options:NSRegularExpressionCaseInsensitive error:nil],
                @"haXe": [NSRegularExpression regularExpressionWithPattern:@"hx" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Hjson": [NSRegularExpression regularExpressionWithPattern:@"hjson" options:NSRegularExpressionCaseInsensitive error:nil],
                @"HTML": [NSRegularExpression regularExpressionWithPattern:@"html|htm|xhtml|vue|we|wpy" options:NSRegularExpressionCaseInsensitive error:nil],
                @"HTML (Elixir)": [NSRegularExpression regularExpressionWithPattern:@"eex|html.eex" options:NSRegularExpressionCaseInsensitive error:nil],
                @"HTML (Ruby)": [NSRegularExpression regularExpressionWithPattern:@"erb|rhtml|html.erb" options:NSRegularExpressionCaseInsensitive error:nil],
                @"INI": [NSRegularExpression regularExpressionWithPattern:@"ini|conf|cfg|prefs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Io": [NSRegularExpression regularExpressionWithPattern:@"io" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Jack": [NSRegularExpression regularExpressionWithPattern:@"jack" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Jade": [NSRegularExpression regularExpressionWithPattern:@"jade|pug" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Java": [NSRegularExpression regularExpressionWithPattern:@"java" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JavaScript": [NSRegularExpression regularExpressionWithPattern:@"js|jsm|jsx" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JSON": [NSRegularExpression regularExpressionWithPattern:@"json" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JSONiq": [NSRegularExpression regularExpressionWithPattern:@"jq" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JSP": [NSRegularExpression regularExpressionWithPattern:@"jsp" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JSSM": [NSRegularExpression regularExpressionWithPattern:@"jssm|jssm_state" options:NSRegularExpressionCaseInsensitive error:nil],
                @"JSX": [NSRegularExpression regularExpressionWithPattern:@"jsx" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Julia": [NSRegularExpression regularExpressionWithPattern:@"jl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Kotlin": [NSRegularExpression regularExpressionWithPattern:@"kt|kts" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LaTeX": [NSRegularExpression regularExpressionWithPattern:@"tex|latex|ltx|bib" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LESS": [NSRegularExpression regularExpressionWithPattern:@"less" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Liquid": [NSRegularExpression regularExpressionWithPattern:@"liquid" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Lisp": [NSRegularExpression regularExpressionWithPattern:@"lisp" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LiveScript": [NSRegularExpression regularExpressionWithPattern:@"ls" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LogiQL": [NSRegularExpression regularExpressionWithPattern:@"logic|lql" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LSL": [NSRegularExpression regularExpressionWithPattern:@"lsl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Lua": [NSRegularExpression regularExpressionWithPattern:@"lua" options:NSRegularExpressionCaseInsensitive error:nil],
                @"LuaPage": [NSRegularExpression regularExpressionWithPattern:@"lp" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Lucene": [NSRegularExpression regularExpressionWithPattern:@"lucene" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Makefile": [NSRegularExpression regularExpressionWithPattern:@"^Makefile|^GNUmakefile|^makefile|^OCamlMakefile|make" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Markdown": [NSRegularExpression regularExpressionWithPattern:@"md|markdown" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Mask": [NSRegularExpression regularExpressionWithPattern:@"mask" options:NSRegularExpressionCaseInsensitive error:nil],
                @"MATLAB": [NSRegularExpression regularExpressionWithPattern:@"matlab" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Maze": [NSRegularExpression regularExpressionWithPattern:@"mz" options:NSRegularExpressionCaseInsensitive error:nil],
                @"MEL": [NSRegularExpression regularExpressionWithPattern:@"mel" options:NSRegularExpressionCaseInsensitive error:nil],
                @"MUSHCode": [NSRegularExpression regularExpressionWithPattern:@"mc|mush" options:NSRegularExpressionCaseInsensitive error:nil],
                @"MySQL": [NSRegularExpression regularExpressionWithPattern:@"mysql" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Nix": [NSRegularExpression regularExpressionWithPattern:@"nix" options:NSRegularExpressionCaseInsensitive error:nil],
                @"NSIS": [NSRegularExpression regularExpressionWithPattern:@"nsi|nsh" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Objective-C": [NSRegularExpression regularExpressionWithPattern:@"m|mm" options:NSRegularExpressionCaseInsensitive error:nil],
                @"OCaml": [NSRegularExpression regularExpressionWithPattern:@"ml|mli" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Pascal": [NSRegularExpression regularExpressionWithPattern:@"pas|p" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Perl": [NSRegularExpression regularExpressionWithPattern:@"pl|pm" options:NSRegularExpressionCaseInsensitive error:nil],
                @"pgSQL": [NSRegularExpression regularExpressionWithPattern:@"pgsql" options:NSRegularExpressionCaseInsensitive error:nil],
                @"PHP": [NSRegularExpression regularExpressionWithPattern:@"php|phtml|shtml|php3|php4|php5|phps|phpt|aw|ctp|module" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Pig": [NSRegularExpression regularExpressionWithPattern:@"pig" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Powershell": [NSRegularExpression regularExpressionWithPattern:@"ps1" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Praat": [NSRegularExpression regularExpressionWithPattern:@"praat|praatscript|psc|proc" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Prolog": [NSRegularExpression regularExpressionWithPattern:@"plg|prolog" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Properties": [NSRegularExpression regularExpressionWithPattern:@"properties" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Protobuf": [NSRegularExpression regularExpressionWithPattern:@"proto" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Python": [NSRegularExpression regularExpressionWithPattern:@"py" options:NSRegularExpressionCaseInsensitive error:nil],
                @"R": [NSRegularExpression regularExpressionWithPattern:@"r" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Razor": [NSRegularExpression regularExpressionWithPattern:@"cshtml|asp" options:NSRegularExpressionCaseInsensitive error:nil],
                @"RDoc": [NSRegularExpression regularExpressionWithPattern:@"Rd" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Red": [NSRegularExpression regularExpressionWithPattern:@"red|reds" options:NSRegularExpressionCaseInsensitive error:nil],
                @"RHTML": [NSRegularExpression regularExpressionWithPattern:@"Rhtml" options:NSRegularExpressionCaseInsensitive error:nil],
                @"RST": [NSRegularExpression regularExpressionWithPattern:@"rst" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Ruby": [NSRegularExpression regularExpressionWithPattern:@"rb|ru|gemspec|rake|^Guardfile|^Rakefile|^Gemfile" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Rust": [NSRegularExpression regularExpressionWithPattern:@"rs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SASS": [NSRegularExpression regularExpressionWithPattern:@"sass" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SCAD": [NSRegularExpression regularExpressionWithPattern:@"scad" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Scala": [NSRegularExpression regularExpressionWithPattern:@"scala" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Scheme": [NSRegularExpression regularExpressionWithPattern:@"scm|sm|rkt|oak|scheme" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SCSS": [NSRegularExpression regularExpressionWithPattern:@"scss" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SH": [NSRegularExpression regularExpressionWithPattern:@"sh|bash|^.bashrc" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SJS": [NSRegularExpression regularExpressionWithPattern:@"sjs" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Smarty": [NSRegularExpression regularExpressionWithPattern:@"smarty|tpl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"snippets": [NSRegularExpression regularExpressionWithPattern:@"snippets" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Soy Template": [NSRegularExpression regularExpressionWithPattern:@"soy" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Space": [NSRegularExpression regularExpressionWithPattern:@"space" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SQL": [NSRegularExpression regularExpressionWithPattern:@"sql" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SQLServer": [NSRegularExpression regularExpressionWithPattern:@"sqlserver" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Stylus": [NSRegularExpression regularExpressionWithPattern:@"styl|stylus" options:NSRegularExpressionCaseInsensitive error:nil],
                @"SVG": [NSRegularExpression regularExpressionWithPattern:@"svg" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Swift": [NSRegularExpression regularExpressionWithPattern:@"swift" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Tcl": [NSRegularExpression regularExpressionWithPattern:@"tcl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Tex": [NSRegularExpression regularExpressionWithPattern:@"tex" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Plain Text": [NSRegularExpression regularExpressionWithPattern:@"txt" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Textile": [NSRegularExpression regularExpressionWithPattern:@"textile" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Toml": [NSRegularExpression regularExpressionWithPattern:@"toml" options:NSRegularExpressionCaseInsensitive error:nil],
                @"TSX": [NSRegularExpression regularExpressionWithPattern:@"tsx" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Twig": [NSRegularExpression regularExpressionWithPattern:@"twig|swig" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Typescript": [NSRegularExpression regularExpressionWithPattern:@"ts|typescript|str" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Vala": [NSRegularExpression regularExpressionWithPattern:@"vala" options:NSRegularExpressionCaseInsensitive error:nil],
                @"VBScript": [NSRegularExpression regularExpressionWithPattern:@"vbs|vb" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Velocity": [NSRegularExpression regularExpressionWithPattern:@"vm" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Verilog": [NSRegularExpression regularExpressionWithPattern:@"v|vh|sv|svh" options:NSRegularExpressionCaseInsensitive error:nil],
                @"VHDL": [NSRegularExpression regularExpressionWithPattern:@"vhd|vhdl" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Wollok": [NSRegularExpression regularExpressionWithPattern:@"wlk|wpgm|wtest" options:NSRegularExpressionCaseInsensitive error:nil],
                @"XML": [NSRegularExpression regularExpressionWithPattern:@"xml|rdf|rss|wsdl|xslt|atom|mathml|mml|xul|xbl|xaml" options:NSRegularExpressionCaseInsensitive error:nil],
                @"XQuery": [NSRegularExpression regularExpressionWithPattern:@"xq" options:NSRegularExpressionCaseInsensitive error:nil],
                @"YAML": [NSRegularExpression regularExpressionWithPattern:@"yaml|yml" options:NSRegularExpressionCaseInsensitive error:nil],
                @"Django": [NSRegularExpression regularExpressionWithPattern:@"html" options:NSRegularExpressionCaseInsensitive error:nil],
            };
        }
        
        NSRange range = NSMakeRange(0, extension.length);
        for(NSString *type in __pastebinTypeMap.allKeys) {
            NSRegularExpression *regex = [__pastebinTypeMap objectForKey:type];
            NSArray *matches = [regex matchesInString:extension options:NSMatchingAnchored range:range];
            for(NSTextCheckingResult *result in matches) {
                if(result.range.location == 0 && result.range.length == range.length) {
                    return type;
                }
            }
        }
    }
    return @"Plain Text";
}

-(id)initWithBuffer:(Buffer *)buffer {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Text Snippet";
        if(buffer)
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        self->_buffer = buffer;
        self->_sayreqid = -1;
        
        self->_type = [[UISegmentedControl alloc] initWithItems:@[@"Snippet", @"Messages"]];
        self->_type.selectedSegmentIndex = 0;
        [self->_type addTarget:self action:@selector(_typeToggled) forControlEvents:UIControlEventValueChanged];
        self.navigationItem.titleView = self->_type;
    }
    return self;
}

-(void)_typeToggled {
    [self.tableView reloadData];
    [self textViewDidChange:self->_text];
}

-(id)initWithPasteID:(NSString *)pasteID {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        self.navigationItem.title = @"Text Snippet";
        self->_pasteID = pasteID;
        self->_sayreqid = -1;
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
        [spinny startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    }
    return self;
}

-(void)_fetchPaste {
    NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:@{@"id":self->_pasteID, @"type":@"json"} error:nil];
    url = [url stringByReplacingOccurrencesOfString:@"https://www.irccloud.com/" withString:[NSString stringWithFormat:@"https://%@/", IRCCLOUD_HOST]];

    [[[NetworkConnection sharedInstance].urlSession dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            CLS_LOG(@"Error fetching pastebin. Error %li : %@", (long)error.code, error.userInfo);
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            self->_text.text = [dict objectForKey:@"body"];
            self->_filename.text = [dict objectForKey:@"name"];
            self->_text.editable = self->_filename.enabled = YES;
            self->_extension = [dict objectForKey:@"extension"];
            [self.tableView reloadData];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
    }] resume];
}

-(void)sendButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:[UIColor activityIndicatorViewStyle]];
    [spinny startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinny];

    if(self->_type.selectedSegmentIndex == 1) {
        if(self->_message.text.length) {
            self->_buffer.draft = [NSString stringWithFormat:@"%@ %@", _message.text, _text.text];
        } else {
            self->_buffer.draft = self->_text.text;
        }
        self->_sayreqid = [[NetworkConnection sharedInstance] say:self->_buffer.draft to:self->_buffer.name cid:self->_buffer.cid handler:^(IRCCloudJSONObject *result) {
            if(![[result objectForKey:@"success"] boolValue]) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        }];
    } else {
        if(!_extension.length)
            self->_extension = @"txt";
        
        IRCCloudAPIResultHandler pasteHandler = ^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] boolValue]) {
                if(self->_pasteID) {
                    [self.tableView endEditing:YES];
                    [self.navigationController popViewControllerAnimated:YES];
                } else {
                    if(self->_message.text.length) {
                        self->_buffer.draft = [NSString stringWithFormat:@"%@ %@", self->_message.text, [result objectForKey:@"url"]];
                    } else {
                        self->_buffer.draft = [result objectForKey:@"url"];
                    }
                    self->_sayreqid = [[NetworkConnection sharedInstance] say:self->_buffer.draft to:self->_buffer.name cid:self->_buffer.cid handler:^(IRCCloudJSONObject *result) {
                        if(![result objectForKey:@"success"]) {
                            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to send message: %@", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                            [self presentViewController:alert animated:YES completion:nil];
                        }
                    }];
                }
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to save snippet, please try again." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
                self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self->_pasteID?@"Save":@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
            }
        };
        
        if(self->_pasteID)
            [[NetworkConnection sharedInstance] editPaste:self->_pasteID name:self->_filename.text contents:self->_text.text extension:self->_extension handler:pasteHandler];
        else
            [[NetworkConnection sharedInstance] paste:self->_filename.text contents:self->_text.text extension:self->_extension handler:pasteHandler];
    }
}

-(void)cancelButtonPressed:(id)sender {
    [self.tableView endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleEvent:) name:kIRCCloudEventNotification object:nil];
    [self.tableView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    Event *e;
    
    switch(event) {
        case kIRCEventBufferMsg:
            e = notification.object;
            if(self->_sayreqid > 0 && e.bid == self->_buffer.bid && (e.reqId == self->_sayreqid || (e.isSelf && [e.from isEqualToString:self->_buffer.name]))) {
                self->_buffer.draft = @"";
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.tableView endEditing:YES];
                    [self dismissViewControllerAnimated:YES completion:nil];
                    self->_buffer.draft = @"";
                    [((AppDelegate *)[UIApplication sharedApplication].delegate).mainViewController clearText];
                }];
            }
            break;
        default:
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;

    self->_filename = [[UITextField alloc] initWithFrame:CGRectZero];
    self->_filename.text = @"";
    self->_filename.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_filename.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self->_filename.autocorrectionType = UITextAutocorrectionTypeNo;
    self->_filename.adjustsFontSizeToFitWidth = YES;
    self->_filename.returnKeyType = UIReturnKeyDone;
    self->_filename.enabled = !_pasteID;
    self->_filename.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self->_filename addTarget:self action:@selector(filenameChanged) forControlEvents:UIControlEventEditingChanged];
    
    self->_message = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_message.text = @"";
    self->_message.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_message.backgroundColor = [UIColor clearColor];
    self->_message.returnKeyType = UIReturnKeyDone;
    self->_message.delegate = self;
    self->_message.font = self->_filename.font;
    self->_message.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_message.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_message.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_message.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }

    self->_messageFooter = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 32)];
    self->_messageFooter.backgroundColor = [UIColor clearColor];
    self->_messageFooter.textColor = [UILabel appearanceWhenContainedInInstancesOfClasses:@[UITableViewHeaderFooterView.class]].textColor;
    self->_messageFooter.textAlignment = NSTextAlignmentCenter;
    self->_messageFooter.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_messageFooter.numberOfLines = 0;
    self->_messageFooter.adjustsFontSizeToFitWidth = YES;
    
    self->_text = [[UITextView alloc] initWithFrame:CGRectZero];
    self->_text.backgroundColor = [UIColor clearColor];
    self->_text.font = self->_filename.font;
    self->_text.textColor = [UITableViewCell appearance].detailTextLabelColor;
    self->_text.delegate = self;
    self->_text.editable = !_pasteID;
    self->_text.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self->_text.text = self->_buffer.draft;
    self->_text.keyboardAppearance = [UITextField appearance].keyboardAppearance;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"autoCaps"]) {
        self->_text.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    } else {
        self->_text.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }
    [self textViewDidChange:self->_text];
    
    if(self->_pasteID)
        [self _fetchPaste];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if(textView == self->_message)
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if(textView != self->_text && [text isEqualToString:@"\n"]) {
        [self.tableView endEditing:YES];
        return NO;
    }
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView {
    self.navigationItem.rightBarButtonItem.enabled = (self->_text.text.length > 0);
    if(textView == self->_text) {
        int count = 0;
        NSArray *lines = [self->_text.text componentsSeparatedByString:@"\n"];
        for (NSString *line in lines) {
            count += ceil((float)line.length / 1080.0f);
        }
        if(self->_type.selectedSegmentIndex == 1)
            self->_messageFooter.text = [NSString stringWithFormat:@"Text will be sent as %i message%@", count, (count == 1)?@"":@"s"];
        else
            self->_messageFooter.text = @"Text snippets are visible to anyone with the URL but are not publicly listed or indexed.";
    }
}

-(void)filenameChanged {
    if([self->_filename.text rangeOfString:@"."].location != NSNotFound) {
        NSString *extension = [self->_filename.text substringFromIndex:[self->_filename.text rangeOfString:@"." options:NSBackwardsSearch].location + 1];
        if(extension.length)
            self->_extension = extension;
        else if(!_extension.length)
            self->_extension = @"txt";
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0)
        return 160;
    else if(indexPath.section == 3)
        return 64;
    else
        return UITableViewAutomaticDimension;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if(self->_pasteID)
        return 3;
    else if(self->_type.selectedSegmentIndex == 0)
        return 4;
    else
        return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return nil;
        case 1:
            return @"File name (optional)";
        case 2:
            return @"Syntax Highlighting Mode";
        case 3:
            return @"Message (optional)";
    }
    return nil;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if(section == 0) {
        CGRect frame = self->_messageFooter.frame;
        frame.origin.x = self.view.safeAreaInsets.left;
        self->_messageFooter.frame = frame;
        return _messageFooter;
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if(section == 0) {
        return 32;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger row = indexPath.row;
    NSString *identifier = [NSString stringWithFormat:@"pastecell-%li-%li", (long)indexPath.section, (long)indexPath.row];
    PastebinEditorCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    
    if(!cell)
        cell = [[PastebinEditorCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.textLabel.text = nil;

    switch(indexPath.section) {
        case 0:
            [self->_text removeFromSuperview];
            self->_text.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_text];
            break;
        case 1:
            [self->_filename removeFromSuperview];
            self->_filename.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_filename];
            break;
        case 2:
            cell.textLabel.text = [PastebinEditorViewController pastebinType:self->_extension];
            break;
        case 3:
            [self->_message removeFromSuperview];
            self->_message.frame = CGRectInset(cell.contentView.bounds, 4, 4);
            [cell.contentView addSubview:self->_message];
            break;
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.tableView endEditing:YES];
    
    if(indexPath.section == 2) {
        PastebinTypeViewController *vc = [[PastebinTypeViewController alloc] init];
        vc.delegate = self;
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

@end
