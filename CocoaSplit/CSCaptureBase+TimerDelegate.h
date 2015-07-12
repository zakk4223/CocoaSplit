//
//  CSCaptureBase+CSCaptureBase_TimerDelegate.h
//  CocoaSplit
//
//  Created by Zakk on 7/11/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"
#import "CSTimerSourceProtocol.h"

@interface CSCaptureBase (TimerDelegate)

@property (weak) id<CSTimerSourceProtocol> timerDelegate;


@end
