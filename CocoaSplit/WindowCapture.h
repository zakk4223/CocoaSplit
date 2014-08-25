//
//  WindowCapture.h
//  CocoaSplit
//
//  Created by Zakk on 8/23/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CaptureBase.h"

@interface WindowCapture : CaptureBase
{
    CFAbsoluteTime _nextCaptureTime;
    CIImage *_currentFrame;
    
}

@property (assign) float captureFPS;

@end
