//
//  AppleVTCompressorBase.m
//  CocoaSplit
//
//  Created by Zakk on 12/25/17.
//

#import "AppleVTCompressorBase.h"

#import "OutputDestination.h"
#import "CSAppleH264CompressorViewController.h"
#import "CSPluginServices.h"


OSStatus VTCompressionSessionCopySupportedPropertyDictionary(VTCompressionSessionRef, CFDictionaryRef *);



@implementation AppleVTCompressorBase


- (id)copyWithZone:(NSZone *)zone
{
    
    AppleVTCompressorBase *copy = [super copyWithZone:zone];

    copy.isNew = self.isNew;
    copy.name = self.name;
    copy.compressorType = self.compressorType;
    copy.width = self.width;
    copy.height = self.height;
    copy.working_width = self.width;
    copy.working_height = self.height;
    
    copy.resolutionOption = self.resolutionOption;
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [super encodeWithCoder:aCoder];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.width = (int)[aDecoder decodeIntegerForKey:@"videoWidth"];
        self.height = (int)[aDecoder decodeIntegerForKey:@"videoHeight"];
        
        if ([aDecoder containsValueForKey:@"resolutionOption"])
        {
            self.resolutionOption = [aDecoder decodeObjectForKey:@"resolutionOption"];
        }
        
        
    }
    
    return self;
}


-(NSMutableDictionary *)encoderSpec
{
    return [NSMutableDictionary dictionary];
}


-(id)init
{
    if (self = [super init])
    {
        
        
        
        self.compressorType = @"Apple VideoToolBox";
        
        _compression_session = NULL;
        
        _compressor_queue = dispatch_queue_create("Apple VT Compressor Queue", 0);
    }
    
    return self;
}





-(void) internal_reset
{
    
    _resetPending = YES;
    self.errored = NO;
    
    
    if (_compression_session)
    {
        VTCompressionSessionCompleteFrames(_compression_session, CMTimeMake(0, 0));
        VTCompressionSessionInvalidate(_compression_session);
        CFRelease(_compression_session);
    }
    
    
    if (_vtpt_ref)
    {
        VTPixelTransferSessionInvalidate(_vtpt_ref);
        CFRelease(_vtpt_ref);
    }
    
    _vtpt_ref = NULL;
    _compression_session = NULL;
    _resetPending = NO;
}


- (void) dealloc
{
    [self reset];
}

void PixelBufferRelease( void *releaseRefCon, const void *baseAddress )
{
    free((int *)baseAddress);
}


-(bool)real_compressFrame:(CapturedFrameData *)frameData
{
    
    if (_resetPending)
    {
        return NO;
    }
    
    
    if (![self hasOutputs])
    {
        return NO;
    }
    
    
    
    
    if (!_compression_session)
    {
        
        if (![self setupCompressor:frameData])
        {
            return NO;
        }
        return NO;
    }

    CFMutableDictionaryRef frameProperties;
    
    /*
     if (isKeyFrame)
     {
     
     frameProperties = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
     CFDictionaryAddValue(frameProperties, kVTEncodeFrameOptionKey_ForceKeyFrame, kCFBooleanTrue);
     } else {
     */
    frameProperties = NULL;
    //}
    
    /*
    if (!_vtpt_ref)
    {
        VTPixelTransferSessionCreate(kCFAllocatorDefault, &_vtpt_ref);
        VTSessionSetProperty(_vtpt_ref, kVTPixelTransferPropertyKey_ScalingMode, kVTScalingMode_Letterbox);
        VTSessionSetProperty(_vtpt_ref, kVTPixelTransferPropertyKey_RealTime, kCFBooleanTrue);
    }
    CVPixelBufferRef converted_frame;
    
    CVImageBufferRef imageBuffer = frameData.videoFrame;
    CVPixelBufferRetain(imageBuffer);
    
    CVPixelBufferPoolRef vtPixelPool = VTCompressionSessionGetPixelBufferPool(_compression_session);
    CVPixelBufferPoolCreatePixelBuffer(NULL, vtPixelPool, &converted_frame);
    
    //CVPixelBufferCreate(kCFAllocatorDefault, self.working_width, self.working_height, kCVPixelFormatType_422YpCbCr8, 0, &converted_frame);
    
    VTPixelTransferSessionTransferImage(_vtpt_ref, imageBuffer, converted_frame);
    */
    
    //set it to nil since this is our private copy and this will force the frameData instance to release the video data
    
    //frameData.videoFrame = nil;
    //frameData.encoderData = converted_frame;
    
    
    //CVPixelBufferRelease(imageBuffer);
    
    VTCompressionSessionEncodeFrame(_compression_session, frameData.videoFrame, frameData.videoPTS, frameData.videoDuration, frameProperties, (__bridge_retained void *)(frameData), NULL);
    if (frameProperties)
    {
        CFRelease(frameProperties);
    }
    
    
    return YES;
}



-(bool)needsSetup
{
    return !_compression_session;
}


- (bool)setupCompressor:(CapturedFrameData *)videoFrame
{
    OSStatus status;
    
    
    [self setupResolution:videoFrame.videoFrame];
    
    if (!self.working_height || !self.working_width)
    {
        self.errored = YES;
        return NO;
    }
    
    
    
    NSMutableDictionary *encoderSpec = [self encoderSpec];
    
    
    _compression_session = NULL;

    
    status = VTCompressionSessionCreate(NULL, self.working_width, self.working_height, self.codecType, (__bridge CFDictionaryRef)encoderSpec, NULL, NULL, VideoCompressorReceiveFrame,  (__bridge void *)self, &_compression_session);
    
    if (status != noErr || !_compression_session)
    {
        self.errored = YES;
        return NO;
    }
    

    CFDictionaryRef sessionProperties = NULL;
    
    VTSessionCopySupportedPropertyDictionary(_compression_session, &sessionProperties);
    

    Float64 durationSecs = CMTimeGetSeconds(videoFrame.videoDuration);
    
    if (durationSecs > 0)
    {
        double captureFPS = 1.0f/durationSecs;
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)(@(captureFPS)));
    }
    
    CFMutableDictionaryRef transferProps = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(transferProps, kVTPixelTransferPropertyKey_ScalingMode, kVTScalingMode_Letterbox);
    CFDictionarySetValue(transferProps, kVTPixelTransferPropertyKey_DestinationTransferFunction, kCVImageBufferTransferFunction_ITU_R_709_2);
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_PixelTransferProperties, transferProps);
    CFRelease(transferProps);
    
    [self configureCompressionSession:_compression_session];
    
    
    _audioBuffer = [[NSMutableArray alloc] init];
    return YES;
    
}


-(void)configureCompressionSession:(VTCompressionSessionRef)session
{
    return;
}


void VideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    
    /*
     if (VTFrameRef)
     {
     CVPixelBufferRelease(VTFrameRef);
     }
     */
    
    
    //@autoreleasepool {
    
    
    if(!sampleBuffer)
        return;
    
    
    
    CFRetain(sampleBuffer);
    
    CapturedFrameData *frameData;
    
    
    frameData = (__bridge_transfer CapturedFrameData *)(VTFrameRef);
    
    
    if (!frameData)
    {
        //What?
        return;
    }
    
    
    //CVPixelBufferRelease(frameData.videoFrame);
    frameData.videoFrame = nil;
    
    
    //frameData.videoFrame = nil;
    frameData.encodedSampleBuffer = sampleBuffer;
    CFArrayRef sample_attachments;
    sample_attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, NO);
    if (sample_attachments)
    {
        CFDictionaryRef attach;
        CFBooleanRef depends_on_others;
        
        attach = CFArrayGetValueAtIndex(sample_attachments, 0);
        depends_on_others = CFDictionaryGetValue(attach, kCMSampleAttachmentKey_DependsOnOthers);
        frameData.isKeyFrame = !CFBooleanGetValue(depends_on_others);
    }
    
    
    AppleVTCompressor *selfobj = (__bridge AppleVTCompressor *)VTref;
    
    
    
    
    for (id dKey in selfobj.outputs)
    {
        
        OutputDestination *dest = selfobj.outputs[dKey];
        
        [dest writeEncodedData:frameData];
        
        
    }
    
    
    CFRelease(sampleBuffer);
    //}
}

-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return nil;
}


@end


