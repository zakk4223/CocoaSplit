//
//  CSCaptureBase+InputFrameTick.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"

@class InputSource;

@interface CSCaptureBase (InputFrameTick)
-(void)frameTickFromInput:(InputSource *)input;
@property (weak) InputSource *tickInput;

@end

@protocol CSCaptureBaseInputFrameTickProtocol
-(void)frameTickFromInput:(InputSource *)input;
@end
