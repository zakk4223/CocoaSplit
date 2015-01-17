//
//  CSIOSurfaceLayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSIOSurfaceLayer.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

@implementation CSIOSurfaceLayer

@synthesize ioSurface = _ioSurface;
@synthesize ioImage = _ioImage;


-(instancetype)init
{
    if (self = [super init])
    {
        self.asynchronous = YES;
        self.needsDisplayOnBoundsChange = YES;
        self.flipImage = NO;
    }
    
    return self;
}


-(void)setIoSurface:(IOSurfaceRef)ioSurface
{

    _ioSurface = ioSurface;
    @synchronized(self)
    {
        _ioImage = [CIImage imageWithIOSurface:ioSurface];
    }
}

-(IOSurfaceRef)ioSurface
{
    return _ioSurface;
}


-(void) drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    
    CGLSetCurrentContext(ctx);
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);


    if (!_ciCtx || !_ioImage)
    {
        return;
    }
    

    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    if (self.flipImage)
    {
        glOrtho(0, self.bounds.size.width,self.bounds.size.height,0,  -1, 1);
    } else {
        glOrtho(0, self.bounds.size.width,0, self.bounds.size.height,  -1, 1);
    }
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    //I'm cheating here. Technically I should probably care about all the values of contentsGravity, but I know I don't want
    //the modes that don't involve resizing of some type. I don't want the layer to leak outside of the bounds of the superlayer
    //so all I'm doing here is Resize and ResizeAspect.
    
    //This covers kCAGravityResize
    NSRect inRect = self.bounds;
    
    
    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        
        float wr = self.bounds.size.width / _ioImage.extent.size.width;
        float hr = self.bounds.size.height / _ioImage.extent.size.height;
        
        float ratio = (hr < wr ? hr : wr);
        
        NSSize scaledSize = NSMakeSize(_ioImage.extent.size.width * ratio, _ioImage.extent.size.height * ratio);
        
        CGFloat originX = self.bounds.size.width/2 - scaledSize.width/2;
        CGFloat originY = self.bounds.size.height/2 - scaledSize.height/2;
        
        inRect = NSMakeRect(originX, originY, scaledSize.width, scaledSize.height);
    }
    
    @synchronized(self)
    {
        [_ciCtx drawImage:_ioImage inRect:inRect fromRect:_ioImage.extent];
    }
    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    
}




-(CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    CGLContextObj contextObj = [super copyCGLContextForPixelFormat:pf];
    
    _ciCtx = [CIContext contextWithCGLContext:contextObj pixelFormat:pf colorSpace:nil options:@{kCIContextWorkingColorSpace: [NSNull null]}];
    return contextObj;
}



@end
