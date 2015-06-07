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

@class CAMultiAudioGraph;


@interface CAMultiAudioNode : NSObject
{
    float _saved_volume;
    
    AudioComponentDescription unitDescr;
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

//There really has to be a better way to do something like this
@property (strong) NSColor *nameColor;

@property (assign) float volume;
@property (assign) bool muted;

@property (assign) bool enabled;
@property (assign) Float32 powerLevel;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType;

-(bool)createNode:(AUGraph)forGraph;
-(void)nodeConnected:(CAMultiAudioNode *)toNode onBus:(UInt32)onBus;
-(void)willConnectNode:(CAMultiAudioNode *)node toBus:(UInt32)toBus;
-(void)willInitializeNode;
-(void)didInitializeNode;
-(void)setInputStreamFormat:(AudioStreamBasicDescription *)format;
-(void)setOutputStreamFormat:(AudioStreamBasicDescription *)format;

-(void)resetSamplerate:(UInt32)sampleRate;
-(void)updatePowerlevel;
-(void)setVolumeOnConnectedNode;


@end
