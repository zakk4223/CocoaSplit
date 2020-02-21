//
//  CSFFMpegInput.m
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFFMpegInput.h"

@implementation CSFFMpegInput


-(instancetype) init
{
    if (self = [super init])
    {
        _video_codec = NULL;
        _video_codec_ctx = NULL;
        _video_stream_idx = -1;
        _audio_stream_idx = -1;
        _is_ready = NO;
        _is_draining = NO;

        _first_video_pts = 0;
        _first_audio_pts = 0;
        _seen_video_pkt = NO;
        _seen_audio_pkt = NO;
        _duration = 0.0f;
        _seek_request = NO;
        _media_opened = NO;
        _seek_time = 0;
        _read_loop_semaphore = dispatch_semaphore_create(0);
        _read_thread = dispatch_queue_create("READ QUEUE", DISPATCH_QUEUE_SERIAL);
        
        _seek_queue = dispatch_queue_create("SEEK QUEUE", DISPATCH_QUEUE_SERIAL);
        _first_frame = NULL;
        
    }
    return self;
}

-(instancetype) initWithMediaPath:(NSString *)mediaPath
{
    if (self = [self init])
    {
        self.mediaPath = mediaPath;
        self.shortName = [mediaPath lastPathComponent];
        [self fetchMediaInfo];
    }
    
    return self;
}


-(bool)fetchMediaInfo
{
    if (!self.mediaPath)
    {
        return NO;
    }
    
    int open_ret = avformat_open_input(&_format_ctx, self.mediaPath.UTF8String, NULL, NULL);
    if (open_ret < 0)
    {
        return NO;
    }

    avformat_find_stream_info(_format_ctx, NULL);
    self.duration = _format_ctx->duration / (double)AV_TIME_BASE;
    return YES;
}


-(bool)openMedia:(int)bufferVideoFrames
{
    @synchronized(self)
    {
        if (_media_opened)
        {
            return YES;
        }
    }

    if (self.is_ready)
    {
        return YES;
    }
    
    
    if (!self.mediaPath)
    {
        return NO;
    }

    
    if (!_video_message_queue)
    {
        av_thread_message_queue_alloc(&_video_message_queue, 60, sizeof(struct frame_message));
    }
    
    if (!_audio_message_queue)
    {
        av_thread_message_queue_alloc(&_audio_message_queue, 4096 , sizeof(struct frame_message));
    }
    
    av_thread_message_queue_set_err_recv(_video_message_queue, 0);
    av_thread_message_queue_set_err_recv(_audio_message_queue, 0);
    av_thread_message_queue_set_err_send(_video_message_queue, 0);
    av_thread_message_queue_set_err_send(_audio_message_queue, 0);


    


    
    
        AVCodecParameters *v_codec_ctx_orig = NULL;
        AVCodecParameters *a_codec_ctx_orig = NULL;
    if (!_format_ctx)
    {
        int open_ret = avformat_open_input(&_format_ctx, self.mediaPath.UTF8String, NULL, NULL);
        if (open_ret < 0)
        {
            _format_ctx = NULL;
            return NO;
        }
    
    
        avformat_find_stream_info(_format_ctx, NULL);
    }
    
        //av_dump_format(_format_ctx, 0, self.mediaPath.UTF8String, 0);
        for (int i=0; i < _format_ctx->nb_streams; i++)
        {
            if (_format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO && _video_stream_idx == -1)
            {
                _video_stream_idx = i;
            }
            
            if (_format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO && _audio_stream_idx == -1)
            {
                _audio_stream_idx = i;
            }
            
            if (_audio_stream_idx > -1 && _video_stream_idx > -1)
            {
                break;
            }
        }
        if (_video_stream_idx > -1)
        {
            self.videoTimeBase = _format_ctx->streams[_video_stream_idx]->time_base;
            v_codec_ctx_orig = _format_ctx->streams[_video_stream_idx]->codecpar;
            _video_codec = avcodec_find_decoder(v_codec_ctx_orig->codec_id);
            _video_codec_ctx = avcodec_alloc_context3(_video_codec);
            avcodec_parameters_to_context(_video_codec_ctx, v_codec_ctx_orig);
            avcodec_open2(_video_codec_ctx, _video_codec, NULL);
            self.dimensions = NSMakeSize(_video_codec_ctx->width, _video_codec_ctx->height);
            _sws_ctx = sws_alloc_context();
            av_opt_set_int(_sws_ctx, "srcw", _video_codec_ctx->width, 0);
            av_opt_set_int(_sws_ctx, "srch", _video_codec_ctx->height, 0);
            av_opt_set_int(_sws_ctx, "src_format", _video_codec_ctx->pix_fmt, 0);
            av_opt_set_int(_sws_ctx, "dstw", _video_codec_ctx->width, 0);
            av_opt_set_int(_sws_ctx, "dsth", _video_codec_ctx->height, 0);
            av_opt_set_int(_sws_ctx, "dst_format", AV_PIX_FMT_NV12, 0);
            int sws_err = sws_init_context(_sws_ctx, NULL, NULL);
            if (sws_err < 0)
            {
                sws_freeContext(_sws_ctx);
                _sws_ctx = NULL;
            }
        }
        if (_audio_stream_idx > -1)
        {
            self.audioTimeBase = _format_ctx->streams[_audio_stream_idx]->time_base;

            a_codec_ctx_orig = _format_ctx->streams[_audio_stream_idx]->codecpar;
            _audio_codec = avcodec_find_decoder(a_codec_ctx_orig->codec_id);
            _audio_codec_ctx = avcodec_alloc_context3(_audio_codec);
            avcodec_parameters_to_context(_audio_codec_ctx, a_codec_ctx_orig);
            avcodec_open2(_audio_codec_ctx, _audio_codec, NULL);
        }
    
    
    self.is_ready = NO;
    _stop_request = NO;
    self.is_draining = NO;
    
    
    self.duration = _format_ctx->duration / (double)AV_TIME_BASE;
    
    
    

    @synchronized(self)
    {
        _media_opened = YES;
    }
    
    dispatch_async(_read_thread, ^{
        [self readAndDecodeVideoFrames:bufferVideoFrames];
    });
    
     return YES;
}








-(CAMultiAudioPCM *)consumeAudioFrame:(AVAudioFormat *)audioFormat error_out:(int *)error_out
{
    struct frame_message msg;
    uint8_t *arrBuf[2] = {0};
    
    
    if (_audio_message_queue && ((*error_out = av_thread_message_queue_recv(_audio_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK)) >= 0))
    {
        
        AVFrame *recv_frame;
        
        recv_frame = msg.frame;
        if (!recv_frame)
        {
            return NULL;
        }
        
        
        if (recv_frame->width == 999)
        {
            //flush PCM player
            av_frame_free(&recv_frame);
            *error_out = AVERROR_PATCHWELCOME;
            
            //flushPCM.frameCount = -1;
            //flushPCM.bufferCount = -1;
            return NULL;
        }
        
        int dst_linesize;
        
        if (!_swr_ctx)
        {
            uint64_t channel_layout = _audio_codec_ctx->channel_layout;
            if (!channel_layout)
            {
                channel_layout = av_get_default_channel_layout(_audio_codec_ctx->channels);
            }
            _swr_ctx = swr_alloc_set_opts(NULL, AV_CH_LAYOUT_STEREO, AV_SAMPLE_FMT_FLTP, audioFormat.sampleRate, channel_layout, _audio_codec_ctx->sample_fmt, _audio_codec_ctx->sample_rate, 0, NULL);
            swr_init(_swr_ctx);
        }
        int64_t dst_nb_samples = av_rescale_rnd(recv_frame->nb_samples, audioFormat.sampleRate, _audio_codec_ctx->sample_rate, AV_ROUND_UP);
        
        CAMultiAudioPCM *retPCM = [[CAMultiAudioPCM alloc] initWithPCMFormat:audioFormat frameCapacity:(int)dst_nb_samples];
        retPCM.frameLength = (int)dst_nb_samples;
        uint8_t *dBuf =  retPCM.audioBufferList->mBuffers->mData;
        
        
        if (dBuf) //Just in case
        {
            av_samples_fill_arrays((uint8_t **)&arrBuf, &dst_linesize, dBuf, 2, (int)dst_nb_samples, AV_SAMPLE_FMT_FLTP, 1);
            av_samples_set_silence((uint8_t **)&arrBuf, 0, (int)dst_nb_samples, 2, AV_SAMPLE_FMT_FLTP);
            swr_convert(_swr_ctx, (uint8_t **)&arrBuf, (int)dst_nb_samples, (const uint8_t **)recv_frame->extended_data, recv_frame->nb_samples);

            av_frame_unref(recv_frame);
            av_frame_free(&recv_frame);
            return retPCM;
        } else {
            return NULL;
        }
    } else {
        return NULL;
    }
}



-(void)videoFlush:(bool)withEOF
{
    
    struct frame_message msg;
    avcodec_flush_buffers(_video_codec_ctx);
    if (_video_message_queue)
    {
        while (av_thread_message_queue_recv(_video_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK) >= 0)
        {
            if (msg.frame)
            {
                av_frame_unref(msg.frame);
                av_frame_free(&msg.frame);
            }
        }
        if (withEOF)
        {
            av_thread_message_queue_set_err_recv(_video_message_queue, AVERROR_EOF);
        } else {
            av_thread_message_queue_set_err_recv(_video_message_queue, 0);
        }
    }
    
    
    
    
}


-(void)audioFlush
{
    
    struct frame_message msg;
    
    avcodec_flush_buffers(_audio_codec_ctx);
    if (_audio_message_queue)
    {
        while (av_thread_message_queue_recv(_audio_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK) >= 0)
        {

            if (msg.frame)
            {
                av_frame_free(&msg.frame);
            }
        }
        
        AVFrame *flushFrame = av_frame_alloc();
        flushFrame->width = 999;
        msg.frame = flushFrame;
        av_thread_message_queue_set_err_recv(_audio_message_queue, 0);
        av_thread_message_queue_send(_audio_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK);
        
    }
}


-(AVFrame *)firstVideoFrame
{
    return _first_frame;
}


-(void)internal_seek:(int64_t)time
{
    if (_format_ctx)
    {
        
        int seek_ret = av_seek_frame(_format_ctx, -1, time, AVSEEK_FLAG_BACKWARD);

        if (seek_ret < 0)
        {
            @synchronized (self) {
                _seek_request = NO;
            }
            return;
        }
        AVFifoBuffer *seek_buffer = av_fifo_alloc(sizeof(AVPacket) * 600);
        
        
        //int seek_ret = avformat_seek_file(_format_ctx, _video_stream_idx, time-10, time, time+10, AVSEEK_FLAG_BACKWARD);
        [self videoFlush:NO];
        [self audioFlush];
        
        if (_first_frame)
        {
            av_frame_free(&_first_frame);
            _first_frame = NULL;
            
        }
        AVPacket buf_pkt;
        int64_t video_pts = AV_NOPTS_VALUE;
        
        while (av_read_frame(_format_ctx, &buf_pkt) >= 0)
        {
            if (buf_pkt.stream_index == _video_stream_idx)
            {
                video_pts = buf_pkt.pts;
                [self decodeVideoPacket:&buf_pkt];
                av_packet_unref(&buf_pkt);
                break;
            } else if (buf_pkt.stream_index == _audio_stream_idx){
                av_fifo_generic_write(seek_buffer, &buf_pkt, sizeof(AVPacket), NULL);
            }
        }
        
        while (av_fifo_size(seek_buffer) >= sizeof(AVPacket))
        {
            AVPacket a_pkt;
            av_fifo_generic_read(seek_buffer, &a_pkt, sizeof(AVPacket), NULL);
            if (av_compare_ts(a_pkt.pts, self.audioTimeBase, video_pts, self.videoTimeBase) >= 0)
            {
                [self decodeAudioPacket:&a_pkt];
            }
            av_packet_unref(&a_pkt);
        }
        av_fifo_free(seek_buffer);
        
        _first_video_pts = 0;
        _seen_video_pkt = NO;
        @synchronized (self) {
            _seek_request = NO;

        }
    }
}

-(void)seek:(double)time
{
    //if (_seek_request) return;
    
    if (_format_ctx)
    {
        int64_t seek_pts = time / av_q2d(AV_TIME_BASE_Q);

        
        _seek_time = seek_pts;
        _seek_request = YES;
        self.is_draining = NO;
        dispatch_semaphore_signal(_read_loop_semaphore);
        av_thread_message_queue_set_err_send(_video_message_queue, AVERROR_EXTERNAL);

        //[self audioFlush];
    }
    
}

-(void)stop
{
    _stop_request = YES;
    dispatch_semaphore_signal(_read_loop_semaphore);
}

-(void)start
{
    dispatch_semaphore_signal(_read_loop_semaphore);
}


-(AVFrame *)consumeFrame:(int *)error_out
{
    
    if (!_video_message_queue)
    {
        return NULL;
    }
    
    
    /*
    if (_video_done)
    {
        return NULL;
    }*/
    *error_out = 0;
    
    struct frame_message msg;
    AVFrame *recv_frame;
    if ((*error_out = av_thread_message_queue_recv(_video_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK)) >= 0)
    {
        
        recv_frame = msg.frame;
    } else {
        
        if (self.is_draining)
        {
            self.is_ready = NO;
        }
        recv_frame = NULL;
    }
    return recv_frame;
}


//You should run this is a gcd queue/block

-(void)readAndDecodeVideoFrames:(int)frameCnt
{
    
    int read_frames = 0;
    AVPacket av_packet;
    

    
    if (!_format_ctx)
    {
        return;
    }
    
    
    
    while (YES)
    {
        @autoreleasepool {
            if (frameCnt == 0 && !self.is_ready)
            {
                
                continue;
            }
            
            
            if (_stop_request)
            {
                [self internal_closeMedia];
                _stop_request = NO;
                return;
            }
            
            bool seekreq;
            @synchronized (self) {
                seekreq = _seek_request;
            }
            
            if (seekreq)
            {
                [self internal_seek:_seek_time];
                av_thread_message_queue_set_err_send(_video_message_queue, 0);
                continue;
            }
            
            int read_ret = 0;
            
            
            read_ret = av_read_frame(_format_ctx, &av_packet);
            if (read_ret < 0)
            {
                av_thread_message_queue_set_err_recv(_video_message_queue, AVERROR_EOF);
                av_thread_message_queue_set_err_recv(_audio_message_queue, AVERROR_EOF);
                
                dispatch_semaphore_wait(_read_loop_semaphore, dispatch_time(DISPATCH_TIME_NOW, 16*NSEC_PER_MSEC));
                continue;
                
            } else {
                if (av_packet.stream_index == _video_stream_idx)
                {
                    if (!_seen_video_pkt && av_packet.pts != AV_NOPTS_VALUE)
                    {
                        _first_video_pts = av_packet.pts;
                        _seen_video_pkt = YES;
                        
                    }
                    
                    bool got_frame = [self decodeVideoPacket:&av_packet];
                    
                    
                    
                    if (got_frame)
                    {
                        read_frames++;
                    }
                } else if (av_packet.stream_index == _audio_stream_idx) {
                    
                    if (!_seen_audio_pkt)
                    {
                        _first_audio_pts = av_packet.pts;
                        _seen_audio_pkt = YES;
                    }
                    
                    bool got_frame = [self decodeAudioPacket:&av_packet];
                    if (!got_frame)
                    {
                        // av_thread_message_queue_set_err_recv(_audio_message_queue, AVERROR_EOF);
                    }
                }
                
                
            }
            av_packet_unref(&av_packet);
            
            if (frameCnt > 0 && read_frames >= frameCnt && !self.is_ready)
            {
                self.is_ready = YES;
                dispatch_semaphore_wait(_read_loop_semaphore, DISPATCH_TIME_FOREVER);
                
            }
        }
    }
}


-(bool)decodeAudioPacket:(AVPacket *)av_packet
{
    AVFrame *output_frame = NULL;
    bool ret = NO;
    output_frame = av_frame_alloc();
    struct frame_message msg;
    
    

        int send_err = avcodec_send_packet(_audio_codec_ctx, av_packet);
        if (send_err < 0)
        {
            av_frame_free(&output_frame);

            return NO;
        }
        if (self.is_draining)
        {
            av_frame_free(&output_frame);

            return NO;
            
        }
        
        while (!avcodec_receive_frame(_audio_codec_ctx, output_frame))
        {
            if (!output_frame->channel_layout)
            {
                output_frame->channel_layout = av_get_default_channel_layout(_audio_codec_ctx->channels);
            }
            AVFrame *cloned_frame = av_frame_clone(output_frame);
            
            msg.frame = cloned_frame;
            msg.notused = 0;
            av_thread_message_queue_send(_audio_message_queue, &msg, 0);
            ret = YES;
            
        }
    av_frame_unref(output_frame);
    av_frame_free(&output_frame);
    return ret;
}


-(bool)decodeVideoPacket:(AVPacket *)av_packet
{
    AVFrame *output_frame = NULL;
    struct frame_message msg;
    bool ret = NO;
    

    
    

    int send_err = avcodec_send_packet(_video_codec_ctx, av_packet);
    if (send_err != 0)
    {
        return NO;
    }
    output_frame = av_frame_alloc();

    int recv_err = avcodec_receive_frame(_video_codec_ctx, output_frame);
    if (!recv_err)
    {

        int width = output_frame->width;
        int height = output_frame->height;
        
        
        
        AVFrame* conv_frame = av_frame_alloc();
        conv_frame->width = width;
        conv_frame->height = height;
        conv_frame->format = AV_PIX_FMT_NV12;
        
        av_frame_get_buffer(conv_frame, 32);
        
        sws_scale(_sws_ctx, (const uint8_t *const*)output_frame->data, output_frame->linesize, 0, height, conv_frame->data, conv_frame->linesize);
        
        conv_frame->pts = output_frame->pts;
        conv_frame->pkt_dts = output_frame->pkt_dts;
        if (output_frame->pts != AV_NOPTS_VALUE)
        {
            
            conv_frame->pts = output_frame->pts;
        } else {
            conv_frame->pts = output_frame->pkt_dts; //I guess
        }
        
        
        msg.frame = conv_frame;
        msg.notused = 0;
        int sendret = av_thread_message_queue_send(_video_message_queue, &msg, 0);
        if (sendret)
        {
            av_frame_unref(conv_frame);
            av_frame_free(&conv_frame);
        }
        if (!_first_frame && conv_frame)
        {
            _first_frame = av_frame_alloc();
            av_frame_ref(_first_frame, conv_frame);
        }
        ret = YES;
    } else {
        ret = NO;
    }
    av_frame_unref(output_frame);
    
    av_frame_free(&output_frame);

    return ret;
}



-(void)closeMedia
{
    @synchronized (self) {
        _stop_request = YES;
        
        dispatch_semaphore_signal(_read_loop_semaphore);
        
        av_thread_message_queue_set_err_send(_video_message_queue, AVERROR_EOF);
        av_thread_message_queue_set_err_send(_audio_message_queue, AVERROR_EOF);
    }
}


-(void) internal_closeMedia
{
    struct frame_message msg;

    if (_video_message_queue)
    {

        while (av_thread_message_queue_recv(_video_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK) >= 0)
        {
            if (msg.frame)
            {
                av_frame_unref(msg.frame);
                av_frame_free(&msg.frame);
            }
        }
        
        av_thread_message_queue_set_err_recv(_video_message_queue, AVERROR_EOF);

    }
    
    if (_audio_message_queue)
    {
        av_thread_message_queue_set_err_recv(_audio_message_queue, AVERROR_EOF);

        
        while (av_thread_message_queue_recv(_audio_message_queue, &msg, AV_THREAD_MESSAGE_NONBLOCK) >= 0)
        {
            if (msg.frame)
            {
                av_frame_unref(msg.frame);
                av_frame_free(&msg.frame);
            }
        }

    }
    
    if (_video_codec_ctx)
    {
        AVFrame *outFrame = av_frame_alloc();
        avcodec_send_packet(_video_codec_ctx, NULL);
        while (avcodec_receive_frame(_video_codec_ctx, outFrame) != AVERROR_EOF)
        {
            av_frame_unref(outFrame);
        }
        
        av_frame_free(&outFrame);
        
        avcodec_close(_video_codec_ctx);
        avcodec_free_context(&_video_codec_ctx);

 
    }
    
    if (_audio_codec_ctx)
    {
        AVFrame *outFrame = av_frame_alloc();
        avcodec_send_packet(_audio_codec_ctx, NULL);
        while (avcodec_receive_frame(_audio_codec_ctx, outFrame) != AVERROR_EOF)
        {
            av_frame_unref(outFrame);
        }
        
        av_frame_free(&outFrame);
        avcodec_close(_audio_codec_ctx);
        avcodec_free_context(&_audio_codec_ctx);

    }

    
    if (_format_ctx)
    {
        avformat_close_input(&_format_ctx);
    }
    
    _video_codec_ctx = NULL;
    _audio_codec_ctx = NULL;

    _format_ctx = NULL;
    if (_sws_ctx)
    {
        sws_freeContext(_sws_ctx);
        _sws_ctx = NULL;
    }
    
    if (_swr_ctx)
    {
        swr_free(&_swr_ctx);
    }

    if (_first_frame)
    {
        av_frame_unref(_first_frame);
        av_frame_free(&_first_frame);
    }
    _media_opened = NO;
    self.duration = 0.0f;
    
 
}

-(void)dealloc
{
    [self closeMedia];
    
    if (_video_message_queue)
    {
        av_thread_message_queue_free(&_video_message_queue);
        _video_message_queue = NULL;
    }
    
    
    if (_audio_message_queue)
    {
        av_thread_message_queue_free(&_audio_message_queue);
        _audio_message_queue = NULL;

    }
    
    if (_video_codec_ctx)
    {
        avcodec_free_context(&_video_codec_ctx);
    }
    
    if (_audio_codec_ctx)
    {
        avcodec_free_context(&_audio_codec_ctx);
    }
    
    if (_format_ctx)
    {
        avformat_free_context(_format_ctx);
    }
    
    
}

@end
