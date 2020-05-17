//
//  CSVirtualCameraOutputService.m
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraOutputService.h"
#import "CSVirtualCameraOutput.h"
#import "CSVirtualCameraOutputViewController.h"
@implementation CSVirtualCameraOutputService

+(NSString *)label
{
    return @"Virtual Camera";
}


-(NSObject<CSOutputWriterProtocol> *)createOutput
{
    return [self createOutput:nil];
}


-(NSObject<CSOutputWriterProtocol> *)createOutput:(NSString *)layoutName
{
    self.layoutName = layoutName;
    self.output = [[CSVirtualCameraOutput alloc] init];
    
    self.output.deviceName = [self getServiceDestination];
    self.output.persistDevice = self.persistDevice;
    return self.output;
}



-(NSString *)getServiceDestination
{
    if (self.deviceName)
    {
        return self.deviceName;
    }
    if (self.layoutName)
    {
        return [NSString stringWithFormat:@"CocoaSplit - %@", self.layoutName];
    }
    return @"CocoaSplit VCam";
}

-(NSViewController *)getConfigurationView
{
    
     CSVirtualCameraOutputViewController *configViewController;
    
    configViewController = [[CSVirtualCameraOutputViewController alloc] initWithNibName:@"CSVirtualCameraOutputViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}


@end
