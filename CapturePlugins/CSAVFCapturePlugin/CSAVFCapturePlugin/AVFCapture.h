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
#import "AVFSession.h"


@interface AVFCapture : CSCaptureBase <CSCaptureSourceProtocol, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVFSession *_capture_session;
    
    CVImageBufferRef _currentFrame;
    AVCaptureDevice *_selectedVideoCaptureDevice;
    NSDictionary *_savedFormatData;
    NSString *_savedFrameRateData;
    CFAbsoluteTime _lastFrameTime;
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






-(void)captureVideoOutput:(CMSampleBufferRef)sampleBuffer;
-(void)captureAudioOutput:(CMSampleBufferRef)sampleBuffer;



@end

