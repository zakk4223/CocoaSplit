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
#import "AVFAudioCapture.h"
#import <CoreMedia/CoreMedia.h>
#import "CSCaptureSourceProtocol.h"
#import "CSAbstractCaptureDevice.h"
#import "AppleVTCompressor.h"
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <mach/mach_time.h>
#import <QuartzCore/CoreImage.h>
#import "CSPluginLoader.h"
#import "CSStreamServiceProtocol.h"
#import "CSNotifications.h"
#import "PluginManagerWindowController.h"
#import "CreateLayoutViewController.h"
#import "CAMultiAudioEngine.h"
#import "CSAnimationRunnerObj.h"
#import "CSAnimationChooserViewController.h"
#import "CSMidiManagerWindowController.h"
#import "MIKMIDI.h"
#import "CSTimerSourceProtocol.h"
#import "CSInputLibraryWindowController.h"
#import "CSInputLibraryItem.h"
#import "CSNewOutputWindowController.h"
#import "CompressionSettingsPanelController.h"
#import "AppleProResCompressor.h"

@class FFMpegTask;
@protocol VideoCompressor;
@class OutputDestination;
@class InputSource;
@class SourceLayout;
@class LayoutPreviewWindowController;
@class CSLayoutEditWindowController;
@class CSTimedOutputBuffer;


void VideoCompressorReceiveFrame(void *, void *, OSStatus , VTEncodeInfoFlags , CMSampleBufferRef );


@class PreviewView;


@interface CaptureController : NSObject <NSMenuDelegate, MIKMIDIMappableResponder, MIKMIDIResponder, MIKMIDIMappingGeneratorDelegate, CSTimerSourceProtocol, NSCollectionViewDelegate> {
    
    
    NSArray *_inputIdentifiers;

    NSRect _stagingFrame;
    NSRect _liveFrame;
    

    NSScreen *_fullscreenOn;
    
    IOPMAssertionID _PMAssertionID;
    IOReturn _PMAssertionRet;
    
    id _activity_token;
    
    long long _frameCount;
    long long _streamFrameStart;
    
    CFAbsoluteTime _lastFrameTime;
    CFAbsoluteTime _firstFrameTime;
    
    CMTime _firstAudioTime;
    
    dispatch_queue_t _main_capture_queue;
    dispatch_queue_t _preview_queue;
    dispatch_source_t _dispatch_timer;
    dispatch_source_t _statistics_timer;
    dispatch_source_t _audio_statistics_timer;

    
    CFAbsoluteTime _frame_interval;
    CFAbsoluteTime _staging_frame_interval;
    
    mach_timebase_info_data_t _mach_timebase;
    double _frame_time;
    double _start_time;
    
    NSMutableArray *videoBuffer;
    
    dispatch_source_t _log_source;
    bool _last_running_value;
    
    
    
    float _min_render_time;
    float _max_render_time;
    float _avg_render_time;
    float _render_time_total;
    int _renderedFrames;
    
    
    NSPopover *_layoutpopOver;
    NSPopover *_animatepopOver;
    
    NSMutableArray *_screensCache;
    NSMutableArray *_layoutWindows;
}


@property (assign) bool useInstantRecord;
@property (assign) int instantRecordBufferDuration;
@property (strong) NSString *instantRecordCompressor;

@property (strong) CSTimedOutputBuffer *instantRecorder;


@property (weak) IBOutlet NSCollectionView *layoutCollectionView;

@property (assign) bool stagingHidden;

@property (strong) NSMutableArray *inputLibrary;

@property (weak) IBOutlet NSMenu *stagingFullScreenMenu;
@property (weak) IBOutlet NSMenu *liveFullScreenMenu;

@property (weak) IBOutlet NSMenu *exportLayoutMenu;


@property (strong) MIKMIDIDeviceManager *midiManager;

@property (strong) NSMutableDictionary *midiDeviceMappings;

@property (strong) NSArray *midiMapGenerators;

@property (assign) NSInteger currentMidiInputStagingIdx;
@property (assign) NSInteger currentMidiInputLiveIdx;

@property (assign) bool currentMidiLayoutLive;

@property (assign) bool useMidiLiveChannelMapping;
@property (assign) NSInteger midiLiveChannel;


@property (weak) IBOutlet NSArrayController *AudioDeviceArrayController;

@property (strong) CAMultiAudioEngine *multiAudioEngine;


@property (strong) PluginManagerWindowController *pluginManagerController;
@property (strong) CSMidiManagerWindowController *midiManagerController;


@property (strong) NSString *renderStatsString;



@property (strong) NSMutableArray *sourceLayouts;
@property (strong) SourceLayout *selectedLayout;
@property (strong) SourceLayout *stagingLayout;


@property (weak) IBOutlet NSSplitView *canvasSplitView;



@property (assign) double captureFPS;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;


@property (assign) double audio_adjust;


@property (weak) IBOutlet NSPopover *editorPopover;

@property (unsafe_unretained) IBOutlet PreviewView *previewCtx;
@property (weak) IBOutlet PreviewView *stagingCtx;

@property (unsafe_unretained) IBOutlet NSObjectController *objectController;

@property (readonly) NSArray *layoutSortDescriptors;

@property (weak) IBOutlet PreviewView *stagingPreviewView;
@property (weak) IBOutlet PreviewView *livePreviewView;

@property (strong) NSMutableDictionary *transitionNames;
@property (strong) NSArray *transitionDirections;
@property (assign) float transitionDuration;
@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;
@property (assign) bool transitionFullScene;


@property (strong) NSWindow *transitionFilterWindow;

- (IBAction)doInstantRecord:(id)sender;

-(IBAction)openTransitionFilterPanel:(NSButton *)sender;

- (IBAction)stagingViewToggle:(id)sender;
-(IBAction)doImportLayout:(id)sender;

-(void)showStagingView;

- (IBAction)openPluginManager:(id)sender;
- (IBAction)openMidiManager:(id)sender;


-(IBAction) swapStagingAndLive:(id)sender;
- (IBAction)stagingGoLive:(id)sender;
- (IBAction)stagingSave:(id)sender;
- (IBAction)stagingRevert:(id)sender;
- (IBAction)mainRevert:(id)sender;


- (IBAction)unlockStagingFPS:(id)sender;
- (IBAction)unlockLiveFPS:(id)sender;

- (bool)deleteLayout:(SourceLayout *)toDelete;


- (IBAction)streamButtonPushed:(id)sender;

- (IBAction)closeAdvancedPrefPanel:(id)sender;
- (IBAction)openAdvancedPrefPanel:(id)sender;
- (IBAction)openCreateSheet:(id)sender;







@property (strong) NSMutableDictionary *compressors;


@property (weak) NSString *selectedVideoType;
@property (strong) NSString *selectedCompressorType;








@property (strong) IBOutlet NSWindow *advancedPrefPanel;
@property (strong) IBOutlet NSWindow *logWindow;

@property (strong) CSNewOutputWindowController *addOutputWindowController;
@property (strong) CompressionSettingsPanelController *compressionEditPanelController;
@property (weak) IBOutlet NSWindow *mainWindow;




- (IBAction)openLogWindow:(id)sender;



@property (strong) NSMutableArray *captureDestinations;
@property (weak) NSIndexSet *selectedCaptureDestinations;
@property (assign) int selectedTabIndex;




@property (assign) int maxOutputPending;
@property (assign) int maxOutputDropped;

@property (assign) BOOL captureRunning;
@property (strong) NSString *resolutionOption;


@property (assign) int captureHeight;
@property (assign) int captureWidth;


@property (strong) NSArray *validSamplerates;



- (IBAction)removeDestination:(id)sender;

@property (weak) NSArray *audioCaptureDevices;







@property (strong) NSDictionary *extraSaveData;

@property (strong) NSPipe *loggingPipe;
@property (strong) NSFileHandle *logReadHandle;

@property (assign) bool useStatusColors;

@property (unsafe_unretained) IBOutlet NSTextView *logTextView;

@property (weak) IBOutlet NSMenu *extrasMenu;

@property (strong) NSMutableDictionary *extraPlugins;

@property (strong) NSMutableDictionary *extraPluginsSaveData;
@property (strong) CSPluginLoader *sharedPluginLoader;

@property (strong) PreviewView *activePreviewView;

@property (strong) CSInputLibraryWindowController *inputLibraryController;



- (IBAction)openAnimatePopover:(NSButton *)sender;

- (void)saveSettings;
- (void)loadSettings;
- (bool) startStream;
- (void) stopStream;
-(void)setExtraData:(id)saveData forKey:(NSString *)forKey;
-(id)getExtraData:(NSString *)forkey;
-(CVPixelBufferRef)currentFrame;
-(double)mach_time_seconds;
-(bool)pendingStreamConfirmation:(NSString *)queryString;
-(int)streamsPendingCount;
-(int)streamsActiveCount;
-(NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
-(NSColor *)statusColor;
-(void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)deleteSource:(InputSource *)delSource;
-(InputSource *)findSource:(NSPoint)forPoint;
-(SourceLayout *)addLayoutFromBase:(SourceLayout *)baseLayout;
-(SourceLayout *)getLayoutForName:(NSString *)name;

- (IBAction)openLayoutPopover:(NSButton *)sender;
-(void)openLayoutPopover:(NSButton *)sender forLayout:(SourceLayout *)layout;
-(void)openBuiltinLayoutPopover:(NSView *)sender spawnRect:(NSRect)spawnRect forLayout:(SourceLayout *)layout;



@property (weak) IBOutlet NSTableView *outputTableView;
- (IBAction)outputEditClicked:(id)sender;

@property (weak) IBOutlet NSArrayController *sourceLayoutsArrayController;

-(void)setupLogging;
+(CSAnimationRunnerObj *) sharedAnimationObj;
- (NSArray *)commandIdentifiers;
- (MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID;
-(void)learnMidiForCommand:(NSString *)command withRepsonder:(id<MIKMIDIMappableResponder>)responder;

-(void)openMidiLearnerForResponders:(NSArray *)responders;
-(void)clearLearnedMidiForCommand:(NSString *)command withResponder:(id<MIKMIDIMappableResponder>)responder;



-(void)layoutWentFullscreen;
-(void)layoutLeftFullscreen;
+(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void(^)(Class))withBlock;
+(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile;
-(void)toggleLayout:(SourceLayout *)layout;
-(void)saveToLayout:(SourceLayout *)layout;
-(void)switchToLayout:(SourceLayout *)layout;
-(CSLayoutEditWindowController *)openLayoutWindow:(SourceLayout *)layout;
-(void)layoutWindowWillClose:(CSLayoutEditWindowController *)windowController;

-(void)addInputToLibrary:(InputSource *)source;
- (IBAction)openLibraryWindow:(id) sender;
-(void)updateFrameIntervals;








@end
