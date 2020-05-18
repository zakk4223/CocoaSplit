//
//  CSVirtualCameraOutputService.h
//  CSVirtualCameraOutput
//
//  Created by Zakk on 5/6/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSStreamServiceBase.h"
#import "CSVirtualCameraOutput.h"
NS_ASSUME_NONNULL_BEGIN

@interface CSVirtualCameraOutputService : CSStreamServiceBase
@property (strong) CSVirtualCameraOutput *output;
@property (strong) NSString *layoutName;
@property (strong) NSString *deviceName;
@property (strong) NSNumber *pixelFormat;
@property (assign) bool persistDevice;

@end

NS_ASSUME_NONNULL_END
