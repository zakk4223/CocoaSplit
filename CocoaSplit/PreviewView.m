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
#import "InputPopupControllerViewController.h"
#import "SourceLayout.h"
#import "CreateLayoutViewController.h"

//wtf apple

@interface NSCursor (CSApplePrivate)
+ (instancetype)_bottomLeftResizeCursor;
+ (instancetype)_topLeftResizeCursor;
+ (instancetype)_bottomRightResizeCursor;
+ (instancetype)_topRightResizeCursor;
+ (instancetype)_windowResizeNorthEastSouthWestCursor;
+ (instancetype)_windowResizeNorthWestSouthEastCursor;
@end


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
    
    if (self.layoutRenderer)
    {
        self.layoutRenderer.layout = _sourceLayout;
    }

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

-(BOOL)acceptsFirstResponder
{
    return YES;
}

-(void)cancelOperation:(id)sender
{
    if (self.isInFullScreenMode)
    {
        [self toggleFullscreen:self];
    }
}

-(void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent.charactersIgnoringModifiers isEqualToString:@"f"] && (theEvent.modifierFlags & NSCommandKeyMask))
    {
        [self toggleFullscreen:self];
    }

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
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Auto Fit" action:@selector(autoFitInput:) keyEquivalent:@"" atIndex:2];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Settings" action:@selector(showInputSettings:) keyEquivalent:@"" atIndex:3];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Delete" action:@selector(deleteInput:) keyEquivalent:@"" atIndex:4];
    tmp.target = self;
    tmp = [self.sourceSettingsMenu insertItemWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@"" atIndex:5];

    
    tmp.target = self;
    

    
    
    
}
-(NSMenu *) buildSourceMenu
{
    NSArray *sourceList = [self.sourceLayout sourceListOrdered];
    
    NSMenu *sourceListMenu = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
    
    
    

    
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
        NSMenuItem *cloneItem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] initWithTitle:@"Clone" action:@selector(cloneInputSource:) keyEquivalent:@""];
        [cloneItem setEnabled:YES];
        [cloneItem setRepresentedObject:src];
        [cloneItem setTarget:self];
        [submenu addItem:cloneItem];
        
        [srcItem setSubmenu:submenu];
        
        [sourceListMenu insertItem:srcItem atIndex:[sourceListMenu.itemArray count]];
        
    }
    
    return sourceListMenu;
}

-(void)trackMousedSource
{
    
    if (self.selectedSource)
    {
        self.mousedSource = self.selectedSource;
        return;
    }
    
    
    NSPoint mouseLoc = [NSEvent mouseLocation];
    
    NSRect rect = NSRectFromCGRect((CGRect){mouseLoc, CGSizeZero});
    
    mouseLoc = [self.window convertRectFromScreen:rect].origin;
    mouseLoc = [self convertPoint:mouseLoc fromView:nil];
    
    if (![self mouse:mouseLoc inRect:self.bounds])
    {
        return;
    }
    
    
    NSPoint worldPoint = [self realPointforWindowPoint:mouseLoc];
    
    InputSource *newSrc = [self.sourceLayout findSource:worldPoint withExtra:2];
    

    if (!newSrc)
    {
        [NSCursor pop];
    }
    
    NSArray *resizeRects = [self resizeRectsForSource:newSrc withExtra:2];

    NSCursor *newCursor = [NSCursor openHandCursor];
    
    bool hitResize = NO;
    
    //bottom left, top left, top right, bottom right
    for(int i=0; i < resizeRects.count; i++)
    {
        NSValue *rVal = [resizeRects objectAtIndex:i];
        
        NSRect reRect = [rVal rectValue];
        if (NSPointInRect(mouseLoc, reRect))
        {
            if (i == 0 || i == 2)
            {
                newCursor = [NSCursor _windowResizeNorthEastSouthWestCursor];
            } else {
                newCursor = [NSCursor _windowResizeNorthWestSouthEastCursor];
            }
            hitResize = YES;
            break;
        }
        
        
    }
    
    if ((newSrc != self.mousedSource) || (hitResize != _in_resize_rect))
    {
        [NSCursor pop];
        [newCursor push];
    }
 
    self.mousedSource = newSrc;
    _in_resize_rect = hitResize;
    
}



-(void)rightMouseDown:(NSEvent *)theEvent
{
    
    if (self.viewOnly)
    {
        return;
    }
    
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    self.selectedSource = [self.sourceLayout findSource:worldPoint];
    if (self.selectedSource)
    {
        [self buildSettingsMenu];
        [self.sourceSettingsMenu popUpMenuPositioningItem:self.sourceSettingsMenu.itemArray.firstObject atLocation:tmp inView:self];
    } else {
        
        NSMenu *srcListMenu = [self buildSourceMenu];
        
        [srcListMenu popUpMenuPositioningItem:srcListMenu.itemArray.firstObject atLocation:tmp inView:self];
    }
}


//bottom left, top left, top right, bottom right

-(NSArray *)resizeRectsForSource:(InputSource *)inputSource withExtra:(float)withExtra
{
    
    NSRect layoutRect = inputSource.layoutPosition;
    
    NSRect extraRect = NSInsetRect(layoutRect, -withExtra, -withExtra);
    
    NSRect viewRect = [self windowRectforWorldRect:extraRect];
    
    
    NSRect bottomLeftRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y, 10.0f, 10.0f);
    NSRect bottomRightRect = NSMakeRect(viewRect.origin.x+viewRect.size.width-10.0f, viewRect.origin.y, 10.0f, 10.0f);
    
    NSRect topLeftRect = NSMakeRect(viewRect.origin.x, viewRect.origin.y+viewRect.size.height-10.0f, 10.0f, 10.0f);
    
    NSRect topRightRect = NSMakeRect(viewRect.origin.x+viewRect.size.width-10.0f, viewRect.origin.y+viewRect.size.height-10.0f, 10.0f, 10.0f);
    
    
    return @[[NSValue valueWithRect:bottomLeftRect], [NSValue valueWithRect:topLeftRect], [NSValue valueWithRect:topRightRect],[NSValue valueWithRect:bottomRightRect]];
    
}



- (void)mouseDown:(NSEvent *)theEvent
{
    
    if (self.viewOnly)
    {
        return;
    }
    
    
    NSPoint tmp;
    
    tmp = [self convertPoint:theEvent.locationInWindow fromView:nil];
    
    NSPoint worldPoint = [self realPointforWindowPoint:tmp];
    
    InputSource *oldSource = self.selectedSource;
    self.selectedSource = [self.sourceLayout findSource:worldPoint];
    if (!self.selectedSource)
    {
        return;
    }
    
    
    self.selectedSource.is_selected = YES;
    if (oldSource)
    {
        oldSource.is_selected = NO;
    }
    
    
    NSArray *resizeRects = [self resizeRectsForSource:self.selectedSource withExtra:2];
    
    //bottom left, top left, top right, bottom right

    
    NSRect bottomLeftRect = [[resizeRects objectAtIndex:0] rectValue];
    NSRect topLeftRect = [[resizeRects objectAtIndex:1] rectValue];
    NSRect topRightRect = [[resizeRects objectAtIndex:2] rectValue];
    NSRect bottomRightRect = [[resizeRects objectAtIndex:3] rectValue];
    
    self.resizeType = kResizeNone;
    
    if (NSPointInRect(tmp, topLeftRect))
    {
        self.resizeType = kResizeLeft | kResizeTop;
    } else if (NSPointInRect(tmp, bottomLeftRect)) {
        self.resizeType = kResizeLeft | kResizeBottom;

    } else if (NSPointInRect(tmp, topRightRect)) {
        self.resizeType = kResizeRight | kResizeTop;
    } else if (NSPointInRect(tmp, bottomRightRect)) {
        self.resizeType = kResizeRight | kResizeBottom;
    }
    
    
    self.isResizing = self.resizeType != kResizeNone;
    
    self.selectedOriginDistance = worldPoint;
    
    if (self.isResizing)
    {
        if (theEvent.modifierFlags & NSAlternateKeyMask)
        {
            self.resizeType |= kResizeCenter;
        }
        
        if (theEvent.modifierFlags & NSControlKeyMask)
        {
            self.resizeType |= kResizeFree;
        }
        
        if (theEvent.modifierFlags & NSShiftKeyMask)
        {
            self.resizeType |= kResizeCrop;
        }


    }
    self.selectedSource.resizeType = self.resizeType;

    
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
        [self adjustDeltas:&dx dy:&dy];

        self.selectedOriginDistance = worldPoint;
        if (self.isResizing)
        {
            if (theEvent.modifierFlags & NSShiftKeyMask)
            {
                //Crop is expressed as a floating point number between 0.0 and 1.0, basically a percentage of that dimension.
                //Convert appropriately.
                
                float x_crop = dx/self.selectedSource.layoutPosition.size.width;
                float y_crop = dy/self.selectedSource.layoutPosition.size.height;
                
                
                if (self.resizeType & kResizeRight)
                {
                    self.selectedSource.crop_right -= x_crop;
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    self.selectedSource.crop_left += x_crop;
                }
                
                if (self.resizeType & kResizeTop)
                {
                    self.selectedSource.crop_top -= y_crop;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    self.selectedSource.crop_bottom += y_crop;
                }
                
            } else {
                
                if (theEvent.modifierFlags & NSAlternateKeyMask)
                {
                    self.resizeType |= kResizeCenter;
                } else {
                    self.resizeType &= ~kResizeCenter;
                }
                
                if (theEvent.modifierFlags & NSShiftKeyMask)
                {
                    self.resizeType |= kResizeCrop;
                }

                CGFloat new_width, new_height;
                
                NSRect sPosition = self.selectedSource.layoutPosition;
                
                new_width = sPosition.size.width;
                new_height = sPosition.size.height;
                
                if (self.resizeType & kResizeRight)
                {
                    new_width += dx;
                    
                }
                
                if (self.resizeType & kResizeLeft)
                {
                    new_width -= dx;
                    
                }
                
                
                if (self.resizeType & kResizeTop)
                {
                    new_height += dy;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    new_height -= dy;
                }
                
                
                [self.selectedSource updateSize:new_width height:new_height];

            }
            
        } else {
            
            [self.selectedSource updateOrigin:dx y:dy];
        }
    }
    
}


-(void)adjustDeltas:(CGFloat *)dx dy:(CGFloat *)dy
{
    
    //define snap points. basically edges and the center of the canvas
    NSPoint c_lb_snap = NSMakePoint(0, 0);
    NSPoint c_rt_snap = NSMakePoint(self.sourceLayout.canvas_width, self.sourceLayout.canvas_height);
    NSPoint c_center_snap = NSMakePoint(self.sourceLayout.canvas_width/2, self.sourceLayout.canvas_height/2);

    
    //selected source snap points. edges, and center
    
    if (!self.selectedSource)
    {
        return;
    }
    
    NSRect src_rect = self.selectedSource.layoutPosition;

    NSPoint s_lb_snap = src_rect.origin;
    NSPoint s_rt_snap = NSMakePoint(src_rect.origin.x+src_rect.size.width, src_rect.origin.y+src_rect.size.height);
    NSPoint s_center_snap = NSMakePoint(src_rect.origin.x+roundf(src_rect.size.width/2), src_rect.origin.y+roundf(src_rect.size.height/2));
    
    
    NSPoint dist;
    
    NSPoint s_snaps[3] = {s_lb_snap, s_rt_snap, s_center_snap};
    NSPoint c_snaps[3] = {c_lb_snap, c_rt_snap, c_center_snap};
    
    bool did_snap_x = NO;
    bool did_snap_y = NO;
    
    //Check if we're already snapped. If we are, check if it's time to break the magnetism.
    if (_snap_x != -1)
    {
        _snap_x_accum += *dx;
        if (fabs(_snap_x_accum) > SNAP_THRESHOLD*2)
        {
            _snap_x = -1;
            *dx = _snap_x_accum;
            _snap_x_accum = 0;
        } else {
            *dx = 0;
        }
        
        did_snap_x = YES;
    }
    
    if (_snap_y != -1)
    {
        _snap_y_accum += *dy;
        if (fabs(_snap_y_accum) > SNAP_THRESHOLD*2)
        {
            _snap_y = -1;
            *dy = _snap_y_accum;
            _snap_y_accum = 0;
        } else {
            *dy = 0;
        }
        
        did_snap_y = YES;
    }


    for(int i=0; i < sizeof(s_snaps)/sizeof(NSPoint); i++)
    {
        NSPoint s_snap = s_snaps[i];
        for(int j=0; j < sizeof(c_snaps)/sizeof(NSPoint); j++)
        {
            
            NSPoint c_snap = c_snaps[j];
            dist = [self pointDistance:s_snap b:c_snap];
            if (!did_snap_x && (copysignf(dist.x, *dx) != dist.x) && (fabs(dist.x) < SNAP_THRESHOLD))
            {
                if ((s_snap.x != c_snap.x) && (_snap_x == -1))
                {
                    *dx = -dist.x;
                    _snap_x = c_snap.x;
                    _snap_x_accum = 0;
                    did_snap_x = YES;
                }
            }
            
            if ((*dy != 0) && !did_snap_y && (copysignf(dist.y, *dy) != dist.y) && (fabs(dist.y) < SNAP_THRESHOLD))
            {

                if ((s_snap.y != c_snap.y) && (_snap_y == -1))
                {
                    *dy = -dist.y;
                    _snap_y = c_snap.y;
                    _snap_y_accum = 0;
                    did_snap_y = YES;

                }
            }
        }
    }
    
}


-(NSPoint)pointDistance:(NSPoint )a b:(NSPoint )b
{
    NSPoint ret;
    
    ret.x = a.x - b.x;
    ret.y = a.y - b.y;
    return ret;
}


-(void) mouseUp:(NSEvent *)theEvent
{
    /*
    if (self.selectedSource)
    {
        self.selectedSource.is_selected = NO;
    }
    */
    _snap_x = -1;
    _snap_y = -1;
    _snap_x_accum = 0;
    _snap_y_accum  = 0;
    
    self.isResizing = NO;
    self.selectedSource.resizeType = kResizeNone;
    self.selectedSource = nil;
}


-(void) mouseMoved:(NSEvent *)theEvent
{
    
    if (!self.viewOnly)
    {
        [self trackMousedSource];
    }
    
    
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


- (IBAction)cloneInputSource:(id)sender
{
    
    NSMenuItem *item = (NSMenuItem *)sender;
    InputSource *toClone;
    
    if (item.representedObject)
    {
        toClone = (InputSource *)item.representedObject;
    } else {
        toClone = self.selectedSource;
    }

    
    
    if (toClone)
    {
        InputSource *newSource = toClone.copy;
        [self.sourceLayout addSource:newSource];
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
        self.mousedSource = nil;
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



-(IBAction) autoFitInput:(id)sender
{
    InputSource *autoFitSource;
    NSMenuItem *menuSender = (NSMenuItem *)sender;
    
    autoFitSource = self.selectedSource;
    if (menuSender.representedObject)
    {
        autoFitSource = (InputSource *)menuSender.representedObject;
    }
    
    [autoFitSource autoFit];
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
        [self exitFullScreenModeWithOptions:nil];
        
        [self.controller layoutLeftFullscreen];
        
    } else {
        
        NSNumber *fullscreenOptions = @(NSApplicationPresentationAutoHideMenuBar|NSApplicationPresentationAutoHideDock);
        
        
        _fullscreenOn = [NSScreen mainScreen];
        
        if (_fullscreenOn != [[NSScreen screens] objectAtIndex:0])
        {
            fullscreenOptions = @(0);
        }
        
        
        [self.controller layoutWentFullscreen];
        
        [self enterFullScreenMode:_fullscreenOn withOptions:@{NSFullScreenModeAllScreens: @NO, NSFullScreenModeApplicationPresentationOptions: fullscreenOptions}];
        
    }
    
}


-(id) initWithFrame:(NSRect)frameRect
{
    
     NSOpenGLPixelFormatAttribute attr[] = {
         NSOpenGLPFANoRecovery,
         NSOpenGLPFAAccelerated,
         NSOpenGLPFAAllowOfflineRenderers,
         NSOpenGLPFADoubleBuffer,
         NSOpenGLPFADepthSize, 32,
         (NSOpenGLPixelFormatAttribute) 0,0,
         (NSOpenGLPixelFormatAttribute) 0
    };
    
    
    
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
    _snap_x = _snap_y = -1;
    
    
    
    [self createShaders];

    
    OpenGLProgram *lineprg = [_shaderPrograms objectForKey:@"line"];

    _lineProgram = lineprg.gl_programName;
    
    
    _cictx = [CIContext contextWithCGLContext:[self.openGLContext CGLContextObj] pixelFormat:CGLGetPixelFormat([self.openGLContext CGLContextObj]) colorSpace:CGColorSpaceCreateDeviceRGB() options:nil];
    int opts = (NSTrackingActiveAlways | NSTrackingInVisibleRect | NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited);
    _trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    
    [self addTrackingArea:_trackingArea];

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
    
    if (!self.sourceLayout || !self.layoutRenderer)
    {
        return;
    }
        
    displayFrame = [self.layoutRenderer currentFrame];
    
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

    CGLLockContext(cgl_ctx);
    
    [self.openGLContext makeCurrentContext];

    IOSurfaceRef cFrame = CVPixelBufferGetIOSurface(cImageBuf);
    
    
    IOSurfaceID cFrameID;
    
    
    if (cFrame)
    {
        cFrameID = IOSurfaceGetID(cFrame);        
    }
    
    if (cFrame && (_boundIOSurfaceID != cFrameID))
    {
        _boundIOSurfaceID = cFrameID;
        

        GLsizei newHeight = (GLsizei)IOSurfaceGetHeight(cFrame);
        GLsizei newWidth = (GLsizei)IOSurfaceGetWidth(cFrame);
        
        if (newHeight != _surfaceHeight || newWidth != _surfaceWidth)
        {
            _resizeDirty = YES;
        }
        
        _surfaceHeight  = newHeight;
        _surfaceWidth   = newWidth;
        
        
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
        
        //glUseProgram(_programId);
        //[self bindProgramTextures:shProgram];
        
        
        

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
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    
    float halfw = (frame.size.width - scaled.width) / 2;
    float halfh = (frame.size.height - scaled.height) / 2;
    

    
    if (_resizeDirty && _surfaceWidth > 0 && _surfaceHeight > 0)
    {
        glViewport(0, 0, frame.size.width, frame.size.height);
        
        glMatrixMode(GL_PROJECTION);
        glPushMatrix();
        glLoadIdentity();
        glOrtho(0.0, frame.size.width, 0.0, frame.size.height, 0, 1);
        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glLoadIdentity();

        glTranslated(halfw, halfh, 0.0);
        glScalef(ratio, ratio, 1.0f);

        glGetDoublev(GL_MODELVIEW_MATRIX, _modelview);
        glGetDoublev(GL_PROJECTION_MATRIX, _projection);
        glGetIntegerv(GL_VIEWPORT, _viewport);
        glDisable(GL_DEPTH_TEST);
        
        _resizeDirty = NO;
        
    }
    


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
    
    
    GLfloat verts[] =
    {
        0, _surfaceHeight,
        _surfaceWidth, _surfaceHeight,
        _surfaceWidth, 0,
        0,0
    };
    
    
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glTexCoordPointer(2, GL_FLOAT, 0, text_coords);
    glEnableClientState(GL_VERTEX_ARRAY);
    glVertexPointer(2, GL_FLOAT, 0, verts);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
    
    
    
    GLfloat outline_verts[8];
    GLfloat snapx_verts[4];
    GLfloat snapy_verts[4];
    

    glEnableClientState(GL_VERTEX_ARRAY);

    //glUseProgram(_lineProgram);
    
    glLineWidth(2.0f);

    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    
    //for(InputSource *src in self.sourceLayout.sourceList)
    if (self.mousedSource || self.isResizing)
    {
        
    

        glColor3f(0.0f, 0.0f, 1.0f);
        NSRect my_rect = self.mousedSource.layoutPosition;
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
    
    if (self.selectedSource)
    {
    
        glLineWidth(1.0f);

        glColor3f(1.0f, 1.0f, 0.0f);
        glLineStipple(2, 0xAAAA);
        //glEnable(GL_LINE_STIPPLE);
        if (_snap_x > -1)
        {
            snapx_verts[0] = _snap_x;
            snapx_verts[1] = 0;
            snapx_verts[2] = _snap_x;
            snapx_verts[3] = self.sourceLayout.canvas_height;
            glVertexPointer(2, GL_FLOAT, 0, snapx_verts);
            glDrawArrays(GL_LINES, 0, 2);
        }
        
        if (_snap_y > -1)
        {
            snapy_verts[0] = 0;
            snapy_verts[1] = _snap_y;
            snapy_verts[2] = self.sourceLayout.canvas_width;
            snapy_verts[3] = _snap_y;
            glVertexPointer(2, GL_FLOAT, 0, snapy_verts);
            glDrawArrays(GL_LINES, 0, 2);
        }
        //glDisable(GL_LINE_STIPPLE);

    }
    glColor3f(1.0f, 1.0f, 1.0f);

    //glUseProgram(_programId);
    
    [self.openGLContext flushBuffer];
    
    //glFlush();

    

    
}

- (BOOL)popoverShouldDetach:(NSPopover *)popover
{
    return YES;
}


-(NSWindow *)detachableWindowForPopover:(NSPopover *)popover
{
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
    
    oldViewController.inputSource = nil;
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
        vcont.inputSource = nil;
        
    }
    
}


@end
