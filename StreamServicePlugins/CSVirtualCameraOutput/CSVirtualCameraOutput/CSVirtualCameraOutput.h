//
//  CSVirtualCameraOutput.h
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSOutputBase.h"
#import "CSVirtualCameraDevice.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSVirtualCameraOutput : CSOutputBase
{
}

@property (strong) CSVirtualCameraDevice *cameraDevice;
@property (strong) NSString *deviceName;
@property (assign) bool persistDevice;

@end

NS_ASSUME_NONNULL_END
