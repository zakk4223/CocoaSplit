//
//  CSTimeCaptureFactory.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPluginFactoryProtocol.h"
#import "CSCurrentTimeCapture.h"
#import "CSElapsedTimeCapture.h"
#import "CSCountdownTimeCapture.h"


@interface CSTimeCaptureFactory : NSObject <CSPluginFactoryProtocol>


+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;

@end
