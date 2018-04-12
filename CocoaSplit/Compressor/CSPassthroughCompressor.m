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
@synthesize usePixelFormat = _usePixelFormat;

-(instancetype)init
{
    if (self = [super init])
    {
        self.compressorType = @"Passthrough";
        self.copyFrame = YES;
        _pixelFormats = @{@"RGBA": @(kCVPixelFormatType_32RGBA),
                          @"ARGB": @(kCVPixelFormatType_32ARGB),
                          @"BGRA": @(kCVPixelFormatType_32BGRA),
                          @"422 YpCbCr8 (2vuy/UYVY)": @(kCVPixelFormatType_422YpCbCr8)
                          };
    }
    
    return self;
}


-(void)setUsePixelFormat:(NSNumber *)usePixelFormat
{
    
    _usePixelFormat = usePixelFormat;
}

-(NSNumber *)usePixelFormat
{
    return _usePixelFormat;
}
-(instancetype)copyWithZone:(NSZone *)zone
{
    CSPassthroughCompressor *newCompressor = [super copyWithZone:zone];
    newCompressor.usePixelFormat = self.usePixelFormat;
    newCompressor.copyFrame = self.copyFrame;
    return newCompressor;
}

-(NSDictionary *)pixelFormats
{
    return _pixelFormats;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.copyFrame forKey:@"copyFrame"];
    [aCoder encodeObject:self.usePixelFormat forKey:@"usePixelFormat"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.copyFrame = [aDecoder decodeBoolForKey:@"copyFrame"];
        self.usePixelFormat = [aDecoder decodeObjectForKey:@"usePixelFormat"];
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
        OSType useFormat = CVPixelBufferGetPixelFormatType(imageBuffer.videoFrame);
        if (self.usePixelFormat)
        {
            useFormat = (OSType)self.usePixelFormat.integerValue;
        }
        
        CVPixelBufferCreate(NULL, CVPixelBufferGetWidth(imageBuffer.videoFrame), CVPixelBufferGetHeight(imageBuffer.videoFrame), useFormat, NULL, &useFrame);
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
    
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, useFrame, &formatDesc);
    CMSampleBufferCreateReadyWithImageBuffer(NULL,useFrame, formatDesc, &timingInfo, &wrapperBuffer);

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
