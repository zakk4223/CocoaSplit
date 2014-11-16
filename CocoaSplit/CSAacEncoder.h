//
//  CSAacEncoder.h
//  CocoaSplit
//
//  Created by Zakk on 11/9/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@class CaptureController;


@interface CSAacEncoder : NSObject
{
    dispatch_queue_t encoderQueue;
    AudioCodec aacCodec;
    Float32 *PCMleftover;
    size_t leftover_size;
    UInt32 maxOutputSize;
    char *magicCookie;
    int *magicCookieSize;
    
    AVAudioFormat *outputFormat;
    long outputSampleCount;
    CMAudioFormatDescriptionRef cmFormat;    
}

@property (assign) bool encoderStarted;
@property (weak) CaptureController *encodedReceiver;
@property (assign) int sampleRate;
@property (assign) int bitRate;

-(void) enqueuePCM:(AVAudioPCMBuffer *)pcmBuffer atTime:(AVAudioTime *)atTime;
-(void) startEncoder;
-(void) stopEncoder;



@end


