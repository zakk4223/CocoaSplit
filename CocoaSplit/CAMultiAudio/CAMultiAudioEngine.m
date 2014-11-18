//
//  CAMultiAudioEngine.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioEngine.h"

OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData );


@implementation CAMultiAudioEngine

@synthesize sampleRate = _sampleRate;
@synthesize outputNode = _outputNode;

-(instancetype)initWithSamplerate:(UInt32)sampleRate
{
    if (self = [super init])
    {
        self.sampleRate = sampleRate;

        self.audioInputs = [NSMutableArray array];
        self.audioOutputs = [[CAMultiAudioDevice allDevices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasOutput == YES"]];
        AudioDeviceID defaultID = [CAMultiAudioDevice defaultOutputDeviceID];
        NSUInteger defaultIdx = [self.audioOutputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return ((CAMultiAudioDevice *)obj).deviceID == defaultID;
        }];
        
        _outputNode = [self.audioOutputs objectAtIndex:defaultIdx];
        
        
        [self buildGraph];
        [self inputsForSystemAudio];


    }
    
    return self;
}


-(void)updateStatistics
{
    for(CAMultiAudioNode *node in self.audioInputs)
    {
        [node updatePowerlevel];
    }
}


-(bool)buildGraph
{
    self.graph = [[CAMultiAudioGraph alloc] init];
    self.graph.sampleRate = self.sampleRate;
    if (!self.graphOutputNode)
    {
        self.graphOutputNode = self.outputNode;
        

    }
    
    
    self.silentNode = [[CAMultiAudioPCMPlayer alloc] init];
    self.encodeMixer = [[CAMultiAudioMixer alloc] init];
    self.previewMixer = [[CAMultiAudioMixer alloc] init];
    
    [self.graph addNode:self.outputNode];
    
    if ([self.graphOutputNode respondsToSelector:@selector(setOutputForDevice)])
    {
        [self.graphOutputNode setOutputForDevice];
    }
    
    
    [self.graph addNode:self.silentNode];
    [self.graph addNode:self.encodeMixer];
    [self.graph addNode:self.previewMixer];
    
    [self.graph connectNode:self.previewMixer toNode:self.graphOutputNode];
    [self.graph connectNode:self.encodeMixer toNode:self.previewMixer];
    [self.graph connectNode:self.silentNode toNode:self.encodeMixer];
    [self.graph startGraph];
    
    AudioUnitAddRenderNotify(self.encodeMixer.audioUnit, encoderRenderCallback, (__bridge void *)(self));
    CAShow(self.graph.graphInst);

    return YES;
}


-(void)inputsForSystemAudio
{
    NSArray *sysDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    for(AVCaptureDevice *dev in sysDevices)
    {
        CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:dev sampleRate:self.sampleRate];
        [self attachInput:avplayer];
    }
}


-(CAMultiAudioDevice *)outputNode
{
    return _outputNode;
}


-(void)setOutputNode:(CAMultiAudioDevice *)outputNode
{
    NSLog(@"SET OUTPUT NODE %@", outputNode.name);
    _outputNode = outputNode;
    if (self.graphOutputNode)
    {
        self.graphOutputNode.deviceID = outputNode.deviceID;
        [self.graphOutputNode setOutputForDevice];
    }
}




-(void)resetEngine
{
    if (!self.graph)
    {
        return;
    }
    
    [self.graph stopGraph];
    self.graph = nil;
    [self buildGraph];
    for (CAMultiAudioNode *node in self.audioInputs)
    {
        [node resetSamplerate:self.sampleRate];
        [self.graph addNode:node];
        [self.graph connectNode:node toNode:self.encodeMixer];
        
    }
    
}
-(UInt32)sampleRate
{
    return _sampleRate;
}


-(void)setSampleRate:(UInt32)sampleRate
{
    UInt32 old_samplerate = _sampleRate;
    _sampleRate = sampleRate;
    
    if (sampleRate > 0 && (sampleRate != old_samplerate))
    {
        //It's easier to just rebuild the graph instead of trying to splunk through all the nodes and connections
        //to change them all.
        [self resetEngine];
    }
    
}



-(void)attachInput:(CAMultiAudioNode *)input
{
    [self.graph addNode:input];
    [self.graph connectNode:input toNode:self.encodeMixer];
    [self addAudioInputsObject:input];
    

    
    
}


-(void)removeInput:(CAMultiAudioNode *)toRemove
{
    NSUInteger index = [self.audioInputs indexOfObject:toRemove];
    [self removeObjectFromAudioInputsAtIndex:index];
    
}

-(void)addAudioInputsObject:(CAMultiAudioNode *)object
{
    [self insertObject:object inAudioInputsAtIndex:self.audioInputs.count];
}

-(void)insertObject:(CAMultiAudioNode *)object inAudioInputsAtIndex:(NSUInteger)index
{
    [self.audioInputs insertObject:object atIndex:index];
}


-(void)removeObjectFromAudioInputsAtIndex:(NSUInteger)index
{
    CAMultiAudioNode *toRemove = [self.audioInputs objectAtIndex:index];
    [self.graph removeNode:toRemove];
    [self.audioInputs removeObjectAtIndex:index];
}

@end

OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData )
{
    if ((*ioActionFlags) & kAudioUnitRenderAction_PostRender)
    {
         
        CAMultiAudioEngine *selfPtr = (__bridge CAMultiAudioEngine *)inRefCon;
        
        if (selfPtr.encoder)
        {
            [selfPtr.encoder enqueuePCM:ioData atTime:inTimeStamp];
        }
        

    }
    return noErr;
    
}

