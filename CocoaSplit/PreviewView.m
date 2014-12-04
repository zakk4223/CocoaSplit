//
//  PreviewView.m
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

#import "PreviewView.h"
#import "InputSource.h"
#import "InputPopupControllerViewController.h"
#import "SourceLayout.h"
#import "CreateLayoutViewController.h"



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

@synthesize sourceLayout = _sourceLayout;



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
    
    newProgram = [self createProgram:@"line" fragmentName:@"line"];
    
    
    progObj = [[OpenGLProgram alloc] init];
    progObj.label = @"line";
    progObj.gl_programName = newProgram;
    [_shaderPrograms setObject:progObj forKey:@"line"];


    
    
}




-(SourceLayout *)sourceLayout
{
    return _sourceLayout;
}

-(void) setSourceLayout:(SourceLayout *)sourceLayout
{
    
    
    if (!sourceLayout.isActive)
    {
        CGLContextObj cgl_ctx = [[self openGLContext] CGLContextObj];
        
        sourceLayout.ciCtx =  [CIContext contextWithCGLContext:cgl_ctx pixelFormat:CGLGetPixelFormat(cgl_ctx) colorSpace:nil options:@{kCIContextWorkingColorSpace: [NSNull null]}];
        
    }
    _sourceLayout = sourceLayout;
}



-(SourceLayout *)sourceLayoutPreview
{
    return self.sourceLayout;
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


-(void) reshape
{
    _resizeDirty = YES;
}


-(void) buildSettingsMenu
{
    if (self.sourceSettingsMenu)
    {
        return;
    }
    
    NSMenuItem *tmp;
    self.sourceSettingsMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Move Up" action:@selector(moveInputUp:) keyEquivalent:@"" atIndex:0];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Move Down" action:@selector(moveInputDown:) keyEquivalent:@"" atIndex:1];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@"" atIndex:2];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Delete" action:@selector(deleteInput:) keyEquivalent:@"" atIndex:3];
    tmp.target = self;
    

    
    
    
}
-(void) buildSourceMenu
{
    NSArray *sourceList = [self.sourceLayout sourceListOrdered];
    
    self.sourceListMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    
    
    

    for (InputSource *src in sourceList)
    {
        NSString *srcName = src.name;
        if (!srcName)
        {
            srcName = [NSString stringWithFormat:@"%@-noname", src.selectedVideoType];
            
        }
    
        NSMenuItem *srcItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:srcName action:nil keyEquivalent:@""];
        [srcItem setEnabled:YES];
        NSMenu *submenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
        NSMenuItem *setItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@""];
        [setItem setEnabled:YES];
        [setItem setRepresentedObject:src];
        [setItem setTarget:self];
        [submenu addItem:setItem];
        NSMenuItem *delItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Delete" action:@selector(deleteInput:) keyEquivalent:@""];
        [delItem setEnabled:YES];
        [delItem setRepresentedObject:src];
        [delItem setTarget:self];
        [submenu addItem:delItem];
        [srcItem setSubmenu:submenu];
        
        [self.sourceListMenu insertItem:srcItem atIndex:[self.sourceListMenu.itemArray count]];
        
    }
}

-(void)rightMouseDown:(NSEvent *)theEvent
{
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    self.selectedSource = [self.sourceLayout findSource:worldPoint];
    if (self.selectedSource)
    {
        [self buildSettingsMenu];
        [self.sourceSettingsMenu popUpMenuPositioningItem:self.sourceSettingsMenu.itemArray.firstObject atLocation:tmp inView:self];
    } else {
        [self buildSourceMenu];
        [self.sourceListMenu popUpMenuPositioningItem:self.sourceListMenu.itemArray.firstObject atLocation:tmp inView:self];
    }
}


- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    
    self.selectedSource = [self.sourceLayout findSource:worldPoint];
    if (!self.selectedSource)
    {
        return;
    }
    
    
    self.selectedSource.is_selected = YES;
    NSRect layoutRect = self.selectedSource.layoutPosition;
    
    //Make a rectangle that's 10 pixels smaller on all sides than the selected layoutPosition. If we're inside the selected object
    //but NOT in the smaller rectangle do a resize (we're grabbing the 'edge')
    NSRect viewRect = [self windowRectforWorldRect:layoutRect];
    
    
    
    
    NSRect topRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y+viewRect.size.height-10.0f, viewRect.size.width, 10.0f);
    NSRect bottomRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y, viewRect.size.width, 10.0f);
    NSRect leftRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y, 10.0f, viewRect.size.height);
    NSRect rightRect = NSMakeRect(viewRect.origin.x+viewRect.size.width-10.0f, viewRect.origin.y, 10.0f, viewRect.size.height);
    
    self.resizeType = kResizeNone;
    
    if (NSPointInRect(tmp, leftRect))
    {
        self.resizeType |= kResizeLeft;
    }
    
    if (NSPointInRect(tmp, topRect))
    {
        self.resizeType |= kResizeTop;
    }
    
    if (NSPointInRect(tmp, rightRect))
    {
        self.resizeType |= kResizeRight;
    }
    
    if (NSPointInRect(tmp, bottomRect))
    {
        self.resizeType |= kResizeBottom;
    }
    
    self.resizeAnchor = NSMakePoint(self.selectedSource.layoutPosition.origin.x + self.selectedSource.layoutPosition.size.width, self.selectedSource.layoutPosition.origin.y+self.selectedSource.layoutPosition.size.height);
    
    self.isResizing = self.resizeType != kResizeNone;
    
    
    self.selectedOriginDistance = worldPoint;
    

    
}


- (void)mouseDragged:(NSEvent *)theEvent
{
    
    NSPoint tmp;
    
    
    NSPoint worldPoint;
    if (self.selectedSource)
    {
        tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
        
        worldPoint = [self realPointforWindowPoint:tmp];
        CGFloat dx, dy;
        dx = worldPoint.x - self.selectedOriginDistance.x;
        dy = worldPoint.y - self.selectedOriginDistance.y;
        self.selectedOriginDistance = worldPoint;
        if (self.isResizing)
        {
            if (theEvent.modifierFlags & NSShiftKeyMask)
            {
                if (self.resizeType & kResizeRight)
                {
                    self.selectedSource.crop_right -= dx;
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    self.selectedSource.crop_left += dx;
                }
                
                if (self.resizeType & kResizeTop)
                {
                    self.selectedSource.crop_top -= dy;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    self.selectedSource.crop_bottom += dy;
                }
                
            } else {
                
                CGFloat new_width, new_height;
                CGFloat adjust_x, adjust_y;
                adjust_x = 0.0f;
                adjust_y = 0.0f;
                
                new_width = self.selectedSource.display_width;//self.selectedSource.layoutPosition.size.width;
                new_height = self.selectedSource.display_height;//self.selectedSource.layoutPosition.size.height;
                
                if (self.resizeType & kResizeRight)
                {
                    new_width = worldPoint.x - self.selectedSource.x_pos;
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    new_width = (self.selectedSource.x_pos + self.selectedSource.display_width) - worldPoint.x;
                    adjust_x = self.resizeAnchor.x - (self.selectedSource.x_pos + new_width);
                }
                
                
                if (self.resizeType & kResizeTop)
                {
                    new_height = worldPoint.y - self.selectedSource.y_pos;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    new_height = (self.selectedSource.y_pos + self.selectedSource.display_height) - worldPoint.y;
                    adjust_y = self.resizeAnchor.y - (self.selectedSource.y_pos + new_height);
                }
                
                
                [self.selectedSource updateSize:new_width height:new_height];
                if (adjust_x || adjust_y)
                {
                    [self.selectedSource updateOrigin:adjust_x y:adjust_y];
                }
            }

            
            
        } else {
            
            
            float x_pos = self.selectedSource.x_pos;
            float y_pos = self.selectedSource.y_pos;
            size_t s_width = self.selectedSource.display_width;
            size_t s_height = self.selectedSource.display_height;
            
            float top_pos = y_pos+s_height;
            float right_pos = x_pos+s_width;
            
            
            //Snap to edges on movement. You're on your own while resizing.
            
            //Snapping is only valid if we're still fully inside the canvas, if we push beyond that we let the user paint outside the box a bit.
            
            if (x_pos > 0 && right_pos < self.sourceLayout.canvas_width)
            {
                if (x_pos < SNAP_THRESHOLD && dx < 0)
                {
                    dx = -x_pos;
                } else if ((right_pos > self.sourceLayout.canvas_width-SNAP_THRESHOLD) && dx > 0) {
                    dx = self.sourceLayout.canvas_width - right_pos;
                }
            }
            
            if (y_pos > 0 && top_pos < self.sourceLayout.canvas_height)
            {
                if (y_pos < SNAP_THRESHOLD && dy < 0)
                {
                    dy = -y_pos;
                } else if ((top_pos > self.sourceLayout.canvas_height-SNAP_THRESHOLD) && dy > 0) {
                    dy = self.sourceLayout.canvas_height - top_pos;
                }
            }
            
            float half_x = x_pos + s_width/2;
            float half_y = y_pos + s_height/2;
            
            //if the middle of our bounding box is outside the canvas, don't let it move any more.
            
            if (half_x <= 0.0f && dx < 0)
            {
                dx = 0.0f;
            } else if ((half_x >= self.sourceLayout.canvas_width) && dx > 0) {
                dx = 0.0f;
            }
            
            if (half_y <= 0.0f && dy < 0)
            {
                dy = 0.0f;
            } else if ((half_y >= self.sourceLayout.canvas_height) && dy > 0) {
                dy = 0.0f;
            }
            [self.selectedSource updateOrigin:dx y:dy];
        }
    }
    
}


-(void) mouseUp:(NSEvent *)theEvent
{
    if (self.selectedSource)
    {
        self.selectedSource.is_selected = NO;
    }
    
    self.isResizing = NO;
    self.selectedSource = nil;
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




- (IBAction)moveInputUp:(id)sender
{
    if (self.selectedSource)
    {
        self.selectedSource.depth += 1;
        
    }
}


- (IBAction)moveInputDown:(id)sender
{
    if (self.selectedSource)
    {
        self.selectedSource.depth -= 1;
    }
}


- (IBAction)addInputSource:(id)sender
{
    
    if (self.sourceLayout)
    {
        
        
        InputSource *newSource = [[InputSource alloc] init];
        [self.sourceLayout addSource:newSource];
        [self spawnInputSettings:newSource atRect:NSZeroRect];
    }
}



- (IBAction)deleteInput:(id)sender
{
    NSMenuItem *item = (NSMenuItem *)sender;
    
    
    if (item.representedObject)
    {
        [self.sourceLayout deleteSource:item.representedObject];
    } else if (self.selectedSource) {
        [self.sourceLayout deleteSource:self.selectedSource];
        self.selectedSource = nil;
    }
}



-(void)spawnInputSettings:(InputSource *)forInput atRect:(NSRect)atRect
{
    
    NSRect spawnRect;
    spawnRect = atRect;
    
    if (NSEqualRects(spawnRect, NSZeroRect))
    {
        NSRect inputRect = [self windowRectforWorldRect:forInput.layoutPosition];
        spawnRect = NSInsetRect(inputRect, inputRect.size.width/2-2.0f, inputRect.size.height/2-2.0f);
    }
    
    
    InputPopupControllerViewController *popupController = [[InputPopupControllerViewController alloc] init];
    
    NSPopover *popover = [[NSPopover alloc] init];
    popover.contentViewController = popupController;
    popover.animates = YES;
    popover.delegate = self;
    popover.behavior = NSPopoverBehaviorSemitransient;
    [popover showRelativeToRect:spawnRect ofView:self preferredEdge:NSMaxXEdge];
    
    popupController.inputSource = forInput;
    forInput.editorController = popupController;
    if (forInput.editorWindow)
    {
        forInput.editorWindow = nil;
    }
}


- (IBAction)showInputSettings:(id)sender
{
    
    
    InputSource *configSource;
    
    NSMenuItem *menuSender = (NSMenuItem *)sender;
    
    
    
    configSource = self.selectedSource;
    if (menuSender.representedObject)
    {
        configSource = (InputSource *)menuSender.representedObject;
    }
    
    
    NSPoint tmp = [self convertPoint:[self.window mouseLocationOutsideOfEventStream] fromView:nil];

    NSRect spawnRect = NSMakeRect(tmp.x, tmp.y, 1.0f, 1.0f);
    
    if (!NSPointInRect(NSMakePoint(tmp.x, 0), self.bounds))
    {
        spawnRect = NSMakeRect(self.bounds.size.width-5, tmp.y, 1.0f, 1.0f);
    } else if (!NSPointInRect(NSMakePoint(0, tmp.y), self.bounds)) {
        spawnRect = NSMakeRect(tmp.x, 5.0f, 1.0f, 1.0f);
    }
    
    [self spawnInputSettings:configSource atRect:spawnRect];

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
    
     NSOpenGLPixelFormatAttribute attr[] = {
         NSOpenGLPFANoRecovery,
         NSOpenGLPFAAccelerated,
         //NSOpenGLPFAAllowOfflineRenderers,
         NSOpenGLPFADepthSize, 32,
         (NSOpenGLPixelFormatAttribute) 0,0,
         (NSOpenGLPixelFormatAttribute) 0
    };
    
    
    NSLog(@"CALLED INIT WITH FRAME");
    
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:(void *)&attr];


    renderLock = [[NSRecursiveLock alloc] init];
    
    
    self = [super initWithFrame:frameRect pixelFormat:pf];
    if (self)
    {
        long swapInterval = 0;
        
        [[self openGLContext] setValues:(GLint *)&swapInterval forParameter:NSOpenGLCPSwapInterval];

        glGenTextures(3, _previewTextures);
    }
    
    _resizeDirty = YES;
    
    [self createShaders];

    OpenGLProgram *lineprg = [_shaderPrograms objectForKey:@"line"];

    _lineProgram = lineprg.gl_programName;
    
    
    _cictx = [CIContext contextWithCGLContext:[self.openGLContext CGLContextObj] pixelFormat:CGLGetPixelFormat([self.openGLContext CGLContextObj]) colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
    CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
   CVDisplayLinkSetOutputCallback(displayLink, &displayLinkRender, (__bridge void *)self);
    
    CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, [[self openGLContext] CGLContextObj], [[self pixelFormat] CGLPixelFormatObj]);
    CVDisplayLinkStart(displayLink);
    
    return self;
}


-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    //Without the autorelease NSColor leaks objects
    
    NSLog(@"Preview: Creating Pixel Buffer Pool %f x %f", size.width, size.height);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @NO} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_renderPool)
    {
        CVPixelBufferPoolRelease(_renderPool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_renderPool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;
    
    
}

-(void)stopDisplayLink
{
    if (displayLink && CVDisplayLinkIsRunning(displayLink))
    {
        CVDisplayLinkStop(displayLink);
    }
}

-(void)restartDisplayLink
{
    if (displayLink && !CVDisplayLinkIsRunning(displayLink))
    {
        CVDisplayLinkStart(displayLink);
    }
}



-(void) cvrender
{
    
    @autoreleasepool {
        
    
    CVImageBufferRef displayFrame = NULL;
    
    if (!self.sourceLayout)
    {
        return;
    }
    displayFrame = [self.sourceLayout currentFrame];
    
    if (!displayFrame)
    {
        return;
    }
    
    
    //CVPixelBufferRetain(displayFrame);
    [self drawPixelBuffer:displayFrame];
    CVPixelBufferRelease(displayFrame);
    }
}



static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                  CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    
    
    
    PreviewView *myself;
    
    myself = (__bridge PreviewView *)displayLinkContext;
    
    [myself cvrender];
    return kCVReturnSuccess;
}



- (void) drawPixelBuffer:(CVImageBufferRef)cImageBuf
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
                plane_enums[0][1] = GL_RGBA;
                plane_enums[0][2] = GL_UNSIGNED_INT_8_8_8_8_REV;
                _num_planes = 1;
                break;
            case kCVPixelFormatType_32RGBA:
                plane_enums[0][0] = GL_RGBA;
                plane_enums[0][1] = GL_RGBA;
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
        
        _programId = shProgram.gl_programName;
        
        glUseProgram(_programId);
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

- (void) drawTexture:(NSRect)dirtyRect{
    


    NSRect frame = self.frame;
    
    
    GLclampf rval = 0.184314f;
    GLclampf gval = 0.309804f;
    GLclampf bval = 0.309804f;
    GLclampf aval = 0.0;
    
    if (self.statusColor)
    {
        rval = [self.statusColor redComponent];
        gval = [self.statusColor greenComponent];
        bval = [self.statusColor blueComponent];
        aval = [self.statusColor alphaComponent];
    }
    
    NSSize scaled;
    
    float wr = frame.size.width / _surfaceWidth ;
    float hr = frame.size.height / _surfaceHeight;
    
    float ratio;
    
    ratio = (hr < wr ? hr : wr);
    
    scaled = NSMakeSize((_surfaceWidth * ratio), (_surfaceHeight * ratio));
    
    glDisable(GL_DEPTH_TEST);
    
    glClearColor(rval, gval, bval, aval);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    glViewport(0, 0, frame.size.width, frame.size.height);
    
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0.0, frame.size.width, 0.0, frame.size.height, 0, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    
    for(int i = 0; i < _num_planes; i++)
    {
        
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _previewTextures[i]);
    }
    
    
    
    GLfloat text_coords[] =
    {
        0.0, 0.0,
        _surfaceWidth, 0.0,
        _surfaceWidth, _surfaceHeight,
        0.0, _surfaceHeight
    };
    
    float halfw = (frame.size.width - scaled.width) / 2;
    float halfh = (frame.size.height - scaled.height) / 2;
    
    
    GLfloat verts[] =
    {
        0, _surfaceHeight,
        _surfaceWidth, _surfaceHeight,
        _surfaceWidth, 0,
        0,0
    };
    
    glTranslated(halfw, halfh, 0.0);
    glScalef(ratio, ratio, 1.0f);
    
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, text_coords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    
    GLfloat outline_verts[8];
    glEnableClientState(GL_VERTEX_ARRAY);

    glUseProgram(_lineProgram);
    
    glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
    glLineWidth(2.0f);
    for(InputSource *src in self.sourceLayout.sourceList)
    {
        NSRect my_rect = src.layoutPosition;
        outline_verts[0] = my_rect.origin.x;
        outline_verts[1] = my_rect.origin.y;
        outline_verts[2] = my_rect.origin.x+my_rect.size.width;
        outline_verts[3] = my_rect.origin.y;
        outline_verts[4] = my_rect.origin.x+my_rect.size.width;
        outline_verts[5] = my_rect.origin.y+my_rect.size.height;
        outline_verts[6] = my_rect.origin.x;
        outline_verts[7] = my_rect.origin.y+my_rect.size.height;

        glVertexPointer(2, GL_FLOAT, 0, outline_verts);
        glDrawArrays(GL_LINE_LOOP, 0, 4);
    }
    glUseProgram(_programId);
    
    if (_resizeDirty && _surfaceWidth > 0 && _surfaceHeight > 0)
    {
        glGetDoublev(GL_MODELVIEW_MATRIX, _modelview);
        glGetDoublev(GL_PROJECTION_MATRIX, _projection);
        glGetIntegerv(GL_VIEWPORT, _viewport);
        _resizeDirty = NO;
        
    }

    
    glFlush();

    

    
}

- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}


-(NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
    NSLog(@"DETACHABLE WINDOW FOR POPOVER");
    InputPopupControllerViewController *newViewController = [[InputPopupControllerViewController alloc] init];
    InputPopupControllerViewController *oldViewController = (InputPopupControllerViewController *)popover.contentViewController;
    
    
     newViewController.inputSource = oldViewController.inputSource;
    NSWindow *popoverWindow;
    popoverWindow = [[NSWindow alloc] init];
    
    
    
    NSRect newFrame = [popoverWindow frameRectForContentRect:NSMakeRect(0.0f, 0.0f, newViewController.view.frame.size.width, newViewController.view.frame.size.height)];
    
    [popoverWindow setFrame:newFrame display:NO];
    
    [popoverWindow setReleasedWhenClosed:NO];
    
    
    [popoverWindow.contentView addSubview:newViewController.view];
    popoverWindow.title = [NSString stringWithFormat:@"CocoaSplit Input (%@)", newViewController.inputSource.name];
    popoverWindow.delegate = newViewController.inputSource;
    
    popoverWindow.styleMask =  NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask;
    
    newViewController.inputSource.editorWindow = popoverWindow;
    newViewController.inputSource.editorController = newViewController;
    return popoverWindow;
    
}

- (void)popoverDidClose:(NSNotification *)notification
{
    NSString *closeReason = [[notification userInfo] valueForKey:NSPopoverCloseReasonKey];
    NSPopover *popover = notification.object;
    if (closeReason && closeReason == NSPopoverCloseReasonStandard)
    {
        InputPopupControllerViewController *vcont = (InputPopupControllerViewController *)popover.contentViewController;
        
        vcont.inputSource.editorController = nil;
    }
    
}


@end
