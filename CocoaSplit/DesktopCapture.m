//
//  DesktopCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/24/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "DesktopCapture.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import <IOSurface/IOSurface.h>



@implementation DesktopCapture



-(bool) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _activeVideoDevice = [[newDev captureDevice] unsignedIntValue];
    return YES;
    
}

-(void) setVideoDimensions:(int)width height:(int)height
{
    _width = width;
    _height = height;
    
}

-(bool)setupCaptureSession:(NSError *__autoreleasing *)therror
{

    if (!_activeVideoDevice)
    {
        *therror = [NSError errorWithDomain:@"videoCapture" code:100 userInfo:@{NSLocalizedDescriptionKey : @"Must select video capture device first"}];
        return NO;
    }
    
    if (!(_width > 0) || !(_height > 0))
    {
        *therror = [NSError errorWithDomain:@"videoCapture" code:150 userInfo:@{NSLocalizedDescriptionKey : @"Width and height must be set to greater than zero"}];
        return NO;
    }
    
    
    _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);
    if (!_capture_queue)
    {
        *therror = [NSError errorWithDomain:@"videoCapture" code:160 userInfo:@{NSLocalizedDescriptionKey : @"Could not create desktop capture dispatch queue"}];
        return NO;
    }
    _currentFrameTime = 0;
    
    NSNumber *minframetime = [NSNumber numberWithFloat:1/self.videoCaptureFPS];
    
    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(_activeVideoDevice, _width, _height,  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef)(@{(NSString *)kCGDisplayStreamQueueDepth : @20, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @NO}), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
        
        if (frameSurface)
        {
            CFRetain(frameSurface);
            IOSurfaceIncrementUseCount(frameSurface);            

            @synchronized(self) {
                if (_currentFrame)
                {
                    IOSurfaceDecrementUseCount(_currentFrame);
                    CFRelease(_currentFrame);
                }
            
                _currentFrame = frameSurface;
                _currentFrameTime = displayTime;
                //IOSurfaceIncrementUseCount(_currentFrame);
                //CFRetain(_currentFrame);
            }

        }
    });
    
    return YES;
}


-(bool)startCaptureSession:(NSError *__autoreleasing *)error
{
    CGDisplayStreamStart(_displayStreamRef);
    return YES;
}


-(bool)stopCaptureSession
{
    CGDisplayStreamStop(_displayStreamRef);
    _currentFrame = NULL;
    _capture_queue = NULL;
    return YES;
}


void DesktopPixelBufferRelease(void *releaseRefCon, const void *baseAddress)
{
    
    if (baseAddress)
        free((void *)baseAddress);
    
    
}



- (CVImageBufferRef) getCurrentFrame
{
    
    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            CVPixelBufferRef tmpbuf;

            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, NULL, &tmpbuf);
            return tmpbuf;
            
            
        }
        
    }
    
    return newbuf;
    
    
}




-(bool)providesAudio
{
    return NO;
}


-(bool)providesVideo
{
    return YES;
}


-(NSArray *) availableVideoDevices
{
    
    CGDirectDisplayID display_ids[15];
    uint32_t active_display_count;
    
    CGGetActiveDisplayList(15, display_ids, &active_display_count);
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    
    
    for(int i = 0; i < active_display_count; i++)
    {
        CGDirectDisplayID disp_id = display_ids[i];
        NSString *displayName;
        
        NSDictionary *deviceInfo = (NSDictionary *)CFBridgingRelease(IODisplayCreateInfoDictionary(CGDisplayIOServicePort(disp_id), kIODisplayOnlyPreferredName));
        NSDictionary *localizedNames = [deviceInfo objectForKey:[NSString stringWithUTF8String:kDisplayProductName]];
        if ([localizedNames count] > 0)
        {
            
            displayName = [localizedNames objectForKey:[[localizedNames allKeys] objectAtIndex:0]];
            
        } else {
            displayName = @"????";
        }
        
        NSNumber *display_id_obj = [NSNumber numberWithLong:disp_id];
        NSString *display_id_uniq = [NSString stringWithFormat:@"%ud", disp_id];
        
        
        [retArray addObject:[[AbstractCaptureDevice alloc] initWithName:displayName device:display_id_obj uniqueID:display_id_uniq]];
    }
    
    return (NSArray *)retArray;
    
}





@end
