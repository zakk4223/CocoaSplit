//
//  CSCaptureBaseInputFrameTickProtocol.m
//  CocoaSplit
//
//  Created by Zakk on 1/25/18.
//

#import <Foundation/Foundation.h>
#import "InputSource.h"

@protocol CSCaptureBaseInputFrameTickProtocol
-(void)frameTickFromInput:(InputSource *)input;
@end
