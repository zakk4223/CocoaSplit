//
//  CAMultiAudioGraph.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#import "CAMultiAudioNode.h"


@interface CAMultiAudioGraph : NSObject
{
    AVAudioEngine *_avEngine;
    AUGraph _graphInst;
    AudioStreamBasicDescription *_graphAsbd;
    
}

//We need to hold references to all the nodes so this isn't a pain to use for clients

@property (strong) NSMutableArray *attachedNodes;
@property (assign) AUGraph graphInst;
@property (readonly) NSSet *nodeSet;
@property (assign) double sampleRate;
@property (strong) AVAudioFormat *graphFormat;
@property (weak) CAMultiAudioEngine *engine;
@property (readonly) AVAudioInputNode *defaultInputNode;
@property (readonly) AVAudioOutputNode *defaultOutputNode;

-(instancetype)initWithSamplerate:(double)samplerate;

-(bool)addNode:(CAMultiAudioNode *)newNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode withFormat:(AVAudioFormat *)format;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode withFormat:(AVAudioFormat *)format inBus:(UInt32)inBus outBus:(UInt32)outBus;
-(bool)addConnection:(CAMultiAudioNode *)fromNode toNode:(CAMultiAudioNode *)toNode withFormat:(AVAudioFormat *)format;
-(bool)addConnection:(CAMultiAudioNode *)fromNode toNode:(CAMultiAudioNode *)toNode toBus:(AVAudioNodeBus)toBus withFormat:(AVAudioFormat *)format;
-(bool)disconnectNode:(CAMultiAudioNode *)node inputBus:(AVAudioNodeBus)inputBus;
-(bool)disconnectNode:(CAMultiAudioNode *)node;
-(bool)disconnectNodeOutput:(CAMultiAudioNode *)node;

-(bool)startGraph;
-(bool)stopGraph;
-(bool)graphUpdate;
-(bool)removeNode:(CAMultiAudioNode *)node;

@end

