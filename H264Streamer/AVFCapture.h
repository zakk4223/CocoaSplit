//
//  AVFCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "CaptureSessionProtocol.h"


@interface AVFCapture : NSObject <CaptureSessionProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVCaptureSession *_capture_session;
    
    dispatch_queue_t _video_capture_queue;
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureVideoDataOutput *_video_capture_output;
    AVCaptureAudioDataOutput *_audio_capture_output;
    CVImageBufferRef _currentFrame;
    
    
    
    
    
    
}
 

@property (strong) AVCaptureDevice *videoInputDevice;
@property (strong) AVCaptureDevice *audioInputDevice;
@property (strong) id audioDelegate;
@property (strong) id videoDelegate;
@property (assign) int videoFPS;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;


-(bool) initCaptureSession:(AVCaptureDevice *)withInput fps:(int)fpsvalue error:(NSError **)therror;
-(bool) startCaptureSession:(id)delegate error:(NSError **)error;
-(bool) stopCaptureSession;



@end

