//
//  CSPcmPlayer.h
//  CocoaSplit
//
//  Created by Zakk on 11/25/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#ifndef CocoaSplit_CSPcmPlayer_h
#define CocoaSplit_CSPcmPlayer_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

#import "CAMultiAudioPCM.h"

@interface CSPcmPlayer : NSObject

@property (strong) NSString *name;
@property (strong) NSString *nodeUID;

-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer;
-(bool)playPcmBuffer:(CAMultiAudioPCM *)pcmBuffer;


@end

#endif
