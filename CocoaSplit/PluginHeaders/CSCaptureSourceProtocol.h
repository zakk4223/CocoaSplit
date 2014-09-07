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


//These are set as state changes/events happen. You can check their values in your code at anytime
//or observe them or override the setter/getter to do whatever you'd like.

//Are we selected in the UI?
@property (assign) bool isSelected;

//If the source is part of a multi-source input this flag is set when it isn't the source being displayed
@property (assign) bool isVisible;

//Your active status (active checkbox in config UI). If an input isn't active currentImage/getCurrentFrame aren't
//called. You can use this to pause timers or deallocate resources if you want.
@property (assign) bool isActive;

-(CIImage *)currentImage;
-(NSViewController *)configurationView;
-(CVImageBufferRef) getCurrentFrame;
+(NSString *) label;





@end
