//
//  CaptureBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/21/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureSessionProtocol.h"


@interface CaptureBase : NSObject <NSCoding>

@property AbstractCaptureDevice *activeVideoDevice;
@property (strong) NSArray *availableVideoDevices;
@property (strong) CIContext *imageContext;
@property (assign) int render_width;
@property (assign) int render_height;
@property (strong) NSString *captureName;
//Blackmagic hack
@property (strong) NSString *savedUniqueID;


-(void)setDeviceForUniqueID:(NSString *)uniqueID;
-(CVImageBufferRef) getCurrentFrame;

@end
