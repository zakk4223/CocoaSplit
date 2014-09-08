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
@synthesize controller = _controller;


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

    }
    
    return self;
}


-(id)copyWithZone:(NSZone *)zone
{
    SourceLayout *newLayout = [[SourceLayout allocWithZone:zone] init];
    
    newLayout.savedSourceListData = self.savedSourceListData;
    newLayout.name = self.name;
    newLayout.controller = self.controller;
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
}



-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.savedSourceListData = [aDecoder decodeObjectForKey:@"savedSourceData"];
    }
    
    return self;
}

-(NSArray *)sourceListOrdered
{
    NSArray *listCopy = [self.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter, _sourceUUIDSorter]];
    return listCopy;
}


-(InputSource *)findSource:(NSPoint)forPoint
{
    
    NSArray *listCopy = [self.sourceList sortedArrayUsingDescriptors:@[_sourceDepthSorter.reversedSortDescriptor, _sourceUUIDSorter.reversedSortDescriptor]];
    
    for (InputSource *isrc in listCopy)
    {
        
        if (NSPointInRect(forPoint, isrc.layoutPosition))
        {
            return isrc;
        }
    }
    
    return nil;
}


-(void) saveSourceList
{
    
    self.savedSourceListData = [NSKeyedArchiver archivedDataWithRootObject:self.sourceList];
}

-(void)restoreSourceList
{
    if (self.savedSourceListData)
    {
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:self.savedSourceListData];
        
        [unarchiver setDelegate:self];
        
        self.sourceList = [unarchiver decodeObjectForKey:@"root"];
        [unarchiver finishDecoding];
        
    }
    
    if (!self.sourceList)
    {
        self.sourceList = [NSMutableArray array];
    }
    
    
    for(InputSource *src in self.sourceList)
    {
        src.layout = self;
        src.imageContext = self.ciCtx;
    }
}

-(id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object
{
    
    if ([object isKindOfClass:[CSCaptureBase class]])
    {
        return [self.sourceCache cacheSource:object uniqueID:((CSCaptureBase *)object).activeVideoDevice.uniqueID];
    } else {
        return object;
    }
}


-(void)deleteSource:(InputSource *)delSource
{
    [self.sourceList removeObject:delSource];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDeleted  object:delSource userInfo:nil];

}



-(void) addSource:(InputSource *)newSource
{
    
    newSource.depth = (int)self.sourceList.count;
    newSource.imageContext  = self.ciCtx;
    newSource.layout = self;
    [self.sourceList addObject:newSource];
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
            src.layout = self;
        }
        
    } else {
        [self saveSourceList];
        for(InputSource *src in self.sourceList)
        {
            src.editorController = nil;
        }
        
        [self.sourceList removeAllObjects];
        
        //self.sourceList = [NSMutableArray array];
    }
}

-(bool) isActive
{
    return _isActive;
}


-(NSObject *)controller
{
    return _controller;
}


-(void) setController:(NSObject *)controller
{
    _controller = controller;
    self.canvas_height = [[controller valueForKey:@"captureHeight"] intValue];
    self.canvas_width = [[controller valueForKey:@"captureWidth"] intValue];
    [controller addObserver:self forKeyPath:@"captureWidth" options:NSKeyValueObservingOptionNew context:nil];
    [controller addObserver:self forKeyPath:@"captureHeight" options:NSKeyValueObservingOptionNew context:nil];
}


-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"captureWidth"])
    {
        int new_width = [change[NSKeyValueChangeNewKey] intValue];
        self.canvas_width = new_width;
    } else if ([keyPath isEqualToString:@"captureHeight"]) {
        int new_height = [change[NSKeyValueChangeNewKey] intValue];
        self.canvas_height = new_height;
    }
}

-(CVPixelBufferRef)currentImg
{
    CVPixelBufferRef destFrame = NULL;
    CIImage *newImage;
    CGFloat frameWidth, frameHeight;
    NSArray *listCopy;
    
    @autoreleasepool {
        
        
        
        
        
        newImage = [_backgroundFilter valueForKey:kCIOutputImageKey];
        
        newImage = [newImage imageByCroppingToRect:NSMakeRect(0, 0, self.canvas_width, self.canvas_height)];
        
        
        listCopy = [self sourceListOrdered];
        
        
        for (InputSource *isource in listCopy)
        {
            if (isource.active)
            {
                newImage = [isource currentImage:newImage];
            }
            
        }
        
        if (!newImage)
        {
            NSLog(@"NO IMAGE");
            return nil;
        }
        
        
        
        frameWidth = self.canvas_width;
        frameHeight = self.canvas_height;
        
        NSSize frameSize = NSMakeSize(frameWidth, frameHeight);
        
        if (!CGSizeEqualToSize(frameSize, _cvpool_size))
        {
            [self createPixelBufferPoolForSize:frameSize];
            _cvpool_size = frameSize;
            
        }
    }
    
    CVPixelBufferPoolCreatePixelBuffer(kCVReturnSuccess, _cvpool, &destFrame);
        
    @autoreleasepool {
     
        [self.ciCtx render:newImage toIOSurface:CVPixelBufferGetIOSurface(destFrame) bounds:NSMakeRect(0,0,frameWidth, frameHeight) colorSpace:CGColorSpaceCreateDeviceRGB()];
        
    }
        @synchronized(self)
        {
            if (_currentPB)
            {
                CVPixelBufferRelease(_currentPB);
            }
            
            _currentPB = destFrame;
        }
        
        for (InputSource *isource in listCopy)
        {
            [isource frameRendered];
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


-(void)dealloc
{
    if (self.controller)
    {
        [self.controller removeObserver:self forKeyPath:@"captureWidth"];
        [self.controller removeObserver:self forKeyPath:@"captureHeight"];
    }
}



@end
