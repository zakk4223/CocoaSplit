//
//  WindowCapture.h
//  CocoaSplit
//
//  Created by Zakk on 8/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"

@interface WindowCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    CFAbsoluteTime _nextCaptureTime;
    NSSize _lastSize;
}

@property (assign) float captureFPS;


@end
