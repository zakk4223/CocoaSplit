//
//  PreviewView.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

#import "CaptureController.h"
#import "InputSource.h"
#import "LayoutRenderer.h"
#import "CSPreviewGLLayer.h"
#import "CSPreviewOverlayView.h"


@class SourceLayout;
//@class InputSource;

#define SNAP_THRESHOLD 10.0f




#define LAYOUT_RESOLUTIONS @[@"1280x720@60", @"1280x720@30", @"1920x1080@60", @"1920x1080@30", @"Custom"]


@interface PreviewView : NSView <NSPopoverDelegate, NSWindowDelegate>

{

    
    CSPreviewGLLayer *_glLayer;
    
    SourceLayout *_renderingLayout;

    
    NSRect _oldFrame;
    
    float _snap_x_accum, _snap_y_accum;
    float _snap_x, _snap_y;
    bool _in_resize_rect;
    
    NSTrackingArea *_trackingArea;

    
    
    
    id _fs_activity_token;
    
    NSScreen *_fullscreenOn;
    NSPopover *_layoutpopOver;
    CSPreviewOverlayView *_overlayView;
    bool _inDrag;
    
    
    

    

}

- (IBAction)toggleFullscreen:(id)sender;

- (IBAction)moveInputUp:(id)sender;
- (IBAction)moveInputDown:(id)sender;
- (IBAction)deleteInput:(id)sender;
- (IBAction)addInputSource:(id)sender;
- (IBAction)showInputSettings:(id)sender;


-(void)spawnInputSettings:(InputSource *)forInput atRect:(NSRect)atRect;
-(void)goFullscreen:(NSScreen *)onScreen;






@property (assign) bool viewOnly;

@property (strong) LayoutRenderer *layoutRenderer;

@property (strong) NSMenu *sourceSettingsMenu;




@property (strong) NSColor *statusColor;

@property (unsafe_unretained) IBOutlet CaptureController *controller;

@property (strong) InputSource *selectedSource;
@property (strong) InputSource *mousedSource;

@property (assign) NSPoint selectedOriginDistance;
@property (assign) bool isResizing;
@property (assign) resize_style resizeType;
@property (strong, atomic) SourceLayout *sourceLayout;
@property (strong) NSViewController *activePopupController;
@property (strong) NSMutableDictionary *activeConfigWindows;
@property (strong) NSMutableDictionary *activeConfigControllers;
@property (assign) bool isEditWindow;

-(void)needsUpdate;
-(NSRect)windowRectforWorldRect:(NSRect)worldRect;
-(NSArray *)resizeRectsForSource:(InputSource *)inputSource withExtra:(float)withExtra;





@end


