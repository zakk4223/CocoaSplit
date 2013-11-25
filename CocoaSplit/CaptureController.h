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
#import "h264Compressor.h"
#import "AppleVTCompressor.h"
#import "x264Compressor.h"
#import "ControllerProtocol.h"
#import <IOKit/pwr_mgt/IOPMLib.h>




void VideoCompressorReceiveFrame(void *, void *, OSStatus , VTEncodeInfoFlags , CMSampleBufferRef );



@interface CaptureController : NSObject <CaptureDataReceiverDelegateProtocol, ControllerProtocol> {
    
    id _audio_capture_session;
    
    NSTimer *_captureTimer;
    NSTimer *_idleTimer;
    BOOL _cmdLineInfo;
    

    NSScreen *_fullscreenOn;
    
    IOPMAssertionID _PMAssertionID;
    IOReturn _PMAssertionRet;
    
    long long _frameCount;
    CFAbsoluteTime _firstFrameTime;
    CFAbsoluteTime _lastFrameTime;
    CFAbsoluteTime _firstAudioTime;
    NSString *_selectedVideoType;
    dispatch_queue_t _main_capture_queue;
    dispatch_queue_t _preview_queue;
    dispatch_source_t _dispatch_timer;
    
    
}
@property (strong) id<h264Compressor> videoCompressor;
@property (retain) id<CaptureSessionProtocol> videoCaptureSession;
@property (retain) id<CaptureSessionProtocol> audioCaptureSession;

@property (assign) double min_delay;
@property (assign) double max_delay;
@property (assign) double avg_delay;
@property (assign) long long compressedFrameCount;
@property (assign) NSMutableArray *streamPanelDestinations;
@property (strong) NSUserDefaults *cmdLineArgs;


@property (unsafe_unretained) IBOutlet PreviewView *previewCtx;
- (IBAction)addStreamingService:(id)sender;

- (IBAction)streamButtonPushed:(id)sender;

- (IBAction)closeAdvancedPrefPanel:(id)sender;
- (IBAction)openAdvancedPrefPanel:(id)sender;
- (IBAction)openCreateSheet:(id)sender;
- (IBAction)videoRefresh:(id)sender;
- (IBAction)openAVFAdvanced:(id)sender;
- (IBAction)closeAVFAdvanced:(id)sender;
- (IBAction)openCompressPanel:(id)sender;
- (IBAction)closeCompressPanel:(id)sender;


- (IBAction)closeCreateSheet:(id)sender;


@property (weak) NSString *selectedVideoType;
@property (strong) NSString *selectedCompressorType;


@property (strong) NSArray *videoTypes;
@property (strong) NSArray *compressorTypes;


@property (strong) NSMutableArray *ffmpeg_objects;
@property (weak) NSString *streamingServiceServer;
@property (weak) NSString *streamingServiceKey;

@property (weak) NSString *streamingDestination;


@property (weak) NSString *selectedDestinationType;


@property (strong) IBOutlet NSWindow *createSheet;
@property (strong) IBOutlet NSWindow *avfPanel;
@property (strong) IBOutlet NSWindow *compressPanel;
@property (strong) IBOutlet NSWindow *advancedPrefPanel;



@property (strong) NSDictionary *destinationTypes;

@property (strong) NSMutableArray *captureDestinations;
@property (weak) NSIndexSet *selectedCaptureDestinations;
@property (assign) int selectedTabIndex;


@property (assign) BOOL showPreview;

@property (assign) int captureVideoAverageBitrate;
@property (assign) int captureVideoMaxBitrate;
@property (assign) int captureVideoMaxKeyframeInterval;
@property (strong) NSString *x264tune;
@property (strong) NSString *x264preset;
@property (strong) NSString *x264profile;
@property (assign) int x264crf;
@property (strong) NSMutableArray *x264tunes;
@property (strong) NSMutableArray *x264presets;
@property (strong) NSMutableArray *x264profiles;
@property (strong) NSArray *vtcompressor_profiles;
@property (strong) NSString *vtcompressor_profile;
@property (assign) BOOL videoCBR;

@property (assign) int maxOutputPending;
@property (assign) int maxOutputDropped;

@property (assign) BOOL captureRunning;
@property (strong) NSArray *arOptions;
@property (strong) NSString *resolutionOption;




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
@property (readonly) AVCaptureDevice *selectedAudioCapture;

@property (readonly) double captureFPS;


@property (weak)  NSString *ffmpeg_path;




- (void) outputSampleBuffer:(CMSampleBufferRef)theBuffer;
- (void) outputAVPacket:(AVPacket *)avpkt codec_ctx:(AVCodecContext *)codec_ctx;
- (void)saveSettings;
- (void)loadSettings;
- (bool) startStream;
- (void) stopStream;
- (void) loadCmdlineSettings:(NSUserDefaults *)cmdargs;





@end
