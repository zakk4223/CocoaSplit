//
//  AppleVTCompressor.m
//  streamOutput
//
//  Created by Zakk on 3/17/13.

#import "AppleVTCompressor.h"
#import "OutputDestination.h"
#import "CSAppleH264CompressorViewController.h"
#import "CSPluginServices.h"


OSStatus VTCompressionSessionCopySupportedPropertyDictionary(VTCompressionSessionRef, CFDictionaryRef *);



@implementation AppleVTCompressor


- (id)copyWithZone:(NSZone *)zone
{
    AppleVTCompressor *copy = [super copyWithZone:zone];
    
    copy.average_bitrate = self.average_bitrate;
    copy.max_bitrate = self.max_bitrate;
    
    copy.profile = self.profile;
    copy.keyframe_interval = self.keyframe_interval;
    copy.use_cbr = self.use_cbr;
    copy.noHardware = self.noHardware;
    copy.forceHardware = self.forceHardware;
        return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInteger:self.average_bitrate forKey:@"average_bitrate"];
    [aCoder encodeInteger:self.max_bitrate forKey:@"max_bitrate"];
    [aCoder encodeInteger:self.keyframe_interval forKey:@"keyframe_interval"];
    [aCoder encodeObject:self.profile forKey:@"profile"];
    [aCoder encodeBool:self.use_cbr forKey:@"use_cbr"];
    [aCoder encodeBool:self.noHardware forKey:@"noHardware"];
    [aCoder encodeBool:self.forceHardware forKey:@"forceHardware"];
    
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.average_bitrate = (int)[aDecoder decodeIntegerForKey:@"average_bitrate"];
        self.max_bitrate = (int)[aDecoder decodeIntegerForKey:@"max_bitrate"];
        self.keyframe_interval = (int)[aDecoder decodeIntegerForKey:@"keyframe_interval"];
        self.profile = [aDecoder decodeObjectForKey:@"profile"];
        self.use_cbr = [aDecoder decodeBoolForKey:@"use_cbr"];
        self.noHardware = [aDecoder decodeBoolForKey:@"noHardware"];
        self.forceHardware = [aDecoder decodeBoolForKey:@"forceHardware"];
    }
    
    return self;
}


-(id)init
{
    if (self = [super init])
    {
        

        
        self.compressorType = @"Apple h264";
        self.profiles = @[[NSNull null], @"Baseline", @"Main", @"High"];
    }
    
    return self;
}





-(NSString *)description
{
    return [NSString stringWithFormat:@"%@: Type: %@, Average Bitrate %d, Max Bitrate %d, CBR: %d, Profile %@", self.name, self.compressorType, self.average_bitrate, self.max_bitrate, self.use_cbr, self.profile];
    
}







-(CMVideoCodecType) codecType
{
    return kCMVideoCodecType_H264;
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

+(bool)HEVCAvailable
{
    bool ret = NO;
    CFArrayRef encoders = NULL;
    
    NSDictionary *opts = @{@"RevealHiddenEncoders": @YES};
    
    
    VTCopyVideoEncoderList((__bridge CFDictionaryRef _Nullable)(opts), &encoders);
    
    
    NSArray *nsEnc = (__bridge NSArray *)(encoders);
    
    for (NSDictionary *encode in nsEnc)
    {
        
        NSString *cName = [encode objectForKey:(NSString *)kVTVideoEncoderList_CodecName];
        if ([cName isEqualToString:@"HEVC"])
        {
            ret = YES;
        }
    }
    CFRelease(encoders);
    
    return ret;
}


+(bool)intelQSVAvailable
{
    

    
    NSMutableDictionary *encoderSpec = [[NSMutableDictionary alloc] init];
    encoderSpec[(__bridge NSString *)kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder] = @YES;
    
    
    VTCompressionSessionRef testSession = NULL;
    OSStatus status;
    
    status = VTCompressionSessionCreate(NULL, 1920, 1080, kCMVideoCodecType_H264, (__bridge CFDictionaryRef)encoderSpec, NULL, NULL, NULL,  (__bridge void *)self, &testSession);
    
    bool ret;
    if (status != noErr || !testSession)
    {
        ret = NO;
    } else {
        VTCompressionSessionInvalidate(testSession);
        if (testSession)
        {
            CFRelease(testSession);
        }
        ret = YES;
    }
    
    return ret;
}


-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return [[CSAppleH264CompressorViewController alloc] init];
}


@end
