//
//  CAMultiAudioInput.h
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioConverter.h"
#import "CAMultiAudioCompressor.h"
#import "CAMultiAudioSubgraph.h"


@protocol CAMultiAudioInputJSExport <JSExport>
@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) CAMultiAudioEqualizer *equalizer;

@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;
@property (assign) bool compressorBypass;


-(void)openMixerWindow:(id)sender;


@end


@interface CAMultiAudioInput : CAMultiAudioNode

@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) CAMultiAudioEqualizer *equalizer;
@property (strong) CAMultiAudioCompressor *dynamicCompressor;
@property (strong) CAMultiAudioNode *headNode;

@property (strong) CAMultiAudioConverter *converterNode;
@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;
@property (assign) bool compressorBypass;
@property (strong) CAMultiAudioSubgraph *subGraph;

-(void)didRemoveInput;
-(bool)teardownGraph;
-(bool)setupGraph;

@end
