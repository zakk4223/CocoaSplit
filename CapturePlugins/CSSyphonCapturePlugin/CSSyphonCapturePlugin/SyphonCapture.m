//
//  SyphonCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "SyphonCapture.h"
#import "CSAbstractCaptureDevice.h"
#import <OpenGL/OpenGL.h>


@implementation SyphonCapture




@synthesize activeVideoDevice = _activeVideoDevice;

@synthesize isFlipped = _isFlipped;
@synthesize renderType = _renderType;


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.isFlipped forKey:@"isFlipped"];
    [aCoder encodeInt:self.renderType forKey:@"renderType"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInit];
        self.isFlipped = [aDecoder decodeBoolForKey:@"isFlipped"];
        self.renderType = [aDecoder decodeIntForKey:@"renderType"];
    }
    
    return self;
}


-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}

-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    
    
    _activeVideoDevice = activeVideoDevice;
    if (_activeVideoDevice)
    {
        self.captureName = activeVideoDevice.captureName;
        [self startSyphon];
    } else {
        self.captureName = nil;
    }
}




-(bool)stopCaptureSession
{
    [_syphon_client stop];
    
    return YES;
}




-(instancetype) init
{
    if (self = [super init])
    {
        [self commonInit];
    }
    
    return self;
}


-(void) commonInit
{
    
    _renderType = kCSRenderFrameArrived;
    
    self.canProvideTiming = YES;
    
    self.isFlipped = NO;

    [self changeAvailableVideoDevices];
   
    _flipTransform = CATransform3DMakeScale(1, -1, 1);

    _dummyFrameUpdate = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerRetire:) name:SyphonServerRetireNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerAnnounce:) name:SyphonServerAnnounceNotification object:nil];

    
    
}


-(CALayer *)createNewLayer
{
    CSSyphonCaptureLayer  *newLayer = [CSSyphonCaptureLayer layer];
    
    if (_syphon_client)
    {
        newLayer.syphonClient = _syphon_client;
    }
    
    if (self.renderType == kCSRenderAsync)
    {
        newLayer.asynchronous = YES;
    } else {
        newLayer.asynchronous = NO;
    }
    
    
    newLayer.flipImage = self.isFlipped;
    return newLayer;
}


-(void)setIsFlipped:(BOOL)isFlipped
{
    
    _isFlipped = isFlipped;
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSIOSurfaceLayer *)layer).flipImage = isFlipped;
    }];

}



-(BOOL)isFlipped
{
    return _isFlipped;
}




-(void)setRenderType:(frame_render_behavior)renderType
{
    bool asyncValue = NO;
    if (renderType == kCSRenderAsync)
    {
        asyncValue = YES;
    }
    
    
    [self updateLayersWithBlock:^(CALayer *layer) {
        ((CSSyphonCaptureLayer *)layer).asynchronous = asyncValue;
    }];

    _renderType = renderType;
}


-(frame_render_behavior)renderType
{
    return _renderType;
}


-(void)frameTick
{
    if (self.renderType == kCSRenderOnFrameTick)
    {
        [self updateLayersWithBlock:^(CALayer *layer) {
            [((CSSyphonCaptureLayer *)layer) setNeedsDisplay];
            
        }];

    }
}


-(NSSize)captureSize
{
    return _last_frame_size;
}


-(void) startSyphon
{
    
    
    if (_syphon_client)
    {
        [_syphon_client stop];
        _syphon_client = nil;
    }
    
    
    
    _syphonServer = [self.activeVideoDevice captureDevice];
    
    if (_syphonServer)
    {
        _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer.copy options:nil newFrameHandler:^(SyphonClient *client) {
   
            //Big stupid hack to force at least one layer to update the size before we kick a framedata block off
            
            if (NSEqualSizes(_last_frame_size, NSZeroSize))
            {
                [self updateLayersWithBlock:^(CALayer *layer) {
                    _last_frame_size = ((CSSyphonCaptureLayer *)layer).lastImageSize;
                }];
            } else if (_dummyFrameUpdate) {
                [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                    return;
                }];
                _dummyFrameUpdate = NO;

            }
                
            
            
            
            if (self.renderType == kCSRenderFrameArrived && !_dummyFrameUpdate)
            {
                [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                    
                    [((CSSyphonCaptureLayer *)layer) setNeedsDisplay];

                }];
                [self frameArrived];
            }
            

            
        }];
        
 
        [self updateLayersWithBlock:^(CALayer *layer) {
            ((CSSyphonCaptureLayer *)layer).syphonClient = _syphon_client;
        }];

        _syphon_uuid = [[_syphon_client serverDescription] objectForKey:SyphonServerDescriptionUUIDKey];

    }
    

}






-(void)changeAvailableVideoDevices
{
    
    NSArray *servers = [[SyphonServerDirectory sharedDirectory] servers];
    NSMutableArray *retArr = [[NSMutableArray alloc] init];
    id sserv;
    
    for(sserv in servers)
    {
        
        NSString *sy_name = [NSString stringWithFormat:@"%@ - %@", [sserv objectForKey:SyphonServerDescriptionAppNameKey], [sserv objectForKey:SyphonServerDescriptionNameKey]];
        
        CSAbstractCaptureDevice *newDev;
        
        newDev = [[CSAbstractCaptureDevice alloc] initWithName:sy_name device:sserv uniqueID:[sserv objectForKey:SyphonServerDescriptionUUIDKey ]];
        
        [retArr addObject:newDev];
        if (!self.activeVideoDevice && [newDev.uniqueID isEqualToString:self.savedUniqueID])
        {
            self.activeVideoDevice = newDev;
        }
        
        
    }
    self.availableVideoDevices = (NSArray *)retArr;
    
    
    
}

-(void) handleSyphonServerAnnounce:(NSNotification *)notification
{
    
    [self changeAvailableVideoDevices];
    
    
}
-(void) handleSyphonServerRetire:(NSNotification *)notification
{
    NSString *retireID = [[notification object] objectForKey:SyphonServerDescriptionUUIDKey];
    
    if ([retireID isEqualToString:_syphon_uuid])
    {
        [_syphon_client stop];
        self.activeVideoDevice = nil;
    }
    
    [self changeAvailableVideoDevices];
    
    
    
}

+(NSString *)label
{
    return @"Syphon Capture";
}

@end
