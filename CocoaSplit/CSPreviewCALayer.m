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
        //CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
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

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [CATransaction commit];
    
    
}




-(void)render
{
    dispatch_async(dispatch_get_main_queue()
                   , ^{
                       [self display];
                   });
}


-(void)display
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
    
    if (_renderBuffer)
    {
        CVPixelBufferRelease(_renderBuffer);
    }
    _renderBuffer = toDraw;
    
    size_t sWidth = CVPixelBufferGetWidth(_renderBuffer);
    size_t sHeight = CVPixelBufferGetHeight(_renderBuffer);
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
    
    if (_renderBuffer)
    {
        if (@available(macOS 10.12, *))
        {
            self.contents = (__bridge id _Nullable)_renderBuffer;
        } else {
            self.contents = (__bridge id _Nullable)(CVPixelBufferGetIOSurface(_renderBuffer));
        }
     }
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
