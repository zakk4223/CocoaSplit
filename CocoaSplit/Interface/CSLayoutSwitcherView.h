//
//  NSLayoutSwitcherView.h
//  CocoaSplit
//
//  Created by Zakk on 3/6/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"

@class CSLayoutSwitcherViewController;

@interface CSSTextView : NSTextView
@end


@interface CSLayoutSwitcherView : NSView
{
    CATextLayer *_labelLayer;
    CSSTextView *_textView;
    NSImageView *_recordImageView;
    
}
@property (strong) SourceLayout *sourceLayout;
@property (assign) bool isSwitcherView;
@property (weak) CSLayoutSwitcherViewController *controller;

-(instancetype)initWithIsSwitcherView:(bool)isSwitcherView;

@end
