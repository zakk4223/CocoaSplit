//
//  CommandLineController.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OutputDestination.h"
#import "ControllerProtocol.h"

@interface CommandLineController : NSObject <ControllerProtocol>


@property (assign) int captureWidth;
@property (assign) int captureHeight;
@property (assign) int captureFPS;
@property (assign) int captureVideoMaxKeyframeInterval;
@property (assign) int captureVideoMaxBitrate;
@property (assign) int captureVideoAverageBitrate;
@property NSString *x264preset;
@property NSString *x264profile;
@property NSString *x264tune;
@property (assign) int x264crf;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;



- (bool) initWithArgs:(NSUserDefaults *)args;

- (void) outputAVPacket:(AVPacket *)avpkt codec_ctx:(AVCodecContext *)codec_ctx;
- (void)captureOutputVideo:(AbstractCaptureDevice *)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t)frameTime;
- (void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void) outputSampleBuffer:(CMSampleBufferRef)theBuffer;





-(bool) setupWithArgs:(NSUserDefaults *)args;
@end
