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
    AppleProResCompressor *copy = [super copyWithZone:zone];
    
    copy.proResType = self.proResType;
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.proResType forKey:@"proResType"];
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
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
        self.proResType = @(kCMVideoCodecType_AppleProRes422);
    }
    
    return self;
}





-(NSString *)description
{
    return @"Apple ProRes Compressor";
}



-(CMVideoCodecType)codecType
{
    return self.proResType.intValue;
}


-(NSMutableDictionary *)encoderSpec
{
    NSMutableDictionary *encoderSpec = [NSMutableDictionary dictionary];
    return encoderSpec;
}



-(void)configureCompressionSession:(VTCompressionSessionRef)session
{
    int real_keyframe_interval = 2;
    VTSessionSetProperty(_compression_session, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, (__bridge CFTypeRef)@(real_keyframe_interval));
    
}



-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return [[CSAppleProResCompressorViewController alloc] init];
}


@end
