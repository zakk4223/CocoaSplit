//
//  AVFSession.h
//  CSAVFCapturePlugin
//
//  Created by Zakk on 2/4/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class AVFCapture;

@interface AVFSession : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession *_capture_session;
    dispatch_queue_t _capture_queue;
    AVCaptureVideoDataOutput *_video_capture_output;
    NSHashTable *_outputs;
    AVCaptureDevice *_capture_device;
    AVCaptureDeviceInput *_video_capture_input;
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureAudioDataOutput *_audio_capture_output;

}

-(void)registerOutput:(AVFCapture *)output;
-(void)removeOutput:(AVFCapture *)output;
-(instancetype)initWithDevice:(AVCaptureDevice *)device;


@end
