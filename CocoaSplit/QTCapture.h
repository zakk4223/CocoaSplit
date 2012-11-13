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
#import "CaptureSessionProtocol.h"
#import "CapturedFrameProtocol.h"
#import "QTHelperProtocol.h"

@interface QTCapture : NSObject <CaptureSessionProtocol, CapturedFrameProtocol>
{
    NSXPCConnection *_xpcConnection;
    id <QTHelperProtocol> _xpcProxy;
    IOSurfaceRef _currentFrame;
    
}


@property (strong) id videoInputDevice;
@property (strong) id videoDelegate;
@property (assign) int videoCaptureFPS;


-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;



@end

