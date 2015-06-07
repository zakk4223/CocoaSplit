//
//  CAMultiAudioDownmixer.m
//  CocoaSplit
//
//  Created by Zakk on 6/3/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CAMultiAudioDownmixer.h"
#import "CAMultiAudioGraph.h"
#import "math.h"

@implementation CAMultiAudioDownmixer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_MatrixMixer unitType:kAudioUnitType_Mixer])
    {
        
    }
    
    return self;
}

-(instancetype)initWithInputChannels:(int)channels
{
    if (self = [self init])
    {
        _inputChannels = channels;
    }
    return self;
}




-(void)setOutputVolume
{
    AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, 0, self.volume, 0);
}


-(void)setVolume:(float)volume
{
    super.volume = volume;
    
    
    [self setOutputVolume];
    
}

-(void)enableMeteringOnInputBus:(UInt32)bus
{
    if (self.audioUnit)
    {
        UInt32 enableVal = 1;
        OSStatus err;
        err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Input, bus, &enableVal, sizeof(enableVal));
        
        if (err)
        {
            NSLog(@"SET METERING MODE FAILED FOR BUS %d ERR %d", bus, err);
        }
    }
}


-(Float32)powerForInputBus:(UInt32)bus
{
    Float32 result = 0;
    OSStatus err;
    
    err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Input, bus, &result);
    
    
    if (err)
    {
        NSLog(@"GET POWER ERROR %d", err);
    }
    
    return result;
}




-(void)setVolumeForScope:(AudioUnitScope)scope onBus:(AudioUnitElement)onBus volume:(float)volume
{
    if (!self.audioUnit)
    {
        NSLog(@"SetVolumeForScope for %@ failed, no AudioUnit!?",self);
        return;
    }
    OSStatus err;
    
    
    err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, scope, onBus, volume, 0);
    if (err)
    {
        NSLog(@"SetVolumeForScope for %@: AUSetParameter failed, err: %d", self, err);
        return;
    }
}


-(void)setVolumeOnInputBus:(UInt32)bus volume:(float)volume
{
    //Downmixers only have one input bus, so just set the global volume to whatever is requested instead of messing around with all the channels.
    
    [self setVolumeForScope:kAudioUnitScope_Global onBus:0xFFFFFFFF volume:volume];
}


-(bool)createNode:(AUGraph)forGraph
{
    [super createNode:forGraph];
    
    //Create the input and output elements
    
    OSStatus err;
    UInt32 elementCount = 1;
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, sizeof(UInt32));
    if (err)
    {
        NSLog(@"Failed to set number of input elements on %@ with status %d", self, err);
    }
    
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Output, 0, &elementCount, sizeof(UInt32));
    if (err)
    {
        NSLog(@"Failed to set number of output elements on %@ with status %d", self, err);
    }

    UInt32 enabled = 1;
    
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Global, 0, &enabled, sizeof(enabled));
    
    return YES;
    
}



-(void)setVolumeOnOutputBus:(UInt32)bus volume:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:bus volume:volume];
}

-(void)setVolumeOnOutput:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:0 volume:volume];
}


-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    
    
    AudioStreamBasicDescription fCopy;
    
    memcpy(&fCopy, format, sizeof(fCopy));
    
    fCopy.mChannelsPerFrame = _inputChannels;
    
    [super setInputStreamFormat:&fCopy];
}

-(void)didInitializeNode
{
    //Enable both input and output busses
    OSStatus err;
    
    err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Enable, kAudioUnitScope_Input, 0, 1, 0);
    if (err)
    {
        NSLog(@"Failed to enable input on %@ with status %d", self, err);
    }
    
    err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Enable, kAudioUnitScope_Output, 0, 1, 0);
    if (err)
    {
        NSLog(@"Failed to enable output on %@ with status %d", self, err);
    }

    //Set Master Volume
    
    err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0xFFFFFFFF, 1.0, 0);
    if (err)
    {
        NSLog(@"Failed to set master volume on %@ with status %d", self, err);
    }
    
    
    //Set output volume for all channels
    for (UInt32 chan = 0; chan < self.graph.graphAsbd->mChannelsPerFrame; chan++) {
        err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Output, chan, 1.0, 0);
        if (err)
        {
            NSLog(@"Failed to set output volume for channel %d on %@ with status %d", chan, self, err);
        }
    }
    
    //set volume for all input channels
    for (UInt32 chan = 0; chan < _inputChannels; chan++) {
        err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Input, chan, 1.0, 0);
        if (err)
        {
            NSLog(@"Failed to set input volume for channel %d on %@ with status %d", chan, self, err);
        }
        
        //also set crosspoint volumes.
        UInt32 outChan = chan % self.graph.graphAsbd->mChannelsPerFrame;
        UInt32 xElem = (chan << 16) | (outChan & 0x0000FFFF);
        
        err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, xElem, 1.0, 0);
        if (err)
        {
            NSLog(@"Failed to set crosspoint volume for channel %d -> %d  on %@ with status %d", chan, outChan, self, err);
        }

    }

    
    
}

-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus
{
    

}
-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus
{
    OSStatus err;
}

@end
