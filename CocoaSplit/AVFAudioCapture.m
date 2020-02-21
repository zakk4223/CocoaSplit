//
//  AVFCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "AVFAudioCapture.h"
#import "CAMultiAudioPCMPlayer.h"


@implementation AVFAudioCapture


@synthesize previewVolume = _previewVolume;
@synthesize activeAudioDevice = _activeAudioDevice;



-(void) commoninit
{
    self.useAudioEngine = NO;
    _capture_session = [[AVCaptureSession alloc] init];
    _audio_capture_queue = dispatch_queue_create("AudioQueue", NULL);
}


-(instancetype) initForAudioEngine:(AVCaptureDevice *)device sampleRate:(int)sampleRate
{
    
    if (self = [super init])
    {
        [self commoninit];
        self.useAudioEngine = YES;
        self.audioSamplerate = sampleRate;
        
        [self setupAudioCompression];
        self.activeAudioDevice = device;

    }
    
    return self;
}
-(id) init
{
    
    if (self = [super init])
    {
        [self commoninit];
        [self setupAudioPreview];
    }
    
    return self;
}


-(void)dealloc
{
    NSLog(@"DEALLOC AUDIO");
    if (_audio_capture_output)
    {
        [_audio_capture_output setSampleBufferDelegate:nil queue:NULL];
    }
    if (_capture_session)
    {
        [_capture_session stopRunning];

        for(AVCaptureInput *inp in _capture_session.inputs)
        {
            [_capture_session removeInput:inp];
        }
        
        for (AVCaptureOutput *outp in _capture_session.outputs)
        {
            [_capture_session removeOutput:outp];
            
        }
    }
    _audio_capture_output = nil;
    _audio_capture_input = nil;
    _audio_capture_queue = nil;
    
}

-(id) activeAudioDevice
{
    return _activeAudioDevice;
}


-(void) setActiveAudioDevice:(AVCaptureDevice *)activeAudioDevice
{
    _activeAudioDevice = activeAudioDevice;
 
    if (!_capture_session)
    {
        return;
    }
    
    [_capture_session beginConfiguration];
    
    /*
    if (_audio_capture_input)
    {
        [_capture_session removeInput:_audio_capture_input];
        _audio_capture_input = nil;
    }
    */
    

    
    
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
    
    if (!self.useAudioEngine)
    {
        self.audioChannelManager = [[AVFChannelManager alloc] initWithPreviewOutput:self.audioPreviewOutput];
    }

}



-(bool) stopCaptureSession
{
    if (_capture_session)
    {
        [_capture_session stopRunning];
    }
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    

    

    
    if (!_capture_session)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"audioCapture" code:110 userInfo:@{NSLocalizedDescriptionKey : @"No active capture session"}];
        }
        
        return NO;
        
    }
    
    if (_capture_session.isRunning)
    {
        return YES;
    }

    dispatch_async(_audio_capture_queue, ^{
        [_capture_session startRunning];
    });
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
        _audio_capture_output = nil;
        
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
        
        
        if (self.useAudioEngine)
        {
           
            
            
            _audio_capture_output.audioSettings = @{
            AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatLinearPCM],
            AVLinearPCMBitDepthKey: @32,
            AVLinearPCMIsFloatKey: @YES,
            AVLinearPCMIsNonInterleaved: @YES,
            //AVNumberOfChannelsKey: @2,
            //AVSampleRateKey: @(self.audioSamplerate),
            };;
            

        } else {
            _audio_capture_output.audioSettings = @{AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
                                                AVSampleRateKey: [NSNumber numberWithInteger: 44100],
                                                AVEncoderBitRateKey: [NSNumber numberWithInt:128000 ],
                                                AVNumberOfChannelsKey: @2
                                                
                                                };
        }
        [_audio_capture_output setSampleBufferDelegate:self queue:_audio_capture_queue];
    }
    
    
    [_capture_session beginConfiguration];
    
    if ([_capture_session canAddOutput:_audio_capture_output])
    {
                [_capture_session addOutput:_audio_capture_output];

    } else {
    }
    
    [_capture_session commitConfiguration];
    
    //self.audioChannelManager.dataOutput = _audio_capture_output;
    
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


-(NSString *)name
{
    return self.activeAudioDevice.localizedName;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    
    
    if (connection.output == _audio_capture_output) {
        
        
        if (self.multiInput)
        {
            [self.multiInput scheduleBuffer:sampleBuffer];
            
        }
        
    }
}

@end
