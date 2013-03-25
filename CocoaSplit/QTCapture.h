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



@property int videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property id videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;
@property NSArray *videoFormats;
@property NSArray *videoFramerates;



-(bool) startCaptureSession:(NSError **)error;
-(bool) stopCaptureSession;
-(void) setVideoDimensions:(int)width height:(int)height;
-(bool) setupCaptureSession:(NSError **)therror;



@end

