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





-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    
    [aCoder encodeObject:self.imagePath forKey:@"imagePath"];
    if (_imageData)
    {
        [aCoder encodeObject:_imageData forKey:@"imageData"];
    }
}



-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    
    if ([aDecoder containsValueForKey:@"imageData"])
    {
        _imageData = [aDecoder decodeObjectForKey:@"imageData"];
        _wasLoadedFromData = YES;
    }
    self.imagePath = [aDecoder decodeObjectForKey:@"imagePath"];
}



-(id)init
{
    if (self = [super init])
    {
        _wasLoadedFromData = NO;
        self.needsSourceSelection = NO;
        self.activeVideoDevice = [[CSAbstractCaptureDevice alloc] init];
        _animation = nil;
        self.allowDedup = YES;
        
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


+(NSString *)uniqueIDFromPasteboardItem:(NSPasteboardItem *)item
{
    NSString *pPath = [item stringForType:@"public.file-url"];
    if (!pPath)
    {
        return nil;
    }
    NSURL *fileURL = [NSURL URLWithString:pPath];
    return [fileURL path];
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



-(void)displayLayer:(ImageCaptureLayer *)layer
{
    int gifIndex = layer.presentationLayer.gifIndex;
    if (_imageSource)
    {
        CGImageRef newImg = CGImageSourceCreateImageAtIndex(_imageSource, gifIndex, NULL);
        
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            layer.contents = (__bridge id _Nullable)(newImg);
        } withPreuseBlock:^{
            CGImageRetain(newImg);
        } withPostuseBlock:^{
            CGImageRelease(newImg);
        }];
        CGImageRelease(newImg);
    }
}


-(CALayer *)createNewLayer
{
    ImageCaptureLayer *newLayer = [ImageCaptureLayer layer];
    
    if (_singleImage)
    {
        newLayer.contents = (__bridge id _Nullable)(_singleImage);
    } else if (_animation) {
        [newLayer addAnimation:_animation forKey:@"gifIndex"];
        newLayer.delegate = self;
    }
    
    newLayer.minificationFilter = kCAFilterTrilinear;
    newLayer.magnificationFilter = kCAFilterTrilinear;

    return newLayer;
}



-(NSImage *)libraryImage
{
    
    
    if (_singleImage)
    {
        return [[NSImage alloc] initWithCGImage:_singleImage size:NSZeroSize];
    } else if (_imageSource) {
        CGImageRef fImg = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        if (fImg)
        {
            
            NSImage *ret = [[NSImage alloc] initWithCGImage:fImg size:NSZeroSize];
            CGImageRelease(fImg);
            return ret;
        } else {
            return nil;
        }
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
    
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    
    if (_imageData)
    {
        _imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)_imageData, (__bridge CFDictionaryRef)dict);
    } else {
        _imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, (__bridge CFDictionaryRef)dict);
    }
    
    if (!_imageSource)
    {
        return;
    }
    CFDictionaryRef firstframeprop = CGImageSourceCopyPropertiesAtIndex(_imageSource, 0, NULL);
    CFDictionaryRef gifTest = CFDictionaryGetValue(firstframeprop, kCGImagePropertyGIFDictionary);
    
    bool isGif;
    
    if (gifTest)
    {
        isGif = YES;
    } else {
        isGif = NO;
    }
    
    
    _totalFrames = CGImageSourceGetCount(_imageSource);
    CFRelease(firstframeprop);
    float totalTime = 0;
    
    ;
    if (_totalFrames > 1 && isGif)
    {
        NSMutableArray *frameArray = [NSMutableArray array];
        
        NSMutableArray *delayList = [[NSMutableArray alloc] init];
        
        for (int i=0; i < _totalFrames; i++)
        {
            CFDictionaryRef frameprop = CGImageSourceCopyPropertiesAtIndex(_imageSource, i, NULL);
            CFDictionaryRef gProp = CFDictionaryGetValue(frameprop, kCGImagePropertyGIFDictionary);
            
            if (!gProp)
            {
                CFRelease(frameprop);
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
            if (i==0)
            {
                NSNumber *iWidth = CFDictionaryGetValue(frameprop, kCGImagePropertyPixelWidth);
                NSNumber *iHeight = CFDictionaryGetValue(frameprop, kCGImagePropertyPixelHeight);
                _imageSize = NSMakeSize([iWidth floatValue], [iHeight floatValue]);
                
            }
            [frameArray addObject:[NSNumber numberWithInt:i]];
            CFRelease(frameprop);
        }
        
        NSMutableArray *timesArray = [NSMutableArray array];
        float base = 0;
        
        for (NSNumber *duration in delayList)
        {
            base = base + (duration.floatValue/totalTime);
            [timesArray addObject:[NSNumber numberWithFloat:base]];
        }
        
        
        _animation = [CAKeyframeAnimation animationWithKeyPath:@"gifIndex"];
        _animation.duration = totalTime;
        _animation.repeatCount = HUGE_VALF;
        _animation.removedOnCompletion = NO;
        _animation.keyTimes = timesArray;
        _animation.values = frameArray;
        _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _animation.calculationMode = kCAAnimationDiscrete;
        _imageDuration = totalTime;
        _singleImage = nil;
        
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            [layer addAnimation:self->_animation forKey:@"gifIndex"];
        }];
        
        
        
    } else {
        _animation = nil;
        CGImageRef sImg = CGImageSourceCreateImageAtIndex(_imageSource, 0, NULL);
        size_t iWidth = CGImageGetWidth(sImg);
        size_t iHeight = CGImageGetHeight(sImg);
        
        _imageSize = NSMakeSize(iWidth, iHeight);
        if (_singleImage)
        {
            CGImageRelease(_singleImage);
        }
        _singleImage = sImg;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                layer.contents = (__bridge id _Nullable)(self->_singleImage);
                [layer removeAnimationForKey:@"gifIndex"];
            }];
        });
    }
    
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

-(void)dealloc
{
    if (_imageSource)
    {
        CFRelease(_imageSource);
    }
    
    if (_singleImage)
    {
        CFRelease(_singleImage);
    }

}
@end
