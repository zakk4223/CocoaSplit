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


-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
}

-(CGRect)contentsRect
{
    return _privateCropRect;
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
    
    newCrop.origin.x = _deckLinkFrameSize.width * _privateCropRect.origin.x;
    newCrop.origin.y = _deckLinkFrameSize.height * _privateCropRect.origin.y;
    newCrop.size.width = _deckLinkFrameSize.width * _privateCropRect.size.width;
    newCrop.size.height = _deckLinkFrameSize.height * _privateCropRect.size.height;

    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        float wr = newCrop.size.width / self.bounds.size.width;
        float hr = newCrop.size.height / self.bounds.size.height;
        
        float ratio = (hr < wr ? wr : hr);
        useSize = NSMakeSize(newCrop.size.width / ratio, newCrop.size.height / ratio);
    }
    

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
    
    
    GLfloat yt = 1.0 - (_privateCropRect.origin.y + _privateCropRect.size.height);
    

    glScalef(_privateCropRect.size.width, _privateCropRect.size.height, 1);
    glTranslatef(_privateCropRect.origin.x * _deckLinkFrameSize.width, yt * _deckLinkFrameSize.height, 0);

    
    
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
