//
//  CaptureBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSCaptureSourceProtocol.h"

@interface CSCaptureBase : NSObject <NSCoding>


@property CSAbstractCaptureDevice *activeVideoDevice;
@property (strong) NSArray *availableVideoDevices;
@property (strong) CIContext *imageContext;
@property (assign) int render_width;
@property (assign) int render_height;
@property (strong) NSString *captureName;
//Blackmagic hack
@property (strong) NSString *savedUniqueID;
@property (assign) bool needsSourceSelection;



-(void)setDeviceForUniqueID:(NSString *)uniqueID;
-(CVImageBufferRef) getCurrentFrame;
-(CIImage *) currentImage;
-(NSView *)configurationView;
+(NSString *) label;


@end
