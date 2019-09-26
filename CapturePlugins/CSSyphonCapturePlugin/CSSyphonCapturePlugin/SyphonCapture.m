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


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    
    [aCoder encodeBool:self.isFlipped forKey:@"isFlipped"];
    [aCoder encodeInt:self.renderType forKey:@"renderType"];
}


-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    
    [super restoreWithCoder:aDecoder];
    
    [self commonInit];
    self.isFlipped = [aDecoder decodeBoolForKey:@"isFlipped"];
    self.renderType = [aDecoder decodeIntForKey:@"renderType"];
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
    
    CGLPixelFormatAttribute attrib[] = {kCGLPFANoRecovery, kCGLPFAAccelerated, 0};
    CGLPixelFormatObj pixelFormat = NULL;
    GLint numPixelFormats = 0;
    CGLChoosePixelFormat (attrib, &pixelFormat, &numPixelFormats);
    CGLCreateContext(pixelFormat, NULL, &_cgl_ctx);
    
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
    
    newLayer.sharedContext = _cgl_ctx;
    
    if (_syphon_client)
    {
        newLayer.syphonClient = _syphon_client;
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
    
    


    _renderType = renderType;
}


-(frame_render_behavior)renderType
{
    return _renderType;
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
        _syphon_client = [[SyphonClient alloc] initWithServerDescription:_syphonServer.copy context:_cgl_ctx options:nil newFrameHandler:^(SyphonClient *client) {
   
            //Big stupid hack to force at least one layer to update the size before we kick a framedata block off
            
            if (self->_dummyFrameUpdate) {
                [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                    return;
                }];
                self->_dummyFrameUpdate = NO;

            }
                
            
 
            
            if (!self->_dummyFrameUpdate)
            {
                [self updateLayersWithFramedataBlock:^(CALayer *layer) {
                    [((CSSyphonCaptureLayer *)layer) setNeedsDisplay];

                }];
                [self frameArrived];
            }
            
            if (NSEqualSizes(self->_last_frame_size, NSZeroSize))
            {
                [self updateLayersWithBlock:^(CALayer *layer) {
                    self->_last_frame_size = ((CSSyphonCaptureLayer *)layer).lastImageSize;
                }];
            }
            
        }];
        
 
        [self updateLayersWithBlock:^(CALayer *layer) {
            ((CSSyphonCaptureLayer *)layer).syphonClient = self->_syphon_client;
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
    NSString *retireID = [[notification userInfo] objectForKey:SyphonServerDescriptionUUIDKey];
    
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
