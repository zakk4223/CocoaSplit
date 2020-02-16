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
{
    AVAudioFormat *_useFormat;
}

@property (strong) AVCaptureDevice *captureDevice;

@property (strong) AVFAudioCapture *avfCapture;
@property (assign) double sampleRate;
@property (readonly) AVAudioFormat *deviceFormat;


-(instancetype)initWithDevice:(AVCaptureDevice *)avDevice;

-(void)resetFormat:(AudioStreamBasicDescription *)format;

@end
