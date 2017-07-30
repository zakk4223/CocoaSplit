//
//  CAMultiAudioMatrixMixerWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CAMultiAudioDownmixer.h"
#import "CAMultiAudioInput.h"

@interface CAMultiAudioMatrixMixerWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *matrixTable;
@property (strong) CAMultiAudioInput *audioNode;
@property (strong) CAMultiAudioDownmixer *downMixer;
@property (assign) UInt32 matrixRows;
@property (assign) UInt32 matrixColumns;
@property (strong) NSWindow *eqWindow;

- (IBAction)matrixVolumeChanged:(NSSlider *)sender;

-(instancetype)initWithAudioMixer:(CAMultiAudioNode *)node;
- (IBAction)openEQWindow:(id)sender;

@end
