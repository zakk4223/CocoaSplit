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



@interface PreviewView : NSOpenGLView
{

    IOSurfaceID _boundIOSurfaceID;
    GLuint      _previewTexture;
    GLuint      _syphonTexture;
    GLsizei     _surfaceWidth;
    GLsizei     _surfaceHeight;
    int         _hackcnt;
    NSTimer *_idleTimer;
    NSTrackingArea *_trackingArea;
    NSRecursiveLock *renderLock;

    
    NSScreen *_fullscreenOn;

    
}

-(void) drawFrame:(CVImageBufferRef)cFrame;
- (IBAction)toggleFullscreen:(id)sender;

@property (assign) BOOL vsync;

@end
