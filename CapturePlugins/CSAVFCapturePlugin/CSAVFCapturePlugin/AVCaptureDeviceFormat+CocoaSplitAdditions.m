//
//  AVCaptureDeviceFormat+CocoaSplitAdditions.m
//  CocoaSplit
//
//  Created by Zakk on 1/19/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "AVCaptureDeviceFormat+CocoaSplitAdditions.h"
#import "AVFrameRateRange+CocoaSplitAdditions.h"

@implementation AVCaptureDeviceFormat (CocoaSplitAdditions)

-(NSString *)localizedName
{
    NSString *localizedName = nil;
    
    CFStringRef formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions((CMVideoFormatDescriptionRef)[self formatDescription]);
    localizedName = [NSString stringWithFormat:@"%@, %d x %d %f", formatName, dimensions.width, dimensions.height, self.maxFramerate.maxFrameRate];
    
    
    return localizedName;
}

-(NSString *)description
{
    return [self localizedName];
}
-(NSDictionary *)saveDictionary
{
    
    CFStringRef formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions([self formatDescription]);
    return @{@"format": (__bridge_transfer NSString *)formatName, @"width": @(dimensions.width), @"height": @(dimensions.height)};
}


-(bool)compareToDictionary:(NSDictionary *)dict
{
    CFStringRef formatName = CMFormatDescriptionGetExtension([self formatDescription], kCMFormatDescriptionExtension_FormatName);
    
    NSString *cmp_format = dict[@"format"];
    
    if (![cmp_format isEqualToString:(__bridge NSString *)(formatName)])
    {
        return NO;
    }
    
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions([self formatDescription]);
    NSNumber *c_width = dict[@"width"];
    NSNumber *c_height = dict[@"height"];
    
    if ([c_width integerValue] == dimensions.width && [c_height integerValue] == dimensions.height)
    {
        return YES;
    }
    
    return NO;
}

-(AVFrameRateRange *)maxFramerate
{
    NSArray *sortedFramerates = [self.videoSupportedFrameRateRanges sortedArrayUsingSelector:@selector(compare:)];
    return sortedFramerates.lastObject;
}

-(NSInteger)pixelCount
{
    CMVideoDimensions myDims = CMVideoFormatDescriptionGetDimensions([self formatDescription]);
    return myDims.width * myDims.height;
}


-(NSComparisonResult)compare:(AVCaptureDeviceFormat *)otherObject
{
    NSComparisonResult frameRateRes = [self.maxFramerate compare:otherObject.maxFramerate];
    if (frameRateRes == NSOrderedSame)
    {
        CMVideoDimensions myDims = CMVideoFormatDescriptionGetDimensions([self formatDescription]);
        CMVideoDimensions otherDims = CMVideoFormatDescriptionGetDimensions([otherObject formatDescription]);
        NSUInteger myPixels = myDims.height * myDims.width;
        NSUInteger otherPixels = otherDims.height * otherDims.width;
        if (myPixels < otherPixels)
        {
            return NSOrderedAscending;
        } else if (myPixels > otherPixels) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
        
    }
    
    return frameRateRes;
}


@end
