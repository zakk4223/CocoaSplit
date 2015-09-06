//
//  CSPreviewOverlayView.h
//  CocoaSplit
//
//  Created by Zakk on 8/31/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InputSource.h"

@class PreviewView;

@interface CSPreviewOverlayView : NSView
{
    NSButton *_closeButton;
}

@property (weak) InputSource *parentSource;
@property (weak) PreviewView *previewView;
-(void)updatePosition;

@end
