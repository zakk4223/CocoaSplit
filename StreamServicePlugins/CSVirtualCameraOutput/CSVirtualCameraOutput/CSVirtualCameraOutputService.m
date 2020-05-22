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
    self.output.pixelFormat = self.pixelFormat;
    self.output.audioOutputDevice = self.audioOutput;
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


-(instancetype) init
{
    if (self = [super init])
    {
        self.pixelFormat = @(kCVPixelFormatType_32BGRA);
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.deviceName forKey:@"deviceName"];
    [aCoder encodeBool:self.persistDevice forKey:@"persistDevice"];
    [aCoder encodeObject:self.pixelFormat forKey:@"pixelFormat"];
    [aCoder encodeObject:self.audioOutput.deviceUID forKey:@"audioOutputDeviceUID"];
}


-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.deviceName = [aDecoder decodeObjectForKey:@"deviceName"];
        self.persistDevice = [aDecoder decodeObjectForKey:@"persistDevice"];
        self.pixelFormat = [aDecoder decodeObjectForKey:@"pixelFormat"];
        self.audioOutputDeviceUID = [aDecoder decodeObjectForKey:@"audioOutputDeviceUID"];
    }
    
    return self;
}


-(NSViewController *)getConfigurationView
{
    
     CSVirtualCameraOutputViewController *configViewController;
    
    configViewController = [[CSVirtualCameraOutputViewController alloc] initWithNibName:@"CSVirtualCameraOutputViewController" bundle:[NSBundle bundleForClass:self.class]];
    configViewController.serviceObj = self;
    return configViewController;
}


@end
