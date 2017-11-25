//
//  CSFFMpegCaptureViewController.h
//  CSFFMpegCapturePlugin
//
//  Created by Zakk on 6/14/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSFFMpegCapture.h"

@interface CSFFMpegCaptureViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>

@property (weak) CSFFMpegCapture *captureObj;
@property (weak) IBOutlet NSSegmentedControl *playlistControl;
@property (strong) IBOutlet NSArrayController *queueArrayController;
@property (strong) NSString *stringItem;


- (IBAction)queueTableDoubleClick:(NSTableView *)sender;

- (IBAction)chooseFile:(id)sender;
- (IBAction)sliderValueChanged:(id)sender;

- (IBAction)tableControlAction:(NSSegmentedControl *)sender;
- (IBAction)manualAddItem:(id)sender;
@property (weak) IBOutlet NSTableView *queueTableView;

@end
