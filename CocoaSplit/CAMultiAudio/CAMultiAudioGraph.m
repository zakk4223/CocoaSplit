//
//  CAMultiAudioGraph.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioGraph.h"

#import "CAMultiAudioDevice.h"




@implementation CAMultiAudioGraph
@synthesize graphAsbd = _graphAsbd;

-(instancetype)initWithSamplerate:(int)samplerate
{
    if (self = [self init])
    {
        //default to something reasonable
        
        _sampleRate = samplerate;
        //set to canonical, 2 channel
        self.graphAsbd = malloc(sizeof(AudioStreamBasicDescription));
        
        _graphAsbd->mSampleRate = self.sampleRate;
        _graphAsbd->mFormatID = kAudioFormatLinearPCM;
        _graphAsbd->mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;
        _graphAsbd->mFramesPerPacket = 1;
        _graphAsbd->mChannelsPerFrame = 2;
        _graphAsbd->mReserved = 0;
        _graphAsbd->mBytesPerPacket = 1 * sizeof(Float32);
        _graphAsbd->mBytesPerFrame = 1 * sizeof(Float32);
        _graphAsbd->mBitsPerChannel = 8 * sizeof(Float32);
        
        
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
    
    if ([self.nodeList containsObject:newNode])
    {
        return YES;
    }
    
    
    if ([newNode createNode:self])
    {
        
        

       [newNode setInputStreamFormat:self.graphAsbd];
      [newNode setOutputStreamFormat:self.graphAsbd];
        
        [newNode willInitializeNode];
        
        OSStatus err = AudioUnitInitialize(newNode.audioUnit);
        if (err)
        {
            NSLog(@"AudioUnitInitialize failed for node %@ with status %d", newNode, err);
            return NO;
        }
        
        [newNode didInitializeNode];
        
        [self.nodeList addObject:newNode];
        [newNode setupEffectsChain];
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
    
    [node willRemoveNode];
    
    
    
    OSStatus err;
    
    if (![self disconnectNode:node])
    {
        NSLog(@"Remove node %@: disconnected failed", node);
        return NO;
    }
    
    for (NSString *inpUUID in node.inputMap)
    {
        NSDictionary *inpInfo = node.inputMap[inpUUID];
        CAMultiAudioNode *inpNode = inpInfo[@"node"];
        [inpNode.outputMap removeObjectForKey:node.nodeUID];
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
    [node removeEffectsChain];
    node.graph = nil;
    return YES;
    
}

-(bool)graphUpdate
{
    if (!_graphInst)
    {
        return NO;
    }
    OSStatus err;
    
    /*
    if (![self stopGraph])
    {
        NSLog(@"Graph %@: graphUpdate, stopGraph failed", self);
        return NO;
    }
    */
    
    err = AUGraphUpdate(_graphInst, NULL);
    if (err)
    {
        NSLog(@"AUGraphUpdate failed, err: %d", err);
        return NO;
    }
    
    /*
    if (![self startGraph])
    {
        NSLog(@"Graph %@: graphUpdate, startGraph failed", self);
        return NO;

    }*/
    
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
    
    OSStatus err;
    
    UInt32 bus = toNode.inputElement;
    UInt32 outBus = node.outputElement;
    
    [node willConnectToNode:toNode inBus:bus outBus:outBus];
    
    [toNode willConnectNode:node inBus:bus outBus:outBus];
    
    CAMultiAudioNode *useNode = node;
    if (node.headNode)
    {
        useNode = node.headNode;
    }

    inNode = useNode.node;
    connectTo = toNode.node;
    //aUnit = node.audioUnit;
    
    err = AUGraphConnectNodeInput(_graphInst, inNode, outBus, connectTo, bus);
    if (err)
    {
        NSLog(@"AUGraphConnectNodeInput failed for %@ -> %@, err: %d", node, toNode, err);
        return NO;
    }
    
    [useNode nodeConnected:toNode inBus:bus outBus:outBus];

    [toNode connectedToNode:node inBus:bus outBus:outBus];
    
    if (![self graphUpdate])
    {
        
        NSLog(@"Graph %@ graphUpdate for connection failed %@ -> %@", self, node, toNode);
        return NO;
    }


    return YES;
}

-(bool)disconnectNode:(CAMultiAudioNode *)node
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    if (!node.outputMap || node.outputMap.count == 0)
    {
       // NSLog(@"Node %@ is not connected to anything", node);
        return YES;
    }
    
    if (!node.audioUnit) 
    {
        NSLog(@"Node %@ has no audio unit", node);
        return NO;
    }
    OSStatus err;
    for(NSString *uuid in node.outputMap)
    {
        NSDictionary *outDict = node.outputMap[uuid];
        CAMultiAudioNode *outNode = outDict[@"node"];
        NSNumber *inBus = outDict[@"inBus"];
        err = AUGraphDisconnectNodeInput(_graphInst, outNode.node, inBus.unsignedIntValue);
        if (err)
        {
            NSLog(@"AUGraphDisconnectNodeInput failed for source node %@ dest node %@, err %d", node, outNode, err);
        }
        [outNode.inputMap removeObjectForKey:node.nodeUID];
    }
    
    [node.outputMap removeAllObjects];

    [self graphUpdate];
    
    return YES;
    
}

-(void)dealloc
{
    self.nodeList = nil;
    if (self.graphAsbd)
    {
        free(self.graphAsbd);
    }
    
    
    if (_graphInst)
    {
        DisposeAUGraph(_graphInst);
    }
}


@end
