//
//  QTCapture.m
//  CocoaSplit
//
//  Created by Zakk on 11/6/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "QTCapture.h"
#import "CSAbstractCaptureDevice.h"
#import "QTHelperProtocol.h"
#import "CapturedFrameProtocol.h"

@implementation QTCapture

@synthesize activeVideoDevice = _activeVideoDevice;
@synthesize availableVideoDevices = _availableVideoDevices;


void qtc_xpc_event_handler(xpc_connection_t conn, xpc_object_t event)
{
    
    xpc_type_t event_type = xpc_get_type(event);
    
    if (event_type == XPC_TYPE_ERROR)
    {
        
    } else {
        
        NSLog(@"Got a reply message!?");
        
    }
}

-(id) init
{
    self = [super init];
    if (self)
    {
        
        self.videoCaptureFPS = 60.0f;
        self.xpc_conn = xpc_connection_create("zakk.lol.QTCaptureHelper", NULL);
        self.xpc_queue = dispatch_queue_create("qtc_capture_queue", NULL);
        
        xpc_connection_set_event_handler(self.xpc_conn,  ^(xpc_object_t event) {
            xpc_type_t event_type = xpc_get_type(event);
            
            if (event_type == XPC_TYPE_ERROR)
            {
                
                
            } else {
                xpc_object_t xpc_frame = xpc_dictionary_get_value(event, "capturedFrame");
                
                if (xpc_frame)
                {
                    IOSurfaceRef newFrame = IOSurfaceLookupFromXPCObject(xpc_frame);
                    [self newCapturedFrame:newFrame];
                    xpc_frame = nil;
                }
            }
        });
        
        
        xpc_connection_resume(self.xpc_conn);
        
        
        
        [self updateAvailableVideoDevices];
        
    
    }
    return self;
    
}




-(CSAbstractCaptureDevice *)activeVideoDevice
{
    return _activeVideoDevice;
}

-(void)setActiveVideoDevice:(CSAbstractCaptureDevice *)activeVideoDevice
{
    _activeVideoDevice = activeVideoDevice;
    [self stopCaptureSession];
    [self startCaptureSession];
    
}




-(bool) providesVideo
{
    return YES;
}

-(bool) providesAudio
{
    return NO;
}



-(void) updateAvailableVideoDevices
{
    
    
    
    NSMutableArray *__block retArray;
    
    xpc_object_t listMessage = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(listMessage, "message", "list_devices");
    
    xpc_connection_send_message_with_reply(self.xpc_conn, listMessage, self.xpc_queue, ^(xpc_object_t reply) {
        
        retArray =  [[ NSMutableArray alloc] init];
        xpc_object_t capture_devs = xpc_dictionary_get_value(reply, "capture_devices");

        xpc_array_apply(capture_devs, ^bool(size_t index, xpc_object_t capture_dev_dict) {
            
            const char *cap_name = xpc_dictionary_get_string(capture_dev_dict, "name");
            const char *cap_id = xpc_dictionary_get_string(capture_dev_dict, "id");
            NSString *ns_name = [[NSString alloc] initWithUTF8String:cap_name];
            NSString *ns_id = [[NSString alloc] initWithUTF8String:cap_id];
            
            [retArray addObject:[[CSAbstractCaptureDevice alloc]  initWithName:ns_name device:ns_id uniqueID:ns_id]];
            return true;
            
        });
        
        [self willChangeValueForKey:@"availableVideoDevices"];
        _availableVideoDevices = (NSArray *)retArray;
        [self didChangeValueForKey:@"availableVideoDevices"];
        
    });
    
}

-(void) newCapturedFrame:(IOSurfaceRef)frameIOref
{
    if (!frameIOref)
    {
        
        return;
    }
    
    
    IOSurfaceIncrementUseCount(frameIOref);
    

    if (frameIOref)
    {
        @synchronized(self)
        {
            if (_currentFrame)
            {
                IOSurfaceDecrementUseCount(_currentFrame);

                CFRelease(_currentFrame);
            }
            
            _currentFrame = frameIOref;
        }
    }
}




-(bool) stopCaptureSession
{
    [_xpcProxy stopXPCCaptureSession];
    return YES;
}


-(bool) startCaptureSession
{
    
    
    if (!self.activeVideoDevice)
    {
        return NO;
    }
    
    
    xpc_object_t start_msg = xpc_dictionary_create(NULL, NULL, 0);
    
    xpc_dictionary_set_string(start_msg, "message", "start_capture");
    xpc_dictionary_set_string(start_msg, "capture_id", [self.activeVideoDevice.uniqueID UTF8String]);
    
    
    xpc_connection_send_message(self.xpc_conn, start_msg);
    
    return YES;
}


void QTPixelBufferRelease(void *releaseRefCon, const void *baseAddress)
{
    
    if (baseAddress)
        free((void *)baseAddress);
    
    
}

- (CVImageBufferRef) getCurrentFrame
{

    CVImageBufferRef newbuf = NULL;
    
    @synchronized(self)
    {
        if (_currentFrame)
        {
            CVPixelBufferCreateWithIOSurface(NULL, _currentFrame, NULL, &newbuf);
        }
        
    }
    
    return newbuf;
    
    

    
    
}


@end
