//
//  CSLayoutEditWindowController.m
//  CocoaSplit
//
//  Created by Zakk on 10/12/15.
//  Copyright © 2015 Zakk. All rights reserved.
//

#import "CSLayoutEditWindowController.h"
#import "CSInputSourceProtocol.h"
#import "CSAudioInputSource.h"


@interface CSLayoutEditWindowController ()

@end

@implementation CSLayoutEditWindowController


-(instancetype) init
{

    return [self initWithWindowNibName:@"CSLayoutEditWindowController"];
}


- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;


    if (self.previewView.sourceLayout.recorder)
    {
        [self.previewView disablePrimaryRender];
    }
    [self.previewView addObserver:self forKeyPath:@"sourceLayout.recorder" options:NSKeyValueObservingOptionNew context:NULL];
    [self.previewView addObserver:self forKeyPath:@"sourceLayout.recordingLayout" options:NSKeyValueObservingOptionNew context:NULL];

    [self.previewView addObserver:self forKeyPath:@"mousedSource" options:NSKeyValueObservingOptionNew context:NULL];
    [self.sourceListViewController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];

    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)openAdvancedAudio:(id)sender
{
    if (!_audioWindowController)
    {
        _audioWindowController = [[CSAdvancedAudioWindowController alloc] init];
    }
    
    _audioWindowController.audioEngine = self.multiAudioEngine;
    
    [_audioWindowController showWindow:nil];
    
}



-(void) setupDummyAudioEngine
{
    CAMultiAudioEngine *audioEngine = nil;
    
    audioEngine = [[CAMultiAudioEngine alloc] init];
    audioEngine.sampleRate = [CaptureController sharedCaptureController].multiAudioEngine.sampleRate;
    
    self.multiAudioEngine = audioEngine;

    audioEngine.previewMixer.muted = YES;
    
    self.previewView.sourceLayout.audioEngine = audioEngine;
//    [audioEngine disableAllInputs];

    [self.previewView.sourceLayout reapplyAudioSources];
}
-(NSString *)windowTitle
{
    return [NSString stringWithFormat:@"Layout - %@", self.previewView.sourceLayout.name];
}


-(void)windowWillClose:(NSNotification *)notification
{
    [self.sourceListViewController removeObserver:self forKeyPath:@"selectedObjects"];

    [self.previewView removeObserver:self forKeyPath:@"sourceLayout.recorder"];
    [self.previewView removeObserver:self forKeyPath:@"sourceLayout.recordingLayout"];

    [self.previewView removeObserver:self forKeyPath:@"mousedSource"];
    self.multiAudioEngine = nil;
    self.previewView.sourceLayout.audioEngine = nil;

    
    if (self.layoutController)
    {
        [self.layoutController discardEditing];
    }
    
    if (self.previewView.sourceLayout && !self.previewView.sourceLayout.recordingLayout)
    {
        [self.previewView.sourceLayout clearSourceList];
    }
    
    if (self.delegate)
    {
        [self.delegate layoutWindowWillClose:self];
    }
}



- (IBAction)cancelEdit:(id)sender
{
    [self close];
}



- (IBAction)editOK:(id)sender
{
    if (self.layoutController)
    {
        [self.layoutController commitEditing];
    }
        
    if (self.previewView.sourceLayout)
    {
        [self.previewView.sourceLayout saveSourceList];
        if (!self.previewView.sourceLayout.recorder)
        {
            //Don't disturb any active recorder
            [self.previewView.sourceLayout clearSourceList];
        }
    }
    [self close];
}




- (IBAction)layoutGoLive:(id)sender
{
    
    CaptureController *controller = [CaptureController sharedCaptureController];
    SourceLayout *useLayout = controller.activePreviewView.sourceLayout;
    [self.previewView.sourceLayout saveSourceList];
    
    [controller switchToLayout:self.previewView.sourceLayout usingLayout:useLayout];
}


-(NSString *)resolutionDescription
{
    return [NSString stringWithFormat:@"%dx%d@%.2f", self.previewView.sourceLayout.canvas_width, self.previewView.sourceLayout.canvas_height, self.previewView.sourceLayout.frameRate];
}

+(NSSet *)keyPathsForValuesAffectingResolutionDescription
{
    return [NSSet setWithObjects:@"previewView.sourceLayout.canvas_height", @"previewView.sourceLayout.canvas_width", @"previewView.sourceLayout.frameRate", nil];
}


+(NSSet *)keyPathsForValuesAffectingWindowTitle
{
    return [NSSet setWithObjects:@"previewView.sourceLayout.name", nil];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"sourceLayout.recordingLayout"])
    {
        if (self.previewView.sourceLayout.recordingLayout)
        {
            [self.recordButton setState:1];
        } else {
            [self.recordButton setState:0];
        }
    }
    
    
    if ([keyPath isEqualToString:@"sourceLayout.recorder"])
    {
        
        self.previewView.sourceLayout.isActive = YES;
        if (self.previewView.sourceLayout.recorder)
        {
            self.multiAudioEngineViewController.viewOnly = NO;
            if (!self.previewView.sourceLayout.recorder.renderer)
            {
                self.previewView.sourceLayout.recorder.renderer = self.previewView.layoutRenderer;
            } else {
                self.previewView.layoutRenderer = self.previewView.sourceLayout.recorder.renderer;
            }
            
            [self.previewView disablePrimaryRender];
            if (!self.multiAudioEngine)
            {
                self.multiAudioEngine = self.previewView.sourceLayout.recorder.audioEngine;
            }
        } else {
            self.showAudioView = NO;
            [self.previewView enablePrimaryRender];
            if (!self.multiAudioEngine)
            {
                [self setupDummyAudioEngine];
            }
            self.multiAudioEngineViewController.viewOnly = YES;
        }


        
     } else if ([keyPath isEqualToString:@"mousedSource"]) {
        NSArray *useSrcs;
        if (self.previewView.mousedSource)
        {
            useSrcs = @[self.previewView.mousedSource];
        } else {
            useSrcs = @[];
        }
        [self.sourceListViewController highlightSources:useSrcs];
    } else if ([keyPath isEqualToString:@"selectedObjects"]) {
        [self.previewView stopHighlightingAllSources];
        for (NSObject <CSInputSourceProtocol> *src in self.sourceListViewController.selectedObjects)
        {
            [self.previewView highlightSource:src];
        }
    }
}


- (IBAction)recordButtonAction:(id)sender
{
    if (self.previewView.sourceLayout.recordingLayout)
    {
        [[CaptureController sharedCaptureController] stopRecordingLayout:self.previewView.sourceLayout];
    } else {
        [[CaptureController sharedCaptureController] startRecordingLayout:self.previewView.sourceLayout];
    }
}


@end
