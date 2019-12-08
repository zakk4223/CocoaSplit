//
//  CompressorBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
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
        self.outputs = [[NSMutableDictionary alloc] init];
        _audioBuffer = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}

-(instancetype)copyWithZone:(NSZone *)zone
{
    CompressorBase *copy = [[self.class allocWithZone:zone] init];
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
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeInteger:self.width forKey:@"videoWidth"];
    [aCoder encodeInteger:self.height forKey:@"videoHeight"];
    
    [aCoder encodeObject:self.resolutionOption forKey:@"resolutionOption"];
    return;
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




-(bool) compressFrame:(CapturedFrameData *)imageBuffer
{
    return YES;
}


-(bool)setupCompressor:(CapturedFrameData *)videoFrame
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


-(int) drainOutputBufferFrame
{
    
    int drain_cnt = 0;
    if (self.outputs.count > 0)
    {
        NSDictionary *outputs = self.outputs;
        for (id dKey in outputs)
        {
            OutputDestination *dest = self.outputs[dKey];
            
            if (dest.buffer_draining)
            {
                drain_cnt++;
                [dest writeEncodedData:nil];
            }
            
        }
        
    }
    return drain_cnt;
}


-(void) removeOutput:(OutputDestination *)destination
{

    [self.outputs removeObjectForKey:[NSValue valueWithPointer:(__bridge const void * _Nullable)(destination)]];
    if (self.outputs.count == 0)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reset];
            self.active = NO;
        });

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
