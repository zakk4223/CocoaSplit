//
//  CSPassthroughCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 1/21/18.
//

#import "CSPassthroughCompressor.h"
#import "OutputDestination.h"
#import "CSPassthroughCompressorViewController.h"

@implementation CSPassthroughCompressor


-(instancetype)init
{
    if (self = [super init])
    {
        self.compressorType = @"Passthrough";
        self.copyFrame = YES;
    }
    
    return self;
}



-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeBool:self.copyFrame forKey:@"copyFrame"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.copyFrame = [aDecoder decodeBoolForKey:@"copyFrame"];
    }
    
    return self;
}


-(bool)compressFrame:(CapturedFrameData *)imageBuffer
{

    bool doCopy;
    
    @synchronized(self)
    {
        doCopy = self.copyFrame;
    }
    
    CVPixelBufferRef useFrame;

    if (doCopy)
    {
        if (!_pvt_ref)
        {
            VTPixelTransferSessionCreate(NULL, &_pvt_ref);
        }
        CVPixelBufferCreate(NULL, CVPixelBufferGetWidth(imageBuffer.videoFrame), CVPixelBufferGetHeight(imageBuffer.videoFrame), CVPixelBufferGetPixelFormatType(imageBuffer.videoFrame), NULL, &useFrame);
        VTPixelTransferSessionTransferImage(_pvt_ref, imageBuffer.videoFrame, useFrame);
    } else {
        useFrame = imageBuffer.videoFrame;
    }
    
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
    if (doCopy)
    {
        CVPixelBufferRelease(useFrame);
    }
    
    for (id dKey in self.outputs)
    {
        OutputDestination *dest = self.outputs[dKey];
        [dest writeEncodedData:imageBuffer];
        
    }
    return YES;
}

-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return [[CSPassthroughCompressorViewController alloc] init];
}


@end
