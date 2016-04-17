//
//  CSIRCompressor.h
//  CocoaSplit
//
//  Created by Zakk on 4/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CompressorBase.h"
#import "AppleVTCompressor.h"
@interface CSIRCompressor : CompressorBase <VideoCompressor, NSCoding>
{
    
    id<VideoCompressor> _compressor;

}


@property (assign) bool tryAppleHardware;
@property (assign) bool useAppleH264;
@property (assign) bool useAppleProRes;
@property (assign) bool usex264;
@property (assign) bool useNone;
@property (assign) int selectedCompressor;



-(bool)compressFrame:(CapturedFrameData *)frameData;
-(void) addAudioData:(CMSampleBufferRef)sampleBuffer;

@end
