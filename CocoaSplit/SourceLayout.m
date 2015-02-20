//
//  SourceLayout.m
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SourceLayout.h"
#import "InputSource.h"


@implementation SourceLayout


@synthesize isActive = _isActive;


-(instancetype) init
{
    if (self = [super init])
    {
        _sourceDepthSorter = [[NSSortDescriptor alloc] initWithKey:@"depth" ascending:YES];
        _sourceUUIDSorter = [[NSSortDescriptor alloc] initWithKey:@"uuid" ascending:YES];
        _backgroundFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
        [_backgroundFilter setDefaults];
        [_backgroundFilter setValue:[CIColor colorWithRed:0.0f green:0.0f blue:0.0f] forKey:kCIInputColorKey];
        self.sourceCache = [[SourceCache alloc] init];
        _frameRate = 30;
        _canvas_height = 720;
        _canvas_width = 1280;
        _fboTexture = 0;
        _rFbo = 0;
        self.rootLayer = [CALayer layer];
    }
    
    return self;
}



-(id)copyWithZone:(NSZone *)zone
{
    SourceLayout *newLayout = [[SourceLayout allocWithZone:zone] init];
    
    newLayout.savedSourceListData = self.savedSourceListData;
    newLayout.name = self.name;
    newLayout.canvas_height = self.canvas_height;
    newLayout.canvas_width = self.canvas_width;
    newLayout.frameRate = self.frameRate;
    newLayout.isActive = NO;
    
    return newLayout;
}



 
-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    
    if (self.isActive)
    {
        [self saveSourceList];
    }
    
    
    [aCoder encodeObject:self.savedSourceListData forKey:@"savedSourceData"];
    [aCoder encodeInt:self.canvas_width forKey:@"canvas_width"];
    [aCoder encodeInt:self.canvas_height forKey:@"canvas_height"];
    [aCoder encodeFloat:self.frameRate forKey:@"frameRate"];
    
    
}



-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.savedSourceListData = [aDecoder decodeObjectForKey:@"savedSourceData"];
        if ([aDecoder containsValueForKey:@"canvas_height"])
        {
            self.canvas_height = [aDecoder decodeIntForKey:@"canvas_height"];
        }
        
        if ([aDecoder containsValueForKey:@"canvas_width"])
        {
            self.canvas_width = [aDecoder decodeIntForKey:@"canvas_width"];
        }
        
        if ([aDecoder containsValueForKey:@"frameRate"])
        {
            self.frameRate = [aDecoder decodeFloatForKey:@"frameRate"];
        }
        
    }
    
    return self;
}


-(NSArray *)sourceListOrdered
{
    NSArray *listCopy = [self.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}


-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra
{
    /* invert the point due to layer rendering inversion/weirdness */
    
    CGPoint newPoint = CGPointMake(forPoint.x, self.canvas_height-forPoint.y);
    CALayer *foundLayer = [self.rootLayer hitTest:newPoint];
    
    if (foundLayer)
    {
        return foundLayer.delegate;
    }
    
    
    return nil;

}
-(InputSource *)findSource:(NSPoint)forPoint
{
    
    return [self findSource:forPoint withExtra:0];
}


-(void) saveSourceList
{
    
    self.savedSourceListData = [NSKeyedArchiver archivedDataWithRootObject:self.sourceList];
}

-(void)restoreSourceList
{
    
    if (self.savedSourceListData)
    {

        self.rootLayer.sublayers = [NSArray array];
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.savedSourceListData];
        
        [unarchiver setDelegate:self];
        
        for(InputSource *src in self.sourceList)
        {
            [src willDelete];
        }
        
        self.sourceList = [unarchiver decodeObjectForKey:@"root"];
        [unarchiver finishDecoding];
        
    }
    
    if (!self.sourceList)
    {
        self.sourceList = [NSMutableArray array];
    }
    
    for(InputSource *src in self.sourceList)
    {
        src.sourceLayout = self;
        src.is_live = self.isActive;
        
        [self.rootLayer addSublayer:src.layer];
    }

}

-(void)deleteSource:(InputSource *)delSource
{
    
    [delSource willDelete];
    
    [self.sourceList removeObject:delSource];
    [delSource.layer removeFromSuperlayer];

    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];

}



-(void) addSource:(InputSource *)newSource
{
    newSource.sourceLayout = self;
    newSource.is_live = self.isActive;
    
    [self.sourceList addObject:newSource];
    [self.rootLayer addSublayer:newSource.layer];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputAdded object:newSource userInfo:nil];
}



-(void) setIsActive:(bool)isActive
{
    bool oldActive = _isActive;
    
    _isActive = isActive;
    
    if (oldActive == isActive)
    {
        //If the value didn't change don't do anything
        return;
    }
    
    
    if (isActive)
    {
        [self restoreSourceList];
        for(InputSource *src in self.sourceList)
        {
            src.sourceLayout = self;
            
        }
        
    } else {
        [self saveSourceList];
        for(InputSource *src in self.sourceList)
        {
            src.editorController = nil;
            
        }
        
        self.rootLayer.sublayers = [NSArray array];
        [self.sourceList removeAllObjects];
        
        //self.sourceList = [NSMutableArray array];
    }
}

-(bool) isActive
{
    return _isActive;
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

-(void)setupCArenderer
{
    if (!self.cglCtx)
    {
        [self createCGLContext];
    }
    
    
    CGLSetCurrentContext(self.cglCtx);
    
    if (!self.renderer)
    {
        self.renderer = [CARenderer rendererWithCGLContext:self.cglCtx options:nil];
    }

    
    [CATransaction begin];
    if (!self.rootLayer)
    {
        self.rootLayer = [CALayer layer];
    }
    CALayer *newRoot = self.rootLayer;
    newRoot.bounds = CGRectMake(0, 0, self.canvas_width, self.canvas_height);
    newRoot.backgroundColor = CGColorCreateGenericRGB(0, 0, 0, 1);
    newRoot.position = CGPointMake(0.0, 0.0);
    newRoot.anchorPoint = CGPointMake(0.0, 0.0);
    newRoot.masksToBounds = YES;
    //newRoot.geometryFlipped = YES;
    newRoot.sublayerTransform = CATransform3DIdentity;
    newRoot.sublayerTransform = CATransform3DTranslate(newRoot.sublayerTransform, 0, self.canvas_height, 0);
    newRoot.sublayerTransform = CATransform3DScale(newRoot.sublayerTransform, 1.0, -1.0, 1.0);
    self.renderer.bounds = NSMakeRect(0.0, 0.0, self.canvas_width, self.canvas_height);
    self.renderer.layer = newRoot;
    [CATransaction commit];
    
    glViewport(0, 0, self.canvas_width, self.canvas_height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(0, self.canvas_width, 0,self.canvas_height, -1, 1);
    
    
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    
    glClearColor(0, 0, 0, 0);

    
}


-(void)renderToSurface:(IOSurfaceRef)ioSurface
{
    CGLSetCurrentContext(self.cglCtx);

    if (!_rFbo)
    {
        glGenFramebuffers(1, &_rFbo);
        NSLog(@"GENERATED FBO %d", _rFbo);

    }
    
    if (!_fboTexture)
    {
        glGenTextures(1, &_fboTexture);
        NSLog(@"GENERATED TEXTURE %d", _fboTexture);

    }
    

    glEnable(GL_TEXTURE_RECTANGLE_ARB);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_RECTANGLE_ARB, _fboTexture);
    
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    //glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glDisable(GL_DEPTH_TEST);
    glDepthMask(GL_FALSE);
    
    
    CGLTexImageIOSurface2D(self.cglCtx, GL_TEXTURE_RECTANGLE_ARB, GL_RGBA, self.canvas_width, self.canvas_height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, ioSurface, 0);

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
    NSArray *listCopy;
    
    
    listCopy = [self sourceListOrdered];
    
    
    for (InputSource *isource in listCopy)
    {
        if (isource.active)
        {
            [isource frameTick];
        }
        
    }
    
    frameWidth = self.canvas_width;
    frameHeight = self.canvas_height;
    
    NSSize frameSize = NSMakeSize(frameWidth, frameHeight);
    
    if (CGSizeEqualToSize(frameSize, CGSizeZero))
    {
        return nil;
    }
    
    if (!CGSizeEqualToSize(frameSize, _cvpool_size))
    {
        [self createPixelBufferPoolForSize:frameSize];
        _cvpool_size = frameSize;
        [self setupCArenderer];
        
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
    
    
    if (!self.isActive)
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


-(InputSource *)inputForUUID:(NSString *)uuid
{

    NSArray *sources = [self sourceListOrdered];
    
    NSUInteger idx = [sources indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((InputSource *)obj).uuid isEqualToString:uuid];
        
        
    }];
    
    
    if (idx != NSNotFound)
    {
        return [sources objectAtIndex:idx];
    }
    return nil;
}



@end
