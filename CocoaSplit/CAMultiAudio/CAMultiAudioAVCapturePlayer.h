//
//  CAMultiAudioAVCapturePlayer.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioPCMPlayer.h"
#import "AVFAudioCapture.h"

@interface CAMultiAudioAVCapturePlayer : CAMultiAudioPCMPlayer



@property (strong) AVFAudioCapture *avfCapture;

-(instancetype)initWithDevice:(AVCaptureDevice *)avDevice sampleRate:(int)sampleRate;



@end
