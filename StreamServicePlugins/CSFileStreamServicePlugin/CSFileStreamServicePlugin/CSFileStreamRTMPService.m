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
    [aCoder encodeObject:self.forceFormat forKey:@"forceFormat"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.destinationURI = [aDecoder decodeObjectForKey:@"destinationURI"];
        self.forceFormat = [aDecoder decodeObjectForKey:@"forceFormat"];
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
    if (self.forceFormat)
    {
        return self.forceFormat;
    }
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
