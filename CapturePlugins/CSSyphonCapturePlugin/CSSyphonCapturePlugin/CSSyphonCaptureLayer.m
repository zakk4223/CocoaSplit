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


/*
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
*/


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


-(BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    

    return YES;
}





-(void)drawLayerContents:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts{
    CGLContextObj cgl_ctx = ctx;
    CGLSetCurrentContext(ctx);

    
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);

    SyphonImage *image = [self.syphonClient newFrameImageForContext:cgl_ctx];
    
    
    if (!image)
    {
        return;
    }
    
    _lastImageSize = image.textureSize;

    self.textureSize = _lastImageSize;
    
    bool imageSizeChanged = !CGSizeEqualToSize(_lastImageSize, image.textureSize);
    
    
    GLfloat tex_coords[] =
    {
        
        0.0f ,  0.0f,
        self.textureSize.width, 0.0f,
        self.textureSize.width, self.textureSize.height,
        0.0f,    self.textureSize.height
    };
    
    
    GLfloat verts[] =
    {
        -1.0f ,  -1.0f,
        1.0f, -1.0f,
        1.0f, 1.0f,
        -1.0f,    1.0f
    };
    
    glEnable(GL_TEXTURE_RECTANGLE_EXT);
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, image.textureName);
    
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
    glDisableClientState( GL_TEXTURE_COORD_ARRAY );
    glDisableClientState(GL_VERTEX_ARRAY);
    
    glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
    glDisable(GL_TEXTURE_RECTANGLE_EXT);
    

}


@end
