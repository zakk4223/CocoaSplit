//
//  AppleVTCompressor.m
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "AppleVTCompressor.h"

@implementation AppleVTCompressor



void PixelBufferRelease( void *releaseRefCon, const void *baseAddress )
{
    free((int *)baseAddress);
}



- (bool)compressFrame:(CVImageBufferRef)imageBuffer pts:(CMTime)pts duration:(CMTime)duration
{
    
    
    if (!_compression_session)
    {
        
        CVPixelBufferRelease(imageBuffer);
        return NO;
    }
    
    VTCompressionSessionEncodeFrame(_compression_session, imageBuffer, pts, duration, NULL, imageBuffer, NULL);
    return YES;
}




- (bool)setupCompressor
{
    OSStatus status;
    NSDictionary *encoder_spec = @{@"EnableHardwareAcceleratedVideoEncoder": @1};
    
    if (!self.settingsController)
    {
        return NO;
    }
    
    
    if (!self.settingsController.captureHeight || !self.settingsController.captureHeight)
    {
        return NO;
        
    }
    
    status = VTCompressionSessionCreate(NULL, self.settingsController.captureWidth, self.settingsController.captureHeight, 'avc1', (__bridge CFDictionaryRef)encoder_spec, NULL, NULL, VideoCompressorReceiveFrame,  (__bridge void *)self, &_compression_session);
    
    //If priority isn't set to -20 the framerate in the SPS/VUI section locks to 25. With -20 it takes on the value of
    //whatever ExpectedFrameRate is. I have no idea what the fuck, but it works.
    
    VTSessionSetProperty(_compression_session, (CFStringRef)@"Priority", (__bridge CFTypeRef)(@-20));
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    
    
    if (self.settingsController.captureVideoMaxKeyframeInterval && self.settingsController.captureVideoMaxKeyframeInterval > 0)
    {
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)(@(self.settingsController.captureVideoMaxKeyframeInterval)));
    }
    
    if (self.settingsController.captureVideoMaxBitrate && self.settingsController.captureVideoMaxBitrate > 0)
    {
        
        int real_bitrate = self.settingsController.captureVideoMaxBitrate*128; // In bytes (1024/8)
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFTypeRef)(@[@(real_bitrate), @1.0]));
        
    }
    
    
    if (self.settingsController.captureVideoAverageBitrate > 0)
    {
        int real_bitrate = self.settingsController.captureVideoAverageBitrate*1024;
        
        NSLog(@"Setting bitrate to %d", real_bitrate);
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AverageBitRate, CFNumberCreate(NULL, kCFNumberIntType, &real_bitrate));
        
    }
    
    if (self.settingsController.captureFPS && self.settingsController.captureFPS > 0)
    {
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)(@(self.settingsController.captureFPS)));
        
    }
    
    return YES;
    
}


void VideoCompressorReceiveFrame(void *VTref, void *VTFrameRef, OSStatus status, VTEncodeInfoFlags infoFlags, CMSampleBufferRef sampleBuffer)
{
    if (VTFrameRef)
    {
        CVPixelBufferRelease(VTFrameRef);
    }
    
    @autoreleasepool {
        
        
        
        if(!sampleBuffer)
            return;
        
        
        
        CFRetain(sampleBuffer);
        
        AppleVTCompressor *selfobj = (__bridge AppleVTCompressor *)VTref;
        
        
        [selfobj.outputDelegate outputSampleBuffer:sampleBuffer];
        
        CFRelease(sampleBuffer);
    }
}


@end
