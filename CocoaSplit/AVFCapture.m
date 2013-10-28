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
        _capture_session = [[AVCaptureSession alloc] init];
        [self setupVideoOutput];
        
        

        [_capture_session startRunning];
    }
    return self;
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


-(void) setVideoDimensions:(int)width height:(int)height
{
    self.videoHeight = height;
    self.videoWidth = width;
    
    return;
}


-(bool) providesVideo
{
    return YES;
}

-(bool) providesAudio
{
    return YES;
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




-(NSArray *) availableVideoDevices
{
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    
    AVCaptureDevice *devinstance;

    for(devinstance in devices)
    {
        NSLog(@"Inputs %@", devinstance.linkedDevices);
        [retArray addObject:[[AbstractCaptureDevice alloc] initWithName:[devinstance localizedName] device:devinstance uniqueID:devinstance.uniqueID]];
    }
    
    return (NSArray *)retArray;
    
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
        NSLog(@"CAPTURE SESSION IS ALREADY RUNNING");
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



-(bool) setupCaptureSession:(NSError **)therror
{
    

    AVCaptureDeviceInput *video_capture_input;
    AVCaptureDeviceInput *audio_capture_input;
    
    self.prerollSeconds = 2;
    _preroll_frame_cnt = 0;
    _preroll_needed_frames = self.prerollSeconds * self.videoCaptureFPS;
    
    
    if (_capture_session)
        return YES;
        
    
    NSLog(@"Starting setup capture");
    if (_videoDelegate || _audioDelegate)
    {
         _capture_session = [[AVCaptureSession alloc] init];
    }
    
    if (_videoDelegate)
    {
        if (!self.activeVideoDevice)
        {
            NSLog(@"No video input device");
            *therror = [NSError errorWithDomain:@"videoCapture" code:100 userInfo:@{NSLocalizedDescriptionKey : @"Must select video capture device first"}];
            return NO;
        }
  
        _capture_session = [[AVCaptureSession alloc] init];
    
        
        video_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_selectedVideoCaptureDevice error:therror];
    
        if (!video_capture_input)
        {
            NSLog(@"No video capture input?");
            return NO;
        }
                     
        if ([_capture_session canAddInput:video_capture_input])
        {
            [_capture_session addInput:video_capture_input];
        
        } else {
            NSLog(@"Can't add video_capture_input");
            *therror = [NSError errorWithDomain:@"videoCapture" code:120 userInfo:@{NSLocalizedDescriptionKey : @"Could not add video input to capture session"}];
            return NO;
        }
  
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];

        [videoSettings setValue:@[@(kCVPixelFormatType_422YpCbCr8FullRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), @(kCVPixelFormatType_422YpCbCr8)] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
/*        if (self.videoHeight && self.videoWidth)
        {
            [videoSettings setValue:@(self.videoHeight) forKey:(NSString *)kCVPixelBufferHeightKey];
            [videoSettings setValue:@(self.videoWidth) forKey:(NSString *)kCVPixelBufferWidthKey];
        } */
        
        NSLog(@"SETTINGS DICT %@", videoSettings);
        _video_capture_output = [[AVCaptureVideoDataOutput alloc] init];
    
        if ([_capture_session canAddOutput:_video_capture_output])
        {
            [_capture_session addOutput:_video_capture_output];
            _video_capture_output.videoSettings = videoSettings;

        } else {
            NSLog(@"Can't add video capture output");
            *therror = [NSError errorWithDomain:@"videoCapture" code:130 userInfo:@{NSLocalizedDescriptionKey : @"Could not add video output to capture session"}];
            return NO;
        }
                
        AVCaptureConnection *outconn = [_video_capture_output connectionWithMediaType:AVMediaTypeVideo];
        if (outconn && self.videoCaptureFPS && self.videoCaptureFPS > 0)
        {
            NSLog(@"SETTING VIDEO CAPTURE FPS %f", self.videoCaptureFPS);
            outconn.videoMinFrameDuration = CMTimeMake(1000, self.videoCaptureFPS*1000);
            
        }
        
    }
    
    if (_audioDelegate)
    {
        
        if (self.activeAudioDevice)
        {
            audio_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:self.activeAudioDevice error:therror];
    
            if (!audio_capture_input)
            {
                NSLog(@"No audio capture input?");
                return NO;
            }
    
            if ([_capture_session canAddInput:audio_capture_input])
            {
                [_capture_session addInput:audio_capture_input];
        
            } else {
                NSLog(@"Can't add audio input?");
                *therror = [NSError errorWithDomain:@"audioCapture" code:220 userInfo:@{NSLocalizedDescriptionKey : @"Could not add audio input to capture session"}];
                return NO;
            }
    
            _audio_capture_output = [[AVCaptureAudioDataOutput alloc] init];
    
    
            
            _audio_capture_output.audioSettings = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
        AVSampleRateKey: [NSNumber numberWithFloat: 44100.0],
        AVEncoderBitRateKey: [NSNumber numberWithInt:_audioBitrate*1000 ],
        AVNumberOfChannelsKey: @2
            
            };

            
            if ([_capture_session canAddOutput:_audio_capture_output])
            {
                [_capture_session addOutput:_audio_capture_output];
            } else {
                NSLog(@"Can't add audio capture output");
                *therror = [NSError errorWithDomain:@"audioCapture" code:230 userInfo:@{NSLocalizedDescriptionKey : @"Could not add audio output to capture session"}];
                return NO;
            }

        } else {
            NSLog(@"No audio device?");
            *therror = [NSError errorWithDomain:@"audioCapture" code:240 userInfo:@{NSLocalizedDescriptionKey : @"Must select audio capture device first"}];
            return NO;
        }
    }
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


-(void) setupAudioCompression
{
    
    if (!_capture_session)
    {
        return;
    }
    
    if (_audio_capture_output)
    {
        return;
    }
    
    
    _audio_capture_output = [[AVCaptureAudioDataOutput alloc] init];
    
    
    
    _audio_capture_output.audioSettings = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                            AVSampleRateKey: [NSNumber numberWithFloat: 44100.0],
                                            AVEncoderBitRateKey: [NSNumber numberWithInt:_audioBitrate*1000 ],
                                            AVNumberOfChannelsKey: @2
                                            
                                            };
    
    [_audio_capture_output setSampleBufferDelegate:self queue:_audio_capture_queue];

    [_capture_session beginConfiguration];
    
    if ([_capture_session canAddOutput:_audio_capture_output])
    {
        [_capture_session addOutput:_audio_capture_output];
    }
    
    [_capture_session commitConfiguration];
    
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
        
        [videoSettings setValue:@[@(kCVPixelFormatType_422YpCbCr8FullRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), @(kCVPixelFormatType_422YpCbCr8)] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
        /*        if (self.videoHeight && self.videoWidth)
         {
         [videoSettings setValue:@(self.videoHeight) forKey:(NSString *)kCVPixelBufferHeightKey];
         [videoSettings setValue:@(self.videoWidth) forKey:(NSString *)kCVPixelBufferWidthKey];
         } */
        
        NSLog(@"SETTINGS DICT %@", videoSettings);
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
