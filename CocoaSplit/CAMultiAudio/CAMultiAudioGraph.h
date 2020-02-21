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
#import "CAMultiAudioConnection.h"

@interface CAMultiAudioGraph : NSObject
{
    AUGraph _graphInst;
}

//We need to hold references to all the nodes so this isn't a pain to use for clients

@property (assign) AUGraph graphInst;
@property (strong) NSMutableArray *nodeList;
@property (strong) NSMutableDictionary *nodeMap;
@property (strong) AVAudioFormat *audioFormat;
@property (weak) CAMultiAudioEngine *engine;
@property (assign) bool running;

-(instancetype)initWithFormat:(AVAudioFormat *)format;


-(bool)addNode:(CAMultiAudioNode *)newNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode format:(AVAudioFormat *)format;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode format:(AVAudioFormat *)format inBus:(UInt32)inBus outBus:(UInt32)outBus;
-(bool)disconnectNode:(CAMultiAudioNode *)node;
-(bool)disconnectNode:(CAMultiAudioNode *)node inputBus:(UInt32)inputBus;
-(bool)disconnectNode:(CAMultiAudioNode *)node outputBus:(UInt32)outputBus;
-(bool)disconnectNodeOutput:(CAMultiAudioNode *)node;
-(bool)disconnectNodeInput:(CAMultiAudioNode *)node;
-(CAMultiAudioConnection *)inputConnection:(CAMultiAudioNode *)node forBus:(UInt32)forBus;
-(NSArray *)outputConnections:(CAMultiAudioNode *)node forBus:(UInt32)forBus;
-(NSArray *)connectedInputBusses:(CAMultiAudioNode *)node;
-(NSArray *)connectedOutputBusses:(CAMultiAudioNode *)node;
-(CAMultiAudioConnection *)findOutputConnection:(CAMultiAudioNode *)node forNode:(CAMultiAudioNode *)forNode onBus:(UInt32)outBus;



-(bool)startGraph;
-(bool)stopGraph;
-(bool)graphUpdate;
-(bool)removeNode:(CAMultiAudioNode *)node;

@end

