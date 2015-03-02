//
//  LayoutRenderer.m
//  CocoaSplit
//
//  Created by Zakk on 2/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "LayoutRenderer.h"

@implementation LayoutRenderer
@synthesize layout = _layout;


-(instancetype)init
{
    if (self = [super init])
    {
        _layoutChanged = NO;
    }
    
    return self;
}



-(void)setLayout:(SourceLayout *)layout
{
    _layout = layout;
    _layoutChanged = YES;
}

-(SourceLayout *)layout
{
    return _layout;
}


-(void) createCGLContext
{
    CGLPixelFormatAttribute glAttributes[] = {
        
        kCGLPFAAccelerated,
        kCGLPFANoRecovery,
        kCGLPFADepthSize, (CGLPixelFormatAttribute)32,
        kCGLPFAAllowOfflineRenderers,
        (CGLPixelFormatAttribute)0
    };
    
    GLint screens;
    CGLPixelFormatObj pixelFormat;
    CGLChoosePixelFormat(glAttributes, &pixelFormat, &screens);
    
    
    if (!pixelFormat)
    {
        return;
    }
    
    CGLCreateContext(pixelFormat, NULL, &_cglCtx);
    
}

-(void)resizeRenderer
{
    
    if (!self.layout)
    {
        return;
    }
    
    
    if (!self.cglCtx)
    {
        [self createCGLContext];
    }
    
    
    CGLSetCurrentContext(self.cglCtx);
    
    if (!self.renderer)
    {
        self.renderer = [CARenderer rendererWithCGLContext:self.cglCtx options:nil];
    }
    
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
        self.renderer.layer = self.rootLayer;
    }

    self.rootLayer.bounds = CGRectMake(0, 0, _cvpool_size.width, _cvpool_size.height);
    self.rootLayer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    self.rootLayer.position = CGPointMake(0.0, 0.0);
    self.rootLayer.anchorPoint = CGPointMake(0.0, 0.0);
    self.rootLayer.masksToBounds = YES;
    self.rootLayer.sublayerTransform = CATransform3DIdentity;
    self.rootLayer.sublayerTransform = CATransform3DTranslate(self.rootLayer.sublayerTransform, 0, _cvpool_size.height, 0);
    self.rootLayer.sublayerTransform = CATransform3DScale(self.rootLayer.sublayerTransform, 1.0, -1.0, 1.0);
    self.renderer.bounds = NSMakeRect(0.0, 0.0, _cvpool_size.width, _cvpool_size.height);
    
    glViewport(0, 0, _cvpool_size.width, _cvpool_size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, _cvpool_size.width, 0,_cvpool_size.height, -1, 1);
    
    
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    
    glClearColor(0, 0, 0, 0);

}


-(void)setupCArenderer
{
    
    CGLSetCurrentContext(self.cglCtx);
    
    [CATransaction begin];
    //[CATransaction setDisableActions:YES];
    
    
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
    }
    
    
    SourceLayout *saveLayout = _currentLayout;
    
    
    if (saveLayout && self.transitionName)
    {
        [CATransaction setDisableActions:YES];
        _layoutTransition = [CATransition animation];
        _layoutTransition.type = self.transitionName  ;
        _layoutTransition.subtype = self.transitionDirection;
        _layoutTransition.duration = self.transitionDuration;
        _layoutTransition.removedOnCompletion = YES;
        [CATransaction setCompletionBlock:^{
            [CATransaction begin];
            [saveLayout.rootLayer removeFromSuperlayer];
            saveLayout.isActive = NO;
            [CATransaction commit];
        }];
        [self.rootLayer addAnimation:_layoutTransition forKey:nil];
        
        [self.rootLayer addSublayer:self.layout.rootLayer];
    } else {
        if (saveLayout)
        {
            [saveLayout.rootLayer removeFromSuperlayer];
            saveLayout.isActive = NO;
        }
        [self.renderer.layer addSublayer:self.layout.rootLayer];
    }
    
    [CATransaction commit];


    _currentLayout = self.layout;
    
}

-(void)renderToSurface:(IOSurfaceRef)ioSurface
{
    CGLSetCurrentContext(self.cglCtx);
    
    if (!_rFbo)
    {
        glGenFramebuffers(1, &_rFbo);
        
    }
    
    if (!_fboTexture)
    {
        glGenTextures(1, &_fboTexture);
        
    }
    
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _fboTexture);
    
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    
    
    CGLTexImageIOSurface2D(self.cglCtx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, (int)IOSurfaceGetWidth(ioSurface), (int)IOSurfaceGetHeight(ioSurface), GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, ioSurface, 0);
    
    GLenum fboStatus;
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, _fboTexture, 0);
    
    glBindFramebuffer(GL_FRAMEBUFFER, _rFbo);
    fboStatus  = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (fboStatus == GL_FRAMEBUFFER_COMPLETE && self.renderer && self.renderer.layer)
    {
        [self.renderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];
        [self.renderer addUpdateRect:self.renderer.bounds];
        [self.renderer render];
        [self.renderer endFrame];
    }
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);
    
    //glFlush();
}

-(CVPixelBufferRef)currentImg
{
    CVPixelBufferRef destFrame = NULL;
    CGFloat frameWidth, frameHeight;

    [self.layout frameTick];
    
    frameWidth = self.layout.canvas_width;
    frameHeight = self.layout.canvas_height;
    
    NSSize frameSize = NSMakeSize(frameWidth, frameHeight);
    
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        return nil;
    }
 
    if (!CGSizeEqualToSize(frameSize, _cvpool_size))
    {
        [self createPixelBufferPoolForSize:frameSize];
        _cvpool_size = frameSize;
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [self resizeRenderer];
        [CATransaction commit];
    }
    
    
    if (_layoutChanged)
    {
        [self setupCArenderer];
        _layoutChanged = NO;

    }
    
    CVPixelBufferPoolCreatePixelBuffer(kCVReturnSuccess, _cvpool, &destFrame);
    
    
    
    [self renderToSurface:CVPixelBufferGetIOSurface(destFrame)];
    
    
    @synchronized(self)
    {
        if (_currentPB)
        {
            CVPixelBufferRelease(_currentPB);
        }
        
        _currentPB = destFrame;
    }
    
    
    return _currentPB;
}


-(CVPixelBufferRef)currentFrame
{
    
    
    if (!self.isLiveRenderer)
    {
        [self currentImg];
    }
    
    
    @synchronized(self)
    {
        CVPixelBufferRetain(_currentPB);
        return _currentPB;
    }
}



-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    NSLog(@"Controller: Creating Pixel Buffer Pool %f x %f", size.width, size.height);
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @NO} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_cvpool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;
    
    
}

@end
