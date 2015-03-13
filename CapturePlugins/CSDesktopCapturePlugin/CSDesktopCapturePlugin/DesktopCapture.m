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
@synthesize renderType = _renderType;






-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeInt:self.region_width forKey:@"region_width"];
    [aCoder encodeInt:self.region_height forKey:@"region_height"];
    [aCoder encodeInt:self.x_origin forKey:@"x_origin"];
    [aCoder encodeInt:self.y_origin forKey:@"y_origin"];
    [aCoder encodeDouble:self.videoCaptureFPS forKey:@"videoCaptureFPS"];
    [aCoder encodeBool:self.showCursor forKey:@"showCursor"];
    [aCoder encodeBool:self.showClicks forKey:@"showClicks"];
    
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [super initWithCoder:aDecoder])
    {
        _videoCaptureFPS = [aDecoder decodeDoubleForKey:@"videoCaptureFPS"];
        _showCursor = [aDecoder decodeBoolForKey:@"showCursor"];
        _showClicks = [aDecoder decodeBoolForKey:@"showClicks"];
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
        self.showClicks = NO;
        self.scaleFactor = 1.0f;
        [self addObserver:self forKeyPath:@"propertiesChanged" options:NSKeyValueObservingOptionNew context:NULL];
        

    }

    return self;
    
}

-(void)setRenderType:(frame_render_behavior)renderType
{
    bool asyncValue = NO;
    if (renderType == kCSRenderAsync)
    {
        asyncValue = YES;
    }
    
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSIOSurfaceLayer *)layer).asynchronous = asyncValue;
    }];
    
    _renderType = renderType;
}


-(frame_render_behavior)renderType
{
    return _renderType;
}


-(CALayer *)createNewLayer
{
    
    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
    
    if (self.renderType == kCSRenderAsync)
    {
        newLayer.asynchronous = YES;
    } else {
        newLayer.asynchronous = NO;
    }
    
    return newLayer;

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
    if (!_capture_session)
    {
        _capture_session = [[AVCaptureSession alloc] init];
        [_capture_session startRunning];
    }
    
    if (!_capture_output)
    {
        
        NSMutableDictionary *videoSettings = [NSMutableDictionary dictionary];
        
        [videoSettings setValue:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
        
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];

        

        _capture_output = [[AVCaptureVideoDataOutput alloc] init];
        if ([_capture_session canAddOutput:_capture_output])
        {
            [_capture_session addOutput:_capture_output];
            _capture_output.videoSettings = videoSettings;
            _capture_queue = dispatch_queue_create("Desktop Capture Queue", NULL);
            [_capture_output setSampleBufferDelegate:self queue:_capture_queue];
        }
    }
    
    [_capture_session beginConfiguration];
    
    if (_screen_input)
    {
        [_capture_session removeInput:_screen_input];
    }
    
    _screen_input = [[AVCaptureScreenInput alloc] initWithDisplayID:self.currentDisplay];
    [self configureScreenInput];
    
    [_capture_session addInput:_screen_input];
    [_capture_session commitConfiguration];
    
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


-(void)configureScreenInput
{
    if (!_screen_input)
    {
        return;
    }
    
    _screen_input.minFrameDuration = CMTimeMake(1,self.videoCaptureFPS);
    if (self.scaleFactor != 0)
    {
        _screen_input.scaleFactor = self.scaleFactor;
    } else {
        _screen_input.scaleFactor = 1.0f;
    }
    
    
    

    CGRect displaySize = CGDisplayBounds(self.currentDisplay);
    
    int use_width = displaySize.size.width - self.x_origin;
    int use_height = displaySize.size.height - self.y_origin;

    if (self.region_width)
    {
        use_width = self.region_width;
    }
    
    if (self.region_height)
    {
        use_height = self.region_height;
    }
    
    
    _screen_input.cropRect = CGRectMake(self.x_origin, self.y_origin, use_width, use_height);
    _screen_input.capturesCursor = self.showCursor;
    _screen_input.capturesMouseClicks = self.showClicks;
}


+ (NSString *)label
{
    return @"Desktop Capture";
}


+ (NSSet *)keyPathsForValuesAffectingPropertiesChanged
{
    return [NSSet setWithObjects:@"scaleFactor", @"videoCaptureFPS", @"x_origin", @"y_origin", @"region_width", @"region_height", @"showCursor",@"showClicks", nil];
}


- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    
    if ([keyPath isEqualToString:@"propertiesChanged"])
    {
        [self configureScreenInput];
    }
    
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{

    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    
    if (videoFrame)
    {
        [self updateLayersWithBlock:^(CALayer *layer) {
            ((CSIOSurfaceLayer *)layer).imageBuffer = videoFrame;
            if (self.renderType == kCSRenderFrameArrived)
            {
                [((CSIOSurfaceLayer *)layer) setNeedsDisplay];
            }
            
        }];
    }

    
}

-(void)dealloc
{
    NSLog(@"DEALLOC DISPLAY STREAM");
    [self removeObserver:self forKeyPath:@"propertiesChanged"];
}


@end
