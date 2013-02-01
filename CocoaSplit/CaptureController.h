//
//  CaptureController.h
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "AVFCapture.h"
#import "QTCapture.h"
#import <CoreMedia/CoreMedia.h>
#import "FFMpegTask.h"
#import "CaptureSessionProtocol.h"
#import "AbstractCaptureDevice.h"
#import "PreviewView.h"



void VideoCompressorReceiveFrame(void *, void *, OSStatus , VTEncodeInfoFlags , CMSampleBufferRef );



@interface CaptureController : NSObject <CaptureDataReceiverDelegateProtocol> {
    
    id _audio_capture_session;
    
    VTCompressionSessionRef _compression_session;
    NSTimer *_captureTimer;
    long long _frameCount;
    CFAbsoluteTime _firstFrameTime;
    NSString *_selectedVideoType;
    dispatch_queue_t _main_capture_queue;
    
    
}

@property (retain) id<CaptureSessionProtocol> videoCaptureSession;
@property (assign) double min_delay;
@property (assign) double max_delay;
@property (assign) double avg_delay;
@property (assign) long long compressedFrameCount;
@property (assign) NSMutableArray *streamPanelDestinations;



@property (unsafe_unretained) IBOutlet PreviewView *previewCtx;
- (IBAction)addStreamingService:(id)sender;

- (IBAction)streamButtonPushed:(id)sender;

- (IBAction)openCreateSheet:(id)sender;
- (IBAction)videoRefresh:(id)sender;


- (IBAction)closeCreateSheet:(id)sender;


@property (weak) NSString *selectedVideoType;

@property (strong) NSArray *videoTypes;

@property (strong) NSMutableArray *ffmpeg_objects;
@property (weak) NSString *streamingServiceServer;
@property (weak) NSString *streamingServiceKey;

@property (weak) NSString *streamingDestination;


@property (weak) NSString *selectedDestinationType;

@property (strong) NSString *statusString;
@property (strong) NSString *compressionStatusString;

@property (strong) IBOutlet NSWindow *createSheet;

@property (strong) NSDictionary *destinationTypes;

@property (strong) NSMutableArray *captureDestinations;
@property (weak) NSIndexSet *selectedCaptureDestinations;



@property (assign) int captureVideoAverageBitrate;
@property (assign) int captureVideoMaxBitrate;
@property (assign) int captureVideoMaxKeyframeInterval;


@property (assign) int captureHeight;
@property (assign) int captureWidth;

@property (assign) int audioBitrate;

@property (assign) int audioSamplerate;


- (IBAction)removeDestination:(id)sender;

@property (weak) NSArray *audioCaptureDevices;

@property (strong) FFMpegTask *ffmpeg_obj;
@property (strong) AVAssetWriterInput *video_writer;
@property (strong) AVAssetWriterInput *audio_writer;


@property (weak) AbstractCaptureDevice *selectedVideoCapture;
@property (weak) AVCaptureDevice *selectedAudioCapture;

@property (assign) int captureFPS;


@property (weak)  NSString *ffmpeg_path;



- (void)saveSettings;
- (void)loadSettings;




@end
