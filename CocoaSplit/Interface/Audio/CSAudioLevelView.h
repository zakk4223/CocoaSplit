//
//  CSAudioLevelView.h
//  CocoaSplit
//
//  Created by Zakk on 8/6/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CSAudioLevelView : NSView
{
    bool _isVertical;
}


@property (assign) float level;
@property (assign) IBInspectable float startValue;
@property (assign) IBInspectable float endValue;
@property (strong) IBInspectable NSColor *backgroundColor;
@property (assign) IBInspectable float backgroundSize;


@end
