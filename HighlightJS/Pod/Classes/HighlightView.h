//
//  HighlightView.h
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HighlightJS.h"
#import "HighlightJSAttributedString.h"

NS_ASSUME_NONNULL_BEGIN

@interface HighlightView : UIView
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) HighlightJS *highlighter;
@property (nonatomic, strong) HighlightJSAttributedString *textStorage;
@property (nonatomic, strong) NSLayoutManager *layoutManager;
@property (nonatomic, strong) NSTextContainer *textContainer;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSString *theme;
@end

NS_ASSUME_NONNULL_END
