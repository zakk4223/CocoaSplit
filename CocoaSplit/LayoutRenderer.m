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
        
        _usescene = [SCNScene scene];
        _cameraNode = [SCNNode node];
        _cameraNode.camera = [SCNCamera camera];
        [_usescene.rootNode addChildNode:_cameraNode];
        
        if (systemMetal)
        {
            _useMetalRenderer = YES;
            _metalDevice = [CaptureController.sharedCaptureController currentMetalDevice];
            NSLog(@"USING METAL RENDERER WITH DEVICE %@", _metalDevice);
            [self createMetalTextureCache];


            _mtlCmdQueue = [_metalDevice newCommandQueue];
        } else {
            
            _useMetalRenderer = NO;
        }
        

        
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

-(void)setupSceneRenderer
{
    
    float half_width = _cvpool_size.width/2.0f;
    float half_height = _cvpool_size.height/2.0f;
    _minBounding = SCNVector3Make(0, 0, 0);
    _maxBounding = SCNVector3Make(_cvpool_size.width, _cvpool_size.height, 0);
    [_usescene.rootNode setBoundingBoxMin:&_minBounding max:&_maxBounding];
    if (!_planeNode)
    {
        _planeNode = [SCNNode node];
        [_usescene.rootNode addChildNode:_planeNode];
    }
    
    if (!_planeNode.geometry)
    {
        _planeNode.geometry = [SCNPlane planeWithWidth:_cvpool_size.width height:_cvpool_size.height];
    }
    

    
    _planeNode.geometry.firstMaterial.diffuse.contents = nil;
    
    SCNPlane *planeGeometry = (SCNPlane *)_planeNode.geometry;
    planeGeometry.width = _cvpool_size.width;
    planeGeometry.height = _cvpool_size.height;
    CGFloat camZ_w;
    CGFloat camZ_h;
    CGFloat camZ;
    
    camZ_w = fabs(half_width/tan((30.0f)*(M_PI/180)));
    camZ_h = fabs(half_height/tan((30.0f)*(M_PI/180)));
    if (camZ_w < camZ_h)
    {
        camZ = camZ_w;
    } else {
        camZ = camZ_h;
    }
    
    _planeNode.position = SCNVector3Make(half_width, half_height, 0);
    _cameraNode.position = SCNVector3Make(half_width, half_height, camZ);
    _cameraNode.camera.zFar = 50000;
}


-(void) setupRootlayer
{
    self.rootLayer.bounds = CGRectMake(0, 0, _cvpool_size.width, _cvpool_size.height);
    CGColorRef tmpColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    self.rootLayer.backgroundColor = tmpColor;
    CGColorRelease(tmpColor);
    self.rootLayer.anchorPoint = CGPointMake(0.0, 0.0);

    self.rootLayer.position = CGPointMake(0.0, _cvpool_size.height);
    self.rootLayer.masksToBounds = YES;
    if (!_useMetalRenderer)
    {
        self.rootLayer.sublayerTransform = CATransform3DIdentity;
        self.rootLayer.sublayerTransform = CATransform3DTranslate(self.rootLayer.sublayerTransform, 0, _cvpool_size.height, 0);
        self.rootLayer.sublayerTransform = CATransform3DScale(self.rootLayer.sublayerTransform, 1.0, -1.0, 1.0);
    }
    if (_planeNode)
    {
        _planeNode.geometry.firstMaterial.diffuse.contents = self.rootLayer;

    }

    self.rootLayer.delegate = self;
}


-(void)resizeRenderer
{
    
    if (!self.layout)
    {
        return;
    }
    
    [self setupSceneRenderer];
    

    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
    }

    [self setupRootlayer];

    
    if (_useMetalRenderer)
    {
        if (!_sceneRenderer)
        {
            _sceneRenderer = [SCNRenderer rendererWithDevice:_metalDevice options:nil];
            _sceneRenderer.scene = _usescene;
            _sceneRenderer.pointOfView = _cameraNode;
        }
    } else {
        if (!self.cglCtx)
        {
            [self createCGLContext];
        }
        
        if (!_sceneRenderer)
        {
            _sceneRenderer = [SCNRenderer rendererWithContext:self.cglCtx options:nil];
            _sceneRenderer.scene = _usescene;
            _sceneRenderer.pointOfView = _cameraNode;

        }
        CGLSetCurrentContext(self.cglCtx);
        glViewport(0, 0, _cvpool_size.width, _cvpool_size.height);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
       // glOrtho(0, _cvpool_size.width, 0,_cvpool_size.height, -1, 1);
    
    
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
    
    
        glClearColor(0, 0, 0, 0);
    }

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
        CVMetalTextureCacheCreateTextureFromImage(NULL, _cvmetalcache, pixelBuffer, NULL, MTLPixelFormatBGRA8Unorm_sRGB, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer), 0, &mtlTexture);
        if (!mtlTexture)
        {
            return;
        }

        MTLRenderPassDescriptor *rpd = [[MTLRenderPassDescriptor alloc] init];
        rpd.colorAttachments[0].texture = CVMetalTextureGetTexture(mtlTexture);
        rpd.colorAttachments[0].loadAction = MTLLoadActionClear;
        rpd.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 0);
        rpd.colorAttachments[0].storeAction = MTLStoreActionStore;
        id<MTLCommandBuffer> cBuf = [_mtlCmdQueue commandBuffer];
        CGRect viewPort = CGRectMake(0, 0, _cvpool_size.width, _cvpool_size.height);
        [_sceneRenderer renderAtTime:CACurrentMediaTime() viewport:viewPort commandBuffer:cBuf passDescriptor:rpd];
        [cBuf commit];
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
    
    if (fboStatus == GL_FRAMEBUFFER_COMPLETE && _sceneRenderer)
    {
        [_sceneRenderer renderAtTime:CACurrentMediaTime()];
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
        goto rError;
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
        goto rError;
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

    if (doSetup)
    {
    
        //[CATransaction lock];
        [CATransaction begin];
        [self.rootLayer addSublayer:self.layout.transitionLayer];
        [self.layout didBecomeVisible];
        @synchronized (self) {
            _layoutChanged = NO;
        }

    }
    
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _cvpool, &destFrame);

    @synchronized (self) {
        [CATransaction begin];
        [self renderToPixelBuffer:destFrame];
        [CATransaction commit];
    }
    CGLSetCurrentContext(NULL);
    @synchronized(self)
    {
        if (_currentPB)
        {
            CVPixelBufferRelease(_currentPB);
        }
        
        _currentPB = destFrame;
    }
    
rError:
    CGLSetCurrentContext(NULL);
    [CATransaction commit];
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
