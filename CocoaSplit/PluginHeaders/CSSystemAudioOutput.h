//
//  CSSystemAudioOutput.h
//  CocoaSplit
//
//  Created by Zakk on 5/22/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#ifndef CSSystemAudioOutput_h
#define CSSystemAudioOutput_h

#import <CoreMedia/CoreMedia.h>
#import "CSSystemAudioNode.h"
#import <AVFoundation/AVFoundation.h>

@interface CSSystemAudioOutput : NSObject

-(instancetype)initWithAudioFormat:(AVAudioFormat *)audioFormat withOutputNode:(CSSystemAudioNode *)outputNode;
-(void)playSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)start;
-(void)stop;
@end
#endif /* CSSystemAudioOutput_h */
