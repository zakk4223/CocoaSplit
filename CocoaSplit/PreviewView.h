//
//  PreviewView.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

#import "CaptureController.h"
#import "InputSource.h"



@class SourceLayout;
//@class InputSource;

static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);


#define SNAP_THRESHOLD 10.0f




@interface OpenGLProgram : NSObject
{
    
    GLint _sampler_uniform_locations[3];
}

@property (strong) NSString *label;
@property (assign) GLuint gl_programName;




-(void) setUniformLocation:(int)index location:(GLint)location;
-(GLint) getUniformLocation:(int)index;

@end



@interface PreviewView : NSOpenGLView <NSPopoverDelegate, NSWindowDelegate>

{

    IOSurfaceID _boundIOSurfaceID;
    NSMutableDictionary      *_shaderPrograms;
    GLuint      _previewTextures[3]; //Is there something with more than 3 planes? Guess we'll find out;
    GLsizei     _surfaceWidth;
    GLsizei     _surfaceHeight;
    int         _hackcnt;
    GLuint      _vertexPosBuffer;
    GLuint      _programId;
    GLuint      _lineProgram;
    bool        _resizeDirty;
    GLint       _viewport[4];
    GLdouble    _modelview[16];
    GLdouble    _projection[16];

    
    float _snap_x_accum, _snap_y_accum;
    float _snap_x, _snap_y;
    bool _in_resize_rect;
    
    CIImage *_currentImage;
    
    
    CVDisplayLinkRef displayLink;
    
    int _num_planes;
    
    id _fs_activity_token;
    
    NSTimer *_idleTimer;
    NSTrackingArea *_trackingArea;
    NSRecursiveLock *renderLock;

    CVPixelBufferPoolRef  _renderPool;
    CIContext *_ciCtx;
    

    NSScreen *_fullscreenOn;
    NSPopover *_layoutpopOver;
    

    

}

- (IBAction)toggleFullscreen:(id)sender;

- (IBAction)moveInputUp:(id)sender;
- (IBAction)moveInputDown:(id)sender;
- (IBAction)deleteInput:(id)sender;
- (IBAction)addInputSource:(id)sender;
- (IBAction)showInputSettings:(id)sender;


-(void)spawnInputSettings:(InputSource *)forInput atRect:(NSRect)atRect;
-(void)stopDisplayLink;
-(void)restartDisplayLink;
-(void) cvrender;




@property (strong) NSMenu *sourceSettingsMenu;

@property (strong) NSMenu *sourceListMenu;


@property (strong) CIContext *cictx;

@property (strong) NSColor *statusColor;

@property (unsafe_unretained) IBOutlet CaptureController *controller;

@property (strong) InputSource *selectedSource;
@property (strong) InputSource *mousedSource;

@property (assign) NSPoint selectedOriginDistance;
@property (assign) bool isResizing;
@property (assign) resize_style resizeType;
@property (strong) SourceLayout *sourceLayout;




@end


