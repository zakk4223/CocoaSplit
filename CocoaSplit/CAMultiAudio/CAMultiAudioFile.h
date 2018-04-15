//
//  CAMultiAudioFile.h
//  CocoaSplit
//
//  Created by Zakk on 7/23/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioInput.h"

@interface CAMultiAudioFile : CAMultiAudioInput
{
    AudioFileID _audioFile;
    Float64 _outputSampleRate;
    SInt64 _lastStartFrame;
    
    
}

@property (strong) NSString *filePath;
@property (assign) AudioStreamBasicDescription *outputFormat;
@property (assign) Float64 duration;
@property (assign) Float64 currentTime;
@property (assign) bool playing;
@property (assign) Float64 startTime;
@property (assign) Float64 endTime;
@property (assign) bool loop;



-(instancetype)initWithPath:(NSString *)path;
-(void)play;
-(void)stop;
-(void)rewind;
+(Float64)durationForPath:(NSString *)path;


@end
