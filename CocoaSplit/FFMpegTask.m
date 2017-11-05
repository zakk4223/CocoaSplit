//
//  FFMpegTask.m
//  H264Streamer
//
//  Created by Zakk on 9/4/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "FFMpegTask.h"
#import <sys/types.h>
#import <sys/stat.h>

#import <stdio.h>

@implementation FFMpegTask


#include "libavformat/avformat.h"

-(void)dealloc
{
    NSLog(@"DEALLOC FFMPEG");
}

-(NSUInteger)frameQueueSize
{
    NSUInteger ret = 0;
    @synchronized (self) {
        ret = _frameQueue.count;
    }
    
    return ret;
}


-(void)clearFrameQueue
{
    @synchronized (self) {
        [_frameQueue removeAllObjects];
        self.buffered_frame_size = 0;
    }
}


-(CapturedFrameData *)consumeframeData
{
    CapturedFrameData *retData = nil;
    
    @synchronized (self) {
        if (_frameQueue.count > 0)
        {
            retData = [_frameQueue objectAtIndex:0];
            [_frameQueue removeObjectAtIndex:0];
            _buffered_frame_size -= [retData encodedDataLength];
        }
    }
    
    return retData;
}


-(void)startConsumerThread
{
    if (!_frameConsumerQueue)
    {
        _frameConsumerQueue = dispatch_queue_create("FFMpeg consumer", DISPATCH_QUEUE_SERIAL);
        
        dispatch_async(_frameConsumerQueue, ^{
            
            while (1)
            {
                @autoreleasepool {
                    
                    @synchronized (self) {
                        if (_close_flag)
                        {
                            [self _internal_stopProcess];
                            break;
                        }
                    }
                    
                    CapturedFrameData *useData = [self consumeframeData];
                    if (!useData)
                    {
                        dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
                    } else {
                        [self writeEncodedData:useData];
                    }
                }
            }
            
        });
    }
}


-(bool)queueFramedata:(CapturedFrameData *)frameData
{
    if (!_frameConsumerQueue)
    {
        [self startConsumerThread];
    }
    
    @synchronized (self) {
        [_frameQueue addObject:frameData];
        _buffered_frame_size += [frameData encodedDataLength];
        dispatch_semaphore_signal(_frameSemaphore);
    }
    return YES;
}



int readAudioTagLength(char **buffer)
{
    int length = 0;
    int cnt =4;
    
    while(cnt--)
    {
        int c = *(*buffer)++;
        
        length = (length << 7) | (c & 0x7f);
        if (!(c & 0x80))
            break;
    }
    return length;
}


-(NSUInteger)buffered_frame_count
{
    return [self frameQueueSize];
}


int readAudioTag(char **buffer, int *tag)
{
    
    *tag = *(*buffer)++;
    return readAudioTagLength(buffer);
    
}



void getAudioExtradata(char *cookie, char **buffer, size_t *size)
{
    char *esds = cookie;
    
    int tag, length;
    
    *size = 0;
    
    readAudioTag(&esds, &tag);
    esds += 2;
    if (tag == 0x03)
        esds++;
    
    readAudioTag(&esds, &tag);
    
    
    if (tag == 0x04) {
        esds++;
        esds++;
        esds += 3;
        esds += 4;
        esds += 4;
        
        length = readAudioTag(&esds, &tag);
        if (tag == 0x05)
        {
            *buffer = calloc(1, length + 8);
            if (*buffer)
            {
                memcpy(*buffer, esds, length);
                *size = length;
                
            }
            
        }
    }
}




-(void) extractAudioCookie:(CMSampleBufferRef)theBuffer
{
    CMAudioFormatDescriptionRef audio_fmt;
    
    
    audio_fmt = CMSampleBufferGetFormatDescription(theBuffer);
    if (!audio_fmt)
    {
        return;
    }
    
    void *audio_tmp;
    audio_tmp = (char *)CMAudioFormatDescriptionGetMagicCookie(audio_fmt, &_audio_extradata_size);
    if (audio_tmp)
    {
        getAudioExtradata(audio_tmp, &_audio_extradata, &_audio_extradata_size);
    }
    
}


-(BOOL) writeEncodedData:(CapturedFrameData *)frameDataIn
{
    
    
    CapturedFrameData *frameData = frameDataIn;
    
    if (!_audio_extradata && [frameData.audioSamples count] > 0)
    {
        
        CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)[frameData.audioSamples objectAtIndex:0];
        [self extractAudioCookie:audioSample];
    }
    
    if (!_av_video_stream && _audio_extradata)
    {
        
        if ([self createAVFormatOut:frameData.encodedSampleBuffer codec_ctx:frameData.avcodec_ctx])
        {
            [self initStatsValues];
        } else {
            return NO;
        }
    }
    
    if (!_av_video_stream || !_av_audio_stream)
    {
        //This is a lie. We probably have only received video frames and are waiting for audio. Just pretend we did something.
        return YES;
    }
    
    
    //If we made it here, we have all the metadata and av* stuff created, so start sending data.
    
    for (id object in frameData.audioSamples)
    {
        CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)object;
        
        
        [self writeAudioSampleBuffer:audioSample presentationTimeStamp:CMSampleBufferGetOutputPresentationTimeStamp(audioSample)];
        
        //CFRelease(audioSample);
    }
    
    BOOL  ret_status = YES;
    
    if (frameData.encodedSampleBuffer)
    {
        
        ret_status = [self writeVideoSampleBuffer:frameData];
    } else if (frameData.avcodec_pkt) {
        ret_status = [self writeAVPacket:frameData];
    }
    
    return ret_status;
}

-(BOOL) writeAudioSampleBuffer:(CMSampleBufferRef)theBuffer presentationTimeStamp:(CMTime)pts
{
    
    
    CFRetain(theBuffer);

    BOOL ret_val = YES;

    if (_av_audio_stream && (self.init_done == YES))
    {
        
            CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(theBuffer);
            size_t buffer_length;
            size_t offset_length;
            char *sampledata;
        
            AVPacket pkt;
        
            av_init_packet(&pkt);
        
        
            pkt.stream_index = _av_audio_stream->index;
        
            CMBlockBufferGetDataPointer(blockBufferRef, 0, &offset_length, &buffer_length, &sampledata);
        
        
        
            pkt.data = (uint8_t *)sampledata;
        
            pkt.size = (int)buffer_length;
            //pkt.destruct = NULL;
            
            
            
            pkt.pts = av_rescale_q(pts.value, (AVRational) {1.0, pts.timescale}, _av_audio_stream->time_base);


        
        
            
            if (av_interleaved_write_frame(_av_fmt_ctx, &pkt) < 0)
            {
                ret_val = NO;
                //[self stopProcess];
            }
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                CFRelease(theBuffer);
            //});
    }
    
    return ret_val;
}

-(void) setVideoFormatOptions:(AVFormatContext *)ctx
{
    
    
    ctx->avoid_negative_ts = AVFMT_AVOID_NEG_TS_MAKE_ZERO;
    
    
    AVOutputFormat *ofmt = ctx->oformat;
    
    if (!ofmt)
    {
        return;
    }
    
    const char *fmt_name = ofmt->name;
    
    if (!strcasecmp(fmt_name, "mmmmmov"))
    {
        av_opt_set_int(ctx->priv_data, "frag_duration", 10000000, 0);
    } else if (!strcasecmp(fmt_name, "segment")) {
        av_opt_set(ctx->priv_data, "reset_timestamps", "1", AV_OPT_SEARCH_CHILDREN);
    }
}


-(bool) createAVFormatOut:(CMSampleBufferRef)theBuffer codec_ctx:(AVCodecContext *)codec_ctx
{
 
    NSLog(@"Creating output format %@ DESTINATION %@", _stream_format, _stream_output);
    AVOutputFormat *av_out_fmt;
    
    int avErr = 0;
    
    if (_stream_format) {
        avErr = avformat_alloc_output_context2(&_av_fmt_ctx, NULL, [_stream_format UTF8String], [_stream_output UTF8String]);
    } else {
        avErr = avformat_alloc_output_context2(&_av_fmt_ctx, NULL, NULL, [_stream_output UTF8String]);
    }
    
    NSLog(@"AV ERR %d", avErr);
    
    if (!_av_fmt_ctx)
    {
        NSLog(@"NO FMT CTX");
        return NO;
    }
    
    
    [self setVideoFormatOptions:_av_fmt_ctx];
    
    av_out_fmt = _av_fmt_ctx->oformat;
    
    _av_video_stream = avformat_new_stream(_av_fmt_ctx, 0);
    
    if (!_av_video_stream)
    {
        NSLog(@"VIDEO STREAM SETUP FAIL");
        return NO;
    }
    
    
    AVCodecContext *c_ctx = _av_video_stream->codec;
    
    
    //c_ctx->codec_type = AVMEDIA_TYPE_VIDEO;
    //c_ctx->codec_id = self.video_codec_id;
    /*
    _av_video_stream->time_base.num = 1000000;
    _av_video_stream->time_base.den = self.framerate*1000000;
    */
    
    //_av_video_stream->time_base.num = 1;
    //_av_video_stream->time_base.den = 1000;
    
    

    
    
    _av_audio_stream = avformat_new_stream(_av_fmt_ctx, 0);
    
    if (!_av_audio_stream)
    {
        return NO;
    }
    
    AVCodecContext *a_ctx = _av_audio_stream->codec;
    
    
    a_ctx->codec_type = AVMEDIA_TYPE_AUDIO;
    a_ctx->codec_id = AV_CODEC_ID_AAC;
    
    /*_av_audio_stream->time_base.num = 100000;
    _av_audio_stream->time_base.den = self.framerate*100000;
     */
    
    _av_audio_stream->time_base.num = 1;
    _av_audio_stream->time_base.den = _samplerate;
    
    a_ctx->sample_rate = _samplerate;
    a_ctx->bit_rate = _audio_bitrate;
    a_ctx->channels = 2;
    a_ctx->extradata = (unsigned char *)_audio_extradata;
    a_ctx->extradata_size = (int)_audio_extradata_size;
    a_ctx->frame_size = 1024;
    
    //a_ctx->frame_size = (_samplerate * 2 * 2) / _framerate;
    
    if (theBuffer)
    {
        CMFormatDescriptionRef fmt;
        CFDictionaryRef atoms;
        CFStringRef avccKey;
        CFDataRef avcc_data;
        CFIndex avcc_size;
        
        CMVideoDimensions avc_dimensions;
        
        fmt = CMSampleBufferGetFormatDescription(theBuffer);
        avc_dimensions = CMVideoFormatDescriptionGetDimensions(fmt);
        self.width = avc_dimensions.width;
        self.height = avc_dimensions.height;
        
        atoms = CMFormatDescriptionGetExtension(fmt, kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms);
        avccKey = CFSTR("avcC");
        if (atoms)
        {
            avcc_data = CFDictionaryGetValue(atoms, avccKey);
            avcc_size = CFDataGetLength(avcc_data);
            c_ctx->extradata = malloc(avcc_size);
    
            CFDataGetBytes(avcc_data, CFRangeMake(0,avcc_size), c_ctx->extradata);
    
            c_ctx->extradata_size = (int)avcc_size;
        }
        c_ctx->codec_type = AVMEDIA_TYPE_VIDEO;
        c_ctx->codec_id = self.video_codec_id;

    } else if (codec_ctx) {
        
        avcodec_copy_context(_av_video_stream->codec, codec_ctx);
        _av_video_stream->time_base = av_add_q(codec_ctx->time_base, (AVRational){0,1});
        _av_video_stream->codec->codec = codec_ctx->codec;
        
        self.width = codec_ctx->width;
        self.height = codec_ctx->height;
        
        c_ctx->extradata_size = codec_ctx->extradata_size;
        c_ctx->extradata = malloc(c_ctx->extradata_size);
        memcpy(c_ctx->extradata, codec_ctx->extradata, c_ctx->extradata_size);

    }
    if (_av_fmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
        c_ctx->flags |= CODEC_FLAG_GLOBAL_HEADER;
    
    if (_av_fmt_ctx->oformat->flags & AVFMT_GLOBALHEADER)
        a_ctx->flags |= CODEC_FLAG_GLOBAL_HEADER;


    c_ctx->width = self.width;
    c_ctx->height = self.height;

    
    av_dump_format(_av_fmt_ctx, 0, [_stream_output UTF8String], 1);
    
    if (!(av_out_fmt->flags & AVFMT_NOFILE))
    {
        int av_err;
        if ((av_err = avio_open(&_av_fmt_ctx->pb, [_stream_output UTF8String], AVIO_FLAG_WRITE)) < 0)
        {
            NSString *open_err = [self av_error_nsstring:av_err ];

            
            NSLog(@"AVIO_OPEN failed REASON %@", open_err);
            _av_fmt_ctx->pb = NULL;
            self.errored = YES;
            [self stopProcess];
            return NO;
        }
    }
        if (_av_fmt_ctx == NULL || avformat_write_header(_av_fmt_ctx, NULL) < 0)
    {
 
        NSLog(@"AVFORMAT_WRITE_HEADER failed");
        self.errored = YES;
        [self stopProcess];
        return NO;
    }
    
    self.init_done = YES;
    return YES;
}


-(void) updateInputStats
{

    self.dropped_frame_count = _dropped_frames;
}


-(void) updateOutputStats
{
    
    _output_framecnt = 0;
    _output_bytes = 0;
}


-(void) initStatsValues
{
    _output_framecnt = 0;
    _output_bytes = 0;
    _buffered_frame_size = 0;
}


-(BOOL) writeAVPacket:(CapturedFrameData *)frameData
{
    
    
    AVPacket *pkt = frameData.avcodec_pkt;
    
    AVPacket *p = av_malloc(sizeof (AVPacket));

    av_init_packet(p);
    
    av_packet_ref(p, pkt);
    
    av_packet_rescale_ts(p, frameData.avcodec_ctx->time_base, _av_video_stream->time_base);

    /*
    if (p->pts != AV_NOPTS_VALUE)
    {
        
        p->pts = av_rescale_q(p->pts, frameData.avcodec_ctx->time_base, _av_video_stream->time_base);
    }
    
    if (p->dts != AV_NOPTS_VALUE)
    {
        p->dts = av_rescale_q(p->dts, frameData.avcodec_ctx->time_base, _av_video_stream->time_base);
    }*/
    
    
    
    
    
    p->stream_index = _av_video_stream->index;
    
    /* Write the compressed frame to the media file. */
    BOOL write_status = YES;
    if (av_interleaved_write_frame(_av_fmt_ctx, p) < 0)
    {
        
        //NSLog(@"INTERLEAVED WRITE FRAME FAILED FOR %@ frame number %lld", self.stream_output, frameData.frameNumber);
        write_status = NO;
    } else {
        _output_framecnt++;
        _output_bytes += [frameData encodedDataLength];

    }
    av_packet_unref(p);
    av_free(p);
    
    return write_status;
}


-(BOOL) writeVideoSampleBuffer:(CapturedFrameData *)frameData
{
    
    if (!frameData || !frameData.encodedSampleBuffer)
    {
        return NO;
    }
    
    CFRetain(frameData.encodedSampleBuffer);
    
    
    
    
    CMSampleBufferRef theBuffer = frameData.encodedSampleBuffer;
    CMBlockBufferRef my_buffer;
    char *sampledata;
    size_t offset_length;
    size_t buffer_length;
    
    my_buffer = CMSampleBufferGetDataBuffer(theBuffer);
    
    
    AVPacket pkt;
    
    av_init_packet(&pkt);
    
    
    pkt.stream_index = _av_video_stream->index;
    
    CMBlockBufferGetDataPointer(my_buffer, 0, &offset_length, &buffer_length, &sampledata);
    
    pkt.data = (uint8_t *)sampledata;
    
    pkt.size = (int)buffer_length;
  
        
        
    pkt.dts = av_rescale_q(CMSampleBufferGetDecodeTimeStamp(theBuffer).value, (AVRational) {1.0, CMSampleBufferGetDecodeTimeStamp(theBuffer).
                timescale}, _av_video_stream->time_base);
        
    pkt.pts = av_rescale_q(CMSampleBufferGetPresentationTimeStamp(theBuffer).value, (AVRational) {1.0, CMSampleBufferGetPresentationTimeStamp(theBuffer).timescale}, _av_video_stream->time_base);

    if (frameData.isKeyFrame)
    {
        pkt.flags |= AV_PKT_FLAG_KEY;
    }
    
    

    BOOL send_status = YES;
    
    if (av_interleaved_write_frame(_av_fmt_ctx, &pkt) < 0)
    {
        NSLog(@"VIDEO WRITE FRAME failed for %@", self.stream_output);
        send_status = NO;
        //[self stopProcess];
    } else {
        _output_framecnt++;
        _output_bytes += [frameData encodedDataLength];
    }

    CFRelease(theBuffer);
        
    return send_status;
        
  }





-(id)init
{
    
    self = [super init];
    self.init_done = NO;
    self.errored = NO;
    _close_flag = NO;
    
    _frameQueue = [NSMutableArray arrayWithCapacity:1000];
    _frameSemaphore = dispatch_semaphore_create(0);
    _pending_frame_size = 0;
    _output_bytes = 0;
    _output_framecnt = 0;
    
    av_register_all();
    avformat_network_init();
    return self;
    
}


-(bool)stopProcess
{
    
    @synchronized (self) {
        _close_flag = YES;
        dispatch_semaphore_signal(_frameSemaphore);
    }
    
    //[self _internal_stopProcess];
    return YES;
}



-(bool)_internal_stopProcess
{
    
    if (_av_fmt_ctx)
    {
        if (_av_fmt_ctx->pb && !self.errored)
        {
            av_write_trailer(_av_fmt_ctx);
        }
        
        avio_close(_av_fmt_ctx->pb);
        avformat_free_context(_av_fmt_ctx);
        
    }
    
    _av_fmt_ctx = NULL;
    _av_video_stream = NULL;
    _av_audio_stream = NULL;
    
    if (_audio_extradata)
    {
        //free(_audio_extradata);
        _audio_extradata = NULL;
    }
    return YES;
        
}

-(NSString *) av_error_nsstring:(int)av_err_num
{
    NSString *errstr = nil;
    
    
    char *av_err_str;
    
    av_err_str = malloc(AV_ERROR_MAX_STRING_SIZE);
    
    if (av_strerror(av_err_num, av_err_str, AV_ERROR_MAX_STRING_SIZE) < 0)
    {
        free(av_err_str);
        errstr = nil;
    } else {
        errstr = [[NSString alloc] initWithBytesNoCopy:av_err_str length:AV_ERROR_MAX_STRING_SIZE encoding:NSASCIIStringEncoding freeWhenDone:YES];
    }
    
    return errstr;
}


@end
