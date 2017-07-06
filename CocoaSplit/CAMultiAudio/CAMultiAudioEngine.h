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
#import "CAMultiAudioConverter.h"



/* our default graph setup looks like this:
 
 
 
 silentNode -> encodeMixer -> previewMixer -> AUHAL
 The outout of encodeMixer is tapped to provide the audio for the outgoing stream
*/
@interface CAMultiAudioEngine : NSObject <NSCoding>
{
    NSString            *_outputId;
    NSMutableDictionary *_inputSettings;
}



@property (strong) CAMultiAudioGraph *graph;
@property (strong) CAMultiAudioMixer *previewMixer;
@property (strong) CAMultiAudioPCMPlayer *silentNode;
@property (strong) CAMultiAudioDefaultOutput *defaultOutputNode;
@property (strong) NSMutableArray *audioInputs;
@property (strong) NSMutableArray *pcmInputs;

@property (strong) CAMultiAudioMixer *encodeMixer;
@property (strong) CSAacEncoder *encoder;
@property (assign) UInt32 sampleRate;
@property (strong) NSArray *audioOutputs;
@property (strong) CAMultiAudioDevice *outputNode;
@property (strong) CAMultiAudioDevice *graphOutputNode;
@property (strong) NSArray *validSamplerates;
@property (assign) Float32 streamAudioPowerLevel;
@property (assign) Float32 previewAudioPowerLevel;



-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)uniqueID withFormat:(const AudioStreamBasicDescription *)withFormat;


-(void)removePCMInput:(CAMultiAudioPCMPlayer *)toRemove;
-(void)attachInput:(CAMultiAudioNode *)input;
-(void)updateStatistics;
-(void)applyInputSettings:(NSDictionary *)inputSettings;
-(NSDictionary *)generateInputSettings;
-(CAMultiAudioNode *)inputForUUID:(NSString *)uuid;




@end
