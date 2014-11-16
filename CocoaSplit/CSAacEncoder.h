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
    UInt32 maxOutputSize;
    char *magicCookie;
    int *magicCookieSize;
    
    long outputSampleCount;
    CMAudioFormatDescriptionRef cmFormat;
    void *_pcmData;
}

@property (assign) bool encoderStarted;
@property (weak) CaptureController *encodedReceiver;
@property (assign) int sampleRate;
@property (assign) int bitRate;
@property (assign) int preallocatedBuffersize;

-(void) enqueuePCM:(AudioBufferList *)pcmBuffer atTime:(const AudioTimeStamp *)atTime;
-(void) startEncoder;
-(void) stopEncoder;



@end


