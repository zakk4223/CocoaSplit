//
//  CSVirtualCameraOutputViewController.h
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/16/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CSVirtualCameraOutputService.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSVirtualCameraOutputViewController : NSViewController
{
    
}
@property (weak) CSVirtualCameraOutputService *serviceObj;
@property (strong) NSDictionary *pixelFormats;
@property (strong) NSArray *formatSortDescriptors;
@property (strong) NSArray *audioOutputs;
@property (readonly) bool virtualCameraInstalled;
@property (readonly) NSMutableAttributedString *descriptionText;
@property (weak) IBOutlet NSTextField *descriptionTextField;
@end

NS_ASSUME_NONNULL_END
