//
//  CAMultiAudioInput.h
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@protocol CAMultiAudioInputJSExport <JSExport>
@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) CAMultiAudioEqualizer *equalizer;

@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;



-(void)openMixerWindow:(id)sender;

@end


@interface CAMultiAudioInput : CAMultiAudioNode

@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) CAMultiAudioEqualizer *equalizer;

@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;


@end
