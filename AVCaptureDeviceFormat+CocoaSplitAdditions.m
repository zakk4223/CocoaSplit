//
//  AVCaptureDeviceFormat+CocoaSplitAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 1/19/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "AVCaptureDeviceFormat+CocoaSplitAdditions.h"

@implementation AVCaptureDeviceFormat (CocoaSplitAdditions)

-(NSString *)localizedName
{
    NSString *localizedName = nil;
    
    CFStringRef formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions((CMVideoFormatDescriptionRef)[self formatDescription]);
    localizedName = [NSString stringWithFormat:@"%@, %d x %d", formatName, dimensions.width, dimensions.height];
    return localizedName;
}
@end
