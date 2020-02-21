//
//  CSPcmPlayer.h
//  CocoaSplit
//
//  Created by Zakk on 11/25/14.
//

#ifndef CocoaSplit_CSPcmPlayer_h
#define CocoaSplit_CSPcmPlayer_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "CAMultiAudioPCM.h"

@interface CSPcmPlayer : NSObject

@property (strong) NSString *name;
@property (strong) NSString *nodeUID;
@property (readonly) NSUInteger pendingFrames;
@property (assign) bool muted;

-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer;
-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer;
-(void)play;
-(void)pause;
-(void)flush;
-(void)setAudioFormat:(AVAudioFormat *)asbd;



@end

#endif
