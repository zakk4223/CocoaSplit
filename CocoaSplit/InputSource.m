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
#import <objc/runtime.h>

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
@synthesize rotationAngleX = _rotationAngleX;
@synthesize rotationAngleY = _rotationAngleY;

@synthesize scrollXSpeed = _scrollXSpeed;
@synthesize scrollYSpeed = _scrollYSpeed;
@synthesize doChromaKey = _doChromaKey;
@synthesize chromaKeyColor = _chromaKeyColor;
@synthesize chromaKeySmoothing = _chromaKeySmoothing;
@synthesize chromaKeyThreshold = _chromaKeyThreshold;
@synthesize clonedFromInput = _clonedFromInput;
@synthesize transitionEnabled = _transitionEnabled;
@synthesize x_pos = _x_pos;
@synthesize y_pos = _y_pos;
@synthesize width = _width;
@synthesize height = _height;


-(instancetype)copyWithZone:(NSZone *)zone
{
    InputSource *newSource = [[InputSource allocWithZone:zone] init];
    
    newSource.videoInput = self.videoInput;
    [newSource registerVideoInput:self.videoInput];
    newSource->_currentLayer = [self.videoInput layerForInput:newSource];
    newSource.layer.sourceLayer = newSource->_currentLayer;
    
    newSource.rotationAngle = self.rotationAngle;
    newSource.rotationAngleY = self.rotationAngleY;
    newSource.rotationAngleX = self.rotationAngleX;
    newSource.opacity =  self.opacity;
    newSource.name = self.name;
    newSource.depth = self.depth;
    newSource.crop_top = self.crop_top;
    newSource.crop_bottom = self.crop_bottom;
    newSource.crop_left = self.crop_left;
    newSource.crop_right = self.crop_right;
    newSource.scrollXSpeed = self.scrollXSpeed;
    newSource.scrollYSpeed = self.scrollYSpeed;
    newSource.rotateStyle = self.rotateStyle;
    newSource.doChromaKey = self.doChromaKey;
    
    newSource.chromaKeyColor = self.chromaKeyColor;
    newSource.chromaKeyThreshold = self.chromaKeyThreshold;
    newSource.chromaKeySmoothing = self.chromaKeySmoothing;
    newSource.videoSources = self.videoSources;
    for(NSObject <CSCaptureSourceProtocol> *vsrc in newSource.videoSources)
    {
        [newSource registerVideoInput:vsrc];
    }
    
    newSource.transitionDuration = self.transitionDuration;
    newSource.transitionFilterName = self.transitionFilterName;
    newSource.transitionDirection = self.transitionDirection;
    

    
    newSource.changeInterval = self.changeInterval;
    newSource.layer.position = self.layer.position;
    newSource.layer.bounds = self.layer.bounds;
    newSource.borderWidth = self.borderWidth;
    newSource.borderColor = self.borderColor;
    newSource.cornerRadius  = self.cornerRadius;
    newSource.backgroundColor = self.backgroundColor;
    
    

    return newSource;
}



-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeFloat:self.rotationAngle forKey:@"rotationAngle"];
    [aCoder encodeFloat:self.rotationAngleX forKey:@"rotationAngleX"];
    [aCoder encodeFloat:self.rotationAngleY forKey:@"rotationAngleY"];

    [aCoder encodeFloat:self.opacity forKey:@"opacity"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeFloat:self.depth forKey:@"CAdepth"];
    [aCoder encodeFloat:self.crop_top forKey:@"CAcrop_top"];
    [aCoder encodeFloat:self.crop_bottom forKey:@"CAcrop_bottom"];
    [aCoder encodeFloat:self.crop_left forKey:@"CAcrop_left"];
    [aCoder encodeFloat:self.crop_right forKey:@"CAcrop_right"];
    [aCoder encodeObject:self.selectedVideoType forKey:@"selectedVideoType"];
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
    

    [aCoder encodeFloat:self.layer.position.x forKey:@"CAx_pos"];
    [aCoder encodeFloat:self.layer.position.y forKey:@"CAy_pos"];
    
    [aCoder encodeFloat:self.layer.bounds.size.width forKey:@"CAdisplay_width"];
    [aCoder encodeFloat:self.layer.bounds.size.height forKey:@"CAdisplay_height"];
    [aCoder encodeFloat:self.borderWidth forKey:@"borderWidth"];
    [aCoder encodeObject:self.borderColor forKey:@"borderColor"];
    [aCoder encodeFloat:self.cornerRadius forKey:@"cornerRadius"];
    [aCoder encodeBool:_userBackground forKey:@"userBackground"];
    [aCoder encodeObject:self.transitionFilterName forKey:@"transitionFilterName"];
    [aCoder encodeObject:self.transitionDirection forKey:@"transitionDirection"];
    [aCoder encodeFloat:self.transitionDuration forKey:@"transitionDuration"];
    
    [aCoder encodeObject:self.parentInput forKey:@"parentInput"];
    
    [aCoder encodeObject:self.constraintMap forKey:@"constraintMap"];
    
    [aCoder encodeObject:self.layer.filters forKey:@"layerFilters"];
    
    if (_userBackground)
    {
        [aCoder encodeObject:self.backgroundColor forKey:@"backgroundColor"];
    }
    
    
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    /*
    There's some 'legacy' stuff in here to support loading older CocoaSplit save formats. Mostly related to the change from CoreImage to CoreAnimation. some types changed, some stuff like x/y position changed names. It's probably a bit slower when you're saving->going live but meh. Problematic variables are encoded with a prefix of 'CA' to avoid excessive use of try/catch
     */
    
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
            //self.layer.sourceLayer = _currentLayer;
            if (!_userBackground)
            {
                self.backgroundColor = nil;
            }
        }
        
        


        float x_pos,y_pos,width,height;
        
        if ([aDecoder containsValueForKey:@"CAx_pos"])
        {
            x_pos = [aDecoder decodeFloatForKey:@"CAx_pos"];
            y_pos = [aDecoder decodeFloatForKey:@"CAy_pos"];

        } else {
        //at one point [xy]_pos was an integer, so if the float fails try integer. otherwise die.
            @try {
                x_pos = [aDecoder decodeFloatForKey:@"x_pos"];
                y_pos = [aDecoder decodeFloatForKey:@"y_pos"];
            } @catch (NSException *e) {
                x_pos = [aDecoder decodeIntForKey:@"x_pos"];
                y_pos = [aDecoder decodeIntForKey:@"y_pos"];
                
            }
        }
        
        if ([aDecoder containsValueForKey:@"CAdisplay_width"])
        {
            width = [aDecoder decodeFloatForKey:@"CAdisplay_width"];
            height = [aDecoder decodeFloatForKey:@"CAdisplay_height"];

            
        } else {
            width = [aDecoder decodeIntForKey:@"display_width"];
            height = [aDecoder decodeIntForKey:@"display_height"];
            
        }


        self.layer.position = CGPointMake(x_pos, y_pos);
        self.layer.bounds = CGRectMake(0, 0, width, height);
       
        

        
        _rotationAngle = [aDecoder decodeFloatForKey:@"rotationAngle"];
        _rotationAngleX = [aDecoder decodeFloatForKey:@"rotationAngleX"];
        _rotationAngleY = [aDecoder decodeFloatForKey:@"rotationAngleY"];
        [self updateRotationTransform];


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
        //Old Cocoasplit encoded this as an integer. CoreAnimation wants a float.
        if ([aDecoder containsValueForKey:@"CAdepth"])
        {
            self.depth = [aDecoder decodeFloatForKey:@"CAdepth"];

        } else {
            self.depth = [aDecoder decodeIntForKey:@"depth"];
        }
        
        if ([aDecoder containsValueForKey:@"CAcrop_top"])
        {
            self.crop_top = [aDecoder decodeFloatForKey:@"CAcrop_top"];
            self.crop_bottom = [aDecoder decodeFloatForKey:@"CAcrop_bottom"];
            self.crop_left = [aDecoder decodeFloatForKey:@"CAcrop_left"];
            self.crop_right = [aDecoder decodeFloatForKey:@"CAcrop_right"];
        } else {
            self.crop_top = [aDecoder decodeIntForKey:@"crop_top"];
            self.crop_bottom = [aDecoder decodeIntForKey:@"crop_bottom"];
            self.crop_left = [aDecoder decodeIntForKey:@"crop_left"];
            self.crop_right = [aDecoder decodeIntForKey:@"crop_right"];
        }

        
        
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

        
        self.transitionDirection = [aDecoder decodeObjectForKey:@"transitionDirection"];
        self.transitionFilterName = [aDecoder decodeObjectForKey:@"transitionFilterName"];
        self.transitionDuration = [aDecoder decodeFloatForKey:@"transitionDuration"];
        
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
        

        self.borderWidth = [aDecoder decodeFloatForKey:@"borderWidth"];
        self.borderColor = [aDecoder decodeObjectForKey:@"borderColor"];
        self.cornerRadius = [aDecoder decodeFloatForKey:@"cornerRadius"];
        self.layoutPosition = self.layer.frame;
        
        InputSource *parentInput = [aDecoder decodeObjectForKey:@"parentInput"];
        if (parentInput)
        {
            [parentInput.layer addSublayer:self.layer];
            [parentInput.attachedInputs addObject:self];
            self.parentInput = parentInput;
            
        }

        id restoredConstraintMap = [aDecoder decodeObjectForKey:@"constraintMap"];
        if (restoredConstraintMap)
        {
            self.constraintMap = restoredConstraintMap;
            [self buildLayerConstraints];
        }
        
        self.layer.filters = [aDecoder decodeObjectForKey:@"layerFilters"];
        

    }
    
    
    
    return self;
}

-(CGRect)globalLayoutPosition
{
    return [self.sourceLayout.rootLayer convertRect:self.layoutPosition fromLayer:self.layer.superlayer];
}

-(void) registerVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    forInput.inputSource = self;
    forInput.isLive = self.is_live;
    [forInput createNewLayerForInput:self];

}

-(void)deregisterVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    if (!forInput)
    {
        return;
    }
    
    forInput.isLive = NO;
    [forInput removeLayerForInput:self];
    
}



-(void)resetConstraints
{
    [self initDictionaryForConstraints:self.constraintMap];
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
    
    
    self.attachedInputs = [NSMutableArray array];
    
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
    
    self.constraintMap = [NSMutableDictionary dictionary];

    _constraintAttributeMap = @{@"LeftEdge": @(kCAConstraintMinX),
                                @"RightEdge": @(kCAConstraintMaxX),
                                @"TopEdge": @(kCAConstraintMaxY),
                                @"BottomEdge": @(kCAConstraintMinY),
                                @"HorizontalCenter": @(kCAConstraintMidX),
                                @"VerticalCenter": @(kCAConstraintMidY),
                                @"Width": @(kCAConstraintWidth),
                                @"Height": @(kCAConstraintHeight),
                                };

    [self initDictionaryForConstraints:self.constraintMap];
    
    
    NSMutableArray *tmpArr = [NSMutableArray array];
    
    for (NSString *base in self.constraintMap.allKeys)
    {
        [tmpArr addObject:[NSString stringWithFormat:@"constraintMap.%@.attr", base]];
        [tmpArr addObject:[NSString stringWithFormat:@"constraintMap.%@.offset", base]];
    }
    
    
    _constraintObserveKeys = tmpArr;
    
    
    self.transitionFilterName = @"fade";
    self.currentEffects = [[NSMutableArray alloc] init];
    
    self.unlock_aspect = NO;
    self.resizeType = kResizeNone;
    
    
    self.layer = [CSInputLayer layer];
    self.layer.contentsGravity = kCAGravityResizeAspect;
    
    self.layer.delegate = self;
    
    //self.layer.anchorPoint = CGPointMake(0.0, 0.0);
    
    //self.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);

    self.layer.bounds = CGRectMake(0.0, 0.0, 200, 200);
    [self positionOrigin:0.0 y:0.0];

    
    
    CIFilter *cFilter = [CIFilter filterWithName:@"CSChromaKeyFilter"];
    [cFilter setDefaults];
    cFilter.name = @"Chromakey";
    cFilter.enabled = NO;
    
    self.layer.sourceLayer.filters = @[cFilter];
    
    _multiTransition = [CATransition animation];
    _multiTransition.type = kCATransitionPush;
    _multiTransition.subtype = kCATransitionFromRight;
    _multiTransition.duration = 2.0;
    _multiTransition.removedOnCompletion = YES;
    
    
    
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);
    
   
    self.layoutPosition = self.layer.frame;
    self.active = YES;
    self.transitionNames = @[kCATransitionFade, kCATransitionPush, kCATransitionMoveIn, kCATransitionReveal, @"cube", @"alignedCube", @"flip", @"alignedFlip"];
    self.transitionDirections = @[kCATransitionFromTop, kCATransitionFromRight, kCATransitionFromBottom, kCATransitionFromLeft];
    self.transitionDirection = kCATransitionFromRight;
    self.transitionDuration = 2.0f;
    
    self.doChromaKey = NO;
    self.chromaKeyThreshold = 0.1005f;
    self.chromaKeySmoothing = 0.1344f;
    
    self.chromaKeyColor = [NSColor greenColor];
    _userBackground = NO;
    self.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);
    _currentInput = self;
    

    [self observeConstraintKeys];
 }



-(void)initDictionaryForConstraints:(NSMutableDictionary *)dict
{
    NSArray *baseKeys = @[@"LeftEdge", @"RightEdge", @"TopEdge", @"BottomEdge", @"HorizontalCenter", @"VerticalCenter", @"Width", @"Height"];
    
    
    for (NSString *base in baseKeys)
    {
        [dict setObject:[NSMutableDictionary dictionaryWithDictionary:@{@"attr": [NSNull null], @"offset": @0}] forKey:base];
    }
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
    if (self.layer.borderColor)
    {
        return [NSColor colorWithCGColor:self.layer.borderColor];
    } else {
        return nil;
    }
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


-(NSMutableArray *)newFilterArray:(NSArray *)filters withoutName:(NSString *)withoutName
{
    NSMutableArray *ret = [NSMutableArray array];
    
    for (CIFilter *filter in filters)
    {
        if ([filter.name isEqualToString:withoutName])
        {
            continue;
        }
        
        [ret addObject:filter];
    }
    
    return ret;
}


-(void)deleteLayerFilter:(NSString *)filteruuid
{
    self.layer.filters = [self newFilterArray:self.layer.filters withoutName:filteruuid];
}
-(void)deleteSourceFilter:(NSString *)filteruuid
{
    self.layer.sourceLayer.filters = [self newFilterArray:self.layer.sourceLayer.filters withoutName:filteruuid];
}

-(void)deleteBackgroundFilter:(NSString *)filteruuid
{
    self.layer.backgroundFilters = [self newFilterArray:self.layer.backgroundFilters withoutName:filteruuid];
}



-(void)addLayerFilter:(NSString *)filterName
{

    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        NSMutableArray *currentFilters = self.layer.filters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }

        [currentFilters addObject:newFilter];
        self.layer.filters = currentFilters;
    }
}

-(void)addSourceFilter:(NSString *)filterName
{
    
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        NSMutableArray *currentFilters = self.layer.sourceLayer.filters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }

        [currentFilters addObject:newFilter];
        self.layer.sourceLayer.filters = currentFilters;
    }
}

-(void)addBackgroundFilter:(NSString *)filterName
{
    
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        NSMutableArray *currentFilters = self.layer.backgroundFilters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }
        [currentFilters addObject:newFilter];
        self.layer.backgroundFilters = currentFilters;
    }
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
    
    return [pluginMap.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}



-(void)dealloc
{
    
    NSLog(@"DEALLOC SOURCE INPUT");
    [self deregisterVideoInput:self.videoInput];
    for(id vInput in self.videoSources)
    {
        [self deregisterVideoInput:vInput];
    }
    
    [self stopObservingConstraintKeys];
    
    
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
    self.layer.name = name;
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


//This is a dummy layer the animation scripts use to keep track of geometry changes without messing up the presentation/model layers
-(CALayer *)animationLayer
{
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    CALayer *nLayer = [CALayer layer];
    
    
    nLayer.position = self.layer.position;
    nLayer.bounds = self.layer.bounds;
    nLayer.transform = self.layer.transform;
    nLayer.hidden = self.layer.hidden;
    [nLayer setValue:@(self.layer.bounds.size.width) forKey:@"fakeWidth"];
    
    [CATransaction commit];

    return nLayer;
}


-(void)updateRotationTransform
{
    CATransform3D transform = CATransform3DMakeRotation(self.rotationAngle * M_PI / 180.0, 0.0, 0.0, 1.0);
    transform = CATransform3DRotate(transform, self.rotationAngleX * M_PI / 180.0, 1.0, 0.0, 0.0);
    transform = CATransform3DRotate(transform, self.rotationAngleY * M_PI / 180.0, 0.0, 1.0, 0.0);
    self.layer.disableAnimation = YES;
    self.layer.transform = transform;

    
    self.layer.disableAnimation  = NO;
}


-(void)setRotationAngle:(float)rotationAngle
{
    _rotationAngle = rotationAngle;
    
    [self updateRotationTransform];
}


-(float)rotationAngle
{
    return _rotationAngle;
}

-(void)setRotationAngleX:(float)rotationAngleX
{
    _rotationAngleX = rotationAngleX;
    
    [self updateRotationTransform];
}


-(float)rotationAngleX
{
    return _rotationAngleX;
}

-(void)setRotationAngleY:(float)rotationAngleY
{
    _rotationAngleY = rotationAngleY;
    
    [self updateRotationTransform];
}


-(float)rotationAngleY
{
    return _rotationAngleY;
}


-(void)setCropRect
{
    CGRect contentsRect = self.layer.contentsRect;
    contentsRect.origin.x = self.crop_left;
    contentsRect.origin.y = self.crop_bottom;
    contentsRect.size.width = 1.0 - self.crop_right - self.crop_left;
    contentsRect.size.height = 1.0 - self.crop_top - self.crop_bottom;
    
        self.layer.cropRect = contentsRect;
    
}



-(void)setTransitionEnabled:(bool)transitionEnabled
{
    _transitionEnabled = transitionEnabled;
    
    if (transitionEnabled)
    {
        for (InputSource *inp in self.attachedInputs)
        {
            inp.layer.hidden = YES;
        }
    } else {
        for (InputSource *inp in self.attachedInputs)
        {
            inp.layer.hidden = NO;
        }
        [self.layer transitionsDisabled];
    }
}


-(bool)transitionEnabled
{
    return _transitionEnabled;
}


-(void) setAdvancedTransitionName:(NSString *)advancedTransitionName
{
    CIFilter *newTransition = [CIFilter filterWithName:advancedTransitionName];
    [newTransition setDefaults];
    self.advancedTransition = newTransition;
    
}


-(NSString *)advancedTransitionName
{
    if (self.advancedTransition)
    {
        return self.advancedTransition.className;
    }
    
    return nil;
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
    
    if (!self.transitionEnabled)
    {
        return;
    }

    
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

    NSMutableArray *chooseInputs = [NSMutableArray arrayWithArray:self.attachedInputs];
    [chooseInputs addObject:self];
    
    InputSource *_nextInput;
    
    
    
    if (chooseInputs.count > 1 && (currentTime >= _nextImageTime) && (self.changeInterval > 0) )
    {
        switch (self.rotateStyle)
        {
            case kRotateNormal:
                _currentSourceIdx++;
                if (_currentSourceIdx == chooseInputs.count)
                {
                    _currentSourceIdx = 0;
                }
                break;
            case kRotateRandom:
                _currentSourceIdx = (unsigned int)arc4random_uniform((unsigned int)chooseInputs.count);
            case kRotateReverse:
                _currentSourceIdx--;
                if (_currentSourceIdx < 0)
                {
                    _currentSourceIdx = (int)chooseInputs.count-1;
                }
                break;
            default:
                break;
        }
        _nextImageTime = currentTime + self.changeInterval;
        _nextInput = [chooseInputs objectAtIndex:_currentSourceIdx];
        
        _multiTransition.type = self.transitionFilterName;
        _multiTransition.duration = self.transitionDuration;
        _multiTransition.subtype = self.transitionDirection;
        _multiTransition.filter = self.advancedTransition.copy;
        
        [self.layer transitionToLayer:_nextInput.layer fromLayer:_currentInput.layer withTransition:_multiTransition];
        _currentInput = _nextInput;
        
        

    }
}


-(void)setWidth:(float)width
{
    _width = width;
    [self updateSize:_width height:_height];
}

-(float)width
{
    return _width;
}

-(void)setHeight:(float)height
{
    _height = height;
    [self updateSize:_width height:_height];
}

-(float)height
{
    return _height;
}


-(void)setX_pos:(float)x_pos
{
    _x_pos = x_pos;
    
    [self positionOrigin:_x_pos y:_y_pos];
}

-(float)x_pos
{
    return _x_pos;
}

-(void)setY_pos:(float)y_pos
{
    _y_pos = y_pos;
    [self positionOrigin:_x_pos y:_y_pos];
}



-(float)y_pos
{
    return _y_pos;
}


-(void)frameTick
{
    
    self.layoutPosition = self.layer.frame;
    _x_pos = self.layer.frame.origin.x;
    _y_pos = self.layer.frame.origin.y;
    _width = self.layer.frame.size.width;
    _height = self.layer.frame.size.height;
    
    [self multiChange];
    
    if (!self.videoInput)
    {
        return;
    }
    
    
    
    if (self.layer.sourceLayer != _currentLayer)
    {
        if (!_userBackground)
        {
            self.backgroundColor = nil;
            _userBackground = NO;
        }
        
        self.layer.allowResize = self.videoInput.allowScaling;
        
        self.layer.sourceLayer = _currentLayer;

        
    }
    [self.videoInput frameTick];
    [self.layer frameTick];

}



-(void)autoFit
{

    
    NSMutableDictionary *newConstraints = [NSMutableDictionary dictionary];
    
    [self initDictionaryForConstraints:newConstraints];
    
    newConstraints[@"HorizontalCenter"][@"attr"] = @(kCAConstraintMidX);
    newConstraints[@"Width"][@"attr"] = @(kCAConstraintWidth);
    newConstraints[@"VerticalCenter"][@"attr"] = @(kCAConstraintMidY);
    newConstraints[@"Height"][@"attr"] = @(kCAConstraintHeight);
    self.constraintMap = newConstraints;
    
    [self buildLayerConstraints];
    //self.layer.bounds = self.layer.superlayer.bounds;
    //self.layer.position = CGPointMake(self.layer.bounds.size.width/2, self.layer.bounds.size.height/2);

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
        
            self.layer.allowResize = tmpResize;
            self.layer.frame = newLayout;
            self.layer.allowResize = oldResize;
        
    }
}



-(void)detachAllInputs
{
    NSArray *aCopy = self.attachedInputs.copy;
    
    for (InputSource *inp in aCopy)
    {
        [self detachInput:inp];
    }
}


-(void)detachInput:(InputSource *)toDetach
{
    if (!toDetach.parentInput)
    {
        return;
    }
    
    if (toDetach.parentInput != self)
    {
        return;
    }

    toDetach.parentInput = nil;
    [self.sourceLayout.rootLayer addSublayer:toDetach.layer];
    toDetach.layer.hidden = NO;
    
    //translate the position to the new sublayers coordinates
    
    
    NSPoint newPosition = [self.sourceLayout.rootLayer convertPoint:toDetach.layer.position fromLayer:self.layer];
    toDetach.layer.position = newPosition;

    
    [self.attachedInputs removeObject:toDetach];
}


-(void)attachInput:(InputSource *)toAttach
{
    if (toAttach.parentInput)
    {
        if (toAttach.parentInput == self)
        {
            return;
        }
        
        [toAttach.parentInput detachInput:toAttach];
    }
    
    [toAttach makeSublayerOfLayer:self.layer];
    [self.attachedInputs addObject:toAttach];
    toAttach.parentInput = self;
}


-(void)makeSublayerOfLayer:(CALayer *)parentLayer
{
    
    
    [parentLayer addSublayer:self.layer];
    //translate the position to the new sublayers coordinates
    NSPoint newPosition = [parentLayer convertPoint:self.layer.position fromLayer:parentLayer.superlayer];
    self.layer.position = newPosition;

}


-(void) positionOrigin:(CGFloat)x y:(CGFloat)y
{
    
    if (self.layer)
    {
        
        NSRect newFrame = self.layer.frame;
        newFrame.origin.x = x;
        newFrame.origin.y = y;
        self.layer.frame = newFrame;
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
        
        
            //[CATransaction begin];
            //[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        self.layer.disableAnimation = YES;
            self.layer.position = newOrigin;
        self.layer.disableAnimation = NO;
            
            //[CATransaction commit];

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
    
    newCaptureSession = nil;
    
    _selectedVideoType = selectedVideoType;
    
}


-(NSViewController *)sourceConfigurationView;
{
    
    NSViewController *vcont = nil;
    if (self.videoInput && [self.videoInput respondsToSelector:@selector(configurationView)])
    {
        vcont = [self.videoInput configurationView];
    }
    
    if (vcont)
    {
        [vcont setValue:self.videoInput forKey:@"captureObj"];
    }
    
    return vcont;
}

-(void) editorPopoverDidClose
{
    return;
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
    return self.sourceLayout.canvas_width;
}

-(size_t)canvas_height
{
    return self.sourceLayout.canvas_height;
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
    _currentInput = nil;
}


-(void) buildLayerConstraints
{
    
    
    NSMutableArray *constraints = [NSMutableArray array];
    
    for (NSString *key in self.constraintMap)
    {
        
        
        NSNumber *constraintVal;
        constraintVal = _constraintAttributeMap[key];
        
        if (!constraintVal)
        {
            continue;
        }
        
        CAConstraintAttribute toConstrain = [constraintVal intValue];
        NSDictionary *valMap = self.constraintMap[key];
        if (!valMap)
        {
            continue;
        }
        NSNumber *parentVal = valMap[@"attr"];
        NSNumber *offsetVal = valMap[@"offset"];
        
        if (!parentVal || (id)parentVal == [NSNull null])
        {
            continue;
        }
        
        CGFloat offsetFloat = 0.0;
        
        if (offsetVal)
        {
            offsetFloat = [offsetVal floatValue];
        }
        
        CAConstraintAttribute parentAttrib = [parentVal intValue];
        [constraints addObject:[CAConstraint constraintWithAttribute:toConstrain relativeTo:@"superlayer" attribute:parentAttrib scale:1 offset:offsetFloat]];
        
    }
    
    self.layer.constraints = constraints;
}


//I should probably use contexts...
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

    if ([keyPath hasPrefix:@"constraintMap"])
    {
        [self buildLayerConstraints];
    }
}


-(void)setClonedFromInput:(InputSource *)clonedFromInput
{
    NSObject <CSCaptureSourceProtocol>*fromInput = clonedFromInput.videoInput;
    
    if (self.videoInput)
    {
        [self deregisterVideoInput:fromInput];
        _currentLayer = nil;
    }
    
    
    if (fromInput)
    {
        self.videoInput = fromInput;
        [self registerVideoInput:fromInput];
        _currentLayer = [fromInput layerForInput:self];
    }
    
    
    _clonedFromInput = clonedFromInput;
}


-(InputSource *)clonedFromInput
{
    return _clonedFromInput;
}



-(void)stopObservingConstraintKeys
{
    for (NSString *key in _constraintObserveKeys)
    {
        [self removeObserver:self forKeyPath:key];
    }
}



-(void)observeConstraintKeys
{
    for (NSString *key in _constraintObserveKeys)
    {
        [self addObserver:self forKeyPath:key options:NSKeyValueObservingOptionNew context:NULL];
    }
}




@end
