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
    
    AppleVTCompressor *_appleh264;

}


-(bool)compressFrame:(CapturedFrameData *)frameData;
-(void) addAudioData:(CMSampleBufferRef)sampleBuffer;

@end
