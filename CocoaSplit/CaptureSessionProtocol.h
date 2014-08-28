//
//  CaptureSessionProtocol.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AbstractCaptureDevice.h"
#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>





@protocol CaptureSessionProtocol <NSObject>

@required

@property AbstractCaptureDevice *activeVideoDevice;
@property (strong) NSArray *availableVideoDevices;






-(CVImageBufferRef) getCurrentFrame;




@optional
@property id activeAudioDevice;
-(void) setAudioDelegate:(id)delegate;
-(NSArray *) availableAudioDevices;
@property (assign) int audioBitrate;
@property (assign) int audioSamplerate;
@property (assign) float previewVolume;
@property (strong) NSString *captureName;

//This is mostly here so we can render text into a CGLayer/CIImage, but some sources may be smart and resize depending on what these values are.
//Less pixels == good
@property (assign) int render_width;
@property (assign) int render_height;
@property (strong) CIContext *imageContext;

@property (strong)     NSViewController *configViewController;

-(void)setupAudioCompression;
-(void)stopAudioCompression;
-(void)chooseDirectory:(id)sender;
-(CIImage *)currentImage;
-(NSView *)configurationView;



@end
