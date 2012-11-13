//
//  QTHelperProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 11/10/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol QTHelperProtocol 
- (void)listCaptureDevices:(void (^)(NSArray *r_devices))reply;
- (void)startXPCCaptureSession:(NSString *)captureID;
- (void)stopXPCCaptureSession;


- (void)testMethod;

@end
