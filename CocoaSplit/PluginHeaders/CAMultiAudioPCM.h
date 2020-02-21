//
//  CAMultiAudioPCM.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>



//This class is used by the CAMultiAudioPCMPlayer class to store some submitted buffers for later free-ing.

@interface CAMultiAudioPCM : AVAudioPCMBuffer
{
    size_t _audioBufferListSize;
    size_t _audioBufferDataSize;
    bool _alloced_buffers;
    
}
@property (assign) ScheduledAudioSlice *audioSlice;



-(instancetype)initWithDescription:(const AudioStreamBasicDescription *)streamFormat forFrameCount:(int)forFrameCount;
-(void)copyFromAudioBufferList:(AudioBufferList *)copyFrom;




@end
