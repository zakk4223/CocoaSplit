//
//  AppleVTCompressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureController.h"
#import "CompressorBase.h"

#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>

@interface AppleVTCompressor : CompressorBase <VideoCompressor, NSCoding>
{
    
    VTCompressionSessionRef _compression_session;
    VTPixelTransferSessionRef _vtpt_ref;
    bool _resetPending;
    

}


//@property (strong) id<ControllerProtocol> outputDelegate;

@property (assign) int average_bitrate;
@property (assign) int max_bitrate;
@property (assign) int keyframe_interval;
@property (strong) NSString *profile;
@property (assign) BOOL use_cbr;
@property (strong) NSArray *profiles;

@property (assign) bool noHardware;
@property (assign) bool forceHardware;


-(bool)compressFrame:(CapturedFrameData *)frameData;
+(bool)intelQSVAvailable;


@end
 