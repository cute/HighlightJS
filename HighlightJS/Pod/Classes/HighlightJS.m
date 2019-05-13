//
//  HighlightJS.m
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import "HighlightJS.h"
#import "HighlightJSHTMLUtils.h"
#import <JavaScriptCore/JavaScriptCore.h>

@interface HighlightJS ()
@property (nonatomic, strong) JSContext *jsContext;
@property (nonatomic, strong) NSString *hljs;
@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) NSString *htmlStart;
@property (nonatomic, strong) NSString *spanStart;
@property (nonatomic, strong) NSString *spanStartClose;
@property (nonatomic, strong) NSString *spanEnd;
@property (nonatomic, strong) NSRegularExpression *htmlEscape;
@end

@implementation HighlightJS
/**
 Default init method.
 
 - returns: HighlightJS instance.
 */

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hljs = @"window.hljs";
        self.htmlStart = @"<";
        self.spanStart = @"span class=\"";
        self.spanStartClose = @"\">";
        self.spanEnd = @"/span>";
        self.htmlEscape = [NSRegularExpression regularExpressionWithPattern:@"&#?[a-zA-Z0-9]+?;"
                                                                    options:NSRegularExpressionCaseInsensitive error:nil];
        
        self.jsContext = [JSContext new];
        [self.jsContext evaluateScript:@"var window = {};"];
        self.bundle = [NSBundle bundleForClass:[HighlightJS class]];
        NSString *hgPath = [self.bundle pathForResource:@"highlight.min" ofType:@"js"];
        NSString *content = [NSString stringWithContentsOfFile:hgPath encoding:NSUTF8StringEncoding error:nil];
        if (content) {
            [self.jsContext evaluateScript:content];
            [self setThemeWithName:@"monokai"];
        }
    }
    return self;
}
/**
 Set the theme to use for highlighting.
 
 - parameter to: Theme name
 
 - returns: true if it was possible to set the given theme, false otherwise
 */

- (void)setThemeWithName:(NSString *)name
{
    NSString *file = [NSString stringWithFormat:@"%@.min", name];
    NSString *cssPath = [self.bundle pathForResource:file ofType:@"css"];
    NSString *themeString = [NSString stringWithContentsOfFile:cssPath encoding:NSUTF8StringEncoding error:nil];
    self.theme = [[HighlightJSTheme alloc] initWithThemeString:themeString];
}

- (void)setTheme:(HighlightJSTheme *)theme
{
    _theme = theme;
    if (self.themeChangedBlock) {
        self.themeChangedBlock(theme);
    }
}

/**
 Takes a String and returns a NSAttributedString with the given language highlighted.
 
 - parameter code:           Code to highlight.
 - parameter languageName:   Language name or alias. Set to `nil` to use auto detection.
 - parameter fastRender:     Defaults to true - When *true* will use the custom made html parser rather than Apple's solution.
 
 - returns: NSAttributedString with the detected code highlighted.
 */

- (NSAttributedString *)highlightWithCode:(NSString *)code languageName:(NSString *)languageName fastRender:(BOOL)fastRender
{
    NSString *fixedCode = [code stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    fixedCode = [fixedCode stringByReplacingOccurrencesOfString:@"\'" withString:@"\\\'"];
    fixedCode = [fixedCode stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    fixedCode = [fixedCode stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    fixedCode = [fixedCode stringByReplacingOccurrencesOfString:@"\r" withString:@""];

    NSString *command;
    if (languageName) {
        command = [NSString stringWithFormat:@"%@.highlight(\"%@\",\"%@\").value;", self.hljs, languageName, fixedCode];
    } else {
        // language auto detection
        command = [NSString stringWithFormat:@"%@.highlightAuto(\"%@\").value;", self.hljs, fixedCode];
    }

    JSValue *res = [self.jsContext evaluateScript:command];

    if (![res isString]) {
        return nil;
    }

    NSString *string = [res toString];
    if (fastRender) {
        return [self processHTMLString:string];
    }
    
    string = [NSString stringWithFormat:@"<style>%@</style><pre><code class=\"hljs\">%@</code></pre>",
              self.theme.lightTheme, string];
    NSDictionary *opt = @{
                          NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                          NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                          };
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSAttributedString alloc] initWithData:data options:opt documentAttributes:nil error:nil];
}

/**
 Returns a list of all the available themes.
 
 - returns: Array of Strings
 */

- (NSArray *)availableThemes
{
    NSArray *paths = [self.bundle pathsForResourcesOfType:@"css" inDirectory:nil];
    NSMutableArray *result = [NSMutableArray new];
    for (NSString *path in paths) {
        NSString *s = [path.lastPathComponent stringByReplacingOccurrencesOfString:@".min.css" withString:@""];
        [result addObject:s];
    }
    return result;
}

/**
 Returns a list of all supported languages.
 
 - returns: Array of Strings
 */
- (NSArray *)supportedLanguages
{
    NSString *command = [NSString stringWithFormat:@"%@.listLanguages();", self.hljs];
    JSValue *res = [self.jsContext evaluateScript:command];
    return [res toArray];
}

- (NSAttributedString *)processHTMLString:(NSString *)string
{
    NSScanner *scanner = [NSScanner scannerWithString:string];
    
    scanner.charactersToBeSkipped = nil;
    NSString *scannedString;
    NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:@""];
    NSMutableArray *propStack = [NSMutableArray arrayWithObjects:@"hljs", nil];
    
    while (!scanner.isAtEnd) {
        BOOL ended = NO;
        if ([scanner scanUpToString:self.htmlStart intoString:&scannedString]) {
            if (scanner.isAtEnd) {
                ended = YES;
            }
        }

        if (scannedString  && scannedString.length > 0) {
            NSAttributedString *attrScannedString = [self.theme applyStyleToString:scannedString styleList:propStack];
            [resultString appendAttributedString:attrScannedString];
            if (ended) {
                continue;
            }
        }
        
        scanner.scanLocation += 1;
        
        NSString *string = scanner.string;
        
        NSString *nextChar = [string substringWithRange:NSMakeRange(scanner.scanLocation, 1)];
        if([nextChar isEqualToString:@"s"]) {
            scanner.scanLocation += self.spanStart.length;
            [scanner scanUpToString:self.spanStartClose intoString:&scannedString];
            scanner.scanLocation += self.spanStartClose.length;
            [propStack addObject:scannedString];
        } else if([nextChar isEqualToString:@"/"]) {
            scanner.scanLocation += self.spanEnd.length;
            [propStack removeLastObject];
        } else {
            NSAttributedString *attrScannedString = [self.theme applyStyleToString:@"<" styleList:propStack];
            [resultString appendAttributedString:attrScannedString];
            scanner.scanLocation += 1;
        }
        
        scannedString = nil;
    }
    
    NSArray *results = [self.htmlEscape matchesInString:resultString.string
                                                options:NSMatchingReportCompletion
                                                  range:NSMakeRange(0, resultString.length)];

    
    NSUInteger locOffset = 0;
    for (NSTextCheckingResult *result in results) {
        NSRange fixedRange = NSMakeRange(result.range.location-locOffset, result.range.length);
        NSString *entity = [resultString.string substringWithRange:fixedRange];
        NSString *decodedEntity = [HighlightJSHTMLUtils decode:entity];
        if (decodedEntity) {
            [resultString replaceCharactersInRange:fixedRange withString:decodedEntity];
            locOffset += result.range.length - 1;
        }
    }
    return resultString;
}

@end
