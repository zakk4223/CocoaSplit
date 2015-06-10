//
//  CAMultiAudioDownmixer.h
//  CocoaSplit
//
//  Created by Zakk on 6/3/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioMixingProtocol.h"

@interface CAMultiAudioDownmixer : CAMultiAudioNode <CAMultiAudioMixingProtocol>
{
    int _inputChannels;
}

@property (assign) UInt32 inputChannelCount;
@property (assign) UInt32 outputChannelCount;

-(instancetype)initWithInputChannels:(int)channels;

-(void)setVolume:(float)volume forChannel:(UInt32)inChannel outChannel:(UInt32)outChannel;
-(Float32)getVolumeforChannel:(UInt32)inChannel outChannel:(UInt32)outChannel;

-(Float32 *)getMixerVolumes;

-(NSDictionary *)saveData;
-(void)restoreData:(NSDictionary *)saveData;


@end
