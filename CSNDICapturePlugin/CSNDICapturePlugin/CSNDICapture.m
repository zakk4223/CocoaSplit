//
//  CSNDICapture.m
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import "CSNDICapture.h"

#import <dlfcn.h>
#import "CSPluginServices.h"
#import "CSNDISource.h"

#define NDILIB_FULL_PATH "/usr/local/lib/"NDILIB_LIBRARY_NAME

@implementation CSNDICapture


-(instancetype)init
{
    if (self = [super init])
    {
        _ndi_dispatch = [CSNDICapture ndi_dispatch_ptr];
        self.allowDedup = YES;
    }
    return self;
}



+(NDIlib_find_instance_t)ndi_source_finder
{
    static NDIlib_find_instance_t ndi_finder = NULL;
    
    @synchronized(self)
    {
        if (!ndi_finder)
        {
            
            NDIlib_find_create_t find_create;
            find_create.show_local_sources = TRUE;
            find_create.p_groups = NULL;
            NDIlib_v3 *dispatch = [self ndi_dispatch_ptr];
            if (dispatch)
            {
                ndi_finder = dispatch->NDIlib_find_create(&find_create);
            }
        }
    }
    
    return ndi_finder;
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
            dlHandle = dlopen(NDILIB_FULL_PATH, RTLD_LOCAL | RTLD_LAZY);
            if (!dlHandle)
            {
                const char *ndiError = dlerror();
                NSLog(@"NDI dlopen() failed: %s %s", ndiError, NDILIB_LIBRARY_NAME);
            }
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


+(NSString *)label
{
    return @"NewTek NDI";
}

-(NDIlib_source_t *)current_ndi_sources:(uint32_t *)out_count
{
    NDIlib_find_instance_t finder = NULL;
    if (!_ndi_dispatch)
    {
        return NULL;
    }
    
    finder = [self.class ndi_source_finder];
    if (!finder)
    {
        return NULL;
    }
    uint32_t source_count = 0;
    const NDIlib_source_t *sources = _ndi_dispatch->NDIlib_find_get_current_sources(finder, &source_count);
    *out_count = source_count;
    return sources;
}


-(NSArray *)availableVideoDevices
{

    uint32_t source_count = 0;
    
    const NDIlib_source_t *sources = [self current_ndi_sources:&source_count];
    

    if (!_ndi_dispatch)
    {
        return nil;
    }
    
    NSMutableArray *ret = [NSMutableArray array];
    
    for (int i=0; i < source_count; i++)
    {
        NDIlib_source_t ndi_src = sources[i];
        
        CSNDISource *src = [[CSNDISource alloc] initWithSource:ndi_src];
        
        CSAbstractCaptureDevice *dev = [[CSAbstractCaptureDevice alloc] initWithName:src.name device:src uniqueID:src.name];
        [ret addObject:dev];
    }

    if (ret.count == 0)
    {
        CSAbstractCaptureDevice *dummyDev = [[CSAbstractCaptureDevice alloc] initWithName:@"Searching..." device:nil uniqueID:nil];
        [ret addObject:dummyDev];
    }
    return ret;
    
}

-(void)registerPCMOutput:(AVAudioFormat *)audioFormat
{
    
    if (_pcmPlayer)
    {
        //looks like we already have one?
        return;
    }
    
    //dispatch_async(dispatch_get_main_queue(), ^{
        _pcmPlayer = [self createPCMInput:self.captureName withFormat:audioFormat];
        _pcmPlayer.name = self.captureName;

   // });

}


-(void)deregisterPCMOutput
{
    _pcmPlayer = nil;
}



-(void)NDIAudioOutput:(CAMultiAudioPCM *)pcmData fromReceiver:(CSNDIReceiver *)fromReceiver
{

    if (!_pcmPlayer)
    {
        CSNDISource *ndiSource = self.activeVideoDevice.captureDevice;

        _pcmPlayer = [self createAttachedAudioInputForUUID:ndiSource.name withName:ndiSource.name withFormat:pcmData.format];
        [_pcmPlayer play];
    }
    
    if (_pcmPlayer)
    {
        [_pcmPlayer playPcmBuffer:pcmData];
    }
}


-(void)NDIAudioOutputFormatChanged:(CSNDIReceiver *)fromReceiver
{
    if (_pcmPlayer)
    {
        [_pcmPlayer setAudioFormat:fromReceiver.audioFormat];
    }
}


-(void)NDIVideoOutput:(CMSampleBufferRef)sampleBuffer fromReceiver:(id)fromReceiver
{
    CVImageBufferRef cBuf = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (cBuf)
    {
        _lastSize = CVImageBufferGetDisplaySize(cBuf);
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            layer.contents = (__bridge id _Nullable)(CVPixelBufferGetIOSurface(cBuf));
        } withPreuseBlock:^{
            CFRetain(sampleBuffer);
        } withPostuseBlock:^{
            CFRelease(sampleBuffer);
        }];
        [self frameArrived];
    }
}



-(NSSize)captureSize
{
    return _lastSize;
}


-(NDIlib_source_t)find_ndi_source:(NSString *)forName
{
    uint32_t source_count = 0;
    const NDIlib_source_t *sources = [self current_ndi_sources:&source_count];

    for (int i = 0; i < source_count; i++)
    {
        NDIlib_source_t ndi_src = sources[i];
        if (!strncmp(ndi_src.p_ndi_name, forName.UTF8String, strlen(ndi_src.p_ndi_name)))
        {
            return ndi_src;
        }
    }
    
    return (NDIlib_source_t){0};
    
}


-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    [super setActiveVideoDevice:activeVideoDevice];

    CSNDISource *ndiSource = activeVideoDevice.captureDevice;
    
    if (ndiSource)
    {
        self.captureName = ndiSource.name;
        
        CSNDIReceiver *newRecv = [[CSNDIReceiver alloc] initWithSource:ndiSource];
        @synchronized(self)
        {
            if (!_video_thread)
            {
                _video_thread = dispatch_queue_create("NDI Video Capture Delegate", DISPATCH_QUEUE_SERIAL);
            }
            
            if (!_audio_thread)
            {
                _audio_thread = dispatch_queue_create("NDI Audio Capture Delegate", DISPATCH_QUEUE_SERIAL);
            }
            
            if (_current_receiver)
            {
                [_current_receiver stopCapture];
            }
            
            _current_receiver = newRecv;
            [_current_receiver registerVideoDelegate:self withQueue:_video_thread];
            [_current_receiver registerAudioDelegate:self withQueue:_audio_thread];
            [_current_receiver startCapture];

        }
    }
}

-(void)setIsLive:(bool)isLive
{
    
    bool oldLive = super.isLive;
    super.isLive = isLive;
    
    if (isLive == oldLive)
    {
        return;
    }
    
    if (!isLive)
    {
        [self deregisterPCMOutput];
    }
}

-(NSImage *)libraryImage
{
    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    return [bundle imageForResource:@"ndi_logo"];
}

-(void)willDelete
{
    [self deregisterPCMOutput];
}


@end
