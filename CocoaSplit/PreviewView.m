//
//  PreviewView.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import "PreviewView.h"


@implementation PreviewView

-(id) initWithFrame:(NSRect)frameRect
{
    
    const NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        NSOpenGLPFAColorSize, 32,
        0
    };
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];

    
    self = [super initWithFrame:frameRect pixelFormat:pf];
    if (self)
    {
        CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
        long swapInterval = 1;
        [[self openGLContext] setValues:(GLint *)&swapInterval forParameter:NSOpenGLCPSwapInterval];
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glGenTextures(1, &_previewTexture);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        NSLog(@"SETUP PREVIEW TEXTURE");
    }
    
    return self;
}




- (void) drawFrame:(CVImageBufferRef)cImageBuf
{
 
    if (!cImageBuf)
    {
        return;
    }
    CVPixelBufferRetain(cImageBuf);
    IOSurfaceRef cFrame = CVPixelBufferGetIOSurface(cImageBuf);
    IOSurfaceID cFrameID;
    if (cFrame)
    {
        cFrameID = IOSurfaceGetID(cFrame);
    }
    if (cFrame && (_boundIOSurfaceID != cFrameID))
    {
        _boundIOSurfaceID = cFrameID;
        CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
        
        _surfaceHeight  = (GLsizei)IOSurfaceGetHeight(cFrame);
        _surfaceWidth   = (GLsizei)IOSurfaceGetWidth(cFrame);
        
        /* the only formats we specify in any of the capture modules are: 420v, 420f and 2vuy. We can't handle 420* without some fragment shader /multi texture trickery, so just grab the first luminance plane and display that for now */
        
        GLenum gl_internal_format;
        GLenum gl_format;
        GLenum gl_type;
        OSType frame_pixel_format = IOSurfaceGetPixelFormat(cFrame);
        
        if (frame_pixel_format == kCVPixelFormatType_422YpCbCr8)
        {
            gl_format = GL_YCBCR_422_APPLE;
            gl_internal_format = GL_RGB;
            gl_type = GL_UNSIGNED_SHORT_8_8_APPLE;
        } else {
            gl_format = GL_LUMINANCE;
            gl_internal_format = GL_LUMINANCE;
            gl_type = GL_UNSIGNED_BYTE;
        }
    
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTexture);
        CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, gl_internal_format, _surfaceWidth, _surfaceHeight, gl_format, gl_type, cFrame, 0);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        [self drawRect:CGRectZero];
    }

    CVPixelBufferRelease(cImageBuf);
}


- (void) drawRect:(NSRect)dirtyRect
{
    CGLContextObj  cgl_ctx  = [[self openGLContext] CGLContextObj];
    
    NSRect frame = self.frame;
    
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glViewport(0, 0, frame.size.width, frame.size.height);
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0.0, frame.size.width, 0.0, frame.size.height, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
    
    //if (_boundIOSurface)
    //{
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTexture);
        glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
        
        glDisable(GL_BLEND);
        
        NSSize scaled;
        
        float wr = _surfaceWidth / frame.size.width;
        float hr = _surfaceHeight / frame.size.height;
        
        float ratio;
        
        ratio = (hr < wr ? wr : hr);
        
        scaled = NSMakeSize((_surfaceWidth / ratio), (_surfaceHeight / ratio));
        
        
        GLfloat text_coords[] =
        {
            0.0, 0.0,
            _surfaceWidth, 0.0,
            _surfaceWidth, _surfaceHeight,
            0.0, _surfaceHeight
        };
        
        float halfw = scaled.width * 0.5;
        float halfh = scaled.height * 0.5;
        
       /* GLfloat verts[] =
        {
            halfw, halfh,
            -halfw, halfh,
            -halfw, -halfh,
            halfw, -halfh
            
        };*/
        
        GLfloat verts[] =
        {
          -halfw, halfh,
            halfw, halfh,
            halfw, -halfh,
            -halfw, -halfh
        };
        
        glTranslated(frame.size.width * 0.5, frame.size.height * 0.5, 0.0);
        glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        glTexCoordPointer(2, GL_FLOAT, 0, text_coords);
        glEnableClientState(GL_VERTEX_ARRAY);
        glVertexPointer(2, GL_FLOAT, 0, verts);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        glDisableClientState(GL_TEXTURE_COORD_ARRAY);
        glDisableClientState(GL_VERTEX_ARRAY);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    //}
/*    if (_boundIOSurface)
    {
        GLfloat texMatrix[16] = {0};
        GLint   saveMatrixMode;
        
        texMatrix[0]    = (GLfloat)_surfaceWidth;
        texMatrix[5]    = -(GLfloat)_surfaceHeight;
        texMatrix[10]   = 1.0;
        texMatrix[13]   = (GLfloat)_surfaceHeight;
        texMatrix[15]   = 1.0;
        
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPushMatrix();
        glLoadMatrixf(texMatrix);
        glMatrixMode(saveMatrixMode);
        
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTexture);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
    } else {
        glColor4f(0.0, 0.0, 0.0, 0.0);
    }
    
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glEnd();
    
    if (_boundIOSurface)
    {
        GLint           saveMatrixMode;
        
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
        glGetIntegerv(GL_MATRIX_MODE, &saveMatrixMode);
        glMatrixMode(GL_TEXTURE);
        glPopMatrix();
        glMatrixMode(saveMatrixMode);
    }
    
    glFlush();
 */
    
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glFlush();
}
@end
