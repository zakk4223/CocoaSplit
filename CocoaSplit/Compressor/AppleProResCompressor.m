//
//  AppleProResCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 3/27/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "AppleProResCompressor.h"
#import "OutputDestination.h"
#import "CSAppleProResCompressorViewController.h"

@implementation AppleProResCompressor

- (id)copyWithZone:(NSZone *)zone
{
    AppleProResCompressor *copy = [[[self class] allocWithZone:zone] init];
    
    copy.settingsController = self.settingsController;
    
    copy.isNew = self.isNew;
    
    copy.name = self.name;
    
    copy.compressorType = self.compressorType;
    
    copy.width = self.width;
    copy.height = self.height;
    copy.working_width = self.width;
    copy.working_height = self.height;
    
    copy.resolutionOption = self.resolutionOption;
    
    copy.proResType = self.proResType;
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.width forKey:@"videoWidth"];
    [aCoder encodeInteger:self.height forKey:@"videoHeight"];
    
    [aCoder encodeObject:self.resolutionOption forKey:@"resolutionOption"];
    [aCoder encodeObject:self.proResType forKey:@"proResType"];
    
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
        
        self.proResType = [aDecoder decodeObjectForKey:@"proResType"];
 
        if (!self.proResType)
        {
            self.proResType = @(kCMVideoCodecType_AppleProRes422);

        }
        
    }
    
    return self;
}


-(id)init
{
    if (self = [super init])
    {
        
        
        
        self.compressorType = @"AppleProResCompressor";
        self.codec_id = AV_CODEC_ID_PRORES;
        self.proResType = @(kCMVideoCodecType_AppleProRes422);
    }
    
    return self;
}


-(void) reset
{
    
    
    self.errored = NO;
    VTCompressionSessionInvalidate(_compression_session);
    if (_compression_session)
    {
        CFRelease(_compression_session);
    }
    
    _compression_session = nil;
    
}



- (void) dealloc
{
    [self reset];
}



-(NSString *)description
{
    
    return @"Apple ProRes Compressor";
    
}


void __ProResPixelBufferRelease( void *releaseRefCon, const void *baseAddress )
{
    free((int *)baseAddress);
}



-(bool)compressFrame:(CapturedFrameData *)frameData
{
    
    
    if (![self hasOutputs])
    {
        return NO;
    }
    
    if (!_compression_session)
    {
        
        if (![self setupCompressor:frameData.videoFrame])
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
    
    if (!_vtpt_ref)
    {
        VTPixelTransferSessionCreate(kCFAllocatorDefault, &_vtpt_ref);
        VTSessionSetProperty(_vtpt_ref, kVTPixelTransferPropertyKey_ScalingMode, kVTScalingMode_Letterbox);
    }
    CVPixelBufferRef converted_frame;
    
    CVImageBufferRef imageBuffer = frameData.videoFrame;
    CVPixelBufferRetain(imageBuffer);
    
    CVPixelBufferCreate(kCFAllocatorDefault, self.working_width, self.working_height, kCVPixelFormatType_420YpCbCr8Planar, 0, &converted_frame);
    
    VTPixelTransferSessionTransferImage(_vtpt_ref, imageBuffer, converted_frame);
    
    //set it to nil since this is our private copy and this will force the frameData instance to release the video data
    
    frameData.videoFrame = nil;
    frameData.encoderData = converted_frame;
    
    
    CVPixelBufferRelease(imageBuffer);
    
    [self setAudioData:frameData syncObj:self];
    
    VTCompressionSessionEncodeFrame(_compression_session, converted_frame, frameData.videoPTS, frameData.videoDuration, frameProperties, (__bridge_retained void *)(frameData), NULL);
    
    if (frameProperties)
    {
        CFRelease(frameProperties);
    }
    
    
    return YES;
}




- (bool)setupCompressor:(CVPixelBufferRef)videoFrame
{
    OSStatus status;
    
    if (!self.settingsController)
    {
        return NO;
    }
    
    [self setupResolution:videoFrame];
    
    if (!self.working_height || !self.working_width)
    {
        self.errored = YES;
        return NO;
    }
    
    NSDictionary *encoderSpec = @{
                                                                    };
    
    _compression_session = NULL;
    
    status = VTCompressionSessionCreate(NULL, self.working_width, self.working_height, self.proResType.intValue, (__bridge CFDictionaryRef)encoderSpec, NULL, NULL, __ProResVideoCompressorReceiveFrame,  (__bridge void *)self, &_compression_session);
    
    //CFDictionaryRef props;
    //VTCompressionSessionCopySupportedPropertyDictionary(_compression_session, &props);
    
    if (status != noErr || !_compression_session)
    {
        NSLog(@"COMPRESSOR SETUP ERROR");
        self.errored = YES;
        return NO;
    }
    
    _audioBuffer = [[NSMutableArray alloc] init];
    return YES;
    
}


void __ProResVideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
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
    
    
    CVPixelBufferRelease(frameData.encoderData);
    
    
    //frameData.videoFrame = nil;
    frameData.encodedSampleBuffer = sampleBuffer;
    
    
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
    return [[CSAppleProResCompressorViewController alloc] init];
}


@end
