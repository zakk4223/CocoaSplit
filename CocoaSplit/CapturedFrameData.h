//
//  CapturedFrameData.h
//  CocoaSplit
//
//  Created by Zakk on 12/3/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"


@interface CapturedFrameData : NSObject



@property long long frameNumber;
@property (assign) double frameTime;

@property CVImageBufferRef videoFrame;
@property (assign) void *encoderData;
@property (assign) BOOL isKeyFrame;


//Array of CMSampleBuffers from audio capture.
@property (retain) NSMutableArray *audioSamples;


@property CMTime videoPTS;
@property CMTime videoDuration;
@property CMSampleBufferRef encodedSampleBuffer;

@property (assign) AVPacket *avcodec_pkt;
@property AVCodecContext *avcodec_ctx;


-(NSInteger) encodedDataLength;

@end