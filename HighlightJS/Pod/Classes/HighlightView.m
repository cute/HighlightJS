//
//  HighlightView.m
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import "HighlightView.h"

@implementation HighlightView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.textStorage = [HighlightJSAttributedString new];
    self.layoutManager = [NSLayoutManager new];
    self.textContainer = [[NSTextContainer alloc] initWithSize:CGSizeZero];
    
    [self.textStorage addLayoutManager:self.layoutManager];
    [self.layoutManager addTextContainer:self.textContainer];
    
    self.highlighter = self.textStorage.highlightJS;
    self.language = @"javascript";

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITextView *textView = [[UITextView alloc] initWithFrame:self.bounds textContainer:self.textContainer];
    self.textView = textView;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textView.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
     textView.backgroundColor = self.highlighter.theme.themeBackgroundColor;
    [self addSubview:textView];
}

- (void)setText:(NSString *)text
{
    self.textView.text = text;
}

- (NSString *)text
{
    return self.textView.text;
}

- (UIFont *)font
{
    return self.highlighter.theme.codeFont;
}

- (void)setFont:(UIFont *)font
{
    self.highlighter.theme.codeFont = font;
}

-(NSString *)language
{
    return self.textStorage.language;
}

- (void)setLanguage:(NSString *)language
{
    self.textStorage.language = language;
}

- (NSString *)themeName
{
    return _theme;
}

- (void)setThemeName:(NSString *)theme
{
    _theme = theme;
    [self.textStorage.highlightJS setThemeWithName:theme];
    self.textView.backgroundColor = self.highlighter.theme.themeBackgroundColor;
}

@end
