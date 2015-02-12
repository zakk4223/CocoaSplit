//
//  CSTimeCaptureFactory.m
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTimeCaptureFactory.h"


@implementation CSTimeCaptureFactory



+(NSArray *)captureSourceClasses
{
    return @[[CSCurrentTimeCapture class], [CSElapsedTimeCapture class], [CSCountdownTimeCapture class], [CSTimeIntervalCapture class]];
}


+(NSArray *)streamServiceClasses
{
    return nil;
}

+(NSArray *)extraPluginClasses
{
    return nil;
}

@end
