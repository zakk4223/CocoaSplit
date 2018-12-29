//
//  CSPreviewGLLayer.m
//  CocoaSplit
//
//  Created by Zakk on 8/8/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSPreviewGLLayer.h"

@implementation CSPreviewGLLayer
@synthesize midiActive = _midiActive;

-(instancetype)init
{
    if (self = [super init])
    {
        _initDone = NO;
        _lastSurfaceSize = NSZeroSize;
        self.needsDisplayOnBoundsChange = YES;
        self.opaque = YES;
        
    }
    
    return self;
}


-(void)setMidiActive:(bool)midiActive
{
    _midiActive = midiActive;
    _resetClearColor = YES;
}

-(bool)midiActive
{
    return _midiActive;
}


-(void)logGLMatrix:(GLKMatrix4)mat
{
    NSLog(@"    %f %f %f %f", mat.m00, mat.m10, mat.m20, mat.m30);
    NSLog(@"    %f %f %f %f", mat.m01, mat.m11, mat.m21, mat.m31);
    NSLog(@"    %f %f %f %f", mat.m02, mat.m12, mat.m22, mat.m32);
    NSLog(@"    %f %f %f %f", mat.m03, mat.m13, mat.m23, mat.m33);
}

-(void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{

    CGLSetCurrentContext(ctx);
    
    if (!_initDone)
    {
        glGenTextures(1, &_renderTexture);
        _initDone = YES;
    }
    
    
    glClearColor(0.329412,0.329412,0.329412,0);

    
/*
    if (_resetClearColor)
    {
        if (self.midiActive)
        {
            glClearColor(0.309804f, 0.184314f, 0.309804f, 0);
        } else {
            glClearColor(0.184314f, 0.309804f, 0.309804f, 0);
        }
        
        _resetClearColor = NO;
    }
  */
    
    glClear(GL_COLOR_BUFFER_BIT);

    if (!self.renderer)
    {
        return;
    }
    
    
    CVPixelBufferRef toDraw;
    if (self.doRender)
    {
     
        toDraw = [self.renderer currentImg];
        CGLSetCurrentContext(ctx);
        
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

    
    IOSurfaceRef drawSurface = CVPixelBufferGetIOSurface(toDraw);
    
    
    size_t surfaceWidth = IOSurfaceGetWidth(drawSurface);
    size_t surfaceHeight = IOSurfaceGetHeight(drawSurface);
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _renderTexture);
    
    CGLTexImageIOSurface2D(ctx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, (GLsizei)surfaceWidth, (GLsizei)surfaceHeight, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, drawSurface, 0);
    
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    NSSize surfaceSize = NSMakeSize(surfaceWidth, surfaceHeight);
    
    if (!NSEqualSizes(surfaceSize, _lastSurfaceSize))
    {
        _resizeDirty = YES;
        _lastSurfaceSize = surfaceSize;
    }
    
    
    float wr = self.bounds.size.width / surfaceSize.width;
    float hr = self.bounds.size.height/ surfaceSize.height;
    
    
    float ratio = (hr < wr ? hr : wr);
    NSSize useSize = NSMakeSize(surfaceSize.width * ratio, surfaceSize.height * ratio);

    CGFloat originX = self.bounds.size.width/2 - useSize.width/2;
    CGFloat originY = self.bounds.size.height/2 - useSize.height/2;
    
    NSRect inRect = NSMakeRect(originX, originY, useSize.width, useSize.height);
    inRect = NSIntegralRect(inRect);
    
    float halfw = (self.bounds.size.width - useSize.width) * 0.5;
    float halfh = (self.bounds.size.height - useSize.height) * 0.5;

    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    
   glOrtho(0.0, self.bounds.size.width, 0.0, self.bounds.size.height, 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glTranslated(halfw, halfh, 0.0);
   glScalef(ratio, ratio, 1.0f);
    
    if (_resizeDirty)
    {
        GLfloat    glmat[16];
        
        glGetFloatv(GL_MODELVIEW_MATRIX, glmat);
        _modelview = GLKMatrix4MakeWithArray(glmat);
        glGetFloatv(GL_PROJECTION_MATRIX, glmat);
        _projection = GLKMatrix4MakeWithArray(glmat);
        
        glGetIntegerv(GL_VIEWPORT, _viewport);
        _resizeDirty = NO;
    }
    
    
    GLfloat tex_coords[] =
    {
        0.0,0.0,
        surfaceWidth, 0.0,
        surfaceWidth, surfaceHeight,
        0.0, surfaceHeight
    };
    
    GLfloat verts[] =
    {
        0, surfaceHeight,
        surfaceWidth, surfaceHeight,
        surfaceWidth, 0,
        0,0
    };
    
    
    glEnableClientState( GL_TEXTURE_COORD_ARRAY );
    glTexCoordPointer(2, GL_FLOAT, 0, tex_coords );
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts );
    glDrawArrays( GL_TRIANGLE_FAN, 0, 4 );
    glDisable( GL_TEXTURE_COORD_ARRAY );
    glDisable(GL_VERTEX_ARRAY);
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    
    
    
    GLfloat snapx_verts[4];
    GLfloat snapy_verts[4];
    
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    
    glLineWidth(2.0f);
    
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    

    
    glColor4f(1.0, 1.0, 1.0, 1.0);
    
    GLfloat textureCoords[] = {
        0, surfaceHeight,
        surfaceWidth, surfaceHeight,
        surfaceWidth, 0,
        0, 0};
    
    GLfloat vertices[] = {
        -1.0, -1.0,
        1.0, -1.0,
        1.0, 1.0,
        -1.0, 1.0
    };
    
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    
    glDisable(GL_TEXTURE_COORD_ARRAY);
    glDisable(GL_VERTEX_ARRAY);
    
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);

 
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];

    
    
}

-(NSRect)windowRectforWorldRect:(NSRect)worldRect
{
    
    
    GLKVector3 winVec;
    
    NSRect winRect;
    
    
    
    
    //origin
    GLKVector3 origpoint = GLKVector3Make(worldRect.origin.x, worldRect.origin.y, 0.0f);
    
    winVec = GLKMathProject(origpoint, _modelview, _projection, _viewport);
    
    winRect.origin.x = winVec.x;
    winRect.origin.y = winVec.y;
    //origin+width and origin+height
    origpoint = GLKVector3Make(worldRect.origin.x+worldRect.size.width, worldRect.origin.y+worldRect.size.height, 0.0f);
    winVec = GLKMathProject(origpoint, _modelview, _projection, _viewport);
    winRect.size.width = winVec.x - winRect.origin.x;
    winRect.size.height = winVec.y - winRect.origin.y;
    return winRect;
}


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint
{
    
    
    GLKVector3 winVec = GLKVector3Make(winPoint.x, winPoint.y, 0);
    GLKVector3 worldPoint = GLKMathUnproject(winVec, _modelview, _projection, _viewport, NULL);
    return NSMakePoint(worldPoint.x, worldPoint.y);
}


-(void)setBounds:(CGRect)bounds
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resizeDirty = YES;
        
    });
    [super setBounds:bounds];
}



-(BOOL)isAsynchronous
{
    return YES;
}


-(BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    if (self.renderer)
    {
        return YES;
    }
    
    return NO;
}



@end


