//
//  AVFCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "CSCaptureBase.h"
#import "AVFChannelManager.h"


@class CAMultiAudioPCMPlayer;

@class CaptureController;

@interface AVFAudioCapture : CSCaptureBase <CSCaptureSourceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVCaptureSession *_capture_session;
    
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureAudioDataOutput *_audio_capture_output;
    AVCaptureDeviceInput *_audio_capture_input;
}


@property (strong) AVFChannelManager *audioChannelManager;
@property (strong) CaptureController *audioDelegate;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;
@property (strong) AVCaptureDevice *activeAudioDevice;
@property (strong) AVCaptureAudioPreviewOutput *audioPreviewOutput;
@property (assign) float previewVolume;
@property (assign) bool useAudioEngine;
@property (readonly) NSString *name;
@property (weak) CAMultiAudioPCMPlayer *multiInput;






-(instancetype) initForAudioEngine:(AVCaptureDevice *)device sampleRate:(int)sampleRate;

-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;
-(void) setupAudioPreview;
-(void) setupAudioCompression;
-(void) stopAudioCompression;



@end

