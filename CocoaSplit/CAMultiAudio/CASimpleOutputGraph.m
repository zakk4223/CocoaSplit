//
//  CASimpleOutputGraph.m
//  CocoaSplit
//
//  Created by Zakk on 5/21/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CASimpleOutputGraph.h"

@implementation CASimpleOutputGraph

@synthesize outputNode = _outputNode;

-(instancetype)initWithAudioFormat:(AVAudioFormat *)audioFormat withOutputNode:(CAMultiAudioDevice *)outputNode
{
    if (self = [self init])
    {
        self.outputNode = outputNode;
        [self buildGraph:audioFormat];
        
    }
    return self;
}

-(void)buildGraph:(AVAudioFormat *)audioFormat
{
    _audioGraph = [[CAMultiAudioGraph alloc] initWithFormat:audioFormat];
    _audioGraph.isSimple = YES;
    _audioMixer = [[CAMultiAudioMixer alloc] init];
    _player = [[CAMultiAudioPCMPlayer alloc] init];
    _player.inputFormat = audioFormat;
    if (self.outputNode)
    {
        [_audioGraph addNode:self.outputNode];
        _audioGraph.outputNode = self.outputNode;
        [_audioGraph.outputNode setOutputForDevice];
    }
    [_audioGraph addNode:_audioMixer];
    [_audioGraph addNode:_player];
    [_audioGraph connectNode:_audioMixer toNode:_audioGraph.outputNode];
    [_audioGraph connectNode:_player toNode:_audioMixer];
    _audioMixer.volume = 1.0f;
    [self start];
    
}

-(void)playSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (_player)
    {
        [_player scheduleBuffer:sampleBuffer];
    }
}

-(void)start
{
    if (_audioGraph)
    {
        [_audioGraph startGraph];
        _player.enabled = YES;
    }
}

-(void)stop
{
    if (_audioGraph)
    {
        [_audioGraph stopGraph];
    }
}

@end


