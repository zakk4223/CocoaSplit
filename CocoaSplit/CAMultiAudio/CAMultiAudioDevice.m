//
//  CAMultiAudioDevice.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioDevice.h"


@implementation CAMultiAudioDevice



-(instancetype)initWithDeviceID:(AudioDeviceID)devid
{
    if (self = [super initWithSubType:kAudioUnitSubType_HALOutput unitType:kAudioUnitType_Output])
    {
        self.deviceID = devid;
    }
    
    return self;

}


-(instancetype)initWithDeviceUID:(NSString *)uid
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

-(AudioStreamBasicDescription *)getOutputFormat
{
    AudioStreamBasicDescription *outfmt = malloc(sizeof(AudioStreamBasicDescription));
    UInt32 outsize = sizeof(AudioStreamBasicDescription);
    
    OSStatus err = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, outfmt, &outsize);
    
    NSLog(@"MY OUTPUT FORMAT %d %f", err, outfmt->mSampleRate);
    
    return outfmt;
}



-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    [super setInputStreamFormat:[self getOutputFormat]];
    
}


-(void)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    return;
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
    
    AudioObjectGetPropertyData(kAudioObjectSystemObject, &deviceProperty, 0, NULL, &tSize, &translation);
    CFRelease(cfUID);
    return deviceID;
}


+(NSString *)defaultOutputDeviceUID
{
    AudioDeviceID defaultID = [self defaultOutputDeviceID];
    
    
    CFStringRef deviceUID = NULL;
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioDevicePropertyDeviceUID;
    propAddress.mElement = kAudioObjectPropertyElementMaster;
    propAddress.mScope = kAudioDevicePropertyScopeInput;

    
    UInt32 datasize = sizeof(deviceUID);
    
    OSStatus err;
    
    err = AudioObjectGetPropertyData(defaultID, &propAddress, 0, NULL, &datasize, &deviceUID);
    if (kAudioHardwareNoError != err)
    {
        NSLog(@"Couldn't get device UID for device ID %d, err: %d", defaultID, err);
    }

    NSString *retval = CFBridgingRelease(deviceUID);
    return retval;
}

+(AudioDeviceID)defaultOutputDeviceID
{
    UInt32 datasize = 0;
    AudioDeviceID defaultDevice;
    
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMaster;
    
    datasize = sizeof(AudioDeviceID);
    OSStatus err;
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propAddress, 0, NULL, &datasize, &defaultDevice);
    
    
    
    return defaultDevice;
}



+(NSMutableArray *)allDevices
{
    UInt32 datasize = 0;
    OSStatus err;
    NSMutableArray *deviceList = [NSMutableArray array];
    CAMultiAudioDevice *newDevice;
    
    AudioObjectPropertyAddress propAddress;
    propAddress.mSelector = kAudioHardwarePropertyDevices;
    propAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propAddress.mElement = kAudioObjectPropertyElementMaster;
    
    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propAddress, 0, NULL, &datasize);
    if (kAudioHardwareNoError != err)
    {
        NSLog(@"Couldn't get size of AudioDeviceID list, err: %d", err);
        return nil;
    }
    
    UInt32 numDevices = (datasize/sizeof(AudioDeviceID));
    AudioDeviceID *deviceIDs = malloc(datasize);
    
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propAddress, 0, NULL, &datasize, deviceIDs);
    if (kAudioHardwareNoError != err)
    {
        NSLog(@"Couldn't get list of AudioDeviceIDs, err: %d", err);
        free(deviceIDs);
        return nil;
    }
    
    for (int i = 0; i < numDevices; i++)
    {
        CFStringRef deviceUID = NULL;
        CFStringRef deviceName = NULL;
        
        propAddress.mScope = kAudioDevicePropertyScopeInput;
        
        datasize = sizeof(deviceUID);
        
        propAddress.mSelector = kAudioDevicePropertyDeviceUID;
        err = AudioObjectGetPropertyData(deviceIDs[i], &propAddress, 0, NULL, &datasize, &deviceUID);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Couldn't get device UID for device ID %d, err: %d", deviceIDs[i], err);
            continue;
        }
        
        datasize = sizeof(deviceName);
        
        propAddress.mSelector = kAudioObjectPropertyName;
        err = AudioObjectGetPropertyData(deviceIDs[i], &propAddress, 0, NULL, &datasize, &deviceName);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Couldn't get device Name for device ID %d, err: %d", deviceIDs[i], err);
            continue;
        }
        
        newDevice = [[CAMultiAudioDevice alloc] initWithDeviceID:deviceIDs[i]];
        newDevice.deviceUID = CFBridgingRelease(deviceUID);
        newDevice.name = CFBridgingRelease(deviceName);

        
        datasize = 0;
        
        propAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
        
        err = AudioObjectGetPropertyDataSize(deviceIDs[i], &propAddress, 0, NULL, &datasize);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Couldn't get StreamConfiguration size for Device ID %d, err: %d", deviceIDs[i], err);
            continue;
        }
        
        
        
        //This is the input buffer list
        AudioBufferList *bufferList = malloc(datasize);
        
        err = AudioObjectGetPropertyData(deviceIDs[i], &propAddress, 0, NULL, &datasize, bufferList);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Error getting input audio buffer list for device ID %d, err: %d", deviceIDs[i], err);
        } else if (bufferList->mNumberBuffers > 0) {
            newDevice.hasInput = YES;
        }
        
        free(bufferList);
        
        datasize = 0;
        
        propAddress.mScope = kAudioDevicePropertyScopeOutput;
        
        err = AudioObjectGetPropertyDataSize(deviceIDs[i], &propAddress, 0, NULL, &datasize);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Couldn't get StreamConfiguration size for Device ID %d, err: %d", deviceIDs[i], err);
            continue;
        }
        
        
        
        //This is the output buffer list
        bufferList = malloc(datasize);
        
        err = AudioObjectGetPropertyData(deviceIDs[i], &propAddress, 0, NULL, &datasize, bufferList);
        if (kAudioHardwareNoError != err)
        {
            NSLog(@"Error getting input audio buffer list for device ID %d, err: %d", deviceIDs[i], err);
        } else if (bufferList->mNumberBuffers > 0) {
            newDevice.hasOutput = YES;
        }
        
        free(bufferList);
        
        [deviceList addObject:newDevice];
    }
    
    return deviceList;
}

@end
