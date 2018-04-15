//
//  CSNDIReceiver.m
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import "CSNDIReceiver.h"
#import "CSNDICapture.h"

@implementation CSNDIReceiver


-(instancetype)initWithSource:(CSNDISource *)ndi_source
{
    if (self = [self init])
    {
        NDIlib_v3 *dispatch = [CSNDICapture ndi_dispatch_ptr];
        
        NDIlib_recv_create_t create_inst = {0};
        create_inst.allow_video_fields = NO;
        create_inst.source_to_connect_to = ndi_source.ndiSource;
        create_inst.color_format = NDIlib_recv_color_format_fastest;
        create_inst.bandwidth = NDIlib_recv_bandwidth_highest;
        
        _receiver_instance = dispatch->NDIlib_recv_create_v2(&create_inst);
        _currentSize = NSZeroSize;
        _videoTimeout = 1000;
        _audioTimeout = 1000;
        _asbd = NULL;
    }
    
    return self;
}

-(AudioStreamBasicDescription *)audioFormat
{
    return _asbd;
}

-(bool) createPixelBufferPoolForSize:(NSSize) size withFormat:(OSType)format
{
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setValue:[NSNumber numberWithInt:size.width] forKey:(NSString *)kCVPixelBufferWidthKey];
    [attributes setValue:[NSNumber numberWithInt:size.height] forKey:(NSString *)kCVPixelBufferHeightKey];
    [attributes setValue:@{} forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
    [attributes setValue:[NSNumber numberWithUnsignedInt:format] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    
    
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    
    
    CVReturn result = CVPixelBufferPoolCreate(NULL, NULL, (__bridge CFDictionaryRef)(attributes), &_cvpool);
    
    if (result != kCVReturnSuccess)
    {
        return NO;
    }
    
    return YES;
    
    
}

-(CVPixelBufferRef) convertFrameToPixelBuffer:(NDIlib_video_frame_v2_t *)ndi_frame
{
    if (!ndi_frame)
    {
        return nil;
    }
    
    
    NSSize frameSize = NSMakeSize(ndi_frame->xres, ndi_frame->yres);
    OSType pixelFormat;
    switch(ndi_frame->FourCC)
    {
        case NDIlib_FourCC_type_BGRA:
        case NDIlib_FourCC_type_BGRX:
            pixelFormat = kCVPixelFormatType_32BGRA;
            break;
        case NDIlib_FourCC_type_RGBA:
        case NDIlib_FourCC_type_RGBX:
            pixelFormat = kCVPixelFormatType_32RGBA;
            break;
        case NDIlib_FourCC_type_UYVA:
        case NDIlib_FourCC_type_UYVY:
        default:
            pixelFormat = kCVPixelFormatType_422YpCbCr8;
            break;
    }
    if (!NSEqualSizes(_currentSize, frameSize))
    {
        _currentSize = frameSize;
        [self createPixelBufferPoolForSize:frameSize withFormat:pixelFormat];
    }
    
    
    CVPixelBufferRef buf;
    CVPixelBufferPoolCreatePixelBuffer(NULL, _cvpool, &buf);
    
    CVPixelBufferLockBaseAddress(buf, 0);
    
    uint8_t *dst_addr = CVPixelBufferGetBaseAddress(buf);
    memcpy(dst_addr, ndi_frame->p_data, ndi_frame->yres*ndi_frame->line_stride_in_bytes);
    
    CVPixelBufferUnlockBaseAddress(buf, 0);
    
    return buf;
}

-(void)stopAudioCapture
{
    @synchronized(self)
    {
        _stop_audio = YES;
    }
}

-(void)stopVideoCapture
{
    @synchronized(self)
    {
        _stop_video = YES;
    }
}

-(void)stopCapture
{
    [self stopAudioCapture];
    [self stopVideoCapture];
}

-(void)startCapture
{
    [self startVideoCapture];
    [self startAudioCapture];
}


-(void)startAudioCapture
{
    
    if (!_audio_receive_thread)
    {
        _audio_receive_thread = dispatch_queue_create("NDI Audio Receiver Thread", DISPATCH_QUEUE_SERIAL);
    }
    if (!_audio_running)
    {
        dispatch_async(_audio_receive_thread, ^{
            self->_audio_running = YES;
            while (1)
            {
                [self captureAudio:self.audioTimeout];
                @synchronized(self)
                {
                    if (self->_stop_audio)
                    {
                        self->_stop_audio = NO;
                        break;
                    }
                }
            }
            self->_audio_running = NO;
        });
    } else {
        return;
    }
}


-(void)startVideoCapture
{
    
    if (!_video_receive_thread)
    {
        _video_receive_thread = dispatch_queue_create("NDI Video Receiver Thread", DISPATCH_QUEUE_SERIAL);
    }
    if (!_video_running)
    {
        dispatch_async(_video_receive_thread, ^{
            self->_video_running = YES;
            while (1)
            {
                [self captureVideo:self.videoTimeout];
                @synchronized(self)
                {
                    if (self->_stop_video)
                    {
                        self->_stop_video = NO;
                        return;
                    }
                }
            }
            self->_video_running = NO;
        });
    } else {
        return;
    }
}

-(bool)captureAudio:(uint32_t)waitMS
{
    NDIlib_v3 *dispatch = [CSNDICapture ndi_dispatch_ptr];

    NDIlib_audio_frame_v2_t audio_frame;
    NDIlib_frame_type_e recv_val =  dispatch->NDIlib_recv_capture_v2(_receiver_instance, NULL, &audio_frame, NULL, waitMS);
    switch(recv_val)
    {
        case NDIlib_frame_type_audio:
            if (_asbd && (_asbd->mSampleRate != audio_frame.sample_rate || _asbd->mChannelsPerFrame != audio_frame.no_channels))
            {
                free(_asbd);
                _asbd = NULL;
                if (_audioDelegate)
                {
                    [_audioDelegate NDIAudioOutputFormatChanged:self];
                }
            }
            
            if (!_asbd)
            {
                _asbd = malloc(sizeof(AudioStreamBasicDescription));
                _asbd->mFormatID = kAudioFormatLinearPCM;
                _asbd->mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
                _asbd->mChannelsPerFrame = audio_frame.no_channels;
                _asbd->mSampleRate = audio_frame.sample_rate;

                _asbd->mBitsPerChannel = 32;
                _asbd->mBytesPerFrame = 4;
                _asbd->mBytesPerPacket = 4;
                _asbd->mFramesPerPacket = 1;
                _asbd->mReserved = 0;
            }
            
            if (_audio_output_queue && _audioDelegate)
            {
                
                CAMultiAudioPCM *retPCM = [[CAMultiAudioPCM alloc] initWithDescription:_asbd forFrameCount:audio_frame.no_samples];
                uint8_t *dBuf = retPCM.dataBuffer;
                if (dBuf)
                {
                    memcpy(dBuf, audio_frame.p_data, 4*audio_frame.no_samples*audio_frame.no_channels);
                }
                dispatch_async(_audio_output_queue, ^{
                    [self->_audioDelegate NDIAudioOutput:retPCM fromReceiver:self];
                });
            }
            
            dispatch->NDIlib_recv_free_audio(_receiver_instance, &audio_frame);
            return YES;
        case NDIlib_frame_type_none:
            return NO;
        case NDIlib_frame_type_status_change:
            return NO;
        default:
            return NO;
    }
    
    return NO;

}
-(bool)captureVideo:(uint32_t)waitMS
{
    NDIlib_v3 *dispatch = [CSNDICapture ndi_dispatch_ptr];
    
     NDIlib_video_frame_v2_t video_frame;
    
    NDIlib_frame_type_e recv_val =  dispatch->NDIlib_recv_capture_v2(_receiver_instance, &video_frame, NULL, NULL, waitMS);

    CVPixelBufferRef newFrame;

    switch(recv_val)
    {
        case NDIlib_frame_type_video:
            if (_videoDelegate && _video_output_queue)
            {
                newFrame = [self convertFrameToPixelBuffer:&video_frame];
                if (newFrame)
                {
                    CMVideoFormatDescriptionRef videoDesc;
                    CMSampleBufferRef newSample;
             
                    CMSampleTimingInfo timingInfo = {0};
                    timingInfo.decodeTimeStamp = kCMTimeInvalid;
                    timingInfo.presentationTimeStamp = CMTimeMake(video_frame.timecode, 100*NSEC_PER_MSEC); //??
                    timingInfo.duration = CMTimeMake(video_frame.frame_rate_D, video_frame.frame_rate_N);
                    CMVideoFormatDescriptionCreateForImageBuffer(NULL, newFrame, &videoDesc);
                    CMSampleBufferCreateReadyWithImageBuffer(NULL, newFrame, videoDesc, &timingInfo, &newSample);
                    CVBufferRelease(newFrame);
                    CFRelease(videoDesc);
                    dispatch_async(_video_output_queue, ^{
                        [self->_videoDelegate NDIVideoOutput:newSample fromReceiver:self];
                        CFRelease(newSample);
                    });
                }
            }
            
            dispatch->NDIlib_recv_free_video(_receiver_instance, &video_frame);
            return YES;
        case NDIlib_frame_type_none:
            return NO;
        case NDIlib_frame_type_status_change:
            return NO;
        default:
            return NO;
    }

    return NO;
    
}

-(void)registerAudioDelegate:(id<NDIAudioOutputDelegateProtocol>)delegate withQueue:(dispatch_queue_t)audioQueue
{
    @synchronized(self)
    {
        _audioDelegate = delegate;
        _audio_output_queue = audioQueue;
    }
}
-(void)registerVideoDelegate:(id<NDIVideoOutputDelegateProtocol>)delegate withQueue:(dispatch_queue_t)videoQueue
{
    @synchronized(self)
    {
        _videoDelegate = delegate;
        _video_output_queue = videoQueue;
    }
}

-(void)removeVideoDelegate
{
    @synchronized(self)
    {
        _videoDelegate = nil;
        _video_output_queue = nil;
    }
}

-(void)removeAudioDelegate
{
    @synchronized(self)
    {
        _audioDelegate = nil;
        _audio_output_queue = nil;
    }
}


-(void)dealloc
{
    NDIlib_v3 *dispatch = [CSNDICapture ndi_dispatch_ptr];
    dispatch->NDIlib_recv_destroy(_receiver_instance);
    if (_cvpool)
    {
        CVPixelBufferPoolRelease(_cvpool);
    }
    
    if (_asbd)
    {
        free(_asbd);
    }
}


@end
