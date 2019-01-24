//
//  CAMultiAudioMixer.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//

#import "CAMultiAudioMixer.h"

@implementation CAMultiAudioMixer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_MultiChannelMixer unitType:kAudioUnitType_Mixer])
    {
        _nextElement = 0;
        
    }
    
    return self;
}

-(void)willInitializeNode
{
    UInt32 elementCount = 64;
    
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0,&elementCount, sizeof(UInt32));
    
    
    err = AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, self.volume, 0);
    UInt32 enableVal = 1;
    
    
    AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Global, 0, &enableVal, sizeof(enableVal));
    

}
-(void)setOutputVolume
{
    AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Output, 0, self.volume, 0);
}

-(void)setVolume:(float)volume
{
    NSLog(@"MIXER %@ VOLUME %f", self, volume);
    super.volume = volume;
    
    
    [self setOutputVolume];
 
    
}

-(void)setEnabled:(bool)enabled
{
    UInt32 elementCount = 0;
    UInt32 elementSize = sizeof(UInt32);
    
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, &elementSize);
    
    for (UInt32 i = 0; i < elementCount; i++)
    {
        AudioUnitSetParameter(self.audioUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, i, enabled, 0);
    }

    [super setEnabled:enabled];

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


-(Float32)outputPower
{
    Float32 result = 0;
    OSStatus err;
    
    
    err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Output, 0, &result);
    
    
    if (err)
    {
        NSLog(@"GET POWER ERROR %d", err);
    }
    
    return result;

}


-(Float32)powerForOutputBus:(UInt32)bus
{
    Float32 result = 0;
    OSStatus err;
    
    //err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Output, bus, &result);
    err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower+bus, kAudioUnitScope_Output, 0, &result);
    
    
    if (err)
    {
        NSLog(@"GET POWER ERROR %d", err);
    }
    
    return result;
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



-(UInt32)inputElement
{
    return [self getNextElement];

}



-(UInt32)getNextElement
{
    UInt32 elementCount = 0;
    UInt32 elementSize = sizeof(UInt32);
    
    UInt32 useElement = 0;
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, &elementSize);
    
    UInt32 interactionCnt = 0;
    
    AUGraphCountNodeInteractions(self.graph.graphInst, self.node, &interactionCnt);
    AUNodeInteraction *interactions = malloc(sizeof(AUNodeInteraction)*interactionCnt);
    
    
    AUGraphGetNodeInteractions(self.graph.graphInst, self.node, &interactionCnt, interactions);
    
    useElement = 0;
    UInt32 seenIdx = 0;
    
    for (int i=0; i < interactionCnt; i++)
    {
        
        AUNodeInteraction iact = interactions[i];
        if (iact.nodeInteractionType == kAUNodeInteraction_Connection && iact.nodeInteraction.connection.destNode == self.node)
        {
            if (seenIdx != iact.nodeInteraction.connection.destInputNumber)
            {
                useElement = seenIdx;
                break;
            } else {
                seenIdx++;
                useElement = iact.nodeInteraction.connection.destInputNumber+1;
            }
            
        }
    }
    
    free(interactions);
    if (useElement >= elementCount)
    {
        elementCount += 64;
        AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, sizeof(elementCount));
    }

    [self setVolumeOnInputBus:useElement volume:1.0];
    return useElement;
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
