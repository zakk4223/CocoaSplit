//
//  CompressorBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CompressorBase.h"

@implementation CompressorBase



-(id) init
{
    if (self = [super init])
    {
        
        self.name = [@"" mutableCopy];

        self.arOptions = @[@"Use Source", @"Preserve AR"];

        self.resolutionOption = @"Use Source";
        
        self.outputs = [[NSMutableDictionary alloc] init];
    }
    
    return self;
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
    [self.outputs setObject:destination forKey:destination.name];
}

-(void) removeOutput:(OutputDestination *)destination
{
    [self.outputs removeObjectForKey:destination.name];
    if (self.outputs.count == 0)
    {
        [self reset];
    }
}


-(bool) hasOutputs
{
    return [self.outputs count] > 0;
}

-(BOOL) setupResolution:(CVImageBufferRef)withFrame error:(NSError **)therror
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
        
        return YES;
    }
    
    
    if ([self.resolutionOption isEqualToString:@"Use Source"])
    {
        self.height = (int)CVPixelBufferGetHeight(withFrame);
        self.width = (int)CVPixelBufferGetWidth(withFrame);
    } else if ([self.resolutionOption isEqualToString:@"Preserve AR"]) {
        float inputAR = (float)CVPixelBufferGetWidth(withFrame) / (float)CVPixelBufferGetHeight(withFrame);
        int newWidth;
        int newHeight;
        
        if (self.height > 0)
        {
            newHeight = self.height;
            newWidth = (int)(round(self.height * inputAR));
        } else if (self.width > 0) {
            newWidth = self.width;
            newHeight = (int)(round(self.width / inputAR));
        } else {
            
            if (therror)
            {
                *therror = [NSError errorWithDomain:@"videoCapture" code:160 userInfo:@{NSLocalizedDescriptionKey : @"Either width or height are required"}];
            }
            
            return NO;
            
        }
        
        self.height = (newHeight +1)/2*2;
        self.width = (newWidth+1)/2*2;
    }
    
    return YES;
}


@end
