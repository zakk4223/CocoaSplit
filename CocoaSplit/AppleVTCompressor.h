//
//  AppleVTCompressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "h264Compressor.h"
#import "CaptureController.h"
#import "ControllerProtocol.h"

#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>

@interface AppleVTCompressor : NSObject <h264Compressor>
{
    
    VTCompressionSessionRef _compression_session;
    
}


@property (strong) id<ControllerProtocol> settingsController;
@property (strong) id<ControllerProtocol> outputDelegate;

-(bool)compressFrame:(CapturedFrameData *)frameData;
-(bool)setupCompressor;


@end
