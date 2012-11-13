//
//  QTCapture.m
//  CocoaSplit
//
//  Created by Zakk on 11/6/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "QTCapture.h"
#import "AbstractCaptureDevice.h"
#import "QTHelperProtocol.h"
#import "CapturedFrameProtocol.h"

@implementation QTCapture


-(id) init
{
    self = [super init];
    if (self)
    {
        NSXPCInterface *xpcInterface = [NSXPCInterface interfaceWithProtocol:@protocol(QTHelperProtocol)];
        NSXPCInterface *xpcCallbackInterface = [NSXPCInterface interfaceWithProtocol:@protocol(CapturedFrameProtocol)];
        
        _xpcConnection = [[NSXPCConnection alloc] initWithServiceName:@"zakk.lol.QTCaptureHelper"];
        
        [_xpcConnection setRemoteObjectInterface:xpcInterface];
        [_xpcConnection setExportedInterface:xpcCallbackInterface];
        [_xpcConnection setExportedObject:self];
        
        NSLog(@"SETUP CONNECTION TO LISTENER");
        [_xpcConnection resume];
        _xpcProxy = [_xpcConnection remoteObjectProxy];
        NSLog(@"GOT PROXY OBJECT");
        
        
    }
    return self;
    
}


-(void) setVideoDimensions:(int)width height:(int)height
{
    return;
}


-(bool) providesVideo
{
    return YES;
}

-(bool) providesAudio
{
    return NO;
}





-(bool) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    NSLog(@"SET VIDEO DEVICE TO %@", [newDev uniqueID]);
    _videoInputDevice = [newDev uniqueID];
    return YES;
    
}


-(NSArray *) availableVideoDevices
{
    
    dispatch_semaphore_t reply_s = dispatch_semaphore_create(0);
    
    NSMutableArray *__block retArray;
    NSLog(@"PROXY %@", _xpcProxy);
    NSLog(@"CONNECTION %@", _xpcConnection);
    [_xpcProxy testMethod];
    NSLog(@"CALLED TEST METHOD FROM SPLIT");
    
    [_xpcProxy listCaptureDevices:^(NSArray *r_devices) {
        NSLog(@"REMOTE DEVICES %@", r_devices);
        retArray = [[NSMutableArray alloc] init];
        NSDictionary *devinstance;
        for (devinstance in r_devices)
        {
           [retArray addObject:[[AbstractCaptureDevice alloc]  initWithName:[devinstance valueForKey:@"name"] device:[devinstance valueForKey:@"id"] uniqueID:[devinstance valueForKey:@"id"]]];
        }
        dispatch_semaphore_signal(reply_s);
    }];
    NSLog(@"SEMAPHORE WAIT");
    dispatch_semaphore_wait(reply_s, DISPATCH_TIME_FOREVER);
    reply_s = nil;
    return (NSArray *)retArray;
    
}

-(void) newCapturedFrame:(IOSurfaceID)ioxpc reply:(void (^)())reply
{
    
    IOSurfaceRef  frameIOref = IOSurfaceLookup(ioxpc);
    if (frameIOref)
    {
        
        @synchronized(self) {
            if (_currentFrame)
            {
                IOSurfaceDecrementUseCount(_currentFrame);
                //CFRelease(_currentFrame);
            }
            
            _currentFrame = frameIOref;
            IOSurfaceIncrementUseCount(_currentFrame);
            //CFRetain(_currentFrame);
        }
    
        
    }

    // ALWAYS reply
    reply();
}




-(bool) stopCaptureSession
{
    [_xpcProxy stopXPCCaptureSession];
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    
    NSLog(@"CALLING STARTXPC WITH %@", _videoInputDevice);
    [_xpcProxy startXPCCaptureSession:_videoInputDevice];
    
    return YES;
}


-(bool) setupCaptureSession:(NSError *__autoreleasing *)therror
{
    
    return YES;
    
}
/*
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
        
        _video_capture_output = [[AVCaptureVideoDataOutput alloc] init];
        
        
        if ([_capture_session canAddOutput:_video_capture_output])
        {
            [_capture_session addOutput:_video_capture_output];
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

*/
void QTPixelBufferRelease(void *releaseRefCon, const void *baseAddress)
{
    
    if (baseAddress)
        free((void *)baseAddress);
    
    
}

- (CVImageBufferRef) getCurrentFrame
{

    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, NULL, &newbuf);
            return newbuf;
            
            
        }
        
    }
    
    return newbuf;
    
    

    
    
}

/*
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    if (connection.output == _video_capture_output)
    {
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        
        
        
        @synchronized(self)
        {
            if (_currentFrame)
            {
                CVPixelBufferRelease(_currentFrame);
            }
            
            CVPixelBufferRetain(videoFrame);
            _currentFrame = videoFrame;
        }
    } else if (connection.output == _audio_capture_output) {
        
        
        [_audioDelegate captureOutputAudio:self didOutputSampleBuffer:sampleBuffer];
    }
    
}
 */

@end
