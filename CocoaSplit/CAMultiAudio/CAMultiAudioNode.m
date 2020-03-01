//
//  CAMultiAudioNode.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioGraph.h"
#import "CAMultiAudioMixingProtocol.h"
#import "CAMultiAudioMatrixMixerWindowController.h"
#import "CAMultiAudioDelay.h"
#include <AudioUnit/AUCocoaUIView.h>
#include <CoreAudioKit/CoreAudioKit.h>
#include "CaptureController.h"


OSStatus RenderTone(
void *inRefCon,
AudioUnitRenderActionFlags *ioActionFlags,
const AudioTimeStamp *inTimeStamp,
UInt32 inBusNumber,
UInt32 inNumberFrames,
                    AudioBufferList *ioData);

@implementation CAMultiAudioVolumeAnimation

@end


@implementation CAMultiAudioNode

@synthesize volume = _volume;
@synthesize muted = _muted;
@synthesize enabled = _enabled;

-(instancetype)init
{
    if (self = [self initWithSubType:0 unitType:0])
    {
        
    }
    
    return self;
}

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer
{
    if (self = [super init])
    {
        //Creating the node and unit are deferred until the node is attached to a graph, since we need the graph to create the node.
        unitDescr.componentManufacturer = manufacturer;
        unitDescr.componentSubType = subType;
        unitDescr.componentType = unitType;
        
        //Default to two channels, subclasses can override this
        
        self.channelCount = 2;
        _volume = 1.0;
        self.effectChain = [NSMutableArray array];
        self.nodeUID = [[NSUUID UUID] UUIDString];
        self.inputConnections = [NSMutableDictionary dictionary];
        self.outputConnections = [NSMutableDictionary dictionary];
        _currentEffectChain = [NSMutableArray array];
    }
    
    return self;
}

-(NSString *)uuid
{
    return self.nodeUID;
}

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    return [self initWithSubType:subType unitType:unitType manufacturer:kAudioUnitManufacturer_Apple];
}



//We don't use NSCoding here because the audio engine/graph does deferred creating of audio unit objects, so most of what we load/save doesn't matter at creating time.
//The engine applies our saved settings after the node is added to the graph and properly connected
-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    saveDict[@"volume"] = [NSNumber numberWithFloat:self.volume];
    saveDict[@"enabled"] = [NSNumber numberWithBool:self.enabled];
    NSMutableArray *effectSaveData = [NSMutableArray array];
    for (CAMultiAudioEffect *effect in self.effectChain)
    {
        NSMutableDictionary *eDict = [NSMutableDictionary dictionary];
        [effect saveDataToDict:eDict];
        [effectSaveData addObject:eDict];
    }
    saveDict[@"effectChain"] = effectSaveData;

}

-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    self.enabled = [restoreDict[@"enabled"] boolValue];
    
    self.volume = [restoreDict[@"volume"] floatValue];
    


    NSArray *effectCopy = [self.effectChain copy];
    for (CAMultiAudioEffect *effect in effectCopy)
    {
        [self removeObjectFromEffectChainAtIndex:[effectCopy indexOfObject:effect]];
    }
    
    
    if (restoreDict[@"effectChain"])
    {
        NSArray *effectData = restoreDict[@"effectChain"];
        for (NSDictionary *eData in effectData)
        {
            CAMultiAudioEffect *newEffect = [[CAMultiAudioEffect alloc] init];
            [newEffect restoreDataFromDict:eData];
            [self addEffect:newEffect];
        }
        
        
    }

    //[self rebuildEffectChain];

}


-(NSView *)audioUnitNSView
{
    UInt32 cuiSize;
    Boolean isWriteable;
    
    NSView *retView = nil;
    
    OSStatus res;
    res = AudioUnitGetPropertyInfo(self.audioUnit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, &cuiSize, &isWriteable);
    
    if (res == noErr)
    {
        AudioUnitCocoaViewInfo *AUViewInfo = malloc(cuiSize);
        res = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, AUViewInfo, &cuiSize);
        if (res == noErr && AUViewInfo)
        {
            CFURLRef auBundlePath = AUViewInfo->mCocoaAUViewBundleLocation;
            CFStringRef factoryName = AUViewInfo->mCocoaAUViewClass[0];
            NSBundle *auBundle = [NSBundle bundleWithURL:(__bridge NSURL * _Nonnull)(auBundlePath)];
            if (auBundle)
            {
                Class factoryClass = [auBundle classNamed:(__bridge NSString * _Nonnull)(factoryName)];
                id<AUCocoaUIBase> factoryInstance = [[factoryClass alloc] init];
                retView = [factoryInstance uiViewForAudioUnit:self.audioUnit withSize:NSZeroSize];
            }
        }
        free(AUViewInfo);
    }
    if (!retView)
    {
        AUGenericView *genView = [[AUGenericView alloc] initWithAudioUnit:self.audioUnit];
        genView.showsExpertParameters = YES;
        retView = genView;
    }
    return retView;
}






-(bool)enabled
{
    return _enabled;
}


-(void)setEnabled:(bool)enabled
{
    if (enabled == _enabled)
    {
        return;
    }
    _enabled = enabled;

    if (_enabled)
    {
        [CaptureController.sharedCaptureController postNotification:CSNotificationAudioEnabled forObject:self];
    } else {
        [CaptureController.sharedCaptureController postNotification:CSNotificationAudioDisabled forObject:self];
    }
    
}
-(UInt32)inputElement
{
    return 0;
}

-(UInt32)outputElement
{
    return 0;
}



-(bool)createNode
{
    return [self createNode:nil];
}


-(bool)createNode:(void(^)(void))completionHandler
{
    
    
    if (_audioUnit)
    {
        //Already created
        return YES;
    }
    
    OSStatus err;
    
    
    AudioComponent auComponent = AudioComponentFindNext(NULL, &unitDescr);

    
    if (!auComponent)
    {
        return NO;
    }
    
    AudioComponentDescription fullDesc;
    AudioComponentGetDescription(auComponent, &fullDesc);
    
    
    bool requiresAsync = (fullDesc.componentFlags & kAudioComponentFlag_RequiresAsyncInstantiation) > 0;
    
    
    if (requiresAsync)
    {
        AudioComponentInstantiate(auComponent, kAudioComponentInstantiation_LoadOutOfProcess, ^(AudioComponentInstance _Nullable auUnit, OSStatus osErr) {
            self.audioUnit = auUnit;
            if (completionHandler)
            {
                dispatch_async(dispatch_get_main_queue(), completionHandler);
            }
        });
    } else {
        AudioUnit newUnit;
        err =  AudioComponentInstanceNew(auComponent, &newUnit);
        if (err)
        {
            NSLog(@"AudioComponentInstanceNew failed for %@, err: %d", self, err);
            _audioUnit = NULL;
            return NO;
        }
        self.audioUnit = newUnit;
        if (completionHandler)
        {
            dispatch_async(dispatch_get_main_queue(), completionHandler);
        }
    }
    self.effectsHead = self;
    self.headNode = self;
    return YES;
}


-(AVAudioFormat *)inputFormatForBus:(UInt32)bus
{
    
    AVAudioFormat *ret = nil;
    AudioStreamBasicDescription asbd;
    UInt32 asbdSize = sizeof(asbd);
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, bus, &asbd, &asbdSize);
    
    AVAudioChannelLayout *chanLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_DiscreteInOrder | asbd.mChannelsPerFrame];
    ret = [[AVAudioFormat alloc] initWithStreamDescription:&asbd channelLayout:chanLayout];
    return ret;
}


-(AVAudioFormat *)outputFormatForBus:(UInt32)bus
{
    
    AVAudioFormat *ret = nil;
    AudioStreamBasicDescription asbd;
    UInt32 asbdSize = sizeof(asbd);
    
    AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, bus, &asbd, &asbdSize);
    
    AVAudioChannelLayout *chanLayout = [AVAudioChannelLayout layoutWithLayoutTag:kAudioChannelLayoutTag_DiscreteInOrder | asbd.mChannelsPerFrame];
    ret = [[AVAudioFormat alloc] initWithStreamDescription:&asbd channelLayout:chanLayout];
    return ret;
}




-(bool)setInputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{

    AudioUnitUninitialize(self.audioUnit);
    
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, bus, format.streamDescription, sizeof(AudioStreamBasicDescription));

    if (err)
    {
        NSLog(@"Failed to set StreamFormat for input on node %@ with %d", self, err);
        return NO;
    }

    [self willInitializeNode];
    AudioUnitInitialize(self.audioUnit);
    [self didInitializeNode];
    return YES;

}


-(bool)setOutputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    AudioUnitUninitialize(self.audioUnit);

    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, bus, format.streamDescription, sizeof(AudioStreamBasicDescription));

    if (err)
    {
        NSLog(@"Failed to set StreamFormat for output on node %@ with %d", self, err);
        return NO;
    }
    [self willInitializeNode];
    AudioUnitInitialize(self.audioUnit);
    [self didInitializeNode];
    return YES;

}



-(void)willInitializeNode
{
    return;
}

-(void)didInitializeNode
{
    return;
}

-(void)generateTone
{
    OSErr err;
    AURenderCallbackStruct input;
    input.inputProc = RenderTone;
    input.inputProcRefCon = (__bridge void * _Nullable)(self);
    err = AudioUnitSetProperty(self.audioUnit,
        kAudioUnitProperty_SetRenderCallback,
        kAudioUnitScope_Input,
        0,
        &input,
        sizeof(input));
}








-(void)nodeConnected:(CAMultiAudioNode *)toNode inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    return;
}


-(void)willConnectNode:(CAMultiAudioNode *)node inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    return;
}

-(void)setMuted:(bool)muted
{
    if (_muted == muted)
    {
        return;
    }
    
    
    //if we're muting, save the current player volume
    if (muted == YES)
    {
        _saved_volume = self.volume;
        self.volume = 0.0f;
    } else {
        self.volume = _saved_volume;
    }
    _muted = muted;
    
    if (_muted)
    {
        [CaptureController.sharedCaptureController postNotification:CSNotificationAudioMuted forObject:self];
    } else {
        [CaptureController.sharedCaptureController postNotification:CSNotificationAudioUnmuted forObject:self];
    }
}


-(bool)muted
{
    return _muted;
}

-(void)animationDidEnd:(NSAnimation *)animation
{
    CAMultiAudioVolumeAnimation *vAnim = (CAMultiAudioVolumeAnimation *)animation;

    self.volume = vAnim.target_volume;
}


-(void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress
{
    CAMultiAudioVolumeAnimation *vAnim = (CAMultiAudioVolumeAnimation *)animation;
    
    float volume_delta = fabs(vAnim.original_volume - vAnim.target_volume);
    float progress_val = volume_delta * progress;
    
    float real_volume = 0;
    
    if (vAnim.target_volume > vAnim.original_volume)
    {
        real_volume = vAnim.original_volume + progress_val;
    } else {
        real_volume = vAnim.original_volume - progress_val;
    }
    
    self.volume = real_volume;
}


-(void)setVolumeAnimated:(float)volume withDuration:(float)duration
{
    _volumeAnimation = [[CAMultiAudioVolumeAnimation alloc] initWithDuration:duration animationCurve:NSAnimationLinear];
    [_volumeAnimation setFrameRate:20.0];
    [_volumeAnimation setDelegate:self];
    _volumeAnimation.animationBlockingMode = NSAnimationNonblockingThreaded;
    _volumeAnimation.target_volume = volume;
    _volumeAnimation.original_volume = self.volume;
    
    
    float step_size = 1.0/20.0;
    float step_vol = 0.0;
    for (int i = 0; i <= 21; i++)
    {
        [_volumeAnimation addProgressMark:step_vol];

        step_vol += step_size;
    }
    [_volumeAnimation startAnimation];
    
}

-(void) willConnectToNode:(CAMultiAudioNode *)node inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    return;
}

-(void) connectedToNode:(CAMultiAudioNode *)node inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    return;
}


-(void)rebuildEffectChain
{
    bool restoreHeadNode = NO;

    NSArray *outConnections = nil;
    CAMultiAudioNode *lastEffect = _currentEffectChain.lastObject;
    AVAudioFormat *useFormat = [self.effectsHead outputFormatForBus:0];

    if (lastEffect)
    {
        outConnections = [self.graph outputConnections:lastEffect forBus:0];
        if (lastEffect == self.headNode)
        {
            restoreHeadNode = YES;
        }
    } else {
        outConnections = [self.graph outputConnections:self.effectsHead forBus:0];
    }
    
    
    [self.effectsHead.graph disconnectNodeOutput:self.effectsHead];
    
    for (CAMultiAudioNode *currNode in _currentEffectChain)
    {
        if (currNode && currNode.graph)
        {
            [currNode.graph disconnectNode:currNode];
            [currNode.graph removeNode:currNode];
        }
    }
    
    
    [_currentEffectChain removeAllObjects];
    
    
    CAMultiAudioNode *currNode = self.effectsHead;


    currNode = self.effectsHead;
    for (CAMultiAudioNode *eNode in self.effectChain)
    {
        [self.graph addNode:eNode];
        [self.graph connectNode:currNode toNode:eNode format:useFormat];
        [_currentEffectChain addObject:eNode];
        currNode = eNode;
    }
    
    if (outConnections && outConnections.count > 0)
    {

        [currNode.graph connectNode:currNode usingConnections:outConnections outBus:0 format:useFormat];

    }
    
    if (restoreHeadNode)
    {
        self.headNode = currNode;
    }
    
}

-(void)addEffect:(CAMultiAudioNode *)effect;
{

    [self insertObject:effect inEffectChainAtIndex:self.effectChain.count];
}


-(void)addEffect:(CAMultiAudioNode *)effect atIndex:(NSUInteger)idx
{

    [self insertObject:effect inEffectChainAtIndex:idx];
}



-(NSUInteger)countOfEffectChain
{
    return self.effectChain.count;
}

-(id)objectInEffectChainAtIndex:(NSUInteger)index
{
    return [self.effectChain objectAtIndex:index];
}


-(void)insertObject:(CAMultiAudioNode *)object inEffectChainAtIndex:(NSUInteger)index
{
    object.deleteNode = NO;
    [self.effectChain insertObject:object atIndex:index];
    [self rebuildEffectChain];
}


-(void)removeObjectFromEffectChainAtIndex:(NSUInteger)index
{
    CAMultiAudioEffect *delNode = [self.effectChain objectAtIndex:index];
    delNode.deleteNode = YES;
    
    [self.effectChain removeObjectAtIndex:index];
    [self rebuildEffectChain];
}



-(void)setupEffectsChain
{
    //[self rebuildEffectChain];
    //Do restore here
}



-(void)removeEffectsChain
{
    if (self.effectsHead)
    {
        [self.graph disconnectNode:self.effectsHead];
    }
    
    for(CAMultiAudioNode *eNode in self.effectChain)
    {
        [self.graph disconnectNode:eNode];
        [self.graph removeNode:eNode];
    }
    
    [self.effectChain removeAllObjects];
}


-(void)reset
{
    AudioUnitReset(self.audioUnit, kAudioUnitScope_Global, 0);
    AudioUnitUninitialize(self.audioUnit);
    AudioUnitInitialize(self.audioUnit);
}
-(void) dealloc
{
    if (self.graph)
    {
        [self removeEffectsChain];
        [self.graph removeNode:self];
        
    }
}

@end


OSStatus RenderTone(
    void *inRefCon,
    AudioUnitRenderActionFlags *ioActionFlags,
    const AudioTimeStamp *inTimeStamp,
    UInt32 inBusNumber,
    UInt32 inNumberFrames,
    AudioBufferList *ioData)

{
    // Fixed amplitude is good enough for our purposes
    const double amplitude = 0.25;

    // Get the tone parameters out of the view controller
    CAMultiAudioDevice *viewController =
    (__bridge CAMultiAudioDevice *)inRefCon;
    double theta = viewController.theta;
    double theta_increment =
        2.0 * M_PI * 600 / 44100;

    // This is a mono tone generator so we only need the first buffer
    const int channel = 0;
    Float32 *buffer = (Float32 *)ioData->mBuffers[channel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++)
    {
        buffer[frame] = sin(theta) * amplitude;
        
        theta += theta_increment;
        if (theta > 2.0 * M_PI)
        {
            theta -= 2.0 * M_PI;
        }
    }
    
    // Store the updated theta back in the view controller
    viewController.theta = theta;

    return noErr;
}
