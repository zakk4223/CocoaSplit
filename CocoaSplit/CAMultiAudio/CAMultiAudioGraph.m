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
    }
    
    return self;
}

-(bool)startGraph
{
    OSStatus err;
    if (!self.outputNode)
    {
        return NO;
    }
    
    
    err = AudioOutputUnitStart(self.outputNode.audioUnit);
    if (err)
    {
        NSLog(@"AudioOutputUnitStart failed, err %d", err);
        return NO;
    }
    
    return YES;
}

-(bool)stopGraph
{
    if (!self.outputNode)
    {
        return NO;
    }
    OSStatus err;
    
    err = AudioOutputUnitStop(self.outputNode.audioUnit);
    if (err)
    {
        NSLog(@"AudioOutputUnitStop failed, err: %d", err);
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
    
    if ([newNode createNode])
    {
        newNode.graph = self;
        newNode.engine = self.engine;
        
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
    if (!node)
    {
        return NO;
    }

    if (![self disconnectNode:node])
    {
        NSLog(@"Remove node %@: disconnected failed", node);
        return NO;
    }

    @synchronized (self.nodeList) {
        [self.nodeList removeObject:node];
    }
    [node removeEffectsChain];
    node.graph = nil;
    return YES;
    
}


-(bool)connectNode:(CAMultiAudioNode *)node usingConnections:(NSArray *)connections outBus:(UInt32)outBus
{
    return [self connectNode:node usingConnections:connections outBus:outBus format:self.audioFormat];
}


-(bool)connectNode:(CAMultiAudioNode *)node usingConnections:(NSArray *)connections outBus:(UInt32)outBus format:(AVAudioFormat *)format
{
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
    @synchronized(self)
    {
        if (!node || !toNode)
        {
            NSLog(@"ConnectNode: Source or destination node is nil %@ -> %@", node, toNode);
            return NO;
        }
        
                
        OSStatus err;
        
        UInt32 bus = inBus;
        
        
        [self disconnectNode:node outputBus:outBus];
        [self disconnectNode:toNode inputBus:inBus];
        
        [node willConnectToNode:toNode inBus:bus outBus:outBus];
        
        [toNode willConnectNode:node inBus:bus outBus:outBus];
        
        
        [toNode setInputStreamFormat:format bus:inBus];
        [node setOutputStreamFormat:format bus:outBus];
        
        
        AudioUnitConnection newConn;
        newConn.destInputNumber = inBus;
        newConn.sourceOutputNumber = outBus;
        newConn.sourceAudioUnit = node.audioUnit;
        
        err = AudioUnitSetProperty(toNode.audioUnit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, inBus, &newConn, sizeof(newConn));
        
        if (err)
        {
            NSLog(@"AudioUnitSetProperty(MakeConnection) failed for %@ -> %@, err: %d", node, toNode, err);
            NSLog(@"%@ OUTPUT %@", node, [node outputFormatForBus:outBus]);
            NSLog(@"%@ INPUT %@", toNode, [toNode inputFormatForBus:inBus]);
            return NO;
        }
        
        [node nodeConnected:toNode inBus:bus outBus:outBus];
        
        [toNode connectedToNode:node inBus:bus outBus:outBus];
        
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
    }
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
    if (!node)
    {
        return NO;
    }
    
    @synchronized (self)
    {
        CAMultiAudioConnection *inputConnection = node.inputConnections[@(inputBus)];
        
        if (inputConnection)
        {
            
            AudioUnitConnection breakConn;
            breakConn.destInputNumber = inputBus;
            breakConn.sourceOutputNumber = inputConnection.bus;
            breakConn.sourceAudioUnit = NULL;
            
            OSErr err = AudioUnitSetProperty(node.audioUnit, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, inputBus, &breakConn, sizeof(breakConn));
            if (err)
            {
                NSLog(@"AudioUnitSetProperty(MakeConnection) failed for node %@:%d, err %d", node, inputBus, err);
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
    }
    return YES;
}


-(bool)disconnectNodeOutput:(CAMultiAudioNode *)node
{
    
    if (!node)
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
    if (!node)
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
    if (!node)
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
    if (!node)
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
}


@end
