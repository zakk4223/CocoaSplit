//
//  CSPassthroughCompressor.h
//  CocoaSplit
//
//  Created by Zakk on 1/21/18.
//

#import "CompressorBase.h"
#import <VideoToolbox/VideoToolbox.h>

@interface CSPassthroughCompressor : CompressorBase
{
    VTPixelTransferSessionRef _pvt_ref;
    NSDictionary *_pixelFormats;
    
}

@property (assign) bool copyFrame;
@property (strong) NSNumber *usePixelFormat;
@property (readonly) NSDictionary *pixelFormats;
@end
