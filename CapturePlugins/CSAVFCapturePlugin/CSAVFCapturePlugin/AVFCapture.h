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
#import "CSCaptureBase.h"
#import "CSPcmPlayer.h"
#import "CSPluginServices.h"
#import "CSIOSurfaceLayer.h"



@interface AVFCapture : CSCaptureBase <CSCaptureSourceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVCaptureSession *_capture_session;
    
    dispatch_queue_t _video_capture_queue;
    
    AVCaptureVideoDataOutput *_video_capture_output;
    AVCaptureDeviceInput *_video_capture_input;

    CVImageBufferRef _currentFrame;
    AVCaptureDevice *_selectedVideoCaptureDevice;
    int _preroll_frame_cnt;
    int _preroll_needed_frames;
    NSDictionary *_savedFormatData;
    NSString *_savedFrameRateData;
    CFAbsoluteTime _lastFrameTime;
    NSMutableArray *_sampleQueue;
    
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureAudioDataOutput *_audio_capture_output;

    CSPcmPlayer *_pcmPlayer;
    
    
    
    
}


@property double videoCaptureFPS;
@property int width;
@property int height;
@property (assign) int videoHeight;
@property (assign) int videoWidth;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property AVCaptureDeviceFormat *activeVideoFormat;
@property AVFrameRateRange *activeVideoFramerate;
@property (assign) int prerollSeconds;
@property (assign) BOOL did_preroll;





-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;



@end

