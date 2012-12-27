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


#define AUDIO_BUFFER_SIZE 1000
@interface FFMpegTask : NSObject
{
    
    
   
    
    dispatch_queue_t _stream_dispatch;
    
    AVFormatContext *_av_fmt_ctx;
    AVStream *_av_video_stream;
    AVStream *_av_audio_stream;
    
    char *_audio_extradata;
    size_t _audio_extradata_size;
    
}


-(void) writeVideoSampleBuffer:(CMSampleBufferRef)theBuffer;
-(void) writeAudioSampleBuffer:(CMSampleBufferRef)theBuffer presentationTimeStamp:(CMTime)pts;


-(bool) stopProcess;
-(bool) restartProcess;

@property (strong) NSString *stream_output;
@property (strong) NSString *stream_format;
@property (assign) int framerate;
@property (assign) int width;
@property (assign) int height;
@property (assign) int samplerate;




@end
