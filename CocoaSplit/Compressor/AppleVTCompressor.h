//
//  AppleVTCompressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//

#import <Foundation/Foundation.h>
#import "CaptureController.h"
#import "CompressorBase.h"
#import "AppleVTCompressorBase.h"

#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>

@interface AppleVTCompressor : AppleVTCompressorBase <VideoCompressor, NSCoding>
{

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


+(bool)intelQSVAvailable;


@end
 
