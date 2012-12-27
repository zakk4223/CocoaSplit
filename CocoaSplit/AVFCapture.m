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



-(bool) setActiveAudioDevice:(id)audioDevice
{
    
    _audioInputDevice = audioDevice;
    return YES;
    
}


-(bool) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _videoInputDevice = [newDev captureDevice];
    return YES;
    
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
        _capture_session = nil;
        _video_capture_queue = nil;
        _videoInputDevice = nil;
        _video_capture_output = nil;
        _audio_capture_output = nil;
        _audioInputDevice = nil;
        _audio_capture_queue = nil;
        
    }
    return YES;
}

/*
-(void)grabPhoto
{
    
    if (!_staticImage)
    {
    AVCaptureConnection *av_conn;
    av_conn = [_capture_output connectionWithMediaType:AVMediaTypeVideo];

    [_capture_output captureStillImageAsynchronouslyFromConnection:av_conn completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        
        
        //Should I copy the Image Buffer? instead of just retaining it?
        
        CVPixelBufferRetain(videoFrame);
        
        [_videoDelegate captureOutputVideo:self didOutputSampleBuffer:sampleBuffer didOutputImage:videoFrame];
        _staticImage = videoFrame;
        
        //CVPixelBufferRelease(videoFrame);

    }];
    } else {
        [_videoDelegate captureOutputVideo:self didOutputSampleBuffer:nil didOutputImage:_staticImage];

    }
    
    
    
}

   
 */

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
        if (!_videoInputDevice)
        {
            NSLog(@"No video input device");
            *therror = [NSError errorWithDomain:@"videoCapture" code:100 userInfo:@{NSLocalizedDescriptionKey : @"Must select video capture device first"}];
            return NO;
        }
  
        _capture_session = [[AVCaptureSession alloc] init];
    
        
        video_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_videoInputDevice error:therror];
    
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
        if (self.videoHeight && self.videoWidth)
        {
            [videoSettings setValue:@(self.videoHeight) forKey:(NSString *)kCVPixelBufferHeightKey];
            [videoSettings setValue:@(self.videoWidth) forKey:(NSString *)kCVPixelBufferWidthKey];
        }
        
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
        
    }
    
    if (_audioDelegate)
    {
        
        if (_audioInputDevice)
        {
            audio_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_audioInputDevice error:therror];
    
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


void PixelBufferRelease(void *releaseRefCon, const void *baseAddress)
{
    
    if (baseAddress)
        free((void *)baseAddress);
    
    
}

- (CVImageBufferRef) getCurrentFrame
{
    //copy the current frame to a new pixel buffer
    //If I don't copy the pixel buffers, sometimes they just generate exceptions, even if I retain them and lock them. Assuming
    //the IOSurface is being reclaimed or something
    //There may be a better way to do this?
    
    CVImageBufferRef newbuf = NULL;
    void *bufbytes;
    void *current_base;
    size_t width;
    size_t height;
    size_t bytesPerRow;
    
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


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (connection.output == _video_capture_output)
    {
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
        CVPixelBufferRetain(videoFrame);
        @synchronized(self)
        {
            if (_currentFrame)
            {
                CVPixelBufferRelease(_currentFrame);
            }
    
            _currentFrame = videoFrame;
        }
    } else if (connection.output == _audio_capture_output) {
        
        
        [_audioDelegate captureOutputAudio:self didOutputSampleBuffer:sampleBuffer];
    }
    
}

@end
