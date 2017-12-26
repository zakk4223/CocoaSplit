//
//  AppleVTCompressorBase.h
//  CocoaSplit
//
//  Created by Zakk on 12/25/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CompressorBase.h"
#import <VideoToolbox/VideoToolbox.h>
#import <VideoToolbox/VTVideoEncoderList.h>


@interface AppleVTCompressorBase : CompressorBase
{
    VTCompressionSessionRef _compression_session;
    VTPixelTransferSessionRef _vtpt_ref;

    dispatch_queue_t _compressor_queue;
    bool _resetPending;

}

-(NSMutableDictionary *)encoderSpec;
-(void)configureCompressionSession:(VTCompressionSessionRef)session;

@property (readonly) CMVideoCodecType codecType;

@end
