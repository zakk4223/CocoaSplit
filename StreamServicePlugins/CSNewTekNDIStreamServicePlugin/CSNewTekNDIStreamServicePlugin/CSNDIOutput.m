//
//  CSNDIOutput.m
//  CSNewTekNDIStreamServicePlugin
//
//  Created by Zakk on 1/21/18.
//

#import "CSNDIOutput.h"
#import "NDIHeaders/Processing.NDI.Lib.h"
#import <dlfcn.h>

@implementation CSNDIOutput



-(instancetype)init
{
    if (self = [super init])
    {
        _dispatch = [self.class ndi_dispatch_ptr];
    }
    
    return self;
}




+(void *)ndi_dispatch_ptr
{
    static void *dlHandle = NULL;
    static NDIlib_v3* (*NDIlib_v3_load)(void) = NULL;
    static NDIlib_v3 *dispatchPtr = NULL;
    @synchronized(self)
    {
        if (dlHandle == NULL)
        {
            dlHandle = dlopen(NDILIB_LIBRARY_NAME, RTLD_LOCAL | RTLD_LAZY);
        }
        
        if (!NDIlib_v3_load && dlHandle)
        {
            *((void**)&NDIlib_v3_load) = dlsym(dlHandle, "NDIlib_v3_load");
        }
        
        if (!NDIlib_v3_load)
        {
            if (dlHandle)
            {
                dlclose(dlHandle);
            }
        }
        
        if (!dispatchPtr && NDIlib_v3_load)
        {
            dispatchPtr = NDIlib_v3_load();
        }
        
    }
    if (!dispatchPtr)
    {
        NSLog(@"Could not load NDI, install the runtime from %s", NDILIB_REDIST_URL);
    }
    
    return dispatchPtr;
}

-(bool)queueFramedata:(CapturedFrameData *)frameData
{
    
    CapturedFrameData *currentFrame;
    if (!_ndi_send)
    {
        NSString *sourceName = _name;
        if (!sourceName)
        {
            sourceName = @"COCOASPLIT";
        }
        
        
        NDIlib_send_create_t send_cr;
        send_cr.clock_audio = NO;
        send_cr.clock_video = NO;
        send_cr.p_ndi_name = sourceName.UTF8String;
        send_cr.p_groups = NULL;
        _ndi_send = _dispatch->NDIlib_send_create(&send_cr);
        
    }
    
    currentFrame = frameData;
    
    CVImageBufferRef useImage = CMSampleBufferGetImageBuffer(currentFrame.encodedSampleBuffer);
    
    if (useImage)
    {


        
        for (id object in currentFrame.pcmAudioSamples)
        {
            
            
            CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)object;
            
            NDIlib_audio_frame_v2_t audio_frame;
            CMItemCount numSamples = CMSampleBufferGetNumSamples(audioSample);
            
            CMFormatDescriptionRef audioFormat = CMSampleBufferGetFormatDescription(audioSample);
            const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormat);
            audio_frame.sample_rate = asbd->mSampleRate;
            audio_frame.no_channels = asbd->mChannelsPerFrame;
            audio_frame.timecode = 0LL;
            audio_frame.no_samples = (int)numSamples;
            audio_frame.channel_stride_in_bytes = (int)(sizeof(float)*numSamples);
            audio_frame.p_metadata = NULL;

            AudioBufferList *buffList;
            CMBlockBufferRef blockBuffer;
            size_t needsize;
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioSample, &needsize, NULL, sizeof(buffList), NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, NULL);
            buffList = malloc(needsize);
            CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(audioSample, &needsize, buffList, needsize, NULL, NULL, kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment, &blockBuffer);

            audio_frame.p_data = buffList->mBuffers[0].mData;
            
            _dispatch->NDIlib_send_send_audio_v2(_ndi_send, &audio_frame);
            free(buffList);

            
        }
        
        NDIlib_video_frame_v2_t send_frame;
        NDIlib_FourCC_type_e useFourCC;
        
        OSType imageFormat = CVPixelBufferGetPixelFormatType(useImage);
        switch (imageFormat) {
            case kCVPixelFormatType_32BGRA:
                useFourCC = NDIlib_FourCC_type_BGRA;
                break;
            case kCVPixelFormatType_32RGBA:
                useFourCC = NDIlib_FourCC_type_RGBA;
                break;
            case kCVPixelFormatType_422YpCbCr8:
                useFourCC = NDIlib_FourCC_type_UYVY;
                break;
                
            default:
                useFourCC = NDIlib_FourCC_type_BGRA;

                break;
        }
        send_frame.xres = (int)CVPixelBufferGetWidth(useImage);
        send_frame.yres = (int)CVPixelBufferGetHeight(useImage);
        send_frame.FourCC = useFourCC;
        send_frame.frame_format_type = NDIlib_frame_format_type_progressive;
        send_frame.frame_rate_N = currentFrame.videoDuration.timescale;
        send_frame.frame_rate_D = (int)currentFrame.videoDuration.value;
        send_frame.picture_aspect_ratio = (float)send_frame.xres/(float)send_frame.yres;
        send_frame.timecode = 0LL;
        send_frame.line_stride_in_bytes = (int)CVPixelBufferGetBytesPerRow(useImage);
        send_frame.p_metadata = NULL;
        
        CVPixelBufferLockBaseAddress(useImage, kCVPixelBufferLock_ReadOnly);
        send_frame.p_data = CVPixelBufferGetBaseAddress(useImage);
        _dispatch->NDIlib_send_send_video_async_v2(_ndi_send, &send_frame);
        
        if (_last_frame)
        {
            CVImageBufferRef oldImage = CMSampleBufferGetImageBuffer(_last_frame.encodedSampleBuffer);
            CVPixelBufferUnlockBaseAddress(oldImage, kCVPixelBufferLock_ReadOnly);
        }
        
        _last_frame = currentFrame;
    }
    
    return YES;
}


-(instancetype) initWithName:(NSString *)name
{
    if (self = [self init])
    {
        _name = name;
    }
    return self;
}


-(void)dealloc
{
    if (_last_frame && _last_frame.encodedSampleBuffer)
    {
        CVPixelBufferRef oldFrame = CMSampleBufferGetImageBuffer(_last_frame.encodedSampleBuffer);
        if (oldFrame)
        {
            CVPixelBufferUnlockBaseAddress(oldFrame, kCVPixelBufferLock_ReadOnly);
        }
    }
    
    _last_frame = nil;
}


@end

