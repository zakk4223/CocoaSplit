//
//  CSSyphonCaptureLayer.m
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 2/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSSyphonCaptureLayer.h"

@implementation CSSyphonCaptureLayer

@synthesize flipImage = _flipImage;

-(instancetype)init
{
    if (self = [super init])
    {
        self.asynchronous = NO;
        self.needsDisplayOnBoundsChange = YES;
        self.flipImage = NO;
    }
    
    return self;
}


-(void)calculateCrop:(CGSize)forSize;
{
    CGRect newCrop;
    
    newCrop.origin.x = forSize.width * _privateCropRect.origin.x;
    newCrop.origin.y = forSize.height * _privateCropRect.origin.y;
    newCrop.size.width = forSize.width * _privateCropRect.size.width;
    newCrop.size.height = forSize.height * _privateCropRect.size.height;
    //_lastImageSize = forSize;
    _calculatedCrop = newCrop;
}


-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
    [self calculateCrop:_lastImageSize];
    _needsRedraw = YES;
    [self setNeedsDisplay];
}

-(CGRect)contentsRect
{
    return _privateCropRect;
}

-(void)setFlipImage:(bool)flipImage
{
    _flipImage = flipImage;
    _needsRedraw = YES;
    [self setNeedsDisplay];
}

-(bool)flipImage
{
    return _flipImage;
}


-(CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    _myCGLContext = [super copyCGLContextForPixelFormat:pf];

    return _myCGLContext;
}


/*
-(BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    

    bool boundsChanged = !CGRectEqualToRect(self.bounds, _lastBounds);
    
    if (boundsChanged || self.syphonClient.hasNewFrame || _needsRedraw)
    {
        return YES;
    }

    return NO;
}
 */





-(void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    CGLContextObj cgl_ctx = ctx;
    CGLSetCurrentContext(ctx);
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);


    SyphonImage *image = [self.syphonClient newFrameImageForContext:cgl_ctx];
    
    
    if (!image)
    {
        return;
    }
    
    bool imageSizeChanged = !CGSizeEqualToSize(_lastImageSize, image.textureSize);
    
    
    
    if (imageSizeChanged)
    {
        [self calculateCrop:image.textureSize];
    }
    
    _lastCrop = _calculatedCrop;
    
    _lastImageSize = image.textureSize;

    _lastBounds  = self.bounds;
    
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0.0, self.bounds.size.width, 0.0, self.bounds.size.height, -1, 1);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    

    
    glTranslated(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5, 0.0);
    
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, image.textureName);
    
    GLfloat tex_coords[] =
    {
        _calculatedCrop.origin.x ,  _calculatedCrop.origin.y,
         _calculatedCrop.origin.x+_calculatedCrop.size.width, _calculatedCrop.origin.y,
         _calculatedCrop.origin.x+_calculatedCrop.size.width, _calculatedCrop.origin.y+_calculatedCrop.size.height,
        _calculatedCrop.origin.x,    _calculatedCrop.origin.y+_calculatedCrop.size.height
    };
    
    NSSize useSize = self.bounds.size;
    
    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        float wr = _calculatedCrop.size.width / self.bounds.size.width;
        float hr = _calculatedCrop.size.height / self.bounds.size.height;
    
        float ratio = (hr < wr ? wr : hr);
        useSize = NSMakeSize(_calculatedCrop.size.width / ratio, _calculatedCrop.size.height / ratio);
        
    }
    
    
    float halfw = useSize.width * 0.5;
    float halfh = useSize.height * 0.5;
    
    if (self.flipImage)
    {
        halfh *= -1;
    }
    
    
    GLfloat verts[] =
    {
        -halfw, halfh,
        halfw, halfh,
        halfw, -halfh,
        -halfw, -halfh
    };
    
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
    glDisable(GL_TEXTURE_RECTANGLE_EXT);
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    _needsRedraw = NO;
    

}


@end
