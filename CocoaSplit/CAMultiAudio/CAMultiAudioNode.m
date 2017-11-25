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


-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType
{
    if (self = [super init])
    {
        //Creating the node and unit are deferred until the node is attached to a graph, since we need the graph to create the node.
        unitDescr.componentManufacturer = kAudioUnitManufacturer_Apple;
        unitDescr.componentSubType = subType;
        unitDescr.componentType = unitType;
        
        //Default to two channels, subclasses can override this
        
        self.channelCount = 2;
        _volume = 1.0;

    }
    
    return self;
}


//We don't use NSCoding here because the audio engine/graph does deferred creating of audio unit objects, so most of what we load/save doesn't matter at creating time.
//The engine applies our saved settings after the node is added to the graph and properly connected
-(void)saveDataToDict:(NSMutableDictionary *)saveDict
{
    saveDict[@"volume"] = [NSNumber numberWithFloat:self.volume];
    saveDict[@"enabled"] = [NSNumber numberWithBool:self.enabled];
}

-(void)restoreDataFromDict:(NSDictionary *)restoreDict
{
    self.volume = [restoreDict[@"volume"] floatValue];
    self.enabled = [restoreDict[@"enabled"] boolValue];
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
    _enabled = enabled;
    
    
}
-(UInt32)inputElement
{
    return 0;
}


-(bool)createNode:(AUGraph)forGraph
{
    if (!forGraph)
    {
        return NO;
    }
    OSStatus err;
    err = AUGraphAddNode(forGraph, &unitDescr, &_node);
    if (err)
    {
        NSLog(@"AUGraphAddNode failed for %@, err: %d", self, err);
        CAShow(forGraph);
        return NO;
    }
    err = AUGraphNodeInfo(forGraph, _node, NULL, &_audioUnit);
    if (err)
    {
        NSLog(@"AUGraphNodeInfo failed for %@, err: %d", self, err);
        return NO;
    }
    
    return YES;
}

-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, format, sizeof(AudioStreamBasicDescription));
    if (err)
    {
        NSLog(@"Failed to set StreamFormat for input %@ in willInitializeNode: %d", self, err);
        return NO;
    }
    
    return YES;
}


-(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    AudioStreamBasicDescription casbd;
    
    memcpy(&casbd, format, sizeof(casbd));
    casbd.mChannelsPerFrame = self.channelCount;
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &casbd, sizeof(AudioStreamBasicDescription));
    
    if (err)
    {
        NSLog(@"Failed to set StreamFormat for output on node %@ with %d", self, err);
        return NO;
    }
    
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



-(void)updatePowerlevel
{
    //[self.connectedTo updatePowerlevel];
    
    CAMultiAudioNode *powerNode = self.connectedTo;
    
    while (powerNode)
    {
        if ([powerNode.class conformsToProtocol:@protocol(CAMultiAudioMixingProtocol)])
        {
            id<CAMultiAudioMixingProtocol>mixerNode = (id<CAMultiAudioMixingProtocol>)powerNode;
            float rawPower = [mixerNode powerForInputBus:powerNode.connectedToBus];
            self.powerLevel = pow(10.0f, rawPower/20.0f);
            break;
        } else {
            powerNode = powerNode.connectedTo;
        }
    }
    
}


/*
-(void)setVolumeOnConnectedNode
{
    
    CAMultiAudioNode *volNode = self.connectedTo;
    
    
    while (volNode)
    {
        if ([volNode.class conformsToProtocol:@protocol(CAMultiAudioMixingProtocol)])
        {
            id<CAMultiAudioMixingProtocol>mixerNode = (id<CAMultiAudioMixingProtocol>)volNode;
            [mixerNode setVolumeOnInputBus:self.downMixer volume:self.volume];
            break;
        } else {
            volNode = volNode.connectedTo;
        }
    }
}
*/




-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus
{
    self.connectedTo = toNode;
    self.connectedToBus = onBus;
}

-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus
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
}

-(void)resetSamplerate:(UInt32)sampleRate
{
    //only certain node types need to react to this
    return;
}

-(void)resetFormat:(AudioStreamBasicDescription *)format
{
    return;
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






-(void) dealloc
{
    if (self.graph)
    {
        [self.graph removeNode:self];
        
    }
}

@end
