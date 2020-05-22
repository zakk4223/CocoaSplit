//
//  CSVirtualCameraOutputViewController.m
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/16/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CSVirtualCameraOutputViewController.h"
#import "CSPluginServices.h"

@interface CSVirtualCameraOutputViewController ()

@end

@implementation CSVirtualCameraOutputViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    self.pixelFormats = @{@"RGBA": @(kCVPixelFormatType_32RGBA),
                      @"ARGB": @(kCVPixelFormatType_32ARGB),
                      @"BGRA": @(kCVPixelFormatType_32BGRA),
                      @"422 YpCbCr8 (2vuy/UYVY)": @(kCVPixelFormatType_422YpCbCr8),
                      @"Planar Component Y'CbCr 8-bit 4:2:0 (y420)": @(kCVPixelFormatType_420YpCbCr8Planar),
                      @"Component Y'CbCr 8-bit 4:2:2 (yuvs)": @(kCVPixelFormatType_422YpCbCr8_yuvs)
                      };
    self.formatSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"key" ascending:YES]];
    self.audioOutputs = [[CSPluginServices sharedPluginServices] audioOutputs];
    if (self.serviceObj.audioOutputDeviceUID)
    {
        for (CSSystemAudioNode *aNode in self.audioOutputs)
        {
            if ([aNode.deviceUID isEqualToString:self.serviceObj.audioOutputDeviceUID])
            {
                self.serviceObj.audioOutput = aNode;
                self.serviceObj.audioOutputDeviceUID = aNode.deviceUID;
                break;
            }
        }
    }
    
}

@end
