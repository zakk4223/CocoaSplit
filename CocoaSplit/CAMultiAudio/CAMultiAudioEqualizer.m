//
//  CAMultiAudioEqualizer.m
//  CocoaSplit
//
//  Created by Zakk on 7/25/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioEqualizer.h"

@implementation CAMultiAudioEqualizer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_GraphicEQ unitType:kAudioUnitType_Effect])
    {
        
    }
    
    return self;
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
