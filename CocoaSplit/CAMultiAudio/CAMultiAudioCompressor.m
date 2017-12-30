//
//  CAMultiAudioCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioCompressor.h"

@implementation CAMultiAudioCompressor

@synthesize bypass = _bypass;

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_MultiBandCompressor unitType:kAudioUnitType_Effect])
    {
        
    }
    
    return self;
}

-(bool) bypass
{
    return _bypass;
}

-(void) setBypass:(bool)bypass
{
    _bypass = bypass;
    if (self.node)
    {
        UInt32 bypassVal = 0;
        if (bypass)
        {
            bypassVal = 1;
        } else {
            bypassVal = 0;
        }
        
        
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_BypassEffect, kAudioUnitScope_Global, 0, &bypassVal, sizeof(bypassVal));
        if (bypass)
        {
            AudioComponentDescription adesc;
            adesc.componentManufacturer = 0;
            adesc.componentType = kAudioUnitType_Effect;
            adesc.componentSubType = 0;
            
            AudioComponent nextComponent = AudioComponentFindNext(NULL, &adesc);
            while (nextComponent)
            {
                CFStringRef auName = NULL;
                AudioComponentCopyName(nextComponent, &auName);
                NSLog(@"COMPONENT NAME %@", auName);
                nextComponent = AudioComponentFindNext(nextComponent, &adesc);
            }
            
            
            AUPreset cPreset;
            cPreset.presetNumber = 0;
            UInt32 cSize = sizeof(cPreset);
            AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_PresentPreset, kAudioUnitScope_Global, 0, &cPreset, cSize);
            AudioUnitEvent myEvent;
            myEvent.mEventType = kAudioUnitEvent_PropertyChange;
            myEvent.mArgument.mProperty.mAudioUnit = self.audioUnit;
            myEvent.mArgument.mProperty.mPropertyID = kAudioUnitProperty_PresentPreset;
            myEvent.mArgument.mProperty.mScope = kAudioUnitScope_Global;
            myEvent.mArgument.mProperty.mElement = 0;
            AUEventListenerNotify(NULL, NULL, &myEvent);
        }
    }
}


-(bool)createNode:(CAMultiAudioGraph *)forGraph
{
    if ([super createNode:forGraph])
    {
        UInt32 bypassVal = 0;
        if (self.bypass)
        {
            bypassVal = 1;
        } else {
            bypassVal = 0;
        }
        
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_BypassEffect, kAudioUnitScope_Global, 0, &bypassVal, sizeof(bypassVal));
        return YES;
    }
    
    return NO;
}


-(NSDictionary *)saveData
{
    CFPropertyListRef saveData;
    UInt32 size = sizeof(CFPropertyListRef);
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &saveData, &size);
    
    if (saveData)
    {
        return (NSDictionary *)CFBridgingRelease(saveData);
    }
    return nil;
}

-(void)restoreData:(NSDictionary *)saveData
{
    CFDictionaryRef cfValue = (__bridge CFDictionaryRef)saveData;
    
    UInt32 size = sizeof(cfValue);
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &cfValue, size);
    
}

@end
