//
//  CSPassthroughCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 1/21/18.
//

#import "CSPassthroughCompressor.h"
#import "OutputDestination.h"

@implementation CSPassthroughCompressor


-(instancetype)init
{
    if (self = [super init])
    {
        self.compressorType = @"Passthrough";
    }
    
    return self;
}


-(bool)compressFrame:(CapturedFrameData *)imageBuffer
{

    CMSampleBufferRef wrapperBuffer;
    CMFormatDescriptionRef formatDesc;
    CMSampleTimingInfo timingInfo;

    timingInfo.duration = imageBuffer.videoDuration;
    timingInfo.decodeTimeStamp = imageBuffer.videoPTS;
    timingInfo.presentationTimeStamp = timingInfo.decodeTimeStamp;
    
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, imageBuffer.videoFrame, &formatDesc);
    CMSampleBufferCreateReadyWithImageBuffer(NULL, imageBuffer.videoFrame, formatDesc, &timingInfo, &wrapperBuffer);

    imageBuffer.encodedSampleBuffer = wrapperBuffer;
    
    CFRelease(formatDesc);
    CFRelease(wrapperBuffer);
    
    for (id dKey in self.outputs)
    {
        OutputDestination *dest = self.outputs[dKey];
        [dest writeEncodedData:imageBuffer];
        
    }
    return YES;
}
@end
