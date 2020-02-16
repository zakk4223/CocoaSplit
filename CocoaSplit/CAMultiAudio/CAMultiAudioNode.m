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


@interface AVAudioNode()
@property(nonatomic, readonly) AudioUnit audioUnit;
@end

@implementation CAMultiAudioVolumeAnimation

@end


@implementation CAMultiAudioNode

@synthesize volume = _volume;
@synthesize muted = _muted;
@synthesize enabled = _enabled;
@synthesize connectedTo = _connectedTo;
@synthesize connectedToBus = _connectedToBus;

-(instancetype)init
{
    if (self = [self initWithAudioNode:nil])
    {
        
    }
    
    return self;
}

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer
{
    if (self = [self initWithAudioNode:nil])
    {
        //Creating the node and unit are deferred until the node is attached to a graph, since we need the graph to create the node.
        unitDescr.componentManufacturer = manufacturer;
        unitDescr.componentSubType = subType;
        unitDescr.componentType = unitType;
        [AVAudioUnit instantiateWithComponentDescription:unitDescr options:kAudioComponentInstantiation_LoadInProcess completionHandler:^(__kindof AVAudioUnit * _Nullable audioUnit, NSError * _Nullable error) {
            self.avAudioNode = audioUnit;
        }];
    }
    
    return self;
}

-(instancetype)initWithAudioNode:(AVAudioNode *)audioNode
{
    if (self = [super init])
    {
        _avAudioNode = audioNode;
        self.effectChain = [NSMutableArray array];
        self.inputMap = [NSMutableDictionary dictionary];
        self.outputMap = [NSMutableDictionary dictionary];
        self.nodeUID = [[NSUUID UUID] UUIDString];
        self.volume = 1.0f;
        self.headNode = self;
        self.effectsHead = self;
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


-(AudioUnit) audioUnit
{
    if (self.avAudioNode)
    {
        return self.avAudioNode.audioUnit;
    }
    return 0;
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
   // self.enabled = [restoreDict[@"enabled"] boolValue];
    
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
    
    if (!self.avAudioNode)
    {
        return nil;
    }
    
    
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


-(void)willInitializeNode
{
    return;
}

-(void)didInitializeNode
{
    return;
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




-(bool)busForOutput:(CAMultiAudioNode *)inputNode busOut:(UInt32 *)busOut
{
    NSString *nodeUUID = inputNode.nodeUID;
    NSDictionary *outputInfo = self.inputMap[nodeUUID];
    if (outputInfo)
    {
        NSNumber *oBus = outputInfo[@"outBus"];
        if (oBus)
        {
            *busOut = oBus.unsignedIntValue;
            return YES;
        }
        return NO;
    }
    
    return NO;
}


-(bool)busForInput:(CAMultiAudioNode *)inputNode busOut:(UInt32 *)busOut
{
    NSString *nodeUUID = inputNode.nodeUID;
    NSDictionary *inputInfo = self.inputMap[nodeUUID];
    if (inputInfo)
    {
        NSNumber *inBus = inputInfo[@"inBus"];
        if (inBus)
        {
            *busOut = inBus.unsignedIntValue;
            return YES;
        }
        return NO;
    }
    
    return NO;
}


-(void)nodeConnected:(CAMultiAudioNode *)toNode inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    [self.outputMap setObject:@{@"inBus": @(inBus), @"outBus": @(outBus), @"node": toNode} forKey:toNode.nodeUID];
    if (outBus == 0)
    {
        _connectedTo = toNode;
        _connectedToBus = inBus;
    }
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

-(void) willConnectToNode:(CAMultiAudioNode *)node inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    return;
}

-(void) connectedToNode:(CAMultiAudioNode *)node inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    

    [self.inputMap setObject:@{@"inBus": @(inBus), @"outBus": @(outBus), @"node": node} forKey:node.nodeUID];

}

-(void)willRemoveNode
{
    return;
}


-(void)didAttachNode
{
    return;
}

-(void)rebuildEffectChain
{
    //Disconnect every node from effectsHead -> headNode (including headNode) and then reconnect everything in effectchain array
    CAMultiAudioNode *currNode = self.effectsHead;

    CAMultiAudioNode *headConn;
    while (currNode && currNode != self.headNode)
    {
        CAMultiAudioNode *connNode = currNode.connectedTo;
        [self.graph disconnectNode:currNode];
        if (currNode.deleteNode)
        {
            [self.graph removeNode:currNode];
        }
        currNode = connNode;
    }
    
    if (currNode) //This is headNode
    {
        headConn = currNode.connectedTo;
        [self.graph disconnectNode:currNode];
        if (currNode.deleteNode)
        {
            [self.graph removeNode:currNode];
        }
        
        self.headNode = self.effectsHead;
    }
    
    currNode = nil;
    currNode = self.effectsHead;
    for (CAMultiAudioNode *eNode in self.effectChain)
    {
        [self.graph addNode:eNode];
        [self.graph connectNode:currNode toNode:eNode];
        currNode = eNode;
    }
    
    if (headConn && currNode)
    {
        [self.graph connectNode:currNode toNode:headConn];
    }
    
    
    if (currNode)
    {
        self.headNode = currNode;
    } else {
        self.headNode = self.effectsHead;
    }
    

    
    //CAShow(self.graph.graphInst);

    
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
    [self rebuildEffectChain];
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


-(void) dealloc
{
    if (self.graph)
    {
        [self removeEffectsChain];
        [self.graph removeNode:self];
        
    }
}

@end
