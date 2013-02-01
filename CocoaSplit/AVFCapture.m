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
    self.videoFramerates = self.activeVideoFormat.videoSupportedFrameRateRanges;
}


-(id) activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _activeVideoDevice = newDev;
    _selectedVideoCaptureDevice = [newDev captureDevice];
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
    
    if (_capture_session.isRunning)
        return YES;
    
    if (!_capture_session)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"videoCapture" code:110 userInfo:@{NSLocalizedDescriptionKey : @"No active capture session"}];
        }
        
        return NO;
        
    }
    _video_capture_queue = dispatch_queue_create("VideoQueue", NULL);
    
    [_video_capture_output setSampleBufferDelegate:self queue:_video_capture_queue];
    
    _audio_capture_queue = dispatch_queue_create("AudioQueue", NULL);
    [_audio_capture_output setSampleBufferDelegate:self queue:_audio_capture_queue];
    

    [_capture_session startRunning];
    
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
        [videoSettings setValue:@[@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), @(kCVPixelFormatType_422YpCbCr8)] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
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
            NSLog(@"QUERIED VIDEO SETTINGS %@", _video_capture_output.videoSettings);

        } else {
            NSLog(@"Can't add video capture output");
            *therror = [NSError errorWithDomain:@"videoCapture" code:130 userInfo:@{NSLocalizedDescriptionKey : @"Could not add video output to capture session"}];
            return NO;
        }
        
        AVCaptureConnection *outconn = [_video_capture_output connectionWithMediaType:AVMediaTypeVideo];
        if (outconn && self.videoCaptureFPS && self.videoCaptureFPS > 0)
        {
            outconn.videoMinFrameDuration = CMTimeMake(1, self.videoCaptureFPS);
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (connection.output == _video_capture_output)
    {
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    

        if (videoFrame)
        {
            CVPixelBufferRetain(videoFrame);

            [self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:videoFrame frameTime:0 ];
            /*
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:newbuf frameTime:0 ];});
             */
            CVPixelBufferRelease(videoFrame);
        }
        
        
    } else if (connection.output == _audio_capture_output) {
        
        
        [_audioDelegate captureOutputAudio:self didOutputSampleBuffer:sampleBuffer];
    }
    
}

@end
