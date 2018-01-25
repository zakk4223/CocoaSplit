//
//  CAMultiAudioGraph.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

#import "CAMultiAudioNode.h"


@interface CAMultiAudioGraph : NSObject
{
    AUGraph _graphInst;
    AudioStreamBasicDescription *_graphAsbd;
    
}

//We need to hold references to all the nodes so this isn't a pain to use for clients

@property (assign) AUGraph graphInst;
@property (strong) NSMutableArray *nodeList;
@property (assign) int sampleRate;
@property (assign) AudioStreamBasicDescription *graphAsbd;
@property (weak) CAMultiAudioEngine *engine;

-(instancetype)initWithSamplerate:(int)samplerate;

-(bool)addNode:(CAMultiAudioNode *)newNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode;
-(bool)connectNode:(CAMultiAudioNode *)node toNode:(CAMultiAudioNode *)toNode sampleRate:(int)sampleRate;
-(bool)disconnectNode:(CAMultiAudioNode *)node;


-(bool)startGraph;
-(bool)stopGraph;
-(bool)graphUpdate;
-(bool)removeNode:(CAMultiAudioNode *)node;

@end

