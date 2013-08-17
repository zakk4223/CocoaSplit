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

@synthesize activeVideoDevice = _activeVideoDevice;



-(BOOL) needsAdvancedVideo
{
    return NO;
}


-(AbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    _activeVideoDevice = newDev;
    _currentDisplay = [[newDev captureDevice] unsignedIntValue];
    
}

-(void) setVideoDimensions:(int)width height:(int)height
{
    self.width = width;
    self.height = height;
    
}

-(bool)setupCaptureSession:(NSError *__autoreleasing *)therror
{

    if (!self.activeVideoDevice)
    {
        *therror = [NSError errorWithDomain:@"videoCapture" code:100 userInfo:@{NSLocalizedDescriptionKey : @"Must select video capture device first"}];
        return NO;
    }
    
    if (!(self.width > 0) || !(self.height > 0))
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
    
    if (!self.videoCaptureFPS || self.videoCaptureFPS == 0)
    {
        self.videoCaptureFPS = 60.0;
    }
    
    
    NSNumber *minframetime = [NSNumber numberWithFloat:(1000.0/(self.videoCaptureFPS*1000))];

    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(_currentDisplay, self.width, self.height,  kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange, (__bridge CFDictionaryRef)(@{(NSString *)kCGDisplayStreamQueueDepth : @20, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @NO}), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
        
        if (frameSurface)
        {
            
            CFRetain(frameSurface);
            @synchronized(self) {
                if (_currentFrame)
                {
                    CFRelease(_currentFrame);
                }
                
                _currentFrame = frameSurface;

            }
            
            /*
            CVPixelBufferRef tmpbuf;
            
            if (self.videoDelegate)
            {
                CVPixelBufferCreateWithIOSurface(NULL, frameSurface, NULL, &tmpbuf);
                if (tmpbuf)
                {
                    [self.videoDelegate captureOutputVideo:nil didOutputSampleBuffer:nil didOutputImage:tmpbuf frameTime:0 ];
                    CVPixelBufferRelease(tmpbuf);
                }
            }
             */
        }
    });
    
    return YES;
}



-(CVImageBufferRef) getCurrentFrame
{
    
    CVImageBufferRef tmpbuf = NULL;
    
    @synchronized(self) {
        if (_currentFrame)
        {
            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, NULL, &tmpbuf);
            
        }
    
    }
    return tmpbuf;
    
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
