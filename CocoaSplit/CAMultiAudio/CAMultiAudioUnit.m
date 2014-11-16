//
//  CAMultiAudioUnit.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioUnit.h"

@implementation CAMultiAudioUnit

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    if (self = [super init])
    {
        AudioComponent comp = {0};
        AudioComponentDescription desc = {0};
        
        desc.componentType = unitType;
        desc.componentSubType = subType;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        comp = AudioComponentFindNext(NULL, &desc);
        if (comp)
        {
            AudioComponentInstanceNew(comp, &_audioUnit);
            OSStatus err;
            err = AudioUnitInitialize(_audioUnit);
            NSLog(@"AU INIT %d", err);

        }
        
        
    }
    
    return self;
}

-(void)connect:(AudioUnit)toNode
{
    AudioUnitConnection conn;
    
    conn.sourceAudioUnit = _audioUnit;
    conn.sourceOutputNumber = 1;
    conn.destInputNumber = 1;
    OSStatus err;
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 asbdSize = sizeof(asbd);
    
    AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, &asbdSize);

    NSLog(@"OUTPUT ASBD SAMPLERATE %f", asbd.mSampleRate);
    
    err = AudioUnitSetProperty(toNode, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 1, &conn, sizeof(conn));
    NSLog(@"UNIT SET CONN %d", err);
    
    err = AudioUnitSetProperty(toNode, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &asbd, asbdSize);
    
    AudioUnitInitialize(_audioUnit);
    
    
}

-(void)openUnit
{
    CAShow(_audioUnit);
    
    OSStatus err = AudioOutputUnitStart(_audioUnit);
    NSLog(@"AU OUTPUT START %d", err);
}

@end
