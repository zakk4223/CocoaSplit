//
//  ImageCapture.m
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "ImageCapture.h"
#import "CSAbstractCaptureDevice.h"

@implementation ImageCapture


@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize imagePath = _imagePath;





-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.imagePath forKey:@"imagePath"];
}



-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.imagePath = [aDecoder decodeObjectForKey:@"imagePath"];
    }
    
    return self;
}



-(id)init
{
    if (self = [super init])
    {
        
        self.needsSourceSelection = NO;
        _animationQueue = dispatch_queue_create("imageCaptureQueue", NULL);
     }
    
    return self;
    
}


- (BOOL)needsAdvancedVideo
{
    return YES;
}



-(NSArray *) availableVideoDevices
{
    
    return @[];
}

-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return nil;
}


-(void) advanceGifFrame
{
    
    //wait the current duration, THEN increment the frame and rerender
    
    if (_totalFrames > 1)
    {
        
        int next_frame = _frameNumber + 1;
    
        
        if (next_frame >= _totalFrames)
        {
            next_frame = 0;
        }
    
        double frame_duration =  [[_delayList objectAtIndex:_frameNumber] floatValue];

        
        dispatch_time_t frame_time = dispatch_time(DISPATCH_TIME_NOW, frame_duration * NSEC_PER_SEC);
    
        _frameNumber = next_frame;
        __weak ImageCapture *mySelf = self;
        
        dispatch_after(frame_time, _animationQueue, ^(void){

            [mySelf renderImage:next_frame];
        
        });

    }
    
}

-(void) resetImageData
{
    _totalFrames = 0;
    _frameNumber = 0;
    
    if (_imageSource)
    {
        CFRelease(_imageSource);
        _imageSource = nil;

    }
    
    if (_imageCache)
    {
        _imageCache = nil;

    }
    _delayList = nil;
}




-(void) dealloc
{

    [self resetImageData];
}


-(void) renderImage:(int)forIdx
{
    CGImageRef theImage = NULL;

    CIImage *newImg = nil;
    
    if (_imageCache.count > forIdx)
    {
        newImg = (CIImage *)[_imageCache objectAtIndex:forIdx ];
    }
    
    if (!newImg && _imageSource)
    {
        theImage = CGImageSourceCreateImageAtIndex(_imageSource, forIdx, NULL);
        
        
        newImg = [CIImage imageWithCGImage:theImage];
        CGImageRelease(theImage);
        [_imageCache insertObject:newImg atIndex:forIdx];
        
    }
    
    _ciimage = newImg;
    
    [self advanceGifFrame];

}


-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    return;
}


-(NSString *)imagePath
{
    
    return _imagePath;
}


-(void)setImagePath:(NSString *)imagePath
{

    if(!imagePath)
    {
        return;
    }
    
    
    _imagePath = imagePath;
    
    
    [self resetImageData];
    
    
    self.captureName = [_imagePath lastPathComponent];
    
    NSData *imgData = [NSData dataWithContentsOfFile:self.imagePath];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceShouldCacheImmediately];

    CGImageSourceRef imgSrc = CGImageSourceCreateWithData((__bridge CFDataRef)imgData, (__bridge CFDictionaryRef)dict);
    
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    _imageSource = imgSrc;
    _imageCache = [[NSMutableArray alloc] init];
    
    
    
    
    _totalFrames = CGImageSourceGetCount(imgSrc);
    
    if (_totalFrames > 1)
    {
        _delayList = [[NSMutableArray alloc] init];
        
        for (int i=0; i < _totalFrames; i++)
        {
            CFDictionaryRef frameprop = CGImageSourceCopyPropertiesAtIndex(imgSrc, i, NULL);
            CFDictionaryRef gProp = CFDictionaryGetValue(frameprop, kCGImagePropertyGIFDictionary);
        
            CFNumberRef udelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFUnclampedDelayTime);
            CFNumberRef gdelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFDelayTime);
            if ([(__bridge NSNumber *)udelay isEqualToNumber:@(0)])
            {
                [_delayList insertObject:(__bridge NSNumber *)gdelay atIndex:i];
            } else {
                [_delayList insertObject:(__bridge NSNumber *)udelay atIndex:i];
            }
        }
    }
    
    
    
    _frameNumber = 0;
    [self renderImage:0];
    
}



-(CIImage *) currentImage
{
    return _ciimage;
}

-(CVImageBufferRef) getCurrentFrame
{
    @synchronized(self) {

        if (self.currentFrame)
        {
            CVPixelBufferRetain(self.currentFrame);
            
        }
    }
    
    
    return self.currentFrame;
}


-(void)chooseDirectory
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];
    
    if ([openPanel runModal] == NSOKButton)
    {
        NSArray *files = [openPanel URLs];
        NSURL *fileUrl = [files objectAtIndex:0];
        if (fileUrl)
        {
            self.imagePath = [fileUrl path];
        }
    }
}
@end
