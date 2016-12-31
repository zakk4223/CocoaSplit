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
    
}


-(void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    CGLSetCurrentContext(ctx);
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    

    
    NSSize useSize = self.bounds.size;
    CGRect newCrop;
    
    GLint vpx = (self.bounds.size.width - useSize.width)/2;
    GLint vpy = (self.bounds.size.height - useSize.height)/2;

    glViewport(vpx, vpy, useSize.width, useSize.height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    
    NSRect cropRect;
    glMatrixMode(GL_TEXTURE);
    glLoadIdentity();
    
    
    if (_deckLinkOGL)
    {
        _deckLinkOGL->PaintGL();
    }

    
    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    
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
