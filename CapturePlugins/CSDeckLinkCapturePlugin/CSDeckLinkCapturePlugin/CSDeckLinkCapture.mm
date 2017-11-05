//
//  CSDeckLinkCapture.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/13/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSDeckLinkCapture.h"
#import "CSIOSurfaceLayer.h"

@implementation CSDeckLinkCapture
@synthesize renderType = _renderType;


+(NSString *)label
{
    return @"Blackmagic Decklink";
}


-(instancetype) init
{
    if (self = [super init])
    {
        _lastSize = NSZeroSize;
        _discoveryDev = new DeckLinkDeviceDiscovery(self);
        _discoveryDev->Enable();
        self.canProvideTiming = YES;
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    if (self.currentInput && self.currentInput.selectedDisplayMode)
    {
        
        [aCoder encodeObject:self.currentInput.selectedDisplayMode.modeName forKey:@"selectedDisplayMode"];
    }
    
    if (self.currentInput && self.currentInput.selectedPixelFormat)
    {
        [aCoder encodeObject:self.currentInput.selectedPixelFormat forKey:@"selectedPixelFormat"];
    }
    
    if (self.currentInput && self.currentInput.activeConnection)
    {
        [aCoder encodeObject:self.currentInput.activeConnection forKey:@"activeConnection"];
    }
    
    [aCoder encodeInt:self.renderType forKey:@"renderType"];
    
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        


        
        if ([aDecoder containsValueForKey:@"selectedDisplayMode"])
        {
            _restoredMode = [aDecoder decodeObjectForKey:@"selectedDisplayMode"];
        }
        
        if ([aDecoder containsValueForKey:@"selectedPixelFormat"])
        {
            _restoredFormat = [aDecoder decodeObjectForKey:@"selectedPixelFormat"];
        }
        
        if ([aDecoder containsValueForKey:@"activeConnection"])
        {
            _restoredInput = [aDecoder decodeObjectForKey:@"activeConnection"];
        }
        
        
        self.renderType = (frame_render_behavior)[aDecoder decodeIntForKey:@"renderType"];
        [self restoreInputSettings];
        
        
    }
    
    return self;
}

-(void)restoreInputSettings
{
    
    if (self.currentInput)
    {
        if (_restoredInput)
        {
            self.currentInput.activeConnection = _restoredInput;
        }
        
        if (_restoredMode)
        {
            
            [self.currentInput setDisplayModeForName:_restoredMode];
            _restoredMode = nil;
        }
        
        if (_restoredFormat)
        {
            self.currentInput.selectedPixelFormat = _restoredFormat;
            _restoredFormat = nil;
        }
    }
}

-(CALayer *)createNewLayer
{
    
    CSDeckLinkLayer *newLayer = [CSDeckLinkLayer layer];
    if (self.renderType == kCSRenderAsync)
    {
        newLayer.asynchronous = YES;
    } else {
        newLayer.asynchronous = NO;
    }
    
    return newLayer;
}


-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    
    super.activeVideoDevice = activeVideoDevice;

    if (activeVideoDevice)
    {
        
        CSDeckLinkWrapper *devWrapper = activeVideoDevice.captureDevice;
        IDeckLink *deckLink = devWrapper.deckLink;
        
    
        
        self.currentInput = [[CSDeckLinkDevice alloc] initWithDevice:deckLink];
        
        [self.currentInput registerOutput:self];
        self.captureName = activeVideoDevice.captureName;
        
    } else {
        self.currentInput = nil;
    }
}



-(void)setRenderType:(frame_render_behavior)renderType
{
    bool asyncValue = NO;
    if (renderType == kCSRenderAsync)
    {
        asyncValue = YES;
    }
    
 /*
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSDeckLinkLayer *)layer).asynchronous = asyncValue;
    }];
   */
    _renderType = renderType;
}


-(frame_render_behavior)renderType
{
    return _renderType;
}



-(void)removeDevice:(IDeckLink *)device
{
    if (!self.availableVideoDevices)
    {
        return;
    }
    
    NSMutableArray *newArray = self.availableVideoDevices.mutableCopy;
    
    
    NSUInteger idx = [newArray indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        CSAbstractCaptureDevice *dev = (CSAbstractCaptureDevice *)obj;
        CSDeckLinkWrapper *wrapper = dev.captureDevice;
        if (wrapper && wrapper.deckLink && wrapper.deckLink == device)
        {
            return YES;
        }
        return NO;
    }];
    
    if (idx != NSNotFound)
    {
        [newArray removeObjectAtIndex:idx];
    }
    
    self.availableVideoDevices = newArray;
}


-(void)addDevice:(CSAbstractCaptureDevice *)device
{

    if (!self.availableVideoDevices)
    {
        self.availableVideoDevices = [NSArray array];
    }
    
    
    
    NSArray *newArray = [self.availableVideoDevices arrayByAddingObject:device];
    self.availableVideoDevices = newArray;
    if (!self.activeVideoDevice && self.savedUniqueID)
    {
        [self setDeviceForUniqueID:self.savedUniqueID];
        [self restoreInputSettings];

    }
}



-(NSSize)captureSize
{
    return _lastSize;
}


-(void)frameArrived:(IDeckLinkVideoFrame *)frame
{
    
    
    if (frame)
    {
        
        _lastSize = NSMakeSize(frame->GetWidth(), frame->GetHeight());
        
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            [(CSDeckLinkLayer *)layer setRenderFrame:frame];
            //if (self.renderType == kCSRenderFrameArrived)
           // {
                [((CSDeckLinkLayer *)layer) setNeedsDisplay];
          //  }
            
        }];
        [self frameArrived];
    }
}

/*
-(void)frameTick
{
    
    if (self.renderType == kCSRenderOnFrameTick)
    {
        
        [self updateLayersWithBlock:^(CALayer *layer) {
            [((CSDeckLinkLayer *)layer) setNeedsDisplay];
        }];
    }
    
}
*/


-(void)dealloc
{
    
     if (self.currentInput)
    {
        [self.currentInput removeOutput:self];
    }
}


@end
