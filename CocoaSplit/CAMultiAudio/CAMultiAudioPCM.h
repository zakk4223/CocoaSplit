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

@interface CAMultiAudioPCM : NSObject
@property (assign) ScheduledAudioSlice *audioSlice;
@property (weak) id player;


-(instancetype)initWithAudioBufferList:(AudioBufferList *)bufferList streamFormat:(AudioStreamBasicDescription *)streamFormat;




@end
