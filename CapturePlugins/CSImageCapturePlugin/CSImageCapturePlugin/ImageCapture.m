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
    if (_imageData)
    {
        [aCoder encodeObject:_imageData forKey:@"imageData"];
    }
}



-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        if ([aDecoder containsValueForKey:@"imageData"])
        {
            _imageData = [aDecoder decodeObjectForKey:@"imageData"];
            _wasLoadedFromData = YES;
        }
        self.imagePath = [aDecoder decodeObjectForKey:@"imagePath"];
    }
    
    return self;
}



-(id)init
{
    if (self = [super init])
    {
        _wasLoadedFromData = NO;
        self.needsSourceSelection = NO;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
     }
    
    return self;
    
}

-(void)willExport
{
    if (self.imagePath && !_wasLoadedFromData)
    {
        NSURL *fileURL = [NSURL fileURLWithPath:self.imagePath];
        _imageData = [NSData dataWithContentsOfURL:fileURL];
    }
}

-(void)didExport
{
    if (!_wasLoadedFromData)
    {
        _imageData = nil;
    }
}


- (BOOL)needsAdvancedVideo
{
    return YES;
}



-(NSArray *) availableVideoDevices
{
    
    return @[];
}





+(NSSet *)mediaUTIs
{
    return [NSSet setWithArray:NSImage.imageTypes];
}


+(NSObject<CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    
    ImageCapture *ret = nil;
    
    NSString *imagePath = [item stringForType:@"public.file-url"];
    if (imagePath)
    {
        NSURL *fileURL = [NSURL URLWithString:imagePath];
        NSString *realPath = [fileURL path];
        ret = [[ImageCapture alloc] init];
        ret.imagePath = realPath;
    }
    return ret;
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
        newLayer.contents = _singleImage;
    } else if (_animation) {
        [newLayer addAnimation:_animation forKey:@"contents"];
    }
    
    newLayer.minificationFilter = kCAFilterTrilinear;
    newLayer.magnificationFilter = kCAFilterTrilinear;

    return newLayer;
}



-(NSImage *)libraryImage
{
    
    
    if (_singleImage)
    {
        return _singleImage;
    } else if (_animation) {
        return _animation.values.firstObject;
    } else {
        return [NSImage imageNamed:@"NSMediaBrowserMediaTypePhotos"];
    }
    return nil;
}


-(NSString *)imagePath
{
    
    return _imagePath;
}


-(float)duration
{
    if (_animation)
    {
        return _animation.duration;
    } else {
        return 0.0f;
    }
}


-(NSSize)captureSize
{
    return _imageSize;
}


-(void)setImagePath:(NSString *)imagePath
{

    if(!imagePath)
    {
        return;
    }
    
    

    _imageSize = NSZeroSize;
    
    _imagePath = imagePath;
    
    
    self.activeVideoDevice.uniqueID = imagePath;
    
    self.captureName = [_imagePath lastPathComponent];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:(id)kCGImageSourceShouldCacheImmediately];

    NSURL *fileURL = [NSURL fileURLWithPath:imagePath];
    
    CGImageSourceRef imgSrc;
    
    if (_imageData)
    {
        imgSrc = CGImageSourceCreateWithData((__bridge CFDataRef)_imageData, (__bridge CFDictionaryRef)dict);
    } else {
       imgSrc = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, (__bridge CFDictionaryRef)dict);
    }
    /*
    if (!_imageData)
    {
        _imageData = [NSData dataWithContentsOfURL:fileURL];
    }
    */
    
    /*
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    
    _imageSource = imgSrc;
     */
    
    
    
    
    CFDictionaryRef firstframeprop = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
    CFDictionaryRef gifTest = CFDictionaryGetValue(firstframeprop, kCGImagePropertyGIFDictionary);

    bool isGif;
    
    if (gifTest)
    {
        isGif = YES;
    } else {
        isGif = NO;
    }

    
    _totalFrames = CGImageSourceGetCount(imgSrc);
    CFRelease(firstframeprop);
    float totalTime = 0;
    
    if (_totalFrames > 1 && isGif)
    {
        NSMutableArray *frameArray = [NSMutableArray array];
        
        NSMutableArray *delayList = [[NSMutableArray alloc] init];
        
        for (int i=0; i < _totalFrames; i++)
        {
            CFDictionaryRef frameprop = CGImageSourceCopyPropertiesAtIndex(imgSrc, i, NULL);
            CFDictionaryRef gProp = CFDictionaryGetValue(frameprop, kCGImagePropertyGIFDictionary);
        
            if (!gProp)
            {
                continue;
            }
            NSNumber *udelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFUnclampedDelayTime);
            NSNumber *gdelay = CFDictionaryGetValue(gProp, kCGImagePropertyGIFDelayTime);
            if ([udelay isEqualToNumber:@(0)])
            {
                [delayList insertObject:gdelay atIndex:i];
                totalTime += gdelay.floatValue;
            } else {
                [delayList insertObject:udelay atIndex:i];
                totalTime += udelay.floatValue;
            }
            CGImageRef frame = CGImageSourceCreateImageAtIndex(imgSrc, i, NULL);
            NSImage *tmpImg = [[NSImage alloc] initWithCGImage:frame size:NSZeroSize];
            if (i==0)
            {
                _imageSize = tmpImg.size;
            }
            
            [frameArray addObject:tmpImg];
            CFRelease(frame);
            
            //[frameArray addObject:(__bridge id)frame];
            
        }
        
        NSMutableArray *timesArray = [NSMutableArray array];
        float base = 0;
        
        for (NSNumber *duration in delayList)
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
        _imageDuration = totalTime;
        _singleImage = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{

            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                [layer addAnimation:_animation forKey:@"contents"];

            }];
        });

        
        
    } else {
        _animation = nil;
        CGImageRef sImg = CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL);
        
        _singleImage = [[NSImage alloc] initWithCGImage:sImg size:NSZeroSize];

        CGImageRelease(sImg);

        _imageSize = _singleImage.size;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                layer.contents = _singleImage;
                [layer removeAnimationForKey:@"contents"];
            }];
                    });
    }
    
    
    if (imgSrc)
    {
        CFRelease(imgSrc);
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
