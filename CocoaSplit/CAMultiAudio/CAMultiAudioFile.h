//
//  CAMultiAudioFile.h
//  CocoaSplit
//
//  Created by Zakk on 7/23/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@interface CAMultiAudioFile : CAMultiAudioNode
{
    AudioFileID _audioFile;
    Float64 _outputSampleRate;
    SInt64 _lastStartFrame;
    
    
}

@property (strong) NSString *filePath;
@property (assign) AudioStreamBasicDescription *outputFormat;
@property (weak) id converterNode;
@property (assign) Float64 duration;
@property (assign) Float64 currentTime;
@property (assign) bool playing;


-(instancetype)initWithPath:(NSString *)path;
-(void)play;
-(void)stop;
-(void)rewind;


@end
