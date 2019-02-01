//
//  CSPreviewMetalLayer.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/18.
//  Copyright © 2018 Zakk. All rights reserved.
//

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CAMetalLayer.h>
#import "CSPreviewRendererLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSPreviewCALayer : CALayer <CSPreviewRendererLayer>
{
    
    CVDisplayLinkRef _displayLink;
    dispatch_queue_t _displayQueue;
    NSRect _lastBounds;
    NSSize _lastSurfaceSize;
    float _scaleRatio;
    NSRect _scaleRect;
    NSUInteger _frameCnt;
    CFTimeInterval _lastFpsTime;
    float _minRenderTime;
    float _maxRenderTime;
    float _avgRenderTime;
    float _sumRenderTime;
}


@property (strong) LayoutRenderer *renderer;
@property (assign) bool doRender;
@property (assign) bool midiActive;
@property (assign) bool resizeDirty;
@property (assign) float measuredFrameRate;
@property (assign) float minRenderTime;
@property (assign) float maxRenderTime;
@property (assign) float avgRenderTime;
@property (assign) bool doDisplay;


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;

@end

NS_ASSUME_NONNULL_END
