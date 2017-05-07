//
//  CAMultiAudioMatrixMixerWindowController.h
//  CocoaSplit
//
//  Created by Zakk on 6/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CAMultiAudioDownmixer.h"

@interface CAMultiAudioMatrixMixerWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *matrixTable;
@property (strong) CAMultiAudioDownmixer *audioNode;
@property (assign) UInt32 matrixRows;
@property (assign) UInt32 matrixColumns;

- (IBAction)matrixVolumeChanged:(NSSlider *)sender;

-(instancetype)initWithAudioMixer:(CAMultiAudioDownmixer *)node;

@end
