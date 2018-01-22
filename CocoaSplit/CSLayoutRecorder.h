//
//  CSLayoutRecorder.h
//  CocoaSplit
//
//  Created by Zakk on 4/30/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"
#import "LayoutRenderer.h"
#import "VideoCompressor.h"
#import "OutputDestination.h"
#import "CSStreamServiceProtocol.h"
#import "CAMultiAudioEngine.h"
#import "CSAacEncoder.h"
#import "CSLayoutRecorderInfoProtocol.h"
#import "CSTimerSourceProtocol.h"
#import "CSCaptureBase+TimerDelegate.h"


@interface CSLayoutRecorder : NSObject <CSLayoutRecorderInfoProtocol, CSTimerSourceProtocol, CSEncodedAudioReceiverProtocol>
{
    dispatch_queue_t _frame_queue;
    long long _frameCount;
    CFAbsoluteTime _firstFrameTime;
    double _frame_time;
    CMTime _firstAudioTime;
    CMTime _previousAudioTime;
    CMTime _firstPcmAudioTime;
    CMTime _previousPcmAudioTime;
    NSMutableArray *_audioBuffer;
    NSMutableArray *_pcmAudioBuffer;




    

}

@property (strong) CAMultiAudioEngine *audioEngine;
@property (strong) CSAacEncoder *audioEncoder;

@property (strong) SourceLayout *layout;
@property (strong) LayoutRenderer *renderer;
@property (strong) NSString *compressor_name;
@property (strong) NSString *baseDirectory;

@property (strong) NSString *outputFilename;

@property (strong) id<VideoCompressor> compressor;
@property (strong) OutputDestination *output;
@property (strong) NSString *fileFormat;

@property (strong) NSMutableDictionary *compressors;
@property (strong) NSMutableArray *outputs;
@property (readonly) float frameRate;


@property (assign) bool useTimestamp;
@property (assign) bool noClobber;

@property (assign) bool recordingActive;
@property (assign) bool defaultRecordingActive;
@property (nonatomic, copy) void(^frameReadyBlock)(void);


-(void) startRecording;
-(void)stopDefaultRecording;
-(void)stopRecordingForOutput:(OutputDestination *)output;
-(void)startRecordingWithOutput:(OutputDestination *)output;
-(void)stopRecordingAll;
-(void)startRecordingCommon;

-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name;
-(void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)captureOutputAudio:(id)fromDevice didOutputPCMSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
