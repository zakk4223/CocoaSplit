//
//  CAMultiAudioDevice.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioDevice.h"


@implementation CAMultiAudioDevice


-(instancetype)initWithDeviceID:(NSString *)uid
{
    if (self = [super initWithSubType:kAudioUnitSubType_HALOutput unitType:kAudioUnitType_Output])
    {
        self.deviceUID = uid;
        self.deviceID = [self lookupUID:uid];
    }
    
    return self;
}



-(void)setInputForDevice
{
    UInt32 enableIO;
    
    enableIO = 1;
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, sizeof(enableIO));
    
    enableIO = 0;
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 1, &enableIO, sizeof(enableIO));
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &_deviceID, sizeof(_deviceID));

    
}


-(void)setOutputForDevice
{
    UInt32 enableIO;
    
    enableIO = 0;
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableIO, sizeof(enableIO));
    
    enableIO = 1;
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 1, &enableIO, sizeof(enableIO));
    
    AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, &_deviceID, sizeof(_deviceID));
}


-(AudioDeviceID)lookupUID:(NSString *)uid
{
    AudioDeviceID deviceID;
    
    UInt32 propSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress deviceProperty;
    deviceProperty.mSelector = kAudioHardwarePropertyDeviceForUID;
    deviceProperty.mScope = kAudioObjectPropertyScopeGlobal;
    deviceProperty.mElement = kAudioObjectPropertyElementMaster;
    
    AudioValueTranslation translation = {};
    
    CFStringRef cfUID = CFBridgingRetain(uid);
    
    
    translation.mInputData = &cfUID;
    
    translation.mInputDataSize = sizeof(CFStringRef);
    translation.mOutputData = &deviceID;
    translation.mOutputDataSize = propSize;
    UInt32 tSize = sizeof(translation);
    
    NSLog(@"GET AUDIO OBJECT DATA");
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &deviceProperty, 0, NULL, &tSize, &translation);
    NSLog(@"DEVICE ID %d FOR UID %@", deviceID, uid);
    CFRelease(cfUID);
    return deviceID;
}



@end
