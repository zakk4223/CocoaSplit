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


@interface AppleVTCompressor : NSObject <h264Compressor>
{
    
    VTCompressionSessionRef _compression_session;
    
}
@property (strong) id<ControllerProtocol> settingsController;
@property (strong) id<ControllerProtocol> outputDelegate;

-(bool)compressFrame:(CVImageBufferRef)imageBuffer pts:(CMTime)pts duration:(CMTime)duration;
-(bool)setupCompressor;


@end
