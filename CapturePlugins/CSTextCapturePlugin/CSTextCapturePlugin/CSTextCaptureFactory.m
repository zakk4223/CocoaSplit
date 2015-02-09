//
//  CSTextCaptureFactory.m
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSTextCaptureFactory.h"

#import "TextCapture.h"
#import "FileTextCapture.h"


@implementation CSTextCaptureFactory



+(NSArray *)captureSourceClasses
{
    return @[[TextCapture class], [FileTextCapture class]];
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

