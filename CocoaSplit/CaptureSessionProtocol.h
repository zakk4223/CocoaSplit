//
//  CaptureSessionProtocol.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractCaptureDevice.h"
#import <AVFoundation/AVFoundation.h>



@protocol CaptureSessionProtocol <NSObject>

@required
-(NSArray *) availableVideoDevices;  
-(bool) stopCaptureSession;
-(bool) startCaptureSession:(NSError **)error;
-(bool) setActiveVideoDevice:(id)videoDevice;
-(bool) providesVideo;
-(bool) providesAudio;
-(void) setVideoDelegate:(id)delegate;
-(bool) setupCaptureSession:(NSError **)therror;
-(void) setVideoCaptureFPS:(int)fps;
-(void) setVideoDimensions:(int)width height:(int)height;


// For those capture schemes that can (attempt) to capture frames at a specific FPS, we should do so.
// The main capture controller will call out for a frame at the specified FPS rate.
// Implementations are free to define exactly what the 'current frame' is.
// This is done to decouple the output rate from weird/badly behaved capture schemes that can't reliably maintain
// the given rate. Basically we'll drop/dup frames if we have to to keep the output to ffmpeg at a more or less steady pace.
-(CVImageBufferRef) getCurrentFrame;




@optional
-(void) setAudioDelegate:(id)delegate;
-(bool) setActiveAudioDevice:(id)audioDevice;
-(NSArray *) availableAudioDevices;


@end


@protocol CaptureDataReceiverDelegateProtocol <NSObject>

@required
//if CMSampleBufferRef may or may not be nil? If it is nil the receiver must
//create PresentationTimeStamps if they are required...
-(void)captureOutputVideo:(id) fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t) frameTime;
-(void)captureOutputAudio:(id) fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end