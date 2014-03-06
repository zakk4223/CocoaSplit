//
//  h264Compressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "FFMpegTask.h"
#import "ControllerProtocol.h"
#import "CapturedFrameData.h"


@class CaptureController;

@protocol h264Compressor <NSObject>

//compressFrame is expected to be non-blocking. Create a serial dispatch queue if the underlying compressor
//is blocking
//-(bool)compressFrame:(CVImageBufferRef)imageBuffer pts:(CMTime)pts duration:(CMTime)duration isKeyFrame:(BOOL)isKeyFrame;

-(bool)compressFrame:(CapturedFrameData *)imageBuffer isKeyFrame:(BOOL)isKeyFrame;


-(bool)setupCompressor;


@property (strong) id<ControllerProtocol> settingsController;
@property (strong) id<ControllerProtocol> outputDelegate;





@end
