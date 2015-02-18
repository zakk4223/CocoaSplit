//
//  CSIOSurfaceLayer.m
//  CocoaSplit
//
//  Created by Zakk on 1/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSIOSurfaceLayer.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/glu.h>

@interface CIImageWrapper : NSObject
{
    IOSurfaceRef _csIOSurfacePriv;
    CVImageBufferRef _csPixelBufferPriv;
}

@property (strong) CIImage *ciImage;

@end

@implementation CIImageWrapper



-(instancetype)init
{
    self = [super init];
    return self;
}


-(instancetype)initWithCVImageBuffer:(CVImageBufferRef)imageBuffer
{
    
    /*
     This method in CIImage fails for non RGB image buffers, even if they are IOSurface backed with surfaces that work fine with initWithIOSurface.
     So let's just retain the image buffer, use initWithIOSurface ourselves. Release the image buffer in dealloc.
     */
    
    if (self = [super init])
    {
        IOSurfaceRef imageSurface = CVPixelBufferGetIOSurface(imageBuffer);
        if (imageSurface)
        {
            CVPixelBufferRetain(imageBuffer);
            _csPixelBufferPriv = imageBuffer;
            _ciImage = [CIImage imageWithIOSurface:imageSurface];
        } else {
            _csPixelBufferPriv = NULL;
            _ciImage = nil;
        }
    }
    
    return self;
}

-(instancetype)initWithCIImage:(CIImage *)img
{
    if (self = [super init])
    {
        _ciImage = img;
    }
    
    return self;
}


-(instancetype)initWithIOSurface:(IOSurfaceRef)surface
{
    //CIImage retains the iosurface, we're just here to mess with the use count.
    if (self = [super init])
    {
        IOSurfaceIncrementUseCount(surface);
        _csIOSurfacePriv = surface;
        _ciImage = [CIImage imageWithIOSurface:surface];
    }
    return self;
}

-(void)dealloc
{
    if (_csIOSurfacePriv)
    {
        IOSurfaceDecrementUseCount(_csIOSurfacePriv);
    }
    
    if (_csPixelBufferPriv)
    {
        CVPixelBufferRelease(_csPixelBufferPriv);
    }
}

@end


@interface CSIOSurfaceLayer()
{
    CIFilter *_resizeFilter;
    CIFilter *_matrixFilter;
    
}
@property (strong) CIImageWrapper *imageWrapper;
@end


@implementation CSIOSurfaceLayer

@synthesize ioSurface = _ioSurface;
@synthesize ioImage = _ioImage;
@synthesize imageBuffer = _imageBuffer;

-(instancetype)init
{
    if (self = [super init])
    {
        self.asynchronous = YES;
        self.needsDisplayOnBoundsChange = YES;
        self.flipImage = NO;
        _lastSurfaceSize = NSMakeRect(0, 0, 0, 0);
        _privateCropRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        _resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [_resizeFilter setDefaults];
        self.imageWrapper = nil;
        
    }
    
    return self;
}

-(void)setImageBuffer:(CVImageBufferRef)imageBuffer
{
    @synchronized(self)
    {
        self.imageWrapper = [[CIImageWrapper alloc] initWithCVImageBuffer:imageBuffer];
    }
 
    //imageWrapper retains imageBuffer
    _imageBuffer = imageBuffer;
}

-(CVImageBufferRef)imageBuffer
{
    return _imageBuffer;
}

-(void)setIoImage:(CIImage *)ioImage
{
    @synchronized(self)
    {
        self.imageWrapper = [[CIImageWrapper alloc] initWithCIImage:ioImage];
    }
    _ioImage = ioImage;
}


-(CIImage *)ioImage
{
    return _ioImage;
}




-(void)calculateCrop:(NSRect)extent;
{
    CGRect newCrop;
    
    newCrop.origin.x = extent.size.width * _privateCropRect.origin.x;
    newCrop.origin.y = extent.size.height * _privateCropRect.origin.y;
    newCrop.size.width = extent.size.width * _privateCropRect.size.width;
    newCrop.size.height = extent.size.height * _privateCropRect.size.height;
    _lastSurfaceSize = extent;
    _calculatedCrop = newCrop;
}


//We handle this by cropping the source image, and never pass it on to the parent
-(void)setContentsRect:(CGRect)contentsRect
{
    _privateCropRect = contentsRect;
    if (self.imageWrapper && self.imageWrapper.ciImage)
    {
        [self calculateCrop:self.imageWrapper.ciImage.extent];
    }
}

-(CGRect)contentsRect
{
    return _privateCropRect;
}



-(void)setIoSurface:(IOSurfaceRef)ioSurface
{

    
    //IOSurfaceIncrementUseCount(ioSurface);
    @synchronized(self)
    {
        self.imageWrapper = [[CIImageWrapper alloc] initWithIOSurface:ioSurface];
    }
    

    /*
    if (_ioSurface)
    {
        IOSurfaceDecrementUseCount(_ioSurface);
    }
     */
    _ioSurface = ioSurface;

    
}


-(IOSurfaceRef)ioSurface
{
    return _ioSurface;
}


-(void) drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts
{
    CIImageWrapper *wrappedImage = self.imageWrapper;
    
    CGLSetCurrentContext(ctx);
    glClearColor(0,0,0,0);
    glClear(GL_COLOR_BUFFER_BIT);

    
    if (!wrappedImage)
    {
        return;
    }
    
    CIImage *useImage;
    @synchronized(self)
    {


        useImage = wrappedImage.ciImage;
        //IOSurfaceIncrementUseCount(cImg);
        

    }
    
    if (!_ciCtx || !useImage)
    {
        return;
    }

    
    CGRect useBounds = self.bounds;

    CIImage *croppedImage;
    
    
    if (!NSEqualRects(useImage.extent, _lastSurfaceSize))
    {
        [self calculateCrop:useImage.extent];
    }

    
    croppedImage = [useImage imageByCroppingToRect:_calculatedCrop];

    
    
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    if (self.flipImage)
    {
        glOrtho(0, useBounds.size.width,useBounds.size.height,0,  -1, 1);
    } else {
        glOrtho(0, useBounds.size.width,0, useBounds.size.height,  -1, 1);
    }
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    //I'm cheating here. Technically I should probably care about all the values of contentsGravity, but I know I don't want
    //the modes that don't involve resizing of some type. I don't want the layer to leak outside of the bounds of the superlayer
    //so all I'm doing here is Resize and ResizeAspect.
    
    //This covers kCAGravityResize
    NSRect inRect = useBounds;
    
    
    if ([self.contentsGravity isEqualToString:kCAGravityResizeAspect])
    {
        
        float wr = useBounds.size.width / croppedImage.extent.size.width;
        float hr = useBounds.size.height / croppedImage.extent.size.height;
        
        float ratio = (hr < wr ? hr : wr);
        
        NSSize scaledSize = NSMakeSize(croppedImage.extent.size.width * ratio, croppedImage.extent.size.height * ratio);
        
        CGFloat originX = useBounds.size.width/2 - scaledSize.width/2;
        CGFloat originY = useBounds.size.height/2 - scaledSize.height/2;
        
        inRect = NSMakeRect(originX, originY, scaledSize.width, scaledSize.height);
        //[_resizeFilter setValue:croppedImage forKey:kCIInputImageKey];
        //[_resizeFilter setValue:@(ratio) forKey:kCIInputScaleKey];
        //croppedImage = [_resizeFilter valueForKey:kCIOutputImageKey];
    }
    
    
    
    [_ciCtx drawImage:croppedImage inRect:inRect fromRect:croppedImage.extent];


    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
    //IOSurfaceDecrementUseCount(cImg);
    

    
}




-(CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf
{
    CGLContextObj contextObj = [super copyCGLContextForPixelFormat:pf];
    
    _ciCtx = [CIContext contextWithCGLContext:contextObj pixelFormat:pf colorSpace:nil options:@{kCIContextWorkingColorSpace: [NSNull null]}];
    return contextObj;
}


@end
