//
//  FFMpegTask.h
//  H264Streamer
//
//  Created by Zakk on 9/4/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "libavformat/avformat.h"
#import "CapturedFrameData.h"
#import "CaptureController.h"
#import "libavutil/opt.h"




#define AUDIO_BUFFER_SIZE 1000



@interface FFMpegTask : NSObject
{
    AVFormatContext *_av_fmt_ctx;
    AVStream *_av_video_stream;
    AVStream *_av_audio_stream;
    
    char *_audio_extradata;
    size_t _audio_extradata_size;
    
    int _input_framecnt;
    int _pending_frame_count;
    int _pending_frame_size;
    int _consecutive_dropped_frames;
    int _dropped_frames;

    NSMutableArray *_frameQueue;
    dispatch_semaphore_t _frameSemaphore;
    dispatch_queue_t _frameConsumerQueue;
    bool _close_flag;
    
    

}



-(BOOL) writeVideoSampleBuffer:(CapturedFrameData *)frameData;
-(BOOL) writeAudioSampleBuffer:(CMSampleBufferRef)theBuffer presentationTimeStamp:(CMTime)pts;
-(BOOL) writeAVPacket:(CapturedFrameData *)frameData;
-(BOOL) writeEncodedData:(CapturedFrameData *)frameData;
-(void) updateOutputStats;
-(void) updateInputStats;
-(void)clearFrameQueue;
-(bool)queueFramedata:(CapturedFrameData *)frameData;
-(NSUInteger)frameQueueSize;
-(void) initStatsValues;






-(bool) stopProcess;
-(NSString *) av_error_nsstring:(int)av_err_num;



@property (assign) int output_framecnt;
@property (assign) int output_bytes;

@property (assign) BOOL init_done;
@property (strong) NSString *stream_output;
@property (strong) NSString *stream_format;
@property (assign) int framerate;
@property (assign) int width;
@property (assign) int height;
@property (assign) int samplerate;
@property (assign) int audio_bitrate;
@property (readonly) NSUInteger buffered_frame_count;
@property (assign) NSUInteger buffered_frame_size;
@property (assign) NSUInteger dropped_frame_count;
@property (assign) BOOL errored;
@property (assign) enum AVCodecID video_codec_id;







@end
