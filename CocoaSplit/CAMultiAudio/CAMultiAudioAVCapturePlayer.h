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

@property (strong) AVCaptureDevice *captureDevice;

@property (strong) AVFAudioCapture *avfCapture;
@property (assign) int sampleRate;

-(instancetype)initWithDevice:(AVCaptureDevice *)avDevice withFormat:(AudioStreamBasicDescription *)withFormat;

-(void)resetFormat:(AudioStreamBasicDescription *)format;
-(const AudioStreamBasicDescription *)deviceAudioDescription;


@end
