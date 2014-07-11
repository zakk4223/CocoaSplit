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
#import "ControllerProtocol.h"

#define AUDIO_BUFFER_SIZE 1000
@interface FFMpegTask : NSObject
{
    
    
   
    
    dispatch_queue_t _stream_dispatch;
    
    AVFormatContext *_av_fmt_ctx;
    AVStream *_av_video_stream;
    AVStream *_av_audio_stream;
    
    char *_audio_extradata;
    size_t _audio_extradata_size;
    
    CFAbsoluteTime _input_frame_timestamp;
    CFAbsoluteTime _output_frame_timestamp;
    int _input_framecnt;
    int _output_framecnt;
    int _output_bytes;
    int _pending_frame_count;
    int _pending_frame_size;
    int _consecutive_dropped_frames;
    int _dropped_frames;

}


-(void) writeVideoSampleBuffer:(CapturedFrameData *)frameData;
-(void) writeAudioSampleBuffer:(CMSampleBufferRef)theBuffer presentationTimeStamp:(CMTime)pts;
-(void) writeAVPacket:(CapturedFrameData *)frameData;
-(void) writeEncodedData:(CapturedFrameData *)frameData;
-(void) updateOutputStats;
-(void) updateInputStats;




-(bool) stopProcess;
-(NSString *) av_error_nsstring:(int)av_err_num;




@property (assign) BOOL init_done;
@property (assign) BOOL active;
@property (strong) NSString *stream_output;
@property (strong) NSString *stream_format;
@property (assign) int framerate;
@property (assign) int width;
@property (assign) int height;
@property (assign) int samplerate;
@property (assign) int audio_bitrate;
@property (assign) int buffered_frame_count;
@property (assign) int buffered_frame_size;
@property (assign) double output_framerate;
@property (assign) double input_framerate;
@property (assign) double output_bitrate;
@property (assign) int dropped_frame_count;
@property (assign) BOOL errored;


@property (strong) id<ControllerProtocol> settingsController;




@end
