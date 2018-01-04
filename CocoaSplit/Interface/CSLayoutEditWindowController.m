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
    [self.previewView addObserver:self forKeyPath:@"mousedSource" options:NSKeyValueObservingOptionNew context:NULL];
    [self.sourceListViewController addObserver:self forKeyPath:@"selectedObjects" options:NSKeyValueObservingOptionNew context:NULL];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


-(NSString *)windowTitle
{
    return [NSString stringWithFormat:@"Layout - %@", self.previewView.sourceLayout.name];
}


-(void)windowWillClose:(NSNotification *)notification
{
    [self.sourceListViewController removeObserver:self forKeyPath:@"selectedObjects"];

    [self.previewView removeObserver:self forKeyPath:@"sourceLayout.recorder"];
    [self.previewView removeObserver:self forKeyPath:@"mousedSource"];

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
        [self.previewView.sourceLayout clearSourceList];
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
    if ([keyPath isEqualToString:@"sourceLayout.recorder"])
    {
        if (self.previewView.sourceLayout.recorder)
        {
            [self.previewView disablePrimaryRender];
        } else {
            [self.previewView enablePrimaryRender];
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


@end
