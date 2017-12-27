//
//  AppleProResCompressor.h
//  CocoaSplit
//
//  Created by Zakk on 3/27/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureController.h"
#import "AppleVTCompressorBase.h"

#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>

@interface AppleProResCompressor : AppleVTCompressorBase <VideoCompressor, NSCoding>
{

    
}


//@property (strong) id<ControllerProtocol> outputDelegate;

@property (strong) NSNumber *proResType;



@end
