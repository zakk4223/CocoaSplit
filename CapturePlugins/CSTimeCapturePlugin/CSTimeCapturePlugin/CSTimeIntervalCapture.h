//
//  CSTimeIntervalCapture.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/12/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeIntervalBase.h"

@interface CSTimeIntervalCapture : CSTimeIntervalBase
{
    CFTimeInterval _lastTime;
}


@property (assign) NSTimeInterval currentInterval;
@property (assign) NSTimeInterval countdownStart;
@property (assign) bool restartWhenLive;

-(void)reset;

@end
