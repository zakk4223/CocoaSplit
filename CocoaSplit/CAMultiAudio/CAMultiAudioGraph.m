//
//  CAMultiAudioGraph.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioGraph.h"





@implementation CAMultiAudioGraph

-(instancetype)init
{
    if (self = [super init])
    {
        //default to something reasonable
        
        self.sampleRate = 44100;
        self.nodeList = [NSMutableArray array];
        OSStatus err;
        err = NewAUGraph(&_graphInst);
        if (err)
        {
            NSLog(@"NewAUGraph failed, err: %d", err);
            return nil;
        }
        err = AUGraphOpen(_graphInst);
        if (err)
        {
            NSLog(@"AUGraphOpen failed, err: %d", err);
            return nil;
        }
        
        err = AUGraphInitialize(_graphInst);
        if (err)
        {
            NSLog(@"AUGraphInitialize failed, err: %d", err);
            return nil;
        }
        
    }
    
    return self;
}

-(bool)startGraph
{
    OSStatus err;
    if (!_graphInst)
    {
        return NO;
    }
    
    
    err = AUGraphStart(_graphInst);
    if (err)
    {
        NSLog(@"AUGraphStart failed, err %d", err);
        return NO;
    }
    
    return YES;
}

-(bool)stopGraph
{
    if (!_graphInst)
    {
        return NO;
    }
    OSStatus err;
    Boolean isRunning;
    
    err = AUGraphIsRunning(_graphInst, &isRunning);
    if (err)
    {
        NSLog(@"AUGraphIsRunning failed, err: %d", err);
        return NO;
    }
    if (isRunning)
    {
        return YES;
    }
    
    err = AUGraphStop(_graphInst);
    if (err)
    {
        NSLog(@"AUGraphStop failed, err: %d", err);
        return NO;
    }
    return YES;
}


-(bool)addNode:(CAMultiAudioNode *)newNode
{
    
    if ([newNode createNode:_graphInst])
    {
        newNode.graph = self;
    
        [self.nodeList addObject:newNode];
        return YES;
    }
    
    return NO;
}

-(bool)removeNode:(CAMultiAudioNode *)node
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    node.graph = nil;
    
    OSStatus err;
    
    if (![self disconnectNode:node])
    {
        NSLog(@"Remove node %@: disconnected failed", node);
        return NO;
    }
    
    err = AUGraphRemoveNode(_graphInst, node.node);
    if (err)
    {
        NSLog(@"Remove node %@: AUGraphRemoveNode failed, err: %d", node, err);
        return NO;
    }
    
    if (![self graphUpdate])
    {
        NSLog(@"Graph %@, graphUpdate failed in removeNode %@", self, node);
        return NO;
    }
    
    [self.nodeList removeObject:node];
    
    return YES;
    
}

-(bool)graphUpdate
{
    if (!_graphInst)
    {
        return NO;
    }
    OSStatus err;
    
    if (![self stopGraph])
    {
        NSLog(@"Graph %@: graphUpdate, stopGraph failed", self);
        return NO;
    }
    
    err = AUGraphUpdate(_graphInst, NULL);
    if (err)
    {
        NSLog(@"AUGraphUpdate failed, err: %d", err);
        return NO;
    }
    
    if (![self startGraph])
    {
        NSLog(@"Graph %@: graphUpdate, startGraph failed", self);
        return NO;

    }
    
    return YES;
}


-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode
{
    return [self connectNode:node toNode:toNode sampleRate:self.sampleRate];
}



-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode sampleRate:(int)sampleRate
{
    
    if (!_graphInst)
    {
        NSLog(@"ConnectNode: No AUGraph!");
        return NO;
    }
    
    if (!node || !toNode)
    {
        NSLog(@"ConnectNode: Source or destination node is nil %@ -> %@", node, toNode);
        return NO;
    }
    
    
    AUNode inNode;
    AUNode connectTo;
    AudioUnit aUnit;
    
    OSStatus err;
    
    inNode = node.node;
    connectTo = toNode.node;
    aUnit = node.audioUnit;
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 asbdSize = sizeof(asbd);
    
    err = AudioUnitGetProperty(aUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, &asbdSize);
    
    if (err)
    {
        NSLog(@"AUGetProperty failed (StreamFormat) on node %@ err: %d", node, err);
        return NO;
    }
    
    
    if (sampleRate > 0)
    {
        asbd.mSampleRate = sampleRate;
        
    }
    asbd.mChannelsPerFrame = node.channelCount;
    
    err = AudioUnitSetProperty(aUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &asbd, asbdSize);
    
    if (err)
    {
        NSLog(@"AUSetProperty failed (StreamFormat) on node %@ err: %d", node, err);
        return NO;
    }


    UInt32 bus = toNode.inputElement;
    
    err = AUGraphConnectNodeInput(_graphInst, inNode, 0, connectTo, bus);
    if (err)
    {
        NSLog(@"AUGraphConnectNodeInput failed for %@ -> %@, err: %d", node, toNode, err);
        return NO;
    }
    
    
    if (![self graphUpdate])
    {
        NSLog(@"Graph %@ graphUpdate for connection failed", self);
        return NO;
    }
    

    [node nodeConnected:toNode onBus:bus];

    return YES;
}

-(bool)disconnectNode:(CAMultiAudioNode *)node
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    if (!node.connectedTo)
    {
        NSLog(@"Node %@ is not connected to anything", node);
        return YES;
    }
    
    if (!node.audioUnit)
    {
        NSLog(@"Node %@ has no audio unit", node);
        return NO;
    }
    OSStatus err;
    
    err = AUGraphDisconnectNodeInput(_graphInst, node.connectedTo.node, node.connectedToBus);
    if (err)
    {
        NSLog(@"AUGraphDisconnectNodeInput failed for node %@, err %d", node, err);
    }
    
    [self graphUpdate];
    
    node.connectedTo = nil;
    return YES;
    
}

-(void)dealloc
{
    self.nodeList = nil;
    if (_graphInst)
    {
        DisposeAUGraph(_graphInst);
    }
}


@end
