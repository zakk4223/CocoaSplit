//
//  CaptureBase.m
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//

#import "CSCaptureBaseInternal.h"
#import "CSTimerSourceProtocol.h"
#import "InputSource.h"
#import "CSNotifications.h"
#import "CSPcmPlayer.h"
#import "CaptureController.h"
#import "CSLayoutRecorder.h"
#import "CSPcmPlayer.h"
#import "CSInputSourceProtocol.h"

#import "SourceCache.h"
#import <objc/runtime.h>


@interface CSPcmPlayer ()

-(void) addPlayer:(id)player forUUID:(NSString *)uuid;
-(void)removePlayerForUUID:(NSString *)uuid;
-(AudioStreamBasicDescription *)audioDescription;

@end



@interface CSCaptureBase()
{
    
    //NSPointerArray *_allInputs;
    
    frame_render_behavior _saved_render_behavior;
    CFAbsoluteTime _fps_start_time;
    int _fps_frame_cnt;
    NSMutableDictionary *pcmPlayers;

}

@property (weak) id timerDelegateCtx;
@property (assign) CGFloat detectedInputWidth;
@property (assign) CGFloat detectedInputHeight;
@property (assign) double layerUpdateFPS;
@property (weak) InputSource *tickInput;
@property (weak) id<CSTimerSourceProtocol> timerDelegate;
@property (strong) NSMapTable *allLayers;
@property (strong) NSMutableDictionary *attachedAudioMap;

@end


@implementation CSCaptureBase

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize allowScaling = _allowScaling;
@synthesize timerDelegate = _timerDelegate;
@synthesize cachePersistent = _cachePersistent;


+(NSString *) label
{
    return NSStringFromClass(self);
}

-(NSString *)instanceLabel
{
    return [self.class label];
}



-(instancetype) init
{
    if (self = [super init])
    {
        self.canProvideTiming = NO;
        self.needsSourceSelection = YES;
        self.allowDedup = YES;
        self.isVisible = NO;
        self.allowScaling = YES;
        self.allLayers = [NSMapTable weakToStrongObjectsMapTable];
        pcmPlayers = [NSMutableDictionary dictionary];
        _fps_start_time = CFAbsoluteTimeGetCurrent();
        _fps_frame_cnt = 0;
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStatistics:) name:CSNotificationStatisticsUpdate object:nil];
    }
    
    return self;
}

-(void)updateStatistics:(NSNotification *)notification
{
    CFAbsoluteTime time_now = CFAbsoluteTimeGetCurrent();
    
    NSSize detectedInputSize = [self captureSize];
    self.detectedInputWidth = detectedInputSize.width;
    self.detectedInputHeight = detectedInputSize.height;
    
    
    self.layerUpdateFPS = _fps_frame_cnt / (time_now - _fps_start_time);
    
    _fps_frame_cnt = 0;
    _fps_start_time = time_now;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.activeVideoDevice.uniqueID forKey:@"active_uniqueID"];
    [aCoder encodeBool:self.allowDedup forKey:@"allowDedup"];
    [aCoder encodeBool:self.cachePersistent forKey:@"cachePersistent"];
    
    [self saveWithCoder:aCoder];
}


-(id) initWithCoder:(NSCoder *)aDecoder
{
    
    if (self = [self init])
    {
        NSString *savedUniqueID = [aDecoder decodeObjectForKey:@"active_uniqueID"];
        self.allowDedup = [aDecoder decodeBoolForKey:@"allowDedup"];

        if (self.allowDedup)
        {
            id newSelf = [[SourceCache sharedCache] findCachedSourceForClass:self.class uniqueID:savedUniqueID];
            if (newSelf)
            {
                return newSelf;
            }
        }
     
        self.savedUniqueID = [aDecoder decodeObjectForKey:@"active_uniqueID"];
        self.cachePersistent = [aDecoder decodeBoolForKey:@"cachePersistent"];

    }
    
    [self restoreWithCoder:aDecoder];
    
    [self setDeviceForUniqueID:self.savedUniqueID];
    return self;
}

-(void) restoreWithCoder:(NSCoder *)aCoder
{
    
}


-(void) saveWithCoder:(NSCoder *)aDecoder
{
    
}

-(NSImage *)libraryImage
{
    return nil;
}


-(NSString *) configurationViewClassName
{
    return [NSString stringWithFormat:@"%@ViewController", self.className];
}


-(NSString *) configurationViewName
{
    return [NSString stringWithFormat:@"%@ViewController", self.className];
}



-(NSViewController *)configurationView
{
    
    NSViewController *configViewController;
    
    NSString *controllerName = self.configurationViewClassName;
    
    
    
    
    Class viewClass = NSClassFromString(controllerName);
    
    if (viewClass)
    {
        
        
        configViewController = [[viewClass alloc] initWithNibName:self.configurationViewName bundle:[NSBundle bundleForClass:self.class]];
        

    }
    return configViewController;
    
}


-(void)setCachePersistent:(bool)cachePersistent
{
    _cachePersistent = cachePersistent;
    
    if (cachePersistent)
    {
        [[SourceCache sharedCache] cacheSourcePersistent:self];
    } else {
        [[SourceCache sharedCache] removePersistentSource:self];
    }
}

-(bool)cachePersistent
{
    return _cachePersistent;
}


-(void)setDeviceForUniqueID:(NSString *)uniqueID
{
    
    CSAbstractCaptureDevice *dummydev = [[CSAbstractCaptureDevice alloc] init];
    
    dummydev.uniqueID = uniqueID;
    
    NSArray *currentAvailableDevices;
    
    currentAvailableDevices = self.availableVideoDevices;
    
    NSUInteger sidx;
    sidx = [currentAvailableDevices indexOfObject:dummydev];
    
    if (sidx == NSNotFound)
    {
        self.activeVideoDevice = nil;
    } else {
        
        self.activeVideoDevice = [currentAvailableDevices objectAtIndex:sidx];
    }
}

-(void)frameTickFromInput:(InputSource *)input
{
    [self frameTick];
}


-(void)frameTick
{
    return;
}


-(void)willDelete
{
    return;
}


-(float)render_height
{
    NSNumber *ret = [self.inputSource valueForKeyPath:@"display_height"];
    return [ret intValue];
}

-(float)render_width
{
    
    NSNumber *ret = [self.inputSource valueForKeyPath:@"display_width"];
    return [ret intValue];
}


-(NSSize)captureSize
{
    return NSZeroSize;
}


-(id) copyWithZone:(NSZone *)zone
{
  
    
    id newCopy = [[self.class alloc] init];
    
    
    
    //This is gross I'm sorry
    
    unsigned int propCount;
    Class currentClass = self.class;
    
    
    while (currentClass && [currentClass superclass])
    {
        
        
    
        objc_property_t *myProperties = class_copyPropertyList(currentClass, &propCount);
        for (unsigned int i = 0; i < propCount; i++)
        {
            objc_property_t prop = myProperties[i];
            const char *propName = property_getName(prop);
            
            NSString *pName = [[NSString alloc] initWithBytes:propName length:strlen(propName) encoding:NSUTF8StringEncoding];
            if ([pName isEqualToString:@"allLayers"])
            {
                continue;
            }
            id propertyValue = [self valueForKey:pName];
            
            [newCopy setValue:propertyValue forKey:pName];
        }
        
        currentClass = [currentClass superclass];
        
        
    }
    return newCopy;
    
}

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
    //hack so we don't throw exceptions during the above function
    return;
}




-(CALayer *)createNewLayer
{
    CALayer *newLayer = [CALayer layer];
    return newLayer;

}


-(CALayer *)createNewLayerForInput:(id)inputsrc
{
    

    CALayer *newLayer = [self createNewLayer];
    @synchronized(self)
    {
        if (!self.tickInput)
        {
            self.tickInput = inputsrc;
        }
        
        
        //[_allInputs addObject:inputsrc];
        [self.allLayers setObject:newLayer forKey:inputsrc];
    }


    
    return newLayer;
}

-(void)removeLayerForInput:(id)inputsrc
{
    @synchronized(self)
    {
        if (self.tickInput == inputsrc)
        {
            self.tickInput = nil;
            
        }

        InputSource *lsrc = (InputSource *)inputsrc;
        
        [self.allLayers removeObjectForKey:inputsrc];
        for (NSString *nodeUID in pcmPlayers)
        {
            CSPcmPlayer *ply = [pcmPlayers objectForKey:nodeUID];
            [ply removePlayerForUUID:lsrc.uuid];
        }
        
        
        if (!self.tickInput)
        {
            for (id key in self.allLayers)
            {
                if (key)
                {
                    self.tickInput = key;
                }
            }
        }
        
        
        if (self.allLayers.count == 0 && !self.cachePersistent)
        {
            [self willDelete];
        }
    }
}



-(void)updateLayersWithFramedataBlock:(void (^)(CALayer *))updateBlock withPreuseBlock:(void(^)(void))preUseBlock withPostuseBlock:(void(^)(void))postUseBlock
{
    [self internalUpdateLayerswithFrameData:true updateBlock:updateBlock preBlock:preUseBlock postBlock:postUseBlock];

}

-(void)updateLayersWithFramedataBlock:(void(^)(CALayer *))updateBlock
{
    

    [self internalUpdateLayerswithFrameData:true updateBlock:updateBlock preBlock:nil postBlock:nil];

}

-(void)updateLayersWithBlock:(void (^)(CALayer *layer))updateBlock
{
    [self internalUpdateLayerswithFrameData:false updateBlock:updateBlock preBlock:nil postBlock:nil];
}

-(void)internalUpdateLayerswithFrameData:(bool) frameData updateBlock:(void (^)(CALayer *layer))updateBlock preBlock:(void(^)(void))preBlock postBlock:(void(^)(void))postBlock
{
    
    @autoreleasepool
    {
        
        
        NSMapTable *inputsCopy = nil;
        @synchronized(self)
        {
            inputsCopy = self.allLayers.copy;
        }
        
        if (frameData)
        {
            _fps_frame_cnt++;
        }
        
        
        for (id key in inputsCopy)
        {
            
            if (!key)
            {
                continue;
            }
            
            
            InputSource *layerSrc = (InputSource *)key;
            if (frameData)
            {
                [layerSrc updateLayersWithNewFrame:updateBlock withPreuseBlock:preBlock withPostuseBlock:postBlock];
            } else {
                [layerSrc updateLayer:updateBlock];
            }
        }
        
    }
    
}

-(CAMultiAudioEngine *)findAudioEngineForInput:(NSObject<CSInputSourceProtocol> *)input
{
    
    CAMultiAudioEngine *useEngine = nil;

    if (input && input.sourceLayout)
    {
        SourceLayout *layout = input.sourceLayout;

        if (layout.recorder && layout.recorder.audioEngine)
        {
            useEngine = layout.recorder.audioEngine;
        } else {
            
            useEngine = layout.audioEngine;
        }
    }
    
    if (!useEngine)
    {
        useEngine = [CaptureController sharedCaptureController].multiAudioEngine;
    }
    
    return useEngine;
}


-(CSPcmPlayer *)createPCMInput:(NSString *)forUID  withFormat:(const AudioStreamBasicDescription *)withFormat
{
    return [self createPCMInput:forUID named:forUID withFormat:withFormat];
}

-(CSPcmPlayer *)createPCMInput:(NSString *)forUID named:(NSString *)withName withFormat:(const AudioStreamBasicDescription *)withFormat
{
    @autoreleasepool
    {
        
        CAMultiAudioEngine *useEngine = nil;
        CSPcmPlayer *newPlayer = [[CSPcmPlayer alloc] init];
        [newPlayer setAudioFormat:withFormat];
        NSMapTable *inputsCopy = nil;
        @synchronized(self)
        {
            inputsCopy = self.allLayers.copy;
        }
        
        
        for (id key in inputsCopy)
        {
            
            if (!key)
            {
                continue;
            }
            
            
            InputSource *layerSrc = (InputSource *)key;
            
            useEngine = [self findAudioEngineForInput:layerSrc];

            CAMultiAudioPCMPlayer *player;
            
            if (useEngine)
            {
                
                player = [useEngine createPCMInput:forUID withFormat:withFormat];
            }
            
            if (player)
            {
                [newPlayer addPlayer:player forUUID:layerSrc.uuid];
                player.name = withName;
            }
        }
        
        
    
        newPlayer.nodeUID = forUID;
        
        [pcmPlayers setObject:newPlayer forKey:newPlayer.nodeUID];
        
        return newPlayer;
    }
}


-(void)removePCMPlayer:(CSPcmPlayer *)player
{
    [pcmPlayers removeObjectForKey:player.nodeUID];
}

-(void)removeAllPcmPlayers
{
    [pcmPlayers removeAllObjects];
}


-(void)frameArrived
{
    if (self.timerDelegate)
    {
        [self.timerDelegate frameArrived:self.timerDelegateCtx];
    }
}


-(void)setTimerDelegate:(id<CSTimerSourceProtocol>)timerDelegate
{
    if (timerDelegate)
    {
        _saved_render_behavior = self.renderType;
        self.renderType = kCSRenderFrameArrived;
    } else {
        self.renderType = _saved_render_behavior;
    }
    
    _timerDelegate = timerDelegate;
}

-(id<CSTimerSourceProtocol>)timerDelegate
{
    return _timerDelegate;
}


-(CALayer *)layerForInput:(id)inputsrc
{
    return [self.allLayers objectForKey:inputsrc];
}

-(void)setAllowScaling:(bool)allowScaling
{
    _allowScaling = allowScaling;
    [self updateLayersWithBlock:^(CALayer *layer) {
        [layer setValue:@(!allowScaling) forKey:@"csnoResize"];
    }];
}

-(bool)allowScaling
{
    return _allowScaling;
}


+(bool)canCreateSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    return NO;
}


+(void) layoutModification:(void (^)(void))modBlock
{
    //On main thread already, just execute the block, otherwise execute on main and wait
    if ([NSThread isMainThread])
    {
        modBlock();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            modBlock();
        });
    }
    
}

-(void)willExport
{
    return;
}


-(void)didExport
{
    return;
}

-(void)visibleStatusChangedForInput:(InputSource *)inputSource
{
    bool real_visible = NO;
    
    for (id key in self.allLayers)
    {
        if (!key)
        {
            continue;
        }
        InputSource *lSrc = key;
        if (lSrc.isVisible)
        {
            real_visible = YES;
        }
    }
    if (real_visible && pcmPlayers.count > 0)
    {
        for(NSString *pUUID in pcmPlayers)        {
            
            CSPcmPlayer *pPlayer = [pcmPlayers objectForKey:pUUID];
            if (pPlayer)
            {
                
                CAMultiAudioEngine *useEngine = [self findAudioEngineForInput:inputSource];
                
                if (useEngine)
                {
                    CAMultiAudioInput *realPlayer = [useEngine inputForUUID:pPlayer.nodeUID];
                    
                    if (inputSource.is_live)
                    {
                        
                        if (!realPlayer)
                        {
                            
                            AudioStreamBasicDescription *useDesc = [pPlayer audioDescription];
                            
                            if (useDesc)
                            {
                                CAMultiAudioPCMPlayer *newPlayer = [useEngine createPCMInput:pPlayer.nodeUID withFormat:useDesc];
                                newPlayer.name = pPlayer.name;
                                
                                [pPlayer addPlayer:newPlayer forUUID:inputSource.uuid];
                            }
                        }
                    } else {
                        if (realPlayer)
                        {
                            [useEngine removeInputAny:realPlayer];
                        }
                    }
                }
            }
        }
    }
    
    if (self.attachedAudioMap)
    {
        for(NSString *aUID in self.attachedAudioMap)
        {
            NSString *aName = [self.attachedAudioMap objectForKey:aUID];
            [self createAttachedAudioInputForUUID:aUID withName:aName];
            
        }
    }
    self.isVisible = real_visible;
}


-(void)activeStatusChangedForInput:(InputSource *)inputSource
{
    bool real_active = NO;
    
    for (id key in self.allLayers)
    {
        if (!key)
        {
            continue;
        }
        InputSource *lSrc = key;
        if (lSrc.active)
        {
            real_active = YES;
        }
    }
    
    self.isActive = real_active;
}

-(void)removeAttachedAudioInput:(NSString *)uuid
{
    
    @autoreleasepool
    {
        if (!uuid || !self.attachedAudioMap || ![self.attachedAudioMap objectForKey:uuid])
        {
            return;
        }
        
        
        [self.attachedAudioMap removeObjectForKey:uuid];
        
        NSMapTable *inputsCopy;
        
        @synchronized(self)
        {
            inputsCopy = self.allLayers.copy;
        }
        
        
        for (id key in inputsCopy)
        {
            
            if (!key)
            {
                continue;
            }
            
            
            InputSource *layerSrc = (InputSource *)key;
            
            
            if (layerSrc && layerSrc.sourceLayout)
            {
                CSAudioInputSource *aSrc = [layerSrc.sourceLayout findSourceForAudioUUID:uuid];
                [layerSrc.sourceLayout deleteSource:aSrc];
            }
        }
    }
}


-(void)changeAttachedAudioInputName:(NSString *)uuid withName:(NSString *)withName
{
    
    @autoreleasepool
    {
        if (!uuid || !withName)
        {
            return;
        }
        
        if (!self.attachedAudioMap)
        {
            self.attachedAudioMap = [NSMutableDictionary dictionary];
        }
        
        [self.attachedAudioMap setObject:withName forKey:uuid];
        
        NSMapTable *inputsCopy;
        
        @synchronized(self)
        {
            inputsCopy = self.allLayers.copy;
        }
        
        
        for (id key in inputsCopy)
        {
            
            if (!key)
            {
                continue;
            }
            
            
            InputSource *layerSrc = (InputSource *)key;
            
            
            if (layerSrc && layerSrc.sourceLayout)
            {
                CSAudioInputSource *aSrc = [layerSrc.sourceLayout findSourceForAudioUUID:uuid];
                
                if (aSrc)
                {
                    aSrc.name = withName;
                }
            }
        }
    }
}


//[self createPCMInput:self.captureName withFormat:audioFormat];

-(CSPcmPlayer *)createAttachedAudioInputForUUID:(NSString *)uuid withName:(NSString *)withName withFormat:(const AudioStreamBasicDescription *)withFormat
{
    if (!uuid)
    {
        return nil;
    }
    
    
    CSPcmPlayer *ret = [self createPCMInput:uuid named:withName withFormat:withFormat];
    [self createAttachedAudioInputForUUID:uuid withName:withName];
    return ret;
}


-(void)createAttachedAudioInputForUUID:(NSString *)uuid withName:(NSString *)withName
{
    if (!uuid)
    {
        return;
    }
    @autoreleasepool
    {
        if (!self.attachedAudioMap)
        {
            self.attachedAudioMap = [NSMutableDictionary dictionary];
        }
        
        
        
        [self.attachedAudioMap setObject:withName forKey:uuid];
        
        NSMapTable *inputsCopy;
        
        @synchronized(self)
        {
            inputsCopy = self.allLayers.copy;
        }
        
        
        for (id key in inputsCopy)
        {
            
            if (!key)
            {
                continue;
            }
            
            
            InputSource *layerSrc = (InputSource *)key;
            
            if (layerSrc && layerSrc.sourceLayout)
            {
                if (![layerSrc.sourceLayout findSourceForAudioUUID:uuid])
                {
                    CSAudioInputSource *newSrc = [[CSAudioInputSource alloc] init];
                    newSrc.audioUUID = uuid;
                    newSrc.name = withName;
                    [layerSrc.sourceLayout addSource:newSrc];
                    [layerSrc attachInput:newSrc];
                }
            }
        }
    }
}

    
-(void)liveStatusChangedForInput:(InputSource *)inputSource
{
    bool real_live = NO;
    
    for (id key in self.allLayers)
    {
        if (!key)
        {
            continue;
        }
        InputSource *lSrc = key;
        if (lSrc.is_live)
        {
            real_live = YES;
        }
    }
    self.isLive = real_live;

}



-(void)dealloc
{
    if (self.timerDelegate)
    {
        [self.timerDelegate frameTimerWillStop:self.timerDelegateCtx];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.timerDelegate = nil;
}


+(NSString *)uniqueIDFromPasteboardItem:(NSPasteboardItem *)item
{
    return nil;
}


+(NSObject <CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    return nil;
}

+(NSObject <CSCaptureSourceProtocol> *)createSourceFromPasteboardItem
{
    return nil;
}


+(NSSet *)mediaUTIs
{
    return nil;
}


@end
