//
//  CSCaptureSourceProtocolPrivate.h
//  CocoaSplit
//
//  Created by Zakk on 1/24/18.
//

#import <Foundation/Foundation.h>
#import "CSCaptureSourceProtocol.h"

@class InputSource;

@protocol CSCaptureSourceProtocolPrivate <CSCaptureSourceProtocol>


-(void)activeStatusChangedForInput:(InputSource *)inputSource;
-(void)liveStatusChangedForInput:(InputSource *)inputSource;

@end
