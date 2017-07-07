//
//  CAMultiAudioNode.h
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <AppKit/AppKit.h>

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <JavaScriptCore/JavaScriptCore.h>


@class CAMultiAudioGraph;
@class CAMultiAudioDownmixer;
@class CAMultiAudioMatrixMixerWindowController;
@class CAMultiAudioDelay;
@class CAMultiAudioNode;

@interface CAMultiAudioVolumeAnimation : NSAnimation

@property (assign) float target_volume;
@property (assign) float original_volume;

@end

@protocol CAMultiAudioNodeJSExport <JSExport>
@property (assign) AUNode node;
@property (assign) AudioUnit audioUnit;
@property (assign) int channelCount;
@property (readonly) UInt32 inputElement;
@property (weak) CAMultiAudioGraph *graph;
@property (weak) CAMultiAudioNode *connectedTo;
@property (assign) UInt32 connectedToBus;
@property (strong) NSString *name;
@property (strong) NSString *nodeUID;
@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) NSMutableArray *delayNodes;
@property (strong) NSColor *nameColor;
@property (assign) float volume;
@property (assign) bool muted;
@property (assign) bool enabled;
@property (assign) Float32 powerLevel;
@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType;

-(bool)createNode:(AUGraph)forGraph;
-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus;
-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus;
-(void)willInitializeNode;
-(void)didInitializeNode;
-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format;
-(void)setOutputStreamFormat:(AudioStreamBasicDescription *)format;

-(void)resetSamplerate:(UInt32)sampleRate;
-(void)resetFormat:(AudioStreamBasicDescription *)format;

-(void)updatePowerlevel;
-(void)setVolumeOnConnectedNode;

-(void)openMixerWindow:(id)sender;
-(void)setVolumeAnimated:(float)volume withDuration:(float)duration;

@end

@interface CAMultiAudioNode : NSObject <CAMultiAudioNodeJSExport, NSAnimationDelegate, NSPasteboardItemDataProvider>
{
    float _saved_volume;
    
    AudioComponentDescription unitDescr;
    CAMultiAudioVolumeAnimation *_volumeAnimation;
}

@property (assign) AUNode node;
@property (assign) AudioUnit audioUnit;
@property (assign) int channelCount;
@property (readonly) UInt32 inputElement;
@property (weak) CAMultiAudioGraph *graph;
@property (weak) CAMultiAudioNode *connectedTo;
@property (assign) UInt32 connectedToBus;
@property (strong) NSString *name;
@property (strong) NSString *nodeUID;

@property (strong) CAMultiAudioDownmixer *downMixer;
@property (strong) NSMutableArray *delayNodes;


//There really has to be a better way to do something like this
@property (strong) NSColor *nameColor;

@property (assign) float volume;
@property (assign) bool muted;

@property (assign) bool enabled;
@property (assign) Float32 powerLevel;

@property (strong) CAMultiAudioMatrixMixerWindowController *mixerWindow;
@property (assign) Float32 delay;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType NS_DESIGNATED_INITIALIZER;



@end
