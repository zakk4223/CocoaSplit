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


@class Foobar;


@implementation InputSource



@synthesize selectedVideoType = _selectedVideoType;
@synthesize name = _name;
@synthesize transitionFilterName = _transitionFilterName;
@synthesize is_selected = _is_selected;
@synthesize active = _active;
@synthesize is_live = _is_live;
@synthesize crop_left = _crop_left;
@synthesize crop_right = _crop_right;
@synthesize crop_top = _crop_top;
@synthesize crop_bottom = _crop_bottom;
@synthesize opacity = _opacity;
@synthesize rotationAngle = _rotationAngle;
@synthesize scrollXSpeed = _scrollXSpeed;
@synthesize scrollYSpeed = _scrollYSpeed;
@synthesize doChromaKey = _doChromaKey;
@synthesize chromaKeyColor = _chromaKeyColor;
@synthesize chromaKeySmoothing = _chromaKeySmoothing;
@synthesize chromaKeyThreshold = _chromaKeyThreshold;



-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeFloat:self.rotationAngle forKey:@"rotationAngle"];
    [aCoder encodeFloat:self.opacity forKey:@"opacity"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeFloat:self.depth forKey:@"depth"];
    [aCoder encodeFloat:self.crop_top forKey:@"crop_top"];
    [aCoder encodeFloat:self.crop_bottom forKey:@"crop_bottom"];
    [aCoder encodeFloat:self.crop_left forKey:@"crop_left"];
    [aCoder encodeFloat:self.crop_right forKey:@"crop_right"];
    [aCoder encodeObject:self.selectedVideoType forKey:@"selectedVideoType"];
    [aCoder encodeBool:self.usePrivateSource forKey:@"usePrivateSource"];
    [aCoder encodeObject:self.uuid forKey:@"uuid"];

    [aCoder encodeFloat:self.scrollXSpeed forKey:@"scrollXSpeed"];
    [aCoder encodeFloat:self.scrollYSpeed forKey:@"scrollYSpeed"];
    
    [aCoder encodeInt:self.rotateStyle forKey:@"rotateStyle"];
    
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
    

    [aCoder encodeFloat:self.layer.position.x forKey:@"frame_origin_x"];
    [aCoder encodeFloat:self.layer.position.y forKey:@"frame_origin_y"];
    [aCoder encodeFloat:self.layer.bounds.size.width forKey:@"frame_width"];
    [aCoder encodeFloat:self.layer.bounds.size.height forKey:@"frame_height"];
    [aCoder encodeFloat:self.borderWidth forKey:@"borderWidth"];
    [aCoder encodeObject:self.borderColor forKey:@"borderColor"];
    [aCoder encodeFloat:self.cornerRadius forKey:@"cornerRadius"];
    [aCoder encodeBool:_userBackground forKey:@"userBackground"];
    if (_userBackground)
    {
        [aCoder encodeObject:self.backgroundColor forKey:@"backgroundColor"];
    }
    
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self commonInit];
        
        
        _userBackground = [aDecoder decodeBoolForKey:@"userBackground"];
        if (_userBackground)
        {
            self.backgroundColor = [aDecoder decodeObjectForKey:@"backgroundColor"];
        }

        self.videoInput = [aDecoder decodeObjectForKey:@"videoInput"];

        self.layer.allowResize = self.videoInput.allowScaling;
        if (self.videoInput)
        {
            
            [self registerVideoInput:self.videoInput];

            _currentLayer = [self.videoInput layerForInput:self];
            self.layer.sourceLayer = _currentLayer;
            if (!_userBackground)
            {
                self.backgroundColor = nil;
            }
        }
        
        


        float x_pos,y_pos,width,height;
        
        x_pos = [aDecoder decodeFloatForKey:@"frame_origin_x"];
        y_pos = [aDecoder decodeFloatForKey:@"frame_origin_y"];
        width = [aDecoder decodeFloatForKey:@"frame_width"];
        height = [aDecoder decodeFloatForKey:@"frame_height"];

        
        CGRect oldFrame = self.layer.frame;
        self.layer.position = CGPointMake(x_pos, y_pos);
        self.layer.bounds = CGRectMake(0, 0, width, height);
       
        [self.layer resizeSourceLayer:self.layer.frame oldFrame:oldFrame];
        self.rotationAngle = [aDecoder decodeFloatForKey:@"rotationAngle"];

        //[self positionOrigin:x_pos y:y_pos];

        //self.layoutPosition = self.layer.frame;
        //if (width && height)
       // {
       //     [self updateSize:width height:height];
       // }
        self.layoutPosition = self.layer.frame;
        

        //self.layoutPosition = self.layer.frame;
        
        //NSLog(@"INIT %f %f %f %f", x_pos, y_pos, width, height);
        
        _selectedVideoType = [aDecoder decodeObjectForKey:@"selectedVideoType"];


        self.opacity = [aDecoder decodeFloatForKey:@"opacity"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.depth = [aDecoder decodeFloatForKey:@"depth"];
        self.crop_top = [aDecoder decodeFloatForKey:@"crop_top"];
        self.crop_bottom = [aDecoder decodeFloatForKey:@"crop_bottom"];
        self.crop_left = [aDecoder decodeFloatForKey:@"crop_left"];
        self.crop_right = [aDecoder decodeFloatForKey:@"crop_right"];

        
        
        self.uuid = [aDecoder decodeObjectForKey:@"uuid"];
        
        self.videoSources = [aDecoder decodeObjectForKey:@"videoSources"];
        if (!self.videoSources)
        {
            self.videoSources = [[NSMutableArray alloc] init];
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

        
        for(id vInput in self.videoSources)
        {
            [self registerVideoInput:vInput];
        }
        
        if ([aDecoder containsValueForKey:@"changeInterval"])
        {
            self.changeInterval = [aDecoder decodeFloatForKey:@"changeInterval"];
        }
        
        
        self.scrollXSpeed = [aDecoder decodeFloatForKey:@"scrollXSpeed"];
        self.scrollYSpeed = [aDecoder decodeFloatForKey:@"scrollYSpeed"];
        
        self.usePrivateSource = [aDecoder decodeBoolForKey:@"usePrivateSource"];

        self.borderWidth = [aDecoder decodeFloatForKey:@"borderWidth"];
        self.borderColor = [aDecoder decodeObjectForKey:@"borderColor"];
        self.cornerRadius = [aDecoder decodeFloatForKey:@"cornerRadius"];
        self.layoutPosition = self.layer.frame;

    }
    
    
    return self;
}



-(void) registerVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    forInput.inputSource = self;
    forInput.isLive = self.is_live;
    [forInput createNewLayerForInput:self];
    [forInput addObserver:self forKeyPath:@"activeVideoDevice.uniqueID" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)deregisterVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    if (!forInput)
    {
        return;
    }
    
    forInput.isLive = NO;
    [forInput removeLayerForInput:self];
    
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
    
    
    self.scrollXSpeed = 0.0f;
    self.scrollYSpeed = 0.0f;
    
    self.lockSize = YES;
    
    self.rotationAngle =  0.0f;
    self.depth = 0;
    self.opacity = 1.0f;
    self.crop_bottom = 0;
    self.crop_top = 0;
    self.crop_left = 0;
    self.crop_right = 0;
    self.videoSources = [[NSMutableArray alloc] init];
    
    self.transitionFilterName = @"fade";
    self.currentEffects = [[NSMutableArray alloc] init];
    self.usePrivateSource = NO;
    
    self.unlock_aspect = NO;
    self.resizeType = kResizeNone;
    
    
    self.layer = [CSInputLayer layer];
    self.layer.contentsGravity = kCAGravityResizeAspect;
    
    self.layer.masksToBounds = YES;
    self.layer.delegate = self;
    
    //self.layer.anchorPoint = CGPointMake(0.0, 0.0);
    
    //self.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);

    self.layer.bounds = CGRectMake(0.0, 0.0, 200, 200);
    [self positionOrigin:0.0 y:0.0];

    
    
    CIFilter *cFilter = [CIFilter filterWithName:@"CSChromaKeyFilter"];
    [cFilter setDefaults];
    cFilter.name = @"Chromakey";
    cFilter.enabled = NO;
    
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];
    [cropFilter setDefaults];
    cropFilter.name = @"CropFilter";
    cropFilter.enabled = NO;
    
    
    self.layer.sourceLayer.filters = @[cropFilter, cFilter];
    
    
    _multiTransition = [[CATransition alloc] init];
    _multiTransition.type = kCATransitionPush;
    _multiTransition.subtype = kCATransitionFromRight;
    _multiTransition.duration = 2.0;
    _multiTransition.removedOnCompletion = YES;
    //_multiTransition.fillMode = kCAFillModeForwards;
    
    
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
   
    self.layoutPosition = self.layer.frame;
    self.active = YES;
    self.transitionNames = @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
    self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];
    self.transitionDirection = kCATransitionFromRight;
    self.transitionDuration = 2.0f;
    
    self.availableEffectNames = [CIFilter filterNamesInCategories:nil];
    self.doChromaKey = NO;
    self.chromaKeyThreshold = 0.1005f;
    self.chromaKeySmoothing = 0.1344f;
    
    self.chromaKeyColor = [NSColor greenColor];
    _userBackground = NO;
    self.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);

    
    
    [self addObserver:self forKeyPath:@"usePrivateSource" options:NSKeyValueObservingOptionNew context:NULL];
    [self addObserver:self forKeyPath:@"editorController" options:NSKeyValueObservingOptionNew context:NULL];
    
 }




-(float)display_height
{
    return self.layoutPosition.size.height;
}

-(float)display_width
{
    return self.layoutPosition.size.width;
}


-(float)depth
{
    return self.layer.zPosition;
}

-(void)setDepth:(float)depth
{
    self.layer.zPosition = depth;
}

-(void)clearBackground
{
    self.backgroundColor = nil;
}


-(void)setBackgroundColor:(NSColor *)backgroundColor
{
    if (backgroundColor)
    {
        _userBackground = YES;
        self.layer.backgroundColor = [backgroundColor CGColor];
    } else {
        _userBackground = NO;
        self.layer.backgroundColor = NULL;
    }
}

-(NSColor *)backgroundColor
{
    if (self.layer.backgroundColor)
    {
        return [NSColor colorWithCGColor:self.layer.backgroundColor];
    } else {
        return nil;
    }
}


-(void)setBorderColor:(NSColor *)borderColor
{
    self.layer.borderColor = [borderColor CGColor];
}

-(NSColor *)borderColor
{
    return [NSColor colorWithCGColor:self.layer.borderColor];
}

-(void)setCornerRadius:(CGFloat)cornerRadius
{
    self.layer.cornerRadius = cornerRadius;
}

-(CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}


-(void)setBorderWidth:(CGFloat)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

-(CGFloat)borderWidth
{
    return self.layer.borderWidth;
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
                
                [_filterGenerator exportKey:inputName fromObject:lastFilter withName:[NSString stringWithFormat:@"params.%@:%@", keyPrefix, inputName]];
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

            [_filterGenerator exportKey:inputName fromObject:lastFilter withName:[NSString stringWithFormat:@"params.%@:%@", keyPrefix, inputName]];
        }

        
        
        CIFilter *newFilter = [_filterGenerator filter];
        if (self.userFilter)
        {
            [self.userFilter removeObserver:self forKeyPath:@"params"];
        }
        self.userFilter = newFilter;
        
        [self.userFilter addObserver:self forKeyPath:@"params" options:NSKeyValueObservingOptionNew context:NULL];
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



-(void)dealloc
{
    
    NSLog(@"DEALLOC SOURCE INPUT");
    [self deregisterVideoInput:self.videoInput];
    for(id vInput in self.videoSources)
    {
        [self deregisterVideoInput:vInput];
    }
    
    [self removeObserver:self forKeyPath:@"usePrivateSource"];
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
    return [NSString stringWithFormat:@"Name: %@ Depth %f", self.name, self.depth];
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


-(void)setRotationAngle:(float)rotationAngle
{
    _rotationAngle = rotationAngle;
    
    CATransform3D transform = CATransform3DMakeRotation(self.rotationAngle * M_PI / 180.0, 0.0, 0.0, 1);
    /*
    [CSCaptureBase layoutModification:^{
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.layer.transform = transform;
        [CATransaction commit];
        
    }];*/
    
    self.layer.disableAnimation = YES;
    self.layer.transform = transform;
    self.layer.disableAnimation = NO;
    
}

-(float)rotationAngle
{
    return _rotationAngle;
}


-(void)setCropRect
{
    CGRect contentsRect = self.layer.contentsRect;
    contentsRect.origin.x = self.crop_left;
    contentsRect.origin.y = self.crop_bottom;
    contentsRect.size.width = 1.0 - self.crop_right - self.crop_left;
    contentsRect.size.height = 1.0 - self.crop_top - self.crop_bottom;
    
    [CSCaptureBase layoutModification:^{
        [CATransaction begin];
        self.layer.cropRect = contentsRect;
        [CATransaction commit];
        
    }];
}




-(void) setTransitionFilterName:(NSString *)transitionFilterName
{
    _transitionFilterName = transitionFilterName;
}



-(NSString *)transitionFilterName
{
    return _transitionFilterName;
}



-(void)multiChange
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

    if (self.videoSources.count > 1 && (currentTime >= _nextImageTime) && (self.changeInterval > 0) )
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
        //[self.videoInput.outputLayer addAnimation:_multiTransition forKey:@"transition"];
        
        //[self.layer.sourceLayer addAnimation:_multiTransition forKey:@"transition"];
        //[self.videoInput.outputLayer addAnimation:_multiTransition forKey:@"transition"];

        //[self.layer.xLayer addAnimation:_multiTransition forKey:@"sublayers"];

        
        _nextInput = [self.videoSources objectAtIndex:_currentSourceIdx];


    }
}

-(void)frameTick
{
    

    self.layoutPosition = self.layer.frame;
    
    [self multiChange];
    
    if (!self.videoInput)
    {
        return;
    }
    
    
    
    [self.videoInput frameTick];
    
    __block CALayer *tLayer;
    
    if (self.videoSources.count > 1 && (self.videoInput != _nextInput))
    {
        _multiTransition = [[CATransition alloc] init];
        _multiTransition.type = self.transitionFilterName;
        _multiTransition.subtype = self.transitionDirection;
        _multiTransition.duration = self.transitionDuration;
        _multiTransition.removedOnCompletion = YES;

        [CSCaptureBase layoutModification:^{
            tLayer = [_nextInput layerForInput:self];
            [self.layer setSourceLayer:tLayer withTransition:_multiTransition];

        }];
        
        self.videoInput = _nextInput;
        _currentLayer = tLayer;
    } else if ((self.layer.sourceLayer != _currentLayer)) {
    
        //dispatch_async(dispatch_get_main_queue(), ^{
        [CSCaptureBase layoutModification:^{
            if (!_userBackground)
            {
                self.backgroundColor = nil;
                _userBackground = NO;
            }
            self.layer.allowResize = self.videoInput.allowScaling;

            self.layer.sourceLayer = _currentLayer;
            

        }];
        
        //});
    }
    
    
    
    
}







-(void)addMulti
{
    if (self.videoInput)
    {
        NSObject<CSCaptureSourceProtocol> *inputCopy;
        
        //inputCopy = self.videoInput.copy;
        
        //[self registerVideoInput:inputCopy];

        [self.videoSources addObject:self.videoInput];
    }
    
}


-(void)autoFit
{
    
    self.layer.frame = CGRectMake(0.0f, 0.0f, self.canvas_width, self.canvas_height);
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





-(void) updateSize:(CGFloat)width height:(CGFloat)height
{
    
    
    NSRect oldLayout = self.layoutPosition;
    NSRect newLayout = self.layoutPosition;
    
    float delta_w, delta_h;
    delta_w = width - oldLayout.size.width;
    delta_h = height - oldLayout.size.height;
    
    bool oldResize = self.layer.allowResize;
    bool tmpResize = oldResize;
    if (self.layer)
    {
        if (self.resizeType & kResizeFree)
        {
            self.layer.sourceLayer.contentsGravity = kCAGravityResize;
        } else {
            self.layer.sourceLayer.contentsGravity = kCAGravityResizeAspect;
        }
        
        if (self.resizeType & kResizeCrop)
        {
            tmpResize = NO;
        }
        
        if (self.resizeType & kResizeCenter)
        {
            newLayout.origin.x -= delta_w/2;
            newLayout.origin.y -= delta_h/2;
        } else {
            if (self.resizeType & kResizeLeft)
            {
                newLayout.origin.x -= delta_w;
            }
        
            if (self.resizeType & kResizeBottom)
            {
                newLayout.origin.y -= delta_h;
            }
        }
        
        
        newLayout.size.width = width;
        newLayout.size.height = height;
        
        [CSCaptureBase layoutModification:^{
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            self.layer.allowResize = tmpResize;
            self.layer.frame = newLayout;
            self.layer.allowResize = oldResize;
            
            [CATransaction commit];

        }];
        

    }
}



-(void) positionOrigin:(CGFloat)x y:(CGFloat)y
{
    if (self.layer)
    {
        
        NSRect newFrame = self.layer.frame;
        newFrame.origin.x = x;
        newFrame.origin.y = y;
        
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        
        self.layer.frame = newFrame;
        [CATransaction commit];
    }

}
-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    
    if (isnan(x))
    {
        NSLog(@"HOLY CRAP NaN");
        return;
    }
    
    
    if (self.layer)
    {
        
        NSPoint newOrigin = self.layer.position;
        newOrigin.x += x;
        newOrigin.y += y;
        
        
        [CSCaptureBase layoutModification:^{
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
            
            self.layer.position = newOrigin;
            
            [CATransaction commit];

        }];
    }
    
}


-(NSSize)size
{
    return self.layoutPosition.size;
}

-(NSPoint)origin
{
    return self.layoutPosition.origin;
}


-(float)opacity
{
    return _opacity;
}


-(void)setOpacity:(float)opacity
{
    _opacity = opacity;
    self.layer.opacity = _opacity;
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
        _currentLayer = nil;
    }
    
    NSObject <CSCaptureSourceProtocol> *newCaptureSession;
    
    Class captureClass = [pluginMap objectForKey:selectedVideoType];
    
    newCaptureSession = [[captureClass alloc] init];
    
    
    self.videoInput = newCaptureSession;
    [self registerVideoInput:self.videoInput];
    _currentLayer = [self.videoInput layerForInput:self];
    
    
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
    _currentLayer = [self.videoInput layerForInput:self];
    
}


-(void) makeSourcePrivate
{
    [self deregisterVideoInput:self.videoInput];
    self.videoInput = self.videoInput.copy;
    [self registerVideoInput:self.videoInput];
    _currentLayer = [self.videoInput layerForInput:self];
}


-(void)setScrollXSpeed:(float)scrollXSpeed
{
    self.layer.scrollXSpeed = scrollXSpeed;
    
}

-(float)scrollXSpeed
{
    return self.layer.scrollXSpeed;
}


-(void)setScrollYSpeed:(float)scrollYSpeed
{

    self.layer.scrollYSpeed = scrollYSpeed;
}


-(float)scrollYSpeed
{
    return self.layer.scrollYSpeed;
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
    self.layer.hidden = !active;
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

-(float) crop_left
{
    return _crop_left;
}


-(void) setCrop_left:(float)crop_left
{
    if (crop_left < 0)
    {
        _crop_left = 0;
    } else {
        _crop_left = crop_left;
    }
    
    [self setCropRect];
    
    
}

-(float) crop_right
{
    return _crop_right;
}


-(void) setCrop_right:(float)crop_right
{
    if (crop_right < 0)
    {
        _crop_right = 0;
    } else {
        _crop_right = crop_right;
    }
    [self setCropRect];

}

-(float) crop_top
{
    return _crop_top;
}


-(void) setCrop_top:(float)crop_top
{
    if (crop_top < 0)
    {
        _crop_top = 0;
    } else {
        _crop_top = crop_top;
    }
    [self setCropRect];

}

-(float) crop_bottom
{
    return _crop_bottom;
}


-(void) setCrop_bottom:(float)crop_bottom
{
    if (crop_bottom < 0)
    {
        _crop_bottom = 0;
    } else {
        _crop_bottom = crop_bottom;
    }
    [self setCropRect];

}


-(void)setChromaKeyColor:(NSColor *)chromaKeyColor
{
    _chromaKeyColor = chromaKeyColor;
    [self.layer.sourceLayer setValue:[[CIColor alloc] initWithColor:chromaKeyColor] forKeyPath:@"filters.Chromakey.inputColor"];
}

-(NSColor *)chromaKeyColor
{
    return _chromaKeyColor;
}

-(void)setChromaKeySmoothing:(float)chromaKeySmoothing
{
    _chromaKeySmoothing = chromaKeySmoothing;
    [self.layer.sourceLayer setValue:@(chromaKeySmoothing) forKeyPath:@"filters.Chromakey.inputSmoothing"];
}

-(float)chromaKeySmoothing
{
    return _chromaKeySmoothing;
}

-(void)setChromaKeyThreshold:(float)chromaKeyThreshold
{
    _chromaKeyThreshold = chromaKeyThreshold;
    [self.layer.sourceLayer setValue:@(chromaKeyThreshold) forKeyPath:@"filters.Chromakey.inputThreshold"];
}

-(float)chromaKeyThreshold
{
    return _chromaKeyThreshold;
}



-(void)setDoChromaKey:(bool)doChromaKey
{
    _doChromaKey = doChromaKey;

    [self.layer.sourceLayer setValue:[NSNumber numberWithBool:doChromaKey] forKeyPath:@"filters.Chromakey.enabled" ];
    if (doChromaKey)
    {
        [self.layer.sourceLayer setValue:[[CIColor alloc] initWithColor:self.chromaKeyColor] forKeyPath:@"filters.Chromakey.inputColor"];

        [self.layer.sourceLayer setValue:@(self.chromaKeySmoothing) forKeyPath:@"filters.Chromakey.inputSmoothing"];

        [self.layer.sourceLayer setValue:@(self.chromaKeyThreshold) forKeyPath:@"filters.Chromakey.inputThreshold"];

    }
    
}

-(bool)doChromaKey
{
    return _doChromaKey;
}



-(void) removeObjectFromVideoSourcesAtIndex:(NSUInteger)index
{
    id removedSource = [self.videoSources objectAtIndex:index];
    [self deregisterVideoInput:removedSource];
    [self.videoSources removeObjectAtIndex:index];
}




-(void)willDelete
{
    if (self.videoInput)
    {
        [self.videoInput willDelete];
    }
}


//I should probably use contexts...
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"editorController"]) {
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
