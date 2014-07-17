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
#import "ControllerProtocol.h"



static CVReturn displayLinkRender(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime,
                                    CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);


@interface OpenGLProgram : NSObject
{
    
    GLint _sampler_uniform_locations[3];
}

@property (strong) NSString *label;
@property (assign) GLuint gl_programName;




-(void) setUniformLocation:(int)index location:(GLint)location;
-(GLint) getUniformLocation:(int)index;

@end



@interface PreviewView : NSOpenGLView
{

    IOSurfaceID _boundIOSurfaceID;
    NSMutableDictionary      *_shaderPrograms;
    GLuint      _previewTextures[3]; //Is there something with more than 3 planes? Guess we'll find out;
    GLuint      _syphonTexture;
    GLsizei     _surfaceWidth;
    GLsizei     _surfaceHeight;
    int         _hackcnt;
    GLuint      _vertexPosBuffer;
    CVDisplayLinkRef displayLink;
    
    int _num_planes;
    
    id _fs_activity_token;
    
    NSTimer *_idleTimer;
    NSTrackingArea *_trackingArea;
    NSRecursiveLock *renderLock;

    CVPixelBufferPoolRef  _renderPool;

    NSScreen *_fullscreenOn;

    

}


-(void) drawFrame:(CVImageBufferRef)cFrame;
- (IBAction)toggleFullscreen:(id)sender;




@property (strong) CIContext *cictx;

@property (strong) NSColor *statusColor;

@property (unsafe_unretained) IBOutlet id<ControllerProtocol> controller;


@end


