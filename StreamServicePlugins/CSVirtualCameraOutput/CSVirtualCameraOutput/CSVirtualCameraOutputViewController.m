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
    
    if (self.descriptionTextField)
    {
        self.descriptionTextField.allowsEditingTextAttributes = YES;
        self.descriptionTextField.selectable = YES;
        
        self.descriptionTextField.attributedStringValue = self.descriptionText;
    }
    
}

-(bool)virtualCameraInstalled
{
    return [CSVirtualCameraDevice isInstalled];
}


-(NSAttributedString *)descriptionText
{
        
    
    NSMutableAttributedString *urlStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"https://www.cocoasplit.com/releases/CSVirtualCamera"]];


    NSString *availableStr = [NSString stringWithFormat:@"CocoaSplit Virtual Camera is not installed. You can download the latest release from "];
    NSMutableAttributedString *retStr = [[NSMutableAttributedString alloc] initWithString:availableStr];
    
    
    
    NSRange range = NSMakeRange(0, urlStr.length);
    
    [urlStr beginEditing];
    
    NSURL *URL = [NSURL URLWithString:[NSString stringWithUTF8String:"https://www.cocoasplit.com/releases/CSVirtualCamera"]];
    
    [urlStr addAttribute:NSLinkAttributeName value:URL range:range];
    
    [urlStr addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    [urlStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:range];
    [urlStr endEditing];
    
    [retStr appendAttributedString:urlStr];
    
    return retStr;
}
@end
