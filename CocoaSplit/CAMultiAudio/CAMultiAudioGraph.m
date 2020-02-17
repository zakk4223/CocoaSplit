//
//  CAMultiAudioGraph.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import "CAMultiAudioGraph.h"

#import "CAMultiAudioDevice.h"




@implementation CAMultiAudioGraph

-(instancetype)initWithSamplerate:(double)samplerate
{
    if (self = [self init])
    {
        
        _avEngine = [[AVAudioEngine alloc] init];
        
        //default to something reasonable
        
        _sampleRate = samplerate;
        
        
        //set to canonical, 2 channel
        self.graphFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:_sampleRate channels:2];
        //Always force an input singleton
        NSLog(@"%@", _avEngine.inputNode);
        
        
    }
    
    return self;
}

-(AVAudioOutputNode *)defaultOutputNode
{
    return _avEngine.outputNode;
}


-(AVAudioInputNode *)defaultInputNode
{
    return _avEngine.inputNode;
}


-(bool)startGraph
{
    if (!_avEngine)
    {
        return NO;
    }
    
    NSError *startError = nil;
    [_avEngine startAndReturnError:&startError];
    
    if (startError)
    {
        NSLog(@"AUGraphStart failed, err %@", startError);
        return NO;
    }
    
    return YES;
}

-(bool)stopGraph
{
    if (!_avEngine)
    {
        return NO;
    }
    
    [_avEngine stop];
    
    return YES;
}


-(bool)addNode:(CAMultiAudioNode *)newNode
{
    
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!newNode)
    {
        return NO;
    }
    
    if (!newNode.avAudioNode)
    {
        return NO;
    }
    
    if (newNode.avAudioNode.engine)
    {
        return YES;
    }
    
    
    [_avEngine attachNode:newNode.avAudioNode];

    newNode.graph = self;
    [newNode didAttachNode];
    
    [newNode setupEffectsChain];
    return YES;
}

-(bool)removeNode:(CAMultiAudioNode *)node
{
    
    if (!_avEngine || !node || !node.avAudioNode)
    {
        return NO;
    }
    
    [node willRemoveNode];
    
    

    [_avEngine detachNode:node.avAudioNode];
    [node removeEffectsChain];
    node.graph = nil;
    return YES;
    
}

-(bool)addConnection:(CAMultiAudioNode *)fromNode toNode:(CAMultiAudioNode *)toNode  withFormat:(AVAudioFormat *)format
{
    [self addConnection:fromNode toNode:toNode toBus:0 withFormat:format];
}


-(bool)addConnection:(CAMultiAudioNode *)fromNode toNode:(CAMultiAudioNode *)toNode toBus:(AVAudioNodeBus)toBus withFormat:(AVAudioFormat *)format
{
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!fromNode || !toNode || !fromNode.avAudioNode || !toNode.avAudioNode)
    {
        return NO;
    }
    
    AVAudioFormat *useFormat = format;
    if (!useFormat)
    {
        useFormat = self.graphFormat;
    }
    
    NSMutableArray *existingConnections = [_avEngine outputConnectionPointsForNode:fromNode.avAudioNode outputBus:0].mutableCopy;
    AVAudioConnectionPoint *newConnect = [[AVAudioConnectionPoint alloc] initWithNode:toNode.avAudioNode bus:toBus];
    [existingConnections addObject:newConnect];
    [_avEngine connect:fromNode.avAudioNode toConnectionPoints:existingConnections fromBus:0 format:useFormat];
    return YES;
}


-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode
{
    return [self connectNode:node toNode:toNode withFormat:self.graphFormat];
}



-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode withFormat:(AVAudioFormat *)format
{
    
    
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!node || !toNode || !format)
    {
        return NO;
    }
    
    if (!node.avAudioNode || !toNode.avAudioNode)
    {
        return NO;
    }
    
    NSLog(@"CONNECTING %@ TO %@ WITH FORMAT %@", node, toNode, format);
    [_avEngine connect:node.avAudioNode to:toNode.avAudioNode format:format];
    return YES;
    
}


-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode withFormat:(AVAudioFormat *)format inBus:(UInt32)inBus outBus:(UInt32)outBus
{
    
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!node || !toNode || !format)
    {
        return NO;
    }
    
    if (!node.avAudioNode || !toNode.avAudioNode)
    {
        return NO;
    }
    
    [_avEngine connect:node.avAudioNode to:toNode.avAudioNode fromBus:outBus toBus:inBus format:format];
    return YES;
    
}

-(bool)disconnectNode:(CAMultiAudioNode *)node inputBus:(AVAudioNodeBus)inputBus
{
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!node || !node.avAudioNode)
    {
        return NO;
    }
    
    [_avEngine disconnectNodeInput:node.avAudioNode bus:inputBus];
    
    return YES;
}
-(bool)disconnectNode:(CAMultiAudioNode *)node
{
    if (!_avEngine)
    {
        return NO;
    }
    
    if (!node || !node.avAudioNode)
    {
        return NO;
    }
    
    [_avEngine disconnectNodeInput:node.avAudioNode];
    [_avEngine disconnectNodeOutput:node.avAudioNode];
    
    return YES;
}

-(void)dealloc
{
    _avEngine = nil;
}


@end
