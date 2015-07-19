//
//  CSDeckLinkDevice.m
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSDeckLinkDevice.h"
#import "CSDeckLinkCapture.h"



@implementation CSDeckLinkDisplayMode


-(instancetype)initWithMode:(IDeckLinkDisplayMode *)displayMode
{
    if (self = [self init])
    {
        CFStringRef desc;
        
        _deckLinkMode = displayMode;
        _deckLinkMode->AddRef();
        _deckLinkMode->GetName(&desc);
        self.modeName = (__bridge NSString *)desc;
    }
    
    return self;
}

-(bool)containsMode:(IDeckLinkDisplayMode *)mode
{
    if (_deckLinkMode && (_deckLinkMode->GetDisplayMode() == mode->GetDisplayMode()))
    {
        return YES;
    }
    
    return NO;
}


-(void)dealloc
{
    if (_deckLinkMode)
    {
        _deckLinkMode->Release();
    }
}

@end


@implementation CSDeckLinkDevice

@synthesize selectedDisplayMode = _selectedDisplayMode;
@synthesize selectedPixelFormat = _selectedPixelFormat;
@synthesize activeConnection = _activeConnection;


+(id) deviceCache
{
    static NSMutableDictionary *deviceCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        deviceCache = [NSMutableDictionary dictionary];
    });
    
    return deviceCache;
}


+(NSString *)uniqueIDForDevice:(IDeckLink *)device
{
    NSString *ret;
    IDeckLinkAttributes *deviceAttributes = NULL;
    
    if (!device)
    {
        return @"No Device";
    }
    
    
    if (device->QueryInterface(IID_IDeckLinkAttributes, (void **)&deviceAttributes) == S_OK)
    {
        
        int64_t topID;
        deviceAttributes->GetInt(BMDDeckLinkPersistentID, &topID);
        ret = [NSString stringWithFormat:@"%lld", topID];
        deviceAttributes->Release();
    }
    
    return ret;
}


-(instancetype) initWithDevice:(IDeckLink *)device
{
    NSMutableDictionary *cachemap = [CSDeckLinkDevice deviceCache];
    NSString *uid = [CSDeckLinkDevice uniqueIDForDevice:device];
    
    CSDeckLinkDevice *cachedSession = [cachemap objectForKey:uid];
    
    
    if (cachedSession)
    {
        self = cachedSession;
    } else if (self = [super init]) {
        self.canDetectFormat = NO;

        
        _outputs = [NSHashTable weakObjectsHashTable];

        IDeckLinkAttributes *deviceAttributes = NULL;
        IDeckLinkConfiguration *deviceConfig = NULL;
        if (device)
        {
            _device = device;
            _device->AddRef();
            if (_device->QueryInterface(IID_IDeckLinkInput, (void **)&_deviceInput) != S_OK)
            {
                _deviceInput = NULL;
            }
        
        
            _connectionMap = @{@"SDI": @(bmdVideoConnectionSDI),
                               @"HDMI": @(bmdVideoConnectionHDMI),
                               @"Optical SDI": @(bmdVideoConnectionOpticalSDI),
                               @"Component": @(bmdVideoConnectionComponent),
                               @"Composite": @(bmdVideoConnectionComposite),
                               @"S-Video": @(bmdVideoConnectionSVideo),
                               @(bmdVideoConnectionSDI): @"SDI",
                               @(bmdVideoConnectionHDMI): @"HDMI",
                               @(bmdVideoConnectionOpticalSDI): @"Optical SDI",
                               @(bmdVideoConnectionComponent): @"Component",
                               @(bmdVideoConnectionComposite): @"Composite",
                               @(bmdVideoConnectionSVideo): @"S-Video",
                               };
            
            
            if (_device->QueryInterface(IID_IDeckLinkAttributes, (void **)&deviceAttributes) == S_OK)
            {
            
                int64_t topID;
                deviceAttributes->GetFlag(BMDDeckLinkSupportsInputFormatDetection, &_canDetectFormat);
                deviceAttributes->GetInt(BMDDeckLinkPersistentID, &topID);
                self.uniqueID = [NSString stringWithFormat:@"%lld", topID];
            
            
                if (_device->QueryInterface(IID_IDeckLinkConfiguration, (void **)&deviceConfig) == S_OK)
                {
                    [self setupConnections:deviceAttributes deviceConfig:deviceConfig];
                    deviceConfig->Release();
                }
                deviceAttributes->Release();
            
            }
            [cachemap setObject:self forKey:self.uniqueID];

        }

        [self setupDisplayModes];
    }
    
    return self;
}




-(void)setupConnections:(IDeckLinkAttributes *)attrs deviceConfig:(IDeckLinkConfiguration *)config
{
    self.videoConnections = [NSMutableArray array];
    
    int64_t ports = 0;
    
    HRESULT err = attrs->GetInt(BMDDeckLinkVideoInputConnections, &ports);
    
    if (err == S_OK)
    {
        if (ports & bmdVideoConnectionSDI)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionSDI)]];
        }
        
        if (ports & bmdVideoConnectionHDMI)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionHDMI)]];
        }
        
        if (ports & bmdVideoConnectionOpticalSDI)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionOpticalSDI)]];
        }
        
        if (ports & bmdVideoConnectionComponent)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionComponent)]];
        }
        
        if (ports & bmdVideoConnectionComposite)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionComposite)]];
        }
        
        if (ports & bmdVideoConnectionSVideo)
        {
            [self.videoConnections addObject:_connectionMap[@(bmdVideoConnectionSVideo)]];
        }
    }
    
    int64_t inputConnection = 0;
    err = config->GetInt(bmdDeckLinkConfigVideoInputConnection, &inputConnection);
    if (err == S_OK)
    {
        _activeConnection = _connectionMap[@(inputConnection)];
    }
}


-(NSString *)activeConnection
{
    return _activeConnection;
}

-(void)setActiveConnection:(NSString *)activeConnection
{
    _activeConnection = activeConnection;
    if (!_device)
    {
        return;
    }
    int64_t inputPort = 0;
    
    NSNumber *inpObj = _connectionMap[activeConnection];
    if (inpObj)
    {
        inputPort = [inpObj longLongValue];
        IDeckLinkConfiguration *deckConfig = NULL;
        HRESULT err;
        err = _device->QueryInterface(IID_IDeckLinkConfiguration, (void **)&deckConfig);
        if (err == S_OK)
        {
            deckConfig->SetInt(bmdDeckLinkConfigVideoInputConnection, inputPort);
            deckConfig->Release();
        }
    }
}


-(void)setDisplayModeForName:(NSString *)name
{
    if (!name)
    {
        return;
    }
    
    for (CSDeckLinkDisplayMode *mode in self.displayModes)
    {
        if ([mode.modeName isEqualToString:name])
        {
            self.selectedDisplayMode = mode;
            break;
        }
    }
}

-(CSDeckLinkDisplayMode *)displayModeForRaw:(IDeckLinkDisplayMode *)mode
{
    for (CSDeckLinkDisplayMode *dldm in self.displayModes)
    {
        if ([dldm containsMode:mode])
        {
            return dldm;
        }
    }
    
    return nil;
}


-(void)setupDisplayModes
{
    
    NSMutableArray *newModes = [NSMutableArray array];
    if (_deviceInput)
    {
        IDeckLinkDisplayModeIterator *iter = NULL;
        if (_deviceInput->GetDisplayModeIterator(&iter) == S_OK)
        {
            IDeckLinkDisplayMode *currMode = NULL;
            while (iter->Next(&currMode) == S_OK)
            {
                CSDeckLinkDisplayMode *oMode = [[CSDeckLinkDisplayMode alloc] initWithMode:currMode];
                [newModes addObject:oMode];
                currMode->Release();
            }
        }
    }
    self.displayModes = newModes;
    self.pixelFormats = @[@"YUV 8-bit", @"YUV 10-bit", @"ARGB 8-bit", @"BGRA 8-bit", @"RGB 10-bit", @"RGB 12-bit", @"RGBXLE 10-bit", @"RGBX 10-bit"];
    _pixelFormatValues[0] = bmdFormat8BitYUV;
    _pixelFormatValues[1] = bmdFormat10BitYUV;
    _pixelFormatValues[2] = bmdFormat8BitARGB;
    _pixelFormatValues[3] = bmdFormat8BitBGRA;
    _pixelFormatValues[4] = bmdFormat10BitRGB;
    _pixelFormatValues[5] = bmdFormat12BitRGB;
    _pixelFormatValues[6] = bmdFormat12BitRGBLE;
    _pixelFormatValues[7] = bmdFormat10BitRGBXLE;
    _pixelFormatValues[8] = bmdFormat10BitRGBX;

    
}


-(bool)setupCapture
{
    if (!_deviceInput)
    {
        return NO;
    }
    
    BMDVideoInputFlags videoFlags = bmdVideoInputFlagDefault;
    if (self.canDetectFormat)
    {
        videoFlags = bmdVideoInputEnableFormatDetection;
    }
    
    
    CSDeckLinkDisplayMode *displayMode = self.selectedDisplayMode;
    if (!_deviceInput)
    {
        return NO;
    }
    
    if (!displayMode)
    {
        displayMode = self.displayModes.firstObject;
    }
    
    
    NSUInteger pixelFormatIdx;
    
    pixelFormatIdx = [self.pixelFormats indexOfObject:self.selectedPixelFormat];
    if (pixelFormatIdx == NSNotFound)
    {
        pixelFormatIdx = 0;
    }
    
    BMDPixelFormat pFormat = _pixelFormatValues[pixelFormatIdx];
    if (_deviceInput->EnableVideoInput(displayMode.deckLinkMode->GetDisplayMode(), pFormat, videoFlags) != S_OK)
    {
        NSLog(@"DeckLink EnableVideoInput failed");
        return NO;
    }
    return YES;

}
-(void)restartCapture
{
    
    if (!_deviceInput)
    {
        return;
    }
    
    _deviceInput->StopStreams();
    if ([self setupCapture])
    {
        _deviceInput->StartStreams();
    }
}




-(void)startCapture
{
    
    if (![self setupCapture])
    {
        return;
    }
    
    
    if (_inputCallbackHandler) //?!?!?!
    {
        _inputCallbackHandler->Release();
    }
    
    _inputCallbackHandler = new DeckLinkInputHandler(self);

    _deviceInput->SetCallback(_inputCallbackHandler);
    
    if (_deviceInput->StartStreams() != S_OK)
    {
        NSLog(@"DeckLink StartStreams failed");
    }
    
}

-(void)stopCapture
{
    
    NSLog(@"STOPPING CAPTURE!");
    if (_deviceInput)
    {
        _deviceInput->StopStreams();
        _deviceInput->SetCallback(NULL);
        _deviceInput->DisableVideoInput();
    }
}


-(CSDeckLinkDisplayMode *)selectedDisplayMode
{
    return _selectedDisplayMode;
}


-(void)setSelectedDisplayMode:(CSDeckLinkDisplayMode *)selectedDisplayMode
{
    
    if (_selectedDisplayMode != selectedDisplayMode)
    {
        _selectedDisplayMode = selectedDisplayMode;
        [self restartCapture];
    }
}

-(NSString *)selectedPixelFormat
{
    return _selectedPixelFormat;
}


-(void)setSelectedPixelFormat:(NSString *)selectedPixelFormat
{
    if (![_selectedPixelFormat isEqualToString:selectedPixelFormat])
    {
        _selectedPixelFormat = selectedPixelFormat;
        [self restartCapture];
    }
}


-(void)detectedDisplayChange:(IDeckLinkDisplayMode *)mode withFlags:(BMDDetectedVideoInputFormatFlags)flags
{
    
    NSString *newFormat = @"YUV 10-bit";
    
    CSDeckLinkDisplayMode *newMode = [self displayModeForRaw:mode];

    if (flags & bmdDetectedVideoInputRGB444)
    {
        newFormat = @"RGB 10-bit";
    }
    
    if (newMode)
    {
        _selectedPixelFormat = newFormat;
        _selectedDisplayMode = newMode;
        [self restartCapture];
    }
}


-(void)frameArrived:(IDeckLinkVideoFrame *)frame
{
    

    NSHashTable *outcopy;
    @synchronized(self)
    {
        outcopy = _outputs.copy;
    }
    
    for (CSDeckLinkCapture *capture in outcopy)
    {
        [capture frameArrived:frame];
    }
}




-(void)registerOutput:(CSDeckLinkCapture *)output
{    
    @synchronized(self)
    {
        [_outputs addObject:output];
        if (_outputs.count == 1)
        {
            [self startCapture];
        }
    }
}



-(void)removeOutput:(CSDeckLinkCapture *)output
{
    @synchronized(self)
    {
        [_outputs removeObject:output];
        
        if (_outputs.count == 0)
        {
            [self stopCapture];
        }
    }
    
}

@end
