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
#import <Cocoa/Cocoa.h>




@protocol CaptureSessionProtocol <NSObject>

@required

@property double videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property id videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;



-(void) setVideoDimensions:(int)width height:(int)height;


-(CVImageBufferRef) getCurrentFrame;




@optional
@property id activeAudioDevice;
-(void) setAudioDelegate:(id)delegate;
-(NSArray *) availableAudioDevices;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property id activeVideoFormat;
@property id activeVideoFramerate;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;
@property (assign) float previewVolume;

-(void)setupAudioCompression;
-(void)stopAudioCompression;




@end


@protocol CaptureDataReceiverDelegateProtocol <NSObject>

@required
//if CMSampleBufferRef may or may not be nil? If it is nil the receiver must
//create PresentationTimeStamps if they are required...
-(void)captureOutputVideo:(id) fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer didOutputImage:(CVImageBufferRef)imageBuffer frameTime:(uint64_t) frameTime;
-(void)captureOutputAudio:(id) fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;


@end