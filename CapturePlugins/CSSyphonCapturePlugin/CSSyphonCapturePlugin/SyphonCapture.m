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


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.isFlipped forKey:@"isFlipped"];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [super initWithCoder:aDecoder])
    {
        [self commonInit];
        self.isFlipped = [aDecoder decodeBoolForKey:@"isFlipped"];
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
    
    self.isFlipped = NO;

    [self changeAvailableVideoDevices];
   
    _flipTransform = CATransform3DMakeScale(1, -1, 1);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerRetire:) name:SyphonServerRetireNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerAnnounce:) name:SyphonServerAnnounceNotification object:nil];

    
    
}

-(CALayer *)createNewLayer
{
    CSIOSurfaceLayer *newLayer = [CSIOSurfaceLayer layer];
    
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
     
         //this call retains the surface, so be sure to release it if we don't care about it anymore
         IOSurfaceRef newSurface = [client IOSurface];
         
         uint32_t newSeed = IOSurfaceGetSeed(newSurface);
         
         if (newSeed != _surfaceSeed)
         {
             CIImage *newImage = [[CIImage alloc] initWithIOSurface:newSurface plane:0 format:kCIFormatARGB8 options:nil];
             _surfaceSeed = newSeed;
             [self updateLayersWithBlock:^(CALayer *layer) {
                 ((CSIOSurfaceLayer *)layer).ioImage = newImage;
             }];
             CFRelease(newSurface);
          } else {
             CFRelease(newSurface);
         }
         
     }];
        
        @synchronized(self)
        {
            _serverSurface = [_syphon_client IOSurface];
        }
        
        
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
        
        NSLog(@"Syphon UUID %@", [sserv objectForKey:SyphonServerDescriptionUUIDKey ]);
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