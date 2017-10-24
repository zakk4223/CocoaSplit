//
//  CSFFMpegInput.h
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>

#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libavutil/threadmessage.h"
#import "libavutil/fifo.h"

#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/samplefmt.h"

#import "CAMultiAudioPCM.h"
#import "CSPcmPlayer.h"





struct frame_message {

    AVFrame *frame;
    int notused;
};


@interface CSFFMpegInput : NSObject
{
    int _video_stream_idx;
    int _audio_stream_idx;
    struct SwsContext *_sws_ctx;
    struct SwrContext *_swr_ctx;
    uint64_t _seek_time;
    bool _seek_request;
    bool _stop_request;
    bool _seen_audio_pkt;
    bool _seen_video_pkt;
    dispatch_semaphore_t _read_loop_semaphore;
    dispatch_queue_t _read_thread;
    
    dispatch_queue_t _seek_queue;
    AVFrame *_first_frame;
    
    
    
}


-(instancetype) initWithMediaPath:(NSString *)mediaPath;
-(bool)openMedia:(int)bufferVideoFrames;
-(void)readAndDecodeVideoFrames:(int)frameCnt;
-(void)stop;
-(void)start;
-(AVFrame *)firstVideoFrame;






@property (strong) NSString *mediaPath;
@property (assign) bool is_ready;
@property (assign) bool is_draining;
@property (assign) AVRational videoTimeBase;
@property (assign) AVRational audioTimeBase;
@property (strong) CSPcmPlayer *pcmPlayer;
@property (assign) bool stopped;
@property (assign) bool paused;
@property (assign) AVThreadMessageQueue *video_message_queue;
@property (assign) AVThreadMessageQueue *audio_message_queue;
@property (assign) AVFormatContext *format_ctx;

@property (assign) AVCodecContext *video_codec_ctx;
@property (assign) AVCodec *video_codec;

@property (assign) AVCodecContext *audio_codec_ctx;
@property (assign) AVCodec *audio_codec;


@property (nonatomic, copy) void (^completionCallback)(void);
@property (assign) int64_t first_video_pts;
@property (assign) int64_t first_audio_pts;


@property (assign) NSSize dimensions;
@property (assign) double duration;

@property (strong) NSString *shortName;


-(AVFrame *)consumeFrame:(int *)error_out;
-(CAMultiAudioPCM *)consumeAudioFrame:(AudioStreamBasicDescription *)asbd error_out:(int *)error_out;
-(void) closeMedia;
-(void) seek:(double)time;









@end
