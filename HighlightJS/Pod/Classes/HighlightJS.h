//
//  HighlightJS.h
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import "HighlightJSTheme.h"

NS_ASSUME_NONNULL_BEGIN


typedef void(^HighlightJSThemeChangedBlock)(HighlightJSTheme *theme);

@interface HighlightJS : NSObject

@property (nonatomic, strong) HighlightJSTheme *theme;
@property (nonatomic, copy) HighlightJSThemeChangedBlock themeChangedBlock;

- (void)setThemeWithName:(NSString *)name;
- (NSAttributedString *)highlightWithCode:(NSString *)code languageName:(NSString *)languageName fastRender:(BOOL)fastRender;

@end

NS_ASSUME_NONNULL_END
