//
//  NSLayoutSwitcherView.h
//  CocoaSplit
//
//  Created by Zakk on 3/6/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SourceLayout.h"
#import "LayoutRenderer.h"

@class CSLayoutSwitcherViewController;

@interface CSSTextView : NSTextView
@end


@interface CSLayoutSwitcherView : NSView
{
    CATextLayer *_labelLayer;
    CSSTextView *_textView;
    NSImageView *_recordImageView;
    
}

@property (weak) LayoutRenderer *useRenderer;
@property (strong) SourceLayout *sourceLayout;
@property (weak) CSLayoutSwitcherViewController *controller;
@property (assign) bool clickable;
@property (assign) bool showTitle;

-(instancetype)initWithIsSwitcherView:(bool)isSwitcherView;

@end
