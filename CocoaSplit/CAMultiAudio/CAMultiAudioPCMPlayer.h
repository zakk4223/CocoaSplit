//
//  CAMultiAudioPCMPlayer.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>

#import "CAMultiAudioNode.h"
#import "CAMultiAudioPCM.h"
#import "CAMultiAudioInput.h"
#import "TPCircularBuffer.h"

struct cspcm_buffer_msg {
    
    TPCircularBuffer *tpBuffer;
    void *pcmObj;
    void *msgPtr;
};




@interface CAMultiAudioPCMPlayer : CAMultiAudioInput
{
    NSMutableArray *_pendingBuffers;
    dispatch_queue_t _pendingQueue;
    bool _playing;
    int _bufcnt;
    bool _exitPending;
    AVAudioConverter *_audioConverter;
    AVAudioFormat *_audioFormat;
    TPCircularBuffer _completedBuffer;
    bool _dataSeen;
}


@property (strong) NSString *inputUID;
@property (assign) Float64 latestScheduledTime;
@property (readonly) NSUInteger pendingFrames;
@property (nonatomic, copy) void (^completedBlock)(CAMultiAudioPCM *pcmBuffer);
@property (strong) NSMutableArray *pauseBuffer;
@property (assign) bool save_buffer;

-(instancetype)initWithAudioFormat:(AVAudioFormat *)format;


-(void)releasePCM:(CAMultiAudioPCM *)buffer;
-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)scheduleAudioBuffer:(AudioBufferList *)bufferList bufferFormat:(AudioStreamBasicDescription)bufferFormat;
-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer;



-(void)play;
-(void)pause;
-(void)flush;




@end
