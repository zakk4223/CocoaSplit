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
#import "CAMultiAudioEqualizer.h"
#import "CSNotifications.h"
#import "CAMultiAudioUnit.h"
OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData );


@implementation CAMultiAudioEngine

@synthesize sampleRate = _sampleRate;
@synthesize outputNode = _outputNode;
@synthesize encoder = _encoder;


-(void)commonInit
{
    _inputSettings = [NSMutableDictionary dictionary];

    self.audioInputs = [NSMutableArray array];
    self.pcmInputs = [NSMutableArray array];
    self.fileInputs = [NSMutableArray array];
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
        NSLog(@"EFFECTS %@", [CAMultiAudioUnit availableEffects]);
        
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
        
        if ([aDecoder containsValueForKey:@"fileInputs"])
        {
            NSArray *fnames = [aDecoder decodeObjectForKey:@"fileInputs"];
            for(NSString *inputPath in fnames)
            {
                [self createFileInput:inputPath];
            }
        }
        if ([aDecoder containsValueForKey:@"equalizerData"])
        {
            NSDictionary *eqdata = [aDecoder decodeObjectForKey:@"equalizerData"];
            [self.equalizer restoreData:eqdata];
        }
    }
    
    return self;
}



-(NSDictionary *)createInputSettings
{
    NSMutableDictionary *saveInputSettings = [NSMutableDictionary dictionary];
    
    for (CAMultiAudioInput *node in self.audioInputs)
    {
        NSString *deviceUID = node.nodeUID;
        NSMutableDictionary *inputopts = [NSMutableDictionary dictionary];
        if (!node.noSettings)
        {
            [node saveDataToDict:inputopts];
            if (inputopts.count > 0)
            {
                [saveInputSettings setValue:inputopts forKey:deviceUID];
            }
        }
    }
    
    return saveInputSettings;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt32:self.sampleRate forKey:@"sampleRate"];
    [aCoder encodeObject:self.outputNode.deviceUID forKey:@"selectedAudioId"];
    [aCoder encodeFloat:self.encodeMixer.volume forKey:@"streamVolume"];
    [aCoder encodeBool:self.encodeMixer.muted forKey:@"streamMuted"];
    [aCoder encodeFloat:self.previewMixer.volume forKey:@"previewVolume"];
    [aCoder encodeBool:self.previewMixer.muted forKey:@"previewMuted"];
    
    NSDictionary *saveInputSettings = [self generateInputSettings];

    NSDictionary *eqdata = [self.equalizer saveData];
    [aCoder encodeObject:eqdata forKey:@"equalizerData"];
    
    [aCoder encodeObject:saveInputSettings forKey:@"inputSettings"];
    
    NSMutableArray *fileSave = [NSMutableArray array];
    for (CAMultiAudioFile *fInput in self.fileInputs)
    {
        [fileSave addObject:fInput.filePath];
    }
    
    [aCoder encodeObject:fileSave forKey:@"fileInputs"];
    
}


-(void)applyInputSettings:(NSDictionary *)inputSettings
{
    
    for (CAMultiAudioInput *input in self.audioInputs)
    {
        if (input.nodeUID)
        {
            NSDictionary *settings = [inputSettings valueForKey:input.nodeUID];
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
    }

}


-(NSMutableDictionary *)generateInputSettings
{
    
    NSMutableDictionary *iSettings = [NSMutableDictionary dictionary];
    
    for (CAMultiAudioInput *node in self.audioInputs)
    {
        NSString *deviceUID = node.nodeUID;
        NSMutableDictionary *inputopts = [NSMutableDictionary dictionary];
        [node saveDataToDict:inputopts];
        [iSettings setValue:inputopts forKey:deviceUID];
        /*
        [inputopts setValue:@(node.volume) forKey:@"volume"];
        [inputopts setValue:@(node.enabled) forKey:@"enabled"];
        if (node.downMixer)
        {
            [inputopts setValue:[node.downMixer saveData] forKey:@"downMixerData"];
        }
         */
        
    }
    
    return iSettings;
    
}


-(CSAacEncoder *)encoder
{
    return _encoder;
}

-(void)setEncoder:(CSAacEncoder *)encoder
{
    CSAacEncoder *oldEncoder = _encoder;
    
    _encoder = encoder;
    
    if (oldEncoder)
    {
        AudioUnitRemoveRenderNotify(self.equalizer.audioUnit, encoderRenderCallback, [oldEncoder inputBufferPtr]);
    }
    
    AudioUnitAddRenderNotify(self.equalizer.audioUnit, encoderRenderCallback, [_encoder inputBufferPtr]);
}


-(void)updateStatistics
{
    CAMultiAudioEngine *__weak blockSelf = self;
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    
    @synchronized(self) {
        for(CAMultiAudioInput *node in blockSelf.audioInputs)
        {
            [node updatePowerlevel];
        }
        // });
    }
    
    
    
    float rawPreview = [self.previewMixer outputPower];
    float rawStream = [self.encodeMixer outputPower];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        self.previewAudioPowerLevel = pow(10.0f, rawPreview/20.0f);
        self.streamAudioPowerLevel = pow(10.0f, rawStream/20.0f);
   // });

    
    
    

}


-(bool)buildGraph
{
    self.graph = [[CAMultiAudioGraph alloc] initWithSamplerate:self.sampleRate];
    
    
    
    NSUInteger selectedIdx = [self.audioOutputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((CAMultiAudioDevice *)obj).deviceUID isEqualToString:self->_outputId];
    }];

    
    
    if (selectedIdx != NSNotFound)
    {
        _outputNode = [self.audioOutputs objectAtIndex:selectedIdx];
    }
    
    
    //if (!self.graphOutputNode)
    {
        self.graphOutputNode = self.outputNode;
        

    }
    
    
    self.silentNode = [[CAMultiAudioSilence alloc] init];
    self.encodeMixer = [[CAMultiAudioMixer alloc] init];
    self.previewMixer = [[CAMultiAudioMixer alloc] init];
    self.equalizer = [[CAMultiAudioEqualizer alloc] init];
    
    [self.graph addNode:self.outputNode];
    
    if ([self.graphOutputNode respondsToSelector:@selector(setOutputForDevice)])
    {
        [self.graphOutputNode setOutputForDevice];
    }
    
    
    
    
    [self.graph addNode:self.silentNode];
    [self.graph addNode:self.encodeMixer];
    [self.graph addNode:self.previewMixer];
    [self.graph addNode:self.equalizer];
    
    [self.graph connectNode:self.previewMixer toNode:self.graphOutputNode];
    [self.graph connectNode:self.equalizer toNode:self.previewMixer];
    
    [self.graph connectNode:self.encodeMixer toNode:self.equalizer];
    [self.graph connectNode:self.silentNode toNode:self.encodeMixer];
    [self.graph startGraph];
    
    
    
    if (self.encoder)
    {
        AudioUnitAddRenderNotify(self.equalizer.audioUnit, encoderRenderCallback, [self.encoder inputBufferPtr]);
    }

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
    
    //CAShow(self.graph.graphInst);


}

-(void)handleDeviceDisconnect:(NSNotification *)notification
{
    AVCaptureDevice *removedDev = notification.object;
    
    if ([removedDev hasMediaType:AVMediaTypeAudio])
    {
        NSUInteger selectedIdx = NSNotFound;
        
        @synchronized(self) {
            selectedIdx = [self.audioInputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
                {
                    CAMultiAudioAVCapturePlayer *testObj = obj;
                    return testObj.captureDevice.uniqueID == removedDev.uniqueID;
                }
                return NO;
            }];
        }
        if (selectedIdx != NSNotFound)
        {
            [self removeObjectFromAudioInputsAtIndex:selectedIdx];
            [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationAudioRemoved object:self userInfo:@{@"UUID": removedDev.uniqueID}];


        }
    }

    
}
-(void)handleDeviceConnect:(NSNotification *)notification
{
    AVCaptureDevice *newDev = notification.object;
    
    if ([newDev hasMediaType:AVMediaTypeAudio])
    {
        NSUInteger selectedIdx = NSNotFound;
        @synchronized(self) {
            selectedIdx = [self.audioInputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
                {
                    CAMultiAudioAVCapturePlayer *testObj = obj;
                    return testObj.captureDevice.uniqueID == newDev.uniqueID;
                }
                return NO;
            }];
        }
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
    

    for (CAMultiAudioNode *node in self.audioInputs)
    {
        [self.graph removeNode:node];
    }
    
    
    float emVolume = self.encodeMixer.volume;
    bool emMuted = self.encodeMixer.muted;
    float pmVolume = self.previewMixer.volume;
    bool pmMuted = self.previewMixer.muted;
    
    NSDictionary *eqData = [self.equalizer saveData];
    _inputSettings = [self generateInputSettings];
    
    self.graph = nil;
    [self buildGraph];
    
    self.encodeMixer.volume = emVolume;
    self.encodeMixer.muted = emMuted;
    self.previewMixer.volume = pmVolume;
    self.previewMixer.muted = pmMuted;
    [self.equalizer restoreData:eqData];
    
    
    
    for (CAMultiAudioInput *node in self.audioInputs)
    {
        [node resetFormat:self.graph.graphAsbd];
        [self reattachInput:node];
        
    }
/*
    for (CAMultiAudioPCMPlayer *node in self.pcmInputs)
    {
        [self attachPCMInput:node];
    }
    
    for (CAMultiAudioFile *node in self.fileInputs)
    {
        [self attachFileInput:node];
    }
*/
    [self.graph graphUpdate];
    
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


-(void)removeFileInput:(CAMultiAudioFile *)toRemove
{

    [self removeInput:toRemove];

    NSUInteger index = [self.fileInputs indexOfObject:toRemove];
    if (index != NSNotFound)
    {

        [self.fileInputs removeObjectAtIndex:index];
    }
    

}


-(void)removePCMInput:(CAMultiAudioPCMPlayer *)toRemove
{
    
    [self removeInput:toRemove];
    NSUInteger index = [self.pcmInputs indexOfObject:toRemove];
    if (index != NSNotFound)
    {
        [self.pcmInputs removeObjectAtIndex:index];
    }
}


-(void)addFileInput:(CAMultiAudioFile *)fileInput
{
    [self attachFileInput:fileInput];
    
    [self.fileInputs addObject:fileInput];
}

-(CAMultiAudioFile *)createFileInput:(NSString *)filePath
{
    CAMultiAudioFile *newInput = [[CAMultiAudioFile alloc] initWithPath:filePath];
    
    if (newInput)
    {
        [self addFileInput:newInput];
    }
    
    return newInput;
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
    
    AudioStreamBasicDescription *devFormat = device.inputFormat;
    
    if (devFormat)
    {
        CAMultiAudioConverter *newConverter = [[CAMultiAudioConverter alloc] initWithInputFormat:devFormat];
        newConverter.nodeUID = device.nodeUID;
        
        newConverter.sourceNode = device;
        device.converterNode = newConverter;
    }
    [self attachInput:device];

}


-(void)attachFileInput:(CAMultiAudioFile *)input
{
    CAMultiAudioConverter *newConverter = [[CAMultiAudioConverter alloc] initWithInputFormat:input.outputFormat];
    newConverter.nodeUID = input.nodeUID; //Not so unique, lol
    
    newConverter.sourceNode = input;
    input.converterNode = newConverter;
    [self attachInput:input];
    
}



-(bool)attachInputCommon:(CAMultiAudioInput *)input
{
    bool ret;
    

    if (input)
    {
        [self.graph addNode:input];
        [self.graph connectNode:input toNode:self.encodeMixer];
    }
    
    return YES;
}


-(void)attachPCMInput:(CAMultiAudioPCMPlayer *)input
{
    
    CAMultiAudioConverter *newConverter = [[CAMultiAudioConverter alloc] initWithInputFormat:input.inputFormat];
    newConverter.nodeUID = input.nodeUID; //Not so unique, lol
    
    newConverter.sourceNode = input;
    input.converterNode = newConverter;
    
    [self attachInput:input];
    
    input.enabled = NO;

}


-(bool)reattachInput:(CAMultiAudioInput *)input
{
    
    bool ret = [self attachInputCommon:input];
    if (!ret)
    {
        return NO;
    }
    
    if (input.nodeUID && !input.noSettings)
    {
        NSDictionary *settings = [_inputSettings valueForKey:input.nodeUID];
        if (settings)
        {
            [input restoreDataFromDict:settings];
        }
    }
    
    return YES;
}



-(bool)attachInput:(CAMultiAudioInput *)input
{
    
    bool ret = [self attachInputCommon:input];
    if (!ret)
    {
        return NO;
    }
    
    
    if (input.nodeUID && !input.noSettings)
    {
        NSDictionary *settings = [_inputSettings valueForKey:input.nodeUID];
        if (settings)
        {
            [input restoreDataFromDict:settings];
        }
    }

    //ughhhhh
    if ([NSThread isMainThread])
    {
        [self addAudioInputsObject:input];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self addAudioInputsObject:input];
        });
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationAudioAdded object:self userInfo:@{@"UUID": input.nodeUID}];

    return YES;
    
}


-(bool)disconnectInputNode:(CAMultiAudioInput *)disconnectNode
{
    

    
    CAMultiAudioSubgraph *inputGraph = (CAMultiAudioSubgraph *)disconnectNode.graph;
    
    [disconnectNode teardownGraph];
    
    [inputGraph removeNode:disconnectNode.headNode];
    disconnectNode.headNode = nil;
    disconnectNode.graph = nil;
    [inputGraph removeNode:inputGraph.outputNode];
    
    AUGraphRemoveNode(self.graph.graphInst, inputGraph.subgraphNode);
    [self.graph graphUpdate];
    [[NSNotificationCenter defaultCenter] postNotificationName:CSNotificationAudioRemoved object:self userInfo:@{@"UUID": disconnectNode.nodeUID}];
    return YES;
}


-(void)removeInput:(CAMultiAudioInput *)toRemove
{
    NSUInteger index = NSNotFound;
    @synchronized(self) {
        index = [self.audioInputs indexOfObject:toRemove];
    }
    
    if (index != NSNotFound)
    {
        NSMutableDictionary *saveSettings = [NSMutableDictionary dictionary];
        
        if (!toRemove.noSettings)
        {
            [toRemove saveDataToDict:saveSettings];
            
            
            if (saveSettings.count > 0)
            {
                _inputSettings[toRemove.nodeUID] = saveSettings;
            }
        }
        
        
        
        [self disconnectInputNode:toRemove];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObjectFromAudioInputsAtIndex:index];
            
        });
        
        [toRemove didRemoveInput];
        
    }
    
    
}


-(CAMultiAudioInput *)inputForUUID:(NSString *)uuid
{
    @synchronized(self) {
        for(CAMultiAudioInput *node in self.audioInputs)
        {
            if ([node.nodeUID isEqualToString:uuid])
            {
                return node;
            }
        }
    }
    return nil;
}


-(void)addAudioInputsObject:(CAMultiAudioNode *)object
{
    
    [self insertObject:object inAudioInputsAtIndex:self.audioInputs.count];
}

-(void)insertObject:(CAMultiAudioNode *)object inAudioInputsAtIndex:(NSUInteger)index
{
    @synchronized(self) {
        [_audioInputs insertObject:object atIndex:index];
    }

}


-(void)removeObjectFromAudioInputsAtIndex:(NSUInteger)index
{
    @synchronized(self)
    {
        if (index < self.audioInputs.count)
        {
            [self.audioInputs removeObjectAtIndex:index];
        }
    }
}


@end

OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData )
{
    
    
    TPCircularBuffer *encodeBuffer = (TPCircularBuffer *)inRefCon;
    

    if (encodeBuffer && ((*ioActionFlags) & kAudioUnitRenderAction_PostRender))
    {
        
        
        TPCircularBufferCopyAudioBufferList(encodeBuffer, ioData, inTimeStamp, kTPCircularBufferCopyAll, NULL);

        /*
        CAMultiAudioEngine *selfPtr = (__bridge CAMultiAudioEngine *)inRefCon;
        
        if (selfPtr.encoder)
        {
            
                
            [selfPtr.encoder enqueuePCM:ioData atTime:inTimeStamp];
        }
        
*/
    }
    
    return noErr;
    
}

