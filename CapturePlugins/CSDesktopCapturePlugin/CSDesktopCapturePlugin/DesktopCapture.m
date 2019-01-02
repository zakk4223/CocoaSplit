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

#import <pthread.h>


@implementation DesktopCapture

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize videoCaptureFPS = _videoCaptureFPS;
@synthesize renderType = _renderType;
@synthesize width = _width;
@synthesize height = _height;
@synthesize x_origin = _x_origin;
@synthesize y_origin = _y_origin;
@synthesize region_height = _region_height;
@synthesize region_width = _region_width;




-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    
    [aCoder encodeInt:self.width forKey:@"width"];
    [aCoder encodeInt:self.height forKey:@"height"];
    [aCoder encodeInt:self.region_width forKey:@"region_width"];
    [aCoder encodeInt:self.region_height forKey:@"region_height"];
    [aCoder encodeInt:self.x_origin forKey:@"x_origin"];
    [aCoder encodeInt:self.y_origin forKey:@"y_origin"];
    [aCoder encodeDouble:self.videoCaptureFPS forKey:@"videoCaptureFPS"];
    [aCoder encodeBool:self.showCursor forKey:@"showCursor"];
    [aCoder encodeInt:self.renderType forKey:@"renderType"];
}



-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    
    [super restoreWithCoder:aDecoder];
    
    _width = [aDecoder decodeIntForKey:@"width"];
    _height = [aDecoder decodeIntForKey:@"height"];
    _videoCaptureFPS = [aDecoder decodeDoubleForKey:@"videoCaptureFPS"];
    _showCursor = [aDecoder decodeBoolForKey:@"showCursor"];
    _region_width = [aDecoder decodeIntForKey:@"region_width"];
    _region_height = [aDecoder decodeIntForKey:@"region_height"];
    _x_origin = [aDecoder decodeIntForKey:@"x_origin"];
    _y_origin = [aDecoder decodeIntForKey:@"y_origin"];
    _renderType = [aDecoder decodeIntForKey:@"renderType"];
}



-(id) init
{
    if (self = [super init])
    {
        _capture_queue = dispatch_queue_create("Desktop Capture Queue", DISPATCH_QUEUE_SERIAL);

        self.canProvideTiming = YES;
        self.videoCaptureFPS = 60.0f;
        self.showCursor = YES;
        _currentFrameTime = 0.0f;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationTerminating:) name:NSApplicationWillTerminateNotification object:nil];
        

    }

    return self;
    
}


-(NSImage *)libraryImage
{
    return [NSImage imageNamed:NSImageNameComputer];
}


-(void)frameTick
{
    
    if (self.renderType == kCSRenderOnFrameTick)
    {
        
        /*
        [self updateLayersWithBlock:^(CALayer *layer) {
            [((CSIOSurfaceLayer *)layer) setNeedsDisplay];
        }];*/
    }
    
}


-(CALayer *)createNewLayer
{
    
    return [CALayer layer];

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


-(void)setRenderType:(frame_render_behavior)renderType
{
    
    
    BOOL asyncValue = NO;
    if (renderType == kCSRenderAsync)
    {
        asyncValue = YES;
    }
    
    /*
    [self updateLayersWithBlock:^(CALayer *layer) {
        
        ((CSIOSurfaceLayer *)layer).asynchronous = asyncValue;
    }];
    */
    _renderType = renderType;
}


-(frame_render_behavior)renderType
{
    return _renderType;
}


-(NSSize)captureSize
{
    return _lastSize;
}


-(bool)setupDisplayStream
{

    int width;
    int height;
    
    NSLog(@"SETUP DISPLAY STREAM");
    _lastSize = CGSizeZero;
    
    if (_displayStreamRef)
    {
        [self stopDisplayStream];
    }
    

    
    if (!self.currentDisplay)
    {
        return NO;
    }

    NSNumber *minframetime = [NSNumber numberWithFloat:1.0f/self.videoCaptureFPS];
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
    

    CFRelease(rectDict);
    
    

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
        if (status == kCGDisplayStreamFrameStatusFrameComplete && frameSurface)
        {
            self->_lastSize = CGSizeMake(IOSurfaceGetWidth(frameSurface), IOSurfaceGetHeight(frameSurface));
            [strongSelf updateLayersWithFramedataBlock:^(CALayer *layer) {
                layer.contents = (__bridge id _Nullable)(frameSurface);
            }];
            [self frameArrived];
        }
    });

    CGDisplayStreamStart(_displayStreamRef);
    
    return YES;
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
        
        
        [retArray addObject:[[CSAbstractCaptureDevice alloc] initWithName:displayName device:display_id_obj uniqueID:display_id_uniq]];
    }
    
    return (NSArray *)retArray;
    
}


+ (NSString *)label
{
    return @"Desktop Capture";
}

-(bool)allowDedup
{
    
    if (self.width > 0 || self.height > 0 || self.x_origin > 0 || self.y_origin > 0 || self.region_width > 0 || self.region_height > 0)
    {
        return NO;
    }
    return YES;
}

/*
+(BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    BOOL doNotify = NO;
    
    NSSet *noAutoSet = [NSSet setWithObjects:@"width", @"height", @"x_origin", @"y_origin", @"region_width", @"region_height", nil];

    if ([noAutoSet containsObject:key])
    {
        doNotify = NO;
    } else {
        doNotify = [super automaticallyNotifiesObserversForKey:key];
    }
    
    return doNotify;
}
*/


-(void)setWidth:(int)width
{
    
    if (_width != width)
    {
        _width = width;
        [self setupDisplayStream];

    }
}

-(int)width
{
    return _width;
}

-(void)setHeight:(int)height
{
    if (_height != height)
    {
        _height = height;
        [self setupDisplayStream];

    }
}

-(int)height
{
    return _height;
}

-(void)setX_origin:(int)x_origin
{
    if (_x_origin != x_origin)
    {
        _x_origin = x_origin;
        [self setupDisplayStream];
    }
}

-(int)x_origin
{
    return _x_origin;
}

-(void)setY_origin:(int)y_origin
{
    if (_y_origin != y_origin)
    {
        _y_origin = y_origin;
        [self setupDisplayStream];
    }
}

-(int)y_origin
{
    return _y_origin;
}

-(void)setRegion_width:(int)region_width
{
    if (_region_width != region_width)
    {
        _region_width = region_width;
        [self setupDisplayStream];
    }
}

-(int)region_width
{
    return _region_width;
}

-(void)setRegion_height:(int)region_height
{
    if (_region_height != region_height)
    {
        _region_height = region_height;
        [self setupDisplayStream];
    }
}

-(int)region_height
{
    return _region_height;
}

-(void)setVideoCaptureFPS:(double)videoCaptureFPS
{
    if (_videoCaptureFPS != videoCaptureFPS)
    {
        _videoCaptureFPS = videoCaptureFPS;
        [self setupDisplayStream];
    }
}

-(double)videoCaptureFPS
{
    return _videoCaptureFPS;
}


-(void)resetRegionRect:(NSRect)regionRect
{
    [self willChangeValueForKey:@"x_origin"];
    [self willChangeValueForKey:@"y_origin"];
    [self willChangeValueForKey:@"region_width"];
    [self willChangeValueForKey:@"region_height"];
    _x_origin = regionRect.origin.x;
    _y_origin = regionRect.origin.y;
    _region_width = regionRect.size.width;
    _region_height = regionRect.size.height;
    [self didChangeValueForKey:@"region_height"];
    [self didChangeValueForKey:@"region_width"];
    [self didChangeValueForKey:@"y_origin"];
    [self didChangeValueForKey:@"x_origin"];
    [self setupDisplayStream];
}



-(void)willDelete
{
    [self stopDisplayStream];

}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
