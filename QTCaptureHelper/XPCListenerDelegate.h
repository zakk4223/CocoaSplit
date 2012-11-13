//
//  XPCListenerDelegate.h
//  CocoaSplit
//
//  Created by Zakk on 11/10/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QTHelperProtocol.h"
#import "CapturedFrameProtocol.h"
#import <QTKit/QTKit.h>

@interface XPCListenerDelegate : NSObject <NSXPCListenerDelegate, QTHelperProtocol>
{
    QTCaptureDevice *captureDevice;
    QTCaptureSession *captureSession;
    QTCaptureDeviceInput *captureInput;
    QTCaptureDecompressedVideoOutput *captureOutput;
    id <CapturedFrameProtocol> xpcProxy;
    dispatch_queue_t frameQueue;
    
    
}


@property (strong) QTCaptureDevice *captureDevice;
@property (strong) QTCaptureSession *captureSession;
@property (strong) QTCaptureDeviceInput *captureInput;
@property (strong) QTCaptureDecompressedVideoOutput *captureOutput;
@property (strong) id xpcProxy;


- (BOOL) listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection;
@end
