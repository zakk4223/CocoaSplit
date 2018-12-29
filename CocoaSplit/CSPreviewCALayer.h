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
    CVPixelBufferRef _renderBuffer;
    NSRect _lastBounds;
    NSSize _lastSurfaceSize;
    float _scaleRatio;
    NSRect _scaleRect;
}


@property (strong) LayoutRenderer *renderer;
@property (assign) bool doRender;
@property (assign) bool midiActive;
@property (assign) bool resizeDirty;


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;

@end

NS_ASSUME_NONNULL_END
