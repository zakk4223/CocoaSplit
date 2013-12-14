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


@synthesize vsync = _vsync;

-(void) setIdleTimer
{
    if (_idleTimer)
    {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
    
    _idleTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                  target:self
                                                selector:@selector(setMouseIdle)
                                                userInfo:nil
                                                 repeats:NO];
    
}
-(void) setMouseIdle
{
    
    [NSCursor setHiddenUntilMouseMoves:YES];
 
}


-(void) mouseMoved:(NSEvent *)theEvent
{
    [self setIdleTimer];
    
}


-(void) mouseExited:(NSEvent *)theEvent
{
    if (_idleTimer)
    {
        [_idleTimer invalidate];
        _idleTimer = nil;
    }
}



- (IBAction)toggleFullscreen:(id)sender;
{
    if (self.isInFullScreenMode)
    {
        [_idleTimer invalidate];
        _idleTimer = nil;
        [self removeTrackingArea:_trackingArea];
        _trackingArea = nil;
        
        [self exitFullScreenModeWithOptions:nil];
        [NSCursor setHiddenUntilMouseMoves:NO];
        
    } else {
        
        NSNumber *fullscreenOptions = @(NSApplicationPresentationAutoHideMenuBar|NSApplicationPresentationAutoHideDock);
        
        
        _fullscreenOn = [NSScreen mainScreen];
        
        if (_fullscreenOn != [[NSScreen screens] objectAtIndex:0])
        {
            fullscreenOptions = @(0);
        }
        
        
        [self enterFullScreenMode:_fullscreenOn withOptions:@{NSFullScreenModeAllScreens: @NO, NSFullScreenModeApplicationPresentationOptions: fullscreenOptions}];
        
        int opts = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);
        _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                            options:opts
                                                              owner:self
                                                           userInfo:nil];

        [self addTrackingArea:_trackingArea];
        [self setIdleTimer];
    }
    
}

-(void) updateVsync
{
    if (self.openGLContext)
    {
        long swapInterval;
        if (self.vsync == YES)
        {
            swapInterval = 1;
        } else {
            swapInterval = 0;
        }
        [[self openGLContext] setValues:(GLint *)&swapInterval forParameter:NSOpenGLCPSwapInterval];
    }
    
}


-(BOOL) vsync
{
    return _vsync;
}



-(void) setVsync:(BOOL)vsync
{
    _vsync = vsync;
    [self updateVsync];
}


-(id) initWithFrame:(NSRect)frameRect
{
    
    const NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
        0
    };
    
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];


    renderLock = [[NSRecursiveLock alloc] init];
    
    
    self = [super initWithFrame:frameRect pixelFormat:pf];
    if (self)
    {
        [self updateVsync];
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glGenTextures(1, &_previewTexture);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);
    }
    
    
    
    
    
    
    
    
    
    return self;
}



- (void) drawFrame:(CVImageBufferRef)cImageBuf
{
    
    CFTypeID bufType = CFGetTypeID(cImageBuf);
    
    if (bufType == CVPixelBufferGetTypeID())
    {
        CVPixelBufferRetain(cImageBuf);
        [self drawPixelBuffer:cImageBuf];
    } else if (bufType == CVOpenGLTextureGetTypeID()) {
        [self drawGLBuffer:cImageBuf];
    }
        
}

- (void) drawGLBuffer:(CVOpenGLTextureRef)cImageBuf
{
    
    GLuint saveTexture = _previewTexture;
    
    _previewTexture = CVOpenGLTextureGetName(cImageBuf);
    NSSize surfaceSize = CVImageBufferGetDisplaySize(cImageBuf);
    _surfaceWidth = surfaceSize.width;
    _surfaceHeight = surfaceSize.height;

    [self drawRect:CGRectZero];
    
    
    _previewTexture = saveTexture;
    
    
}

- (void) drawPixelBuffer:(CVPixelBufferRef)cImageBuf
{
 
    if (!cImageBuf)
    {
        return;
    }
    
    
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];

    
    //CVPixelBufferRetain(cImageBuf);
    IOSurfaceRef cFrame = CVPixelBufferGetIOSurface(cImageBuf);
    IOSurfaceID cFrameID;
    
    [self.openGLContext makeCurrentContext];
    if ([renderLock tryLock] == NO)
    {
        [NSOpenGLContext clearCurrentContext];
        return;
    }
    if (cFrame)
    {
        cFrameID = IOSurfaceGetID(cFrame);        
    }
    
    if (cFrame && (_boundIOSurfaceID != cFrameID))
    {
        _boundIOSurfaceID = cFrameID;
        
        _surfaceHeight  = (GLsizei)IOSurfaceGetHeight(cFrame);
        _surfaceWidth   = (GLsizei)IOSurfaceGetWidth(cFrame);
        
        /* the only formats we specify in any of the capture modules are: 420v, 420f and 2vuy. We can't handle 420* without some  shader /multi texture trickery, so just grab the first luminance plane and display that for now */
        
        GLenum gl_internal_format;
        GLenum gl_format;
        GLenum gl_type;
        OSType frame_pixel_format = IOSurfaceGetPixelFormat(cFrame);
        

        if (frame_pixel_format == kCVPixelFormatType_422YpCbCr8)
        {
            gl_format = GL_YCBCR_422_APPLE;
            gl_internal_format = GL_RGB8;
            gl_type = GL_UNSIGNED_SHORT_8_8_APPLE;
        } else if (frame_pixel_format == kCVPixelFormatType_422YpCbCr8FullRange) {
            gl_format = GL_YCBCR_422_APPLE;
            gl_internal_format = GL_RGB;
            gl_type = GL_UNSIGNED_SHORT_8_8_REV_APPLE;
        } else if (frame_pixel_format == kCVPixelFormatType_32BGRA) {
            gl_format = GL_BGRA;
            gl_internal_format = GL_RGB;
            gl_type = GL_UNSIGNED_INT_8_8_8_8_REV;
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
    }

    

      [self drawTexture:CGRectZero];


    [NSOpenGLContext clearCurrentContext];
    [renderLock unlock];

    CVPixelBufferRelease(cImageBuf);
}

- (void) update
{
  
    if ([renderLock tryLock] == YES)
    {
        [super update];
        [renderLock unlock];
    }

}


/*
- (void) reshape
{
    CGLContextObj  cgl_ctx  = [[self openGLContext] CGLContextObj];
    CGLLockContext(cgl_ctx);
    [super reshape];
    CGLUnlockContext(cgl_ctx);
    
}
*/


- (void) drawRect:(NSRect)dirtyRect
{

    if ([renderLock tryLock] == YES)
    {
        [self.openGLContext makeCurrentContext];
        [self drawTexture:dirtyRect];
        [NSOpenGLContext clearCurrentContext];
        [renderLock unlock];
    }
    
}

- (void) drawTexture:(NSRect)dirtyRect
{
//    CGLContextObj  cgl_ctx  = [[self openGLContext] CGLContextObj];
 //   CGLLockContext(cgl_ctx);
//    NSLog(@"CONTEXT %@", self.openGLContext);
    
    
    


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
    
    //CGLUnlockContext(cgl_ctx);
}


@end
