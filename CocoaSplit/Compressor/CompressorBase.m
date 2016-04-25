//
//  CompressorBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CompressorBase.h"
#import "OutputDestination.h"

@implementation CompressorBase



-(id) init
{
    if (self = [super init])
    {
        
        self.errored = NO;
        
        self.name = [@"" mutableCopy];

        self.arOptions = @[@"Use Source", @"Preserve AR"];

        self.resolutionOption = @"Use Source";
        
        self.codec_id = AV_CODEC_ID_H264;
        
        self.outputs = [[NSMutableDictionary alloc] init];
        _audioBuffer = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    return [[self.class allocWithZone:zone] init];
}


-(bool) validate:(NSError **)therror
{
    
    if (!self.resolutionOption || [self.resolutionOption isEqualToString:@"None"])
    {
        if (!(self.height > 0) || !(self.width > 0))
        {
            if (therror)
            {
                *therror = [NSError errorWithDomain:@"videoCapture" code:150 userInfo:@{NSLocalizedDescriptionKey : @"Both width and height are required"}];
            }
            
            return NO;
        }
    } else if ([self.resolutionOption isEqualToString:@"Preserve AR"])  {
        if (self.height == 0 && self.width == 0)
        {
            if (therror)
            {
                *therror = [NSError errorWithDomain:@"videoCapture" code:160 userInfo:@{NSLocalizedDescriptionKey : @"Either width or height are required"}];
            }
            return NO;
        }
    }
    
    return YES;
}





-(void) reset
{
    return;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    return;
}

-(id) initWithCoder:(NSCoder *)aDecoder
{
    self.codec_id = AV_CODEC_ID_H264;
    return self;
}




-(bool) compressFrame:(CapturedFrameData *)imageBuffer
{
    return YES;
}


-(bool)setupCompressor:(CVPixelBufferRef)videoFrame
{
    
    return YES;
}


-(void) addOutput:(OutputDestination *)destination
{
    
    
    [self.outputs setObject:destination forKey:[NSValue valueWithPointer:(__bridge const void * _Nullable)(destination)]];
    self.active = YES;
}

-(NSInteger)outputCount
{
    return self.outputs.count;
}


-(void) removeOutput:(OutputDestination *)destination
{

    [self.outputs removeObjectForKey:[NSValue valueWithPointer:(__bridge const void * _Nullable)(destination)]];
    if (self.outputs.count == 0)
    {
        [self reset];
        self.active = NO;
    }
}


-(bool) hasOutputs
{
    return [self.outputs count] > 0;
}

-(BOOL) setupResolution:(CVImageBufferRef)withFrame
{
    
    self.working_height = self.height;
    self.working_width = self.width;
    
    
    if (!self.resolutionOption || [self.resolutionOption isEqualToString:@"None"])
    {
        if (!(self.working_height > 0) || !(self.working_width > 0))
        {
            return NO;
        }
        
        return YES;
    }
    
    
    if ([self.resolutionOption isEqualToString:@"Use Source"])
    {
        self.working_height = (int)CVPixelBufferGetHeight(withFrame);
        self.working_width = (int)CVPixelBufferGetWidth(withFrame);
        
    } else if ([self.resolutionOption isEqualToString:@"Preserve AR"]) {
        float inputAR = (float)CVPixelBufferGetWidth(withFrame) / (float)CVPixelBufferGetHeight(withFrame);
        int newWidth;
        int newHeight;
        
        if (self.working_height > 0)
        {
            newHeight = self.working_height;
            newWidth = (int)(round(self.working_height * inputAR));
        } else if (self.working_width > 0) {
            newWidth = self.working_width;
            newHeight = (int)(round(self.working_width / inputAR));
        } else {
            
            return NO;
        }
        
        self.working_height = (newHeight +1)/2*2;
        self.working_width = (newWidth+1)/2*2;
    }
    
    return YES;
}
-(id <CSCompressorViewControllerProtocol>)getConfigurationView
{
    return nil;
}


@end
