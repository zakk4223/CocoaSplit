//
//  NSLayoutSwitcherView.h
//  CocoaSplit
//
//  Created by Zakk on 3/6/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"

@interface CSSTextView : NSTextView
@end


@interface CSLayoutSwitcherView : NSView
{
    CATextLayer *_labelLayer;
    CSSTextView *_textView;
    
}
@property (strong) SourceLayout *sourceLayout;

@end
