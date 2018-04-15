//
//  CAMultiAudioInput.h
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioConverter.h"
#import "CAMultiAudioSubgraph.h"


@protocol CAMultiAudioInputJSExport <JSExport>
@property (strong) CAMultiAudioDownmixer *downMixer;

@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;
@property (assign) bool compressorBypass;
@property (assign) float powerLevel;
@property (assign) NSInteger refCount;


-(void)openMixerWindow:(id)sender;


@end


@interface CAMultiAudioInput : CAMultiAudioNode
{
}
@property (strong) CAMultiAudioDownmixer *downMixer;

@property (strong) CAMultiAudioConverter *converterNode;
@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;
@property (strong) CAMultiAudioSubgraph *subGraph;
@property (assign) float powerLevel;
@property (assign) NSInteger refCount;

-(void)didRemoveInput;
-(bool)teardownGraph;
-(bool)setupGraph;
-(void)updatePowerlevel;
-(void)removeFromEngine;

@end
