//
//  LayoutRenderer.m
//  CocoaSplit
//
//  Created by Zakk on 2/28/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CaptureController.h"
#import "LayoutRenderer.h"
#import <Metal/Metal.h>

@implementation LayoutRenderer
@synthesize layout = _layout;


-(instancetype)init
{
    if (self = [super init])
    {
        _layoutChanged = NO;
        bool systemMetal = CaptureController.sharedCaptureController.useMetalIfAvailable;
        
        if (systemMetal && [CARenderer instancesRespondToSelector:@selector(setDestination:)])
        {
            NSLog(@"USING METAL RENDERER");
            _useMetalRenderer = YES; //CArenderer supports swapping the destination Metal texture on the fly
            _metalDevice = MTLCreateSystemDefaultDevice();
            [self createMetalTextureCache];
            
        } else {
            _useMetalRenderer = NO;
        }
        //
        _useMetalRenderer = NO;

         
    }
    
    return self;
}



-(void)setLayout:(SourceLayout *)layout
{
    _layout = layout;
    @synchronized (self) {
        _layoutChanged = YES;
    }
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

-(void) setupRootlayer
{
    self.rootLayer.bounds = CGRectMake(0, 0, _cvpool_size.width, _cvpool_size.height);
    CGColorRef tmpColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    self.rootLayer.backgroundColor = tmpColor;
    CGColorRelease(tmpColor);
    self.rootLayer.position = CGPointMake(0.0, 0.0);
    self.rootLayer.anchorPoint = CGPointMake(0.0, 0.0);
    self.rootLayer.masksToBounds = YES;
    self.rootLayer.sublayerTransform = CATransform3DIdentity;
    self.rootLayer.sublayerTransform = CATransform3DTranslate(self.rootLayer.sublayerTransform, 0, _cvpool_size.height, 0);
    self.rootLayer.sublayerTransform = CATransform3DScale(self.rootLayer.sublayerTransform, 1.0, -1.0, 1.0);
    self.renderer.bounds = NSMakeRect(0.0, 0.0, _cvpool_size.width, _cvpool_size.height);
    self.rootLayer.delegate = self;
}


-(void)resizeRenderer
{
    
    if (!self.layout)
    {
        return;
    }
    
    
    if (!_useMetalRenderer)
    {
        if (!self.cglCtx)
        {
            [self createCGLContext];
        }
        CGLSetCurrentContext(self.cglCtx);
    }
    
    
    if (!self.renderer)
    {
        if (_useMetalRenderer)
        {
            //A bit wasteful, but only for the initial frame
            CVPixelBufferRef dummyFrame = NULL;
            
            CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _cvpool, &dummyFrame);
            CVMetalTextureRef dummyTexture = NULL;
            
            CVMetalTextureCacheCreateTextureFromImage(NULL, _cvmetalcache, dummyFrame, NULL, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(dummyFrame), CVPixelBufferGetHeight(dummyFrame), 0, &dummyTexture);
            if (@available(macOS 10.13, *)) {
                self.renderer = [CARenderer rendererWithMTLTexture:CVMetalTextureGetTexture(dummyTexture) options:nil];
            } else {
                self.renderer = [CARenderer rendererWithCGLContext:self.cglCtx options:nil];
            }
        } else {
            self.renderer = [CARenderer rendererWithCGLContext:self.cglCtx options:nil];
        }
    }
    
    
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
        self.renderer.layer = self.rootLayer;
    }

    [self setupRootlayer];

    
    if (!_useMetalRenderer)
    {
        glViewport(0, 0, _cvpool_size.width, _cvpool_size.height);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, _cvpool_size.width, 0,_cvpool_size.height, -1, 1);
    
    
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
    
    
        glClearColor(0, 0, 0, 0);
    }

}


-(void)setupCArenderer
{
    CGLSetCurrentContext(self.cglCtx);
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
        [self setupRootlayer];
        self.renderer.layer = self.rootLayer;
    }
    
    [self.renderer.layer addSublayer:self.layout.transitionLayer];
    _currentLayout = self.layout;
    [_currentLayout didBecomeVisible];
    
}

-(void)renderToPixelBuffer:(CVPixelBufferRef)pixelBuffer
{

    if (!pixelBuffer)
    {
        return;
    }
    
    if (_useMetalRenderer)
    {
        CVMetalTextureRef mtlTexture = NULL;
        CVMetalTextureCacheCreateTextureFromImage(NULL, _cvmetalcache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &mtlTexture);
        if (!mtlTexture)
        {
            return;
        }
        [self.renderer setDestination:CVMetalTextureGetTexture(mtlTexture)];
        [self.renderer beginFrameAtTime:CACurrentMediaTime() timeStamp:NULL];
        [self.renderer addUpdateRect:self.renderer.bounds];
        [self.renderer render];
        [self.renderer endFrame];
        CFRelease(mtlTexture);
            
        return;
    }
    
    IOSurfaceRef ioSurface = CVPixelBufferGetIOSurface(pixelBuffer);
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
    
    glFlush();
   // [CATransaction flush];
}

-(CVPixelBufferRef)currentImg
{

    [CATransaction begin];
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

    
    frameWidth = self.layout.canvas_width;
    frameHeight = self.layout.canvas_height;
    
    NSSize frameSize = NSMakeSize(frameWidth, frameHeight);
    
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        CGLSetCurrentContext(NULL);

        return nil;
    }
 
    if (!CGSizeEqualToSize(frameSize, _cvpool_size))
    {
        [self createPixelBufferPoolForSize:frameSize];
        _cvpool_size = frameSize;
        [self resizeRenderer];
    }
    

    bool doSetup = NO;
    @synchronized (self) {
        doSetup = _layoutChanged;
    }
    
    if (doSetup && self.renderer)
    {
        //[CATransaction lock];
        [CATransaction begin];
        [self setupCArenderer];
        [CATransaction commit];
        //[CATransaction unlock];
        @synchronized (self) {
            _layoutChanged = NO;
        }

    }
    
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _cvpool, &destFrame);

    @synchronized (self) {
        [CATransaction begin];
        [self renderToPixelBuffer:destFrame];
        //[CATransaction unlock];
        [CATransaction commit];
    }
    [CATransaction commit];
    CGLSetCurrentContext(NULL);
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
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{(NSString *)kIOSurfaceIsGlobal: @NO} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    [attributes setValue:@YES forKey:(NSString *)kCVPixelBufferMetalCompatibilityKey];
    
    
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

-(bool)createMetalTextureCache
{
    if (_cvmetalcache)
    {
        CFRelease(_cvmetalcache);
    }
    
    CVReturn result = CVMetalTextureCacheCreate(NULL, NULL, _metalDevice, NULL, &_cvmetalcache);
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    return YES;
}


-(void)dealloc
{
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    if (_cglCtx)
    {
        CGLDestroyContext(_cglCtx);
    }
    
    if (_currentPB)
    {
        CVPixelBufferRelease(_currentPB);
    }
}

@end
