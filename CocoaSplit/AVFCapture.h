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
    AVCaptureDevice *_selectedVideoCaptureDevice;
    
    
    
}


@property (readonly) NSArray *availableVideoDevices;
@property int videoCaptureFPS;
@property int width;
@property int height;
@property id videoDelegate;
@property (strong) id audioDelegate;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;
@property (assign) int videoHeight;
@property (assign) int videoWidth;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property id activeAudioDevice;
@property AVCaptureDeviceFormat *activeVideoFormat;
@property AVFrameRateRange *activeVideoFramerate;
@property AbstractCaptureDevice *activeVideoDevice;





-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;



@end

