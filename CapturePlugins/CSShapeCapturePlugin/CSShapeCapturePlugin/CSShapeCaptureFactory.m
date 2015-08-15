//
//  CSShapeCaptureFactory.m
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSShapeCaptureFactory.h"
#import "CSPluginServices.h"

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
        CSPluginServices *sharedService = [CSPluginServices sharedPluginServices];
        
        
        NSString *pathLoaderFilePath = [[NSBundle bundleForClass:[CSShapeCaptureFactory class]] pathForResource:@"CSShapePathLoader" ofType:@"py" inDirectory:@"Python"];
        
    
        Class loaderClass = [sharedService loadPythonClass:@"CSShapePathLoader" fromFile:pathLoaderFilePath];
       sharedPathLoader = [[loaderClass alloc] init];
   });
    return sharedPathLoader;
}


@end
