//
//  CaptureBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved
//

#import "CSCaptureBase.h"
#import "SourceCache.h"
#import <objc/runtime.h>

@interface CSCaptureBase()
{
    NSMapTable *_allLayers;
}

@end
@implementation CSCaptureBase

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize allowScaling = _allowScaling;

+(NSString *) label
{
    return NSStringFromClass(self);
}


-(instancetype) init
{
    if (self = [super init])
    {
        self.needsSourceSelection = YES;
        self.allowDedup = YES;
        self.isVisible = YES;
        self.allowScaling = YES;
        _allLayers = [NSMapTable weakToStrongObjectsMapTable];
        
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.activeVideoDevice.uniqueID forKey:@"active_uniqueID"];
    [aCoder encodeBool:self.allowDedup forKey:@"allowDedup"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
     
        self.allowDedup = [aDecoder decodeBoolForKey:@"allowDedup"];
        self.savedUniqueID = [aDecoder decodeObjectForKey:@"active_uniqueID"];
        [self setDeviceForUniqueID:self.savedUniqueID];
    }
    
    return self;
}

-(NSString *) configurationViewClassName
{
    return [NSString stringWithFormat:@"%@ViewController", self.className];
}


-(NSString *) configurationViewName
{
    return [NSString stringWithFormat:@"%@ViewController", self.className];
}



-(NSViewController *)configurationView
{
    
    NSViewController *configViewController;
    
    NSString *controllerName = self.configurationViewClassName;
    
    
    
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        
        configViewController = [[viewClass alloc] initWithNibName:self.configurationViewName bundle:[NSBundle bundleForClass:self.class]];
        
        if (configViewController)
        {
            
            //Should probably make a base class for view controllers and put captureObj there
            //but for now be gross.
            [configViewController setValue:self forKey:@"captureObj"];
        }
    }
    return configViewController;
    
}


-(void)setDeviceForUniqueID:(NSString *)uniqueID
{
    CSAbstractCaptureDevice *dummydev = [[CSAbstractCaptureDevice alloc] init];
    
    dummydev.uniqueID = uniqueID;
    
    NSArray *currentAvailableDevices;
    
    currentAvailableDevices = self.availableVideoDevices;
    
    
    NSUInteger sidx;
    sidx = [currentAvailableDevices indexOfObject:dummydev];
    
    if (sidx == NSNotFound)
    {
        self.activeVideoDevice = nil;
    } else {
        
        self.activeVideoDevice = [currentAvailableDevices objectAtIndex:sidx];
    }
}

-(void)frameTick
{
    return;
}


-(void)willDelete
{
    return;
}


-(float)render_height
{
    NSNumber *ret = [self.inputSource valueForKeyPath:@"display_height"];
    return [ret intValue];
}

-(float)render_width
{
    
    NSNumber *ret = [self.inputSource valueForKeyPath:@"display_width"];
    return [ret intValue];
}


-(id) copyWithZone:(NSZone *)zone
{
  
    
    id newCopy = [[self.class alloc] init];
    
    
    
    //This is gross I'm sorry
    
    unsigned int propCount;
    Class currentClass = self.class;
    
    
    while (currentClass && [currentClass superclass])
    {
        
        
    
        objc_property_t *myProperties = class_copyPropertyList(currentClass, &propCount);
        for (unsigned int i = 0; i < propCount; i++)
        {
            objc_property_t prop = myProperties[i];
            const char *propName = property_getName(prop);
            
            NSString *pName = [[NSString alloc] initWithBytes:propName length:strlen(propName) encoding:NSUTF8StringEncoding];
            id propertyValue = [self valueForKey:pName];
            
            [newCopy setValue:propertyValue forKey:pName];
        }
        
        currentClass = [currentClass superclass];
        
        
    }
    return newCopy;
    
}

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
    //hack so we don't throw exceptions during the above function
    return;
}


-(CALayer *)createNewLayer
{
    return [CALayer layer];
}


-(CALayer *)createNewLayerForInput:(id)inputsrc
{
    CALayer *newLayer = [self createNewLayer];
    [newLayer setValue:@(!self.allowScaling) forKey:@"csnoResize"];
    @synchronized(self)
    {
        [_allLayers setObject:newLayer forKey:inputsrc];
    }
    return newLayer;
}

-(void)removeLayerForInput:(id)inputsrc
{
    @synchronized(self)
    {
        [_allLayers removeObjectForKey:inputsrc];
        if (_allLayers.count == 0)
        {
            [self willDelete];
        }
    }
}


-(void)updateLayersWithBlock:(void (^)(CALayer *layer))updateBlock
{
    NSMapTable *layersCopy = nil;
    @synchronized(self)
    {
        layersCopy = _allLayers.copy;
    }
    
    for (id key in layersCopy)
    {
        [CATransaction begin];
        CALayer *clayer = [layersCopy objectForKey:key];
        updateBlock(clayer);
        [CATransaction commit];
    }
    
}

-(CALayer *)layerForInput:(id)inputsrc
{
    return [_allLayers objectForKey:inputsrc];
}

-(void)setAllowScaling:(bool)allowScaling
{
    _allowScaling = allowScaling;
    [self updateLayersWithBlock:^(CALayer *layer) {
        [layer setValue:@(!allowScaling) forKey:@"csnoResize"];
    }];
}

-(bool)allowScaling
{
    return _allowScaling;
}


+(void) layoutModification:(void (^)())modBlock
{
    //On main thread already, just execute the block, otherwise execute on main and wait
    if ([NSThread isMainThread])
    {
        modBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            modBlock();
        });
    }
    
}

@end
