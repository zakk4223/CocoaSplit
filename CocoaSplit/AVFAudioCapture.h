//
//  AVFCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVFChannelManager.h"


@class CAMultiAudioPCMPlayer;


@interface AVFAudioCapture : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{

    AVCaptureSession *_capture_session;
    
    dispatch_queue_t _audio_capture_queue;
    
    AVCaptureAudioDataOutput *_audio_capture_output;
    AVCaptureDeviceInput *_audio_capture_input;
}


@property (strong) AVFChannelManager *audioChannelManager;
@property (assign) int audioBitrate;
@property (strong) AVCaptureDevice *activeAudioDevice;
@property (strong) AVCaptureAudioPreviewOutput *audioPreviewOutput;
@property (assign) float previewVolume;
@property (assign) bool useAudioEngine;
@property (readonly) NSString *name;
@property (weak) CAMultiAudioPCMPlayer *multiInput;






-(instancetype) initForAudioEngine:(AVCaptureDevice *)device;

-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;
-(void) setupAudioPreview;
-(void) setupAudioCompression;
-(void) stopAudioCompression;



@end

