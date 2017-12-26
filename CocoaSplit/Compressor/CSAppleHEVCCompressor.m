//
//  CSAppleHEVCCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 12/26/17.
//

#import "CSAppleHEVCCompressor.h"
#import "CSAppleH264CompressorViewController.h"

@implementation CSAppleHEVCCompressor


-(id)init
{
    if (self = [super init])
    {
        
        
        
        self.compressorType = @"Apple HEVC";
        self.codec_id = AV_CODEC_ID_HEVC;
        
        self.profiles = @[[NSNull null], @"Baseline", @"Main", @"High"];
    }
    
    return self;
}


-(CMVideoCodecType) codecType
{
    return kCMVideoCodecType_HEVC;
}

-(NSMutableDictionary *)encoderSpec
{
    
    NSMutableDictionary *encoderSpec = [NSMutableDictionary dictionary];
    
    bool enableVal = !self.noHardware;
    
    encoderSpec[(__bridge NSString *)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder] = @(enableVal);
    
    
    if (self.forceHardware)
    {
        encoderSpec[(__bridge NSString *)kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder] = @YES;
    }
    
    return encoderSpec;
}


-(void)configureCompressionSession:(VTCompressionSessionRef)session
{
    OSStatus status;
    
    VTSessionSetProperty(session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    VTSessionSetProperty(session, (__bridge CFStringRef)@"RealTime", kCFBooleanTrue);
    
    int real_keyframe_interval = 2;
    if (self.keyframe_interval && self.keyframe_interval > 0)
    {
        real_keyframe_interval = self.keyframe_interval;
    }
    
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(real_keyframe_interval));
    
    int real_bitrate_limit = 0;
    float limit_seconds = 0.0f;
    
    if (self.use_cbr && self.average_bitrate && self.average_bitrate > 0)
    {
        
        limit_seconds = 1.0f;
        real_bitrate_limit = (self.average_bitrate/2)*125; // In bytes (1000/8)
        
    } else if (self.max_bitrate && self.max_bitrate > 0) {
        real_bitrate_limit = self.max_bitrate*125; // In bytes (1000/8)
        limit_seconds = 1.0f;
    }
    
    
    
    
    if (self.average_bitrate > 0)
    {
        int real_bitrate = self.average_bitrate*1000;
        
        
        VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_AverageBitRate, CFNumberCreate(NULL, kCFNumberIntType, &real_bitrate));
        
    }
    
    //This doesn't appear to work at all (2012 rMBP, 10.8.4). Even if you set DataRateLimits, you don't get anything back if you
    //try to retrieve it.
    
    if (real_bitrate_limit > 0)
    {
        
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
    
    
    if (self.profile)
    {
        CFStringRef session_profile = nil;
        
        
        if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8)
        {
            if ([self.profile isEqualToString:@"Baseline"])
            {
                session_profile = kVTProfileLevel_H264_Baseline_4_1;
            } else if ([self.profile isEqualToString:@"Main"]) {
                session_profile = kVTProfileLevel_H264_Main_5_0;
            } else if ([self.profile isEqualToString:@"High"]) {
                session_profile = kVTProfileLevel_H264_High_5_0;
            }
        } else {
            if ([self.profile isEqualToString:@"Baseline"])
            {
                session_profile = (__bridge CFStringRef)@"H264_Baseline_AutoLevel";
            } else if ([self.profile isEqualToString:@"Main"]) {
                session_profile = (__bridge CFStringRef)@"H264_Main_AutoLevel";
            } else if ([self.profile isEqualToString:@"High"]) {
                session_profile = (__bridge CFStringRef)@"H264_High_AutoLevel";
            }
        }
        
        
        if (session_profile)
        {
            VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_ProfileLevel, session_profile);
        }
        
        
    }
}

-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return [[CSAppleH264CompressorViewController alloc] init];
}


@end
