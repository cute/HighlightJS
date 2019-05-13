//
//  HighlightJSAttributedString.m
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import "HighlightJSAttributedString.h"

@implementation HighlightJSAttributedString
// Initialize the CodeAttributedString
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

// Initialize the CodeAttributedString
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    _language = @"javascript";
    self.stringStorage = [[NSMutableAttributedString alloc] initWithString:@""];
    self.highlightJS = [HighlightJS new];
    __weak typeof(self) weakSelf = self;
    self.highlightJS.themeChangedBlock = ^(HighlightJSTheme * _Nonnull theme) {
        [weakSelf highlight:NSMakeRange(0, weakSelf.stringStorage.length)];
    };
}


#if TARGET_OS_OSX
// Initialize the CodeAttributedString
#endif

// Language syntax to use for highlighting. Providing nil will disable highlighting.
- (void)setLanguage:(NSString *)language
{
    _language = language;
    [self highlight:NSMakeRange(0, self.stringStorage.length)];
}

// Returns a standard String based on the current one.
- (NSString *)string
{
    return self.stringStorage.string;
}

/**
 Returns the attributes for the character at a given index.
 
 - parameter location: Int
 - parameter range:    NSRangePointer
 
 - returns: Attributes
 */
- (NSDictionary<NSAttributedStringKey,id> *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    return [self.stringStorage attributesAtIndex:location effectiveRange:range];
}

/**
 Replaces the characters at the given range with the provided string.
 
 - parameter range: NSRange
 - parameter str:   String
 */
-(void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    [self.stringStorage replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters range:range changeInLength:str.length - range.length];
}

/**
 Sets the attributes for the characters in the specified range to the given attributes.
 
 - parameter attrs: [String : AnyObject]
 - parameter range: NSRange
 */

-(void)setAttributes:(NSDictionary<NSAttributedStringKey,id> *)attrs range:(NSRange)range
{
    [self.stringStorage setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

/// Called internally everytime the string is modified.
- (void)processEditing
{
    [super processEditing];
    if (self.language && (self.editedMask & NSTextStorageEditedCharacters)) {
        NSRange range = [self.string paragraphRangeForRange:self.editedRange];
        [self highlight:range];
    }
}

- (void)highlight:(NSRange)range
{
    if (!self.language) {
        return;
    }

    if (self.highlightDelegate &&
        [self.highlightDelegate respondsToSelector:@selector(shouldHighlight:)] &&
        ![self.highlightDelegate shouldHighlight:range]) {
        return;
    }
    
    NSString *string = self.string;
    NSString *line = [string substringWithRange:range];

    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSAttributedString *tmpStrg = [self.highlightJS highlightWithCode:line languageName:self.language fastRender:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            //Checks to see if this highlighting is still valid.
            if ((range.location + range.length) > self.stringStorage.length) {
                if (self.highlightDelegate) {
                    [self.highlightDelegate didHighlight:range success:NO];
                }
                return;
            }

            if (![tmpStrg.string isEqualToString:[self.stringStorage attributedSubstringFromRange:range].string]) {
                if (self.highlightDelegate) {
                    [self.highlightDelegate didHighlight:range success:NO];
                }
                return;
            }
    
            [self beginEditing];
            [tmpStrg enumerateAttributesInRange:NSMakeRange(0, tmpStrg.length)
                                        options:0
                                     usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange locRange, BOOL * _Nonnull stop) {
                                         NSRange fixedRange = NSMakeRange(range.location+locRange.location, locRange.length);
                                         fixedRange.length = (fixedRange.location + fixedRange.length < string.length) ? fixedRange.length : string.length-fixedRange.location;
                                         fixedRange.length = (fixedRange.length >= 0) ? fixedRange.length : 0;
                                         [self.stringStorage setAttributes:attrs range:fixedRange];
                                     }];
            [self endEditing];
            [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
            if (self.highlightDelegate) {
                [self.highlightDelegate didHighlight:range success:YES];
            }
        });
    });
}

@end
