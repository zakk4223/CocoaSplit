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
        self.inputChannelCount = channels;
    }
    return self;
}




-(void)setOutputVolume
{
    AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, 0xFFFFFFFF, self.volume, 0);
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
        //err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_MeteringMode, kAudioUnitScope_Output, 0, &enableVal, sizeof(enableVal));
        
        if (err)
        {
            NSLog(@"SET METERING MODE FAILED FOR BUS %d ERR %d", bus, err);
        }
    }
}

-(Float32)powerForOutputBus:(UInt32)bus
{
    Float32 result = 0;
    OSStatus err;
    
    err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Output, bus, &result);
    //err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Output, 0, &result);
    
    
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
    //err = AudioUnitGetParameter(self.audioUnit, kStereoMixerParam_PostAveragePower, kAudioUnitScope_Output, 0, &result);
    
    
    if (err)
    {
        NSLog(@"GET POWER ERROR %d", err);
    }
    
    return result;
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


-(bool)createNode:(CAMultiAudioGraph *)forGraph
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


-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus
{
    AudioStreamBasicDescription nformat;
    AudioStreamBasicDescription sformat;
    UInt32 fsize = sizeof(nformat);
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, toBus, &sformat, &fsize);
    AudioUnitGetProperty(node.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &nformat, &fsize);

}
-(void)setVolumeOnOutputBus:(UInt32)bus volume:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:bus volume:volume];
}

-(void)setVolumeOnOutput:(float)volume
{
    [self setVolumeForScope:kAudioUnitScope_Output onBus:0 volume:volume];
}


-(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    bool ret =     [super setOutputStreamFormat:format];

    self.outputChannelCount = format->mChannelsPerFrame;

    return ret;
}


-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    
    
    AudioStreamBasicDescription fCopy;
    
    
    memcpy(&fCopy, format, sizeof(fCopy));
    
    
    fCopy.mChannelsPerFrame = _inputChannels;
    
    
    return [super setInputStreamFormat:&fCopy];
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
        
        [self setVolume:1.0 forChannel:chan outChannel:outChan];
        
    }

    
    
}

-(Float32)getVolumeforChannel:(UInt32)inChannel outChannel:(UInt32)outChannel
{
    UInt32 xElem = (inChannel << 16) | (outChannel & 0x0000FFFF);
    Float32 ret = 0.0f;
    
    OSStatus err = AudioUnitGetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, xElem, &ret);
    
    if (err)
    {
        NSLog(@"Failed to get crosspoint volume for channel %d -> %d  on %@ with status %d", inChannel, outChannel, self, err);
    }
 
    return ret;
    
}
-(void)setVolume:(float)volume forChannel:(UInt32)inChannel outChannel:(UInt32)outChannel
{
    UInt32 xElem = (inChannel << 16) | (outChannel & 0x0000FFFF);
    OSStatus err = AudioUnitSetParameter(self.audioUnit, kMatrixMixerParam_Volume, kAudioUnitScope_Global, xElem, volume,0);
    if (err)
    {
        NSLog(@"Failed to set crosspoint volume for channel %d -> %d  on %@ with status %d", inChannel, outChannel, self, err);
    }
}


-(void)restoreData:(NSDictionary *)saveData
{
    UInt32 inputCount = [[saveData objectForKey:@"inputChannels"] unsignedIntValue];
    UInt32 outputCount = [[saveData objectForKey:@"outputChannels"] unsignedIntValue];
    NSData *data = [saveData objectForKey:@"data"];

    NSUInteger dataSize = data.length;
    
    if ((dataSize % sizeof(Float32)))
    {
        return;
    }
    
    
    Float32 *levels = malloc(dataSize);
    
    [data getBytes:levels length:dataSize];
    
    
    for (int ichan = 0; ichan < inputCount; ichan++)
    {
        if (ichan >= self.inputChannelCount)
        {
            break;
        }
        
        for (int ochan = 0; ochan < outputCount; ochan++)
        {
            if (ochan >= self.outputChannelCount)
            {
                break;
            }
            
            Float32 xpoint = levels[(ichan * (outputCount+1)) + ochan];
            [self setVolume:xpoint forChannel:ichan outChannel:ochan];
        }
    }
    if (levels)
    {
        free(levels);
    }
}

-(NSDictionary *)saveData
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    UInt32 levelSize = (self.inputChannelCount+1)*(self.outputChannelCount+1)*sizeof(Float32);

    Float32 *levelData = malloc(levelSize);
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_MatrixLevels, kAudioUnitScope_Global, 0, levelData, &levelSize);
    
    NSData *levels = [NSData dataWithBytesNoCopy:levelData length:levelSize freeWhenDone:YES];
    [ret setObject:@(self.inputChannelCount) forKey:@"inputChannels"];
    [ret setObject:@(self.outputChannelCount) forKey:@"outputChannels"];
    [ret setObject:levels forKey:@"data"];
    return ret;
}


-(Float32 *)getMixerVolumes
{
    
    Float32 *ret = malloc((self.inputChannelCount+1)*(self.outputChannelCount+1));
    UInt32 levelSize;
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_MatrixLevels, kAudioUnitScope_Global, 0, ret, &levelSize);
    
    return ret;
}



@end
