//
//  PreviewView.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>


@interface PreviewView : NSOpenGLView
{

    IOSurfaceRef _boundIOSurface;
    GLuint      _previewTexture;
    GLsizei     _surfaceWidth;
    GLsizei     _surfaceHeight;
    
}

-(void) drawFrame:(CVImageBufferRef)cFrame;

@end
