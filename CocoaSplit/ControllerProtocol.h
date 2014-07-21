//
//  ControllerProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "CapturedFrameData.h"
#import <AppKit/AppKit.h>
#import "h264Compressor.h"
#import "InputSource.h"


@protocol ControllerProtocol <NSObject>


@property int captureWidth;
@property int captureHeight;
@property (readonly) double captureFPS;
@property (readonly) int audioBitrate;
@property (readonly) int audioSamplerate;
@property (assign) BOOL captureRunning;

@property int captureVideoMaxKeyframeInterval;
@property int captureVideoMaxBitrate;
@property int captureVideoAverageBitrate;
@property NSString *x264preset;
@property NSString *x264profile;
@property NSString *x264tune;
@property NSString *vtcompressor_profile;
@property int x264crf;
@property BOOL videoCBR;
@property (assign) int maxOutputPending;
@property (assign) int maxOutputDropped;
@property NSString *imageDirectory;
@property (strong) id <h264Compressor> selectedCompressor;
@property (strong) NSMutableDictionary *compressors;


-(void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)newFrame;
-(void)setExtraData:(id)saveData forKey:(NSString *)forKey;
-(id)getExtraData:(NSString *)forkey;
-(CVPixelBufferRef)currentFrame;
-(double)mach_time_seconds;
-(NSColor *)statusColor;




- (void) outputEncodedData:(CapturedFrameData *)frameData;








@end
