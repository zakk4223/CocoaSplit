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
@class CAMultiAudioEqualizer;
@class CAMultiAudioEngine;

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
@property (assign) float volume;
@property (assign) bool muted;
@property (assign) bool enabled;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType;
-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer;

-(bool)createNode:(CAMultiAudioGraph *)forGraph;
-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus;
-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus;
-(void)willInitializeNode;
-(void)didInitializeNode;
-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format;
-(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format;

-(void)resetSamplerate:(UInt32)sampleRate;
-(void)resetFormat:(AudioStreamBasicDescription *)format;

-(void)setVolumeAnimated:(float)volume withDuration:(float)duration;
-(NSView *)audioUnitNSView;
-(void)saveDataToDict:(NSMutableDictionary *)saveDict;
-(void)restoreDataFromDict:(NSDictionary *)restoreDict;


@end

@interface CAMultiAudioNode : NSObject <CAMultiAudioNodeJSExport, NSAnimationDelegate>
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
@property (weak) CAMultiAudioEngine *engine;

@property (assign) UInt32 connectedToBus;
@property (strong) NSString *name;
@property (strong) NSString *nodeUID;
@property (weak) CAMultiAudioNode *headNode;
@property (weak) CAMultiAudioNode *effectsHead;
@property (strong) NSMutableArray *effectChain;
@property (assign) bool deleteNode;




@property (assign) float volume;
@property (assign) bool muted;

@property (assign) bool enabled;


-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType;
-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer NS_DESIGNATED_INITIALIZER;
-(void) willConnectToNode:(CAMultiAudioNode *)node;
-(void) connectedToNode:(CAMultiAudioNode *)node;
-(void)willRemoveNode;
-(void)setupEffectsChain;
-(void)removeEffectsChain;
-(void)addEffect:(CAMultiAudioNode *)effect;
-(void)addEffect:(CAMultiAudioNode *)effect atIndex:(NSUInteger)idx;


@end
