//
//  CaptureSessionProtocol.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CSAbstractCaptureDevice.h"
#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>





@protocol CSCaptureSourceProtocol

@required

@property CSAbstractCaptureDevice *activeVideoDevice;
@property (strong) NSArray *availableVideoDevices;
@property (assign) int render_width;
@property (assign) int render_height;
@property (strong) NSString *captureName;
@property (strong) CIContext *imageContext;
@property (assign) bool needsSourceSelection;

-(CIImage *)currentImage;
-(NSViewController *)configurationView;
-(CVImageBufferRef) getCurrentFrame;
+(NSString *) label;





@end
