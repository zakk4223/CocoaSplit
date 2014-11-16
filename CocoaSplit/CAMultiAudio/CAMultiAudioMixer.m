//
//  CAMultiAudioMixer.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioMixer.h"

@implementation CAMultiAudioMixer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_StereoMixer unitType:kAudioUnitType_Mixer])
    {
        _nextElement = 0;
        
    }
    
    return self;
}

-(bool)createNode:(AUGraph)forGraph
{
    [super createNode:forGraph];
    
    UInt32 elementCount = 15;
    
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,&elementCount, sizeof(UInt32));
    
    NSLog(@"SET ELEMENTS %d", err);

    err = AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, self.volume, 0);
    
    return YES;
    
}


-(void)setOutputVolume
{
    AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, self.volume, 0);
}

-(void)setVolume:(float)volume
{
    super.volume = volume;
    
    
    [self setOutputVolume];
    
}


-(UInt32)inputElement
{
    return [self getNextElement];

}



-(UInt32)getNextElement
{
    UInt32 elementCount = 0;
    UInt32 elementSize = 0;
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, &elementSize);
    
    /*
    UInt32 interactionCnt = elementCount*2;
    AUNodeInteraction *interactions = malloc(sizeof(AUNodeInteraction)*interactionCnt);
    
    
    AUGraphGetNodeInteractions(self.graph.graphInst, self.node, &interactionCnt, interactions);
    */
    
    //Naive implementation. bump up element count by one and return that as the bus to connect to.
    
    //elementCount = 3;

    //NSLog(@"RETURNING ELEMENT %d", elementCount-1);
    return _nextElement++;
}


-(void)setVolumeForScope:(AudioUnitScope)scope onBus:(AudioUnitElement)onBus volume:(float)volume
{
    if (!self.audioUnit)
    {
        NSLog(@"SetVolumeForScope for %@ failed, no AudioUnit!?",self);
        return;
    }
    OSStatus err;
    
    err = AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, scope, onBus, volume, 0);
    if (err)
    {
        NSLog(@"SetVolumeForScope for %@: AUSetParameter failed, err: %d", self, err);
        return;
    }
}


-(void)setVolumeOnInputBus:(UInt32)bus volume:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Input onBus:bus volume:volume];
}


-(void)setVolumeOnOutputBus:(UInt32)bus volume:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:bus volume:volume];
}

-(void)setVolumeOnOutput:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:0 volume:volume];
}





@end
