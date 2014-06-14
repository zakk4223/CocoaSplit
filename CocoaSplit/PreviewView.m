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



@implementation OpenGLProgram


-(id) init
{
    if (self = [super init])
    {
        _sampler_uniform_locations[0] = -1;
        _sampler_uniform_locations[1] = -1;
        _sampler_uniform_locations[2] = -1;
        
    }
    
    return self;
}


-(void)setUniformLocation:(int)index location:(GLint)location
{
    if (index < sizeof(_sampler_uniform_locations))
    {
        _sampler_uniform_locations[index] = location;
    }
}


-(GLint)getUniformLocation:(int)index
{
    if (index >= sizeof(_sampler_uniform_locations))
    {
        return -1;
    } else {
        return _sampler_uniform_locations[index];
    }
    
}

@end

@implementation PreviewView






-(void) logGLShader:(GLuint)logTarget shaderPath:(NSString *)shaderPath
{
	int infologLength = 0;
	int maxLength;
    
	if(glIsShader(logTarget))
    {
		glGetShaderiv(logTarget,GL_INFO_LOG_LENGTH,&maxLength);
	} else {
		glGetProgramiv(logTarget,GL_INFO_LOG_LENGTH,&maxLength);
    }
	char infoLog[maxLength];
    
	if (glIsShader(logTarget))
    {
		glGetShaderInfoLog(logTarget, maxLength, &infologLength, infoLog);
	} else {
		glGetProgramInfoLog(logTarget, maxLength, &infologLength, infoLog);
    }
    
	if (infologLength > 0)
    {
		NSLog(@"LOG FOR SHADER %@:  %s\n",shaderPath, infoLog);
    }
    
}


-(GLuint) loadShader:(NSString *)name  shaderType:(GLenum)shaderType
{
    
    
    NSBundle *appBundle = [NSBundle mainBundle];
    
    NSString *extension;
    if (shaderType == GL_FRAGMENT_SHADER)
    {
        extension = @"fgsh";
    } else if (shaderType == GL_VERTEX_SHADER) {
        extension = @"vtsh";
    }
    
    NSString *shaderPath = [appBundle pathForResource:name ofType:extension inDirectory:@"Shaders"];
    
    NSString *shaderSource = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:NULL];
    
    GLuint shaderName;
    
    shaderName = glCreateShader(shaderType);
    
    const char *sc_src = [shaderSource cStringUsingEncoding:NSASCIIStringEncoding];
    
    glShaderSource(shaderName, 1, &sc_src, NULL);
    glCompileShader(shaderName);
    [self logGLShader:shaderName shaderPath:shaderPath];
    return shaderName;
}

-(GLuint) createProgram:(NSString *)vertexName fragmentName:(NSString *)fragmentName
{
    GLuint progVertex = [self loadShader:vertexName shaderType:GL_VERTEX_SHADER];
    GLuint progFragment = [self loadShader:fragmentName shaderType:GL_FRAGMENT_SHADER];
    
    GLuint newProgram = glCreateProgram();
    glAttachShader(newProgram, progVertex);
    glAttachShader(newProgram, progFragment);
    glLinkProgram(newProgram);
    

    [self logGLShader:newProgram shaderPath:nil];

    
    
    return newProgram;
}


-(void) setProgramUniforms:(OpenGLProgram *)program
{
    GLint text_loc;
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture1");
    [program setUniformLocation:0 location:text_loc];
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture2");
    [program setUniformLocation:1 location:text_loc];
    
    
    text_loc = glGetUniformLocation(program.gl_programName, "my_texture3");
    [program setUniformLocation:2 location:text_loc];
}


-(void) createShaders
{
    
    OpenGLProgram *progObj;
    _shaderPrograms = [[NSMutableDictionary alloc] init];
    
    
    GLuint newProgram = [self createProgram:@"passthrough" fragmentName:@"passthrough"];
    
    progObj = [[OpenGLProgram alloc] init];
    progObj.label = @"passthrough";
    progObj.gl_programName = newProgram;

    [self setProgramUniforms:progObj];
    
    [_shaderPrograms setObject: progObj forKey:@"passthrough"];
    
    newProgram = [self createProgram:@"passthrough" fragmentName:@"420v"];
    
    progObj = [[OpenGLProgram alloc] init];
    progObj.label = @"420v";
    progObj.gl_programName = newProgram;
    
    [self setProgramUniforms:progObj];

    [_shaderPrograms setObject:progObj forKey:@"420v"];
    
}


-(void)bindProgramTextures:(OpenGLProgram *)program
{
    
    
    for(int i = 0; i < 3; i++)
    {
        glUniform1i([program getUniformLocation:i], i);
    }
    
}


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



-(id) initWithFrame:(NSRect)frameRect
{
    
    const NSOpenGLPixelFormatAttribute attr[] = {
        NSOpenGLPFAAccelerated,
        NSOpenGLPFANoRecovery,
//        NSOpenGLPFAOpenGLProfile,
//        NSOpenGLProfileVersion3_2Core,
        0
    };
    
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];


    renderLock = [[NSRecursiveLock alloc] init];
    
    
    self = [super initWithFrame:frameRect pixelFormat:pf];
    if (self)
    {
        long swapInterval = 1;
        
        [[self openGLContext] setValues:(GLint *)&swapInterval forParameter:NSOpenGLCPSwapInterval];

        glGenTextures(3, _previewTextures);
    }
    
    
    [self createShaders];
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
    CVDisplayLinkSetOutputCallback(displayLink, &displayLinkRender, (__bridge void *)self);
    
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, [[self openGLContext] CGLContextObj], [[self pixelFormat] CGLPixelFormatObj]);
    CVDisplayLinkStart(displayLink);
    
    
    
    return self;
}


static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                  CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    
    PreviewView *myself;
    
    myself = (__bridge PreviewView *)displayLinkContext;
    
    CVImageBufferRef displayFrame = NULL;
    displayFrame = [myself.controller currentFrame];
    
    
    if (displayFrame)
    {

    
        [myself drawFrame:displayFrame];
    
        CVPixelBufferRelease(displayFrame);
    }
    
    
    
    return kCVReturnSuccess;
}



- (void) drawFrame:(CVImageBufferRef)cImageBuf
{
        
    CFTypeID bufType = CFGetTypeID(cImageBuf);
    
    if (bufType == CVPixelBufferGetTypeID())
    {
        [self drawPixelBuffer:cImageBuf];
//    } else if (bufType == CVOpenGLTextureGetTypeID()) {
  //      [self drawGLBuffer:cImageBuf];
    }
        
}

- (void) drawPixelBuffer:(CVPixelBufferRef)cImageBuf
{
 
    if (!cImageBuf)
    {
        return;
    }
    
    
    CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];


    IOSurfaceRef cFrame = CVPixelBufferGetIOSurface(cImageBuf);
    IOSurfaceID cFrameID;
    
    CGLLockContext(cgl_ctx);

    [self.openGLContext makeCurrentContext];
    
    if (cFrame)
    {
        cFrameID = IOSurfaceGetID(cFrame);        
    }
    
    if (cFrame && (_boundIOSurfaceID != cFrameID))
    {
        _boundIOSurfaceID = cFrameID;
        
        _surfaceHeight  = (GLsizei)IOSurfaceGetHeight(cFrame);
        _surfaceWidth   = (GLsizei)IOSurfaceGetWidth(cFrame);
        
        GLenum gl_internal_format;
        GLenum gl_format;
        GLenum gl_type;
        OSType frame_pixel_format = IOSurfaceGetPixelFormat(cFrame);

        NSString *programName;
        programName = @"passthrough"; //default

        //format, internal_format, gl_type
        GLenum plane_enums[3][3];
        
        switch (frame_pixel_format) {
            case kCVPixelFormatType_422YpCbCr8:
                plane_enums[0][0] = GL_YCBCR_422_APPLE;
                plane_enums[0][1] = GL_RGB8;
                plane_enums[0][2] = GL_UNSIGNED_SHORT_8_8_APPLE;
                _num_planes = 1;
                break;
            case kCVPixelFormatType_422YpCbCr8FullRange:
            case kCVPixelFormatType_422YpCbCr8_yuvs:
                plane_enums[0][0] = GL_YCBCR_422_APPLE;
                plane_enums[0][1] = GL_RGB;
                plane_enums[0][2] = GL_UNSIGNED_SHORT_8_8_REV_APPLE;
                _num_planes = 1;
                break;
            case kCVPixelFormatType_32BGRA:
                plane_enums[0][0] = GL_BGRA;
                plane_enums[0][1] = GL_RGB;
                plane_enums[0][2] = GL_UNSIGNED_INT_8_8_8_8_REV;
                _num_planes = 1;
                break;
            case kCVPixelFormatType_32ARGB:
                plane_enums[0][0] = GL_RGB;
                plane_enums[0][1] = GL_RGB;
                plane_enums[0][2] = GL_UNSIGNED_INT_8_8_8_8;
                _num_planes = 1;
                break;
            case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
                plane_enums[0][0] = GL_RED;
                plane_enums[0][1] = GL_RED;
                plane_enums[0][2] = GL_UNSIGNED_BYTE;
                plane_enums[1][0] = GL_RG;
                plane_enums[1][1] = GL_RG;
                plane_enums[1][2] = GL_UNSIGNED_BYTE;
                _num_planes = 2;
                programName = @"420v";
                break;
            default:
                gl_format = GL_LUMINANCE;
                gl_internal_format = GL_LUMINANCE;
                gl_type = GL_UNSIGNED_BYTE;
                _num_planes = 1;
                break;
        }
    
        for(int t_idx = 0; t_idx < _num_planes; t_idx++)
        {
            
            glActiveTexture(GL_TEXTURE0+t_idx);
            glEnable(GL_TEXTURE_RECTANGLE_ARB);
            glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTextures[t_idx]);
            
            glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            
            CGLTexImageIOSurface2D(cgl_ctx, GL_TEXTURE_RECTANGLE_ARB, plane_enums[t_idx][1], (GLsizei)IOSurfaceGetWidthOfPlane(cFrame, t_idx), (GLsizei)IOSurfaceGetHeightOfPlane(cFrame, t_idx), plane_enums[t_idx][0], plane_enums[t_idx][2], cFrame, t_idx);
            

        }
        
        
        OpenGLProgram *shProgram = [_shaderPrograms objectForKey:programName];
        
        GLuint progID = shProgram.gl_programName;
        
        glUseProgram(progID);
        [self bindProgramTextures:shProgram];
        
        
        

    }

    
      [self drawTexture:CGRectZero];

    CGLUnlockContext(cgl_ctx);

    [NSOpenGLContext clearCurrentContext];

}



- (void) drawRect:(NSRect)dirtyRect
{

    [self.openGLContext makeCurrentContext];
    CGLLockContext([self.openGLContext CGLContextObj]);
    

    [self drawTexture:dirtyRect];
    
    CGLUnlockContext([self.openGLContext CGLContextObj]);


    [NSOpenGLContext clearCurrentContext];
    
}

- (void) drawTexture:(NSRect)dirtyRect
{


    
    
    


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
    
    
    
    for(int i = 0; i < _num_planes; i++)
    {

        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTextures[i]);
    }
    
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
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glFlush();
    

    
}


@end
