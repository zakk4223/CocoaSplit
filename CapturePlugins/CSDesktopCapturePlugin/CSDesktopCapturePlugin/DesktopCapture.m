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
#import "CSIOSurfaceLayer.h"




@implementation DesktopCapture

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize videoCaptureFPS = _videoCaptureFPS;





-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInt:self.width forKey:@"width"];
    [aCoder encodeInt:self.height forKey:@"height"];
    [aCoder encodeInt:self.region_width forKey:@"region_width"];
    [aCoder encodeInt:self.region_height forKey:@"region_height"];
    [aCoder encodeInt:self.x_origin forKey:@"x_origin"];
    [aCoder encodeInt:self.y_origin forKey:@"y_origin"];
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
        _region_width = [aDecoder decodeIntForKey:@"region_width"];
        _region_height = [aDecoder decodeIntForKey:@"region_height"];
        _x_origin = [aDecoder decodeIntForKey:@"x_origin"];
        _y_origin = [aDecoder decodeIntForKey:@"y_origin"];
        
    }
    
    [self setupDisplayStream];
    return self;
}



-(id) init
{
    if (self = [super init])
    {
        _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);

        self.videoCaptureFPS = 60.0f;
        self.showCursor = YES;
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationTerminating:) name:NSApplicationWillTerminateNotification object:nil];
        

    }

    return self;
    
}


-(CALayer *)createNewLayer
{
    return [CSIOSurfaceLayer layer];
}


-(void)applicationTerminating:(NSApplication *)sender
{
    [self stopDisplayStream];
}



-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(CSAbstractCaptureDevice *)newDev
{
    
    _activeVideoDevice = newDev;
    self.currentDisplay = [[newDev captureDevice] unsignedIntValue];
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
    

    
    if (!self.currentDisplay)
    {
        NSLog(@"NO DISPLAY");
        return NO;
    }
    
    
    
    
    
    NSNumber *minframetime = [NSNumber numberWithFloat:(1000.0/(self.videoCaptureFPS*1000))];

    CGRect displaySize = CGDisplayBounds(self.currentDisplay);
    
    width = displaySize.size.width - self.x_origin;
    height = displaySize.size.height - self.y_origin;
    
    if (self.region_width)
    {
        width = self.region_width;
    }
    
    if (self.region_height)
    {
        height = self.region_height;
    }
    
    if (self.width && self.height)
    {
        width = self.width;
        height = self.height;
    }
    

    CFDictionaryRef rectDict;

    int rect_width;
    int rect_height;
    
    if (self.region_width)
    {
        rect_width = self.region_width;
    } else {
        rect_width = displaySize.size.width - self.x_origin;
    }
    
    if (self.region_height)
    {
        rect_height = self.region_height;
    } else {
        rect_height = displaySize.size.height - self.y_origin;
    }

    rectDict = CGRectCreateDictionaryRepresentation(CGRectMake(self.x_origin, self.y_origin, rect_width, rect_height));
    
    
    NSDictionary *opts = @{(NSString *)kCGDisplayStreamQueueDepth : @8, (NSString *)kCGDisplayStreamMinimumFrameTime : minframetime, (NSString *)kCGDisplayStreamPreserveAspectRatio: @YES, (NSString *)kCGDisplayStreamShowCursor:@(self.showCursor), (NSString *)kCGDisplayStreamSourceRect: (__bridge NSDictionary *)rectDict};
    
    
    
    

    __weak __typeof__(self) weakSelf = self;
    
    _displayStreamRef = CGDisplayStreamCreateWithDispatchQueue(self.currentDisplay, width, height,  kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, (__bridge CFDictionaryRef)(opts), _capture_queue, ^(CGDisplayStreamFrameStatus status, uint64_t displayTime, IOSurfaceRef frameSurface, CGDisplayStreamUpdateRef updateRef) {
        if (!weakSelf)
        {
            return;
        }
        
        __typeof__(self) strongSelf = weakSelf;
        
        
        if (status == kCGDisplayStreamFrameStatusStopped)
        {
            if (strongSelf->_displayStreamRef)
            {
                CFRelease(strongSelf->_displayStreamRef);
            }
            
            
        }
        
        if (frameSurface)
        {
            [strongSelf updateLayersWithBlock:^(CALayer *layer) {
                ((CSIOSurfaceLayer *)layer).ioSurface = frameSurface;
            }];
            
            
        }
    });

    CGDisplayStreamStart(_displayStreamRef);
    return YES;
}





-(bool)stopDisplayStream
{
    
    if (_displayStreamRef)
    {
        NSLog(@"STOP DISPLAY STREAM");
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
        
        
        [retArray addObject:[[CSAbstractCaptureDevice alloc] initWithName:displayName device:display_id_obj uniqueID:display_id_uniq]];
    }
    
    return (NSArray *)retArray;
    
}


+ (NSString *)label
{
    return @"Desktop Capture";
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"width", @"height", @"videoCaptureFPS", @"x_origin", @"y_origin", @"region_width", @"region_height", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self setupDisplayStream];
    }
    
}


-(void)willDelete
{
    [self stopDisplayStream];

}

-(void)dealloc
{
    NSLog(@"DEALLOC DISPLAY STREAM");
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
