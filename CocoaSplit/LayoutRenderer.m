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


-(id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event
{
    return (id<CAAction>)[NSNull null];
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
    
    NSLog(@"RESIZE RENDERER");
    if (!self.renderer)
    {
        //self.renderer = [CARenderer rendererWithCGLContext:self.cglCtx options:nil];
    }
    
    
    
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
        //self.renderer.layer = self.rootLayer;
    }

    self.rootLayer.bounds = CGRectMake(0, 0, _cvpool_size.width, _cvpool_size.height);
    self.rootLayer.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    self.rootLayer.position = CGPointMake(0.0, 0.0);
    self.rootLayer.anchorPoint = CGPointMake(0.0, 0.0);
   // self.rootLayer.masksToBounds = YES;
    self.rootLayer.sublayerTransform = CATransform3DIdentity;
    //self.rootLayer.sublayerTransform = CATransform3DTranslate(self.rootLayer.sublayerTransform, 0, _cvpool_size.height, 0);
    self.rootLayer.sublayerTransform = CATransform3DScale(self.rootLayer.sublayerTransform, 1.0, -1.0, 1.0);
    self.renderer.bounds = NSMakeRect(0.0, 0.0, _cvpool_size.width, _cvpool_size.height);
    self.rootLayer.delegate = self;

    if (!self.sceneRenderer)
    {
        self.sceneRenderer = [SCNRenderer rendererWithContext:self.cglCtx options:nil];
        self.sceneRenderer.scene = self.layout.rootScene;
        self.sceneRenderer.pointOfView = self.layout.cameraNode;
        self.sceneRenderer.debugOptions = SCNDebugOptionShowBoundingBoxes;
        self.sceneRenderer.showsStatistics = YES;
        self.sceneRenderer.delegate = self;
        
    }


    glViewport(0, 0, _cvpool_size.width, _cvpool_size.height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    NSLog(@"CVPOOL %@", NSStringFromSize(_cvpool_size));
    
    
    //glMatrixMode(GL_MODELVIEW);
   // glLoadIdentity();
    glClearColor(1,0,1,1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    CGLSetCurrentContext(NULL);

}


-(void)setupCArenderer
{
    CGLSetCurrentContext(self.cglCtx);
    
    
    
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
        self.rootLayer.delegate = self;
    }
    
    
    
    
    
    [CATransaction begin];
    _currentLayout.inTransition = NO;
    
    if (_transitionLayout)
    {
        
        [_transitionLayout.rootLayer removeFromSuperlayer];
        _transitionLayout.isActive = NO;
        _transitionLayout = nil;
    }
    
    [self.rootLayer addSublayer:self.layout.rootLayer];
    [CATransaction commit];
    
    
    
    _currentLayout = self.layout;
    [_currentLayout didBecomeVisible];
    
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
    
    if (!_flipTexture)
    {
        glGenTextures(1, &_flipTexture);\
        glEnable(GL_TEXTURE_RECTANGLE_ARB);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _flipTexture);
        glTexImage2D(GL_TEXTURE_RECTANGLE_ARB, 0, GL_RGBA, (int)IOSurfaceGetWidth(ioSurface), (int)IOSurfaceGetHeight(ioSurface), 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, 0);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
        glDisable(GL_TEXTURE_RECTANGLE_ARB);

    }
    
    if (!_flipFbo)
    {
        glGenFramebuffers(1, &_flipFbo);
    }
    
    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _flipTexture);
    
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    
    
    
    
    GLenum fboStatus;
    
    glBindFramebuffer(GL_FRAMEBUFFER, _flipFbo);

    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, _flipTexture, 0);
    
    fboStatus  = glCheckFramebufferStatus(GL_FRAMEBUFFER);

    glClearColor(0,0,0,1);
    glClear(GL_COLOR_BUFFER_BIT);
    if (fboStatus == GL_FRAMEBUFFER_COMPLETE && self.sceneRenderer)
    {
        [self.sceneRenderer renderAtTime:CACurrentMediaTime()];
    }
    
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);

    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _fboTexture);

    CGLTexImageIOSurface2D(self.cglCtx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, (int)IOSurfaceGetWidth(ioSurface), (int)IOSurfaceGetHeight(ioSurface), GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, ioSurface, 0);

    glBindFramebuffer(GL_READ_FRAMEBUFFER, _flipFbo);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, _rFbo);
    glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, _flipTexture, 0);
    glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB, _rFbo, 0);

    glBlitFramebuffer(0, 0, _cvpool_size.width, _cvpool_size.height, 0, _cvpool_size.height, _cvpool_size.width, 0, GL_COLOR_BUFFER_BIT, GL_NEAREST);
    
    glBindFramebuffer(GL_READ_FRAMEBUFFER, 0);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);
    glDisable(GL_TEXTURE_RECTANGLE_ARB);

    glFlush();
    [CATransaction flush];
    CGLSetCurrentContext(NULL);
}

-(CVPixelBufferRef)currentImg
{
    
    
    if (!self.layout)
    {
        return NULL;
    }
    
    
    if (self.cglCtx)
    {
        CGLSetCurrentContext(self.cglCtx);
    }
    
    CVPixelBufferRef destFrame = NULL;
    CGFloat frameWidth, frameHeight;

    
    [self.layout frameTick];
    if (_transitionLayout)
    {
        [_transitionLayout frameTick];
    }
    
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
        [self resizeRenderer];
    }
    

    
    if (_layoutChanged)
    {
        [self setupCArenderer];
        _layoutChanged = NO;

    }
    
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _cvpool, &destFrame);
    

    [self renderToSurface:CVPixelBufferGetIOSurface(destFrame)];

    
    @synchronized(self)
    {
        if (_currentPB)
        {
            CVPixelBufferRelease(_currentPB);
        }
        
        _currentPB = destFrame;
    }
    
    CGLSetCurrentContext(NULL);
    return _currentPB;
}


-(CVPixelBufferRef)currentFrame
{
    
    @synchronized(self)
    {
        if (_currentPB)
        {
            CVPixelBufferRetain(_currentPB);
        }
        return _currentPB;
    }
}



-(bool) createPixelBufferPoolForSize:(NSSize) size
{
    NSLog(@"Controller: Creating Pixel Buffer Pool %f x %f LAYOUT %@", size.width, size.height, self.layout);
    
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
