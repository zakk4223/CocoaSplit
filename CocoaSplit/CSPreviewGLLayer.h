//
//  CSPreviewGLLayer.h
//  CocoaSplit
//
//  Created by Zakk on 8/8/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "LayoutRenderer.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>
#import <GLKit/GLKit.h>



@interface CSPreviewGLLayer : CAOpenGLLayer
{
    bool _initDone;
    GLuint _renderTexture;
    NSSize _lastSurfaceSize;
    bool _resizeDirty;
    CIContext *_cictx;
    bool _resetClearColor;
    
    
    GLint       _viewport[4];
    GLKMatrix4    _modelview;
    GLKMatrix4    _projection;
    CVPixelBufferRef _renderBuffer;
    
    
}

@property (strong) LayoutRenderer *renderer;
@property (weak) InputSource *outlineSource;
@property (assign) bool doSnaplines;

@property (assign) float snap_y;
@property (assign) float snap_x;
@property (assign) bool doRender;
@property (assign) bool midiActive;
@property (assign) bool resizeDirty;


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;




@end
