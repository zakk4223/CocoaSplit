//
//  XPCListenerDelegate.m
//  CocoaSplit
//
//  Created by Zakk on 11/10/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import "XPCListenerDelegate.h"
#import "QTHelperProtocol.h"
#import <QTKit/QTKit.h>
#import <IOSurface/IOSurfaceAPI.h>

#import <CoreVideo/CoreVideo.h>
#import <QuickTime/QuickTime.h>


#import <xpc/xpc.h>


XPCListenerDelegate *captureDelegate;





@implementation XPCListenerDelegate


@synthesize captureDevice;
@synthesize captureSession;
@synthesize captureInput;
@synthesize captureOutput;
@synthesize xpcProxy;
@synthesize xpc_connection;







- (void) dealloc
{
 
    NSLog(@"HOLY SHIT DEALLOC");
    if (self.xpcProxy)
    {
        [self.xpcProxy release];
        
    }
    [super dealloc];

}


- (BOOL) listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{
    

    NSLog(@"SHOULD ACCEPT NEW CONNECTION\n");
    NSXPCInterface *helperInterface = [[NSXPCInterface interfaceWithProtocol:@protocol(QTHelperProtocol)] retain];
    NSXPCInterface *masterInterface = [[NSXPCInterface interfaceWithProtocol:@protocol(CapturedFrameProtocol)] retain];
    
    
    [newConnection setExportedInterface:helperInterface];
    [newConnection setExportedObject:self];
    
    [newConnection setRemoteObjectInterface:masterInterface];
    self.xpcProxy = [newConnection remoteObjectProxy];
    [self.xpcProxy retain];
    

    
    [newConnection resume];
    [helperInterface release];
    [masterInterface release];
    return YES;
}

- (void) listCaptureDevices:(void (^)(NSArray *r_devices))reply
{
    
    NSArray *devices = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
    NSLog(@"DEVICES IN HELPER %@", devices);
    
    NSMutableArray *retArray = [[NSMutableArray alloc] init];
    QTCaptureDevice *devinstance;
    
    for(devinstance in devices)
    {
        [retArray addObject: @{@"name" : [devinstance localizedDisplayName], @"id":devinstance.uniqueID}];
        
        
    }
    

    reply((NSArray *)retArray);
    [retArray release];
}


- (void) stopXPCCaptureSession
{
    if (self.captureSession)
    {
        [self.captureSession stopRunning];
        [self.captureSession release];
    }
    
    if (self.captureDevice)
    {
        [self.captureDevice close];
        [self.captureDevice release];
    }
    
    if (self.captureInput)
    {
        [self.captureInput release];
    }
    
    if (self.captureOutput)
    {
        [self.captureOutput release];
    }
    
    if (frameQueue)
    {
        dispatch_release(frameQueue);
    }
    
    
}


- (void) startXPCCaptureSession:(NSString *)captureID
{
    frameQueue = dispatch_queue_create("zakk.lol.frameQueue", NULL);
    
    self.captureSession = [[[QTCaptureSession alloc] init] retain];
    self.captureDevice = [[QTCaptureDevice deviceWithUniqueID:captureID] retain];
    [self.captureDevice open:nil];
    self.captureInput = [[[QTCaptureDeviceInput alloc] initWithDevice:self.captureDevice] retain];
    

    NSError *error;
    
    [self.captureSession addInput:self.captureInput error:&error];
    
    self.captureOutput = [[[QTCaptureDecompressedVideoOutput alloc] init] retain];
    

    NSDictionary *ioAttrs = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                        forKey: (NSString *)kIOSurfaceIsGlobal];
    
    NSMutableDictionary *pbAttrs = [NSMutableDictionary dictionaryWithObject:ioAttrs
                                                                      forKey: (NSString*)kCVPixelBufferIOSurfacePropertiesKey];
    
   [pbAttrs setObject: @[@(kCVPixelFormatType_422YpCbCr8), @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange), @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
                forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [self.captureOutput setPixelBufferAttributes:pbAttrs];
    
    [self.captureOutput setDelegate:self];
    [self.captureSession addOutput:self.captureOutput error:nil];
    
    
    [self.captureSession startRunning];
    
}


- (void) sendFrame:(CVImageBufferRef)newFrame
{
   
    
    
   if (newFrame)
   {
       IOSurfaceRef frameIOSurface = CVPixelBufferGetIOSurface(newFrame);
       xpc_object_t frameID = IOSurfaceCreateXPCObject(frameIOSurface);
 
       
       xpc_object_t xpc_frame_message = xpc_dictionary_create(NULL, NULL, 0);
       
       xpc_dictionary_set_value(xpc_frame_message, "capturedFrame", frameID);
       
       xpc_connection_send_message(self.xpc_connection, xpc_frame_message);
       
       xpc_release(frameID);
       xpc_release(xpc_frame_message);
       
       CVPixelBufferRelease(newFrame);
   }
    
}
- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputVideoFrame:(CVImageBufferRef)videoFrame withSampleBuffer:(QTSampleBuffer *)sampleBuffer fromConnection:(QTCaptureConnection *)connection
{

    
    CVPixelBufferRetain(videoFrame);
    
    
    dispatch_async(frameQueue, ^{
        [self sendFrame:videoFrame];
    });
    
    
}


@end


void qt_xpc_list_devices(xpc_connection_t conn, xpc_object_t event)
{
    
    NSArray *devices = [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeVideo];
    NSLog(@"DEVICES IN HELPER %@", devices);
    
    QTCaptureDevice *devinstance;
    
    xpc_object_t reply = xpc_dictionary_create_reply(event);
    
    xpc_object_t dev_array = xpc_array_create(NULL, 0);
    
    
    for(devinstance in devices)
    {
        xpc_object_t dev_xpc = xpc_dictionary_create(NULL, NULL, 0);
        
        xpc_dictionary_set_string(dev_xpc, "name", [[devinstance localizedDisplayName] UTF8String]);
        
        xpc_dictionary_set_string(dev_xpc, "id", [devinstance.uniqueID UTF8String]);
        
        xpc_array_append_value(dev_array, dev_xpc);
        
    }
    
    
    xpc_dictionary_set_value(reply, "capture_devices", dev_array);
    
    xpc_connection_send_message(conn, reply);
    
    xpc_release(dev_array);
    xpc_release(reply);
    
    
    
}


void qt_xpc_start_capture(xpc_connection_t conn, xpc_object_t event)
{

    const char *capture_id = xpc_dictionary_get_string(event, "capture_id");
    captureDelegate = [[XPCListenerDelegate alloc] init];
    captureDelegate.xpc_connection = conn;
    [captureDelegate startXPCCaptureSession:[[NSString alloc] initWithUTF8String:capture_id]];
}

void qt_xpc_stop_capture(xpc_connection_t conn, xpc_object_t event)
{
    
    if (captureDelegate)
    {
        [captureDelegate stopXPCCaptureSession];
    }
}


void qt_xpc_peer_event_handler(xpc_connection_t conn, xpc_object_t event)
{
    
    xpc_type_t event_type = xpc_get_type(event);
    
    if (event_type == XPC_TYPE_ERROR)
    {
        
    } else {
        const char *message = xpc_dictionary_get_string(event, "message");
        NSLog(@"RECEIVED XPC MESSAGE %s", message);
        
        if (!strcmp(message, "list_devices"))
        {
            
            qt_xpc_list_devices(conn, event);
            
        } else if (!strcmp(message, "start_capture")) {
            
            qt_xpc_start_capture(conn, event);
            
        } else if (!strcmp(message, "stop_capture")) {
            qt_xpc_stop_capture(conn, event);
            
        } else {
            NSLog(@"Unknown XPC message type!");
        }
        
    }
}
void qt_xpc_handle_connection(xpc_connection_t conn)
{
    
    
    xpc_connection_set_event_handler(conn, ^(xpc_object_t event) {
        qt_xpc_peer_event_handler(conn, event);
        
    });
    
    xpc_connection_resume(conn);
    
}
