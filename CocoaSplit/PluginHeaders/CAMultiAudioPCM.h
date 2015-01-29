//
//  CAMultiAudioPCM.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>



//This class is used by the CAMultiAudioPCMPlayer class to store some submitted buffers for later free-ing.

@interface CAMultiAudioPCM : NSObject <NSCopying>
{
    size_t _audioBufferListSize;
    size_t _audioBufferDataSize;
    AudioBufferList *_pcmData;
    
}
@property (assign) ScheduledAudioSlice *audioSlice;
@property (assign) int bufferCount;
@property (assign) int frameCount;
@property (weak) id player;
@property (assign) AudioStreamBasicDescription pcmFormat;

-(instancetype)initWithAudioBufferList:(AudioBufferList *)bufferList streamFormat:(const AudioStreamBasicDescription *)streamFormat;
-(instancetype)initWithDescription:(const AudioStreamBasicDescription *)streamFormat forFrameCount:(int)forFrameCount;
-(void)copyFromAudioBufferList:(AudioBufferList *)copyFrom;




@end
