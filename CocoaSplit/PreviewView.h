//
//  PreviewView.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <Syphon/Syphon.h>
#import "CaptureController.h"



@class SourceLayout;
@class InputSource;

static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);


#define SNAP_THRESHOLD 10.0f


typedef enum resize_style_t {
 
    kResizeNone = 0,
    kResizeTop = 1 << 0,
    kResizeRight = 1<<1,
    kResizeBottom = 1<<2,
    kResizeLeft = 1<<3
    
} resize_style;


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
    GLuint      _syphonTexture;
    GLsizei     _surfaceWidth;
    GLsizei     _surfaceHeight;
    int         _hackcnt;
    GLuint      _vertexPosBuffer;
    GLuint      _programId;
    GLuint      _lineProgram;
    
    CVDisplayLinkRef displayLink;
    
    int _num_planes;
    
    id _fs_activity_token;
    
    NSTimer *_idleTimer;
    NSTrackingArea *_trackingArea;
    NSRecursiveLock *renderLock;

    CVPixelBufferPoolRef  _renderPool;
    CIContext *_ciCtx;
    

    NSScreen *_fullscreenOn;

    

}

- (IBAction)toggleFullscreen:(id)sender;

- (IBAction)moveInputUp:(id)sender;
- (IBAction)moveInputDown:(id)sender;
- (IBAction)deleteInput:(id)sender;
- (IBAction)addInputSource:(id)sender;
- (IBAction)showInputSettings:(id)sender;

-(void)spawnInputSettings:(InputSource *)forInput atRect:(NSRect)atRect;



@property (strong) NSMenu *sourceSettingsMenu;

@property (strong) NSMenu *sourceListMenu;


@property (strong) CIContext *cictx;

@property (strong) NSColor *statusColor;

@property (unsafe_unretained) IBOutlet CaptureController *controller;

@property (strong) InputSource *selectedSource;
@property (assign) NSPoint selectedOriginDistance;
@property (assign) bool isResizing;
@property (assign) resize_style resizeType;
@property (assign) NSPoint resizeAnchor;
@property (strong) SourceLayout *sourceLayout;
//If a preview view is set to an active source we copy it so changes don't mess with the live feed
//When we save or set to live we use this variable to grab the original version and modify it in place
@property (strong) SourceLayout *originalActiveLayout;




@end


