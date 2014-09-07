//
//  CaptureBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureSourceProtocol.h"

@interface CSCaptureBase : NSObject <NSCoding, NSCopying>


@property CSAbstractCaptureDevice *activeVideoDevice;
@property (strong) NSArray *availableVideoDevices;
@property (strong) CIContext *imageContext;
@property (readonly) int render_width;
@property (readonly) int render_height;
@property (strong) NSString *captureName;
@property (strong) NSString *savedUniqueID;
@property (assign) bool needsSourceSelection;
//If you are accessing this in a plugin I will be very unhappy on the internet
@property (weak) id inputSource;


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



-(void)setDeviceForUniqueID:(NSString *)uniqueID;
-(CVImageBufferRef) getCurrentFrame;
-(CIImage *) currentImage;
-(NSView *)configurationView;
+(NSString *) label;


@end
