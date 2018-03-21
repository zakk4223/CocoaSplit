//
//  CSAacEncoder.h
//  CocoaSplit
//
//  Created by Zakk on 11/9/14.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "TPCircularBuffer.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "CSEncodedAudioReceiverProtocol.h"


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
    u_int64_t _last_sample_time;
    int _last_write_sample_cnt;
    TPCircularBuffer _inputBuffer;
    TPCircularBuffer _scratchBuffer;
    dispatch_source_t _dispatch_timer;
    dispatch_semaphore_t _aSemaphore;
    CMFormatDescriptionRef _pcmFormat;
    
    
}

@property (assign) bool encoderStarted;
@property (weak) NSObject<CSEncodedAudioReceiverProtocol> *encodedReceiver;
@property (assign) int sampleRate;
@property (assign) int bitRate;
@property (assign) int preallocatedBuffersize;
@property (assign) AudioStreamBasicDescription *inputASBD;
@property (assign) bool skipCompression;

-(void) enqueuePCM:(AudioBufferList *)pcmBuffer atTime:(const AudioTimeStamp *)atTime;
-(void) setupEncoderBuffer;

-(void) stopEncoder;
-(void *)inputBufferPtr;



@end


