//
//  AVFAudioChannel.m
//  CocoaSplit
//
//  Created by Zakk on 4/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "AVFAudioChannel.h"


@implementation AVFAudioChannel



-(id)init
{
    
    self = [super init];
    
    if (self)
    {
        self.slaveChannels = [[NSMutableArray alloc] init];
    }
    
    
    return self;
    
}



-(id)initWithMasterChannel:(AVCaptureAudioChannel *)masterChannel
{
    self = [self init];
    
    if (self)
    {
        self.masterChannel = masterChannel;
    }
    
    return self;
}



-(void)addSlaveChannel:(AVCaptureAudioChannel *)newChannel
{
    
    [self.slaveChannels addObject:newChannel];
    
}


-(double)volume
{
    return self.masterChannel.volume;
}


-(void) setVolume:(double)channelVolume
{
    self.masterChannel.volume = channelVolume;
    for (AVCaptureAudioChannel *slaveChannel in self.slaveChannels)
    {
        slaveChannel.volume = channelVolume;
    }
}

-(BOOL)enabled
{
    return self.masterChannel.enabled;
}

-(void)setEnabled:(BOOL)enabledValue
{
    self.masterChannel.enabled = enabledValue;
    for (AVCaptureAudioChannel *slaveChannel in self.slaveChannels)
    {
        slaveChannel.enabled = enabledValue;
    }
}



@end
