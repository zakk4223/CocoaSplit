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
@synthesize compositingFilterName = _compositingFilterName;


-(instancetype)copyWithZone:(NSZone *)zone
{
    [CATransaction begin];
    InputSource *newSource = [[InputSource allocWithZone:zone] init];
    newSource.name = _editedName;

    newSource.videoInput = self.videoInput;
    [newSource registerVideoInput:self.videoInput];
    newSource->_currentLayer = [self.videoInput layerForInput:newSource];
    newSource.layer.sourceLayer = newSource->_currentLayer;
    
    newSource.rotationAngle = self.rotationAngle;
    newSource.rotationAngleY = self.rotationAngleY;
    newSource.rotationAngleX = self.rotationAngleX;
    newSource.opacity =  self.opacity;
    
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
    newSource.advancedTransition = self.advancedTransition;
    
    

    
    newSource.changeInterval = self.changeInterval;
    newSource.layer.position = self.layer.position;
    newSource.layer.bounds = self.layer.bounds;
    newSource.borderWidth = self.borderWidth;
    newSource.borderColor = self.borderColor;
    newSource.cornerRadius  = self.cornerRadius;
    newSource.backgroundColor = self.backgroundColor;
    
    
    newSource.startColor = self.startColor;
    newSource.stopColor = self.stopColor;
    newSource.gradientStartX = self.gradientStartX;
    newSource.gradientStartY = self.gradientStartY;
    newSource.gradientStopX = self.gradientStopX;
    newSource.gradientStopY = self.gradientStopY;

    [CATransaction commit];
    return newSource;
}




-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.rotationAngle forKey:@"rotationAngle"];
    [aCoder encodeFloat:self.rotationAngleX forKey:@"rotationAngleX"];
    [aCoder encodeFloat:self.rotationAngleY forKey:@"rotationAngleY"];
    [aCoder encodeFloat:self.opacity forKey:@"opacity"];
    [aCoder encodeObject:_editedName forKey:@"name"];
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
    
    if (self.sourceLayout)
    {
        [aCoder encodeFloat:self.canvas_width forKey:@"topLevelWidth"];
        [aCoder encodeFloat:self.canvas_height forKey:@"topLevelHeight"];
    } else {
        [aCoder encodeFloat:_topLevelWidth forKey:@"topLevelWidth"];
        [aCoder encodeFloat:_topLevelHeight forKey:@"topLevelHeight"];
    }
    
    
    [aCoder encodeBool:self.doChromaKey forKey:@"doChromaKey"];
    [aCoder encodeObject:self.chromaKeyColor forKey:@"chromaKeyColor"];
    [aCoder encodeFloat:self.chromaKeyThreshold forKey:@"chromaKeyThreshold"];
    [aCoder encodeFloat:self.chromaKeySmoothing forKey:@"chromaKeySmoothing"];
    [aCoder encodeObject:self.videoSources forKey:@"videoSources"];
    [aCoder encodeObject:self.currentEffects forKey:@"currentEffects"];
    [aCoder encodeFloat:self.changeInterval forKey:@"changeInterval"];

    
    [aCoder encodeFloat:self.sceneNode.position.x forKey:@"CAx_pos"];
    [aCoder encodeFloat:self.sceneNode.position.y forKey:@"CAy_pos"];
    
    
    [aCoder encodeFloat:self.globalLayoutPosition.size.width forKey:@"CAdisplay_width"];
    [aCoder encodeFloat:self.globalLayoutPosition.size.height forKey:@"CAdisplay_height"];
    [aCoder encodeFloat:self.borderWidth forKey:@"borderWidth"];
    [aCoder encodeObject:self.borderColor forKey:@"borderColor"];
    [aCoder encodeFloat:self.cornerRadius forKey:@"cornerRadius"];
    [aCoder encodeBool:_userBackground forKey:@"userBackground"];
    [aCoder encodeObject:self.transitionFilterName forKey:@"transitionFilterName"];
    [aCoder encodeObject:self.transitionDirection forKey:@"transitionDirection"];
    [aCoder encodeFloat:self.transitionDuration forKey:@"transitionDuration"];
    [aCoder encodeObject:self.advancedTransition forKey:@"advancedTransition"];
    
    [aCoder encodeObject:self.parentInput forKey:@"parentInput"];
    
    
    //if we directly encode constraintMap the resulting NSData is not equal to an 'equal' InputSource, so double encode?
    
    NSData *constraintData = [NSKeyedArchiver archivedDataWithRootObject:self.constraintMap];

    [aCoder encodeObject:constraintData forKey:@"constraintMapData"];
    
    //[aCoder encodeObject:self.constraintMap forKey:@"constraintMap"];
    
    [aCoder encodeObject:self.startColor forKey:@"gradientStartColor"];
    [aCoder encodeObject:self.stopColor forKey:@"gradientStopColor"];
    [aCoder encodeFloat: self.gradientStartX forKey:@"gradientStartPointX"];
    [aCoder encodeFloat: self.gradientStartY forKey:@"gradientStartPointY"];
    [aCoder encodeFloat: self.gradientStopX forKey:@"gradientEndPointX"];
    [aCoder encodeFloat: self.gradientStopY forKey:@"gradientEndPointY"];

    
    [aCoder encodeObject:self.layer.filters forKey:@"layerFilters"];
    if (_userBackground)
    {
        [aCoder encodeObject:self.backgroundColor forKey:@"backgroundColor"];
    }
    
    [aCoder encodeObject:self.compositingFilterName forKey:@"compositingFilterName"];
    
    [aCoder encodeBool:self.alwaysDisplay forKey:@"alwaysDisplay"];
    [aCoder encodeBool:self.transitionEnabled forKey:@"transitionEnabled"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    /*
    There's some 'legacy' stuff in here to support loading older CocoaSplit save formats. Mostly related to the change from CoreImage to CoreAnimation. some types changed, some stuff like x/y position changed names. It's probably a bit slower when you're saving->going live but meh. Problematic variables are encoded with a prefix of 'CA' to avoid excessive use of try/catch
     */
    
    if (self = [super init])
    {
        
        [CATransaction begin];
        [self commonInit];
        
        
        _userBackground = [aDecoder decodeBoolForKey:@"userBackground"];
        if (_userBackground)
        {
            self.backgroundColor = [aDecoder decodeObjectForKey:@"backgroundColor"];
        }

        
        self.videoInput = [aDecoder decodeObjectForKey:@"videoInput"];

        if (self.videoInput)
        {
            
            [self registerVideoInput:self.videoInput];

            _currentLayer = [self.videoInput layerForInput:self];
            //self.layer.sourceLayer = _currentLayer;
            if (!_userBackground)
            {
                self.backgroundColor = nil;
                _userBackground = NO;
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


        NSRect tmpRect = NSIntegralRect(NSMakeRect(x_pos, y_pos, width, height));
        if (self.sceneNode)
        {
            self.sceneNode.position = SCNVector3Make(tmpRect.origin.x, tmpRect.origin.y, 0);
            [self directSize:tmpRect.size.width height:tmpRect.size.height];
        }
        



        id constraintData = [aDecoder decodeObjectForKey:@"constraintMap"];
        if (constraintData)
        {
            self.constraintMap = constraintData;
        } else if ((constraintData = [aDecoder decodeObjectForKey:@"constraintMapData"])) {
            self.constraintMap = [NSKeyedUnarchiver unarchiveObjectWithData:constraintData];
        }
        
        
        
        
        _rotationAngle = [aDecoder decodeFloatForKey:@"rotationAngle"];
        _rotationAngleX = [aDecoder decodeFloatForKey:@"rotationAngleX"];
        _rotationAngleY = [aDecoder decodeFloatForKey:@"rotationAngleY"];
        [self updateRotationTransform];


        
        

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
            _crop_top = [aDecoder decodeFloatForKey:@"CAcrop_top"];
            _crop_bottom = [aDecoder decodeFloatForKey:@"CAcrop_bottom"];
            _crop_left = [aDecoder decodeFloatForKey:@"CAcrop_left"];
            _crop_right = [aDecoder decodeFloatForKey:@"CAcrop_right"];
            [self setCropRectWithoutResize];
        } else {
            _crop_top = [aDecoder decodeIntForKey:@"crop_top"];
            _crop_bottom = [aDecoder decodeIntForKey:@"crop_bottom"];
            _crop_left = [aDecoder decodeIntForKey:@"crop_left"];
            _crop_right = [aDecoder decodeIntForKey:@"crop_right"];
            [self setCropRectWithoutResize];
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
        self.advancedTransition = [aDecoder decodeObjectForKey:@"advancedTransition"];
        
        
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
        

        
        self.startColor = [aDecoder decodeObjectForKey:@"gradientStartColor"];
        self.stopColor = [aDecoder decodeObjectForKey:@"gradientStopColor"];
        
        
        self.gradientStartX = [aDecoder decodeFloatForKey:@"gradientStartPointX"];
        self.gradientStartY = [aDecoder decodeFloatForKey:@"gradientStartPointY"];
        
        self.gradientStopX = [aDecoder decodeFloatForKey:@"gradientEndPointX"];
        self.gradientStopY = [aDecoder decodeFloatForKey:@"gradientEndPointY"];
        
        
        if ([aDecoder containsValueForKey:@"topLevelWidth"])
        {
            _topLevelWidth = [aDecoder decodeFloatForKey:@"topLevelWidth"];
        }
        
        if ([aDecoder containsValueForKey:@"topLevelHeight"])
        {
            _topLevelHeight = [aDecoder decodeFloatForKey:@"topLevelHeight"];
        }
        
        
        self.layer.filters = [aDecoder decodeObjectForKey:@"layerFilters"];
        self.compositingFilterName = [aDecoder decodeObjectForKey:@"compositingFilterName"];
        if ([aDecoder containsValueForKey:@"alwaysDisplay"])
        {
            self.alwaysDisplay = [aDecoder decodeBoolForKey:@"alwaysDisplay"];
        }

        if ([aDecoder containsValueForKey:@"transitionEnabled"])
        {
            self.transitionEnabled = [aDecoder decodeBoolForKey:@"transitionEnabled"];
        }
        
        [CATransaction commit];

        InputSource *parentInput = [aDecoder decodeObjectForKey:@"parentInput"];
        self.parentInput = parentInput;
        
        if (self.parentInput)
        {
            
            [self.parentInput.layer addSublayer:self.layer];
            [self.parentInput.attachedInputs addObject:self];
        }

        
    }
    self.geometryNode.name = self.uuid;

    return self;
}



-(void)addedToLayout
{
    
    if (self.parentInput)
    {
        
        [self.parentInput.layer addSublayer:self.layer];
        [self.parentInput.attachedInputs addObject:self];
    }

}


-(CGRect)globalLayoutPosition
{
    
    return self.layoutPosition;
    
    //return CGRectMake(self.sceneNode.position.x, self.sceneNode.position.y, self.scenePlane.width, self.scenePlane.height);
    
    //return [self.sourceLayout.rootLayer convertRect:self.layer.frame fromLayer:self.layer.superlayer];
}

-(void) registerVideoInput:(NSObject<CSCaptureSourceProtocol> *)forInput
{
    forInput.inputSource = self;
    forInput.isLive = self.is_live;
    [forInput addObserver:self forKeyPath:@"captureName" options:NSKeyValueChangeNewKey context:NULL];
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
    [forInput removeObserver:self forKeyPath:@"captureName"];
    
}



-(void)restoreConstraints
{
    self.constraintMap = _restoredConstraintMap;
    _restoredConstraintMap = nil;
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

    [CATransaction begin];
    self.name = nil;
    self.scriptStorage = [NSMutableDictionary dictionary];
    _nextImageTime = 0.0f;
    _currentSourceIdx = 0;
    _needsAdjustment = NO;
    _needsAdjustPosition = NO;
    _topLevelHeight = 0;
    _topLevelWidth = 0;
    
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
    _refCount = 0;
    
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
    //self.layer.contentsGravity = kCAGravityTopRight;
    
    self.layer.sourceInput = self;
    
   // self.layer.anchorPoint = CGPointMake(0.0, 0.0);
    
    self.layer.backgroundColor = CGColorCreateGenericRGB(0, 0, 1, 1);

   self.layer.frame = CGRectMake(0.0, 0.0, 200, 200);
  //  self.layer.position = CGPointMake(0, 0);
    
    [self positionOrigin:0.0 y:0.0];
    
    [self createUUID];

    self.sceneNode = [SCNNode node];
    self.geometryNode = [SCNNode node];
    
    self.geometryNode.geometry = [SCNPlane planeWithWidth:1 height:1];
    
    self.sceneNode.position = SCNVector3Make(0,0, 0);
    
    //self.scenePlane = (SCNPlane *)self.geometryNode.geometry;
    self.geometryNode.geometry.firstMaterial.diffuse.contents = self.layer;
    self.geometryNode.geometry.firstMaterial.diffuse.wrapS = SCNWrapModeRepeat;
    self.geometryNode.geometry.firstMaterial.diffuse.wrapT = SCNWrapModeRepeat;
    self.geometryNode.geometry.firstMaterial.doubleSided = YES;
    [self.sceneNode addChildNode:self.geometryNode];
    
    self.geometryNode.name = self.uuid;


    [self directSize:200 height:200];
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
    [CATransaction commit];
    _undoActionMap = @{@"name": @"Set Name",
                       @"crop_top": @"Crop Top",
                       @"changeInterval": @"Change Interval",
                       @"gradientStartX": @"Gradient Start Color X",
                       @"gradientStartY": @"Gradient Start Color Y",
                       @"gradientStopX": @"Gradient Stop Color X",
                       @"gradientStopY": @"Gradient Stop Color Y",
                       @"startColor": @"Gradient Start Color",
                       @"stopColor": @"Gradient Stop Color",
                       @"backgroundColor": @"Background Color",
                       @"borderColor": @"Border Color",
                       @"cornerRadius": @"Border Corner Radius",
                       @"borderWidth": @"Border Width",
                       @"compositingFilterName": @"Composition Filter",
                       @"rotationAngle": @"Rotation",
                       @"rotationAngleX": @"X Rotation",
                       @"rotationAngleY": @"Y Rotation",
                       @"transitionDuration": @"Effect Duration",
                       @"transitionDirection": @"Transition Direction",
                       @"transitionEnabled": @"Enable Transitions",
                       @"alwaysDisplay": @"Always Show",
                       @"transitionFilterName": @"Transition Effect",
                       @"width": @"Width",
                       @"height": @"Height",
                       @"opacity": @"Opacity",
                       @"scrollXSpeed": @"Horizontal Scroll Speed",
                       @"scrollYSpeed": @"Vertical Scroll Speed",
                       @"crop_left": @"Crop Left",
                       @"crop_right": @"Crop Right",
                       @"crop_bottom": @"Crop Bottom",
                       @"chromaKeyColor": @"Chroma Key Color",
                       @"chromaKeySmoothing": @"CK Smoothing",
                       @"chromaKeyThreshold": @"CK Threshold",
                       @"rotateStyle": @"Order",
                       };
    
 }



-(void)createUUID
{
    CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
    self.uuid = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
    CFRelease(tmpUUID);

}

-(void)setRotateStyle:(input_rotate_style)rotateStyle
{
    _rotateStyle = rotateStyle;
}

-(input_rotate_style)rotateStyle
{
    return _rotateStyle;
}


-(void)setChangeInterval:(float)changeInterval
{
    
    _changeInterval = changeInterval;
}

-(float)changeInterval
{
    return _changeInterval;
}


-(void)initDictionaryForConstraints:(NSMutableDictionary *)dict
{
    NSArray *baseKeys = @[@"LeftEdge", @"RightEdge", @"TopEdge", @"BottomEdge", @"HorizontalCenter", @"VerticalCenter", @"Width", @"Height"];
    
    
    for (NSString *base in baseKeys)
    {
        NSMutableDictionary *valDict = [[NSMutableDictionary alloc] init];
        [valDict setObject:[NSNumber numberWithInt:0] forKey:@"attr"];
        [valDict setObject:[NSNumber numberWithInt:0] forKey:@"offset"];
        [dict setObject:valDict forKey:base];
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
    return self.geometryNode.renderingOrder;
}


-(void)setDepth:(float)depth
{
    
    self.geometryNode.renderingOrder = depth;
    
}




-(void)setGradientStartX:(CGFloat)gradientStartX
{
    self.layer.gradientStartX = gradientStartX;
}

-(CGFloat)gradientStartX
{
    return self.layer.gradientStartX;
}

-(void)setGradientStartY:(CGFloat)gradientStartY
{
    self.layer.gradientStartY = gradientStartY;
}

-(CGFloat)gradientStartY
{
    return self.layer.gradientStartY;
}

-(void)setGradientStopX:(CGFloat)gradientStopX
{
    self.layer.gradientStopX = gradientStopX;
}

-(CGFloat)gradientStopX
{
    return self.layer.gradientStopX;
}

-(void)setGradientStopY:(CGFloat)gradientStopY
{
    self.layer.gradientStopY = gradientStopY;
}

-(CGFloat)gradientStopY
{
    return self.layer.gradientStopY;
}

-(NSColor *)startColor
{
    return self.layer.startColor;
}


-(void)setStartColor:(NSColor *)startColor
{

    self.layer.startColor = startColor;
}

-(NSColor *)stopColor
{
    return self.layer.stopColor;
}


-(void)setStopColor:(NSColor *)stopColor
{
    
    self.layer.stopColor = stopColor;
}


-(void)clearBackground
{
    self.backgroundColor = nil;
    _userBackground = YES;
}


-(void)setBackgroundColor:(NSColor *)backgroundColor
{
    

    [CATransaction begin];
    _userBackground = YES;

    if (backgroundColor)
    {
        self.layer.backgroundColor = [backgroundColor CGColor];
    } else {
        self.layer.backgroundColor = NULL;
    }
    [CATransaction commit];
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

    [CATransaction begin];
    self.layer.borderColor = [borderColor CGColor];
    [CATransaction commit];
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

    [CATransaction begin];
    self.layer.cornerRadius = cornerRadius;
    [CATransaction commit];
}

-(CGFloat)cornerRadius
{
    return self.layer.cornerRadius;
}


-(void)setBorderWidth:(CGFloat)borderWidth
{
    
    
    
    [CATransaction begin];
    self.layer.borderWidth = borderWidth;
    [CATransaction commit];
    
}

-(CGFloat)borderWidth
{
    return self.layer.borderWidth;
}


-(NSString *)compositingFilterName
{
    return _compositingFilterName;
}

-(void)setCompositingFilterName:(NSString *)compositingFilterName
{
    
    CIFilter *newFilter = nil;
    if (compositingFilterName)
    {
        newFilter = [CIFilter filterWithName:compositingFilterName];
    }
    [CATransaction begin];
    self.layer.compositingFilter = newFilter;
    [CATransaction commit];
    _compositingFilterName = compositingFilterName;
}


-(void)setIsMaskLayer:(bool)isMaskLayer
{
    

    [self.sourceLayout.undoManager disableUndoRegistration];
    if (isMaskLayer)
    {
        self.compositingFilterName = @"CIMinimumCompositing";
    } else if ([self.compositingFilterName isEqualToString:@"CIMinimumCompositing"]) {
        self.compositingFilterName = nil;
    }
    [self.sourceLayout.undoManager enableUndoRegistration];
    
}


-(bool)isMaskLayer
{
    return [self.compositingFilterName isEqualToString:@"CIMinimumCompositing"];
}



-(CIFilter *) filter:(NSString *)filterUUID fromArray:(NSArray *)fromArray
{
    
    CIFilter *ret = nil;
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CIFilter *obj = (CIFilter *)evaluatedObject;
        return [obj.name isEqualToString:filterUUID];
    }];
    
    NSArray *results = [fromArray filteredArrayUsingPredicate:predicate];
    if (results)
    {
        ret = results.firstObject;
    }
    
    return ret;
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
    CIFilter *toDelete = [self filter:filteruuid fromArray:self.layer.filters];
    if (toDelete)
    {
        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:toDelete];
        __weak InputSource *weakSelf = self;
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            CIFilter *newFilter = [NSKeyedUnarchiver unarchiveObjectWithData:saveData];
            NSMutableArray *cFilters = weakSelf.layer.filters.mutableCopy;
            if (!cFilters)
            {
                cFilters = [NSMutableArray array];
            }
            [cFilters addObject:newFilter];
            [CATransaction begin];
            weakSelf.layer.filters = cFilters;
            [CATransaction commit];
            [[self.sourceLayout.undoManager prepareWithInvocationTarget:weakSelf.sourceLayout] modifyUUID:weakSelf.uuid withBlock:^(InputSource *input) {
                [input deleteLayerFilter:newFilter.name];
            }];
            [self.sourceLayout.undoManager setActionName:@"Add Input Filter"];
            
            
            
        }];
        [self.sourceLayout.undoManager setActionName:@"Delete Input Filter"];
        
    }

    [CATransaction begin];
    self.layer.filters = [self newFilterArray:self.layer.filters withoutName:filteruuid];
    [CATransaction commit];
}

-(void)deleteSourceFilter:(NSString *)filteruuid
{
    CIFilter *toDelete = [self filter:filteruuid fromArray:self.layer.sourceLayer.filters];
    if (toDelete)
    {
        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:toDelete];
        __weak InputSource *weakSelf = self;
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            CIFilter *newFilter = [NSKeyedUnarchiver unarchiveObjectWithData:saveData];
            NSMutableArray *cFilters = weakSelf.layer.sourceLayer.filters.mutableCopy;
            if (!cFilters)
            {
                cFilters = [NSMutableArray array];
            }
            [cFilters addObject:newFilter];
            [CATransaction begin];
            weakSelf.layer.sourceLayer.filters = cFilters;
            [CATransaction commit];
            [[self.sourceLayout.undoManager prepareWithInvocationTarget:weakSelf.sourceLayout] modifyUUID:weakSelf.uuid withBlock:^(InputSource *input) {
                [input deleteSourceFilter:newFilter.name];
            }];
            [self.sourceLayout.undoManager setActionName:@"Add Source Filter"];
            
            
            
        }];
        [self.sourceLayout.undoManager setActionName:@"Delete Source Filter"];
        
    }

    [CATransaction begin];
    self.layer.sourceLayer.filters = [self newFilterArray:self.layer.sourceLayer.filters withoutName:filteruuid];
    [CATransaction commit];
}

-(void)deleteBackgroundFilter:(NSString *)filteruuid
{
    CIFilter *toDelete = [self filter:filteruuid fromArray:self.layer.backgroundFilters];
    if (toDelete)
    {
        NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:toDelete];
        __weak InputSource *weakSelf = self;
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            CIFilter *newFilter = [NSKeyedUnarchiver unarchiveObjectWithData:saveData];
            NSMutableArray *cFilters = weakSelf.layer.backgroundFilters.mutableCopy;
            if (!cFilters)
            {
                cFilters = [NSMutableArray array];
            }
            [cFilters addObject:newFilter];
            [CATransaction begin];
            weakSelf.layer.backgroundFilters = cFilters;
            [CATransaction commit];
            [[self.sourceLayout.undoManager prepareWithInvocationTarget:weakSelf.sourceLayout] modifyUUID:weakSelf.uuid withBlock:^(InputSource *input) {
                [input deleteBackgroundFilter:newFilter.name];
            }];
            [self.sourceLayout.undoManager setActionName:@"Add Background Filter"];



        }];
        [self.sourceLayout.undoManager setActionName:@"Delete Background Filter"];
        
    }
    
    [CATransaction begin];
    self.layer.backgroundFilters = [self newFilterArray:self.layer.backgroundFilters withoutName:filteruuid];
    [CATransaction commit];
}



-(NSString *)addLayerFilter:(NSString *)filterName
{

    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            [input deleteLayerFilter:filterID];
        }];

        NSMutableArray *currentFilters = self.layer.filters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }

        [currentFilters addObject:newFilter];
        [CATransaction begin];
        self.layer.filters = currentFilters;
        [CATransaction commit];
        return filterID;
    }
    return nil;
}

-(NSString *)addSourceFilter:(NSString *)filterName
{
    
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            [input deleteSourceFilter:filterID];
        }];

        NSMutableArray *currentFilters = self.layer.sourceLayer.filters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }

        [currentFilters addObject:newFilter];
        [CATransaction begin];
        self.layer.sourceLayer.filters = currentFilters;
        [CATransaction commit];
        return filterID;
    }
    return nil;
}

-(NSString *)addBackgroundFilter:(NSString *)filterName
{
    
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter)
    {
        [newFilter setDefaults];
        CFUUIDRef tmpUUID = CFUUIDCreate(NULL);
        NSString *filterID = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, tmpUUID);
        CFRelease(tmpUUID);
        newFilter.name = filterID;
        
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            [input deleteBackgroundFilter:filterID];
        }];
        [self.sourceLayout.undoManager setActionName:@"Add Background Filter"];

        NSMutableArray *currentFilters = self.layer.backgroundFilters.mutableCopy;
        if (!currentFilters)
        {
            currentFilters = [NSMutableArray array];
        }
        [currentFilters addObject:newFilter];
        [CATransaction begin];
        self.layer.backgroundFilters = currentFilters;
        [CATransaction commit];
        return filterID;
    }
    return nil;
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


/*
-(NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@ Depth %f", self.name, self.depth];
}
 */


-(void)setName:(NSString *)name
{
    
    
    _name = name;


    _editedName = name;
    
    if (!_name)
    {
        if (self.videoInput)
        {
            _name = self.videoInput.captureName;
            _editedName = nil;
        }
    }
    
    if (!_name)
    {
        _name = @"No Name";
        _editedName = nil;
    }

    
    
    [CATransaction begin];
    self.layer.name = name;
    [CATransaction commit];
}


-(NSString *)name
{
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
    /*
    CATransform3D transform = CATransform3DMakeRotation(self.rotationAngle * M_PI / 180.0, 0.0, 0.0, 1.0);
    transform = CATransform3DRotate(transform, self.rotationAngleX * M_PI / 180.0, 1.0, 0.0, 0.0);
    transform = CATransform3DRotate(transform, self.rotationAngleY * M_PI / 180.0, 0.0, 1.0, 0.0);
    
    [CATransaction begin];
    self.layer.disableAnimation = YES;

    
    self.layer.transform = transform;

    
    self.layer.disableAnimation  = NO;
    [CATransaction commit];
     */
    
    self.geometryNode.eulerAngles = SCNVector3Make(0,0, self.rotationAngle * M_PI/180.0);
    self.sceneNode.eulerAngles = SCNVector3Make(self.rotationAngleX * M_PI/180.0, self.rotationAngleY * M_PI/180.0, 0);
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



-(void)setCropRectWithoutResize
{
    CGRect contentsRect = self.layer.sourceLayer.contentsRect;
    contentsRect.origin.x = self.crop_left;
    contentsRect.origin.y = self.crop_bottom;
    contentsRect.size.width = 1.0 - self.crop_right - self.crop_left;
    contentsRect.size.height = 1.0 - self.crop_top - self.crop_bottom;
    [CATransaction begin];
    self.layer.cropRect = contentsRect;
    [CATransaction commit];
}


-(void)setCropRect
{
    
    CGRect contentsRect = self.layer.contentsRect;//self.layer.sourceLayer.contentsRect;
    CGRect oldRect = contentsRect;
    
    contentsRect.origin.x = self.crop_left;
    contentsRect.origin.y = self.crop_bottom;
    contentsRect.size.width = 1.0 - self.crop_right - self.crop_left;
    contentsRect.size.height = 1.0 - self.crop_top - self.crop_bottom;

    
    CGFloat delta_w = (contentsRect.size.width - oldRect.size.width);
    CGFloat delta_h = (contentsRect.size.height - oldRect.size.height);
    CGRect currentRect = self.layer.frame;

    CGFloat new_width = currentRect.size.width;
    CGFloat new_height = currentRect.size.height;

    if (!NSEqualSizes(NSZeroSize,self.videoInput.captureSize))
    {
        
        
        CGFloat layer_full_width = currentRect.size.width/oldRect.size.width;
        CGFloat layer_full_height = currentRect.size.height/oldRect.size.height;
        
        new_width = layer_full_width * contentsRect.size.width;
        new_height = layer_full_height * contentsRect.size.height;
        

    
    }
    [CATransaction begin];
    self.layer.cropRect = contentsRect;
    if (delta_w || delta_h)
    {
        resize_style saveResize = self.resizeType;
        self.resizeType &= ~kResizeCrop;
        self.resizeType |= kResizeFree;

        [self updateSize:new_width height:new_height];
        
        self.resizeType = saveResize;
        
    }

    [CATransaction commit];
    
}




-(void)setTransitionDuration:(float)transitionDuration
{
    _transitionDuration = transitionDuration;
}


-(float)transitionDuration
{
    return _transitionDuration;
}
-(void)setTransitionDirection:(NSString *)transitionDirection
{
    _transitionDirection = transitionDirection;
}

-(NSString *)transitionDirection
{
    return _transitionDirection;
}

-(void)setTransitionEnabled:(bool)transitionEnabled
{
    [CATransaction begin];
    _transitionEnabled = transitionEnabled;
    
    if (transitionEnabled)
    {
        for (InputSource *inp in self.attachedInputs)
        {
            if (!inp.alwaysDisplay)
            {
                inp.layer.hidden = YES;
            }
        }
    } else {
        for (InputSource *inp in self.attachedInputs)
        {
            inp.layer.hidden = NO;
        }
        [self.layer transitionsDisabled];
    }
    [CATransaction commit];
}

-(bool)alwaysDisplay
{
    return _alwaysDisplay;
}

-(void)setAlwaysDisplay:(bool)alwaysDisplay
{
    
    
    if (alwaysDisplay)
    {
        [CATransaction begin];
        self.layer.hidden = NO;
        [CATransaction commit];
    }
    
    _alwaysDisplay = alwaysDisplay;
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
    if ([transitionFilterName hasPrefix:@"CI"])
    {
        CIFilter *newFilter = [CIFilter filterWithName:transitionFilterName];
        [newFilter setDefaults];
        self.advancedTransition = newFilter;
    } else {
        self.advancedTransition = nil;
    }
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

    if ((currentTime >= _nextImageTime) && (self.changeInterval > 0))
    {
        [self multiChangeForce];
    }
    
}

    
-(void)multiChangeForce
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();

    NSPredicate *inputFilter = [NSPredicate predicateWithFormat:@"alwaysDisplay == NO"];
    NSMutableArray *chooseInputs = [NSMutableArray arrayWithArray:self.attachedInputs];
    [chooseInputs filterUsingPredicate:inputFilter];
    if (!self.alwaysDisplay)
    {
        [chooseInputs addObject:self];
    }
    
    
    
    InputSource *_nextInput;
    
    
    
    if (chooseInputs.count > 1)
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
        
        @try {
            _nextInput = [chooseInputs objectAtIndex:_currentSourceIdx];
        }
        @catch (NSException *exception) {
            _nextInput = nil;
        }
        
        if (_nextInput)
        {
            _multiTransition.type = self.transitionFilterName;
            _multiTransition.duration = self.transitionDuration;
            _multiTransition.subtype = self.transitionDirection;
            _multiTransition.filter = self.advancedTransition.copy;
        
            CALayer *fromLayer = nil;
            if (!_currentInput.alwaysDisplay)
            {
                fromLayer = _currentInput.layer;
            }
        
            [self.layer transitionToLayer:_nextInput.layer fromLayer:fromLayer withTransition:_multiTransition];
            _currentInput = _nextInput;
        }
    }
}


-(void)setWidth:(float)width
{
    _width = width;
    
    
    
    [self directSize:_width height:_height];
    
}

-(float)width
{
    return _width;
}

-(void)setHeight:(float)height
{
    _height = height;
    [self directSize:_width height:_height];
}

-(float)height
{
    return _height;
}


-(void)setX_pos:(float)x_pos
{
    //[self registerUndoForProperty:@"x_pos" withAction:@"Position X"];
    if (x_pos > 0 && x_pos <= 1.0)
    {
        CALayer *sLayer = self.layer.superlayer;
        x_pos = sLayer.bounds.origin.x + (sLayer.bounds.size.width * x_pos);
        x_pos = roundf(x_pos);
    }
    _x_pos = x_pos;
    
    
    
    [self positionOrigin:_x_pos y:_y_pos];
}

-(float)x_pos
{
    return _x_pos;
}

-(void)setY_pos:(float)y_pos
{
    //[self registerUndoForProperty:@"y_pos" withAction:@"Position Y"];
    if (y_pos > 0 && y_pos <= 1.0)
    {
        CALayer *sLayer = self.layer.superlayer;
        y_pos = sLayer.bounds.origin.y + (sLayer.bounds.size.height * y_pos);
        y_pos = roundf(y_pos);
    }

    _y_pos = y_pos;
    [self positionOrigin:_x_pos y:_y_pos];
}



-(float)y_pos
{
    return _y_pos;
}



-(void) adjustInputSize: (bool)doPosition
{

    if (self.topLevelHeight > 0 && self.topLevelWidth > 0)
    {
        float wRatio = self.canvas_width/self.topLevelWidth;
        float hRatio = self.canvas_height/self.topLevelHeight;
        float old_x = self.x_pos;
        float old_y = self.y_pos;
        
        float new_width = self.layer.frame.size.width * wRatio;
        float new_height = self.layer.frame.size.height * hRatio;
        [self directSize:new_width height:new_height];
        if (doPosition)
        {
            self.x_pos = old_x*wRatio;
            self.y_pos = old_y*hRatio;
        }
    }
    
    self.topLevelWidth = self.canvas_width;
    self.topLevelHeight = self.canvas_height;
    
}

-(void)frameTick
{
    
    /*
    self.layoutPosition = self.layer.frame;
    _x_pos = self.layer.frame.origin.x;
    _y_pos = self.layer.frame.origin.y;
    _width = self.layer.frame.size.width;
    _height = self.layer.frame.size.height;
    */
    
    _x_pos = self.sceneNode.position.x;
    _y_pos = self.sceneNode.position.y;

 //   _width = self.scenePlane.width;
 //   _height = self.scenePlane.height;
    
    SCNVector3 minPoint;
    SCNVector3 maxPoint;
    if ([self.geometryNode getBoundingBoxMin:&minPoint max:&maxPoint])
    {
        SCNVector3 cMin = [self.geometryNode convertPosition:minPoint toNode:self.sceneNode.parentNode];
        SCNVector3 cMax = [self.geometryNode convertPosition:maxPoint toNode:self.sceneNode.parentNode];

        self.layoutPosition = NSMakeRect(cMin.x, cMin.y, cMax.x-cMin.x, cMax.y-cMin.y);
        _width = cMax.x-cMin.x;
        _height = cMax.y-cMin.y;
        
        //self.layoutPosition = NSMakeRect(self.sceneNode.position.x, self.sceneNode.position.y, self.scenePlane.width, self.scenePlane.height);
    }
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
        
        self.layer.sourceLayer = _currentLayer;
    }
    
    
    [self.videoInput frameTickFromInput:self];
    
    [self.layer frameTick];
    if (self.needsAdjustment)
    {
        [self adjustInputSize:self.needsAdjustPosition];
        self.needsAdjustment = NO;
    }
}



-(void)autoSize
{
    if (!self.videoInput)
    {
        return;
    }
    
    NSSize videoSize = [self.videoInput captureSize];
    
    
    if (!NSEqualSizes(videoSize, NSZeroSize))
    {
        [self directSize:videoSize.width height:videoSize.height];
    }
}

-(void)autoCenter:(NSRect)containerRect
{
    NSRect myRect = self.layer.bounds;
    
    
    if (NSContainsRect(containerRect, myRect))
    {
        [self autoFit];
    } else {
        //We're bigger than the container! Set ourselves to the exact same size and origin
        [self directSize:containerRect.size.width height:containerRect.size.height];
        [self positionOrigin:0 y:0];
    }
}


-(void)autoFit
{

    float wr = self.size.width / self.canvas_width;
    float hr = self.size.height / self.canvas_height;
    float ratio = (hr < wr ? wr : hr);
    [self directSize:self.size.width / ratio height:self.size.height / ratio];
    CGFloat newX = (self.canvas_width/2) - self.layer.frame.size.width/2;
    CGFloat newY = (self.canvas_height/2) - self.layer.frame.size.height/2;
    [self positionOrigin:newX y:newY];
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





-(void) directSize:(CGFloat)width height:(CGFloat)height
{
    NSRect newLayout = self.layoutPosition;
    
    newLayout.size.width = width;
    newLayout.size.height = height;
    
    NSRect iRect = NSIntegralRect(newLayout);

    iRect.origin.x = 0;
    iRect.origin.y = 0;
    
    [CATransaction begin];
    self.layer.frame = iRect;
    //self.layer.sourceLayer.frame = iRect;
    [CATransaction commit];
    
    //[self.scenePlane setBoundingBoxMin:&minPoint max:&maxPoint];
    
    //self.scenePlane.width = iRect.size.width;
    //self.scenePlane.height = iRect.size.height;
    self.geometryNode.scale = SCNVector3Make(iRect.size.width, iRect.size.height, 1);
    
    
    self.sceneNode.pivot = SCNMatrix4MakeTranslation(-iRect.size.width/2, -iRect.size.height/2, 0);
}


-(void)resetAspectRatio
{
    

    if (!self.videoInput || NSEqualSizes(NSZeroSize, self.videoInput.captureSize))
    {
        return;
    }
    
    CGFloat height = self.height;
    CGFloat width = self.width;
    
    CGFloat inputAR = self.videoInput.captureSize.width / self.videoInput.captureSize.height;
    if (height > width)
    {
        width = inputAR * height;
    } else {
        height = width/inputAR;
    }

    resize_style resizeSave = self.resizeType;
    self.resizeType = kResizeTop | kResizeRight | kResizeFree;
    [self updateSize:width height:height];
    self.resizeType = resizeSave;
}



-(void) resizeToPoint:(CGPoint)point withResizeFlags:(resize_style)resizeType
{
    
    NSRect currentPos = self.globalLayoutPosition;
    
    
    NSLog(@"CURRENT POSITION %@", NSStringFromRect(currentPos));
    
    SCNMatrix4 tmpPivot;
    
    CGFloat newWidth = currentPos.size.width;
    CGFloat newHeight = currentPos.size.height;
    CGFloat newX = currentPos.origin.x;
    CGFloat newY = currentPos.origin.y;
    

    if (resizeType & kResizeRight)
    {
        
        newWidth = (point.x - currentPos.origin.x);
        
        
        NSLog(@"WIDTH DIFFERENCE %f", newWidth - currentPos.size.width);
        
        newX = ((point.x - newWidth) + (newWidth - currentPos.size.width));
        
    }
    
    if (resizeType & kResizeTop)
    {
        newHeight = point.y - currentPos.origin.y;
        //newY = point.y - newHeight;
    }
    
    if (resizeType & kResizeLeft)
    {
        
        CGFloat currentMaxX = NSMaxX(currentPos);

        newWidth = currentMaxX - point.x;
        
        newX = currentMaxX - newWidth;


        //newX = point.x;
    }
    
    if (resizeType & kResizeBottom)
    {
        CGFloat curMaxY = NSMaxY(currentPos);
        
        
        newHeight = curMaxY - point.y;
        newY = curMaxY - newHeight;
    }


    NSLog(@"NEW %f %f %f %f", newX, newY, newWidth, newHeight);
    [self positionOrigin:newX y:newY];

    [self directSize:newWidth height:newHeight];


}



-(void) updateSize:(CGFloat)width height:(CGFloat)height
{
    
    [CATransaction begin];
    //NSRect oldLayout = self.layer.frame;
   // NSRect newLayout = self.layer.frame;
    
    NSRect oldLayout = self.layoutPosition; //NSMakeRect(self.sceneNode.position.x, self.sceneNode.position.y, self.scenePlane.width, self.scenePlane.height);
    NSRect newLayout = oldLayout;
    
    NSLog(@"CURRENT POSITION %@", NSStringFromRect(oldLayout));
    
    
    CGFloat delta_w, delta_h;
    delta_w = width - oldLayout.size.width;
    delta_h = height - oldLayout.size.height;
    //Preserve aspect ratio on resize. Take the largest dimension and figure out hte other one
    
    if (self.videoInput && !NSEqualSizes(self.videoInput.captureSize, NSZeroSize) && !(self.resizeType & kResizeFree) && !(self.resizeType & kResizeCrop))
    {
        CGFloat inputAR = oldLayout.size.width / oldLayout.size.height;
        if (height > width)
        {
            width = inputAR * height;
            delta_w = width - oldLayout.size.width;
        } else {
            height = width/inputAR;
            delta_h = height - oldLayout.size.height;
        }
    }
    
    if (self.layer)
    {
        
        
        newLayout.size.width = width;
        newLayout.size.height = height;
        
        
        if (self.resizeType & kResizeCrop)
        {
            //calculate the crop left/right/top/bottom values and let setCropRect handle the resize
            
            CGFloat full_width = oldLayout.size.width/self.layer.sourceLayer.contentsRect.size.width;
            CGFloat delta_wp = delta_w/full_width;
            CGFloat full_height = oldLayout.size.height/self.layer.sourceLayer.contentsRect.size.height;
            CGFloat delta_hp = delta_h/full_height;
            
            
            if (self.resizeType & kResizeLeft)
            {
                
                self.crop_left -= delta_wp;
            }
            
            if (self.resizeType & kResizeRight)
            {
                self.crop_right -= delta_wp;
            }

            if (self.resizeType & kResizeTop)
            {
                self.crop_top -= delta_hp;
            }
            
            if (self.resizeType & kResizeBottom)
            {
                self.crop_bottom -= delta_hp;
            }
        } else {
            
            if (self.resizeType & kResizeCenter)
            {
                newLayout.origin.x -= delta_w/2;
                newLayout.origin.y -= delta_h/2;
            } else {
                if (self.resizeType & kResizeLeft)
                {
                    //Where does the origin need to be to keep the right side in the same place?
                    newLayout.origin.x -= delta_w;
                }
                
                if (self.resizeType & kResizeBottom)
                {
                    NSLog(@"DELTA H %f", delta_h);
                    
                    newLayout.origin.y -= delta_h/2;
                }
            }

            //self.layer.frame = newLayout;
            [self directSize:newLayout.size.width height:newLayout.size.height];

            [self positionOrigin:newLayout.origin.x y:newLayout.origin.y];
            //self.sceneNode.position = SCNVector3Make(newLayout.origin.x, newLayout.origin.y, 0);
            
        }
    }
    [CATransaction commit];
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

    [CATransaction begin];
    [toDetach resetConstraints];
    
    toDetach.parentInput = nil;
    toDetach.alwaysDisplay = NO;
    
    [self.sourceLayout.rootLayer addSublayer:toDetach.layer];
    toDetach.layer.hidden = NO;
    
    //translate the position to the new sublayers coordinates
    
    
    NSPoint newPosition = [self.sourceLayout.rootLayer convertPoint:toDetach.layer.position fromLayer:self.layer];
    toDetach.layer.position = newPosition;
    [CATransaction commit];
    
    [[self mutableArrayValueForKey:@"attachedInputs"] removeObject:toDetach];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputDetached object:toDetach userInfo:nil];

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
    [[self mutableArrayValueForKey:@"attachedInputs"] addObject:toAttach];
    toAttach.parentInput = self;
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationInputAttached object:toAttach userInfo:nil];

}




-(NSArray *)getLayersToCanvas:(CALayer *)startLayer
{
    NSMutableArray *ret = [NSMutableArray array];
    
    CALayer *curr = startLayer;
    while (curr)
    {
        [ret addObject:curr];
        curr = curr.superlayer;
        if (curr == self.sourceLayout.rootLayer)
        {
            break;
        }
    }
    
    return ret;
}


-(void)makeSublayerOfLayer:(CALayer *)parentLayer
{
    
    [CATransaction begin];
    
    NSPoint newPosition = self.layer.frame.origin;

    
    if (!NSIntersectsRect(parentLayer.frame, self.layer.frame))
    {
        newPosition.x = NSMidX(parentLayer.frame) - self.layer.frame.size.width/2;
        newPosition.y = NSMidY(parentLayer.frame) - self.layer.frame.size.height/2;
    }
    
    
    
    [parentLayer addSublayer:self.layer];
    //translate the position to the new sublayers coordinates
    
    NSArray *layers = [self getLayersToCanvas:parentLayer];
    
    for (CALayer *curr in [layers reverseObjectEnumerator])
    {
      //We start at the layer just before the canvas layer and the point we are converting is in canvas coordinate space
        newPosition = [curr convertPoint:newPosition fromLayer:curr.superlayer];
    }
    
    NSRect oldFrame = self.layer.frame;
    oldFrame.origin = newPosition;
    
    self.layer.frame = oldFrame;
    [CATransaction commit];

}


-(void) positionOrigin:(CGFloat)x y:(CGFloat)y
{
    
    if (self.layer)
    {
        
        /*
        NSRect newFrame = self.layer.frame;
        newFrame.origin.x = x;
        newFrame.origin.y = y;
        [CATransaction begin];
        self.layer.frame = newFrame;
        [CATransaction commit];
         */
        
        
        //[self updateOrigin:x-self.sceneNode.position.x y:y-self.sceneNode.position.y];
        
        //[self updateOrigin:x-self.layer.frame.origin.x y:y-self.layer.frame.origin.y];
        
        NSRect previousRect = self.globalLayoutPosition;
        previousRect.origin.x = x;
        previousRect.origin.y = y;
        NSRect layoutRect = NSIntegralRect(previousRect);
        
        self.sceneNode.position = SCNVector3Make(layoutRect.origin.x, layoutRect.origin.y, 0);
        
    }

}
-(void) updateOrigin:(CGFloat)x y:(CGFloat)y
{
    
    if (isnan(x))
    {
        return;
    }
    
    
    if (self.layer)
    {
        
        NSPoint newOrigin = NSMakePoint(self.sceneNode.position.x, self.sceneNode.position.y);
        newOrigin.x += x;
        newOrigin.y += y;
        
        
        [CATransaction begin];
            //[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        NSRect tmpRect = NSIntegralRect(NSMakeRect(newOrigin.x, newOrigin.y, 100, 100));
        
        self.layer.disableAnimation = YES;
        //self.layer.position = tmpRect.origin;
        
        self.layer.disableAnimation = NO;
            
        [CATransaction commit];

        self.sceneNode.position = SCNVector3Make(newOrigin.x, newOrigin.y, 0);
        
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
    self.sceneNode.opacity = _opacity;
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
    }
    
    NSObject <CSCaptureSourceProtocol> *newCaptureSession;
    
    Class captureClass = [pluginMap objectForKey:selectedVideoType];
    newCaptureSession = [[captureClass alloc] init];
    
    [self registerVideoInput:newCaptureSession];
    CALayer *newLayer = [newCaptureSession layerForInput:self];
    
    _currentLayer = newLayer;
    [SCNTransaction begin];
    
    self.layer.sourceLayer = _currentLayer;
    
    //self.scenePlane.firstMaterial.diffuse.contents = _currentLayer;
    
    [SCNTransaction commit];
    
    self.videoInput = newCaptureSession;

 
    _selectedVideoType = selectedVideoType;
    self.name = _editedName;
    
 }

-(NSData *)saveData
{
    NSMutableData *saveData = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:saveData];
    
    [archiver encodeObject:self forKey:@"root"];
    [archiver finishEncoding];
    return saveData;
}

-(bool)isDifferentInput:(InputSource *)from
{
    if (![from.uuid isEqualToString:self.uuid])
    {
        return YES;
    }
    
    NSData *myData = [self saveData];
    NSData *fromData = [from saveData];
    
    
    
    if ([myData isEqualToData:fromData])
    {
        return NO;
    }
    
    return YES;
}


-(NSViewController *)sourceConfigurationView
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

    /*
    if (scrollXSpeed != 0)
    {
        CABasicAnimation *xanim = [CABasicAnimation animationWithKeyPath:@"firstMaterial.diffuse.contentsTransform.translation.x"];
        if (scrollXSpeed < 0)
        {
            xanim.fromValue = @1.0f;
            xanim.toValue = @0.0f;
        } else {
            xanim.fromValue = @0.0;
            xanim.toValue = @1.0;
        }
        xanim.duration = fabs(scrollXSpeed);
        xanim.repeatCount = INFINITY;
        [self.geometryNode.geometry addAnimation:xanim forKey:@"scrollX"];
    } else {
        [self.geometryNode.geometry removeAnimationForKey:@"scrollX"];
    }
    _scrollXSpeed = scrollXSpeed;
    */
    
    
    [CATransaction begin];
    self.layer.scrollXSpeed = scrollXSpeed;
    [CATransaction commit];
   
}

-(float)scrollXSpeed
{
    return self.layer.scrollXSpeed;
}


-(void)setScrollYSpeed:(float)scrollYSpeed
{

    [CATransaction begin];
    self.layer.scrollYSpeed = scrollYSpeed;
    [CATransaction commit];
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

-(NSString *)MIDIShortIdentifier
{
    return nil;
}


-(NSString *)MIDIIdentifier
{
    return [NSString stringWithFormat:@"Input:%@", self.uuid];
}

-(NSArray *)commandIdentifiers
{
    return @[@"Opacity", @"Rotate", @"RotateX", @"RotateY", @"Active", @"AutoFit",
             @"HScroll", @"VScroll", @"CropLeft", @"CropRight", @"CropTop", @"CropBottom",
             @"CKEnable", @"CKThresh", @"CKSmooth", @"BorderWidth", @"CornerRadius",
             @"GradientStartX", @"GradientStartY", @"GradientStopX", @"GradientStopY",
             @"ChangeInterval", @"EffectDuration", @"MultiTransition",
             @"PositionX", @"PositionY", @"Freeze"];
}

-(MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID
{
    MIKMIDIResponderType ret = MIKMIDIResponderTypeAbsoluteSliderOrKnob;

    if ([@[@"Opacity",@"Rotate",@"RotateX",@"RotateY"] containsObject:commandID])
    {
        ret |= MIKMIDIResponderTypeButton;
    }
    
    if ([@[@"Active", @"AutoFit", @"CKEnable", @"MultiTransition", @"Freeze"] containsObject:commandID])
    {
        ret = MIKMIDIResponderTypeButton;
    }
    
    
    return ret;
}


-(BOOL)respondsToMIDICommand:(MIKMIDICommand *)command
{
    return YES;
}

-(float)convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:(float)minvalue maxValue:(float)maxvalue
{
    NSUInteger midiValue = command.value;
    
    float midifract = midiValue/127.0;
    
    float valRange = maxvalue - minvalue;
    
    float valFract = valRange * midifract;
    
    return minvalue + valFract;
}

-(void)handleMIDICommandChangeInterval:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:60];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.changeInterval = newVal;
    });
    
}

-(void)handleMIDICommandEffectDuration:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:10];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.transitionDuration = newVal;
    });
    
}

-(void)handleMIDICommandPositionX:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.x_pos = newVal;
    });
    
}

-(void)handleMIDICommandPositionY:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.y_pos = newVal;
    });
    
}




-(void)handleMIDICommandCKThresh:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:0.5];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.chromaKeyThreshold = newVal;
    });
    
}


-(void)handleMIDICommandGradientStartX:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.gradientStartX = newVal;
    });

}

-(void)handleMIDICommandGradientStartY:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.gradientStartY = newVal;
    });
    
}

-(void)handleMIDICommandGradientStopX:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.gradientStopX = newVal;
    });
    
}

-(void)handleMIDICommandGradientStopY:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.gradientStopY = newVal;
    });
    
}



-(void)handleMIDICommandCKSmooth:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:0.5];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.chromaKeySmoothing = newVal;
    });
    
}


-(void)handleMIDICommandMultiTransition:(MIKMIDICommand *)command
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self multiChangeForce];
    });
}


-(void)handleMIDICommandCKEnable:(MIKMIDICommand *)command
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.doChromaKey = !self.doChromaKey;
    });
}



-(void)handleMIDICommandBorderWidth:(MIKMIDICommand *)command
{
    float newVal = ((MIKMIDIChannelVoiceCommand *)command).value;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.borderWidth = newVal;
    });
    
}

-(void)handleMIDICommandCornerRadius:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:360];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.cornerRadius = newVal;
    });
    
}


-(void)handleMIDICommandCropLeft:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.crop_left = newVal;
    });
}

-(void)handleMIDICommandCropRight:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.crop_right = newVal;
    });
    
}

-(void)handleMIDICommandCropTop:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.crop_top = newVal;
    });
    
}

-(void)handleMIDICommandCropBottom:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0.0 maxValue:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.crop_bottom = newVal;
    });
    
}



-(void)handleMIDICommandFreeze:(MIKMIDICommand *)command
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isFrozen = !self.isFrozen;
    });
}


-(void)handleMIDICommandAutoFit:(MIKMIDICommand *)command
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self autoFit];
    });
}


-(void)handleMIDICommandHScroll:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:-10.0 maxValue:10.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollXSpeed = newVal;
    });
}

-(void)handleMIDICommandVScroll:(MIKMIDICommand *)command
{
    float newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:-10.0 maxValue:10.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scrollYSpeed = newVal;
    });
}


-(void)handleMIDICommandOpacity:(MIKMIDICommand *)command
{
    float newVal;
    if (command.commandType == MIKMIDICommandTypeNoteOn)
    {
        if (self.opacity != 0)
        {
            newVal = 0;
        } else {
            newVal = 1;
        }
    } else {
        newVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0 maxValue:1.0];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.opacity = newVal;
    });
}

-(void)handleMIDICommandActive:(MIKMIDICommand *)command
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.active = !self.active;
    });

}

-(float)handleGenericRotateForMidi:(float)currentValue forCommand:(MIKMIDICommand *)command
{
    float retVal;
    if (command.commandType == MIKMIDICommandTypeNoteOn)
    {
        retVal = currentValue + 90;
        if (retVal >= 360)
        {
            retVal = 0;
        }
    } else {
       retVal = [self convertMidiValueForRange:(MIKMIDIChannelVoiceCommand *)command minValue:0 maxValue:360];
    }
    
    return retVal;
}


-(void)handleMIDICommandRotate:(MIKMIDICommand *)command
{
    float newVal = [self handleGenericRotateForMidi:self.rotationAngle forCommand:command];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rotationAngle = newVal;
    });
}

-(void)handleMIDICommandRotateX:(MIKMIDICommand *)command
{
    float newVal = [self handleGenericRotateForMidi:self.rotationAngleX forCommand:command];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rotationAngleX = newVal;
    });
}

-(void)handleMIDICommandRotateY:(MIKMIDICommand *)command
{
    float newVal = [self handleGenericRotateForMidi:self.rotationAngleY forCommand:command];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.rotationAngleY = newVal;
    });
}



-(void)layerUpdated
{
    if (self.autoPlaceOnFrameUpdate)
    {
        [self autoSize];
        [self autoCenter:NSMakeRect(0, 0, self.canvas_width, self.canvas_height)];
        self.autoPlaceOnFrameUpdate = NO;
    }
}


-(void) setActive:(bool)active
{
    
    _active = active;
    if (self.videoInput)
    {
        self.videoInput.isActive = active;
    }
    
    CATransition *trans = [CATransition animation];
    trans.type = kCATransitionPush;
    trans.subtype = kCATransitionFromLeft;
    trans.duration = 1.5;
    trans.removedOnCompletion = YES;
    NSLog(@"PARENT %@", self.layer.superlayer);
    [self.layer addAnimation:trans forKey:kCATransition];
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

-(CGFloat) crop_left
{
    return _crop_left;
}


-(void) setCrop_left:(CGFloat)crop_left
{
    if (crop_left < 0)
    {
        _crop_left = 0;
    } else {
        _crop_left = crop_left;
    }
    
    [self setCropRect];
    
    
}

-(CGFloat) crop_right
{
    return _crop_right;
}


-(void) setCrop_right:(CGFloat)crop_right
{
    if (crop_right < 0)
    {
        _crop_right = 0;
    } else {
        _crop_right = crop_right;
    }
    [self setCropRect];

}

-(CGFloat) crop_top
{
    return _crop_top;
}


-(void) setCrop_top:(CGFloat)crop_top
{
    if (crop_top < 0)
    {
        _crop_top = 0;
    } else {
        _crop_top = crop_top;
    }
    [self setCropRect];

}

-(CGFloat) crop_bottom
{
    return _crop_bottom;
}


-(void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    
    NSString *actionName = _undoActionMap[keyPath];
    if (!actionName)
    {
        if ([keyPath isEqualToString:@"isMaskLayer"])
        {
            actionName = value ? @"Set As Mask" : @"Unset As Mask";
        } else if ([keyPath isEqualToString: @"active"]) {
            actionName = value ? @"Set Active" : @"Unset Active";
        } else if ([keyPath isEqualToString:@"doChromaKey"]) {
            actionName = value ? @"Set Chroma Key" : @"Unset Chroma Key";
        } else {
            actionName = [NSString stringWithFormat:@"Change %@", keyPath];
        }
    }
    
    [self registerUndoForProperty:keyPath withAction:actionName];
    
    [super setValue:value forKeyPath:keyPath];
}
-(void) setCrop_bottom:(CGFloat)crop_bottom
{
    if (crop_bottom < 0)
    {
        _crop_bottom = 0;
    } else {
        _crop_bottom = crop_bottom;
    }
    [self setCropRect];

}


-(void)registerUndoForProperty:(NSString *)propName withAction:(NSString *)action
{
    id propertyValue = [self valueForKeyPath:propName];
    
    [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
        [input setValue:propertyValue forKeyPath:propName];
        
    }];
    [self.sourceLayout.undoManager setActionName:action];
}



-(void)setChromaKeyColor:(NSColor *)chromaKeyColor
{


    _chromaKeyColor = chromaKeyColor;
    [CATransaction begin];
    [self.layer.sourceLayer setValue:[[CIColor alloc] initWithColor:chromaKeyColor] forKeyPath:@"filters.Chromakey.inputColor"];
    [CATransaction commit];
}

-(NSColor *)chromaKeyColor
{
    return _chromaKeyColor;
}

-(void)setChromaKeySmoothing:(float)chromaKeySmoothing
{

    _chromaKeySmoothing = chromaKeySmoothing;
    [CATransaction begin];
    [self.layer.sourceLayer setValue:@(chromaKeySmoothing) forKeyPath:@"filters.Chromakey.inputSmoothing"];
    [CATransaction commit];
}

-(float)chromaKeySmoothing
{
    return _chromaKeySmoothing;
}

-(void)setChromaKeyThreshold:(float)chromaKeyThreshold
{
    _chromaKeyThreshold = chromaKeyThreshold;
    [CATransaction begin];
    [self.layer.sourceLayer setValue:@(chromaKeyThreshold) forKeyPath:@"filters.Chromakey.inputThreshold"];
    [CATransaction commit];
}

-(float)chromaKeyThreshold
{
    return _chromaKeyThreshold;
}



-(void)setDoChromaKey:(bool)doChromaKey
{
    
    _doChromaKey = doChromaKey;

    [CATransaction begin];
    [self.layer.sourceLayer setValue:[NSNumber numberWithBool:doChromaKey] forKeyPath:@"filters.Chromakey.enabled" ];
    if (doChromaKey)
    {
                
        [self.layer.sourceLayer setValue:[[CIColor alloc] initWithColor:self.chromaKeyColor] forKeyPath:@"filters.Chromakey.inputColor"];

        [self.layer.sourceLayer setValue:@(self.chromaKeySmoothing) forKeyPath:@"filters.Chromakey.inputSmoothing"];

        [self.layer.sourceLayer setValue:@(self.chromaKeyThreshold) forKeyPath:@"filters.Chromakey.inputThreshold"];

    }
    [CATransaction commit];
    
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
    [self detachAllInputs];
    if (self.parentInput)
    {
        [self.parentInput detachInput:self];
    }
    
    
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
        if (!parentAttrib)
        {
            continue;
        }
        [constraints addObject:[CAConstraint constraintWithAttribute:toConstrain relativeTo:@"superlayer" attribute:parentAttrib scale:1 offset:offsetFloat]];
        
    }
    
    [CATransaction begin];
    self.layer.constraints = constraints;
    [CATransaction commit];
    
    
}


//I should probably use contexts...
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{

    
    if ([keyPath hasPrefix:@"constraintMap"])
    {
        id oldValue = change[NSKeyValueChangeOldKey];
        NSRect oldFrame = self.layoutPosition;
        
        [[self.sourceLayout.undoManager prepareWithInvocationTarget:self.sourceLayout] modifyUUID:self.uuid withBlock:^(InputSource *input) {
            [input setValue:oldValue forKeyPath:keyPath];
            [input updateSize:oldFrame.size.width height:oldFrame.size.height];
            [input positionOrigin:oldFrame.origin.x y:oldFrame.origin.y];
            
        }];
        [self.sourceLayout.undoManager setActionName:@"Constraint Change"];

        [self buildLayerConstraints];
    } else if ([keyPath isEqualToString:@"captureName"]) {
        self.name = _editedName;
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
        [self addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    }
}




@end
