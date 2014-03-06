//
//  x264Compressor.m
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "x264Compressor.h"

@implementation x264Compressor



- (bool)compressFrame:(CapturedFrameData *)frameData isKeyFrame:(BOOL)isKeyFrame
{
    
    
    if (!self.settingsController || !self.outputDelegate)
    {
        //CVPixelBufferRelease(imageBuffer);
        return NO;
    }
    
    
    if (!_av_codec)
    {
        BOOL setupOK;

        setupOK = [self setupCompressor];
        
        if (!setupOK)
        {
            return NO;
        }
    }
    
    
    
    dispatch_async(_compressor_queue, ^{
        
        CMTime pts = frameData.videoPTS;
        
        size_t src_height;
        size_t src_width;
        enum PixelFormat frame_fmt;
        CVImageBufferRef imageBuffer = frameData.videoFrame;
        
        OSType cv_pixel_format = CVPixelBufferGetPixelFormatType(imageBuffer);
        
        //NSLog(@"WIDTH INPUT %zd HEIGHT %zd",  CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
        
        if (cv_pixel_format == kCVPixelFormatType_422YpCbCr8)
        {
            frame_fmt = PIX_FMT_UYVY422;
        } else if (cv_pixel_format == kCVPixelFormatType_422YpCbCr8FullRange) {
            frame_fmt = PIX_FMT_YUYV422;
        } else if (cv_pixel_format == kCVPixelFormatType_32BGRA) {
            frame_fmt = PIX_FMT_BGRA;
        } else {
            frame_fmt = PIX_FMT_NV12;
        }

        src_height = CVPixelBufferGetHeight(imageBuffer);
        src_width = CVPixelBufferGetWidth(imageBuffer);
    
    
    if (!_vtpt_ref)
    {
        VTPixelTransferSessionCreate(kCFAllocatorDefault, &_vtpt_ref);
        VTSessionSetProperty(_vtpt_ref, kVTPixelTransferPropertyKey_ScalingMode, kVTScalingMode_Letterbox);
    }
    CVPixelBufferRef converted_frame;
    
    CVPixelBufferCreate(kCFAllocatorDefault, _av_codec_ctx->width, _av_codec_ctx->height, kCVPixelFormatType_420YpCbCr8Planar, 0, &converted_frame);
    
    VTPixelTransferSessionTransferImage(_vtpt_ref, imageBuffer, converted_frame);
        
    
        imageBuffer = nil;
        frameData.videoFrame = nil;
        
    //CVPixelBufferRelease(imageBuffer);
    AVFrame *outframe = avcodec_alloc_frame();
    outframe->format = PIX_FMT_YUV420P;
    outframe->width = (int)src_width;
    outframe->height = (int)src_height;
    CVPixelBufferLockBaseAddress(converted_frame, kCVPixelBufferLock_ReadOnly);
    size_t plane_count = CVPixelBufferGetPlaneCount(converted_frame);
    int i;
    for (i=0; i < plane_count; i++)
    {
        outframe->linesize[i] = (int)CVPixelBufferGetBytesPerRowOfPlane(converted_frame, i);
        outframe->data[i] = CVPixelBufferGetBaseAddressOfPlane(converted_frame, i);
        
    }
    
    
    
    
    outframe->pts = av_rescale_q(pts.value, (AVRational){1,1000000}, _av_codec_ctx->time_base);
        
        
        
        
    AVPacket *pkt = av_malloc(sizeof (AVPacket));
    av_init_packet(pkt);
                                                                                                    
        
        
    int ret;
    int got_output;
    
    pkt->data = NULL;
    pkt->size = 0;
    

    if (isKeyFrame)
    {
        outframe->pict_type = AV_PICTURE_TYPE_I;
    }
        
    ret = avcodec_encode_video2(_av_codec_ctx, pkt, outframe, &got_output);

    CVPixelBufferUnlockBaseAddress(converted_frame, kCVPixelBufferLock_ReadOnly);
    


    

    
    
    if (ret < 0)
    {
        NSLog(@"ERROR IN AVCODEC ENCODE");
    }
    
    if (got_output)
    {
        
        frameData.avcodec_ctx = _av_codec_ctx;
        frameData.avcodec_pkt = pkt;
        
        [self.outputDelegate outputEncodedData:frameData];
        
        //[self.outputDelegate outputAVPacket:pkt codec_ctx:_av_codec_ctx];
    }
        av_free(outframe);
    CVPixelBufferRelease(converted_frame);
        //av_free_packet(pkt);
         //av_free(pkt);
        
        
    });
    
    return YES;
    
    
}



- (bool)setupCompressor
{
 
    avcodec_register_all();
    
    

    if (!self.settingsController)
    {
        return NO;
    }
    

    _compressor_queue = dispatch_queue_create("x264 encoder queue", NULL);

    
    _av_codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    
    if (!_av_codec)
    {
        NSLog(@"Could not find H264 Codec!?");
        return NO;
    }
    
    _av_codec_ctx = avcodec_alloc_context3(_av_codec);
    avcodec_get_context_defaults3(_av_codec_ctx, _av_codec);
    
    //_av_codec_ctx->max_b_frames = 0;
    _av_codec_ctx->width = self.settingsController.captureWidth;
    _av_codec_ctx->height = self.settingsController.captureHeight;
    _av_codec_ctx->time_base.num = 1000000;
    
    _av_codec_ctx->time_base.den = self.settingsController.captureFPS*1000000;
    _av_codec_ctx->pix_fmt = PIX_FMT_YUV420P;
    
    
    int real_keyframe_interval = 0;
    if (!self.settingsController.captureVideoMaxKeyframeInterval)
    {
        real_keyframe_interval = self.settingsController.captureFPS*2;
    } else {
        real_keyframe_interval  = self.settingsController.captureFPS*self.settingsController.captureVideoMaxKeyframeInterval;
    }
    
    
    _av_codec_ctx->gop_size = real_keyframe_interval;

    AVDictionary *opts = NULL;

    
    _av_codec_ctx->rc_max_rate = self.settingsController.captureVideoAverageBitrate*1000;

    if (!self.settingsController.videoCBR)
    {
         _av_codec_ctx->rc_buffer_size = self.settingsController.captureVideoMaxBitrate*1000;
        av_dict_set(&opts, "crf", [[NSString stringWithFormat:@"%d", self.settingsController.x264crf] UTF8String], 0);

    } else {
        
        //what did we learn today? Don't believe shit you read in forum posts...
         //_av_codec_ctx->rc_buffer_size = ((1/self.settingsController.captureFPS)*self.settingsController.captureVideoAverageBitrate)*1000;
        _av_codec_ctx->rc_buffer_size = self.settingsController.captureVideoAverageBitrate*1000;
        
        _av_codec_ctx->bit_rate = self.settingsController.captureVideoAverageBitrate*1000;
        av_dict_set(&opts, "nal-hrd", "cbr", 0);
    }
    
    _av_codec_ctx->flags |= CODEC_FLAG_GLOBAL_HEADER;
    
    id x264preset = self.settingsController.x264preset;
    
    if (x264preset != [NSNull null])
    {
        av_dict_set(&opts, "preset", [x264preset UTF8String], 0);
    }
    
    id x264profile = self.settingsController.x264profile;

    if (x264profile != [NSNull null])
    {
        av_dict_set(&opts, "profile", [x264profile UTF8String], 0);
    }
    
    id x264tune = self.settingsController.x264tune;

    if (x264tune != [NSNull null])
    {
        av_dict_set(&opts, "tune", [self.settingsController.x264tune UTF8String], 0);
    }
    
    
    if (avcodec_open2(_av_codec_ctx, _av_codec, &opts) < 0)
    {
        return NO;
    }
    
    
    _sws_ctx = NULL;
    
    
    return YES;
}
@end




