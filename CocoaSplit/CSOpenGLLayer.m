//
//  CSOpenGLLayer.m
//  CocoaSplit
//
//  Created by Zakk on 2/20/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSOpenGLLayer.h"


@implementation CSOpenGLLayer


-(instancetype)initWithSize:(NSSize)size
{
    if (self = [super init])
    {
        self.textureSize = size;
    }
    return self;
}



-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
}

-(CGRect)contentsRect
{
    return _privateCropRect;
}

-(void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    
    CGLSetCurrentContext(ctx);
    NSRect pjRect;
    
    pjRect.origin.x = -1.0f + (2.0f*_privateCropRect.origin.x);
    pjRect.size.width = (2.0f*_privateCropRect.size.width);
    pjRect.origin.y = -1.0f + (2.0f*_privateCropRect.origin.y);
    pjRect.size.height = (2.0f*_privateCropRect.size.height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(pjRect.origin.x, NSMaxX(pjRect), pjRect.origin.y, NSMaxY(pjRect), -1.0f, 1.0f);

    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    
    
    [self drawLayerContents:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
}



-(void)drawLayerContents:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    return;
}
@end
