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
@synthesize videoCaptureFPS = _videoCaptureFPS;






-(BOOL) needsAdvancedVideo
{
    return NO;
}



-(id) init
{
    if (self = [super init])
    {
        _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);

        self.videoCaptureFPS = 30.0f;
        
    }

    return self;
    
}


-(AbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    
    NSLog(@"SETTING ACTIVE VIDEO DEVICE");
    _activeVideoDevice = newDev;
    _currentDisplay = [[newDev captureDevice] unsignedIntValue];
    CGRect displaySize = CGDisplayBounds(_currentDisplay);
    
    self.width = displaySize.size.width;
    self.height = displaySize.size.height;
    
    
    [self setupDisplayStream];
}

-(double)videoCaptureFPS
{
    return _videoCaptureFPS;
}


-(void) setVideoCaptureFPS:(double)videoCaptureFPS
{
    
     _videoCaptureFPS = videoCaptureFPS;
    
    [self setupDisplayStream];
}



-(bool)setupDisplayStream
{

    
    if (_displayStreamRef)
    {
        [self stopDisplayStream];
    }
    
    
    
    if (!_currentDisplay)
    {
        NSLog(@"NO DISPLAY");
        return NO;
    }
    
    
    NSLog(@"SETUP DISPLAY STREAM %f", self.videoCaptureFPS);
    
    
    NSNumber *minframetime = [NSNumber numberWithFloat:(1000.0/(self.videoCaptureFPS*1000))];

    
    
    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(_currentDisplay, self.width, self.height,  kCVPixelFormatType_32BGRA, (__bridge CFDictionaryRef)(@{(NSString *)kCGDisplayStreamQueueDepth : @8, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @NO}), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
        
        if (status == kCGDisplayStreamFrameStatusStopped)
        {
            return;
            
        }
        
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
            
        }
    });
    
    CGDisplayStreamStart(_displayStreamRef);
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




-(bool)stopDisplayStream
{
    
    if (_displayStreamRef)
    {
        CGDisplayStreamStop(_displayStreamRef);
    }
    
  
    @synchronized(self) {
        if (_currentFrame)
        {
            CFRelease(_currentFrame);
            _currentFrame = NULL;
        }
    }

  
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




-(void)dealloc
{
    [self stopDisplayStream];
}


@end
