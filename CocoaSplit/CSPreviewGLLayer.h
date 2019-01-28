//
//  CSPreviewGLLayer.h
//  CocoaSplit
//
//  Created by Zakk on 8/8/15.
//

#import <QuartzCore/QuartzCore.h>
#import "LayoutRenderer.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>
#import <GLKit/GLKit.h>

#import "CSPreviewRendererLayer.h"


@interface CSPreviewGLLayer : CAOpenGLLayer <CSPreviewRendererLayer>
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
@property (assign) bool doRender;
@property (assign) bool midiActive;
@property (assign) bool resizeDirty;
@property (assign) bool doDisplay;


-(NSPoint)realPointforWindowPoint:(NSPoint)winPoint;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;




@end
