//
//  CSDeckLinkLayer.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSDeckLinkLayer.h"

@implementation CSDeckLinkLayer


-(instancetype)init
{
    if (self = [super init])
    {
        self.asynchronous = NO;
        self.needsDisplayOnBoundsChange = YES;
        
        _deckLinkOGL = CreateOpenGLScreenPreviewHelper();
        _deckLinkOGL->AddRef();
    }
    
    return self;
}

-(CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    _myCGLContext = [super copyCGLContextForPixelFormat:pf];
    CGLSetCurrentContext(_myCGLContext);
    if (_deckLinkOGL)
    {
        _deckLinkOGL->InitializeGL();
    }
    
    return _myCGLContext;
}


-(void)releaseCGLContext:(CGLContextObj)ctx
{
    if (_deckLinkOGL)
    {
        _deckLinkOGL->Release();
        _deckLinkOGL = NULL;
    }
    CGLReleaseContext(ctx);
}

-(BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    return YES;
}



-(void)setRenderFrame:(IDeckLinkVideoFrame *)frame
{
    if (_deckLinkOGL)
    {
        _deckLinkOGL->SetFrame(frame);
    }
    _deckLinkFrameSize = CGSizeMake(frame->GetWidth(), frame->GetHeight());
    self.textureSize = _deckLinkFrameSize;
    
}


-(void)drawLayerContents:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    
    
    if (_deckLinkOGL)
    {
        _deckLinkOGL->PaintGL();
    }
    
    
    
    
    _needsRedraw = NO;
    
    
}

-(void)dealloc
{
    if (_deckLinkOGL)
    {
        _deckLinkOGL->Release();
    }
}
@end
