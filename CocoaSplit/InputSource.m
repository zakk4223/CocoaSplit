//
//  InputSource.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputSource.h"
#import "CaptureSessionProtocol.h"


static NSArray *_sourceTypes = nil;




@implementation InputSource



@synthesize selectedVideoType = _selectedVideoType;
@synthesize name = _name;
@synthesize imageContext = _imageContext;
@synthesize scaleFactor = _scaleFactor;
@synthesize transitionFilterName = _transitionFilterName;


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeFloat:self.x_pos forKey:@"x_pos"];
    [aCoder encodeFloat:self.y_pos forKey:@"y_pos"];
    [aCoder encodeInt64:self.display_width forKey:@"display_width"];
    [aCoder encodeInt64:self.display_height forKey:@"display_height"];
    [aCoder encodeDouble:self.rotationAngle forKey:@"rotationAngle"];
    [aCoder encodeFloat:self.scaleFactor forKey:@"scaleFactor"];
    [aCoder encodeFloat:self.opacity forKey:@"opacity"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInt:self.depth forKey:@"depth"];
    [aCoder encodeInt:self.crop_top forKey:@"crop_top"];
    [aCoder encodeInt:self.crop_bottom forKey:@"crop_bottom"];
    [aCoder encodeInt:self.crop_left forKey:@"crop_left"];
    [aCoder encodeInt:self.crop_right forKey:@"crop_right"];
    [aCoder encodeObject:self.selectedVideoType forKey:@"selectedVideoType"];

    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    
    [aCoder encodeInt:self.rotateStyle forKey:@"rotateStyle"];
    if (self.transitionFilter)
    {
        [aCoder encodeObject:self.transitionFilter forKey:@"transitionFilter"];
    }
    
    
    
    
    if (self.videoInput)
    {
        [aCoder encodeObject:self.videoInput forKey:@"videoInput"];
    }
    
    [aCoder encodeBool:self.doChromaKey forKey:@"doChromaKey"];
    [aCoder encodeObject:self.chromaKeyColor forKey:@"chromaKeyColor"];
    [aCoder encodeFloat:self.chromaKeyThreshold forKey:@"chromaKeyThreshold"];
    [aCoder encodeFloat:self.chromaKeySmoothing forKey:@"chromaKeySmoothing"];

    
    
    [aCoder encodeObject:self.videoSources forKey:@"videoSources"];
    [aCoder encodeObject:self.currentEffects forKey:@"currentEffects"];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self commonInit];
        self.x_pos = [aDecoder decodeFloatForKey:@"x_pos"];
        self.y_pos = [aDecoder decodeFloatForKey:@"y_pos"];
        self.display_width = [aDecoder decodeInt64ForKey:@"display_width"];
        self.display_height = [aDecoder decodeInt64ForKey:@"display_height"];
        
        self.rotationAngle = [aDecoder decodeDoubleForKey:@"rotationAngle"];
        //self.scaleFactor = [aDecoder decodeFloatForKey:@"scaleFactor"];
        self.opacity = [aDecoder decodeFloatForKey:@"opacity"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.depth = [aDecoder decodeIntForKey:@"depth"];
        self.videoInput = [aDecoder decodeObjectForKey:@"videoInput"];
        _selectedVideoType = [aDecoder decodeObjectForKey:@"selectedVideoType"];
        self.crop_top = [aDecoder decodeIntForKey:@"crop_top"];
        self.crop_bottom = [aDecoder decodeIntForKey:@"crop_bottom"];
        self.crop_left = [aDecoder decodeIntForKey:@"crop_left"];
        self.crop_right = [aDecoder decodeIntForKey:@"crop_right"];

        
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        
        self.videoSources = [aDecoder decodeObjectForKey:@"videoSources"];
        if (!self.videoSources)
        {
            self.videoSources = [[NSMutableArray alloc] init];
        }
        
        self.transitionFilter = [aDecoder decodeObjectForKey:@"transitionFilter"];
        
        if (self.transitionFilter)
        {
            self.transitionFilterName = self.transitionFilter.attributes[@"CIAttributeFilterName"];
        }
        
        
        self.rotateStyle = [aDecoder decodeIntForKey:@"rotateStyle"];
        
        self.currentEffects = [aDecoder decodeObjectForKey:@"currentEffects"];
        if (!self.currentEffects)
        {
            self.currentEffects = [[NSMutableArray alloc] init];
        }
        
        if ([aDecoder containsValueForKey:@"doChromaKey"])
        {
            self.doChromaKey = [aDecoder decodeBoolForKey:@"doChromaKey"];
        }
        
        if ([aDecoder containsValueForKey:@"chromaKeyColor"])
        {

            self.chromaKeyColor = [aDecoder decodeObjectForKey:@"chromaKeyColor"];
        }
        
        if ([aDecoder containsValueForKey:@"chromaKeyThreshold"])
        {

            self.chromaKeyThreshold = [aDecoder decodeFloatForKey:@"chromaKeyThreshold"];
        }
        
        if ([aDecoder containsValueForKey:@"chromaKeySmoothing"])
        {
            
            self.chromaKeySmoothing = [aDecoder decodeFloatForKey:@"chromaKeySmoothing"];
        }

        
        [self rebuildUserFilter];
    }
    
    
    return self;
}



-(id)init
{
    if (self = [super init])
    {
        [self commonInit];
    }
    return self;
}


-(void)commonInit
{
    _internalScaleFactor = 1.0f;
    _nextImageTime = 0.0f;
    _currentSourceIdx = 0;
    self.changeInterval = 20.0f;
    
    
    self.scaleFactor = 1.0f;
    _x_pos = 200.0f;
    _y_pos = 200.0f;
    
    self.lockSize = YES;
    
    self.rotationAngle =  0.0f;
    self.depth = 0;
    self.opacity = 1.0f;
    self.crop_bottom = 0;
    self.crop_top = 0;
    self.crop_left = 0;
    self.crop_right = 0;
    self.display_width = 200;
    self.display_height = 200;
    self.videoSources = [[NSMutableArray alloc] init];
    
    self.transitionFilterName = @"CISwipeTransition";
    self.currentEffects = [[NSMutableArray alloc] init];
    
    
    
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
    self.compositeFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
    [self.compositeFilter setDefaults];
    
    self.layoutPosition = NSMakeRect(self.x_pos, self.y_pos, self.display_width, self.display_height);
    self.active = YES;
    self.transitionNames = [CIFilter filterNamesInCategory:kCICategoryTransition];
    self.availableEffectNames = [CIFilter filterNamesInCategories:nil];
    self.doChromaKey = NO;
    self.chromaKeyThreshold = 0.1005f;
    self.chromaKeySmoothing = 0.1344f;
    
    self.chromaKeyColor = [NSColor greenColor];
    
    
    [self addObserver:self forKeyPath:@"editorPopover" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self rebuildFilters];
    [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
 }


-(void)rebuildUserFilter
{
    _filterGenerator = [[CIFilterGenerator alloc] init];
    
    CIFilter *lastFilter = nil;
    CIFilter *firstFilter = nil;
    if (self.currentEffects.count == 0)
    {
        self.userFilter = nil;
        return;
    }
    
    
    if (self.currentEffects.count == 1)
    {
        self.userFilter = self.currentEffects.firstObject;
    } else {
        for (CIFilter *cur in self.currentEffects)
        {
            if (!lastFilter)
            {
                lastFilter = cur;
                firstFilter = cur;
                continue;
            }
            
            [_filterGenerator connectObject:lastFilter withKey:kCIOutputImageKey toObject:cur withKey:kCIInputImageKey];
            for (NSString *inputName in lastFilter.inputKeys)
            {
                if ([inputName isEqualToString:kCIInputImageKey])
                {
                    continue;
                }
                NSString *keyPrefix = lastFilter.className;
                
                [_filterGenerator exportKey:inputName fromObject:lastFilter withName:[NSString stringWithFormat:@"%@:%@", keyPrefix, inputName]];
            }
            
            
            lastFilter = cur;
        }
        
        
        [_filterGenerator exportKey:kCIInputImageKey fromObject:firstFilter withName:kCIInputImageKey];
        [_filterGenerator exportKey:kCIOutputImageKey fromObject:lastFilter withName:nil];
        for (NSString *inputName in lastFilter.inputKeys)
        {
            if ([inputName isEqualToString:kCIInputImageKey])
            {
                continue;
            }

            NSString *keyPrefix = lastFilter.className;

            [_filterGenerator exportKey:inputName fromObject:lastFilter withName:[NSString stringWithFormat:@"%@:%@", keyPrefix, inputName]];
        }

        
        
        CIFilter *newFilter = [_filterGenerator filter];
        self.userFilter = newFilter;
    }
}




-(void)removeUserEffects:(NSIndexSet *)filterIndexes
{
    
    [self.currentEffects removeObjectsAtIndexes:filterIndexes];
    [self rebuildUserFilter];
    
}



-(void)addUserEffect:(NSIndexSet *)filterIndexes
{
    
    
    [filterIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
    
        NSString *filterName = [self.availableEffectNames objectAtIndex:idx];
        
        CIFilter *newFilter = [CIFilter filterWithName:filterName];
        
        if (newFilter)
        {
            [newFilter setDefaults];
            [self.currentEffects addObject:newFilter];
        }
    }];
    
    [self rebuildUserFilter];

}




-(NSArray *)sourceTypes
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sourceTypes  =  @[@"Desktop", @"AVFoundation", @"QTCapture", @"Syphon", @"Image", @"Text", @"Window", @"Movie"];
    });

    return _sourceTypes;
}


-(void)setImageContext:(CIContext *)imageContext
{
    _imageContext = imageContext;
    if (self.videoInput)
    {
        self.videoInput.imageContext = imageContext;
    }
}

-(CIContext *)imageContext
{
    return _imageContext;
}


-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
    [self removeObserver:self forKeyPath:@"editorPopover"];
    
}

-(void)setSettingsTab:(NSString *)settingsTab
{
    return;
}


-(NSString *)settingsTab
{
    if (self.videoInput)
    {
        return @"Settings";
    }
    
    return @"Source";
}


-(NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@ Depth %d", self.name, self.depth];
}


-(void)setName:(NSString *)name
{
    _name = name;
}


-(NSString *)name
{
    if (!_name && self.videoInput)
    {
        return self.videoInput.captureName;
    }
    
    return _name;
}


-(void)rebuildFilters
{
    
    
    if (!self.chromaKeyFilter)
    {
        self.chromaKeyFilter = [CIFilter filterWithName:@"CSChromaKeyFilter"];
        [self.chromaKeyFilter setDefaults];
    }

    if(!self.selectedFilter)
    {
        self.selectedFilter = [CIFilter filterWithName:@"CIColorMatrix"];
        [self.selectedFilter setDefaults];
    }
    
    if(!self.transformFilter)
    {
        self.transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [self.transformFilter setDefaults];
    }
   
    if (!self.scaleFilter)
    {
        self.scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
        [self.scaleFilter setDefaults];
    }

    if (!self.cropFilter)
    {
        self.cropFilter = [CIFilter filterWithName:@"CICrop"];
        [self.cropFilter setDefaults];
    }
    
    
    
    
    NSAffineTransform *geometryTransform = [NSAffineTransform transform];
    
    //Calculate crop rectangle, then adjust for shifted origin of the crop.

    NSRect cropRect = [self calculateCropRect:self.inputImage.extent.size.width height:self.inputImage.extent.size.height];
    

    
    [self.cropFilter setValue:[CIVector vectorWithX:cropRect.origin.x Y:cropRect.origin.y Z:cropRect.size.width W:cropRect.size.height] forKeyPath:@"inputRectangle"];
    
    NSAffineTransform *rotateTransform = [NSAffineTransform transform];
    [rotateTransform rotateByDegrees:self.rotationAngle];
    
    NSPoint rotateOrigin = [rotateTransform transformPoint:cropRect.origin];
    NSSize rotateSize = [rotateTransform transformSize:cropRect.size];
    
    
    NSRect rotateRect = NSMakeRect(rotateOrigin.x, rotateOrigin.y, rotateSize.width, rotateSize.height);
    
    
    
    
    
    CGFloat scale_cx, scale_cy, cent_x, cent_y, x,y;
    
    [self scaleToRect:NSMakeRect(self.x_pos, self.y_pos, self.display_width, self.display_height) extent:NSMakeRect(rotateRect.origin.x, rotateRect.origin.y, rotateRect.size.width, rotateRect.size.height)];
    
    
    
    cent_x = (rotateRect.origin.x) + rotateRect.size.width/2;
    cent_y = (rotateRect.origin.y) + rotateRect.size.height/2;
    scale_cx = cent_x*_internalScaleFactor;
    scale_cy = cent_y*_internalScaleFactor;
    x = (scale_cx)-cent_x;
    y = (scale_cy)-cent_y;
    
    NSAffineTransform *scaleTransform = [[NSAffineTransform alloc] init];
    [scaleTransform translateXBy:-x yBy:-y];
    //[scaleTransform scaleBy:self.scaleFactor];
    [self.scaleFilter setValue:@(_internalScaleFactor) forKey:kCIInputScaleKey];

    [geometryTransform appendTransform:scaleTransform];
    NSAffineTransform *positionTrans = [[NSAffineTransform alloc] init];
    
    [positionTrans translateXBy:_scale_x_pos yBy:_scale_y_pos];
    [geometryTransform appendTransform:positionTrans];
    
    [geometryTransform rotateByDegrees:self.rotationAngle];
    
    
    [self.transformFilter setValue:geometryTransform forKeyPath:kCIInputTransformKey];
    
    
    if (self.doChromaKey)
    {
        [self.chromaKeyFilter setValue:[[CIColor alloc] initWithColor:self.chromaKeyColor] forKey:kCIInputColorKey];
        
        [self.chromaKeyFilter setValue:@(self.chromaKeyThreshold) forKey:@"inputThreshold"];
        [self.chromaKeyFilter setValue:@(self.chromaKeySmoothing) forKey:@"inputSmoothing"];
    }
    
    
    CIVector *alphaVector = [CIVector vectorWithX:0.0f Y:0.0f Z:0.0f W:self.opacity];
    [self.selectedFilter setDefaults];
    
    [self.selectedFilter setValue:alphaVector forKey:@"inputAVector"];
    if (self.is_selected)
    {
        [self.selectedFilter setValue:[CIVector vectorWithX:1.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBiasVector"];
    }
    
}

-(NSRect)calculateCropRect:(int)width height:(int)height
{
    return NSMakeRect(self.crop_left, self.crop_bottom, width-self.crop_right-self.crop_left, height-self.crop_top-self.crop_bottom);
}



-(CIImage *)getCurrentImage
{
    
    CIImage *outimg = nil;
    CVPixelBufferRef newFrame = NULL;
    
    id<CaptureSessionProtocol>useInput;

    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    if (!useInput)
    {
        useInput = self.videoInput;
    }
    
    
    if (self.videoSources.count > 0 && (currentTime >= _nextImageTime) && (self.changeInterval > 0))
    {
        
        switch (self.rotateStyle)
        {
            case kRotateNormal:
                _currentSourceIdx++;
                if (_currentSourceIdx == self.videoSources.count)
                {
                    _currentSourceIdx = 0;
                }
                break;
            case kRotateRandom:
                _currentSourceIdx = (unsigned int)arc4random_uniform((unsigned int)self.videoSources.count);
                break;
            case kRotateReverse:
                _currentSourceIdx--;
                if (_currentSourceIdx < 0)
                {
                    _currentSourceIdx = (int)self.videoSources.count-1;
                }
                break;
            default:
                break;
        }
        _nextImageTime = currentTime + self.changeInterval;

        
        
        useInput = [self.videoSources objectAtIndex:_currentSourceIdx];
        
        _oldImage = _preBgImage;
        
        if (_oldImage && self.transitionFilter)
        {
        
            _oldCVBuf = _tmpCVBuf;
            CVPixelBufferRetain(_oldCVBuf);
            _inTransition = YES;
            _transitionTime = currentTime;
            NSArray *inputKeys = [self.transitionFilter inputKeys];
            
            if ([inputKeys containsObject:kCIInputExtentKey])
            {
                [self.transitionFilter setValue:[CIVector vectorWithX:self.x_pos Y:self.y_pos Z:self.display_width W:self.display_height] forKey:kCIInputExtentKey];
            }

            [self.transitionFilter setValue:_oldImage forKey:kCIInputImageKey];
        }
        
    }
    
    if (useInput)
    {
        if ([useInput respondsToSelector:@selector(currentImage)])
        {
            outimg = [useInput currentImage];
        } else {
            
            newFrame = [useInput getCurrentFrame];
            if (newFrame)
            {
                
                
                //leaks memory in 10.9, less efficient if the buffer is YUV (probably due to pixel format conversion.
                //instead all the capture inputs produce RGB buffers, although it is questionable if it is wise to leave
                //that conversion up to the individual capture sources.
                
                //outimg = [CIImage imageWithCVImageBuffer:newFrame];
                
                
                outimg = [CIImage imageWithIOSurface:CVPixelBufferGetIOSurface(newFrame)];
                
                
                
                
                _tmpCVBuf = newFrame;
                
            }
        }
        
    }
    
    return outimg;
    
    
}

-(void) setTransitionFilterName:(NSString *)transitionFilterName
{
    _transitionFilterName = transitionFilterName;
    if (self.transitionFilter)
    {
        NSDictionary *attrs = self.transitionFilter.attributes;
        NSString *fname = attrs[@"CIAttributeFilterName"];
        if ([fname isEqualToString:transitionFilterName])
        {
            return;
        }
    }
    self.transitionFilter = [CIFilter filterWithName:_transitionFilterName];
    [self.transitionFilter setDefaults];
}



-(NSString *)transitionFilterName
{
    return _transitionFilterName;
}


-(CIImage *)currentImage:(CIImage *)backgroundImage
{
    
    CIImage *outimg = nil;
    self.inputImage = [self getCurrentImage];
    
    if (!self.inputImage)
    {
        if (!self.solidFilter)
        {
            self.solidFilter = [CIFilter filterWithName:@"CIConstantColorGenerator"];
            [self.solidFilter setDefaults];
            [self.solidFilter setValue:[CIColor colorWithRed:0.0f green:0.0f blue:0.85f] forKey:kCIInputColorKey];
        }
        
        self.inputImage = [[self.solidFilter valueForKey:kCIOutputImageKey] imageByCroppingToRect:CGRectMake(0.0f, 0.0f, 200.0f, 200.0f)];
    }
    
    outimg = self.inputImage;
    

    if (!NSEqualSizes(self.oldSize, self.inputImage.extent.size))
    {
        [self rebuildFilters];
    }
    
    if (self.userFilter)
    {
        NSArray *userInputs = self.userFilter.inputKeys;
        if ([userInputs containsObject:kCIInputImageKey])
        {
            [self.userFilter setValue:outimg forKeyPath:kCIInputImageKey];
        }
        outimg = [self.userFilter valueForKey:kCIOutputImageKey];
    }

    self.oldSize = self.inputImage.extent.size;
    [self.cropFilter setValue:outimg forKeyPath:kCIInputImageKey];
    
    outimg = [self.cropFilter valueForKey:kCIOutputImageKey];

    
    
    //self.inputImage = outimg;
    [self.scaleFilter setValue:outimg forKeyPath:kCIInputImageKey];
    
    outimg  = [self.scaleFilter valueForKey:kCIOutputImageKey];
    
    [self.transformFilter setValue:outimg forKeyPath:kCIInputImageKey];

    outimg = [self.transformFilter valueForKey:kCIOutputImageKey];
    


    if (self.doChromaKey && self.chromaKeyFilter)
    {
        [self.chromaKeyFilter setValue:outimg forKey:kCIInputImageKey];
        outimg = [self.chromaKeyFilter valueForKey:kCIOutputImageKey];
    }
    
    
    [self.selectedFilter setValue:outimg forKey:kCIInputImageKey];
    outimg = [self.selectedFilter valueForKey:kCIOutputImageKey];
    
    self.layoutPosition = NSMakeRect(self.x_pos, self.y_pos, self.display_width, self.display_height);

    _preBgImage = outimg;
    
    if (_inTransition)
    {
        CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
        
        CFAbsoluteTime filterTime = currentTime - _transitionTime;
        [self.transitionFilter setValue:outimg forKey:kCIInputTargetImageKey];
        [self.transitionFilter setValue:@(filterTime) forKey:kCIInputTimeKey];
        if (filterTime >= 1.0f)
        {
            _inTransition = NO;
        }
        outimg = [self.transitionFilter valueForKey:kCIOutputImageKey];
        
    } else {
        _oldImage = nil;
        CVPixelBufferRelease(_oldCVBuf);
    }

    
    
    if (backgroundImage)
    {
        //CIFilter *compositeCopy = [self.compositeFilter copy];
        [self.compositeFilter setValue:outimg forKeyPath:kCIInputImageKey];
        [self.compositeFilter setValue:backgroundImage forKeyPath:kCIInputBackgroundImageKey];
        outimg = [self.compositeFilter valueForKey:kCIOutputImageKey];
    }
    return outimg;
}




-(void) frameRendered
{
    if (_tmpCVBuf)
    {
        CVPixelBufferRelease(_tmpCVBuf);
        _tmpCVBuf = NULL;
    }
}

-(void)addMulti
{
    if (self.videoInput)
    {
        [self.videoSources addObject:self.videoInput];
    }
    
}


-(void)autoFit
{
    _x_pos = 0.0f;
    _y_pos = 0.0f;
    self.display_width = self.canvas_width;
    self.display_height = self.canvas_height;
    
    //[self scaleToRect:NSMakeRect(0.0f, 0.0f, self.canvas_width, self.canvas_height)];
    
    [self rebuildFilters];
}




-(float) calculateScale:(CGSize)forSize sourceSize:(CGSize)sourceSize
{
    
    
    CGFloat source_width, source_height;
    
    source_width = fabs(sourceSize.width);
    source_height = fabs(sourceSize.height);
    
    if (source_width == 0 && source_height == 0)
    {
        return _internalScaleFactor;
    }
    
    float wr = forSize.width / source_width;
    float hr = forSize.height / source_height;
    
    float ratio;
    ratio = (hr < wr ? hr : wr);
    return ratio;
}



-(void) scaleToRect:(CGRect)rect extent:(CGRect)extent
{
    
    CGFloat source_width, source_height;
    
    source_width = extent.size.width;
    source_height = extent.size.height;
    
    if (NSEqualSizes(extent.size, rect.size))
    {
        _scale_x_pos = self.x_pos;
        _scale_y_pos = self.y_pos;
        _internalScaleFactor = 1.0f;
        
        return;
    }
    
    
    if (source_width == 0 && source_height == 0)
    {
        return;
    }
    
    float ratio = [self calculateScale:rect.size sourceSize:extent.size];
    
    float new_w, new_h;
    float new_x, new_y;
    
    new_w = source_width * ratio;
    new_h = source_height * ratio;
    
    new_x = (rect.size.width - new_w)/2;
    new_y = (rect.size.height - new_h)/2;
    
    float x_adj, y_adj;
    x_adj = ((new_w-source_width)/2)-extent.origin.x;
    y_adj = ((new_h-source_height)/2)-extent.origin.y;
    
    
    
    _scale_x_pos = new_x+x_adj+_x_pos;
    _scale_y_pos = new_y+y_adj+_y_pos;
    
    
    _internalScaleFactor = ratio;

    
}

-(void) scaleTo:(CGFloat)width height:(CGFloat)height
{

    CGFloat source_width, source_height;
    
    source_width = self.inputImage.extent.size.width;
    source_height = self.inputImage.extent.size.height;
    
    
    
    if (source_width == 0 && source_height == 0)
    {
        return;
    }
    
    float ratio = 0.0f;
    
    //float ratio = [self calculateScale:width height:height];

    float new_w, new_h;
    float new_x, new_y;
    
    new_w = source_width * ratio;
    new_h = source_height * ratio;
    
    new_x = (width - new_w)/2;
    new_y = (height - new_h)/2;
    float x_adj, y_adj;
    //compensate for scaling adjustment. This adjustment is only valid when we're force-setting to center.
    //There's probably a general case method for compensating for the scaling-at-center movement of the origin
    //but I'm not good with computer
    
    
    x_adj = ((new_w-source_width)/2)-self.inputImage.extent.origin.x;
    y_adj = ((new_h-source_height)/2)-self.inputImage.extent.origin.y;
    

 
    _x_pos = new_x+x_adj;
    _y_pos = new_y+y_adj;
    _internalScaleFactor = ratio;

    
    [self rebuildFilters];
}


-(void) updateSize:(CGFloat)width height:(CGFloat)height
{
    
    self.display_width = width;
    self.display_height = height;
    [self rebuildFilters];
}


-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    _x_pos += x;
    _y_pos += y;
    _scale_x_pos += x;
    _scale_y_pos += y;
    
    [self rebuildFilters];
}



-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}



-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    
    
    NSLog(@"SETTING SELECTED VIDEO TYPE %@", selectedVideoType);
    
    self.videoInput.configViewController = nil;
    
    self.videoInput = nil;
    
    id <CaptureSessionProtocol> newCaptureSession;
    
    if ([selectedVideoType isEqualToString:@"Desktop"])
    {
        newCaptureSession = [[DesktopCapture alloc ] init];
    } else if ([selectedVideoType isEqualToString:@"AVFoundation"]) {
        newCaptureSession = [[AVFCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"QTCapture"]) {
        newCaptureSession = [[QTCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Syphon"]) {
        newCaptureSession = [[SyphonCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Image"]) {
        
        newCaptureSession = [[ImageCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Text"]) {
        newCaptureSession = [[TextCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Window"]) {
        newCaptureSession = [[WindowCapture alloc] init];
    } else if ([selectedVideoType isEqualToString:@"Movie"]) {
        newCaptureSession = [[MovieCapture alloc] init];
    } else {
        newCaptureSession = [[AVFCapture alloc] init];
    }
    
    newCaptureSession.imageContext = self.imageContext;

    
    self.videoInput = newCaptureSession;
    [self sourceConfigurationView];

    
    newCaptureSession = nil;
    
    _selectedVideoType = selectedVideoType;
    
}


-(void)sourceConfigurationView
{
    NSView *configView = nil;
    if ([self.videoInput respondsToSelector:@selector(configurationView)])
    {
        configView = [self.videoInput configurationView];
        
    }
    
    if (self.editorPopover.contentViewController)
    {
        
        InputPopupControllerViewController *pcont = (InputPopupControllerViewController*)self.editorPopover.contentViewController;
        
        
        
        NSArray *currentSubviews = pcont.sourceConfigView.subviews;
        NSView *currentSubview = currentSubviews.firstObject;
        if (!configView)
        {
            [currentSubview removeFromSuperview];
        } else if (currentSubview) {
            [[pcont.sourceConfigView animator] replaceSubview:currentSubview with:configView ];
        } else {
            [[pcont.sourceConfigView animator] addSubview:configView];
        }
    }

    
}


-(float) scaleFactor
{
    return _scaleFactor;
}


-(void) setScaleFactor:(float)scaleFactor
{
    _scaleFactor = scaleFactor;
    
    
    _display_width = self.inputImage.extent.size.width*scaleFactor;
    _display_height = self.inputImage.extent.size.height*scaleFactor;
    [self rebuildFilters];
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"x_pos", @"y_pos", @"rotationAngle", @"is_selected", @"depth", @"opacity", @"crop_left", @"crop_right", @"crop_top", @"crop_bottom", @"doChromaKey", @"chromaKeyColor", @"chromaKeyThreshold", @"chromaKeySmoothing", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self rebuildFilters];
    } else if ([keyPath isEqualToString:@"editorPopover"]) {
        NSLog(@"SOURCE CONFIG");
        [self sourceConfigurationView];
    }
        
        
}




@end
