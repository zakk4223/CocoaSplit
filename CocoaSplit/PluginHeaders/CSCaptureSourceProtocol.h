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

//HEY YOU, DEVELOPER
//THIS IS ABSOLUTELY REQUIRED!!!! IF YOU DO CUSTOM UI FOR SETTING SOURCES
//YOU MUST CREATE AS DUMMY CSAbstractCaptureDevice AND MAKE SURE uniqueID IS SET TO SOMETHING

//activeVideoDevice.uniqueID is observed for changes and source deduplication happens this way
//if you aren't using availablevideo devices/active video device just create a dummy instance
//and set uniqueID to something uniquely generated for your source. That or just don't support
//deduplication. Be that way.
@property CSAbstractCaptureDevice *activeVideoDevice;

@property (strong) NSArray *availableVideoDevices;

@property (readonly) int render_width;

@property (readonly) int render_height;

@property (strong) NSString *captureName;

@property (strong) CIContext *imageContext;

@property (assign) bool needsSourceSelection;

@property (weak) id inputSource;



//Set this to true if you don't want source sharing/deduplication. You should really have a good reason
//for this.
@property (assign) bool allowDedup;

-(CIImage *)currentImage;
-(NSViewController *)configurationView;
-(CVImageBufferRef) getCurrentFrame;
+(NSString *) label;





@end
