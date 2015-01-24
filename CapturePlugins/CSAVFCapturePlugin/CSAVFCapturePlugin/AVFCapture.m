//
//  AVFCapture.m
//  H264Streamer
//
//  Created by Zakk on 9/3/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "AVFCapture.h"
#import "CSAbstractCaptureDevice.h"
#import "AVCaptureDeviceFormat+CocoaSplitAdditions.h"
#import "AVFrameRateRange+CocoaSplitAdditions.m"
#import <CoreMediaIO/CMIOHardware.h>

@implementation AVFCapture         


@synthesize activeVideoFormat = _activeVideoFormat;
@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize activeVideoFramerate = _activeVideoFramerate;



-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    if (self.activeVideoDevice)
    {
        [aCoder encodeObject:self.activeVideoFormat.saveDictionary forKey:@"activeVideoFormat"];
    }
    
    if (self.activeVideoFramerate)
    {
        [aCoder encodeObject:self.activeVideoFramerate.localizedName forKey:@"activeVideoFramerate"];
    }
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        
        
        _savedFormatData = [aDecoder decodeObjectForKey:@"activeVideoFormat"];
        _savedFrameRateData = [aDecoder decodeObjectForKey:@"activeVideoFramerate"];
        [self restoreFormatAndFrameRate];
    }
    
    return self;
}

+(NSString *)label
{
    return @"Webcam Capture";
}


-(void) restoreFormatAndFrameRate
{
    if (_selectedVideoCaptureDevice)
    {
        for (AVCaptureDeviceFormat *fmt in _selectedVideoCaptureDevice.formats)
        {
            if ([fmt compareToDictionary:_savedFormatData])
            {
                self.activeVideoFormat = fmt;
                break;
            }
            
        }
        
        if (self.activeVideoFormat)
        {
            for (AVFrameRateRange *frr in self.activeVideoFormat.videoSupportedFrameRateRanges)
            {
                if ([frr.localizedName isEqualToString:_savedFrameRateData])
                {
                    self.activeVideoFramerate = frr;
                    break;
                }
            }
        }
    }

    
}
-(id) init
{
    if (self = [super init])
    {
        _lastFrameTime = 0;
        _sampleQueue = [NSMutableArray array];
        
         CMIOObjectPropertyAddress prop = { kCMIOHardwarePropertyAllowScreenCaptureDevices, kCMIOObjectPropertyScopeGlobal, kCMIOObjectPropertyElementMaster };
         UInt32 allow = 1;
         CMIOObjectSetPropertyData( kCMIOObjectSystemObject, &prop, 0, NULL, sizeof(allow), &allow );

        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceChange:) name:AVCaptureDeviceWasConnectedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceChange:) name:AVCaptureDeviceWasDisconnectedNotification object:nil];

        [self changeAvailableVideoDevices];
        _capture_session = [[AVCaptureSession alloc] init];
        [self setupVideoOutput];
        
        
        [_capture_session startRunning];
    }
    return self;
}


-(void) handleDeviceChange:(NSNotification *)notification
{
    
    [self changeAvailableVideoDevices];
    
    
}



-(void)dealloc
{
    
    NSLog(@"DEALLOC AVF");
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_capture_session)
    {
        [_capture_session stopRunning];
    }
}




-(AVFrameRateRange *)activeVideoFramerate
{
    return _activeVideoFramerate;
    
}



-(void) setActiveVideoFramerate:(AVFrameRateRange *)activeVideoFramerate
{
    _activeVideoFramerate = activeVideoFramerate;
  
    //TODO: ERROR HANDLING
/*    [self.activeVideoDevice lockForConfiguration:nil];
    self.activeVideoDevice.activeVideoMinFrameDuration = _activeVideoFramerate.minFrameDuration;
    [self.activeVideoDevice unlockForConfiguration];
  */
    
    
    if([[[_selectedVideoCaptureDevice activeFormat] videoSupportedFrameRateRanges] containsObject:_activeVideoFramerate])
    {
        if([_selectedVideoCaptureDevice lockForConfiguration:nil])
        {
            [_selectedVideoCaptureDevice setActiveVideoMinFrameDuration:_activeVideoFramerate.minFrameDuration];
            [_selectedVideoCaptureDevice unlockForConfiguration];
        }
    }
    
    self.videoCaptureFPS = _activeVideoFramerate.minFrameRate;
    
}


-(AVCaptureDeviceFormat *) activeVideoFormat
{
    return _activeVideoFormat;
}


-(void) setActiveVideoFormat:(id)activeVideoFormat
{
    _activeVideoFormat = activeVideoFormat;
    //TODO: Error handling here
/*    [self.activeVideoDevice lockForConfiguration:nil];
    self.activeVideoDevice.activeFormat = _activeVideoFormat;
    [self.activeVideoDevice unlockForConfiguration];
*/
    
    
    if ([_selectedVideoCaptureDevice lockForConfiguration:nil])
    {
        
        [_selectedVideoCaptureDevice setActiveFormat:_activeVideoFormat];
        [_selectedVideoCaptureDevice unlockForConfiguration];
    }
    
    self.videoFramerates = self.activeVideoFormat.videoSupportedFrameRateRanges;
}




-(id) activeVideoDevice
{
    return _activeVideoDevice;
}


-(void) setActiveVideoDevice:(CSAbstractCaptureDevice *)newDev
{
    _activeVideoDevice = newDev;
    _selectedVideoCaptureDevice = [newDev captureDevice];
    
    if (!_capture_session)
    {
        return;
    }
    
    [_capture_session beginConfiguration];
    
    if (_video_capture_input)
    {
        [_capture_session removeInput:_video_capture_input];
        _video_capture_input = nil;
    }
    
    
    if (_selectedVideoCaptureDevice)
    {
        _video_capture_input = [AVCaptureDeviceInput deviceInputWithDevice:_selectedVideoCaptureDevice error:nil];
        
        if (_video_capture_input)
        {
            
            [_capture_session addInput:_video_capture_input];
        }
    }
    
    [_capture_session commitConfiguration];
    
    self.captureName = newDev.captureName;
    
    self.videoFormats = _selectedVideoCaptureDevice.formats;
    self.videoFramerates = _selectedVideoCaptureDevice.activeFormat.videoSupportedFrameRateRanges;
    if ([_selectedVideoCaptureDevice hasMediaType:AVMediaTypeMuxed])
    {
        [self setupAudioOutput];
        
    } else {
        [self removeAudioOutput];
    }
}


-(void)setIsLive:(bool)isLive
{
    super.isLive = isLive;
    
    if (!isLive)
    {
        if (_pcmPlayer)
        {
            [[CSPluginServices sharedPluginServices] removePCMInput:_pcmPlayer];
            _pcmPlayer = nil;
        }
    }
}


-(void) changeAvailableVideoDevices
{
    
    NSArray *devices = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] arrayByAddingObjectsFromArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeMuxed]];
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    
    
    AVCaptureDevice *devinstance;

    for(devinstance in devices)
    {
        [retArray addObject:[[CSAbstractCaptureDevice alloc] initWithName:[devinstance localizedName] device:devinstance uniqueID:devinstance.uniqueID]];
    }
    
    self.availableVideoDevices = retArray;
    /*
    The blackmagic driver is weird and there's a delay before the device shows up in the available list. So the initial restore of the config
    can't find the unique ID because it doesn't exist yet. So instead we always save the restored UniqueID to a property and then try to restore
    it when we get a notification of a device change. Only restore if we don't already have a source set, though.
     */
    
    if (!self.activeVideoDevice && self.savedUniqueID)
    {
        [self setDeviceForUniqueID:self.savedUniqueID];
        [self restoreFormatAndFrameRate];
        
    }
    
}



-(bool) stopCaptureSession
{
    if (_capture_session)
    {
        [_capture_session stopRunning];
        /*
        _capture_session = nil;
        _video_capture_queue = nil;
        self.activeVideoDevice = nil;
        _video_capture_output = nil;
        _audio_capture_output = nil;
        self.activeAudioDevice = nil;
        _audio_capture_queue = nil;
        */
    }
    return YES;
}


-(bool) startCaptureSession:(NSError **)error
{
    

    _preroll_frame_cnt = 0;
    self.did_preroll = false;
    
    if (_capture_session.isRunning)
    {
        return YES;
    }

    
    if (!_capture_session)
    {
        if (error)
        {
            *error = [NSError errorWithDomain:@"videoCapture" code:110 userInfo:@{NSLocalizedDescriptionKey : @"No active capture session"}];
        }
        
        return NO;
        
    }
    
    
    [_selectedVideoCaptureDevice lockForConfiguration:nil];
    if (self.activeVideoFormat)
    {
        _selectedVideoCaptureDevice.activeFormat = self.activeVideoFormat;
    }
    if (self.activeVideoFramerate)
    {
                
        _selectedVideoCaptureDevice.activeVideoMinFrameDuration = self.activeVideoFramerate.minFrameDuration;
    }
    
    [_selectedVideoCaptureDevice unlockForConfiguration];
    

    
    return YES;
}


-(void) removeAudioOutput
{
    
    if (!_capture_session || !_audio_capture_output)
    {
        return;
    }
    
    
    [_capture_session beginConfiguration];
    
    [_capture_session removeOutput:_audio_capture_output];
    [_capture_session commitConfiguration];

    _audio_capture_output = nil;
    _audio_capture_queue = nil;
    
    
    
    if (_pcmPlayer)
    {
        [[CSPluginServices sharedPluginServices] removePCMInput:_pcmPlayer];
    }
}


-(void) setupAudioOutput
{
    
    if (!_capture_session)
    {
        return;
    }
    
    if (!_audio_capture_output)
    {
        
        
        
            _audio_capture_output = [[AVCaptureAudioDataOutput alloc] init];
        
        
            _audio_capture_output.audioSettings = @{
                                                    AVFormatIDKey: [NSNumber numberWithInt:kAudioFormatLinearPCM],
                                                    AVLinearPCMBitDepthKey: @32,
                                                    AVLinearPCMIsFloatKey: @YES,
                                                    AVLinearPCMIsNonInterleaved: @YES,
                                                    //AVNumberOfChannelsKey: @2,
                                                    };
            
    
        _audio_capture_queue = dispatch_queue_create("AVFCaptureMuxedAudio", NULL);
        [_audio_capture_output setSampleBufferDelegate:self queue:_audio_capture_queue];
    }
    
    
    [_capture_session beginConfiguration];
    
    if ([_capture_session canAddOutput:_audio_capture_output])
    {
        [_capture_session addOutput:_audio_capture_output];
        
    } else {
        NSLog(@"COULDN'T ADD AUDIO OUTPUT");
    }
    
    
    [_capture_session commitConfiguration];
}




-(CALayer *)createNewLayer
{
    return [CSIOSurfaceLayer layer];
}


-(void)setupVideoOutput
{
    
    
    if (_capture_session)
    {
        NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] init];
        
        //I know CIImage can handle this input type. Maybe make this some sort of advanced config if some devices can't handle it?
        
        [videoSettings setValue:@(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
         
        
        
        //[videoSettings setValue:@(kCVPixelFormatType_32BGRA) forKey:(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey];
        
        //[videoSettings setValue:@[@(kCVPixelFormatType_422YpCbCr8), @(kCVPixelFormatType_422YpCbCr8FullRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange), ] forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
        NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: NO]
                                                            forKey: (NSString *)kIOSurfaceIsGlobal];
        
        
        
        [videoSettings setValue:ioAttrs forKey:(NSString *)kCVPixelBufferIOSurfacePropertiesKey];
 
        _video_capture_output = [[AVCaptureVideoDataOutput alloc] init];
        
        //AVCaptureVideoPreviewLayer *avlayer = [AVCaptureVideoPreviewLayer layerWithSession:_capture_session];
        CSIOSurfaceLayer *avlayer = [CSIOSurfaceLayer layer];
        avlayer.delegate = self;
        if ([_capture_session canAddOutput:_video_capture_output])
        {
            [_capture_session addOutput:_video_capture_output];
            _video_capture_output.videoSettings = videoSettings;
            
            
            _video_capture_queue = dispatch_queue_create("VideoQueue", NULL);
            
            [_video_capture_output setSampleBufferDelegate:self queue:_video_capture_queue];

        }
    }
}






- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (connection.output == _video_capture_output)
    {
        NSLog(@"DROPPED FRAME!!!");
    }
    
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    
    if (connection.output == _video_capture_output)
    {
        
        CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
        

        if (videoFrame)
        {
        

            
            [self updateLayersWithBlock:^(CALayer *layer) {
                ((CSIOSurfaceLayer *)layer).imageBuffer = videoFrame;

            }];


            

            /*
            @synchronized(self) {
                if (_currentFrame)
                {
                    CVPixelBufferRelease(_currentFrame);
                }
                
                _currentFrame = videoFrame;
            
            }
             */
            
        }
    } else if (connection.output == _audio_capture_output) {
        if (self.isLive && !_pcmPlayer)
        {
            CMFormatDescriptionRef sDescr = CMSampleBufferGetFormatDescription(sampleBuffer);
            const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
            _pcmPlayer = [[CSPluginServices sharedPluginServices] createPCMInput:self.activeVideoDevice.uniqueID withFormat:asbd];
            _pcmPlayer.name = _selectedVideoCaptureDevice.localizedName;
        }
        
        if (_pcmPlayer)
        {
            [_pcmPlayer scheduleBuffer:sampleBuffer];
        }
    }
}


@end
