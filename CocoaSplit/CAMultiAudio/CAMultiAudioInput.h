//
//  CAMultiAudioInput.h
//  CocoaSplit
//
//  Created by Zakk on 7/30/17.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioConverter.h"
#import "CAMultiAudioOutputTrack.h"

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
@property (strong) NSMutableDictionary *powerLevels;
@property (assign) NSInteger refCount;
@property (assign) bool isGlobal;


-(void)openMixerWindow:(id)sender;


@end


@interface CAMultiAudioInput : CAMultiAudioNode
{
}
@property (strong) CAMultiAudioMixer *downMixer;
@property (strong) CAMultiAudioDelay *stupidNode;
@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;
@property (assign) bool noSettings;
@property (assign) bool systemDevice;
@property (assign) float powerLevel;
@property (strong) NSMutableDictionary *powerLevels;

@property (assign) NSInteger refCount;
@property (assign) bool isGlobal;
@property (strong) NSMutableDictionary *outputTracks;
@property (strong) NSString *deviceUID;
@property (readonly) AVAudioFormat *inputFormat;


-(void)didRemoveInput;
-(bool)teardownGraph;
-(bool)setupGraph;
-(void)updatePowerlevel;
-(void)removeFromEngine;
-(void)addToOutputTrack:(CAMultiAudioOutputTrack *)trackName;
-(void)removeFromOutputTrack:(CAMultiAudioOutputTrack *)trackName;
-(void)didAttachInput;

@end
