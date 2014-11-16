//
//  CAMultiAudioEngine.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioEngine.h"

@implementation CAMultiAudioEngine

-(instancetype)initWithSamplerate:(UInt32)sampleRate
{
    if (self = [super init])
    {
        self.sampleRate = sampleRate;
        
        self.audioInputs = [NSMutableArray array];
        
        self.graph = [[CAMultiAudioGraph alloc] init];
        self.graph.sampleRate = sampleRate;
        
        self.silentNode = [[CAMultiAudioPCMPlayer alloc] init];
        self.defaultOutputNode = [[CAMultiAudioDefaultOutput alloc] init];
        self.encodeMixer = [[CAMultiAudioMixer alloc] init];
        self.previewMixer = [[CAMultiAudioMixer alloc] init];
        
        [self.graph addNode:self.defaultOutputNode];
        [self.graph addNode:self.silentNode];
        [self.graph addNode:self.encodeMixer];
        [self.graph addNode:self.previewMixer];
        
        [self.graph connectNode:self.previewMixer toNode:self.defaultOutputNode];
        [self.graph connectNode:self.encodeMixer toNode:self.previewMixer];
        [self.graph connectNode:self.silentNode toNode:self.encodeMixer];
        [self.graph startGraph];
        
    }
    
    return self;
}

-(void)attachInput:(CAMultiAudioNode *)input
{
    [self.graph addNode:input];
    [self.graph connectNode:input toNode:self.encodeMixer];
    [self addAudioInputsObject:input];
    

    
    
}


-(void)removeInput:(CAMultiAudioNode *)toRemove
{
    NSUInteger index = [self.audioInputs indexOfObject:toRemove];
    [self removeObjectFromAudioInputsAtIndex:index];
    
}

-(void)addAudioInputsObject:(CAMultiAudioNode *)object
{
    [self insertObject:object inAudioInputsAtIndex:self.audioInputs.count];
}

-(void)insertObject:(CAMultiAudioNode *)object inAudioInputsAtIndex:(NSUInteger)index
{
    [self.audioInputs insertObject:object atIndex:index];
}


-(void)removeObjectFromAudioInputsAtIndex:(NSUInteger)index
{
    CAMultiAudioNode *toRemove = [self.audioInputs objectAtIndex:index];
    [self.graph removeNode:toRemove];
    [self.audioInputs removeObjectAtIndex:index];
}

@end
