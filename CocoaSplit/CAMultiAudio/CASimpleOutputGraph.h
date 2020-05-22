//
//  CASimpleOutputGraph.h
//  CocoaSplit
//
//  Created by Zakk on 5/21/20.
//  Copyright © 2020 Zakk. All rights reserved.
//


/*
 This class provides a very simple CAMultiAudioGraph, designed for outputing a single PCM audio stream to an output device
 The graph is just: PCMPlayer -> Mixer (for volume control) -> HAL output
 
 */
#import <Foundation/Foundation.h>
#import "CAMultiAudio.h"

NS_ASSUME_NONNULL_BEGIN

@interface CASimpleOutputGraph : NSObject
{
    CAMultiAudioGraph *_audioGraph;
    CAMultiAudioMixer *_audioMixer;
    CAMultiAudioPCMPlayer *_player;
    
}

@property (strong) CAMultiAudioDevice *outputNode;

-(instancetype) initWithAudioFormat:(AVAudioFormat *)audioFormat withOutputNode:(CAMultiAudioDevice *)outputNode;
-(void) playSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)start;
-(void)stop;


@end

NS_ASSUME_NONNULL_END
