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
        _queueSemaphore = dispatch_semaphore_create(0);
        _compressQueue = [NSMutableArray array];
        _reset_flag = NO;
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




-(void)internal_reset
{
    [self reset];
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

-(bool)queueFramedata:(CapturedFrameData *)frameData
{
    if (!_consumerThread)
    {
        [self startConsumerThread];
    }
    
    @synchronized (self) {
        //If the queue is too deep, start dropping old frames
        if (_compressQueue.count > 10)
        {
            CapturedFrameData *dontCare = [self consumeframeData];
        }
        [_compressQueue addObject:frameData];
            
        dispatch_semaphore_signal(_queueSemaphore);
    }
    
    return YES;
}


-(void)clearFrameQueue
{
    @synchronized (self) {
        [_compressQueue removeAllObjects];
    }
}


-(CapturedFrameData *)consumeframeData
{
    CapturedFrameData *retData = nil;
    @synchronized (self) {
        
        
        if (_compressQueue.count > 0)
        {
            retData = [_compressQueue objectAtIndex:0];
            [_compressQueue removeObjectAtIndex:0];
        }
    }
    return retData;
}


-(void)startConsumerThread
{
    if (!_consumerThread)
    {
        _consumerThread = dispatch_queue_create("Compressor consumer", DISPATCH_QUEUE_SERIAL);
        dispatch_async(_consumerThread, ^{
            
            while (1)
            {
                @autoreleasepool {
                    @synchronized (self) {
                        
                        if (self->_reset_flag)
                        {
                            [self clearFrameQueue];
                            [self internal_reset];
                        }
                    }
                    CapturedFrameData *useData = [self consumeframeData];
                    if (!useData)
                    {
                        dispatch_semaphore_wait(self->_queueSemaphore, DISPATCH_TIME_FOREVER);
                    } else {
                        [self real_compressFrame:useData];

                    }
                }
            }
        });
    }
}



-(bool)compressFrame:(CapturedFrameData *)frameData
{
    if (![self hasOutputs])
    {
        return NO;
    }
    
    
    if ([self needsSetup] && !self.errored)
    {
        BOOL setupOK;
        
        setupOK = [self setupCompressor:frameData];
        
        if (!setupOK)
        {
            self.errored = YES;
            return NO;
        }
    }
    
    
    
    [self reconfigureCompressor];
    
    /*
    if (frameData.videoFrame)
    {
        CVPixelBufferRetain(frameData.videoFrame);
    }*/

    [self queueFramedata:frameData];
    return YES;
}


-(bool)needsSetup
{
    return NO;
}


-(void)reconfigureCompressor
{
    return;
}

-(bool) real_compressFrame:(CapturedFrameData *)imageBuffer
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
