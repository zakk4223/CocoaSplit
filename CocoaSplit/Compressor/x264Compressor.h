//
//  x264Compressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libswscale/swscale.h"
#import <CoreVideo/CoreVideo.h>
#import "VideoCompressor.h"
#import "CaptureController.h"
#import <VideoToolbox/VideoToolbox.h>
#import "CapturedFrameData.h"
#import "CompressorBase.h"
#import "CSPluginServices.h"
#import "x264.h"





@interface x264Compressor : CompressorBase
{
    
    
    AVCodec *_av_codec;
    AVCodecContext *_av_codec_ctx;
    struct SwsContext *_sws_ctx;
    dispatch_queue_t _compressor_queue;
    VTPixelTransferSessionRef _vtpt_ref;
    double _next_keyframe_time;
    int64_t _last_pts;
    bool _reset_flag;
    dispatch_queue_t _consumerThread;
    NSMutableArray *_compressQueue;
    dispatch_semaphore_t _queueSemaphore;
    CFMutableDictionaryRef _formatExtensions;
    
    
    
    
}


@property (strong) NSMutableArray *x264tunes;
@property (strong) NSMutableArray *x264presets;
@property (strong) NSMutableArray *x264profiles;




@property (strong) NSString *preset;
@property (strong) NSString *tune;
@property (strong) NSString *profile;
@property (assign) int vbv_maxrate;
@property (assign) int vbv_buffer;
@property (assign) int keyframe_interval;
@property (assign) int crf;
@property (assign) bool use_cbr;
@property (strong) NSString *advancedSettings;





-(bool)compressFrame:(CapturedFrameData *)frameData;
-(bool)setupCompressor:(CVPixelBufferRef)videoFrame;


@end
