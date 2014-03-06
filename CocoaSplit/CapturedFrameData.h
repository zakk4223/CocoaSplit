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

@property CVImageBufferRef videoFrame;

//Array of CMSampleBuffers from audio capture.
@property (retain) NSMutableArray *audioSamples;


@property CMTime videoPTS;
@property CMTime videoDuration;
@property CMSampleBufferRef encodedSampleBuffer;

@property AVPacket *avcodec_pkt;
@property AVCodecContext *avcodec_ctx;

@end