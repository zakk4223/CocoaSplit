//
//  CSPreviewGLLayer.m
//  CocoaSplit
//
//  Created by Zakk on 8/8/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSPreviewGLLayer.h"

@implementation CSPreviewGLLayer

-(instancetype)init
{
    if (self = [super init])
    {
        _initDone = NO;
        _lastSurfaceSize = NSZeroSize;
        self.outlineSource = nil;
        self.doSnaplines = NO;
        self.needsDisplayOnBoundsChange = YES;
        self.opaque = YES;
        
        _snap_x = -1;
        _snap_y  = -1;
        
    }
    
    return self;
}


-(void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    
    
    
    if (!_initDone)
    {
        glGenTextures(1, &_renderTexture);
        glClearColor(0.184314f, 0.309804f, 0.309804f, 0);

        _initDone = YES;
    }
    glClear(GL_COLOR_BUFFER_BIT);

    
    CVPixelBufferRef toDraw = [self.renderer currentFrame];
    
    if (!toDraw)
    {
        return;
    }
    
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
        glGetDoublev(GL_MODELVIEW_MATRIX, _modelview);
        glGetDoublev(GL_PROJECTION_MATRIX, _projection);
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
    
    
    
    GLfloat outline_verts[8];
    GLfloat snapx_verts[4];
    GLfloat snapy_verts[4];
    
    
    glEnableClientState(GL_VERTEX_ARRAY);
    
    
    glLineWidth(2.0f);
    
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    
    if (self.outlineSource)
    {
        NSRect outRect = self.outlineSource.globalLayoutPosition;
    
        if (!NSEqualRects(NSZeroRect, outRect))
        {
            glColor3f(0.0f, 0.0f, 1.0f);
            outline_verts[0] = outRect.origin.x;
            outline_verts[1] = outRect.origin.y;
            outline_verts[2] = outRect.origin.x+outRect.size.width;
            outline_verts[3] = outRect.origin.y;
            outline_verts[4] = outRect.origin.x+outRect.size.width;
            outline_verts[5] = outRect.origin.y+outRect.size.height;
            outline_verts[6] = outRect.origin.x;
            outline_verts[7] = outRect.origin.y+outRect.size.height;
        
            glVertexPointer(2, GL_FLOAT, 0, outline_verts);
            glDrawArrays(GL_LINE_LOOP, 0, 4);
            glColor3f(1.0f, 1.0f, 1.0f);

        }
        
        glLineWidth(1.0f);
        
        glColor3f(1.0f, 1.0f, 0.0f);
        glLineStipple(2, 0xAAAA);
        if (self.doSnaplines)
        {
            if (_snap_x > -1)
            {
                float snap_y_min = 0;
                float snap_y_max = self.outlineSource.sourceLayout.canvas_height;
                
                if (self.outlineSource && self.outlineSource.parentInput)
                {
                    NSRect parentRect = ((InputSource *)self.outlineSource.parentInput).globalLayoutPosition;
                    snap_y_min = parentRect.origin.y;
                    snap_y_max = NSMaxY(parentRect);
                }
                
                snapx_verts[0] = _snap_x;
                snapx_verts[1] = snap_y_min;
                snapx_verts[2] = _snap_x;
                snapx_verts[3] = snap_y_max;
                glVertexPointer(2, GL_FLOAT, 0, snapx_verts);
                glDrawArrays(GL_LINES, 0, 2);
            }
            
            if (_snap_y > -1)
            {
                float snap_x_min = 0;
                float snap_x_max = self.outlineSource.sourceLayout.canvas_width;
                
                if (self.outlineSource && self.outlineSource.parentInput)
                {
                    NSRect parentRect = ((InputSource *)self.outlineSource.parentInput).globalLayoutPosition;
                    snap_x_min = parentRect.origin.x;
                    snap_x_max = NSMaxX(parentRect);
                }
                
                snapy_verts[0] = snap_x_min;
                snapy_verts[1] = _snap_y;
                snapy_verts[2] = snap_x_max;
                snapy_verts[3] = _snap_y;
                glVertexPointer(2, GL_FLOAT, 0, snapy_verts);
                glDrawArrays(GL_LINES, 0, 2);
            }
        }
        //glDisable(GL_LINE_STIPPLE);
        
        glColor3f(1.0f, 1.0f, 1.0f);

    }


    
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


    
    //[super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];


    
    CVPixelBufferRelease(toDraw);
    
    
}

-(NSRect)windowRectforWorldRect:(NSRect)worldRect
{
    
    
    GLdouble winx, winy, winz;
    NSRect winRect;
    
    
    
    
    //origin
    gluProject(worldRect.origin.x, worldRect.origin.y, 0.0f, _modelview, _projection, _viewport, &winx, &winy, &winz);
    winRect.origin.x = winx;
    winRect.origin.y = winy;
    //origin+width and origin+height
    gluProject(worldRect.origin.x+worldRect.size.width, worldRect.origin.y+worldRect.size.height, 0.0f, _modelview, _projection, _viewport, &winx, &winy, &winz);
    
    winRect.size.width = winx - winRect.origin.x;
    winRect.size.height = winy - winRect.origin.y;
    return winRect;
}


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint
{
    
    
    GLdouble winx, winy, winz;
    GLdouble worldx, worldy, worldz;
    
    
    
    winx = winPoint.x;
    winy = winPoint.y;
    winz = 0.0f;
    
    gluUnProject(winx, winy, winz, _modelview, _projection, _viewport, &worldx, &worldy, &worldz);
    
    return NSMakePoint(worldx, worldy);
}


-(void)setBounds:(CGRect)bounds
{
    _resizeDirty = YES;
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


