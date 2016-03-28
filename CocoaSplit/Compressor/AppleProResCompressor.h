//
//  AppleProResCompressor.h
//  CocoaSplit
//
//  Created by Zakk on 3/27/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureController.h"
#import "CompressorBase.h"

#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>

@interface AppleProResCompressor : CompressorBase <VideoCompressor, NSCoding>
{
    
    VTCompressionSessionRef _compression_session;
    VTPixelTransferSessionRef _vtpt_ref;
    
}


//@property (strong) id<ControllerProtocol> settingsController;
//@property (strong) id<ControllerProtocol> outputDelegate;

@property (strong) NSNumber *proResType;


-(bool)compressFrame:(CapturedFrameData *)frameData;

@end
