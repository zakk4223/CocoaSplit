//
//  CAMultiAudioNode.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioGraph.h"
#import "CAMultiAudioMixingProtocol.h"


@implementation CAMultiAudioNode

@synthesize volume = _volume;
@synthesize muted = _muted;
@synthesize enabled = _enabled;


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
        self.nameColor = [NSColor blackColor];
    }
    
    return self;
}


-(bool)enabled
{
    return _enabled;
}


-(void)setEnabled:(bool)enabled
{
    NSColor *newColor;
    _enabled = enabled;
    if (enabled)
    {
        newColor = [NSColor greenColor];
    } else {
        newColor = [NSColor blackColor];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.nameColor = newColor;
    });

    
    
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

-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, format, sizeof(AudioStreamBasicDescription));
    if (err)
    {
        NSLog(@"Failed to set StreamFormat for input %@ in willInitializeNode: %d", self, err);
    }
}


-(void)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
    AudioStreamBasicDescription casbd;
    
    memcpy(&casbd, format, sizeof(casbd));
    casbd.mChannelsPerFrame = self.channelCount;
    
    OSStatus err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &casbd, sizeof(AudioStreamBasicDescription));
    
    if (err)
    {
        NSLog(@"Failed to set StreamFormat for output on node %@ with %d", self, err);
    }

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
    
    [self.connectedTo updatePowerlevel];
    
    if ([self.connectedTo.class conformsToProtocol:@protocol(CAMultiAudioMixingProtocol)])
    {
        id<CAMultiAudioMixingProtocol>mixerNode = (id<CAMultiAudioMixingProtocol>)self.connectedTo;
        self.powerLevel = [mixerNode powerForInputBus:self.connectedToBus];
    }
}


-(void)setVolumeOnConnectedNode
{
    if (!self.connectedTo)
    {
        return;
    }
    
    
    if ([self.connectedTo.class conformsToProtocol:@protocol(CAMultiAudioMixingProtocol)])
    {
        id<CAMultiAudioMixingProtocol>mixerNode = (id<CAMultiAudioMixingProtocol>)self.connectedTo;
        [mixerNode setVolumeOnInputBus:self.connectedToBus volume:self.volume];
    }
}


-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus
{
    self.connectedTo = toNode;
    self.connectedToBus = onBus;
    [self setVolumeOnConnectedNode];
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


-(bool)muted
{
    return _muted;
}



-(void)setVolume:(float)volume
{
    _volume = volume;
    [self setVolumeOnConnectedNode];
    
}

-(float)volume
{
    return _volume;
}


-(void) dealloc
{
    if (self.graph)
    {
        [self.graph removeNode:self];
        
    }
}

@end
