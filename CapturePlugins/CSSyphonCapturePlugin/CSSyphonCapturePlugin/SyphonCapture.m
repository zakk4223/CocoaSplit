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
   
    if(!_flipTransform)
    {
        NSAffineTransform *nsflip = [[NSAffineTransform alloc] init];

        
        _flipTransform = [CIFilter filterWithName:@"CIAffineTransform"];
        [_flipTransform setDefaults];
        [_flipTransform setValue:nsflip forKeyPath:kCIInputTransformKey];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerRetire:) name:SyphonServerRetireNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSyphonServerAnnounce:) name:SyphonServerAnnounceNotification object:nil];

    
    
}


-(CIImage *)currentImage
{
    
    
    CIImage *retImage = nil;
    
    @synchronized(self)
    {
        if (_serverSurface)
        {
            CIImage *newImage = [[CIImage alloc] initWithIOSurface:_serverSurface plane:0 format:kCIFormatARGB8 options:nil];
            if (self.isFlipped)
            {
                [_flipTransform setValue:newImage forKey:kCIInputImageKey];
                retImage = [_flipTransform valueForKey:kCIOutputImageKey];
            } else {
                retImage = newImage;
            }
        }
    }
    
    return retImage;
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
        NSLog(@"STARTING SYPHON");
        //_syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer options:nil newFrameHandler:nil];
    
    
        
    
        
        
     _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer.copy options:nil newFrameHandler:^(SyphonClient *client) {
     
         //this call retains the surface, so be sure to release it if we don't care about it anymore
         IOSurfaceRef newSurface = [client IOSurface];
         
         uint32_t newSeed = IOSurfaceGetSeed(newSurface);
         
         if (newSeed != _surfaceSeed)
         {
             _surfaceSeed = newSeed;
             IOSurfaceRef oldSurface = _serverSurface;

             @synchronized(self)
             {
                 _serverSurface = newSurface;
                 NSAffineTransform *nsflip = [NSAffineTransform transform];
                 [nsflip translateXBy:0 yBy:IOSurfaceGetHeight(_serverSurface)];
                 
                 [nsflip scaleXBy:1 yBy:-1];
                 [_flipTransform setValue:nsflip forKeyPath:kCIInputTransformKey];
             }
             if (oldSurface)
             {
                 CFRelease(oldSurface);
             }
         } else {
             CFRelease(newSurface);
         }
         
         /*
     CVPixelBufferRef videoFrame = [weakself renderNewFrame:client];
         //NSLog(@"GET SYPHON FRAME %f", CFAbsoluteTimeGetCurrent());
         
         
     CVPixelBufferRetain(videoFrame);
     
     @synchronized(weakself) {
     if (_currentFrame)
     {
         
         CVPixelBufferRelease(_currentFrame);
     }
     
     _currentFrame = videoFrame;
     
     }*/
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

@end