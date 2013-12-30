//
//  ControllerProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "AbstractCaptureDevice.h"

@protocol ControllerProtocol <NSObject>


@property int captureWidth;
@property int captureHeight;
@property (readonly) double captureFPS;
@property int captureVideoMaxKeyframeInterval;
@property int captureVideoMaxBitrate;
@property int captureVideoAverageBitrate;
@property NSString *x264preset;
@property NSString *x264profile;
@property NSString *x264tune;
@property NSString *vtcompressor_profile;
@property int x264crf;
@property int audioBitrate;
@property int audioSamplerate;
@property BOOL videoCBR;
@property (assign) int maxOutputPending;
@property (assign) int maxOutputDropped;
@property NSString *imageDirectory;



- (void) outputAVPacket:(AVPacket *)avpkt codec_ctx:(AVCodecContext *)codec_ctx;
- (void)captureOutputVideo:(AbstractCaptureDevice *)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t)frameTime;
- (void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void) outputSampleBuffer:(CMSampleBufferRef)theBuffer;
-(void)newFrame;
-(void)setExtraData:(id)saveData forKey:(NSString *)forKey;
-(id)getExtraData:(NSString *)forkey;









@end
