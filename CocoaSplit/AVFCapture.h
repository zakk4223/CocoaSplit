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
#import "ControllerProtocol.h"


@interface AVFCapture : NSObject <CaptureSessionProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVCaptureSession *_capture_session;
    
    dispatch_queue_t _video_capture_queue;
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureVideoDataOutput *_video_capture_output;
    AVCaptureAudioDataOutput *_audio_capture_output;
    AVCaptureDeviceInput *_audio_capture_input;
    AVCaptureDeviceInput *_video_capture_input;

    CVImageBufferRef _currentFrame;
    AVCaptureDevice *_selectedVideoCaptureDevice;
    int _preroll_frame_cnt;
    int _preroll_needed_frames;
    
    
    
}



@property (readonly) NSArray *availableVideoDevices;
@property double videoCaptureFPS;
@property int width;
@property int height;
@property id<ControllerProtocol> videoDelegate;
@property (strong) id<ControllerProtocol> audioDelegate;
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
@property (strong) AVCaptureAudioPreviewOutput *audioPreviewOutput;
@property (assign) int prerollSeconds;
@property (assign) BOOL did_preroll;
@property (assign) float previewVolume;






-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;
-(void) setupAudioPreview;
-(id) initForAudio;
-(void) setupAudioCompression;


@end

