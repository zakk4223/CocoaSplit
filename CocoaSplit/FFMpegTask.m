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


-(BOOL) resetOutputIfNeeded
{
    //Should probably only do this if we're a network based output
    if (self.settingsController.maxOutputDropped)
    {
        if (_consecutive_dropped_frames >= self.settingsController.maxOutputDropped)
        {
            self.errored = YES;
            [self stopProcess];
            return YES;
        }
    }
    return NO;
}



-(BOOL) shouldDropFrame
{

    if (self.settingsController.maxOutputPending)
    {
        if (_pending_frame_count >= self.settingsController.maxOutputPending)
        {
            return YES;
        }
    }
    
    return NO;
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


-(void) writeEncodedData:(CapturedFrameData *)frameData
{
    
    if (!self.active)
    {
        return;
    }
    
    
    if (!_audio_extradata && [frameData.audioSamples count] > 0)
    {
        
        CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)[frameData.audioSamples objectAtIndex:0];
        
        [self extractAudioCookie:audioSample];
    }
    
    if (!_stream_dispatch)
    {
        _stream_dispatch = dispatch_queue_create("FFMpeg Stream Dispatch", NULL);
        _pending_frame_count = 0;
    }

    if (!_av_video_stream && _audio_extradata)
    {
        if ([self createAVFormatOut:frameData.encodedSampleBuffer codec_ctx:frameData.avcodec_ctx])
        {
            [self initStatsValues];
            
        } else {
            return;
        }
    }
    
    if (!_av_video_stream || !_av_audio_stream)
    {
        //!?
        return;
    }
    
    
    //If we made it here, we have all the metadata and av* stuff created, so start sending data.
    
    
    for (id object in frameData.audioSamples)
    {
        CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)object;
        
        if (CMSampleBufferGetNumSamples(audioSample) > 1)
        {
            NSLog(@"NUMBER OF SAMPLES IN FRAME %ld", CMSampleBufferGetNumSamples(audioSample));
            
        }
        
        
        [self writeAudioSampleBuffer:audioSample presentationTimeStamp:CMSampleBufferGetOutputPresentationTimeStamp(audioSample)];
        //CFRelease(audioSample);
    }
    
    if (frameData.encodedSampleBuffer)
    {
        
        [self writeVideoSampleBuffer:frameData.encodedSampleBuffer];
    } else if (frameData.avcodec_pkt) {
        [self writeAVPacket:frameData.avcodec_pkt codec_ctx:frameData.avcodec_ctx];
    }
    
}

-(void) writeAudioSampleBuffer:(CMSampleBufferRef)theBuffer presentationTimeStamp:(CMTime)pts;
{
    
    
    if ([self shouldDropFrame])
    {
        return;
    }

    CFRetain(theBuffer);


    if (_av_audio_stream && (self.init_done == YES))
    {
        dispatch_async(_stream_dispatch, ^{
            if (!self.active)
            {
                return;
            }
        
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
            pkt.destruct = NULL;
            
            
            //NSLog(@"FFMPEG AUDIO PTS %lld/%d", pts.value, pts.timescale);
            
            pkt.pts = av_rescale_q(pts.value, (AVRational) {1.0, pts.timescale}, _av_audio_stream->time_base);


            
            //pkt.dts = pkt.pts;
            
            
//            pkt.pts = pts.value;
            if (av_interleaved_write_frame(_av_fmt_ctx, &pkt) < 0)
            {
                NSLog(@"AV WRITE AUDIO failed");
                [self stopProcess];
            }
            //CMSampleBufferInvalidate(theBuffer);
            CFRelease(theBuffer);
        });
    /*} else if (!_audio_extradata) {
        
        CMAudioFormatDescriptionRef audio_fmt;
        audio_fmt = CMSampleBufferGetFormatDescription(theBuffer);
        void *audio_tmp;
        if (!audio_fmt)
            return;
        
        
        
        audio_tmp = (char *)CMAudioFormatDescriptionGetMagicCookie(audio_fmt, &_audio_extradata_size);
        
        if (audio_tmp)
        {
            getAudioExtradata(audio_tmp, &_audio_extradata, &_audio_extradata_size);
        }
     */
    }
}


-(bool) createAVFormatOut:(CMSampleBufferRef)theBuffer codec_ctx:(AVCodecContext *)codec_ctx
{
 
    NSLog(@"Creating output format %@ DESTINATION %@", _stream_format, _stream_output);
    AVOutputFormat *av_out_fmt;
    
    
    if (_stream_format) {
        avformat_alloc_output_context2(&_av_fmt_ctx, NULL, [_stream_format UTF8String], [_stream_output UTF8String]);
    } else {
        avformat_alloc_output_context2(&_av_fmt_ctx, NULL, NULL, [_stream_output UTF8String]);
    }
    
    if (!_av_fmt_ctx)
    {
        NSLog(@"No av_fmt_ctx");
        return NO;
    }
    
    
    av_out_fmt = _av_fmt_ctx->oformat;
    _av_video_stream = avformat_new_stream(_av_fmt_ctx, 0);
    
    if (!_av_video_stream)
    {
        NSLog(@"No av_video_stream");
        return NO;
    }
    
    
    AVCodecContext *c_ctx = _av_video_stream->codec;
    
    c_ctx->codec_type = AVMEDIA_TYPE_VIDEO;
    c_ctx->codec_id = AV_CODEC_ID_H264;
    c_ctx->time_base.num = 1000000;
    c_ctx->time_base.den = self.framerate*1000000;
    
    
    _av_audio_stream = avformat_new_stream(_av_fmt_ctx, 0);
    
    if (!_av_audio_stream)
    {
        NSLog(@"No av_audio_stream");
        return NO;
    }
    
    AVCodecContext *a_ctx = _av_audio_stream->codec;
    
    
    a_ctx->codec_type = AVMEDIA_TYPE_AUDIO;
    a_ctx->codec_id = AV_CODEC_ID_AAC;
    a_ctx->time_base.num = 1000000;
    a_ctx->time_base.den = self.framerate*1000000;
    a_ctx->sample_rate = _samplerate;
    a_ctx->bit_rate = _audio_bitrate;
    a_ctx->channels = 2;
    a_ctx->extradata = (unsigned char *)_audio_extradata;
    a_ctx->extradata_size = (int)_audio_extradata_size;
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
        NSLog(@"ATOMS %@", atoms);
        avcc_data = CFDictionaryGetValue(atoms, avccKey);
        avcc_size = CFDataGetLength(avcc_data);
        c_ctx->extradata = malloc(avcc_size);
    
        CFDataGetBytes(avcc_data, CFRangeMake(0,avcc_size), c_ctx->extradata);
    
        c_ctx->extradata_size = (int)avcc_size;
    } else if (codec_ctx) {
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
        NSLog(@"Doing AVIO_OPEN");
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
    }
    
    self.init_done = YES;
    return YES;
}


-(void) updateInputStats
{
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    double calculated_input_framerate = _input_framecnt / (time_now - _input_frame_timestamp);
    _input_framecnt = 0;
    _input_frame_timestamp = time_now;

    dispatch_async(dispatch_get_main_queue(), ^{
        
    
    
        self.input_framerate = calculated_input_framerate;
    self.buffered_frame_count = _pending_frame_count;
    self.buffered_frame_size = _pending_frame_size;
    self.dropped_frame_count = _dropped_frames;
    });
    
    
}

-(void) updateOutputStats
{
    
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    double calculated_output_framerate = _output_framecnt / (time_now - _output_frame_timestamp);
    double calculated_output_bitrate = (_output_bytes / (time_now - _output_frame_timestamp))*8;
    _output_framecnt = 0;
    _output_bytes = 0;
    _output_frame_timestamp = time_now;

    
    dispatch_async(dispatch_get_main_queue(), ^{
    
    
        self.output_framerate = calculated_output_framerate;
        self.output_bitrate = calculated_output_bitrate;
    });
    
}


-(void) initStatsValues
{
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    _input_framecnt = 0;
    _input_frame_timestamp = time_now;
    _output_framecnt = 0;
    _output_bytes = 0;
    _output_frame_timestamp = time_now;
}

-(void) writeAVPacket:(AVPacket *)pkt codec_ctx:(AVCodecContext *)codec_ctx
{
    
    
    if (!_stream_dispatch)
    {
        _stream_dispatch = dispatch_queue_create("FFMpeg Stream Dispatch", NULL);
        _pending_frame_count = 0;
    }

    
    _input_framecnt++;
    
    
    @synchronized(self)
    {
        _pending_frame_count++;
        _pending_frame_size += pkt->size;
    }

    
    if ((_input_framecnt % self.framerate) == 0)
    {
        [self updateInputStats];
    }

    
    if ([self shouldDropFrame])
    {
        _dropped_frames++;
        _consecutive_dropped_frames++;
        NSLog(@"SHOULD DROP FRAME");
        return;
    } else {
        _consecutive_dropped_frames = 0;
    }

    if ([self resetOutputIfNeeded])
    {
        NSLog(@"OUTPUT RESET");
        return;
    }
    
    

    
    
    
    AVPacket *p = av_malloc(sizeof (AVPacket));
    
    memcpy(p, pkt, sizeof(AVPacket));
    p->destruct = NULL;
    av_dup_packet(p);

    
    dispatch_async(_stream_dispatch, ^{
        
        if (!self.active)
        {
            NSLog(@"NOT ACTIVE");
            return;
        }
        
        /*
        if (!_av_video_stream)
        {
            if (_audio_extradata)
            {
                if (![self createAVFormatOut:nil codec_ctx:codec_ctx])
                {
                    
                    av_free_packet(p);
                    av_free(p);
                    NSLog(@"NO AVFORMAT OUT");
                    return;
                }
                [self initStatsValues];
            } else {
                @synchronized(self)
                {
                    _pending_frame_count--;
                    _pending_frame_size -= p->size;
                }
                NSLog(@"NO AUDIO EXTRA");
                return;
            }
        }
        
        */
         if (p->pts != AV_NOPTS_VALUE)
         {
             p->pts = av_rescale_q(p->pts, codec_ctx->time_base, _av_video_stream->time_base);
         }
         
         if (p->dts != AV_NOPTS_VALUE)
         {
             p->dts = av_rescale_q(p->dts, codec_ctx->time_base, _av_video_stream->time_base);
         }
         
        
        
        
        p->stream_index = _av_video_stream->index;
        
        int packet_size = p->size;
        /* Write the compressed frame to the media file. */
        if (av_interleaved_write_frame(_av_fmt_ctx, p) < 0)
        {
            NSLog(@"INTERLEAVED WRITE FRAME FAILED");
        }
        
        
        av_free_packet(p);
        av_free(p);
        _output_framecnt++;
        _output_bytes += packet_size;
        if ((_output_framecnt % self.framerate) == 0)
        {
            [self updateOutputStats];
        }
        
        @synchronized(self)
        {
            _pending_frame_count--;
            _pending_frame_size -= packet_size;
        }
    });
    
    
    
}

-(void) writeVideoSampleBuffer:(CMSampleBufferRef)theBuffer
{
    
    
    if (!theBuffer)
    {
        return;
    }
    
    /*
    if (!_stream_dispatch)
    {
        _stream_dispatch = dispatch_queue_create("FFMpeg Stream Dispatch", NULL);
        _pending_frame_count = 0;
    }
    
     */
    

    
    _input_framecnt++;
    if ((_input_framecnt % self.framerate) == 0)
    {
        [self updateInputStats];
    }

    
    if ([self shouldDropFrame])
    {
        _dropped_frames++;
        _consecutive_dropped_frames++;
        return;
    } else {
        _consecutive_dropped_frames = 0;
    }

    if ([self resetOutputIfNeeded])
    {
        return;
    }
    
    
    CFRetain(theBuffer);
    
    
    CMBlockBufferRef tmp_sample_data = CMSampleBufferGetDataBuffer(theBuffer);
    
    
    size_t data_length = CMBlockBufferGetDataLength(tmp_sample_data);
    
    
    @synchronized(self)
    {
        _pending_frame_count++;
        _pending_frame_size += data_length;
    }

    dispatch_async(_stream_dispatch, ^{
        
    if (!self.active)
    {
        return;
    }
        
       
        /*
    if (!_av_video_stream)
    {
        if (_audio_extradata)
        {
            if (![self createAVFormatOut:theBuffer codec_ctx:nil])
            {
                return;
            }
            [self initStatsValues];

        } else {
            @synchronized(self) { _pending_frame_count--; _pending_frame_size -= data_length;}
            return;
        }
    }
         */
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
  
        
        pkt.dts = av_rescale_q(CMSampleBufferGetDecodeTimeStamp(theBuffer).value, (AVRational) {1.0, CMSampleBufferGetDecodeTimeStamp(theBuffer).timescale}, _av_video_stream->time_base);        
        
    pkt.pts = av_rescale_q(CMSampleBufferGetPresentationTimeStamp(theBuffer).value, (AVRational) {1.0, CMSampleBufferGetPresentationTimeStamp(theBuffer).timescale}, _av_video_stream->time_base);

        
        
        
        

        //kt.pts = CMSampleBufferGetPresentationTimeStamp(theBuffer).value;
        

        
        
    if ([self isBufferKeyframe:theBuffer])
    {
        pkt.flags |= AV_PKT_FLAG_KEY;
    }
    
    
        
    if (av_interleaved_write_frame(_av_fmt_ctx, &pkt) < 0)
    {
        NSLog(@"VIDEO WRITE FRAME failed");
        //[self stopProcess];
    }
    
        _output_framecnt++;
        _output_bytes += pkt.size;
        if ((_output_framecnt % self.framerate) == 0)
        {
            [self updateOutputStats];
        }
        
    //CMSampleBufferInvalidate(theBuffer);
    CFRelease(theBuffer);
        
        @synchronized(self)
        {
            _pending_frame_count--;
            _pending_frame_size -= pkt.size;
        }
    });
    
    return;
        
  }


-(BOOL) isBufferKeyframe:(CMSampleBufferRef)theBuffer
{
    
    CFArrayRef sample_attachments;
    BOOL result = NO;
    
    sample_attachments = CMSampleBufferGetSampleAttachmentsArray(theBuffer, NO);
    if (sample_attachments)
    {
        CFDictionaryRef attach;
        CFBooleanRef depends_on_others;
        
        attach = CFArrayGetValueAtIndex(sample_attachments, 0);
        depends_on_others = CFDictionaryGetValue(attach, kCMSampleAttachmentKey_DependsOnOthers);
        result = depends_on_others == kCFBooleanFalse;
    }
    
    return result;
    
}



-(id)init
{
    
    self = [super init];
    self.init_done = NO;
    self.active = NO;
    self.errored = NO;
    
    av_register_all();
    avformat_network_init();
    
    
    _stream_dispatch = dispatch_queue_create("FFMpeg Stream Dispatch", NULL);
    
    
    return self;
    
}


-(bool)stopProcess
{
    
    if (!self.active)
    {
        return NO;
    }
    
    
    self.active = NO;
    
    dispatch_async(_stream_dispatch, ^{
        [self _internal_stopProcess];
    });
    
    return YES;
}



-(bool)_internal_stopProcess
{
    
    if (_av_fmt_ctx)
    {
        if (_av_fmt_ctx->pb)
        {
            av_write_trailer(_av_fmt_ctx);
        }
        
        avio_close(_av_fmt_ctx->pb);
        av_free(_av_fmt_ctx);
    }
    
    if (_av_video_stream)
        av_free(_av_video_stream);
    if (_av_audio_stream)
        av_free(_av_audio_stream);

    _av_fmt_ctx = NULL;
    _av_video_stream = NULL;
    _av_audio_stream = NULL;
    
    if (_audio_extradata)
    {
        free(_audio_extradata);
        _audio_extradata = NULL;
    }
    
    
    _stream_dispatch = nil;
    
    NSLog(@"Stopped FFMPEG");
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
