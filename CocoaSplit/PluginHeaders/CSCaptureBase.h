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


-(void)setDeviceForUniqueID:(NSString *)uniqueID;
-(CVImageBufferRef) getCurrentFrame;
-(CIImage *) currentImage;
-(NSView *)configurationView;
+(NSString *) label;


@end
