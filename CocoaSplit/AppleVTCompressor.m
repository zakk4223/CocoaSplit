//
//  AppleVTCompressor.m
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "AppleVTCompressor.h"

OSStatus VTCompressionSessionCopySupportedPropertyDictionary(VTCompressionSessionRef, CFDictionaryRef *);



@implementation AppleVTCompressor



- (void) dealloc
{
    NSLog(@"VTCompressor Dealloc");
    VTCompressionSessionInvalidate(_compression_session);
    if (_compression_session)
    {
        CFRelease(_compression_session);
    }
    
    _compression_session = nil;
}


void PixelBufferRelease( void *releaseRefCon, const void *baseAddress )
{
    free((int *)baseAddress);
}



//- (bool)compressFrame:(CVImageBufferRef)imageBuffer pts:(CMTime)pts duration:(CMTime)duration isKeyFrame:(BOOL)isKeyFrame
-(bool)compressFrame:(CapturedFrameData *)frameData isKeyFrame:(BOOL)isKeyFrame
{
    
    
    
    if (!_compression_session)
    {
        
        if (![self setupCompressor])
        {
            //CVPixelBufferRelease(imageBuffer);
            return NO;
        }
        return NO;
    }
    
    
    CFMutableDictionaryRef frameProperties;
    
    if (isKeyFrame)
    {
    
        frameProperties = CFDictionaryCreateMutable(NULL, 0, &kCFCopyStringDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        CFDictionaryAddValue(frameProperties, kVTEncodeFrameOptionKey_ForceKeyFrame, kCFBooleanTrue);
    } else {
        frameProperties = NULL;
    }
    
    
    VTCompressionSessionEncodeFrame(_compression_session, frameData.videoFrame, frameData.videoPTS, frameData.videoDuration, frameProperties, (__bridge_retained void *)(frameData), NULL);
    
    if (frameProperties)
    {
        CFRelease(frameProperties);
    }
    
    
    return YES;
}




- (bool)setupCompressor
{
    OSStatus status;
    
    if (!self.settingsController)
    {
        return NO;
    }

    if (!self.settingsController.captureHeight || !self.settingsController.captureHeight)
    {
        return NO;
    }
    
	NSDictionary *encoderSpec = @{
		(__bridge NSString *)kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: @YES,
	};
	
    _compression_session = NULL;
    status = VTCompressionSessionCreate(NULL, self.settingsController.captureWidth, self.settingsController.captureHeight, kCMVideoCodecType_H264, (__bridge CFDictionaryRef)encoderSpec, NULL, NULL, VideoCompressorReceiveFrame,  (__bridge void *)self, &_compression_session);
    
    CFDictionaryRef props;
    VTCompressionSessionCopySupportedPropertyDictionary(_compression_session, &props);
    
    NSLog(@"SUPPORTED PROPERTIES %@", props);
    if (status != noErr || !_compression_session)
    {
        return NO;
    }
	
	CFRelease(props);
    
    //If priority isn't set to -20 the framerate in the SPS/VUI section locks to 25. With -20 it takes on the value of
    //whatever ExpectedFrameRate is. I have no idea what the fuck, but it works.
    
    //VTSessionSetProperty(_compression_session, (CFStringRef)@"Priority", (__bridge CFTypeRef)(@-20));
    
    
	NSDictionary *transferSpec = @{
		(__bridge NSString *)kVTPixelTransferPropertyKey_ScalingMode: (__bridge NSString *)kVTScalingMode_Letterbox,
	};
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_PixelTransferProperties, (__bridge CFTypeRef)(transferSpec));
    
    
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    VTSessionSetProperty(_compression_session, (__bridge CFStringRef)@"RealTime", kCFBooleanTrue);
    
    
    
    
    
    int real_keyframe_interval = 2;
    if (self.settingsController.captureVideoMaxKeyframeInterval && self.settingsController.captureVideoMaxKeyframeInterval > 0)
    {
        real_keyframe_interval = self.settingsController.captureVideoMaxKeyframeInterval;
    }
    
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(real_keyframe_interval));
    
    
    
    

    
    int real_bitrate_limit = 0;
    float limit_seconds = 0.0f;
    
    if (self.settingsController.videoCBR && self.settingsController.captureVideoAverageBitrate && self.settingsController.captureVideoAverageBitrate > 0)
    {
        
        limit_seconds = 1.0f;
        real_bitrate_limit = (self.settingsController.captureVideoAverageBitrate/2)*125; // In bytes (1000/8)
        
    } else if (self.settingsController.captureVideoMaxBitrate && self.settingsController.captureVideoMaxBitrate > 0) {
        real_bitrate_limit = self.settingsController.captureVideoMaxBitrate*125; // In bytes (1000/8)
        limit_seconds = 1.0f;
    }
    
    
    
    
    if (self.settingsController.captureVideoAverageBitrate > 0)
    {
        int real_bitrate = self.settingsController.captureVideoAverageBitrate*1000;
        
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AverageBitRate, CFNumberCreate(NULL, kCFNumberIntType, &real_bitrate));
        
    }
    
    

    /*
    
    if (self.settingsController.captureFPS && self.settingsController.captureFPS > 0)
    {
        
        
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)(@(self.settingsController.captureFPS)));
        
    }
    
     */
    
    
    //This doesn't appear to work at all (2012 rMBP, 10.8.4). Even if you set DataRateLimits, you don't get anything back if you
    //try to retrieve it.
    
    if (real_bitrate_limit > 0)
    {
        NSLog(@"SETTING DAT RATE LIMIT");
        
		NSArray *dataRateLimits = @[
			@(real_bitrate_limit),
			@(limit_seconds),
		];
        
        OSStatus success = VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef)dataRateLimits);
        if (success != noErr)
        {
            NSLog(@"FAILED TO SET DATALIMITS");
        }
    }

    
    if (self.settingsController.vtcompressor_profile)
    {
        CFStringRef session_profile = nil;
        
        
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
        {
            if ([self.settingsController.vtcompressor_profile isEqualToString:@"Baseline"])
            {
                session_profile = kVTProfileLevel_H264_Baseline_4_1;
            } else if ([self.settingsController.vtcompressor_profile isEqualToString:@"Main"]) {
                session_profile = kVTProfileLevel_H264_Main_5_0;
            } else if ([self.settingsController.vtcompressor_profile isEqualToString:@"High"]) {
                session_profile = kVTProfileLevel_H264_High_5_0;
            }            
        } else {
            if ([self.settingsController.vtcompressor_profile isEqualToString:@"Baseline"])
            {
                session_profile = (__bridge CFStringRef)@"H264_Baseline_AutoLevel";
            } else if ([self.settingsController.vtcompressor_profile isEqualToString:@"Main"]) {
                session_profile = (__bridge CFStringRef)@"H264_Main_AutoLevel";
            } else if ([self.settingsController.vtcompressor_profile isEqualToString:@"High"]) {
                session_profile = (__bridge CFStringRef)@"H264_High_AutoLevel";
            }
        }
        
        
        if (session_profile)
        {
            VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ProfileLevel, session_profile);
        }
            
            
    }
    return YES;
    
}


void VideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    
    /*
    if (VTFrameRef)
    {
        CVPixelBufferRelease(VTFrameRef);
    }
     */
    
    
    @autoreleasepool {
        
        
        
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
        
        
        /* We don't need the original video frame anymore, set the property to nil, which will release the CVImageBufferRef */
        
        frameData.videoFrame = nil;
        frameData.encodedSampleBuffer = sampleBuffer;
        
        
        AppleVTCompressor *selfobj = (__bridge AppleVTCompressor *)VTref;
        
        
        [selfobj.outputDelegate outputEncodedData:frameData];
        
        //[selfobj.outputDelegate outputSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
    }
}


@end
