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





-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInt:self.width forKey:@"width"];
    [aCoder encodeInt:self.height forKey:@"height"];
    [aCoder encodeDouble:self.videoCaptureFPS forKey:@"videoCaptureFPS"];
    [aCoder encodeBool:self.showCursor forKey:@"showCursor"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [super initWithCoder:aDecoder])
    {
        _width = [aDecoder decodeIntForKey:@"width"];
        _height = [aDecoder decodeIntForKey:@"height"];
        _videoCaptureFPS = [aDecoder decodeDoubleForKey:@"videoCaptureFPS"];
        _showCursor = [aDecoder decodeBoolForKey:@"showCursor"];
    }
    
    return self;
}



-(BOOL) needsAdvancedVideo
{
    return NO;
}



-(id) init
{
    if (self = [super init])
    {
        _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);

        self.videoCaptureFPS = 60.0f;
        self.showCursor = YES;
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];

    }

    return self;
    
}


-(AbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(AbstractCaptureDevice *)newDev
{
    
    _activeVideoDevice = newDev;
    _currentDisplay = [[newDev captureDevice] unsignedIntValue];
    self.captureName = newDev.captureName;
    
    [self setupDisplayStream];
}

-(bool)setupDisplayStream
{

    int width;
    int height;
    
    
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

    if (self.width && self.height)
    {
        width = self.width;
        height = self.height;
    } else {
        CGRect displaySize = CGDisplayBounds(_currentDisplay);
        width = displaySize.size.width;
        height = displaySize.size.height;
    }
    
    
    
    NSDictionary *opts = @{(NSString *)kCGDisplayStreamQueueDepth : @8, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @YES, (NSString *)kCGDisplayStreamShowCursor:@(self.showCursor)};
    
    
    
    
    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(_currentDisplay, width, height,  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(opts), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
        
        if (status == kCGDisplayStreamFrameStatusStopped)
        {
            return;
            
        }
        
        if (frameSurface)
        {
            CIImage *newImg = [CIImage imageWithIOSurface:frameSurface];

            
            @synchronized(self) {
                _currentImg = newImg;
            }
            
        }
    });
    
    CGDisplayStreamStart(_displayStreamRef);
    return YES;
}



-(CIImage *)currentImage
{
    
    CIImage *retimg;
    @synchronized(self)
    {
        retimg = _currentImg;
    }
    
    return retimg;
}


-(bool)stopDisplayStream
{
    
    if (_displayStreamRef)
    {
        CGDisplayStreamStop(_displayStreamRef);
    }
    
  
    @synchronized(self) {
        _currentImg = nil;
        
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


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"width", @"height", @"videoCaptureFPS", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self setupDisplayStream];
    }
    
}



-(void)dealloc
{
    [self removeObserver:self forKeyPath:@"propertiesChanged"];

    [self stopDisplayStream];
}


@end
