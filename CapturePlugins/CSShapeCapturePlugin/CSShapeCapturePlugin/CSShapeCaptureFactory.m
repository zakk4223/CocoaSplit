//
//  CSShapeCaptureFactory.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeCaptureFactory.h"

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
        NSString *pathLoaderPluginPath = [[NSBundle bundleForClass:[CSShapeCaptureFactory class]] pathForResource:@"CSShapePathLoader" ofType:@"plugin"];
        
        NSBundle *pathLoaderBundle = [NSBundle bundleWithPath:pathLoaderPluginPath];
    

        Class loaderClass = [pathLoaderBundle principalClass];
        
        
       sharedPathLoader = [[loaderClass alloc] init];
   });
    return sharedPathLoader;
}


@end
