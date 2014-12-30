//
//  InputSource.m
//  CocoaSplit
//
//  Created by Zakk on 7/17/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "InputSource.h"
#import "CSCaptureSourceProtocol.h"
#import "SourceLayout.h"
#import "InputPopupControllerViewController.h"

static NSArray *_sourceTypes = nil;




@implementation InputSource



@synthesize selectedVideoType = _selectedVideoType;
@synthesize name = _name;
@synthesize imageContext = _imageContext;
@synthesize scaleFactor = _scaleFactor;
@synthesize transitionFilterName = _transitionFilterName;
@synthesize is_selected = _is_selected;
@synthesize active = _active;
@synthesize is_live = _is_live;
@synthesize crop_left = _crop_left;
@synthesize crop_right = _crop_right;
@synthesize crop_top = _crop_top;
@synthesize crop_bottom = _crop_bottom;



-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    

    [aCoder encodeInt:self.x_pos forKey:@"x_pos"];
    [aCoder encodeInt:self.y_pos forKey:@"y_pos"];
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
    [aCoder encodeBool:self.usePrivateSource forKey:@"usePrivateSource"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    
    [aCoder encodeInt:self.rotateStyle forKey:@"rotateStyle"];
    [aCoder encodeFloat:_last_x_adjust forKey:@"last_x_adjust"];
    [aCoder encodeFloat:_last_y_adjust forKey:@"last_y_adjust"];
    
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
    [aCoder encodeFloat:self.changeInterval forKey:@"changeInterval"];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self commonInit];
        self.x_pos = [aDecoder decodeIntForKey:@"x_pos"];
        self.y_pos = [aDecoder decodeIntForKey:@"y_pos"];
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

        _last_x_adjust = [aDecoder decodeFloatForKey:@"last_x_adjust"];
        _last_y_adjust =  [aDecoder decodeFloatForKey:@"last_y_adjust"];
        
        
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

        if (self.videoInput)
        {
            [self registerVideoInput:self.videoInput];
        }
        
        for(id vInput in self.videoSources)
        {
            [self registerVideoInput:vInput];
        }
        
        if ([aDecoder containsValueForKey:@"changeInterval"])
        {
            self.changeInterval = [aDecoder decodeFloatForKey:@"changeInterval"];
        }
        
        
        self.usePrivateSource = [aDecoder decodeBoolForKey:@"usePrivateSource"];

        [self rebuildUserFilter];
    }
    
    
    return self;
}



-(void) registerVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    forInput.inputSource = self;
    forInput.isLive = self.is_live;
    [forInput addObserver:self forKeyPath:@"activeVideoDevice.uniqueID" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)deregisterVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    if (!forInput)
    {
        return;
    }
    
    forInput.isLive = NO;
    
    [forInput removeObserver:self forKeyPath:@"activeVideoDevice.uniqueID"];
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
    _nextImageTime = 0.0f;
    _currentSourceIdx = 0;
    
    self.changeInterval = 20.0f;
    
    
    self.scaleFactor = 1.0f;
    _x_pos = 0;
    _y_pos = 0;
    
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
    self.usePrivateSource = NO;
    
    self.unlock_aspect = NO;
    self.resizeType = kResizeNone;
    
    _locked_ar = 1.0;
    
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
   
    self.layoutPosition = NSMakeRect(self.x_pos, self.y_pos, self.display_width, self.display_height);
    self.active = YES;
    self.transitionNames = [CIFilter filterNamesInCategory:kCICategoryTransition];
    self.availableEffectNames = [CIFilter filterNamesInCategories:nil];
    self.doChromaKey = NO;
    self.chromaKeyThreshold = 0.1005f;
    self.chromaKeySmoothing = 0.1344f;
    
    self.chromaKeyColor = [NSColor greenColor];
    
    [self addObserver:self forKeyPath:@"usePrivateSource" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"editorController" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self rebuildFilters];
    self.needRebuildFilter = NO;
    
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
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
    
    return pluginMap.allKeys;
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


-(void)invalidateFilters
{
    @synchronized(self)
    {
        self.needRebuildFilter = YES;
    }
}

-(void)dealloc
{
    
    NSLog(@"DEALLOC SOURCE INPUT");
    [self deregisterVideoInput:self.videoInput];
    for(id vInput in self.videoSources)
    {
        [self deregisterVideoInput:vInput];
    }
    
    [self removeObserver:self forKeyPath:@"usePrivateSource"];
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
    [self removeObserver:self forKeyPath:@"editorController"];
    
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
    
 
    if (!self.compositeFilter)
    {
        self.compositeFilter = [CIFilter filterWithName:@"CISourceOverCompositing"];
        [self.compositeFilter setDefaults];
    }
    
    
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
    
    if (!self.rotateFilter)
    {
        self.rotateFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [self.rotateFilter setDefaults];

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
    
    if (!self.prescaleTransformFilter)
    {
        
        self.prescaleTransformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        [self.prescaleTransformFilter setDefaults];

        
    }
    

    if (!self.cropFilter)
    {
        self.cropFilter = [CIFilter filterWithName:@"CICrop"];
        [self.cropFilter setDefaults];
    }
    
    
    //Calculate crop rectangle, then adjust for shifted origin of the crop.

    
    if (!self.inputImage)
    {
        return;
    }
    
    
    NSRect cropRect;
    NSRect fullRect = self.inputImage.extent;
    
    //Any transform we use gets applied to this path, so we can easily keep track of our bounds if we need to do
    //calculations.
    
    
    NSBezierPath *currentPath;
    
    if (self.videoInput.allowScaling)
    {
        currentPath = [NSBezierPath bezierPathWithRect:fullRect];
    } else {
        currentPath = [NSBezierPath bezierPathWithRect:NSMakeRect(0, 0, self.display_width, self.display_height)];
    }
    
    
    NSAffineTransform *preScaleTransform = [NSAffineTransform transform];
    
    
    NSAffineTransform *rotateTransform = [NSAffineTransform transform];
    

    

    if (self.rotationAngle > 0 && self.rotationAngle < 360)
    {
        int rc_x, rc_y;
        rc_x = NSMidX(currentPath.bounds);
        rc_y = NSMidY(currentPath.bounds);
        
        [rotateTransform translateXBy:rc_x yBy:rc_y];
        [rotateTransform rotateByDegrees:self.rotationAngle];
        [rotateTransform translateXBy:-rc_x yBy:-rc_y];
        [currentPath transformUsingAffineTransform:rotateTransform];
    
    }
    
    [self.rotateFilter setValue:rotateTransform forKeyPath:kCIInputTransformKey];

    NSAffineTransform *geometryTransform = [NSAffineTransform transform];
    
    cropRect = [self calculateCropRect:currentPath.bounds];
    /*
    if (!self.videoInput.allowScaling)
    {
        cropRect = [self calculateCropRect:currentPath.bounds];
        
    } else {
        cropRect = [self calculateCropRect:NSMakeRect(currentPath.bounds.origin.x, currentPath.bounds.origin.y, self.display_width, self.display_height)];
    }
     */
    
    

    cropRect = [self calculateCropRect:currentPath.bounds];
    currentPath = [NSBezierPath bezierPathWithRect:cropRect];
    
    
    
    _inputExtent = currentPath.bounds;
    [self.cropFilter setValue:[CIVector vectorWithX:cropRect.origin.x Y:cropRect.origin.y Z:cropRect.size.width W:cropRect.size.height] forKeyPath:@"inputRectangle"];
    

    
    
    
    if (self.videoInput.allowScaling)
    {
        CGFloat scaleX = self.display_width/cropRect.size.width;
        CGFloat scaleY = self.display_height/cropRect.size.height;
        if (self.unlock_aspect)
        {
            _locked_ar = scaleX/scaleY;
        }
        
        
        
        
        
        NSAffineTransform *scaleSim = [[NSAffineTransform alloc] init];
        CGFloat useScale = fminf(scaleX, scaleY);
        [scaleSim scaleBy:useScale];
        [currentPath transformUsingAffineTransform:scaleSim];
        
        float scale_x_adjust, scale_y_adjust;
        
        scale_x_adjust = _last_x_adjust;
        scale_y_adjust = _last_y_adjust;
        
        
        if (!_lastScalePath)
        {
            _lastScalePath = currentPath.copy;
            
        }
        
        if (self.resizeType & kResizeLeft)
        {
            scale_x_adjust = NSMaxX(_lastScalePath.bounds) - NSMaxX(currentPath.bounds);
        }
        
        if (self.resizeType & kResizeBottom)
        {
            scale_y_adjust = NSMaxY(_lastScalePath.bounds) - NSMaxY(currentPath.bounds);
        }
        
        if (self.resizeType & kResizeTop)
        {
            scale_y_adjust = NSMinY(_lastScalePath.bounds) - NSMinY(currentPath.bounds);
        }
        
        if (self.resizeType & kResizeRight)
        {
            scale_x_adjust = NSMinX(_lastScalePath.bounds) - NSMinX(currentPath.bounds);
        }
        
        
        if (self.resizeType & kResizeCenter)
        {
            scale_y_adjust = NSMidY(_lastScalePath.bounds) - NSMidY(currentPath.bounds);
            scale_x_adjust = NSMidX(_lastScalePath.bounds) - NSMidX(currentPath.bounds);
        }
        
        
        
        if (scale_x_adjust != 0 || scale_y_adjust != 0)
        {
            NSAffineTransform *postScaleTranslate = [NSAffineTransform transform];
            [postScaleTranslate translateXBy:scale_x_adjust yBy:scale_y_adjust];
            [geometryTransform appendTransform:postScaleTranslate];
            [currentPath transformUsingAffineTransform:postScaleTranslate];
        }
        
        _last_x_adjust = scale_x_adjust;
        _last_y_adjust = scale_y_adjust;
        
        
        
        [self.scaleFilter setValue:@(useScale) forKey:kCIInputScaleKey];
        [self.scaleFilter setValue:@(_locked_ar) forKey:kCIInputAspectRatioKey];

    }
    _lastScalePath = currentPath.copy;
    
    [self.prescaleTransformFilter setValue:preScaleTransform forKey:kCIInputTransformKey];
    
    NSAffineTransform *positionT = [NSAffineTransform transform];
    
    
    [positionT translateXBy:_x_pos yBy:_y_pos];
    [geometryTransform appendTransform:positionT];
    [currentPath transformUsingAffineTransform:positionT];
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

    /*
    if (self.is_selected)
    {
        [self.selectedFilter setValue:[CIVector vectorWithX:1.0f Y:0.0f Z:0.0f W:0.0f] forKey:@"inputBiasVector"];
    }
     */
    
}

-(NSRect)calculateCropRect:(NSRect)inputRect
{
    CGFloat new_origin_x, new_origin_y, new_max_x, new_max_y;
    
    CGFloat old_origin_x, old_origin_y, old_max_x, old_max_y;
    
    old_origin_x = NSMinX(inputRect);
    old_origin_y = NSMinY(inputRect);
    old_max_x = NSMaxX(inputRect);
    old_max_y = NSMaxY(inputRect);
    
    new_origin_x = old_origin_x + self.crop_left;
    new_origin_y = old_origin_y + self.crop_bottom;
    new_max_x = old_max_x - self.crop_right;
    new_max_y = old_max_y - self.crop_top;

    return NSMakeRect(new_origin_x, new_origin_y, new_max_x-new_origin_x, new_max_y-new_origin_y);
    
    
    
}



-(CIImage *)getCurrentImage
{
    
    CIImage *outimg = nil;
    CVPixelBufferRef newFrame = NULL;
    

    NSObject<CSCaptureSourceProtocol> *_useInput = nil;
    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    
    if (self.videoSources.count > 0)
    {
        _useInput = [self.videoSources objectAtIndex:_currentSourceIdx];

    } else {
        _useInput = self.videoInput;
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

    
        _useInput.isVisible = NO;
        _useInput = [self.videoSources objectAtIndex:_currentSourceIdx];
        _useInput.isVisible = YES;
        
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
                
                [self.transitionFilter setValue:[CIVector vectorWithCGRect:self.layoutPosition] forKey:kCIInputExtentKey];
                
                //[self.transitionFilter setValue:[CIVector vectorWithX:self.x_pos Y:self.y_pos Z:self.display_width W:self.display_height] forKey:kCIInputExtentKey];
            }

            [self.transitionFilter setValue:_oldImage forKey:kCIInputImageKey];
        }
        
    }
    
    if (_useInput)
    {
        
        outimg = [_useInput currentImage];
        
        if (!outimg)
        {
            newFrame = [_useInput getCurrentFrame];
            if (newFrame)
            {

                
                IOSurfaceRef frameSurface = CVPixelBufferGetIOSurface(newFrame);

                if (frameSurface)
                {
                    
                    outimg = [CIImage imageWithIOSurface:frameSurface];
                    _tmpCVBuf = newFrame;
                } else {
                    //WHYYYYYYYYYYYYYYYYYYYYYY
                    outimg = [CIImage imageWithCVImageBuffer:newFrame];
                    _tmpCVBuf = NULL;
                }
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
        [self invalidateFilters];
    }
    
    @synchronized(self)
    {
        if (self.needRebuildFilter)
        {
            [self rebuildFilters];
            self.needRebuildFilter = NO;
        }
    }
    

    [self.rotateFilter setValue:outimg forKey:kCIInputImageKey];
    outimg = [self.rotateFilter valueForKey:kCIOutputImageKey];
    
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
    [self.prescaleTransformFilter setValue:outimg forKeyPath:kCIInputImageKey];
    
    outimg  = [self.prescaleTransformFilter valueForKey:kCIOutputImageKey];
   
    
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
    
    self.layoutPosition = outimg.extent;
    
    
    

    
    
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
    



    
    _preBgImage = outimg;
   
    

    
    if (backgroundImage)
    {
        outimg = [outimg imageByCompositingOverImage:backgroundImage];
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
        NSObject<CSCaptureSourceProtocol> *inputCopy;
        
        inputCopy = self.videoInput.copy;
        
        [self registerVideoInput:inputCopy];

        [self.videoSources addObject:inputCopy];
    }
    
}


-(void)autoFit
{
    _x_pos = 0.0f;
    _y_pos = 0.0f;
    _last_y_adjust = _last_x_adjust = 0;
    
    self.resizeType = kResizeNone;
    
    self.display_width = self.canvas_width;
    self.display_height = self.canvas_height;
    
    
    NSRect scaleRect = [self scaleToRect:NSMakeRect(0.0f, 0.0f, self.canvas_width, self.canvas_height) extent:_inputExtent];
    
    _x_pos = scaleRect.origin.x;
    _y_pos = scaleRect.origin.y;

    self.unlock_aspect = NO;
    _locked_ar = 1.0;
    
    [self invalidateFilters];
}




-(float) calculateScale:(CGSize)forSize sourceSize:(CGSize)sourceSize
{
    
    
    CGFloat source_width, source_height;
    
    source_width = fabs(sourceSize.width);
    source_height = fabs(sourceSize.height);
    
    float wr = forSize.width / source_width;
    float hr = forSize.height / source_height;
    
    float ratio;
    ratio = (hr < wr ? hr : wr);
    return ratio;
}



-(NSRect) scaleToRect:(CGRect)rect extent:(CGRect)extent
{
    
    CGFloat source_width, source_height;
    
    source_width = extent.size.width;
    source_height = extent.size.height;
    
    if (NSEqualSizes(extent.size, rect.size) || !self.videoInput.allowScaling)
    {
        
        
        return extent;
    }
    
    
    if (source_width == 0 && source_height == 0)
    {
        return extent;
    }
    
    float ratio = [self calculateScale:rect.size sourceSize:extent.size];
    
    float new_w, new_h;
    float new_x, new_y;
    
    new_w = source_width * ratio;
    new_h = source_height * ratio;
    
    new_x = (rect.size.width - new_w)/2;
    new_y = (rect.size.height - new_h)/2;
    new_x -= extent.origin.x*ratio;
    new_y -= extent.origin.y*ratio;
    

    return NSMakeRect(new_x, new_y, new_w, new_h);
    
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

    
    [self invalidateFilters];
}


-(void) updateSize:(CGFloat)width height:(CGFloat)height
{
    
    
    self.display_width = width;
    self.display_height = height;
    
    [self invalidateFilters];
}


-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    if (isnan(x))
    {
        NSLog(@"HOLY CRAP NaN");
        return;
    }
    
    
    _x_pos += x;
    _y_pos += y;
    [self invalidateFilters];
}






-(NSString *) selectedVideoType
{
    return _selectedVideoType;
}

-(void) setSelectedVideoType:(NSString *)selectedVideoType
{
    
    
    
    
    
    NSMutableDictionary *pluginMap = [[CSPluginLoader sharedPluginLoader] sourcePlugins];
    
    _currentInputViewController = nil;
    
    if (self.videoInput)
    {
        [self deregisterVideoInput:self.videoInput];
        self.videoInput = nil;
    }
    
    NSObject <CSCaptureSourceProtocol> *newCaptureSession;
    
    Class captureClass = [pluginMap objectForKey:selectedVideoType];
    
    newCaptureSession = [[captureClass alloc] init];
    
    
    
    newCaptureSession.imageContext = self.imageContext;

    
    self.videoInput = newCaptureSession;
    [self registerVideoInput:self.videoInput];
    
    
    [self sourceConfigurationView];

    newCaptureSession = nil;
    
    _selectedVideoType = selectedVideoType;
    
}


-(void)sourceConfigurationView
{
    NSView *configView = nil;
    if ([self.videoInput respondsToSelector:@selector(configurationView)])
    {
        
        _currentInputViewController = [self.videoInput configurationView];
        configView = _currentInputViewController.view;
        
    }
    
    if (self.editorController)
    {
        
        
        InputPopupControllerViewController *pcont = self.editorController;
        
        
        
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

-(void) editorPopoverDidClose
{
    return;
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
    [self invalidateFilters];
}

-(void) deduplicateVideoSource:(NSObject<CSCaptureSourceProtocol> *)source
{
    
    
    if (self.usePrivateSource)
    {
        return;
    }
    
    if (source != self.videoInput)
    {
        return;
    }
    
    
    SourceCache *scache = self.layout.sourceCache;
    
    id newInput = [scache cacheSource:source uniqueID:source.activeVideoDevice.uniqueID];
    if (newInput == source)
    {
        return;
    }
    
    
    
    [self deregisterVideoInput:self.videoInput];
    self.videoInput = newInput;
    [self registerVideoInput:self.videoInput];
    
}


-(void) makeSourcePrivate
{
    [self deregisterVideoInput:self.videoInput];
    self.videoInput = self.videoInput.copy;
    [self registerVideoInput:self.videoInput];
    
}


-(size_t)canvas_width
{
    return self.layout.canvas_width;
}

-(size_t)canvas_height
{
    return self.layout.canvas_height;
}


-(void) setActive:(bool)active
{
    _active = active;
    if (self.videoInput)
    {
        self.videoInput.isActive = active;
    }
}


-(bool)active
{
    return _active;
}


-(void) setIs_live:(bool)is_live
{
    _is_live = is_live;
    if (self.videoInput)
    {
        self.videoInput.isLive = is_live;
    }
}

-(bool)is_live
{
    return _is_live;
}


-(void) setIs_selected:(bool)is_selected
{
    _is_selected = is_selected;
    if (self.videoInput)
    {
        self.videoInput.isSelected = is_selected;
    }
    
    if (is_selected)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputSelected object:self userInfo:nil];

    }
    
}


-(bool)is_selected
{
    return _is_selected;
}

-(int) crop_left
{
    return _crop_left;
}


-(void) setCrop_left:(int)crop_left
{
    if (crop_left < 0)
    {
        _crop_left = 0;
    } else {
        _crop_left = crop_left;
    }
}

-(int) crop_right
{
    return _crop_right;
}


-(void) setCrop_right:(int)crop_right
{
    if (crop_right < 0)
    {
        _crop_right = 0;
    } else {
        _crop_right = crop_right;
    }
}

-(int) crop_top
{
    return _crop_top;
}


-(void) setCrop_top:(int)crop_top
{
    if (crop_top < 0)
    {
        _crop_top = 0;
    } else {
        _crop_top = crop_top;
    }
}

-(int) crop_bottom
{
    return _crop_bottom;
}


-(void) setCrop_bottom:(int)crop_bottom
{
    if (crop_bottom < 0)
    {
        _crop_bottom = 0;
    } else {
        _crop_bottom = crop_bottom;
    }
}



-(void) removeObjectFromVideoSourcesAtIndex:(NSUInteger)index
{
    id removedSource = [self.videoSources objectAtIndex:index];
    [self deregisterVideoInput:removedSource];
    [self.videoSources removeObjectAtIndex:index];
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"x_pos", @"y_pos", @"rotationAngle", @"is_selected", @"depth", @"opacity", @"crop_left", @"crop_right", @"crop_top", @"crop_bottom", @"doChromaKey", @"chromaKeyColor", @"chromaKeyThreshold", @"chromaKeySmoothing", nil];
}


//I should probably use contexts...
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self invalidateFilters];
    } else if ([keyPath isEqualToString:@"editorController"]) {
        [self sourceConfigurationView];
    } else if ([keyPath isEqualToString:@"activeVideoDevice.uniqueID"]) {
        [self deduplicateVideoSource:object];
    } else if ([keyPath isEqualToString:@"usePrivateSource"]) {
        if (self.usePrivateSource)
        {
            [self makeSourcePrivate];
        }
    }
        
        
}



-(void) windowWillClose:(NSNotification *)notification
{
    self.editorController = nil;
    self.editorWindow = nil;
}


@end
