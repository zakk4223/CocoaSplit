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


-(void)setDeviceForUniqueID:(NSString *)uniqueID;
-(CVImageBufferRef) getCurrentFrame;

@end
