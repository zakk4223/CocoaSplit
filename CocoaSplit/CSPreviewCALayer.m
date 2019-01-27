//
//  CSPreviewMetalLayer.m
//  CocoaSplit
//
//  Created by Zakk on 12/27/18.
//

#import "CSPreviewCALayer.h"
CVReturn DisplayCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext);


@implementation CSPreviewCALayer


-(instancetype) init
{
    if (self = [super init])
    {
        self.contentsGravity = kCAGravityResizeAspect;
        _lastBounds = NSZeroRect;
        _lastSurfaceSize = NSZeroSize;
        CVDisplayLinkCreateWithCGDisplay(CGMainDisplayID(), &_displayLink);
        CVDisplayLinkSetOutputCallback(_displayLink, &DisplayCallback, (__bridge void * _Nullable)(self));
        CVDisplayLinkStart(_displayLink);
    }
    
    return self;
}

-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint
{
    return NSMakePoint((winPoint.x - _scaleRect.origin.x)/_scaleRatio, (winPoint.y - _scaleRect.origin.y)/_scaleRatio);
}


-(NSRect)windowRectforWorldRect:(NSRect)worldRect
{
    NSPoint windowOrigin = NSMakePoint((worldRect.origin.x*_scaleRatio)+_scaleRect.origin.x, (worldRect.origin.y*_scaleRatio)+_scaleRect.origin.y);
    NSSize windowSize = NSMakeSize(worldRect.size.width*_scaleRatio, worldRect.size.height*_scaleRatio);
    return NSMakeRect(windowOrigin.x, windowOrigin.y, windowSize.width, windowSize.height);
}

-(void)updateScaleConstants
{
    float wr = _lastBounds.size.width / _lastSurfaceSize.width;
    float hr = _lastBounds.size.height / _lastSurfaceSize.height;
    
    
    _scaleRatio = (hr < wr ? hr : wr);
    NSSize useSize = NSMakeSize(_lastSurfaceSize.width * _scaleRatio, _lastSurfaceSize.height * _scaleRatio);
    
    CGFloat originX = _lastBounds.size.width/2 - useSize.width/2;
    CGFloat originY = _lastBounds.size.height/2 - useSize.height/2;
    _scaleRect = NSMakeRect(originX, originY, useSize.width, useSize.height);
}




-(void)render
{
    if (!self.renderer || !self.renderer.layout)
    {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
                   , ^{
                       @autoreleasepool {
                           
                           
                           [CATransaction begin];
                               [self displayContent];
                          [CATransaction commit];
                       }
                   });
    
}


-(void)displayContent
{

    CVPixelBufferRef toDraw;
 
    bool sizeDirty = NO;
    
    if (!self.renderer)
    {
        return;
    }
    
    if (self.doRender)
    {
        toDraw = [self.renderer currentImg];
        if (toDraw)
        {
            CVPixelBufferRetain(toDraw);
        }
    } else {
        toDraw = [self.renderer currentFrame];
    }
    
    if (!toDraw)
    {
        return;
    }
    
    
    size_t sWidth = CVPixelBufferGetWidth(toDraw);
    size_t sHeight = CVPixelBufferGetHeight(toDraw);
    NSSize sSize = NSMakeSize(sWidth, sHeight);
    if (!NSEqualSizes(sSize, _lastSurfaceSize))
    {
        _lastSurfaceSize = sSize;
        sizeDirty = YES;
    }

    if (!NSEqualRects(_lastBounds, self.bounds))
    {
        _lastBounds = self.bounds;
        sizeDirty = YES;
    }
    
    if (sizeDirty)
    {
        [self updateScaleConstants];
    }
    
    
    self.contentsGravity = kCAGravityResizeAspect;
    self.minificationFilter = kCAFilterLinear;
    self.magnificationFilter = kCAFilterTrilinear;
    
    if (toDraw)
    {
        if (@available(macOS 10.12, *))
        {
            self.contents = (__bridge id _Nullable)toDraw;
        } else {
            self.contents = (__bridge id _Nullable)(CVPixelBufferGetIOSurface(toDraw));
        }
     }
    
    CVPixelBufferRelease(toDraw);
}

CVReturn DisplayCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext)
{
    CSPreviewCALayer *realSelf = (__bridge CSPreviewCALayer *)displayLinkContext;
    [realSelf render];
    return kCVReturnSuccess;
}

-(void)dealloc
{
    if (_displayLink)
    {
        CVDisplayLinkStop(_displayLink);
        CVDisplayLinkRelease(_displayLink);
    }
}



@end
