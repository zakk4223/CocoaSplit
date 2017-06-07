//
//  CSShapeCaptureFactory.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <objc/runtime.h>

#import "CSShapeCaptureFactory.h"
#import "CSPluginServices.h"
#import "NSBezierPathJSExport.h"
@implementation CSShapeCaptureFactory



+(NSArray *)captureSourceClasses
{
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [CSShapeCaptureFactory sharedPathLoader];
    });
     */
    Class ret = [CSShapeCapture class];

    return @[ret];
}


+(NSArray *)streamServiceClasses
{
    return nil;
}


+(NSArray *)extraPluginClasses
{
    return nil;
}

+(CSShapePathLoader *) sharedPathLoader
{
    static CSShapePathLoader *sharedPathLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        //[[CSPluginServices sharedPluginServices] exportClassForJavaScript:[NSBezierPath class]];
        
        class_addProtocol([NSBezierPath class], @protocol(NSBezierPathJSExport));
        
        sharedPathLoader = [[CSShapePathLoader alloc] init];
        
   });
    return sharedPathLoader;
}


@end
