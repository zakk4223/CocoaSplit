//
//  CAMultiAudioEngine.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioEngine.h"
#import "CAMultiAudioDownmixer.h"
#import "CAMultiAudioDelay.h"


OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData );


@implementation CAMultiAudioEngine

@synthesize sampleRate = _sampleRate;
@synthesize outputNode = _outputNode;


-(void)commonInit
{
    _inputSettings = [NSMutableDictionary dictionary];

    self.audioInputs = [NSMutableArray array];
    self.pcmInputs = [NSMutableArray array];
    self.validSamplerates = @[@44100, @48000];
    self.sampleRate = 44100;
    self.audioOutputs = [[CAMultiAudioDevice allDevices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasOutput == YES"]];

    _outputId = [CAMultiAudioDevice defaultOutputDeviceUID];
    
    
    

    
}
-(instancetype)init
{
    if (self = [super init])
    {
        [self commonInit];
        
        [self buildGraph];
        [self inputsForSystemAudio];
        self.encodeMixer.volume = 1.0;
        self.encodeMixer.muted = NO;
        self.previewMixer.volume = 1.0;
        self.previewMixer.muted  = NO;
}
    
    return self;
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self commonInit];
        
        if ([aDecoder containsValueForKey:@"sampleRate"])
        {
            self.sampleRate = [aDecoder decodeInt32ForKey:@"sampleRate"];
        }
        
        if ([aDecoder containsValueForKey:@"selectedAudioId"])
        {
            
            NSString *savedUID = [aDecoder decodeObjectForKey:@"selectedAudioId"];
            if (savedUID)
            {
                _outputId = savedUID;
            }
            
        }
        

        
        
        
        if ([aDecoder containsValueForKey:@"inputSettings"])
        {
            _inputSettings = [aDecoder decodeObjectForKey:@"inputSettings"];
        }
        
        
        
        [self buildGraph];
        [self inputsForSystemAudio];
        if ([aDecoder containsValueForKey:@"streamVolume"])
        {
            self.encodeMixer.volume = [aDecoder decodeFloatForKey:@"streamVolume"];
        }
        
        if ([aDecoder containsValueForKey:@"streamMuted"])
        {
            self.encodeMixer.muted = [aDecoder decodeBoolForKey:@"streamMuted"];
        }
        
        if ([aDecoder containsValueForKey:@"previewVolume"])
        {
            self.previewMixer.volume = [aDecoder decodeFloatForKey:@"previewVolume"];
        }
        
        if ([aDecoder containsValueForKey:@"previewMuted"])
        {
            self.previewMixer.muted = [aDecoder decodeBoolForKey:@"previewMuted"];
        }
        
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt32:self.sampleRate forKey:@"sampleRate"];
    [aCoder encodeObject:self.outputNode.deviceUID forKey:@"selectedAudioId"];
    [aCoder encodeFloat:self.encodeMixer.volume forKey:@"streamVolume"];
    [aCoder encodeBool:self.encodeMixer.muted forKey:@"streamMuted"];
    [aCoder encodeFloat:self.previewMixer.volume forKey:@"previewVolume"];
    [aCoder encodeBool:self.previewMixer.muted forKey:@"previewMuted"];
    
    for (CAMultiAudioNode *node in self.audioInputs)
    {
        NSString *deviceUID = node.nodeUID;
        NSMutableDictionary *inputopts = [_inputSettings valueForKey:deviceUID];
        
        
        if (!inputopts)
        {
            inputopts = [NSMutableDictionary dictionary];
            [_inputSettings setValue:inputopts forKey:deviceUID];
            
        }
        [inputopts setValue:@(node.volume) forKey:@"volume"];
        [inputopts setValue:@(node.enabled) forKey:@"enabled"];
        if (node.downMixer)
        {
            [inputopts setValue:[node.downMixer saveData] forKey:@"downMixerData"];
        }
    }
    
    [aCoder encodeObject:_inputSettings forKey:@"inputSettings"];
    
    
    
}

-(void)updateStatistics
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        for(CAMultiAudioNode *node in self.audioInputs)
        {
            [node updatePowerlevel];
        }
    });
    
    
    float rawPreview = [self.previewMixer outputPower];
    float rawStream = [self.encodeMixer outputPower];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.previewAudioPowerLevel = pow(10.0f, rawPreview/20.0f);
        self.streamAudioPowerLevel = pow(10.0f, rawStream/20.0f);
    });

    
    
    

}


-(bool)buildGraph
{
    self.graph = [[CAMultiAudioGraph alloc] initWithSamplerate:self.sampleRate];
    
    
    
    NSUInteger selectedIdx = [self.audioOutputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((CAMultiAudioDevice *)obj).deviceUID isEqualToString:_outputId];
    }];

    
    
    if (selectedIdx != NSNotFound)
    {
        _outputNode = [self.audioOutputs objectAtIndex:selectedIdx];
    }
    
    
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

    return YES;
}


-(void)inputsForSystemAudio
{
    NSArray *sysDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
    for(AVCaptureDevice *dev in sysDevices)
    {
        CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:dev withFormat:self.graph.graphAsbd];
        
        [self attachInput:avplayer];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceConnect:) name:AVCaptureDeviceWasConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceDisconnect:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];
    
    CAShow(self.graph.graphInst);


}

-(void)handleDeviceDisconnect:(NSNotification *)notification
{
    AVCaptureDevice *removedDev = notification.object;
    
    if ([removedDev hasMediaType:AVMediaTypeAudio])
    {
        NSUInteger selectedIdx = [self.audioInputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
            {
                CAMultiAudioAVCapturePlayer *testObj = obj;
                return testObj.captureDevice.uniqueID == removedDev.uniqueID;
            }
            return NO;
        }];
        
        if (selectedIdx != NSNotFound)
        {
            [self removeObjectFromAudioInputsAtIndex:selectedIdx];

        }
    }

    
}
-(void)handleDeviceConnect:(NSNotification *)notification
{
    AVCaptureDevice *newDev = notification.object;
    
    if ([newDev hasMediaType:AVMediaTypeAudio])
    {
        NSUInteger selectedIdx = [self.audioInputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
            {
                CAMultiAudioAVCapturePlayer *testObj = obj;
                return testObj.captureDevice.uniqueID == newDev.uniqueID;
            }
            return NO;
        }];
        
        if (selectedIdx == NSNotFound)
        {
            CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:newDev withFormat:self.graph.graphAsbd];
            [self attachInput:avplayer];
        }
    }
}


-(CAMultiAudioDevice *)outputNode
{
    return _outputNode;
}


-(void)setOutputNode:(CAMultiAudioDevice *)outputNode
{
    _outputNode = outputNode;
    if (self.graphOutputNode)
    {
        self.graphOutputNode.deviceID = outputNode.deviceID;
        [self.graph stopGraph];
        [self.graphOutputNode setOutputForDevice];
        [self.graph startGraph];
    }
}




-(void)resetEngine
{
    if (!self.graph)
    {
        return;
    }
    
    [self.graph stopGraph];
    
    for (CAMultiAudioPCMPlayer *node in self.pcmInputs)
    {
        if (node.converterNode)
        {
            [self removeInput:node.converterNode];
        }

    }
    /*
    for (CAMultiAudioNode *node in self.audioInputs)
    {
        [self.graph removeNode:node];
    }
    */
    
    self.graph = nil;
    [self buildGraph];
    
    for (CAMultiAudioNode *node in self.audioInputs)
    {
        [node resetFormat:self.graph.graphAsbd];
        [self reattachInput:node];
        
    }

    for (CAMultiAudioPCMPlayer *node in self.pcmInputs)
    {
        [self attachPCMInput:node];
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


-(void)removePCMInput:(CAMultiAudioPCMPlayer *)toRemove
{
    CAMultiAudioConverter *converter = toRemove.converterNode;
    
    [self removeInput:converter];

    
   
    NSUInteger index = [self.pcmInputs indexOfObject:toRemove];
    if (index != NSNotFound)
    {
        [self.pcmInputs removeObjectAtIndex:index];
    }
    
    
}


-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)uniqueID withFormat:(const AudioStreamBasicDescription *)withFormat
{
    CAMultiAudioPCMPlayer *newInput = [[CAMultiAudioPCMPlayer alloc] init];
    newInput.inputFormat = (AudioStreamBasicDescription *)withFormat;
    newInput.nodeUID = uniqueID;
    
    [self attachPCMInput:newInput];
    
    //[newInput play];
    [self.pcmInputs addObject:newInput];
    return newInput;
    
}

-(void)attachDeviceInput:(CAMultiAudioAVCapturePlayer *)device
{
    if (!device)
    {
        return; //what?
    }
    
    CAMultiAudioNode *toAttach = nil;
    
    AudioStreamBasicDescription *devFormat = device.inputFormat;
    
    if (devFormat)
    {
        CAMultiAudioConverter *newConverter = [[CAMultiAudioConverter alloc] initWithInputFormat:devFormat];
        newConverter.nodeUID = device.nodeUID;
    
        newConverter.sourceNode = device;
        device.converterNode = newConverter;
        toAttach = newConverter;
    }
    
    [self.graph addNode:device];
    [self attachInput:toAttach];
    if (devFormat)
    {
        [self.graph connectNode:device toNode:toAttach sampleRate:devFormat->mSampleRate];
    }

}


-(void)attachPCMInput:(CAMultiAudioPCMPlayer *)input
{
    CAMultiAudioConverter *newConverter = [[CAMultiAudioConverter alloc] initWithInputFormat:input.inputFormat];
    newConverter.nodeUID = input.nodeUID; //Not so unique, lol
    
    newConverter.sourceNode = input;
    input.converterNode = newConverter;
    
    [self.graph addNode:input];
    [self attachInput:newConverter];
    
    [self.graph connectNode:input toNode:newConverter sampleRate:input.inputFormat->mSampleRate];

}
-(void)reattachInput:(CAMultiAudioNode *)input
{
    
    
    [self.graph addNode:input];
    
    CAMultiAudioDownmixer *dmix = [[CAMultiAudioDownmixer alloc] initWithInputChannels:input.channelCount];
    [self.graph addNode:dmix];
    
    [self.graph connectNode:dmix toNode:self.encodeMixer];
    
    CAMultiAudioNode *connectNode = dmix;
    CAMultiAudioDelay *delayNode = nil;
    
    for(int i=0; i < 5; i++)
    {
        delayNode = [[CAMultiAudioDelay alloc] init];
        [self.graph addNode:delayNode];
        [self.graph connectNode:delayNode toNode:connectNode];
        connectNode = delayNode;
        [input.delayNodes addObject:delayNode];
    }
    
    
    [self.graph connectNode:input toNode:delayNode];
    
    input.downMixer = dmix;

}

-(void)attachInput:(CAMultiAudioNode *)input
{
    
    
    [self.graph addNode:input];
    
    CAMultiAudioDownmixer *dmix = [[CAMultiAudioDownmixer alloc] initWithInputChannels:input.channelCount];
    [self.graph addNode:dmix];
    
    [self.graph connectNode:dmix toNode:self.encodeMixer];

    CAMultiAudioNode *connectNode = dmix;
    CAMultiAudioDelay *delayNode = nil;

    for(int i=0; i < 5; i++)
    {
        delayNode = [[CAMultiAudioDelay alloc] init];
        [self.graph addNode:delayNode];
        [self.graph connectNode:delayNode toNode:connectNode];
        connectNode = delayNode;
        [input.delayNodes addObject:delayNode];
    }
    
    
    [self.graph connectNode:input toNode:delayNode];
    
    input.downMixer = dmix;
    
    if (input.nodeUID)
    {
        NSDictionary *settings = [_inputSettings valueForKey:input.nodeUID];
        if (settings)
        {
            input.volume = [(NSNumber *)[settings valueForKey:@"volume"] floatValue];
            input.enabled = [(NSNumber *)[settings valueForKey:@"enabled"] boolValue];
            NSDictionary *mixerData = [settings valueForKey:@"downMixerData"];
            if (mixerData)
            {
                [input.downMixer restoreData:mixerData];
            }
        }
    }

    //[self.graph connectNode:input toNode:self.encodeMixer];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self addAudioInputsObject:input];
    });
    

    
    
}


-(void)removeInput:(CAMultiAudioNode *)toRemove
{
    NSUInteger index = [self.audioInputs indexOfObject:toRemove];
    if (index != NSNotFound)
    {
        NSMutableDictionary *saveSettings = [NSMutableDictionary dictionary];
        
        saveSettings[@"volume"] = @(toRemove.volume);
        saveSettings[@"enabled"] = @(toRemove.enabled);
        if (toRemove.downMixer)
        {
            saveSettings[@"downMixerData"] = [toRemove.downMixer saveData];
        }
        
        _inputSettings[toRemove.nodeUID] = saveSettings;

        
        CAMultiAudioDownmixer *dmix = toRemove.downMixer;
        toRemove.downMixer = nil;
        
        [self.graph removeNode:toRemove];
        
        if (dmix)
        {
            [self.graph removeNode:dmix];
        }
        
        NSArray *delayNodes = toRemove.delayNodes.copy;
        
        for (CAMultiAudioDelay *dNode in delayNodes)
        {
            [self.graph removeNode:dNode];
            [toRemove.delayNodes removeObject:dNode];
        }
        
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObjectFromAudioInputsAtIndex:index];

        });
    }
    
    
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
    if (index < self.audioInputs.count)
    {
        [self.audioInputs removeObjectAtIndex:index];
    }
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

