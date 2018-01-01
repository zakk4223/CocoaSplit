//
//  CAMultiAudioEffect.m
//  CocoaSplit
//
//  Created by Zakk on 12/31/17.
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


-(void)setAudioUnitBypass
{
    UInt32 bypassVal;
    
    if (self.bypass)
    {
        bypassVal = 1;
    } else {
        bypassVal = 0;
    }
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_BypassEffect, kAudioUnitScope_Global, 0, &bypassVal, sizeof(bypassVal));
}


-(void)setBypass:(bool)bypass
{
    _bypass = bypass;
    [self setAudioUnitBypass];
}

-(bool)bypass
{
    return _bypass;
}




-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    if (restoreDict[@"subType"])
    {
        unitDescr.componentSubType = (OSType)[restoreDict[@"subType"] unsignedIntegerValue];
    }
    
    if (restoreDict[@"componentType"])
    {
        unitDescr.componentType = (OSType)[restoreDict[@"componentType"] unsignedIntegerValue];
    }

    if (restoreDict[@"manufacturer"])
    {
        unitDescr.componentManufacturer = (OSType)[restoreDict[@"manufacturer"] unsignedIntegerValue];
    }
    
    if (restoreDict[@"name"])
    {
        self.name = restoreDict[@"name"];
    }
    
    if (restoreDict[@"bypass"])
    {
        self.bypass = [restoreDict[@"bypass"] boolValue];
    }
    
    if (restoreDict[@"effectSettings"])
    {
        _auClassData = restoreDict[@"effectSettings"];
    }
}



-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    NSNumber *subType = [NSNumber numberWithUnsignedInteger:unitDescr.componentSubType];
    NSNumber *manufacturer = [NSNumber numberWithUnsignedInteger:unitDescr.componentManufacturer];
    NSNumber *auType = [NSNumber numberWithUnsignedInteger:unitDescr.componentType];
    
    [saveDict setObject:subType forKey:@"subType"];
    [saveDict setObject:manufacturer forKey:@"manufacturer"];
    [saveDict setObject:auType forKey:@"componentType"];
    [saveDict setObject:self.name forKey:@"name"];
    [saveDict setObject:[NSNumber numberWithBool:self.bypass] forKey:@"bypass"];
    
    CFPropertyListRef saveData;
    UInt32 size = sizeof(CFPropertyListRef);
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &saveData, &size);
    
    if (saveData)
    {
        [saveDict setObject:(NSDictionary *)CFBridgingRelease(saveData) forKey:@"effectSettings"];
    }
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
    
    if (ret && !self.name)
    {
        AudioComponent comp = AudioComponentFindNext(NULL, &unitDescr);
        CFStringRef cName;
        AudioComponentCopyName(comp, &cName);
        self.name = CFBridgingRelease(cName);
    }
    
    if (self.audioUnit && _auClassData)
    {
        CFDictionaryRef cfValue = (__bridge CFDictionaryRef)_auClassData;
        
        UInt32 size = sizeof(cfValue);
        
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &cfValue, size);
    }
    
    [self setAudioUnitBypass];
    
    return ret;
}

-(void)selectPresetNumber:(SInt32)presetNumber
{
    if (self.audioUnit)
    {
        AUPreset auPreset = {0};
        auPreset.presetNumber = presetNumber;
        
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, &auPreset, sizeof(auPreset));
        AudioUnitParameter changeMsg;
        changeMsg.mAudioUnit = self.audioUnit;
        changeMsg.mParameterID = kAUParameterListener_AnyParameter;
        AUParameterListenerNotify(NULL, NULL, &changeMsg);
    }
}


-(NSArray *)effectPresets
{
    NSMutableArray *presetRet = [NSMutableArray array];
    CFArrayRef presets = NULL;
    UInt32 size = sizeof(presets);
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_FactoryPresets, kAudioUnitScope_Global, 0, &presets, &size);
    if (presets)
    {
        
        UInt8 preset_cnt = CFArrayGetCount(presets);
        for(int i = 0; i < preset_cnt; i++)
        {
            AUPreset *preset = (AUPreset *)CFArrayGetValueAtIndex(presets, i);
            NSString *presetName = CFBridgingRelease(preset->presetName);
            
            [presetRet addObject:@{@"name": presetName, @"number": [NSNumber numberWithInt:preset->presetNumber]}];
        }
        CFRelease(presets);
    }
    return presetRet;
}

@end
