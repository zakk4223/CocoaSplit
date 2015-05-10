//
//  AVFSession.m
//  CSAVFCapturePlugin
//
//  Created by Zakk on 2/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "AVFSession.h"
#import "AVFCapture.h"

@implementation AVFSession


+(id) sessionCache
{
    static NSMutableDictionary *sessionCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sessionCache = [NSMutableDictionary dictionary];
    });
    
    return sessionCache;
}

-(instancetype)initWithDevice:(AVCaptureDevice *)device
{
    
    
    NSMutableDictionary *cachemap = [AVFSession sessionCache];
    AVFSession *cachedSession = [cachemap objectForKey:device.uniqueID];
    
    if (cachedSession)
    {
        self = cachedSession;
    } else if (self = [super init]) {
        
        _outputs = [NSHashTable weakObjectsHashTable];
        
        
        
        _capture_device = device;
        _capture_session = [[AVCaptureSession alloc] init];
        [self setupVideoOutput];
        [self setupCaptureInput];

        [_capture_session startRunning];
        
        [cachemap setObject:self forKey:device.uniqueID];
    }
    return self;
}




-(void)setupVideoOutput
{
    if (_capture_session)
    {
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
        
        //I know CIImage can handle this input type. Maybe make this some sort of advanced config if some devices can't handle it?
        
        //[videoSettings setValue:@(kCVPixelFormatType_32BGRA) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];

        
        //[videoSettings setValue:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
        
        
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
        
        _video_capture_output = [[AVCaptureVideoDataOutput alloc] init];
        
        if ([_capture_session canAddOutput:_video_capture_output])
        {
            [_capture_session addOutput:_video_capture_output];
            _video_capture_output.videoSettings = videoSettings;
            
            _capture_queue = dispatch_queue_create("VideoQueue", NULL);
            
            [_video_capture_output setSampleBufferDelegate:self queue:_capture_queue];
            
        }
    }
}

-(void)setupCaptureInput
{
    if (!_capture_session)
    {
        return;
    }
    
    [_capture_session beginConfiguration];
    
    if (_capture_device)
    {
        
        _video_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_capture_device error:nil];
        
        if (_video_capture_input)
        {
            [_capture_session addInput:_video_capture_input];
            
        }
    }
    [_capture_session commitConfiguration];
    
    if ([_capture_device hasMediaType:AVMediaTypeMuxed])
    {
        [self setupAudioOutput];
    }
}


-(void)setupAudioOutput
{
    if (!_capture_session)
    {
        return;
    }
    
    if (!_audio_capture_output)
    {
        
        
        
        _audio_capture_output = [[AVCaptureAudioDataOutput alloc] init];
        
        
        _audio_capture_output.audioSettings = @{
                                                AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatLinearPCM],
                                                AVLinearPCMBitDepthKey: @32,
                                                AVLinearPCMIsFloatKey: @YES,
                                                AVLinearPCMIsNonInterleaved: @YES,
                                                //AVNumberOfChannelsKey: @2,
                                                };
        
        
        _audio_capture_queue = dispatch_queue_create("AVFCaptureMuxedAudio", NULL);
        [_audio_capture_output setSampleBufferDelegate:self queue:_audio_capture_queue];
    }
    
    
    [_capture_session beginConfiguration];
    
    if ([_capture_session canAddOutput:_audio_capture_output])
    {
        [_capture_session addOutput:_audio_capture_output];
        
    } else {
        NSLog(@"COULDN'T ADD AUDIO OUTPUT");
    }
    
    
    [_capture_session commitConfiguration];
}


-(void)registerOutput:(AVFCapture *)output
{
    
    @synchronized(self)
    {
        [_outputs addObject:output];
        if (_outputs.count == 1)
        {
            [_capture_session startRunning];
        }
    }
}

-(void)removeOutput:(AVFCapture *)output
{
    @synchronized(self)
    {
        [_outputs removeObject:output];
        
        if (_outputs.count == 0)
        {
            [_capture_session stopRunning];
        }
    }
    
    //shut capture session if no more outputs are active
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection.output == _video_capture_output)
    {
        NSLog(@"DROPPED FRAME!!!");
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    NSHashTable *outcopy;
    @synchronized(self)
    {
        outcopy = _outputs.copy;
    }
    
    
    for(AVFCapture *outcapture in outcopy)
    {
        if (outcapture)
        {
            if (connection.output == _video_capture_output)
            {
                [outcapture captureVideoOutput:sampleBuffer];
            } else if (connection.output == _audio_capture_output) {
                [outcapture captureAudioOutput:sampleBuffer];
            }
        }
    }

}


@end
