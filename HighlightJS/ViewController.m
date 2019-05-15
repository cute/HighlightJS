//
//  ViewController.m
//  HighlightJS
//
//  Created by Li Guangming on 2019/5/13.
//  Copyright © 2019 Li Guangming. All rights reserved.
//

#import "ViewController.h"
#import "HLJSTextView.h"
#import "NSString+HLJS.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    HLJSTextView *view = [[HLJSTextView alloc] initWithFrame:self.view.bounds];
    view.language = @"javascript";
    view.text = @"function $initHighlight(block, cls) {\n  try {\n    if (cls.search(/\bno-highlight\b/) != -1)\n      return process(block, true, 0x0F) +\n             ` class=\"${cls}\"`;\n  } catch (e) {\n    /* handle exception */\n  }\n  for (var i = 0 / 2; i < classes.length; i++) {\n    if (checkCondition(classes[i]) === undefined)\n      console.log('undefined');\n  }\n}\n\nexport  $initHighlight;";
    [self.view addSubview:view];
}


@end
