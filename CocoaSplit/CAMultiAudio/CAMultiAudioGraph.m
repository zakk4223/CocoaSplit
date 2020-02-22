//
//  CAMultiAudioGraph.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioGraph.h"

#import "CAMultiAudioDevice.h"



@implementation CAMultiAudioGraph

-(instancetype)initWithFormat:(AVAudioFormat *)format
{
    if (self = [self init])
    {
        //default to something reasonable
        
        _audioFormat = format;
        if (!_audioFormat)
        {
            _audioFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0f channels:2];
        }
        
        self.nodeList = [NSMutableArray array];
        self.nodeMap = [NSMutableDictionary dictionary];
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
    @synchronized(self.nodeList)
    {
        if ([self.nodeList containsObject:newNode])
        {
            return YES;
        }
    }
    
    if ([newNode createNode:self])
    {
        [newNode willInitializeNode];
        
        OSStatus err = AudioUnitInitialize(newNode.audioUnit);
        if (err)
        {
            NSLog(@"AudioUnitInitialize failed for node %@ with status %d", newNode, err);
            return NO;
        }
        [newNode didInitializeNode];
        
        @synchronized (self.nodeList) {
            [self.nodeList addObject:newNode];
        }
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

    @synchronized (self.nodeList) {
        [self.nodeList removeObject:node];
    }
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

-(bool)connectNode:(CAMultiAudioNode *)node usingConnections:(NSArray *)connections outBus:(UInt32)outBus
{
    return [self connectNode:node usingConnections:connections outBus:outBus format:self.audioFormat];
}


-(bool)connectNode:(CAMultiAudioNode *)node usingConnections:(NSArray *)connections outBus:(UInt32)outBus format:(AVAudioFormat *)format
{
    if (!_graphInst)
    {
        NSLog(@"ConnectNode: No AUGraph!");
        return NO;
    }
    
    if (!node)
    {
        return NO;
    }
    
    for(CAMultiAudioConnection *conn in connections)
    {
        [self connectNode:node toNode:conn.node format:format inBus:conn.bus outBus:outBus];
    }
    
    return YES;
}


-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode
{
    return [self connectNode:node toNode:toNode format:self.audioFormat];
}



-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode format:(AVAudioFormat *)format
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
    
    UInt32 inBus = toNode.inputElement;
    UInt32 outBus = node.outputElement;
    
    return [self connectNode:node toNode:toNode format:format inBus:inBus outBus:outBus];
}


-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode format:(AVAudioFormat *)format inBus:(UInt32)inBus outBus:(UInt32)outBus
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
    
    
    NSLog(@"CONNECT %@:%d TO %@:%d FORMAT %@", node, outBus, toNode, inBus, format);
    AUNode inNode;
    AUNode connectTo;
    
    OSStatus err;
    
    UInt32 bus = inBus;
    
    

    [node willConnectToNode:toNode inBus:bus outBus:outBus];
    
    [toNode willConnectNode:node inBus:bus outBus:outBus];
    

    inNode = node.node;
    connectTo = toNode.node;
    //aUnit = node.audioUnit;
    [toNode setInputStreamFormat:format bus:inBus];
    [node setOutputStreamFormat:format bus:outBus];

    err = AUGraphConnectNodeInput(_graphInst, inNode, outBus, connectTo, bus);
    if (err)
    {
        NSLog(@"AUGraphConnectNodeInput failed for %@ -> %@, err: %d", node, toNode, err);
        return NO;
    }

    [node nodeConnected:toNode inBus:bus outBus:outBus];

    [toNode connectedToNode:node inBus:bus outBus:outBus];
    
    if (![self graphUpdate])
    {
        
        UInt32 elementCount = 0;
        UInt32 elementSize = sizeof(UInt32);
        
        
        AudioUnitGetProperty(toNode.audioUnit, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &elementCount, &elementSize);
        
        NSLog(@"Graph %@ graphUpdate for connection failed %@:%d -> %@:%d (%d)", self, node, outBus, toNode, bus, elementCount );
        return NO;
    }

    NSMutableArray *outputsForBus = node.outputConnections[@(outBus)];
    if (!outputsForBus)
    {
        outputsForBus = [NSMutableArray array];
        node.outputConnections[@(outBus)] = outputsForBus;
    }
    [outputsForBus addObject:[[CAMultiAudioConnection alloc] initWithNode:toNode bus:inBus]];
    toNode.inputConnections[@(inBus)] = [[CAMultiAudioConnection alloc] initWithNode:node bus:outBus];
    NSLog(@"%@ OUTPUT %@", node, [node outputFormatForBus:outBus]);
    NSLog(@"%@ INPUT %@", toNode, [toNode inputFormatForBus:inBus]);
    
    return YES;
}


-(NSArray *)connectedInputBusses:(CAMultiAudioNode *)node
{
    return node.inputConnections.allKeys;
}

-(NSArray *)connectedOutputBusses:(CAMultiAudioNode *)node
{
    return node.outputConnections.allKeys;
}



-(CAMultiAudioConnection *)findOutputConnection:(CAMultiAudioNode *)node forNode:(CAMultiAudioNode *)forNode onBus:(UInt32)outBus
{
    
    CAMultiAudioConnection *retConn = nil;
    NSArray *outConns = [self outputConnections:node forBus:outBus];
    for(CAMultiAudioConnection *conn in outConns)
    {
        if (conn.node == forNode)
        {
            retConn = conn;
            break;
        }
    }
    
    return retConn;
}


-(CAMultiAudioConnection *)inputConnection:(CAMultiAudioNode *)node forBus:(UInt32)forBus
{
    return node.inputConnections[@(forBus)];
}


-(NSArray *)outputConnections:(CAMultiAudioNode *)node forBus:(UInt32)forBus
{
    NSMutableArray *conns = node.outputConnections[@(forBus)];
    
    if (conns)
    {
        return [conns copy];
    }
    
    return @[];
}


-(bool)disconnectNode:(CAMultiAudioNode *)node inputBus:(UInt32)inputBus
{
    return [self disconnectNode:node inputBus:inputBus updateOutputs:YES];
}


-(bool)disconnectNode:(CAMultiAudioNode *)node inputBus:(UInt32)inputBus updateOutputs:(bool)updateOutputs
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    CAMultiAudioConnection *inputConnection = node.inputConnections[@(inputBus)];
    
    if (inputConnection)
    {
        OSErr err = AUGraphDisconnectNodeInput(_graphInst, node.node, inputBus);
        if (err)
        {
            NSLog(@"AUGraphDisconnectNodeInput failed for node %@:%d, err %d", node, inputBus, err);
        }
        
        if (updateOutputs)
        {
            CAMultiAudioNode *srcNode = inputConnection.node;
            if (srcNode)
            {
                NSMutableArray *newConns = [NSMutableArray array];
                NSArray *conns = [self outputConnections:srcNode forBus:inputConnection.bus];
                for(CAMultiAudioConnection *nConn in conns)
                {
                    if (nConn.node != node)
                    {
                        [newConns addObject:nConn];
                    }
                }
                
                srcNode.outputConnections[@(inputConnection.bus)] = newConns;
            }
        }
        [node.inputConnections removeObjectForKey:@(inputBus)];
    }
    [self graphUpdate];
    return YES;
}


-(bool)disconnectNodeOutput:(CAMultiAudioNode *)node
{
    
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    NSArray *outbusses = node.outputConnections.allKeys;
    
    for(NSNumber *busNum in outbusses)
    {
        [self disconnectNode:node outputBus:busNum.unsignedIntValue];
    }
    
    return YES;
}

-(bool)disconnectNodeInput:(CAMultiAudioNode *)node
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    NSArray *inbusses = node.inputConnections.allKeys;
    for(NSNumber *busNum in inbusses)
    {
        [self disconnectNode:node inputBus:busNum.unsignedIntValue updateOutputs:YES];
    }
    return YES;
}


-(bool)disconnectNode:(CAMultiAudioNode *)node outputBus:(UInt32)outputBus
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    NSArray *outputConnections = [self outputConnections:node forBus:outputBus];
    
    for(CAMultiAudioConnection *conn in outputConnections)
    {
        [self disconnectNode:conn.node inputBus:conn.bus updateOutputs:NO];
    }
    
    [node.outputConnections removeObjectForKey:@(outputBus)];
    return YES;
}


-(bool)disconnectNode:(CAMultiAudioNode *)node
{
    if (!_graphInst || !node)
    {
        return NO;
    }
    
    [self disconnectNodeInput:node];
    [self disconnectNodeOutput:node];

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
