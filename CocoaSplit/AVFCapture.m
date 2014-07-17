//
//  AVFCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "AVFCapture.h"
#import "AbstractCaptureDevice.h"

@implementation AVFCapture         


@synthesize activeVideoFormat = _activeVideoFormat;
@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize activeVideoFramerate = _activeVideoFramerate;
@synthesize previewVolume = _previewVolume;
@synthesize activeAudioDevice = _activeAudioDevice;



-(id) init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceChange:) name:AVCaptureDeviceWasConnectedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceChange:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];

        [self changeAvailableVideoDevices];
        _capture_session = [[AVCaptureSession alloc] init];
        [self setupVideoOutput];
        
        
        [_capture_session startRunning];
    }
    return self;
}


-(void) handleDeviceChange:(NSNotification *)notification
{
    
    [self changeAvailableVideoDevices];
    
    
}



-(id) initForAudio
{
    
    if (self = [super init])
    {
        _capture_session = [[AVCaptureSession alloc] init];
        [self setupAudioPreview];
        _audio_capture_queue = dispatch_queue_create("AudioQueue", NULL);

        [_capture_session startRunning];

    }
    
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_capture_session)
    {
        [_capture_session stopRunning];
    }
}




-(AVFrameRateRange *)activeVideoFramerate
{
    return _activeVideoFramerate;
    
}



-(void) setActiveVideoFramerate:(AVFrameRateRange *)activeVideoFramerate
{
    _activeVideoFramerate = activeVideoFramerate;
  
    //TODO: ERROR HANDLING
/*    [self.activeVideoDevice lockForConfiguration:nil];
    self.activeVideoDevice.activeVideoMinFrameDuration = _activeVideoFramerate.minFrameDuration;
    [self.activeVideoDevice unlockForConfiguration];
  */
    
    
    if([[[_selectedVideoCaptureDevice activeFormat] videoSupportedFrameRateRanges] containsObject:_activeVideoFramerate])
    {
        if([_selectedVideoCaptureDevice lockForConfiguration:nil])
        {
            [_selectedVideoCaptureDevice setActiveVideoMinFrameDuration:_activeVideoFramerate.minFrameDuration];
            [_selectedVideoCaptureDevice unlockForConfiguration];
        }
    }
    
    self.videoCaptureFPS = _activeVideoFramerate.minFrameRate;
    
}


-(AVCaptureDeviceFormat *) activeVideoFormat
{
    return _activeVideoFormat;
}


-(void) setActiveVideoFormat:(id)activeVideoFormat
{
    _activeVideoFormat = activeVideoFormat;
    //TODO: Error handling here
/*    [self.activeVideoDevice lockForConfiguration:nil];
    self.activeVideoDevice.activeFormat = _activeVideoFormat;
    [self.activeVideoDevice unlockForConfiguration];
*/
    
    
    if ([_selectedVideoCaptureDevice lockForConfiguration:nil])
    {
        [_selectedVideoCaptureDevice setActiveFormat:_activeVideoFormat];
        [_selectedVideoCaptureDevice unlockForConfiguration];
    }
    
    self.videoFramerates = self.activeVideoFormat.videoSupportedFrameRateRanges;
}


-(id) activeAudioDevice
{
    return _activeAudioDevice;
}

-(void) setActiveAudioDevice:(id)activeAudioDevice
{
    _activeAudioDevice = activeAudioDevice;
 
    if (!_capture_session)
    {
        return;
    }
    
    [_capture_session beginConfiguration];
    
    if (_audio_capture_input)
    {
        [_capture_session removeInput:_audio_capture_input];
        _audio_capture_input = nil;
    }
    
    

    
    
    _audio_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:self.activeAudioDevice error:nil];
    
    if (!_audio_capture_input)
    {
        NSLog(@"No audio capture input?");
    } else {
        
        
        if ([_capture_session canAddInput:_audio_capture_input])
        {
            [_capture_session addInput:_audio_capture_input];
            
        } else {
            NSLog(@"Can't add audio input?");
        }
    }
    [_capture_session commitConfiguration];
    
    self.audioChannelManager = [[AVFChannelManager alloc] initWithPreviewOutput:self.audioPreviewOutput];

}



-(id) activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _activeVideoDevice = newDev;
    _selectedVideoCaptureDevice = [newDev captureDevice];
    
    if (!_capture_session)
    {
        return;
    }
    
    [_capture_session beginConfiguration];
    
    if (_video_capture_input)
    {
        [_capture_session removeInput:_video_capture_input];
        _video_capture_input = nil;
    }
    
    
    if (_selectedVideoCaptureDevice)
    {
        _video_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_selectedVideoCaptureDevice error:nil];
        
        if (_video_capture_input)
        {
            [_capture_session addInput:_video_capture_input];
        }
    }
    
    [_capture_session commitConfiguration];
    
    self.videoFormats = _selectedVideoCaptureDevice.formats;
    self.videoFramerates = _selectedVideoCaptureDevice.activeFormat.videoSupportedFrameRateRanges;
    
}




-(void) changeAvailableVideoDevices
{
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    
    AVCaptureDevice *devinstance;

    for(devinstance in devices)
    {
        [retArray addObject:[[AbstractCaptureDevice alloc] initWithName:[devinstance localizedName] device:devinstance uniqueID:devinstance.uniqueID]];
    }
    
    self.availableVideoDevices = retArray;
    
}



-(bool) stopCaptureSession
{
    if (_capture_session)
    {
        [_capture_session stopRunning];
        /*
        _capture_session = nil;
        _video_capture_queue = nil;
        self.activeVideoDevice = nil;
        _video_capture_output = nil;
        _audio_capture_output = nil;
        self.activeAudioDevice = nil;
        _audio_capture_queue = nil;
        */
    }
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    

    _preroll_frame_cnt = 0;
    self.did_preroll = false;
    
    if (_capture_session.isRunning)
    {
        return YES;
    }

    
    if (!_capture_session)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"videoCapture" code:110 userInfo:@{NSLocalizedDescriptionKey : @"No active capture session"}];
        }
        
        return NO;
        
    }
    
    
    [_selectedVideoCaptureDevice lockForConfiguration:nil];
    if (self.activeVideoFormat)
    {
        _selectedVideoCaptureDevice.activeFormat = self.activeVideoFormat;
    }
    if (self.activeVideoFramerate)
    {
                
        _selectedVideoCaptureDevice.activeVideoMinFrameDuration = self.activeVideoFramerate.minFrameDuration;
    }
    
    [_selectedVideoCaptureDevice unlockForConfiguration];
    

    
    return YES;
}



-(void) setPreviewVolume:(float)previewVolume
{
    
    _previewVolume = previewVolume;
    
    if (self.audioPreviewOutput)
    {
        self.audioPreviewOutput.volume = previewVolume;
    }
}

-(float)previewVolume
{
    return _previewVolume;
}


-(void) stopAudioCompression
{
    if (!_capture_session)
    {
        return;
    }
    
    if (_audio_capture_output)
    {
        [_capture_session beginConfiguration];
        [_capture_session removeOutput:_audio_capture_output];
        [_capture_session commitConfiguration];
    }
}


-(void) setupAudioCompression
{
    
    if (!_capture_session)
    {
        return;
    }
    
    if (!_audio_capture_output)
    {
        
        
        
        _audio_capture_output = [[AVCaptureAudioDataOutput alloc] init];
        
        
        NSLog(@"AUDIO SAMPLERATE %d BITRATE %d", self.audioSamplerate, self.audioBitrate);
        
        _audio_capture_output.audioSettings = nil;
        _audio_capture_output.audioSettings = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                                AVSampleRateKey: [NSNumber numberWithInteger: self.audioSamplerate],
                                                AVEncoderBitRateKey: [NSNumber numberWithInt:self.audioBitrate*1000 ],
                                                AVNumberOfChannelsKey: @2
                                                
                                                };

        
        
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
    self.audioChannelManager.dataOutput = _audio_capture_output;
    
}


-(void) setupAudioPreview
{
    if (_capture_session)
    {
        self.audioPreviewOutput = [[AVCaptureAudioPreviewOutput alloc] init];
        if ([_capture_session canAddOutput:self.audioPreviewOutput])
        {
            [_capture_session addOutput:self.audioPreviewOutput];
        }
        self.audioPreviewOutput.volume = self.previewVolume;
    }
}


-(void)setupVideoOutput
{
    if (_capture_session)
    {
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
        
        //[videoSettings setValue:@(kCVPixelFormatType_422YpCbCr8) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
         
        
        
        [videoSettings setValue:@(kCVPixelFormatType_32BGRA) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
        
        //[videoSettings setValue:@[@(kCVPixelFormatType_422YpCbCr8), @(kCVPixelFormatType_422YpCbCr8FullRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), ] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
        /*        if (self.videoHeight && self.videoWidth)
         {
         [videoSettings setValue:@(self.videoHeight) forKey:(NSString *)kCVPixelBufferHeightKey];
         [videoSettings setValue:@(self.videoWidth) forKey:(NSString *)kCVPixelBufferWidthKey];
         } */
        
        _video_capture_output = [[AVCaptureVideoDataOutput alloc] init];
        
        if ([_capture_session canAddOutput:_video_capture_output])
        {
            [_capture_session addOutput:_video_capture_output];
            _video_capture_output.videoSettings = videoSettings;
            
            _video_capture_queue = dispatch_queue_create("VideoQueue", NULL);
            
            [_video_capture_output setSampleBufferDelegate:self queue:_video_capture_queue];

        }
    }
}


- (CVImageBufferRef) getCurrentFrame
{
    
    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            CVPixelBufferRetain(_currentFrame);
            return _currentFrame;
            
            /*
            CVPixelBufferLockBaseAddress(_currentFrame, 1);
            width = CVPixelBufferGetWidth(_currentFrame);
            height = CVPixelBufferGetHeight(_currentFrame);
            bytesPerRow = CVPixelBufferGetBytesPerRow(_currentFrame);
            bufbytes = malloc(height*bytesPerRow);
            current_base = CVPixelBufferGetBaseAddress(_currentFrame);
            memcpy(bufbytes, current_base, height*bytesPerRow);
        
            CVPixelBufferCreateWithBytes(NULL, width, height, CVPixelBufferGetPixelFormatType(_currentFrame), bufbytes, bytesPerRow, PixelBufferRelease, NULL, NULL, &newbuf);
            CVBufferPropagateAttachments(_currentFrame, newbuf);
            
            CVPixelBufferUnlockBaseAddress(_currentFrame, 1);
             */
        }
        
    }
    
    return newbuf;
    

}


- (BOOL)needsAdvancedVideo
{
    return YES;
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
    if (connection.output == _video_capture_output)
    {
        
        /*
        if (!self.did_preroll)
        {
            if (_preroll_frame_cnt < _preroll_needed_frames)
            {
                _preroll_frame_cnt++;
                return;
            } else if (_preroll_frame_cnt >= _preroll_needed_frames) {
                self.did_preroll = true;
                //dispatch_async(dispatch_get_main_queue(), ^{
                
                    [_capture_session stopRunning];
                    [_capture_session startRunning];

                //});
                return;
            }
        }
         */
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    

        if (videoFrame)
        {
            
            
            CVPixelBufferRetain(videoFrame);

            @synchronized(self) {
                if (_currentFrame)
                {
                    CVPixelBufferRelease(_currentFrame);
                }
                
                _currentFrame = videoFrame;
            
            }
            
            //[self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:videoFrame frameTime:0 ];
            /*
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:newbuf frameTime:0 ];});
             */
            //CVPixelBufferRelease(videoFrame);
        }
        
        
    } else if (connection.output == _audio_capture_output) {
        
        if (_audioDelegate)
        {
            [_audioDelegate captureOutputAudio:self didOutputSampleBuffer:sampleBuffer];
        }
    }
    
}

@end
