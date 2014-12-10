//
//  CSSyphonCaptureFactory.m
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSSyphonCaptureFactory.h"
#import "SyphonCapture.h"
#import "CSSyphonInjectCapture.h"

@implementation CSSyphonCaptureFactory



+(NSArray *)captureSourceClasses
{
    return @[[SyphonCapture class], [CSSyphonInjectCapture class]];
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
