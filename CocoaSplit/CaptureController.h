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
#import "CSAddInputViewController.h"
#import "CAMultiAudioEngine.h"
#import "CSAnimationRunnerObj.h"
#import "CSMidiManagerWindowController.h"
#import "MIKMIDI.h"
#import "CSTimerSourceProtocol.h"
#import "CSInputLibraryWindowController.h"
#import "CSInputLibraryItem.h"
#import "CSNewOutputWindowController.h"
#import "CompressionSettingsPanelController.h"
#import "AppleProResCompressor.h"
#import "CSAddOutputPopupViewController.h"
#import "CSStreamOutputWindowController.h"
#import "CSLayoutSwitcherWithPreviewWindowController.h"
#import "CSScriptWindowViewController.h"
#import "CSLayoutSequence.h"
#import "CSSequenceItemLayout.h"
#import "CSSequenceItemWait.h"
#import "CSLayoutSwitcherViewController.h"
#import "CSGridView.h"
#import "CSSequenceEditorWindowController.h"
#import "CSSequenceActivatorViewController.h"
#import "CSLayoutRecorderInfoProtocol.h"
#import "JavaScriptCore/JavaScriptCore.h"
#import "CSLayoutTransitionViewProtocol.h"



@class FFMpegTask;
@protocol VideoCompressor;
@class OutputDestination;
@class InputSource;
@class SourceLayout;
@class LayoutPreviewWindowController;
@class CSLayoutEditWindowController;
@class CSTimedOutputBuffer;
@class CSAdvancedAudioWindowController;
@class CSLayoutRecorder;


void VideoCompressorReceiveFrame(void *, void *, OSStatus , VTEncodeInfoFlags , CMSampleBufferRef );


@class PreviewView;

@protocol CaptureControllerExport <JSExport>
@property (strong) NSMutableArray *layoutRecorders;
@property (strong) NSString *layoutRecorderCompressorName;
@property (strong) NSString *layoutRecordingDirectory;
@property (strong) NSString *layoutRecordingFormat;
@property (weak) IBOutlet CSGridView *layoutGridView;
@property (assign) bool useInstantRecord;
@property (assign) int instantRecordBufferDuration;
@property (strong) NSString *instantRecordCompressor;
@property (strong) NSString *instantRecordDirectory;
@property (readonly) float frameRate;
@property (assign) bool instantRecordActive;
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
@property (strong) NSString *outputStatsString;
@property (strong) NSMutableArray *layoutSequences;
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
@property (strong) NSString *transitionName;
@property (assign) NSInteger active_output_count;
@property (assign) NSInteger total_dropped_frames;
@property (weak) IBOutlet NSView *transitionConfigurationView;
@property (weak) IBOutlet NSView *transitionSuperView;
@property (weak) IBOutlet NSScrollView *audioView;
@property (assign) bool useTransitions;
@property (weak) IBOutlet NSLayoutConstraint *transitionConstraint;
@property (weak) IBOutlet NSLayoutConstraint *audioConstraint;
@property (weak) IBOutlet NSTextField *transitionLabel;
@property (strong) NSWindow *transitionFilterWindow;
@property (strong) NSMutableDictionary *compressors;
@property (weak) NSString *selectedVideoType;
@property (strong) NSString *selectedCompressorType;
@property (strong) IBOutlet NSWindow *advancedPrefPanel;
@property (strong) IBOutlet NSWindow *logWindow;
@property (strong) CSNewOutputWindowController *addOutputWindowController;
@property (strong) CompressionSettingsPanelController *compressionEditPanelController;
@property (weak) IBOutlet NSWindow *mainWindow;
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
@property (weak) NSArray *audioCaptureDevices;
@property (weak) IBOutlet NSOutlineView *inputOutlineView;
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
@property (strong) NSIndexSet *inputOutlineSelectionIndexes;
@property (weak) IBOutlet NSArrayController *activeInputsArrayController;
@property (assign) bool inLayoutTransition;
@property (weak) IBOutlet NSTableView *inputTableView;
@property (weak) IBOutlet NSTableView *outputTableView;
@property (weak) IBOutlet NSArrayController *sourceLayoutsArrayController;
@property (weak) IBOutlet NSTreeController *inputTreeController;
@property (weak) IBOutlet NSButton *streamButton;
@property (strong) NSString *layoutScriptLabel;
@property (strong) CSLayoutRecorder *mainLayoutRecorder;
@property (readonly) SourceLayout *activeLayout;


-(IBAction)hideTransitionView:(id)sender;
-(IBAction)showTransitionView:(id)sender;
- (IBAction)doInstantRecord:(id)sender;
-(IBAction)openTransitionFilterPanel:(NSButton *)sender;



- (IBAction)stagingViewToggle:(id)sender;
-(IBAction)doImportLayout:(id)sender;

-(void)showStagingView;
-(void) hideStagingView;


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


- (IBAction)chooseInstantRecordDirectory:(id)sender;
- (IBAction)chooseLayoutRecordDirectory:(id)sender;







- (IBAction)openLogWindow:(id)sender;



- (IBAction)removeDestination:(id)sender;



+(CaptureController *)sharedCaptureController;

-(NSObject<VideoCompressor> *)compressorByName:(NSString *)name;
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
-(void)deleteSource:(InputSource *)delSource;
-(InputSource *)findSource:(NSPoint)forPoint;
-(SourceLayout *)addLayoutFromBase:(SourceLayout *)baseLayout;
-(SourceLayout *)getLayoutForName:(NSString *)name;
-(void)addSequenceWithNameDedup:(CSLayoutSequence *)sequence;
-(SourceLayout *)findLayoutWithName:(NSString *)name;
-(void)openSequenceWindow:(CSLayoutSequence *)forSequence;
-(CSLayoutSequence *)getSequenceForName:(NSString *)name;


- (IBAction)createLayoutOrSequenceAction:(id)sender;
-(bool)deleteSequence:(CSLayoutSequence *)toDelete;

- (IBAction)openLayoutPopover:(NSButton *)sender;
-(void)openLayoutPopover:(NSButton *)sender forLayout:(SourceLayout *)layout;
-(void)openBuiltinLayoutPopover:(NSView *)sender spawnRect:(NSRect)spawnRect forLayout:(SourceLayout *)layout;



- (IBAction)outputEditClicked:(OutputDestination *)sender;


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
-(void)toggleLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout;
-(void)toggleLayout:(SourceLayout *)layout;
-(void)removeLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout;
-(void)mergeLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout;

-(void)saveToLayout:(SourceLayout *)layout;
-(void)switchToLayout:(SourceLayout *)layout;
-(void)switchToLayout:(SourceLayout *)layout usingLayout:(SourceLayout *)usingLayout;

-(CSLayoutEditWindowController *)openLayoutWindow:(SourceLayout *)layout;
-(void)layoutWindowWillClose:(CSLayoutEditWindowController *)windowController;
-(void)sequenceWindowWillClose:(CSSequenceEditorWindowController *)windowController;



-(void)addInputToLibrary:(NSObject<CSInputSourceProtocol> *)source;
-(void)addInputToLibrary:(NSObject<CSInputSourceProtocol> *)source atIndex:(NSUInteger)idx;

- (IBAction)openLibraryWindow:(id) sender;

- (IBAction)configureIRCompressor:(id)sender;
- (IBAction)configureLayoutRecordingCompressor:(id)sender;



- (IBAction)inputTableControlClick:(NSButton *)sender;

-(void) resetInputTableHighlights;


- (IBAction)outputSegmentedAction:(NSButton *)sender;

- (IBAction)openAdvancedAudio:(id)sender;
- (IBAction)openStreamOutputWindow:(id)sender;
-(void) removeObjectFromCaptureDestinationsAtIndex:(NSUInteger)index;
-(void)openAddOutputPopover:(id)sender sourceRect:(NSRect)sourceRect;

- (IBAction)openLayoutSwitcherWindow:(id)sender;
- (IBAction)switchLayoutView:(id)sender;
-(bool) sleepUntil:(double)target_time;
-(CSLayoutRecorder *)startRecordingLayout:(SourceLayout *)layout;
-(CSLayoutRecorder *)startRecordingLayout:(SourceLayout *)layout usingOutput:(OutputDestination *)output;
-(void)stopRecordingLayout:(SourceLayout *)layout usingOutput:(OutputDestination *)output;
-(void)removeLayoutRecorder:(CSLayoutRecorder *)toRemove;
-(void)stopRecordingLayout:(SourceLayout *)layout;
-(void)removeFileAudio:(CAMultiAudioFile *)toDelete;

@end



@interface CaptureController : NSObject <CaptureControllerExport, NSTableViewDelegate, NSMenuDelegate, MIKMIDIMappableResponder, MIKMIDIResponder, MIKMIDIMappingGeneratorDelegate, NSCollectionViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, CSLayoutRecorderInfoProtocol, NSTableViewDataSource, NSCollectionViewDataSource>

{
CSSequenceEditorWindowController *_sequenceWindowController;


CSLayoutSwitcherViewController *_layoutViewController;
CSScriptWindowViewController *_scriptWindowViewController;
CSSequenceActivatorViewController *_sequenceViewController;


CSLayoutSequence *_testSequence;

NSArray *_inputIdentifiers;

NSRect _stagingFrame;
NSRect _liveFrame;


NSScreen *_fullscreenOn;

IOPMAssertionID _PMAssertionID;
IOReturn _PMAssertionRet;

id _activity_token;

long long _frameCount;
long long _streamFrameStart;

dispatch_source_t _statistics_timer;
dispatch_source_t _audio_statistics_timer;



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

NSPopover *_addInputpopOver;

NSPopover *_addOutputpopOver;

NSPopover *_layoutpopOver;

NSMutableArray *_screensCache;
NSMutableArray *_layoutWindows;
NSMutableArray *_outputWindows;
NSMutableArray *_sequenceWindows;

bool _needsIRReset;

CSAdvancedAudioWindowController *_audioWindowController;
CSStreamOutputWindowController *_streamOutputWindowController;
CSLayoutSwitcherWithPreviewWindowController *_layoutSwitcherWindowController;
CGFloat _savedAudioConstraintConstant;
NSArray *_savedTransitionConstraints;
    
    NSMenu *_inputsMenu;
    

}
@property (strong) NSArray *inputViewSortDescriptors;

@property (strong) NSMutableArray *layoutRecorders;
@property (strong) NSString *layoutRecorderCompressorName;
@property (strong) NSString *layoutRecordingDirectory;
@property (strong) NSString *layoutRecordingFormat;
@property (weak) IBOutlet CSGridView *layoutGridView;
@property (assign) bool useInstantRecord;
@property (assign) int instantRecordBufferDuration;
@property (strong) NSString *instantRecordCompressor;
@property (strong) NSString *instantRecordDirectory;
@property (readonly) float frameRate;
@property (assign) bool instantRecordActive;
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
@property (strong) NSString *outputStatsString;
@property (strong) NSMutableArray *layoutSequences;
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
@property (assign) NSInteger active_output_count;
@property (assign) NSInteger total_dropped_frames;
@property (weak) IBOutlet NSView *transitionConfigurationView;
@property (weak) IBOutlet NSView *transitionSuperView;
@property (weak) IBOutlet NSScrollView *audioView;
@property (assign) bool useTransitions;
@property (weak) IBOutlet NSLayoutConstraint *transitionConstraint;
@property (weak) IBOutlet NSLayoutConstraint *audioConstraint;
@property (weak) IBOutlet NSTextField *transitionLabel;
@property (strong) NSWindow *transitionFilterWindow;
@property (strong) NSMutableDictionary *compressors;
@property (weak) NSString *selectedVideoType;
@property (strong) NSString *selectedCompressorType;
@property (strong) IBOutlet NSWindow *advancedPrefPanel;
@property (strong) IBOutlet NSWindow *logWindow;
@property (strong) CSNewOutputWindowController *addOutputWindowController;
@property (strong) CompressionSettingsPanelController *compressionEditPanelController;
@property (weak) IBOutlet NSWindow *mainWindow;
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
@property (weak) NSArray *audioCaptureDevices;
@property (weak) IBOutlet NSOutlineView *inputOutlineView;
@property (weak) IBOutlet NSTableView *audioTableView;

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
@property (strong) NSIndexSet *inputOutlineSelectionIndexes;
@property (weak) IBOutlet NSArrayController *activeInputsArrayController;
@property (assign) bool inLayoutTransition;
@property (weak) IBOutlet NSTableView *inputTableView;
@property (weak) IBOutlet NSTableView *outputTableView;
@property (weak) IBOutlet NSArrayController *sourceLayoutsArrayController;
@property (weak) IBOutlet NSTreeController *inputTreeController;
@property (weak) IBOutlet NSButton *streamButton;
@property (strong) NSString *layoutScriptLabel;
@property (strong) CSLayoutRecorder *mainLayoutRecorder;
@property (readonly) SourceLayout *activeLayout;
@property (strong) NSMutableSet *audioFileUTIs;
@property (weak) IBOutlet NSView *layoutTransitionConfigView;
@property (strong) NSObject<CSLayoutTransitionViewProtocol> *layoutTransitionViewController;


@property (weak) IBOutlet NSArrayController *audioInputsArrayController;

-(JSContext *)setupJavascriptContext;
-(NSObject<CSInputSourceProtocol>*)inputSourceForPasteboardItem:(NSPasteboardItem *)item;

-(IBAction)openScriptSwitcherWindow:(id)sender;
-(IBAction)inputOutlineViewDoubleClick:(NSOutlineView *)outlineView;
-(bool)fileURLIsAudio:(NSURL *)url;

@end
