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



@interface CSLayoutRecorder : NSObject <CSLayoutRecorderInfoProtocol>
{
    dispatch_queue_t _frame_queue;
    long long _frameCount;
    CFAbsoluteTime _firstFrameTime;
    double _frame_time;
    CMTime _firstAudioTime;
    CMTime _previousAudioTime;
    NSMutableArray *_audioBuffer;




    

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


-(void) startRecording;
-(void)stopRecording;
-(void)stopDefaultRecording;
-(void)stopRecordingForOutput:(OutputDestination *)output;
-(void)startRecordingWithOutput:(OutputDestination *)output;
-(void)stopRecordingAll;

-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name;


@end
