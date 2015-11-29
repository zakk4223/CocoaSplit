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






+(NSString *)label
{
    return @"Image";
}


-(CALayer *)createNewLayer
{
    CALayer *newLayer = [CALayer layer];
    if (_singleImage)
    {
        newLayer.contents = (__bridge id)(_singleImage);
    } else if (_animation) {
        [newLayer addAnimation:_animation forKey:@"contents"];
    }
    
    newLayer.minificationFilter = kCAFilterTrilinear;
    newLayer.magnificationFilter = kCAFilterTrilinear;

    return newLayer;
}



-(NSImage *)libraryImage
{
    if (self.imagePath)
    {
        return [[NSImage alloc] initWithContentsOfFile:self.imagePath];
    }
    return nil;
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
        
        _animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        _animation.duration = totalTime;
        _animation.repeatCount = HUGE_VALF;
        _animation.removedOnCompletion = NO;
        //animation.fillMode = kCAFillModeForwards;
        _animation.values = frameArray;
        _animation.keyTimes = timesArray;
        _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _animation.calculationMode = kCAAnimationDiscrete;
        dispatch_async(dispatch_get_main_queue(), ^{

            [self updateLayersWithBlock:^(CALayer *layer) {
                [layer addAnimation:_animation forKey:@"contents"];

            }];
        });

        
        
    } else {
        _animation = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            _singleImage = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);

            [self updateLayersWithBlock:^(CALayer *layer) {
                layer.contents = (__bridge id)(_singleImage);
                [layer removeAnimationForKey:@"contents"];
            }];
                    });
    }
    
    
    
    _frameNumber = 0;
    
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
