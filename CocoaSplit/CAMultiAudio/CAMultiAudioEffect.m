//
//  CAMultiAudioEffect.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioEffect.h"

@implementation CAMultiAudioEffect


@synthesize bypass = _bypass;


-(instancetype) initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer
{
    if (self = [super initWithSubType:subType unitType:unitType manufacturer:manufacturer])
    {
        self.nodeUID = [[NSUUID UUID] UUIDString];
    }
    
    return self;
}
-(void)setBypass:(bool)bypass
{
    _bypass = bypass;
    UInt32 bypassVal;
    
    if (bypass)
    {
        bypassVal = 1;
    } else {
        bypassVal = 0;
    }
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_BypassEffect, kAudioUnitScope_Global, 0, &bypassVal, sizeof(bypassVal));
}

-(bool)bypass
{
    return _bypass;
}


+(NSArray *)availableEffects
{
    
    NSMutableArray *ret = [NSMutableArray array];
    AudioComponentDescription searchDesc = {0};
    searchDesc.componentType = kAudioUnitType_Effect;
    
    AudioComponent result = NULL;
    
    while ((result = AudioComponentFindNext(result, &searchDesc)))
    {
        AudioComponentDescription resultDesc;
        AudioComponentGetDescription(result, &resultDesc);
        
        CAMultiAudioEffect *newUnit = [[CAMultiAudioEffect alloc] initWithSubType:resultDesc.componentSubType unitType:resultDesc.componentType manufacturer:resultDesc.componentManufacturer];
        CFStringRef name;
        AudioComponentCopyName(result, &name);
        newUnit.name = CFBridgingRelease(name);
        [ret addObject:newUnit];
    }
    
    return ret;
}

-(id)copyWithZone:(NSZone *)zone
{
    CAMultiAudioEffect *newNode = [[CAMultiAudioEffect alloc] initWithSubType:unitDescr.componentSubType unitType:unitDescr.componentType manufacturer:unitDescr.componentManufacturer];
    newNode.name = self.name;
    return newNode;
}


-(bool)createNode:(CAMultiAudioGraph *)forGraph
{
    bool ret = [super createNode:forGraph];
    
    if (ret)
    {
        AudioComponent comp = AudioComponentFindNext(NULL, &unitDescr);
        CFStringRef cName;
        AudioComponentCopyName(comp, &cName);
        self.name = CFBridgingRelease(cName);
    }
    
    return ret;
}


@end
