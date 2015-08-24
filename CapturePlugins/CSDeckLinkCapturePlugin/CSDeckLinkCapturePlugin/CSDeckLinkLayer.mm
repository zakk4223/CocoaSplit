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


/*
-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
    [self calculateCrop:_lastImageSize];
    _needsRedraw = YES;
    [self setNeedsDisplay];
}

-(CGRect)contentsRect
{
    return _privateCropRect;
}
*/


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

    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        float wr = _deckLinkFrameSize.width / self.bounds.size.width;
        float hr = _deckLinkFrameSize.height / self.bounds.size.height;
        
        float ratio = (hr < wr ? wr : hr);
        useSize = NSMakeSize(_deckLinkFrameSize.width / ratio, _deckLinkFrameSize.height / ratio);
    }
    
    GLint vpx = (self.bounds.size.width - useSize.width)/2;
    GLint vpy = (self.bounds.size.height - useSize.height)/2;

    glViewport(vpx, vpy, useSize.width, useSize.height);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    
    
    if (_deckLinkOGL)
    {
        _deckLinkOGL->PaintGL();
    }

    /*
    glTranslated(self.bounds.size.width * 0.5, self.bounds.size.height * 0.5, 0.0);
    */
    
    
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
