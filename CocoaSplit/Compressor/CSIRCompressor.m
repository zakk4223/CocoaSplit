//
//  CSIRCompressor.m
//  CocoaSplit
//
//  Created by Zakk on 4/11/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSIRCompressor.h"
#import "OutputDestination.h"

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
    
    return copy;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    
    
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.width forKey:@"videoWidth"];
    [aCoder encodeInteger:self.height forKey:@"videoHeight"];
    
    [aCoder encodeObject:self.resolutionOption forKey:@"resolutionOption"];
    
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


-(id)init
{
    if (self = [super init])
    {
        
        
        
        self.compressorType = @"Instant Replay Compressor";
        
    }
    
    return self;
}


-(void) reset
{
    self.errored = NO;
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

    if (!_appleh264)
    {
        _appleh264 = [[AppleVTCompressor alloc] init];
        _appleh264.average_bitrate = 9000;
        _appleh264.max_bitrate = 150000;
        _appleh264.keyframe_interval = 2;
        _appleh264.forceHardware = YES;
        [_appleh264 addOutput:self];
    }
    
    bool ret = [_appleh264 compressFrame:frameData];
    if (!ret && _appleh264.errored)
    {
        _appleh264.forceHardware = NO;
        _appleh264.noHardware = YES;
        ret = [_appleh264 compressFrame:frameData];
    }
    

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
    OSStatus status;
    
    
    [self setupResolution:videoFrame];
    
    if (!self.working_height || !self.working_width)
    {
        self.errored = YES;
        return NO;
    }
    
    
    return YES;
    
}



-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return nil;
}

@end
