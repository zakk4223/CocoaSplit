//
//  CSLayoutCapture.m
//  CSLayoutCapturePlugin
//
//  Created by Zakk on 8/11/17.
//

#import "CSLayoutCapture.h"
#import "CSPluginServices.h"
#import "CSIOSurfaceLayer.h"
#import "CSNotifications.h"


@interface InputSourceHack
-(void)autoFit;
@property (assign) CGFloat crop_left;
@property (assign) CGFloat crop_right;
@property (assign) CGFloat crop_top;
@property (assign) CGFloat crop_bottom;
@property (assign) bool autoPlaceOnFrameUpdate;
@property (assign) bool wasAutoplaced;
@property (strong) NSString *name;
@property (assign) NSRect layoutPosition;

@end

@implementation CSLayoutCapture

+(NSString *)label
{
    return @"Layout";
}


+(NSSet *)mediaUTIs
{
    return [NSSet setWithArray:@[@"cocoasplit.layout"]];
}

-(void)setIsLive:(bool)isLive
{
    [super setIsLive:isLive];
    if (_current_layout)
    {
        _current_layout.isActive = isLive;
    }
}

-(float)duration
{
    float maxDuration = 0.0f;
    
    if (_current_layout)
    {
        for (NSObject *inp in _current_layout.sourceList)
        {
            float inp_duration = [[inp valueForKey:@"duration"] floatValue];
            if (inp_duration > maxDuration)
            {
                maxDuration = inp_duration;
            }
        }
    }
    return maxDuration;
}


-(instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:CSNotificationLayoutSaved object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutDeleted:) name:CSNotificationLayoutDeleted object:nil];

        self.allowDedup = NO;
        _last_frame_size = NSZeroSize;
        _last_crop_rect = NSZeroRect;
        _cropNamePattern = nil ;
        _pcmPlayers = [NSMutableDictionary dictionary];
    }
    return self;
}


-(void)layoutChanged:(NSNotification *)notification
{
    NSObject *changedLayout = [notification object];
    
    if (self.activeVideoDevice && (self.activeVideoDevice.captureDevice == changedLayout))
    {
        [self setupRenderer];
    }
}

/*
-(void)layoutDeleted:(NSNotification *)notification
{
    NSObject *deletedLayout = [notification object];
    
    if (self.activeVideoDevice && (self.activeVideoDevice.captureDevice == deletedLayout) && _current_renderer)
    {
        @synchronized(self)
        {
            [_current_renderer setValue:nil forKey:@"layout"];
            _current_renderer = nil;
        }
    }
}
*/

+(NSObject<CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    NSData *indexData = [item dataForType:@"cocoasplit.layout"];
    NSString *draggedUUID = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];
   // NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];
    /*
    if (!indexes)
    {
        return nil;
    }
    
    NSInteger draggedItemIdx = [indexes firstIndex];
     */
    NSObject *controller = [[CSPluginServices sharedPluginServices] captureController];
    NSArray *layouts = [controller valueForKey:@"sourceLayouts"];

    SourceLayoutHack *useLayout = nil;
    for (SourceLayoutHack *tmp in layouts)
    {
        if ([tmp.uuid isEqualToString:draggedUUID])
        {
            useLayout = tmp;
        }
    }
    
    //SourceLayoutHack *useLayout = [layouts objectAtIndex:draggedItemIdx];

    if (useLayout)
    {
        NSString *layoutName = [useLayout valueForKey:@"name"];
        NSString *layoutUUID = [useLayout valueForKey:@"uuid"];
        CSLayoutCapture *ret = [[CSLayoutCapture alloc] init];
        ret.activeVideoDevice = [[CSAbstractCaptureDevice alloc] initWithName:layoutName device:useLayout uniqueID:layoutUUID];
        return ret;
    }
    
    return nil;
}


-(NSArray *)availableVideoDevices
{
    NSObject *controller = [[CSPluginServices sharedPluginServices] captureController];
    NSMutableArray *ret = [NSMutableArray array];
    NSArray *layouts = [controller valueForKey:@"sourceLayouts"];
    NSMutableArray *useLayouts = layouts.mutableCopy;
    
    SourceLayoutHack *liveLayout = [controller valueForKey:@"activeLayout"];
    SourceLayoutHack *stagingLayout = [controller valueForKey:@"stagingLayout"];
    if (liveLayout)
    {
        [useLayouts addObject:liveLayout];
    }
    
    if (stagingLayout)
    {
        [useLayouts addObject:stagingLayout];
    }
    
    
    for (NSObject *layout in useLayouts)
    {
        NSString *layoutName = [layout valueForKey:@"name"];
        NSString *layoutUUID = [layout valueForKey:@"uuid"];
        CSAbstractCaptureDevice *dev = [[CSAbstractCaptureDevice alloc] initWithName:layoutName device:nil uniqueID:layoutUUID];
        NSLog(@"ADDED %@: %@", layoutName, layoutUUID);
        [ret addObject:dev];
    }
    

    return ret;
}


-(SourceLayoutHack *)capturedLayout
{

    NSObject *controller = [[CSPluginServices sharedPluginServices] captureController];
    SEL layoutSEL = NSSelectorFromString(@"sourceLayoutForUUID:");
    SourceLayoutHack *origDev = [controller performSelector:layoutSEL withObject:self.activeVideoDevice.uniqueID];
    if (!origDev)
    {
        return nil;
    }
    //SourceLayoutHack *capDev = [origDev copy];
    return origDev;
}


-(void)setupRenderer
{
    Class outputClass = NSClassFromString(@"OutputDestination");

    self.captureName = self.activeVideoDevice.captureName;
    
    SourceLayoutHack *origDev = [self capturedLayout];
    NSLog(@"ORIGINAL DEV IS %@", origDev);
    if (!origDev)
    {
        return;
    }
    _current_layout = origDev;
    _out_dest = [[outputClass alloc] init];
    _out_dest.assignedLayout = origDev;
    _out_dest.compressor_name = @"PassthroughNoCopy";
    _out_dest.ffmpeg_out = self;
    _out_dest.alwaysStart = YES;
    _out_dest.active = YES;
    

}





-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    
    [super setActiveVideoDevice:activeVideoDevice];
     
     [self setupRenderer];
}

-(NSSize)captureSize
{
    return _last_frame_size;
}


-(CALayer *)createNewLayer
{
    CALayer *layer = [CALayer layer];
    return layer;
}


-(void)saveWithCoder:(NSCoder *)aCoder
{
    [super saveWithCoder:aCoder];
    
    [aCoder encodeObject:self.cropNamePattern forKey:@"cropNamePattern"];
}


-(void)restoreWithCoder:(NSCoder *)aDecoder
{
    [super restoreWithCoder:aDecoder];
    self.cropNamePattern = [aDecoder decodeObjectForKey:@"cropNamePattern"];
}


-(void)setupInputCropping:(NSRect )sourceRect
{
    CGFloat left;
    CGFloat right;
    CGFloat top;
    CGFloat bottom;
    
    if (NSEqualRects(sourceRect, _last_crop_rect))
    {
        return;
    }
    
    _last_crop_rect = sourceRect;
    
    if (NSEqualRects(sourceRect, NSZeroRect))
    {
        left = right = top = bottom = 0.0f;
    } else {
        left = sourceRect.origin.x/_last_frame_size.width;
        right = (_last_frame_size.width - NSMaxX(sourceRect))/_last_frame_size.width;
        top = sourceRect.origin.y/_last_frame_size.height;
        bottom = (_last_frame_size.height - NSMaxY(sourceRect))/_last_frame_size.height;
    }
    [self updateInputWithBlock:^(id input) {
        InputSourceHack *useInput = input;
        
        useInput.crop_top = top;
        useInput.crop_bottom = bottom;
        useInput.crop_left = left;
        useInput.crop_right = right;
        [useInput autoFit];
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
            [useInput autoFit];
        });*/
    }];
    
}
-(InputSourceHack *)findInputMatch:(NSString *)matchPattern
{
    NSRegularExpression *matchRE = [NSRegularExpression regularExpressionWithPattern:matchPattern options:0 error:nil];
    
    for (InputSourceHack *inp in _current_layout.sourceList)
    {
        NSUInteger matchCnt = [matchRE numberOfMatchesInString:inp.name options:0 range:NSMakeRange(0,inp.name.length)];
        if (matchCnt > 0)
        {
            return inp;
        }
    }
    return nil;
}


-(bool)queueFramedata:(CapturedFrameDataHack *)frameData
{
    CVImageBufferRef useImage = CMSampleBufferGetImageBuffer(frameData.encodedSampleBuffer);
    if (useImage)
    {
       _last_frame_size = NSMakeSize(CVPixelBufferGetWidth(useImage), CVPixelBufferGetHeight(useImage));
        NSRect useCropRect = NSZeroRect;
        if (self.cropNamePattern)
        {
            InputSourceHack *matchedInp = [self findInputMatch:self.cropNamePattern];
            if (matchedInp)
            {
                NSRect inputRect = matchedInp.layoutPosition;
                useCropRect = inputRect;
            }
        }
        
        
        
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            layer.contents = (__bridge id _Nullable)useImage;
        } withPreuseBlock:^{
            CFRetain(useImage);
        } withPostuseBlock:^{
            CFRelease(useImage);
        }];
        
        [self setupInputCropping:useCropRect];
    }
    NSString *audioTrackkey = nil;

    
    for (NSString *audioTrackkey in frameData.pcmAudioSamples)
    {
        NSArray *pcmSamples = frameData.pcmAudioSamples[audioTrackkey];
        for (id object in pcmSamples)
        {
            CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)object;
            CSPcmPlayer *pcmPlayer = _pcmPlayers[audioTrackkey];
            if (!pcmPlayer)
            {
                CMFormatDescriptionRef sDescr = CMSampleBufferGetFormatDescription(sampleBuffer);
                const AudioStreamBasicDescription *asbd =  CMAudioFormatDescriptionGetStreamBasicDescription(sDescr);
                NSString *trackName = [[CSPluginServices sharedPluginServices] nameForAudioTrackUUID:audioTrackkey];
                if (!trackName)
                {
                    trackName = @"";
                }
                
                NSString *pcmName = [NSString stringWithFormat:@"%@ - %@", self.activeVideoDevice.captureName, trackName];
                
                pcmPlayer = [self createAttachedAudioInputForUUID:audioTrackkey withName:pcmName withFormat:asbd];
                _pcmPlayers[audioTrackkey] = pcmPlayer;
            }
            
            if (pcmPlayer)
            {
                [pcmPlayer scheduleBuffer:sampleBuffer];
            }
        }
        
    }

    return YES;
}


-(bool) stopProcess
{
    return YES;
}

-(bool)errored
{
    return NO;
}

-(void)initStatsValues
{
    return;
}

-(NSUInteger)frameQueueSize
{
    return 0;
}

-(int) output_framecnt
{
    return 0;
}

-(NSUInteger) output_bytes
{
    return 0;
}

-(NSUInteger) buffered_frame_count
{
    return 0;
}
-(NSUInteger) buffered_frame_size
{
    return 0;
}

-(void)willDelete
{
    if (_out_dest)
    {
        _out_dest.active = NO;
    }
    _out_dest = nil;
    _current_layout = nil;
}


-(void)dealloc
{
    NSLog(@"DEALLOC LAYOUT INPUT");
}
@end
