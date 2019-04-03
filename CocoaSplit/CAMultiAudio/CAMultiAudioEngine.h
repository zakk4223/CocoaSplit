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
#import "CAMultiAudioSilence.h"
#import "CAMultiAudioEffect.h"
#import "CAMultiAudioOutputTrack.h"

/* our default graph setup looks like this:
 
 
 
 silentNode -> encodeMixer -> previewMixer -> AUHAL
 The outout of encodeMixer is tapped to provide the audio for the outgoing stream
*/
@interface CAMultiAudioEngine : NSObject <NSCoding>
{
    NSString            *_outputId;
    NSMutableDictionary *_inputSettings;
    CAMultiAudioAVCapturePlayer *_defaultInput;
}



@property (strong) CAMultiAudioGraph *graph;
@property (strong) CAMultiAudioMixer *previewMixer;
@property (strong) CAMultiAudioSilence *silentNode;
@property (strong) CAMultiAudioDefaultOutput *defaultOutputNode;
@property (strong) NSMutableArray *audioInputs;
@property (strong) NSMutableArray *pcmInputs;
@property (strong) NSMutableArray *fileInputs;
@property (strong) CAMultiAudioOutputTrack *defaultOutputTrack;

@property (strong) CAMultiAudioDownmixer *encodeMixer;
//@property (strong) CSAacEncoder *encoder;
@property (assign) UInt32 sampleRate;
@property (assign) int audioBitrate;
@property (assign) double audio_adjust;
@property (strong) NSArray *audioOutputs;
@property (strong) CAMultiAudioDevice *outputNode;
@property (strong) CAMultiAudioDevice *graphOutputNode;
@property (strong) NSArray *validSamplerates;
@property (assign) Float32 streamAudioPowerLevel;
@property (assign) Float32 previewAudioPowerLevel;
@property (strong) NSMutableDictionary *streamAudioPowerLevels;
@property (strong) NSMutableDictionary *previewAudioPowerLevels;
@property (strong) NSMutableDictionary *outputTracks;

@property (strong) CAMultiAudioEffect *renderNode;


-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)uniqueID withFormat:(const AudioStreamBasicDescription *)withFormat;
-(CAMultiAudioFile *)createFileInput:(NSString *)filePath;
-(void)addFileInput:(CAMultiAudioFile *)fileInput;



-(void)removePCMInput:(CAMultiAudioPCMPlayer *)toRemove;
-(void)removeFileInput:(CAMultiAudioFile *)toRemove;
-(bool)attachInput:(CAMultiAudioInput *)input;
-(void)updateStatistics;
-(void)applyInputSettings:(NSDictionary *)inputSettings;
-(NSMutableDictionary *)generateInputSettings;
-(CAMultiAudioInput *)inputForUUID:(NSString *)uuid;
-(void) disableAllInputs;
-(void)removeInputAny:(CAMultiAudioInput *)input;
-(NSDictionary *)systemAudioInputs;
-(CAMultiAudioInput *)inputForSystemUUID:(NSString *)uuid;
-(void)startEncoders;
-(void)stopEncoders;
-(void)addOutputTrack;
-(bool)createOutputTrack:(NSString *)withName;
-(bool)removeOutputTrack:(NSString *)withName;
-(bool)addInput:(CAMultiAudioInput *)input toTrack:(CAMultiAudioOutputTrack *)outputTrack;
-(bool)removeInput:(CAMultiAudioInput *)input fromTrack:(CAMultiAudioOutputTrack *)outputTrack;


@end
