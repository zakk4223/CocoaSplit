//
//  CSVaughnliveStreamService.m
//  CSVaughnliveStreamServicePlugin
//
//  Created by Zakk on 5/31/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSVaughnliveStreamService.h"
#import "CSVaughnliveStreamServiceViewController.h"


@implementation CSVaughnliveStreamService

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
    
    CSVaughnliveStreamServiceViewController *configViewController;
    
    configViewController = [[CSVaughnliveStreamServiceViewController alloc] initWithNibName:@"CSVaughnliveStreamServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}




-(NSString *)getServiceDestination
{
    NSString *destination = nil;
    if (self.streamKey)
    {
        destination = [NSString stringWithFormat:@"%@%@", INGEST_URL, self.streamKey];
    }
    return destination;
}

+(NSImage *)serviceImage
{
    return [[NSBundle bundleForClass:[self class]] imageForResource:@"vaughnlive_icon"];
}


+(NSString *)label
{
    return @"Vaughnlive.TV";
}


+(NSString *)serviceDescription
{
    return @"Vaughnlive.TV";
}


@end
