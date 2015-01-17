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
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
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

+(NSString *)label
{
    return @"Image";
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
    
    self.activeVideoDevice.uniqueID = imagePath;
    
    self.captureName = [_imagePath lastPathComponent];
    
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceShouldCacheImmediately];

    NSURL *fileURL = [NSURL fileURLWithPath:imagePath];
    
    CGImageSourceRef imgSrc = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, (__bridge CFDictionaryRef)dict);
    
    
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    _imageSource = imgSrc;
    _imageCache = [[NSMutableArray alloc] init];
    
    
    
    
    _totalFrames = CGImageSourceGetCount(imgSrc);
    float totalTime = 0;
    
    if (_totalFrames > 1)
    {
        NSMutableArray *frameArray = [NSMutableArray array];
        
        _delayList = [[NSMutableArray alloc] init];
        
        for (int i=0; i < _totalFrames; i++)
        {
            CFDictionaryRef frameprop = CGImageSourceCopyPropertiesAtIndex(imgSrc, i, NULL);
            CFDictionaryRef gProp = CFDictionaryGetValue(frameprop, kCGImagePropertyGIFDictionary);
        
            NSNumber *udelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFUnclampedDelayTime);
            NSNumber *gdelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFDelayTime);
            if ([udelay isEqualToNumber:@(0)])
            {
                [_delayList insertObject:gdelay atIndex:i];
                totalTime += gdelay.floatValue;
            } else {
                [_delayList insertObject:udelay atIndex:i];
                totalTime += udelay.floatValue;
            }
            CGImageRef frame = CGImageSourceCreateImageAtIndex(_imageSource, i, NULL);
            [frameArray addObject:(__bridge id)frame];
            
        }
        
        NSMutableArray *timesArray = [NSMutableArray array];
        float base = 0;
        for (NSNumber *duration in _delayList)
        {
            base = base + (duration.floatValue/totalTime);
            [timesArray addObject:[NSNumber numberWithFloat:base]];
        }
        
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        animation.duration = totalTime;
        animation.repeatCount = HUGE_VALF;
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.values = frameArray;
        animation.keyTimes = timesArray;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        animation.calculationMode = kCAAnimationDiscrete;
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.outputLayer addAnimation:animation forKey:@"contents"];
        });

        
        
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.outputLayer.contents = (__bridge id)CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        });
    }
    
    
    
    _frameNumber = 0;
    [self renderImage:0];
    
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
