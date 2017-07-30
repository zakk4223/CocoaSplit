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
    } else {
        return [NSImage imageNamed:@"NSMediaBrowserMediaTypePhotos"];
    }
    return nil;
}


-(NSString *)imagePath
{
    
    return _imagePath;
}


-(NSSize)captureSize
{
    if (_imageSource)
    {
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
        NSNumber *width = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
        NSNumber *height = (NSNumber *)CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
        return NSMakeSize(width.floatValue, height.floatValue);
    }
    return NSZeroSize;
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
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    _imageSource = imgSrc;
    _imageCache = [[NSMutableArray alloc] init];
    
    
    
    
    CFDictionaryRef firstframeprop = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);
    CFDictionaryRef gifTest = CFDictionaryGetValue(firstframeprop, kCGImagePropertyGIFDictionary);

    _totalFrames = CGImageSourceGetCount(imgSrc);
    float totalTime = 0;
    
    if (_totalFrames > 1 && gifTest)
    {
        NSMutableArray *frameArray = [NSMutableArray array];
        
        _delayList = [[NSMutableArray alloc] init];
        
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

            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                [layer addAnimation:_animation forKey:@"contents"];

            }];
        });

        
        
    } else {
        _animation = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            _singleImage = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);

            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
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
