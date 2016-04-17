//
//  CSIRCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 4/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSIRCompressor.h"
#import "OutputDestination.h"
#import "CSInstantRecorderCompressorViewController.h"
#import "x264Compressor.h"



@implementation CSIRCompressor

- (id)copyWithZone:(NSZone *)zone
{
    CSIRCompressor *copy = [[[self class] allocWithZone:zone] init];
    
    
    copy.isNew = self.isNew;
    
    copy.name = self.name;

    copy.compressorType = self.compressorType;
    
    copy.width = self.width;
    copy.height = self.height;
    copy.working_width = self.width;
    copy.working_height = self.height;
    
    copy.resolutionOption = self.resolutionOption;
    copy.tryAppleHardware = self.tryAppleHardware;
    copy.useAppleH264 = self.useAppleH264;
    copy.useAppleProRes = self.useAppleProRes;
    copy.usex264 = self.usex264;
    copy.useNone = self.useNone;
    
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.width forKey:@"videoWidth"];
    [aCoder encodeInteger:self.height forKey:@"videoHeight"];
    
    [aCoder encodeObject:self.resolutionOption forKey:@"resolutionOption"];
    [aCoder encodeBool:self.tryAppleHardware forKey:@"tryAppleHardware"];
    [aCoder encodeBool:self.useAppleH264 forKey:@"useAppleH264"];
    [aCoder encodeBool:self.useAppleProRes forKey:@"useAppleProRes"];
    [aCoder encodeBool:self.usex264 forKey:@"usex264"];
    [aCoder encodeBool:self.useNone forKey:@"useNone"];
    
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
        
        if ([aDecoder containsValueForKey:@"tryAppleHardware"])
        {
            self.tryAppleHardware = [aDecoder decodeBoolForKey:@"tryAppleHardware"];
        }
        
        if ([aDecoder containsValueForKey:@"useAppleH264"])
        {
            self.useAppleH264 = [aDecoder decodeBoolForKey:@"useAppleH264"];
        }

        if ([aDecoder containsValueForKey:@"useAppleProRes"])
        {
            self.useAppleProRes = [aDecoder decodeBoolForKey:@"useAppleProRes"];
        }

        if ([aDecoder containsValueForKey:@"usex264"])
        {
            self.usex264 = [aDecoder decodeBoolForKey:@"usex264"];
        }

        if ([aDecoder containsValueForKey:@"useNone"])
        {
            self.useNone = [aDecoder decodeBoolForKey:@"useNone"];
        }
    }
    
    return self;
}


-(id)init
{
    if (self = [super init])
    {
        
        
        
        self.compressorType = @"Instant Replay Compressor";
        self.tryAppleHardware = YES;
        self.useAppleH264 = YES;
        
        
    }
    
    return self;
}


-(void) reset
{
    self.errored = NO;
    if (_compressor)
    {
        [_compressor reset];
    }
    
    _compressor = nil;
    
    
    
}


- (void) dealloc
{
    [self reset];
}



-(bool)compressFrame:(CapturedFrameData *)frameData
{
    
    
    if (![self hasOutputs])
    {
        return NO;
    }
    
    [self setAudioData:frameData syncObj:self];

    
    if (!_compressor)
    {
        bool compressor_status;

        compressor_status = [self setupCompressor:frameData.videoFrame];
        
        if (!compressor_status)
        {
            self.errored = YES;
            return NO;
        } else {
            self.codec_id = _compressor.codec_id;
            
            [_compressor addOutput:self];
        }
    }

    bool ret;
    ret = [_compressor compressFrame:frameData];
    return ret;
}


-(void) writeEncodedData:(CapturedFrameData *)frameData
{
    for (id dKey in self.outputs)
    {
        
        OutputDestination *dest = self.outputs[dKey];
        
        [dest writeEncodedData:frameData];
        
        
    }

}


- (bool)setupCompressor:(CVPixelBufferRef)videoFrame
{

    NSLog(@"%@ TRY HARDWARE %d USE NONE %d USE AH264 %d USE APRO %d USE x264 %d SELECTED COMPRESSOR %d", self, self.tryAppleHardware, self.useNone, self.useAppleH264, self.useAppleProRes, self.usex264, self.selectedCompressor);
    
    if (self.tryAppleHardware && [AppleVTCompressor intelQSVAvailable])
    {
        
        AppleVTCompressor *acomp = [[AppleVTCompressor alloc] init];
        acomp.average_bitrate = 9000;
        acomp.max_bitrate = 15000;
        acomp.keyframe_interval = 2;
        acomp.forceHardware = YES;
        _compressor = acomp;
        return YES;
    }
    
    if (self.useNone)
    {
        return NO;
    }
    
    if (self.useAppleH264)
    {
        AppleVTCompressor *acomp = [[AppleVTCompressor alloc] init];
        acomp.average_bitrate = 9000;
        acomp.max_bitrate = 15000;
        acomp.keyframe_interval = 2;
        acomp.forceHardware = NO;
        acomp.noHardware = YES;
        _compressor = acomp;
        return YES;
    }
    
    if (self.useAppleProRes)
    {
        AppleProResCompressor *acomp = [[AppleProResCompressor alloc] init];
        _compressor = acomp;
        return YES;
    }
    
    if (self.usex264)
    {
        x264Compressor *xcomp = [[x264Compressor alloc] init];
        xcomp.use_cbr = NO;
        xcomp.crf = 10;
        _compressor = xcomp;
        return YES;
    }
    
    return NO; //???
}



-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return [[CSInstantRecorderCompressorViewController alloc] init];
}

@end
