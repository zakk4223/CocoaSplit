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
    dispatch_source_t _pendingTimer;
    
    bool _playing;
    bool _exitPending;
    
    TPCircularBuffer _completedBuffer;
    
    
    
}

@property (strong) NSString *inputUID;
@property (readonly) NSUInteger pendingFrames;
@property (nonatomic, copy) void (^completedBlock)(CAMultiAudioPCM *pcmBuffer);
@property (strong) NSMutableArray *pauseBuffer;
@property (assign) bool save_buffer;

-(void)releasePCM:(CAMultiAudioPCM *)buffer;
-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer;
-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer;


-(void)play;
-(void)pause;
-(void)flush;




@end
