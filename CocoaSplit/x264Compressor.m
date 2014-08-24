//
//  x264Compressor.m
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "x264Compressor.h"
#import "OutputDestination.h"


@implementation x264Compressor



- (id)copyWithZone:(NSZone *)zone
{
    
    x264Compressor *copy = [[[self class] allocWithZone:zone] init];
    
    copy.x264tunes = self.x264tunes;
    copy.x264presets = self.x264presets;
    copy.x264profiles = self.x264profiles;
    
    copy.settingsController = self.settingsController;
    copy.outputDelegate = self.outputDelegate;
    
    copy.isNew = self.isNew;
    copy.name = self.name;
    copy.compressorType = self.compressorType;
    
    copy.preset = self.preset;
    copy.tune = self.tune;
    copy.profile = self.profile;
    copy.vbv_maxrate = self.vbv_maxrate;
    copy.vbv_buffer = self.vbv_buffer;
    copy.keyframe_interval = self.keyframe_interval;
    copy.crf = self.crf;
    copy.use_cbr = self.use_cbr;
    
    copy.width = self.width;
    copy.height = self.height;
    copy.working_width = self.working_width;
    copy.working_height = self.working_height;

    copy.resolutionOption = self.resolutionOption;
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [aCoder encodeObject:self.preset forKey:@"preset"];
    [aCoder encodeObject:self.tune forKey:@"tune"];
    [aCoder encodeObject:self.profile forKey:@"profile"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.vbv_maxrate forKey:@"vbv_maxrate"];
    [aCoder encodeInteger:self.vbv_buffer forKey:@"vbv_buffer"];
    [aCoder encodeInteger:self.keyframe_interval forKey:@"keyframe_interval"];
    [aCoder encodeInteger:self.crf forKey:@"crf"];
    [aCoder encodeBool:self.use_cbr forKey:@"use_cbr"];
    [aCoder encodeInteger:self.width forKey:@"videoWidth"];
    [aCoder encodeInteger:self.height forKey:@"videoHeight"];
    
    [aCoder encodeObject:self.resolutionOption forKey:@"resolutionOption"];
    
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.preset = [aDecoder decodeObjectForKey:@"preset"];
        self.tune = [aDecoder decodeObjectForKey:@"tune"];
        self.profile = [aDecoder decodeObjectForKey:@"profile"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.vbv_maxrate = (int)[aDecoder decodeIntegerForKey:@"vbv_maxrate"];
        self.vbv_buffer = (int)[aDecoder decodeIntegerForKey:@"vbv_buffer"];
        self.crf = (int)[aDecoder decodeIntegerForKey:@"crf"];
        self.use_cbr = [aDecoder decodeBoolForKey:@"use_cbr"];
        self.keyframe_interval = (int)[aDecoder decodeIntegerForKey:@"keyframe_interval"];
        self.width = (int)[aDecoder decodeIntegerForKey:@"videoWidth"];
        self.height = (int)[aDecoder decodeIntegerForKey:@"videoHeight"];
        if ([aDecoder containsValueForKey:@"resolutionOption"])
        {
            self.resolutionOption = [aDecoder decodeObjectForKey:@"resolutionOption"];
        }
        
        if ([[NSNull null] isEqual:self.preset])
        {
            self.preset = nil;
        }
        
        if ([[NSNull null] isEqual:self.tune])
        {
            self.tune = nil;
        }

        
        if ([[NSNull null] isEqual:self.profile])
        {
            self.profile = nil;
        }

        if ([[NSNull null] isEqual:self.resolutionOption])
        {
            self.resolutionOption = nil;
        }

        
    }
    
    return self;
}



-(id)init
{
    if (self = [super init])
    {
        

        self.compressorType = @"x264";
        
        //this all seems like I should be doing it one time, in some sort of thing you might call a class variable...
        
        
        self.x264tunes = [[NSMutableArray alloc] init];
        
        self.x264presets = [[NSMutableArray alloc] init];
        
        self.x264profiles = [[NSMutableArray alloc] init];
        
        for (int i = 0; x264_profile_names[i]; i++)
        {
            [self.x264profiles addObject:[NSString stringWithUTF8String:x264_profile_names[i]]];
        }
        
        
        for (int i = 0; x264_preset_names[i]; i++)
        {
            [self.x264presets addObject:[NSString stringWithUTF8String:x264_preset_names[i]]];
        }
        
        for (int i = 0; x264_tune_names[i]; i++)
        {
            [self.x264tunes addObject:[NSString stringWithUTF8String:x264_tune_names[i]]];
        }

    }
    return self;
}


-(void) reset
{
    
    _compressor_queue = nil;
    
    self.errored = NO;
    _av_codec = NULL;
}




-(NSString *)descriptionmm
{
    return [NSString stringWithFormat:@"%@: Type: %@, VBV-Maxrate %d, VBV-Buffer %d, CRF %d, CBR: %d, Profile %@, Tune %@, Preset %@", self.name, self.compressorType, self.vbv_maxrate, self.vbv_buffer, self.crf, self.use_cbr, self.profile, self.tune, self.preset];
    
}


- (bool)compressFrame:(CapturedFrameData *)frameData
{
    
    if (![self hasOutputs])
    {
        return NO;
    }
    
    if (!self.settingsController)
    {
        return NO;
    }
    
    
    if (!_av_codec)
    {
        BOOL setupOK;

        setupOK = [self setupCompressor:frameData.videoFrame];
        
        if (!setupOK)
        {
            self.errored = YES;
            return NO;
        }
    }
    
    
    if (frameData.videoFrame)
    {
        CVPixelBufferRetain(frameData.videoFrame);
    }
    
    [self setAudioData:frameData syncObj:self];

    dispatch_async(_compressor_queue, ^{
        
        
        if (frameData.frameNumber == 1)
        {
            _next_keyframe_time = frameData.frameTime;
        }
        
        BOOL isKeyFrame = NO;
        
        if (frameData.frameTime >= _next_keyframe_time)
        {
            isKeyFrame = YES;
            _next_keyframe_time += self.keyframe_interval;
        }
        
        
        CMTime pts = frameData.videoPTS;
        
        
        size_t src_height;
        size_t src_width;
        CVImageBufferRef imageBuffer = frameData.videoFrame;
        
        
        //NSLog(@"WIDTH INPUT %zd HEIGHT %zd",  CVPixelBufferGetWidth(imageBuffer), CVPixelBufferGetHeight(imageBuffer));
        
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
        
    
        CVPixelBufferRelease(imageBuffer);
        imageBuffer = nil;
        
        //poke the frameData so it releases the video buffer
        frameData.videoFrame = nil;
        
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
        
        
        for (id dKey in self.outputs)
        {
            OutputDestination *dest = self.outputs[dKey];

            [dest writeEncodedData:frameData];
            
        }
        //[self.outputDelegate outputEncodedData:frameData];
        
        
        //[self.outputDelegate outputAVPacket:pkt codec_ctx:_av_codec_ctx];
    }
        av_free(outframe);
    CVPixelBufferRelease(converted_frame);
        //av_free_packet(pkt);
         //av_free(pkt);
        
        
    });
    
    return YES;
    
    
}



-(bool)setupCompressor:(CVPixelBufferRef)videoFrame
{
 
    avcodec_register_all();
    
    

    NSLog(@"IN COMPRESSOR SETUP");
    if (!self.settingsController)
    {
        return NO;
    }
    

    [self setupResolution:videoFrame];
    
    _compressor_queue = dispatch_queue_create("x264 encoder queue", NULL);

    
    _av_codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    
    if (!_av_codec)
    {
        NSLog(@"Could not find H264 Codec!?");
        return NO;
    }
    
    _next_keyframe_time = 0.0f;
    
    _av_codec_ctx = avcodec_alloc_context3(_av_codec);
    avcodec_get_context_defaults3(_av_codec_ctx, _av_codec);
    
    //_av_codec_ctx->max_b_frames = 0;
    _av_codec_ctx->width = self.working_width;
    _av_codec_ctx->height = self.working_height;
    _av_codec_ctx->time_base.num = 1000000;
    
    _av_codec_ctx->time_base.den = self.settingsController.captureFPS*1000000;
    _av_codec_ctx->pix_fmt = PIX_FMT_YUV420P;
    
    
    int real_keyframe_interval = 0;
    if (!self.keyframe_interval)
    {
        real_keyframe_interval = self.settingsController.captureFPS*2;
    } else {
        real_keyframe_interval  = self.settingsController.captureFPS*self.keyframe_interval;
    }
    
    
    _av_codec_ctx->gop_size = real_keyframe_interval;

    AVDictionary *opts = NULL;

    
    _av_codec_ctx->rc_max_rate = self.vbv_maxrate*1000;

    if (!self.use_cbr)
    {
         _av_codec_ctx->rc_buffer_size = self.vbv_buffer*1000;
        av_dict_set(&opts, "crf", [[NSString stringWithFormat:@"%d", self.crf] UTF8String], 0);

    } else {
        
        //what did we learn today? Don't believe shit you read in forum posts...
         //_av_codec_ctx->rc_buffer_size = ((1/self.settingsController.captureFPS)*self.settingsController.captureVideoAverageBitrate)*1000;
        _av_codec_ctx->rc_buffer_size = self.vbv_maxrate*1000;
        
        _av_codec_ctx->bit_rate = self.vbv_maxrate*1000;
        av_dict_set(&opts, "nal-hrd", "cbr", 0);
    }
    
    _av_codec_ctx->flags |= CODEC_FLAG_GLOBAL_HEADER;
    
    id x264preset = self.preset;
    
    if (x264preset)
    {
        av_dict_set(&opts, "preset", [x264preset UTF8String], 0);
    }
    
    id x264profile = self.profile;

    if (x264profile)
    {
        av_dict_set(&opts, "profile", [x264profile UTF8String], 0);
    }
    
    id x264tune = self.tune;

    if (x264tune)
    {
        av_dict_set(&opts, "tune", [x264tune UTF8String], 0);
    }
    
    
    if (avcodec_open2(_av_codec_ctx, _av_codec, &opts) < 0)
    {
        return NO;
    }
    
    
    _sws_ctx = NULL;
    
    _audioBuffer = [[NSMutableArray alloc] init];

    
    return YES;
}

- (void) setNilValueForKey:(NSString *)key
{
    
    NSUInteger key_idx = [@[@"vbv_buffer", @"vbv_maxrate", @"crf"] indexOfObject:key];
    
    if (key_idx != NSNotFound)
    {
        return [self setValue:[NSNumber numberWithInt:0] forKey:key];
    }
    
    [super setNilValueForKey:key];
}



@end




