//
//  QTCapture.h
//  CocoaSplit
//
//  Created by Zakk on 11/6/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <QTKit/QTKit.h>
#import "CaptureBase.h"
#import "CapturedFrameProtocol.h"
#import "QTHelperProtocol.h"

@interface QTCapture : CaptureBase <CaptureSessionProtocol>
{
    NSXPCConnection *_xpcConnection;
    id <QTHelperProtocol> _xpcProxy;
    IOSurfaceRef _currentFrame;
    
}



@property double videoCaptureFPS;
@property int width;
@property int height;
@property (readonly) BOOL needsAdvancedVideo;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;
@property xpc_connection_t xpc_conn;
@property dispatch_queue_t xpc_queue;





-(bool) stopCaptureSession;



@end

