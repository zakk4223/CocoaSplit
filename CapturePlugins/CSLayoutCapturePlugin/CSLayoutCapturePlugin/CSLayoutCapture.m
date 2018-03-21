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
    if (_current_renderer)
    {
        SourceLayoutHack *capDev = [_current_renderer valueForKey:@"layout"];
        capDev.isActive = isLive;
    }
}

-(instancetype)init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutChanged:) name:CSNotificationLayoutSaved object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutDeleted:) name:CSNotificationLayoutDeleted object:nil];

        self.allowDedup = NO;
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

+(NSObject<CSCaptureSourceProtocol> *)createSourceFromPasteboardItem:(NSPasteboardItem *)item
{
    NSData *indexData = [item dataForType:@"cocoasplit.layout"];
    NSIndexSet *indexes = [NSKeyedUnarchiver unarchiveObjectWithData:indexData];
    
    if (!indexes)
    {
        return nil;
    }
    
    NSInteger draggedItemIdx = [indexes firstIndex];
    NSObject *controller = [[CSPluginServices sharedPluginServices] captureController];
    NSArray *layouts = [controller valueForKey:@"sourceLayouts"];

    NSObject *useLayout = [layouts objectAtIndex:draggedItemIdx];
    if (useLayout)
    {
        NSString *layoutName = [useLayout valueForKey:@"name"];
        CSLayoutCapture *ret = [[CSLayoutCapture alloc] init];
        ret.activeVideoDevice = [[CSAbstractCaptureDevice alloc] initWithName:layoutName device:useLayout uniqueID:layoutName];
        return ret;
    }
    
    return nil;
}


-(NSArray *)availableVideoDevices
{
    NSObject *controller = [[CSPluginServices sharedPluginServices] captureController];
    NSMutableArray *ret = [NSMutableArray array];
    NSArray *layouts = [controller valueForKey:@"sourceLayouts"];
    for (NSObject *layout in layouts)
    {
        NSString *layoutName = [layout valueForKey:@"name"];
        
        CSAbstractCaptureDevice *dev = [[CSAbstractCaptureDevice alloc] initWithName:layoutName device:layout uniqueID:layoutName];
        [ret addObject:dev];
    }
    
    return ret;
}


-(void)setupRenderer
{
    Class renderClass = NSClassFromString(@"LayoutRenderer");
    
    self.captureName = self.activeVideoDevice.captureName;
    SourceLayoutHack *capDev = [self.activeVideoDevice.captureDevice copy];
    capDev.isActive = self.isLive;
    SEL restoreSEL = NSSelectorFromString(@"restoreSourceList:");
    [capDev performSelector:restoreSEL withObject:nil];
    @synchronized(self)
    {
        if (!_current_renderer)
        {
            _current_renderer = [[renderClass alloc] init];
        }
    }
    

    [_current_renderer setValue:capDev forKey:@"layout"];
}


-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    
    [super setActiveVideoDevice:activeVideoDevice];
     
     [self setupRenderer];
}

-(NSSize)captureSize
{
    if (self.activeVideoDevice)
    {
        SourceLayoutHack *capDev = self.activeVideoDevice.captureDevice;
        return NSMakeSize(capDev.canvas_width, capDev.canvas_height);
    }
    return NSZeroSize;
}

-(CALayer *)createNewLayer
{
    return [CALayer layer];
}


-(void)frameTick
{
    
    LayoutRendererHack *renderer = nil;
    @synchronized(self)
    {
        renderer = _current_renderer;
    }
    if (renderer)
    {
        CVImageBufferRef pb = [renderer currentImg];
        

        
        [self updateLayersWithFramedataBlock:^(CALayer *layer) {
            
            if (pb)
            {
                layer.contents = (__bridge id _Nullable)(pb);
            } else {
                layer.contents = nil;
            }
            
        } withPreuseBlock:^{
            if (pb)
                CFRetain(pb);
        } withPostuseBlock:^{
            if (pb)
                CFRelease(pb);
        }];

    }
}

@end
