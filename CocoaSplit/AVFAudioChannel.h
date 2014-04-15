//
//  AVFAudioChannel.h
//  CocoaSplit
//
//  Created by Zakk on 4/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@interface AVFAudioChannel : NSObject

@property (strong) AVCaptureAudioChannel *masterChannel;
@property (strong) NSMutableArray *slaveChannels;


-(id)initWithMasterChannel:(AVCaptureAudioChannel *)masterChannel;
-(void)addSlaveChannel:(AVCaptureAudioChannel *)newChannel;

-(double)volume;
-(void)setVolume:(double)channelVolume;

-(BOOL)enabled;
-(void)setEnabled:(BOOL)enabledValue;



@end
