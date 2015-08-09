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



@interface CSPreviewGLLayer : CAOpenGLLayer
{
    bool _initDone;
    GLuint _renderTexture;
    NSSize _lastSurfaceSize;
    bool _resizeDirty;
    CIContext *_cictx;
    
    
    GLint       _viewport[4];
    GLdouble    _modelview[16];
    GLdouble    _projection[16];

    
}

@property (strong) LayoutRenderer *renderer;
@property (weak) InputSource *outlineSource;
@property (assign) bool doSnaplines;

@property (assign) float snap_y;
@property (assign) float snap_x;


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;



@end
