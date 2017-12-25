//
//  CSSequenceActivatorView.h
//  CocoaSplit
//
//  Created by Zakk on 3/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSLayoutSequence.h"

@class CSSequenceActivatorViewController;

@interface CSSequenceTextView : NSTextView
@end

@interface CSSequenceActivatorView : NSView
{
    CSSequenceTextView *_textView;
}
@property (weak) CSLayoutSequence *layoutSequence;
@property (weak) CSSequenceActivatorViewController *controller;
@property (assign) bool isQueued;

@end
