//
//  CSFileStreamRTMPService.m
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import "CSFileStreamRTMPService.h"
#import "CSFileStreamRTMPServiceViewController.h"


@implementation CSFileStreamRTMPService

-(instancetype) init
{
    if(self = [super init])
    {
        self.isReady = YES;
    }
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.destinationURI forKey:@"destinationURI"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.destinationURI = [aDecoder decodeObjectForKey:@"destinationURI"];
    }
    
    return self;
}


-(NSViewController *)getConfigurationView
{
    
    CSFileStreamRTMPServiceViewController *configViewController;
    
    configViewController = [[CSFileStreamRTMPServiceViewController alloc] initWithNibName:@"CSFileStreamRTMPServiceViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}



-(NSString *)getServiceFormat
{
    return @"FLV";
}



-(NSString *)getServiceDestination
{
    
    return self.destinationURI;
}



+(NSString *)label
{
    return @"RTMP/Network";
}


+(NSString *)serviceDescription
{
    return @"RTMP/Network";
}

+(NSImage *)serviceImage
{
    return [NSImage imageNamed:NSImageNameNetwork];
}


-(void)prepareForStreamStart
{
    return;
}


@end
