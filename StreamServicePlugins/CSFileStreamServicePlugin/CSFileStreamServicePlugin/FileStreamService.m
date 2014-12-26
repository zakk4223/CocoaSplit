//
//  FileStreamService.m
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 8/29/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "FileStreamService.h"
#import "FileStreamServiceViewController.h"


@implementation FileStreamService



-(instancetype) init
{
    if(self = [super init])
    {
        self.isReady = YES;
    }
    return self;
}


-(NSViewController *)getConfigurationView
{
 
    FileStreamServiceViewController *configViewController;
    
    configViewController = [[FileStreamServiceViewController alloc] initWithNibName:@"FileStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}




-(NSString *)getServiceDestination
{
    
    return self.fileName;
}



+(NSString *)label
{
    return @"File/RTMP";
}


+(NSString *)serviceDescription
{
    return @"File/RTMP";
}

@end
