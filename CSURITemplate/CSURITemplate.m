//
//  CSURITemplate.m
//  CSURITemplate
//
//  Created by Will Harris on 26/02/2013.
//  Copyright (c) 2013 Cogenta Systems Ltd. All rights reserved.
//

#import "CSURITemplate.h"

NSString *const CSURITemplateErrorDomain = @"com.cogenta.CSURITemplate.errors";
NSString *const CSURITemplateErrorScanLocationErrorKey = @"location";

@protocol CSURITemplateTerm <NSObject>

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError **)error;

@end

@protocol CSURITemplateEscaper <NSObject>

- (NSString *)escapeItem:(id)item;

@end

@protocol CSURITemplateVariable <NSObject>

@property (nonatomic, readonly) NSString *key;
- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper error:(NSError **)error;
- (BOOL)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  error:(NSError **)error
                                  block:(void (^)(NSString *key, NSString *value))block;

@end

@interface CSURITemplateEscaping : NSObject

+ (NSObject<CSURITemplateEscaper> *)uriEscaper;
+ (NSObject<CSURITemplateEscaper> *)fragmentEscaper;

@end

@interface CSURITemplateURIEscaper : NSObject <CSURITemplateEscaper>

@end

@interface CSURITemplateFragmentEscaper : NSObject <CSURITemplateEscaper>

@end

@implementation CSURITemplateEscaping

+ (NSObject<CSURITemplateEscaper> *)uriEscaper
{
    return [[CSURITemplateURIEscaper alloc] init];
}

+ (NSObject<CSURITemplateEscaper> *)fragmentEscaper
{
    return [[CSURITemplateFragmentEscaper alloc] init];
}

@end

@interface NSObject (URITemplateAdditions)

- (NSString *)csuri_stringEscapedForURI;
- (NSString *)csuri_stringEscapedForFragment;
- (NSString *)csuri_basicString;
- (NSArray *)csuri_explodedItems;
- (NSArray *)csuri_explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper;
- (NSString *)csuri_escapeWithEscaper:(id<CSURITemplateEscaper>)escaper;
- (void)csuri_enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)key
                                           block:(void (^)(NSString *key, NSString *value))block;
@end

@implementation CSURITemplateURIEscaper

- (NSString *)escapeItem:(NSObject *)item
{
    return [item csuri_stringEscapedForURI];
}

@end

@implementation CSURITemplateFragmentEscaper

- (NSString *)escapeItem:(NSObject *)item
{
    return [item csuri_stringEscapedForFragment];
}

@end

@implementation NSObject (URITemplateAdditions)

- (NSString *)csuri_escapeWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    return [escaper escapeItem:self];
}

- (NSString *)csuri_stringEscapedForURI
{
    return [[self csuri_basicString] csuri_stringEscapedForURI];
}

- (NSString *)csuri_stringEscapedForFragment
{
    return [[self csuri_basicString] csuri_stringEscapedForFragment];
}

- (NSString *)csuri_basicString
{
    return [self description];
}

- (NSArray *)csuri_explodedItems
{
    return [NSArray arrayWithObject:self];
}

- (NSArray *)csuri_explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    NSMutableArray *result = [NSMutableArray array];
    for (id value in [self csuri_explodedItems]) {
        [result addObject:[value csuri_escapeWithEscaper:escaper]];
    }
    return [NSArray arrayWithArray:result];
}

- (void)csuri_enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)key
                                           block:(void (^)(NSString *, NSString *))block
{
    for (NSString *value in [self csuri_explodedItemsEscapedWithEscaper:escaper]) {
        block(key, value);
    }
}

@end

@implementation NSString (URITemplateAdditions)

- (NSString *)csuri_stringEscapedForURI
{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef) self,
                                                              NULL,
                                                              CFSTR("!*'();:@&=+$,/?%#[]"),
                                                              kCFStringEncodingUTF8));
}

- (NSString *)csuri_stringEscapedForFragment
{
    return (NSString *)
    CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (__bridge CFStringRef) self,
                                                              NULL,
                                                              CFSTR(" "),
                                                              kCFStringEncodingUTF8));
}

- (NSString *)csuri_basicString
{
    return self;
}

@end

@implementation NSArray (URITemplateAdditions)

- (NSString *)csuri_stringEscapedForURI
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item csuri_stringEscapedForURI]];
    }
    return [result componentsJoinedByString:@","];
}


- (NSString *)csuri_stringEscapedForFragment
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item csuri_stringEscapedForFragment]];
    }
    return [result componentsJoinedByString:@","];
}

- (NSString *)csuri_basicString
{
    NSMutableArray *result = [NSMutableArray array];
    for (id item in self) {
        [result addObject:[item csuri_basicString]];
    }
    return [result componentsJoinedByString:@","];
}

- (NSArray *)csuri_explodedItems
{
    return self;
}

@end

@implementation NSDictionary (URITemplateAdditions)

- (NSString *)csuri_stringEscapedForURI
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key csuri_stringEscapedForURI]];
        [result addObject:[obj csuri_stringEscapedForURI]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSString *)csuri_stringEscapedForFragment
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key csuri_stringEscapedForFragment]];
        [result addObject:[obj csuri_stringEscapedForFragment]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSString *)csuri_basicString
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:[key csuri_basicString]];
        [result addObject:[obj csuri_basicString]];
    }];
    return [result componentsJoinedByString:@","];
}

- (NSArray *)csuri_explodedItems
{
    NSMutableArray *result = [NSMutableArray array];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [result addObject:key];
        [result addObject:obj];
    }];
    return [NSArray arrayWithArray:result];
}

- (NSArray *)csuri_explodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
{
    NSMutableArray *result = [NSMutableArray array];
    [self csuri_enumerateExplodedItemsEscapedWithEscaper:escaper
                                        defaultKey:nil
                                             block:^(NSString *k, NSString *v)
    {
        [result addObject:[NSString stringWithFormat:@"%@=%@", k, v]];
    }];
    return [NSArray arrayWithArray:result];
}

- (void)csuri_enumerateExplodedItemsEscapedWithEscaper:(id<CSURITemplateEscaper>)escaper
                                      defaultKey:(NSString *)defaultKey
                                           block:(void (^)(NSString *, NSString *))block
{
    [self enumerateKeysAndObjectsUsingBlock:^(id k, id obj, BOOL *stop) {
        block([k csuri_escapeWithEscaper:escaper],
              [obj csuri_escapeWithEscaper:escaper]);
    }];
}

@end

@implementation NSNull (URITemplateDescriptions)

- (NSArray *)csuri_explodedItems
{
    return [NSArray array];
}

@end

#pragma mark -

@interface CSURITemplateLiteralTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSString *literal;

- (id)initWithLiteral:(NSString *)literal;

@end

@implementation CSURITemplateLiteralTerm

@synthesize literal;

- (id)initWithLiteral:(NSString *)aLiteral
{
    self = [super init];
    if (self) {
        literal = aLiteral;
    }
    return self;
}

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError *__autoreleasing *)error
{
    return literal;
}

@end

@interface CSURITemplateInfixExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;
- (NSString *)infix;
- (NSString *)prepend;

@end

@implementation CSURITemplateInfixExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)prepend
{
    return @"";
}

- (NSString *)infix
{
    return @"";
}

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError *__autoreleasing *)error
{
    BOOL isFirst = YES;
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        NSArray *values = [variable valuesWithVariables:variables
                                                escaper:[self escaper]
                                                  error:error];
        if ( ! values) {
            // An error was encountered expanding the variable.
            return nil;
        }
        
        for (NSString *value in values) {
            if (isFirst) {
                isFirst = NO;
                [result appendString:[self prepend]];
            } else {
                [result appendString:[self infix]];
            }
            
            [result appendString:value];
        }
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateCommaExpressionTerm : CSURITemplateInfixExpressionTerm

@end

@implementation CSURITemplateCommaExpressionTerm

- (NSString *)infix
{
    return @",";
}

@end

@interface CSURITemplatePrependExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;

- (id)initWithVariables:(NSArray *)variables;

@end

@implementation CSURITemplatePrependExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (NSString *)prepend
{
    return @"";
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError *__autoreleasing *)error
{
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        for (NSString *value in [variable valuesWithVariables:variables
                                                      escaper:[self escaper]
                                                        error:error]) {
            [result appendString:[self prepend]];
            [result appendString:value];
        }
    }
    
    return [NSString stringWithString:result];
}


@end

@interface CSURITemplateSolidusExpressionTerm : CSURITemplatePrependExpressionTerm

@end

@implementation CSURITemplateSolidusExpressionTerm

- (NSString *)prepend
{
    return @"/";
}

@end


@interface CSURITemplateDotExpressionTerm : CSURITemplatePrependExpressionTerm

@end

@implementation CSURITemplateDotExpressionTerm

- (NSString *)prepend
{
    return @".";
}

@end


@interface CSURITemplateHashExpressionTerm : CSURITemplateCommaExpressionTerm

@end

@implementation CSURITemplateHashExpressionTerm

- (NSString *)prepend
{
    return @"#";
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping fragmentEscaper];
}

@end

@interface CSURITemplateQueryExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;
- (NSString *)prepend;

@end

@implementation CSURITemplateQueryExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)prepend
{
    return @"?";
}

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError *__autoreleasing *)error
{
    __block BOOL isFirst = YES;
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        BOOL success = [variable enumerateKeyValuesWithVariables:variables
                                                         escaper:[self escaper]
                                                           error:error
                                                           block:^(NSString *key, NSString *value) {
            
            if (isFirst) {
                isFirst = NO;
                [result appendString:[self prepend]];
            } else {
                [result appendString:@"&"];
            }
            
            [result appendString:key];
            [result appendString:@"="];
            [result appendString:value];
        }];
        
        if ( ! success) return nil;
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateParameterExpressionTerm : NSObject <CSURITemplateTerm>

@property (nonatomic, strong) NSArray *variablesExpression;
- (id)initWithVariables:(NSArray *)variables;

@end

@implementation CSURITemplateParameterExpressionTerm

@synthesize variablesExpression;

- (id)initWithVariables:(NSArray *)theVariables
{
    self = [super init];
    if (self) {
        variablesExpression = theVariables;
    }
    return self;
}

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping uriEscaper];
}

- (NSString *)expandWithVariables:(NSDictionary *)variables error:(NSError *__autoreleasing *)error
{
    NSMutableString *result = [NSMutableString string];
    for (NSObject<CSURITemplateVariable> *variable in variablesExpression) {
        BOOL success = [variable enumerateKeyValuesWithVariables:variables escaper:[self escaper] error:error block:^(NSString *key, NSString *value) {
             [result appendString:@";"];
             
             [result appendString:key];
             
             if ( ! [value isEqualToString:@""]) {
                 [result appendString:@"="];
                 [result appendString:value];
             }
         }];
        
        if ( ! success) return nil;
    }
    
    return [NSString stringWithString:result];
}

@end

@interface CSURITemplateReservedExpressionTerm : CSURITemplateCommaExpressionTerm

@end

@implementation CSURITemplateReservedExpressionTerm

- (id<CSURITemplateEscaper>)escaper
{
    return [CSURITemplateEscaping fragmentEscaper];
}

@end

@interface CSURITemplateQueryContinuationExpressionTerm : CSURITemplateQueryExpressionTerm

@end

@implementation CSURITemplateQueryContinuationExpressionTerm

- (NSString *)prepend
{
    return @"&";
}

@end

#pragma mark -

@interface CSURITemplateUnmodifiedVariable : NSObject <CSURITemplateVariable>

- (id)initWithKey:(NSString *)key;

@end

@implementation CSURITemplateUnmodifiedVariable

@synthesize key;

- (id)initWithKey:(NSString *)aKey
{
    self = [super init];
    if (self) {
        key = aKey;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper error:(NSError *__autoreleasing *)error
{
    id value = [variables objectForKey:key];
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return [NSArray array];
    }
    
    if ([value isKindOfClass:[NSArray class]] && [(NSArray *)value count] == 0) {
        return [NSArray array];
    }
    
    NSMutableArray *result = [NSMutableArray array];
    NSString *escaped = [value csuri_escapeWithEscaper:escaper];
    [result addObject:escaped];
    
    return [NSArray arrayWithArray:result];
}

- (BOOL)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  error:(NSError *__autoreleasing *)error
                                  block:(void (^)(NSString *, NSString *))block
{
    id value = [variables objectForKey:key];
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return YES;
    }
    
    if ([value isEqual:@[]]) {
        block(key, @"");
        return YES;
    }
    
    NSString *escaped = [value csuri_escapeWithEscaper:escaper];
    block(key, escaped);
    return YES;
}

@end

@interface CSURITemplateExplodedVariable : NSObject <CSURITemplateVariable>

- (id)initWithKey:(NSString *)key;

@end

@implementation CSURITemplateExplodedVariable

@synthesize key;

- (id)initWithKey:(NSString *)aKey
{
    self = [super init];
    if (self) {
        key = aKey;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper error:(NSError *__autoreleasing *)error
{
    id values = [variables objectForKey:key];
    if ( ! values) {
        return [NSArray array];
    }
    
    NSMutableArray *result = [NSMutableArray array];
    
    for (id value in [values csuri_explodedItemsEscapedWithEscaper:escaper]) {
        [result addObject:value];
    }
    
    return [NSArray arrayWithArray:result];
}

- (BOOL)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  error:(NSError *__autoreleasing *)error
                                  block:(void (^)(NSString *, NSString *))block
{
    id values = [variables objectForKey:key];
    if ( ! values) {
        return YES;
    }
    
    [values csuri_enumerateExplodedItemsEscapedWithEscaper:escaper
                                          defaultKey:key
                                               block:block];
    return YES;
}

@end

@interface CSURITemplatePrefixedVariable : NSObject <CSURITemplateVariable>

@property (nonatomic, assign) NSUInteger maxLength;

- (id)initWithKey:(NSString *)key maxLength:(NSUInteger)maxLength;

@end

@implementation CSURITemplatePrefixedVariable

@synthesize key;
@synthesize maxLength;

- (id)initWithKey:(NSString *)aKey maxLength:(NSUInteger)aMaxLength
{
    self = [super init];
    if (self) {
        key = aKey;
        maxLength = aMaxLength;
    }
    return self;
}

- (NSArray *)valuesWithVariables:(NSDictionary *)variables escaper:(id<CSURITemplateEscaper>)escaper error:(NSError *__autoreleasing *)error
{
    id value = [variables objectForKey:key];
    
    if ( ! [value isKindOfClass:[NSString class]]) {
        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Variables with a maximum length modifier can only be expanded with string values, but a value of type '%@' given.", nil), [value class]];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"An unexpandable value was given for a template variable.", nil), NSLocalizedFailureReasonErrorKey: failureReason };
        if (error) *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidExpansionValue userInfo:userInfo];
        return nil;
    }
    
    if ( ! value || (NSNull *) value == [NSNull null]) {
        return [NSArray array];
    }

    NSMutableArray *result = [NSMutableArray array];
    NSString *description = [value csuri_basicString];
    if (maxLength <= [description length]) {
        description = [description substringToIndex:maxLength];
    }
    
    [result addObject:[description csuri_escapeWithEscaper:escaper]];
    
    return [NSArray arrayWithArray:result];
}

- (BOOL)enumerateKeyValuesWithVariables:(NSDictionary *)variables
                                escaper:(id<CSURITemplateEscaper>)escaper
                                  error:(NSError *__autoreleasing *)error
                                  block:(void (^)(NSString *, NSString *))block
{
    NSArray *values = [self valuesWithVariables:variables escaper:escaper error:error];
    if ( ! values) {
        // An error was encountered expanding the variables.
        return NO;
    }
    
    for (NSString *value in values) {
        block(key, value);
    }
    return YES;
}

@end

#pragma mark -

@interface CSURITemplate ()

@property (nonatomic, copy, readwrite) NSString *templateString;
@property (nonatomic, copy, readwrite) NSURL *baseURL;
@property (nonatomic, strong) NSMutableArray *terms;

@end

@implementation CSURITemplate

+ (instancetype)URITemplateWithString:(NSString *)templateString error:(NSError **)error
{
    CSURITemplate *URITemplate = [[self alloc] initWithTemplateString:templateString];
    BOOL success = [URITemplate parseTemplate:error];
    return success ? URITemplate : nil;
}

+ (instancetype)URITemplateWithString:(NSString *)templateString relativeToURL:(NSURL *)baseURL error:(NSError **)error
{
    CSURITemplate *URITemplate = [self URITemplateWithString:templateString error:error];
    URITemplate.baseURL = baseURL;
    return URITemplate;
}

- (id)initWithTemplateString:(NSString *)templateString
{
    self = [super init];
    if (self) {
        self.templateString = templateString;
        self.terms = [NSMutableArray array];
    }
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Failed to call designated initializer. Invoke `URITemplateWithString:error:` or `URITemplateWithString:relativeToURL:error:` instead" userInfo:nil];
}

- (NSObject<CSURITemplateVariable> *)variableWithVarspec:(NSString *)varspec error:(NSError **)error
{
    NSParameterAssert(varspec);
    NSParameterAssert(error);
    if ([varspec rangeOfString:@"$"].location != NSNotFound) {
        // Varspec contains a forbidden character.
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The template contains an invalid variable key.", nil),
                                    NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"A variable key containing the forbidden character '$' was encountered.", nil) };
        *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidVariableKey userInfo:userInfo];
        return nil;
    }
    NSMutableCharacterSet *varchars = [NSMutableCharacterSet alphanumericCharacterSet];
    [varchars addCharactersInString:@"._%"];
                                
    NSCharacterSet *modifierStartCharacters = [NSCharacterSet characterSetWithCharactersInString:@":*"];
    NSScanner *scanner = [NSScanner scannerWithString:varspec];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    NSString *key = nil;
    [scanner scanCharactersFromSet:varchars intoString:&key];
    
    NSString *modifierStart = nil;
    [scanner scanCharactersFromSet:modifierStartCharacters intoString:&modifierStart];
    
    if ([modifierStart isEqualToString:@"*"]) {
        // Modifier is explode.

        if ( ! [scanner isAtEnd]) {
            // There were extra characters after the explode modifier.
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"Extra characters were found after the explode modifier ('*') for the variable '%@'.", nil), key];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The template contains an invalid variable modifier.", nil),
                                        NSLocalizedFailureReasonErrorKey: failureReason };
            *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidVariableModifier userInfo:userInfo];
            return nil;
        }
        
        return [[CSURITemplateExplodedVariable alloc] initWithKey:key];
    } else if ([modifierStart isEqualToString:@":"]) {
        // Modifier is prefix.
        NSCharacterSet *oneToNine = [NSCharacterSet characterSetWithCharactersInString:@"123456789"];
        NSCharacterSet *zeroToNine = [NSCharacterSet decimalDigitCharacterSet];
        NSString *firstDigit = @"";
        if ( ! [scanner scanCharactersFromSet:oneToNine intoString:&firstDigit]) {
            // The max-chars does not start with a valid digit.
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"The variable '%@' was followed by the maximum length modifier (':'), but the maximum length argument was prefixed with an invalid character.", nil), key];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The template contains an invalid variable modifier.", nil),
                                        NSLocalizedFailureReasonErrorKey: failureReason };
            *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidVariableModifier userInfo:userInfo];
            return nil;
        }
        NSString *restDigits = @"";
        [scanner scanCharactersFromSet:zeroToNine intoString:&restDigits];
        NSString *digits = [firstDigit stringByAppendingString:restDigits];
        
        if ( ! [scanner isAtEnd]) {
            // The max-chars is not entirely digits.
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"The variable '%@' was followed by the maximum length modifier (':'), but the maximum length argument is not numeric.", nil), key];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The template contains an invalid variable modifier.", nil),
                                        NSLocalizedFailureReasonErrorKey: failureReason };
            *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidVariableModifier userInfo:userInfo];
            return nil;
        }

        NSUInteger maxLength = (NSUInteger)ABS([digits integerValue]);
        return [[CSURITemplatePrefixedVariable alloc] initWithKey:key
                                                        maxLength:maxLength];
    } else {
        // No modifier.
        
        if ( ! [scanner isAtEnd]) {
            // There were extra characters after the key.
            NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"The variable key '%@' is invalid.", nil), varspec];
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"The template contains an invalid variable key.", nil),
                                        NSLocalizedFailureReasonErrorKey: failureReason };
            *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidVariableKey userInfo:userInfo];
            return nil;
        }
        
        return [[CSURITemplateUnmodifiedVariable alloc] initWithKey:key];
    }
    
    return nil;
}

- (NSArray *)variablesWithVariableList:(NSString *)variableList error:(NSError **)error
{
    NSParameterAssert(variableList);
    NSParameterAssert(error);
    NSMutableArray *variables = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:variableList];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    while ( ! [scanner isAtEnd]) {
        NSString *varspec = nil;
        [scanner scanUpToString:@"," intoString:&varspec];
        [scanner scanString:@"," intoString:NULL];
        NSObject<CSURITemplateVariable> *variable = [self variableWithVarspec:varspec error:error];
        if ( ! variable) {
            // An error was encountered parsing the varspec.
            return nil;
        }
        [variables addObject:variable];
    }
    return variables;
}

- (NSObject<CSURITemplateTerm> *)termWithOperator:(NSString *)operator
                                     variableList:(NSString *)variableList
                                            error:(NSError **)error
{
    NSParameterAssert(variableList);
    NSParameterAssert(error);
    if ([operator length] > 1) {
        // The term has an invalid operator.
        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"An operator was encountered with a length greater than 1 character ('%@').", nil), operator];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"An invalid operator was encountered.", nil),
                                    NSLocalizedFailureReasonErrorKey : failureReason };
        *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorInvalidOperator userInfo:userInfo];
        return nil;
    }
    
    NSArray *variables = [self variablesWithVariableList:variableList error:error];
    if ( ! variables) {
        // An error was encountered parsing a variable.
        return nil;
    }
    
    if ([operator isEqualToString:@"/"]) {
        return [[CSURITemplateSolidusExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"."]) {
        return [[CSURITemplateDotExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"#"]) {
        return [[CSURITemplateHashExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"?"]) {
        return [[CSURITemplateQueryExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@";"]) {
        return [[CSURITemplateParameterExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"+"]) {
        return [[CSURITemplateReservedExpressionTerm alloc] initWithVariables:variables];
    } else if ([operator isEqualToString:@"&"]) {
        return [[CSURITemplateQueryContinuationExpressionTerm alloc] initWithVariables:variables];
    } else if ( ! operator) {
        return [[CSURITemplateCommaExpressionTerm alloc] initWithVariables:variables];
    } else {
        // The operator is unknown or reserved.
        NSString *failureReason = [NSString stringWithFormat:NSLocalizedString(@"The URI template specification does not include an operator for the character '%@'.", nil), operator];
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"An unknown operator was encountered.", nil),
                                    NSLocalizedFailureReasonErrorKey : failureReason };
        *error = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorUnknownOperator userInfo:userInfo];
        return nil;
    }
}

- (NSObject<CSURITemplateTerm> *)termWithExpression:(NSString *)expression error:(NSError **)error
{
    NSCharacterSet *operators = [NSCharacterSet characterSetWithCharactersInString:@"+#./;?&=,!@|"];
    NSScanner *scanner = [NSScanner scannerWithString:expression];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

    NSString *operator = nil;
    [scanner scanCharactersFromSet:operators intoString:&operator];
    return [self termWithOperator:operator
                     variableList:[expression substringFromIndex:scanner.scanLocation]
                            error:error];
}

- (BOOL)parseTemplate:(NSError **)error
{
    NSError *parsingError = nil;
    NSScanner *scanner = [NSScanner scannerWithString:self.templateString];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    while ( ! [scanner isAtEnd]) {
        NSCharacterSet *curlyBrackets = [NSCharacterSet
                                         characterSetWithCharactersInString:@"{}"];
        NSString *literal = nil;
        if ([scanner scanUpToCharactersFromSet:curlyBrackets
                                    intoString:&literal]) {
            CSURITemplateLiteralTerm *term = [[CSURITemplateLiteralTerm alloc]
                                                 initWithLiteral:literal];
            [self.terms addObject:term];
        }
        
        NSString *curlyBracket = nil;
        [scanner scanCharactersFromSet:curlyBrackets intoString:&curlyBracket];
        if ([curlyBracket isEqualToString:@"}"]) {
            // An expression was closed but not opened.
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"An expression was closed that was never opened.", nil),
                                        NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"A closing '}' character was encountered that was not preceeded by an opening '{' character.", nil),
                                        CSURITemplateErrorScanLocationErrorKey: @(scanner.scanLocation) };
            parsingError = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorExpressionClosedButNeverOpened userInfo:userInfo];
            break;
        }
        
        NSString *expression = nil;
        if ([scanner scanUpToString:@"}" intoString:&expression]) {
            if ( ! [scanner scanString:@"}" intoString:NULL]) {
                // An expression was opened not closed.
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"An expression was opened but never closed.", nil),
                                            NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"An opening '{' character was never terminated by  '}' character.", nil),
                                            CSURITemplateErrorScanLocationErrorKey: @(scanner.scanLocation) };
                parsingError = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorExpressionOpenedButNeverClosed userInfo:userInfo];
                break;
            }
            
            NSObject<CSURITemplateTerm> *term = [self termWithExpression:expression error:&parsingError];
            if ( ! term) {
                // An error was encountered parsing the term expression. Include the scan location in the error
                NSMutableDictionary *mutableUserInfo = [[parsingError userInfo] mutableCopy];
                mutableUserInfo[CSURITemplateErrorScanLocationErrorKey] = @(scanner.scanLocation);
                break;
            }
            
            [self.terms addObject:term];
        }
    }
    
    if (parsingError && error) *error = parsingError;
    return parsingError ? NO : YES;
}

- (NSString *)relativeStringWithVariables:(NSDictionary *)variables error:(NSError **)error
{
    NSError *expansionError = nil;
    if ( ! variables) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"A template cannot be expanded without a dictionary of variables.", nil) };
        expansionError = [NSError errorWithDomain:CSURITemplateErrorDomain code:CSURITemplateErrorNoVariables userInfo:userInfo];
        if (error) *error = expansionError;
        return nil;
    }
    NSMutableString *result = [NSMutableString string];
    BOOL errorEncountered = NO;
    for (NSObject<CSURITemplateTerm> *term in self.terms) {
        NSString *value = [term expandWithVariables:variables error:&expansionError];
        if ( ! value) {
            // An error was encountered expanding the term.
            errorEncountered = YES;
            break;
        }
        [result appendString:value];
    }
    if (expansionError && error) *error = expansionError;
    return errorEncountered ? nil : [result copy];
}

- (NSURL *)URLWithVariables:(NSDictionary *)variables relativeToBaseURL:(NSURL *)baseURL error:(NSError **)error
{
    NSString *expandedTemplate = [self relativeStringWithVariables:variables error:error];
    if ( ! expandedTemplate) return nil;
    return [NSURL URLWithString:expandedTemplate relativeToURL:baseURL];
}

- (NSArray *)keysOfVariables
{
    NSMutableArray *keys = [NSMutableArray arrayWithCapacity:self.terms.count];
    for (id <CSURITemplateTerm> term in self.terms) {
        if (![term respondsToSelector:@selector(variablesExpression)]) continue;
        for (id <CSURITemplateVariable> variable in [term performSelector:@selector(variablesExpression)]) {
            [keys addObject:variable.key];
        }
    }
    return keys;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p templateString=\"%@\"", self.class, self, self.templateString];
}

@end

@implementation CSURITemplate (Deprecations)

- (id)initWithURITemplate:(NSString *)URITemplate
{
    self = [self initWithTemplateString:URITemplate];
    BOOL success = [self parseTemplate:nil];
    return success ? self : nil;
}

- (NSString *)URIWithVariables:(NSDictionary *)variables
{
    return [self relativeStringWithVariables:variables ?: @{} error:nil];
}

@end
