//
//  CAMultiAudioEngine.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//

#import "CAMultiAudioEngine.h"
#import "CAMultiAudioDownmixer.h"
#import "CAMultiAudioDelay.h"
#import "CSNotifications.h"
#import "CAMultiAudioUnit.h"
#import "CAMultiAudioOutputTrack.h"
#import "CaptureController.h"


OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData );


@implementation CAMultiAudioEngine

@synthesize sampleRate = _sampleRate;
@synthesize outputNode = _outputNode;
//@synthesize encoder = _encoder;


-(void)commonInit
{
    _inputSettings = [NSMutableDictionary dictionary];
    _savedSystemInputs = [NSMutableDictionary dictionary];

    self.audioInputs = [NSMutableArray array];
    self.pcmInputs = [NSMutableArray array];
    self.fileInputs = [NSMutableArray array];
    self.validSamplerates = @[@44100, @48000];
    self.sampleRate = 44100;
    self.streamAudioPowerLevels = [NSMutableDictionary dictionary];
    self.streamAudioPowerLevels[@"output"] = [NSMutableArray array];
    self.previewAudioPowerLevels = [NSMutableDictionary dictionary];
    self.previewAudioPowerLevels[@"output"] = [NSMutableArray array];

    self.audioOutputs = [[CAMultiAudioDevice allDevices] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hasOutput == YES"]];
    self.outputTracks = [NSMutableDictionary dictionary];
    
    _outputId = [CAMultiAudioDevice defaultOutputDeviceUID];
    
    
    

    
}

-(instancetype)initWithDefaultTrackUUID:(NSString *)outputUUID
{
    if (self = [super init])
    {
        _defaultTrackUUID = outputUUID;
        
        [self commonInit];
        
        [self buildGraph];
        [self inputsForSystemAudio];
        self.encodeMixer.volume = 1.0;
        self.encodeMixer.muted = NO;
        self.previewMixer.volume = 1.0;
        self.previewMixer.muted  = NO;
        [self.graph startGraph];
    }
    
    return self;

}

-(instancetype)init
{
    return [self initWithDefaultTrackUUID:nil];
}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        [self commonInit];
        
        if ([aDecoder containsValueForKey:@"sampleRate"])
        {
            UInt32 oldSampleRate = [aDecoder decodeInt32ForKey:@"sampleRate"];
            self.sampleRate = (double)oldSampleRate;
        }
        
        
        if ([aDecoder containsValueForKey:@"sampleRateDouble"])
        {
            self.sampleRate = [aDecoder decodeDoubleForKey:@"sampleRateDouble"];

        }
        
        if ([aDecoder containsValueForKey:@"audioBitrate"])
        {
            self.audioBitrate = [aDecoder decodeIntForKey:@"audioBitrate"];
        }
        
        if ([aDecoder containsValueForKey:@"audioAdjust"])
        {
            self.audio_adjust = [aDecoder decodeDoubleForKey:@"audioAdjust"];
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
        
        
        
        if ([aDecoder containsValueForKey:@"defaultOutputTrack"])
        {
            _defaultOutputTrack = [aDecoder decodeObjectForKey:@"defaultOutputTrack"];
        }
        
        [self buildGraph];

        if (_defaultOutputTrack)
        {
            _defaultOutputTrack.encoderNode = self.renderNode;
        }
        
        if ([aDecoder containsValueForKey:@"outputTracks"])
        {
            NSDictionary *outputTracks = [aDecoder decodeObjectForKey:@"outputTracks"];
            [self willChangeValueForKey:@"outputTracks"];
            
            for (NSString *trackName in outputTracks)
            {
                CAMultiAudioOutputTrack *outTrack = outputTracks[trackName];
                [self.outputTracks setObject:outTrack forKey:outTrack.uuid];
            }
            [self didChangeValueForKey:@"outputTracks"];
            
        }
        
        [self inputsForSystemAudio];
        
        if ([aDecoder containsValueForKey:@"encodeMixerSettings"])
        {
            [self.encodeMixer restoreDataFromDict:[aDecoder decodeObjectForKey:@"encodeMixerSettings"]];
        }
        
        
        if ([aDecoder containsValueForKey:@"streamVolume"])
        {
            self.encodeMixer.volume = [aDecoder decodeFloatForKey:@"streamVolume"];
        }
        
        if ([aDecoder containsValueForKey:@"streamMuted"])
        {
            self.encodeMixer.enabled = ![aDecoder decodeBoolForKey:@"streamMuted"];
        }
        
        if ([aDecoder containsValueForKey:@"previewVolume"])
        {
            self.previewMixer.volume = [aDecoder decodeFloatForKey:@"previewVolume"];
        }
        
        if ([aDecoder containsValueForKey:@"previewMuted"])
        {
            self.previewMixer.enabled = ![aDecoder decodeBoolForKey:@"previewMuted"];
        }
        
        if ([aDecoder containsValueForKey:@"fileInputs"])
        {
            NSArray *fnames = [aDecoder decodeObjectForKey:@"fileInputs"];
            for(NSString *inputPath in fnames)
            {
                [self createFileInput:inputPath];
            }
        }

        if ([aDecoder containsValueForKey:@"savedSystemInputs"])
        {
            
            _savedSystemInputs = [aDecoder decodeObjectForKey:@"savedSystemInputs"];
            _savedSystemInputs = _savedSystemInputs.mutableCopy;
            
            for (NSString *nodeUID in _savedSystemInputs)
            {
                NSString *devUID = _savedSystemInputs[nodeUID];
                AVCaptureDevice *dev = [AVCaptureDevice deviceWithUniqueID:devUID];
                if (dev)
                {
                    CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:dev];
                    avplayer.nodeUID = nodeUID;
                    [self attachInput:avplayer];
                }
            }
        }
        [self.graph startGraph];
        for (NSString *trackUUID in self.outputTracks)
        {
            CAMultiAudioOutputTrack *outTrack = self.outputTracks[trackUUID];
            if (outTrack != _defaultOutputTrack)
            {
                [self attachOutputTrack:outTrack];
            }
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
    [aCoder encodeDouble:self.sampleRate forKey:@"sampleRateDouble"];
    [aCoder encodeObject:self.outputNode.deviceUID forKey:@"selectedAudioId"];
    [aCoder encodeFloat:self.encodeMixer.volume forKey:@"streamVolume"];
    [aCoder encodeBool:!self.encodeMixer.enabled forKey:@"streamMuted"];
    [aCoder encodeFloat:self.previewMixer.volume forKey:@"previewVolume"];
    [aCoder encodeBool:!self.previewMixer.enabled forKey:@"previewMuted"];

    [aCoder encodeInt:self.audioBitrate forKey:@"audioBitrate"];
    [aCoder encodeDouble:self.audio_adjust forKey:@"audioAdjust"];
    
    NSMutableDictionary *encodeMixerChain = [NSMutableDictionary dictionary];
    [self.encodeMixer saveDataToDict:encodeMixerChain];
    [aCoder encodeObject:encodeMixerChain forKey:@"encodeMixerSettings"];
    
    NSDictionary *saveInputSettings = [self generateInputSettings];


    
    [aCoder encodeObject:saveInputSettings forKey:@"inputSettings"];
    
    NSMutableArray *fileSave = [NSMutableArray array];
    for (CAMultiAudioFile *fInput in self.fileInputs)
    {
        [fileSave addObject:fInput.filePath];
    }
    
    [aCoder encodeObject:fileSave forKey:@"fileInputs"];
    
    [aCoder encodeObject:self.outputTracks forKey:@"outputTracks"];
    [aCoder encodeObject:_defaultOutputTrack forKey:@"defaultOutputTrack"];
    
    NSMutableDictionary *systemInputMap = [NSMutableDictionary dictionary];
    
    for (CAMultiAudioInput *input in self.audioInputs)
    {
        if ([input isEqual:_defaultInput])
        {
            continue;
        }
        if ([input isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
        {
            
            CAMultiAudioAVCapturePlayer *avinput = (CAMultiAudioAVCapturePlayer *)input;
            if (avinput.isGlobal)
            {
                systemInputMap[avinput.nodeUID] = avinput.deviceUID;
            }
        }
    }
    
    [aCoder encodeObject:systemInputMap forKey:@"savedSystemInputs"];
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

-(void) disableAllInputs
{
    for (CAMultiAudioInput *input in self.audioInputs)
    {
        input.enabled = NO;
    }
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
    

    NSMutableArray *previewArray = self.previewAudioPowerLevels[@"output"];
    NSMutableArray *streamArray = self.streamAudioPowerLevels[@"output"];
    
    if (previewArray.count != self.previewMixer.channelCount)
    {
    
        if (previewArray.count < self.previewMixer.channelCount)
        {
            for (NSUInteger i = 0; i < self.previewMixer.channelCount - previewArray.count; i++)
            {
                [previewArray addObject:@(-60.0f)];
            }
        } else {
            
            for (NSUInteger i = previewArray.count - 1; i >= self.previewMixer.channelCount; i--)
            {
                [previewArray removeObjectAtIndex:i];
            }
        }
        
    }
    
    if (streamArray.count != self.encodeMixer.channelCount)
    {
        
        if (streamArray.count < self.encodeMixer.channelCount)
        {
            for (NSUInteger i = 0; i < self.encodeMixer.channelCount - streamArray.count; i++)
            {
                [streamArray addObject:@(-60.0f)];
            }
        } else {
            
            for (NSUInteger i = streamArray.count - 1; i >= self.encodeMixer.channelCount; i--)
            {
                [streamArray removeObjectAtIndex:i];
            }
        }
    }
    
    
    for (int i = 0; i < previewArray.count; i++)
    {
        
        float pVal = [self.previewMixer powerForOutputBus:i];
        [previewArray replaceObjectAtIndex:i withObject:@(pVal)];
    }
    
    for (int i = 0; i < streamArray.count; i++)
    {
        float pVal = [self.encodeMixer powerForOutputBus:i];
        [streamArray replaceObjectAtIndex:i withObject:@(pVal)];
    }
    
    float rawPreview = [self.previewMixer outputPower];
    float rawStream = [self.encodeMixer outputPower];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
    self.previewAudioPowerLevel = rawPreview;
    self.streamAudioPowerLevel = rawStream;
   // });

    
    
    

}

-(bool)removeInput:(CAMultiAudioInput *)input fromTrack:(NSString *)outputTrackUUID
{
    if (!outputTrackUUID)
    {
        return NO;
    }
    
    
    CAMultiAudioOutputTrackConnection *trackConn = input.outputTracks[outputTrackUUID];
    if (!trackConn)
    {
        return NO;
    }
    
    NSNumber *trackOutBus = trackConn.outputTrack.outputBus;

    [self.encodeMixer disconnectInputBus:trackConn.bus fromOutputBus:trackOutBus.unsignedIntValue];
    [input.outputTracks removeObjectForKey:outputTrackUUID];
    return YES;
}


-(bool)addInput:(CAMultiAudioInput *)input toTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    
    if (!outputTrack)
    {
        return NO;
    }
    if (!self.outputTracks[outputTrack.uuid])
    {
        return NO;
    }
    
    
    NSNumber *trackOutBus = outputTrack.outputBus;
    CAMultiAudioConnection *inputConn = [self.graph findOutputConnection:input.headNode forNode:self.encodeMixer onBus:0];
    [self.encodeMixer connectInputBus:inputConn.bus toOutputBus:trackOutBus.unsignedIntValue];
    CAMultiAudioOutputTrackConnection *trackConn = [[CAMultiAudioOutputTrackConnection alloc] initWithTrack:outputTrack inBus:inputConn.bus];
    [input.outputTracks setObject:trackConn forKey:outputTrack.uuid];
    return YES;
}



-(void)setupDefaultOutputTrack
{
    CAMultiAudioOutputTrack *defaultTrack = nil;
    
    defaultTrack = _defaultOutputTrack;

    if (!defaultTrack)
    {
        defaultTrack = [[CAMultiAudioOutputTrack alloc] init];
        defaultTrack.encoderNode = self.renderNode;
        defaultTrack.outputBus = @(0);
        defaultTrack.name = @"Default";
        if (self.defaultTrackUUID)
        {
            defaultTrack.uuid = self.defaultTrackUUID;
        } else {
            self.defaultTrackUUID = defaultTrack.uuid;
        }
    } else {
        self.defaultTrackUUID = defaultTrack.uuid;
    }
    
    
    if (!defaultTrack.encoder)
    {
        CSAacEncoder *encoder =  [[CSAacEncoder alloc] init];
        encoder.sampleRate = self.sampleRate;
        encoder.bitRate = self.audioBitrate*1000;
        encoder.inputASBD = self.graph.audioFormat.streamDescription;
        encoder.trackName = defaultTrack.uuid;
        [encoder setupEncoderBuffer];
        defaultTrack.encoder = encoder;
    }
    

    _defaultOutputTrack = defaultTrack;
    self.outputTracks[defaultTrack.uuid] = defaultTrack;
}



-(void)addOutputTrack
{
    NSString *useName = [NSString stringWithFormat:@"Track %lu", (unsigned long)self.outputTracks.count];
    [self createOutputTrack:useName];
}


-(void)attachOutputTrack:(CAMultiAudioOutputTrack *)outputTrack
{
    CAMultiAudioEffect *encNode = [[CAMultiAudioEffect alloc] initWithSubType:kAudioUnitSubType_Delay unitType:kAudioUnitType_Effect];
    CSAacEncoder *encoder = [[CSAacEncoder alloc] init];
    encoder.sampleRate = self.sampleRate;
    encoder.bitRate = self.audioBitrate*1000;
    encoder.trackName = outputTrack.uuid;
    encoder.inputASBD = self.graph.audioFormat.streamDescription;
    [encoder setupEncoderBuffer];
    encNode.bypass = YES;
    [self.graph addNode:encNode];
    [self.graph connectNode:self.encodeMixer toNode:encNode];
    [self.graph connectNode:encNode toNode:self.previewMixer];
    CAMultiAudioConnection *eConn = [self.graph inputConnection:encNode forBus:0];

    [self.previewMixer setVolumeOnInputBus:eConn.bus volume:0.0f];
    CAMultiAudioConnection *silenceConn = [self.graph findOutputConnection:self.silentNode forNode:self.encodeMixer onBus:0];
    [self.encodeMixer setVolumeOnOutputBus:eConn.bus volume:1.0f];
    
    [self.encodeMixer connectInputBus:silenceConn.bus toOutputBus:eConn.bus];
    outputTrack.encoderNode = encNode;
    outputTrack.encoder = encoder;
    outputTrack.outputBus = @(eConn.bus);
}

-(bool)createOutputTrack:(NSString *)withName
{
    return [self createOutputTrack:withName withUUID:nil];
}


-(bool)createOutputTrack:(NSString *)withName withUUID:(NSString *)uuid
{

    if ([withName isEqualToString:@"Default"])
    {
        return NO;
    }
    CAMultiAudioOutputTrack *outputTrack = [[CAMultiAudioOutputTrack alloc] init];
    outputTrack.name = withName;
    if (uuid)
    {
        outputTrack.uuid = uuid;
    }
    
    [self attachOutputTrack:outputTrack];

    [self willChangeValueForKey:@"outputTracks"];
    
    [self.outputTracks setObject:outputTrack forKey:outputTrack.uuid];
    [self didChangeValueForKey:@"outputTracks"];
    [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackCreated forObject:withName];

    return YES;
}

-(bool)removeOutputTrack:(NSString *)withUUID
{
    CAMultiAudioOutputTrack *trackInfo = self.outputTracks[withUUID];

    if (!trackInfo)
    {
        return NO;
    }
    
    if ([trackInfo.name isEqualToString:@"Default"])
    {
        return NO;
    }
    
    
    if (trackInfo)
    {
        CSAacEncoder *enc = trackInfo.encoder;
        if (enc)
        {
            [enc stopEncoder];
        }
        
        CAMultiAudioNode *encNode = trackInfo.encoderNode;
        [self.encodeMixer disconnectOutput:encNode];
        if (encNode)
        {
            [self.graph removeNode:encNode];
        }
        
        [self willChangeValueForKey:@"outputTracks"];
        [self.outputTracks removeObjectForKey:withUUID];
        [self didChangeValueForKey:@"outputTracks"];
        
        for (CAMultiAudioInput *input in self.audioInputs)
        {
            
            if ([input.outputTracks valueForKey:withUUID])
            {
                [input removeFromOutputTrack:withUUID];
            }
        }
        
        [[CaptureController sharedCaptureController] postNotification:CSNotificationAudioTrackDeleted forObject:withUUID];
        return YES;
    }
    
    return NO;
}


-(bool)buildGraph
{
    AVAudioFormat *useFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:self.sampleRate channels:2];
    self.graph = [[CAMultiAudioGraph alloc] initWithFormat:useFormat];
    self.graph.engine = self;
    
    
    
    NSUInteger selectedIdx = [self.audioOutputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [((CAMultiAudioDevice *)obj).deviceUID isEqualToString:self->_outputId];
    }];

    
    if (selectedIdx == NSNotFound)
    {
        selectedIdx = [self.audioOutputs indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [((CAMultiAudioDevice *)obj).deviceUID isEqualToString:[CAMultiAudioDevice defaultOutputDeviceUID]];
        }];
    }
    
    
    if (selectedIdx != NSNotFound)
    {
        _outputNode = [self.audioOutputs objectAtIndex:selectedIdx];
    } else {
        _outputNode = [self.audioOutputs objectAtIndex:0];
    }
    
    
    self.graphOutputNode = self.outputNode;
    self.graph.outputNode = self.outputNode;
    
    
    
    
    self.silentNode = [[CAMultiAudioSilence alloc] init];
    self.encodeMixer = [[CAMultiAudioDownmixer alloc] initWithInputChannels:2];
    self.encodeMixer.nodeUID = @"__CS_ENCODE_MIXER_NODE";
    self.encodeMixer.name = @"Stream";
    self.previewMixer = [[CAMultiAudioMixer alloc] init];
    self.previewMixer.nodeUID = @"__CS_PREVIEW_MIXER_NODE";
    self.previewMixer.name = @"Preview";
    self.renderNode = [[CAMultiAudioEffect alloc] initWithSubType:kAudioUnitSubType_Delay unitType:kAudioUnitType_Effect];
    
    [self.graph addNode:self.outputNode];
    
    if ([self.graphOutputNode respondsToSelector:@selector(setOutputForDevice)])
    {
        [self.graphOutputNode setOutputForDevice];
    }
    
    
    
    
    [self.graph addNode:self.silentNode];
    [self.graph addNode:self.encodeMixer];
    [self.graph addNode:self.previewMixer];
    [self.graph addNode:self.renderNode];
    self.renderNode.bypass = YES;
    
    [self.graph connectNode:self.previewMixer toNode:self.graphOutputNode];
    [self.graph connectNode:self.renderNode toNode:self.previewMixer];
    
    [self.graph connectNode:self.encodeMixer toNode:self.renderNode];
    [self.graph connectNode:self.silentNode toNode:self.encodeMixer];
    

    /*
    if (!self.encoder)
    {
        CSAacEncoder *encoder = [[CSAacEncoder alloc] init];
        encoder.sampleRate = self.sampleRate;
        encoder.bitRate = self.audioBitrate*1000;
    
        encoder.inputASBD = self.graph.graphAsbd;
        [encoder setupEncoderBuffer];
        self.encoder = encoder;
    } else {
        AudioUnitAddRenderNotify(self.renderNode.audioUnit, encoderRenderCallback, [self.encoder inputBufferPtr]);
    }
     */
    [self setupDefaultOutputTrack];

    return YES;
}


-(void)listenForDefaultInputChange
{
    AudioObjectPropertyAddress inputDeviceAddress = {
        kAudioHardwarePropertyDefaultInputDevice,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    __weak CAMultiAudioEngine *weakSelf = self;
    
    AudioObjectAddPropertyListenerBlock(kAudioObjectSystemObject, &inputDeviceAddress, dispatch_get_main_queue(), ^(UInt32 inNumberAddresses, const AudioObjectPropertyAddress * _Nonnull inAddresses) {
        CAMultiAudioEngine *strongSelf = weakSelf;
        if (strongSelf && strongSelf->_defaultInput)
        {
            [strongSelf attachDefaultInput];
        }
    });
}


-(void)removeDefaultInput
{
    if (_defaultInput)
    {
        [self removeInput:_defaultInput];
        _defaultInput = nil;
    }
}


-(void)attachDefaultInput
{
    AVCaptureDevice *defaultAV = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (defaultAV)
    {
        if (self->_defaultInput)
        {
            if ([self->_defaultInput.captureDevice.uniqueID isEqualToString:defaultAV.uniqueID])
            {
                return;
            } else {
                [self removeInput:self->_defaultInput];
                _defaultInput = nil;
            }
        }
        CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:defaultAV];
        
        
        avplayer.name = @"System Input";
        avplayer.nodeUID = @"__CS_SYSTEM_INPUT_UUID__";
        avplayer.enabled = YES;

        [self attachInput:avplayer];
        _defaultInput = avplayer;
    }
}


-(NSDictionary *)systemAudioInputs
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    if (_defaultInput)
    {
        [ret setObject:_defaultInput.name forKey:_defaultInput.nodeUID];
    }
    
    
    NSArray *sysDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    for(AVCaptureDevice *dev in sysDevices)
    {
        [ret setObject:dev.localizedName forKey:dev.uniqueID];
    }
    
    return ret;
}

-(CAMultiAudioInput *)findInputForSystemUUID:(NSString *)uuid
{
    @synchronized(self) {
        for(CAMultiAudioInput *node in self.audioInputs)
        {
            if ([node isKindOfClass:[CAMultiAudioAVCapturePlayer class]])
            {
                CAMultiAudioAVCapturePlayer *sysInput = (CAMultiAudioAVCapturePlayer *)node;
                if ([sysInput.deviceUID isEqualToString:uuid])
                {
                    return node;
                }
            }
        }
    }
    return nil;
}


-(CAMultiAudioInput *)createInputForSystemUUID:(NSString *)uuid
{
    
    AVCaptureDevice *dev = [AVCaptureDevice deviceWithUniqueID:uuid];
    
    if (!dev)
    {
        return nil;
    }
    
    CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:dev];
    if (avplayer)
    {
        [self attachInput:avplayer];
        avplayer.enabled = YES;
    }
    return avplayer;
}


-(void)inputsForSystemAudio
{
    
    
    //NSArray *sysDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    
   [self attachDefaultInput];
    [self listenForDefaultInputChange];
    NSArray *sysDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    for(AVCaptureDevice *dev in sysDevices)
    {
        if (_defaultInput && [dev.uniqueID isEqualToString:_defaultInput.captureDevice.uniqueID])
        {
            continue;
        }
        
        NSDictionary *settings = [_inputSettings valueForKey:dev.uniqueID];
        bool isEnabled = [settings[@"enabled"] boolValue];
        bool isGlobal = [settings[@"isGlobal"] boolValue];
        if (isEnabled || isGlobal)
        {
            CAMultiAudioAVCapturePlayer *avplayer = [[CAMultiAudioAVCapturePlayer alloc] initWithDevice:dev];
            NSString *realUID = avplayer.nodeUID;
            avplayer.nodeUID = dev.uniqueID;
            [self attachInput:avplayer];
            avplayer.nodeUID = realUID;
        }
        
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
            [CaptureController.sharedCaptureController postNotification:CSNotificationAudioRemoved forObject:self];
        }
    }

    
}
-(void)handleDeviceConnect:(NSNotification *)notification
{
    /*
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
     */
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
    
    _inputSettings = [self generateInputSettings];

    NSMutableDictionary *encodeEffectChain = [NSMutableDictionary dictionary];
    [self.encodeMixer saveDataToDict:encodeEffectChain];
    
    for (CAMultiAudioNode *node in self.audioInputs)
    {
        [self.graph removeNode:node];
    }
    
    
    float emVolume = self.encodeMixer.volume;
    bool emMuted = self.encodeMixer.muted;
    float pmVolume = self.previewMixer.volume;
    bool pmMuted = self.previewMixer.muted;
    
    
    self.graph = nil;
    [self buildGraph];
    
    self.encodeMixer.volume = emVolume;
    self.encodeMixer.muted = emMuted;
    self.previewMixer.volume = pmVolume;
    self.previewMixer.muted = pmMuted;
    
    
    
    for (CAMultiAudioInput *node in self.audioInputs)
    {
        [self reattachInput:node];
        
    }

    [self.encodeMixer restoreDataFromDict:encodeEffectChain];
    [self.graph startGraph];

}


-(void)startEncoder:(NSString *)trackUID
{
    CAMultiAudioOutputTrack *outputTrack = self.outputTracks[trackUID];
    if (outputTrack)
    {
        CAMultiAudioNode *renderNode = outputTrack.encoderNode;
        CSAacEncoder *encoder = outputTrack.encoder;
        AudioUnitAddRenderNotify(renderNode.audioUnit, encoderRenderCallback, [encoder inputBufferPtr]);
    }

}
-(void)startEncoders
{
    
    for(NSString *trackName in self.outputTracks)
    {
        [self startEncoder:trackName];
    }
}

-(void)stopEncoders
{
    for(NSString *trackName in self.outputTracks)
    {
        CAMultiAudioOutputTrack *outputTrack = self.outputTracks[trackName];
        CAMultiAudioNode *renderNode = outputTrack.encoderNode;
        CSAacEncoder *encoder = outputTrack.encoder;
        AudioUnitRemoveRenderNotify(renderNode.audioUnit, encoderRenderCallback, [encoder inputBufferPtr]);
    }
}

/*
-(double)sampleRate
{
    return _sampleRate;
}


-(void)setSampleRate:(double)sampleRate
{
    double old_samplerate = _sampleRate;
    _sampleRate = sampleRate;
    if (sampleRate > 0 && (sampleRate != old_samplerate))
    {
        //It's easier to just rebuild the graph instead of trying to splunk through all the nodes and connections
        //to change them all.
        [self resetEngine];

    }
    
}
*/


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
    [self attachInput:fileInput];
    
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


-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)uniqueID withFormat:(AVAudioFormat *)withFormat
{
    CAMultiAudioPCMPlayer *newInput = nil;
    

    newInput = [[CAMultiAudioPCMPlayer alloc] init];
    newInput.inputFormat = withFormat;
    newInput.nodeUID = uniqueID;
    
    [self attachInput:newInput];
    
    //[newInput play];
    [self.pcmInputs addObject:newInput];
    return newInput;
    
}

-(void)removeInputAny:(CAMultiAudioInput *)input
{
    if ([input isKindOfClass: CAMultiAudioPCMPlayer.class])
    {
        [self removePCMInput:(CAMultiAudioPCMPlayer *)input];
    } else if ([input isKindOfClass:CAMultiAudioFile.class]) {
        [self removeFileInput:(CAMultiAudioFile *)input];
    }
}

-(bool)attachInputCommon:(CAMultiAudioInput *)input
{
    if (input)
    {
        [self.graph addNode:input];
        [self.graph connectNode:input.headNode toNode:self.encodeMixer];
        if (_defaultOutputTrack)
        {
            [self addInput:input toTrack:_defaultOutputTrack];
        }
    }
    
    return YES;
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
    
    input.enabled = YES;
    
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
    [CaptureController.sharedCaptureController postNotification:CSNotificationAudioAdded forObject:self];
    return YES;
    
}


-(bool)disconnectInputNode:(CAMultiAudioInput *)disconnectNode
{

    CAMultiAudioGraph *inputGraph = disconnectNode.graph;
    

    [inputGraph removeNode:disconnectNode];
    /*
    if (disconnectNode.headNode)
    {
        [inputGraph removeNode:disconnectNode.headNode];
    } else {
        [inputGraph removeNode:disconnectNode];
    }
    */
    
    [disconnectNode teardownGraph];

    disconnectNode.headNode = nil;
    disconnectNode.graph = nil;
    
    [CaptureController.sharedCaptureController postNotification:CSNotificationAudioRemoved forObject:self];
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
            NSInteger mIndex = NSNotFound;
            @synchronized(self) {
                mIndex = [self.audioInputs indexOfObject:toRemove];
            
                if (mIndex != NSNotFound)
                {
                    [self removeObjectFromAudioInputsAtIndex:mIndex];
                }
            }
            
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


-(void)dealloc
{
    /*
    if (self.encoder)
    {
        [self.encoder stopEncoder];
    }*/
    
    for(NSString *trackName in self.outputTracks)
    {
        CAMultiAudioOutputTrack *trackInfo = self.outputTracks[trackName];
        CSAacEncoder *enc = trackInfo.encoder;
        if (enc)
        {
            [enc stopEncoder];
        }
    }
}


@end

OSStatus encoderRenderCallback( void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData )
{
    
    

    if ((*ioActionFlags) & kAudioUnitRenderAction_PostRenderError)
    {
        return noErr;
    }
    
    
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

