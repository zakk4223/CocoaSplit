//
//  CAMultiAudioEngine.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudio.h"
#import "CSAacEncoder.h"


/* our default graph setup looks like this:
 
 
 
 silentNode -> encodeMixer -> previewMixer -> defaultOutputNode
 The outout of encodeMixer is tapped to provide the audio for the outgoing stream
*/
@interface CAMultiAudioEngine : NSObject <NSCoding>
{
    AudioDeviceID   _outputId;
    NSMutableDictionary *_inputSettings;
}



@property (strong) CAMultiAudioGraph *graph;
@property (strong) CAMultiAudioMixer *previewMixer;
@property (strong) CAMultiAudioPCMPlayer *silentNode;
@property (strong) CAMultiAudioDefaultOutput *defaultOutputNode;
@property (strong) NSMutableArray *audioInputs;
@property (strong) CAMultiAudioMixer *encodeMixer;
@property (strong) CSAacEncoder *encoder;
@property (assign) UInt32 sampleRate;
@property (strong) NSArray *audioOutputs;
@property (strong) CAMultiAudioDevice *outputNode;
@property (strong) CAMultiAudioDevice *graphOutputNode;
@property (strong) NSArray *validSamplerates;





-(void)attachInput:(CAMultiAudioNode *)input;
-(instancetype)initWithSamplerate:(UInt32)sampleRate;
-(void)updateStatistics;


@end
