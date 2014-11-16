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

@interface CAMultiAudioPCMPlayer : CAMultiAudioNode
{
    NSMutableArray *_pendingBuffers;
    
}


-(bool)playAudioBufferListASAP:(AudioBufferList *)audioBufferList;
-(void)releasePCM:(CAMultiAudioPCM *)buffer;
-(void)scheduleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)play;




@end
