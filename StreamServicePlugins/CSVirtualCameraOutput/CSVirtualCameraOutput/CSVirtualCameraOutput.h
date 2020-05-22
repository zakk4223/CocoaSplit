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
#import "CSSystemAudioOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSVirtualCameraOutput : CSOutputBase
{
    CSSystemAudioOutput *_audioOutput;
}

@property (strong) CSVirtualCameraDevice *cameraDevice;
@property (strong) NSString *deviceName;
@property (assign) bool persistDevice;
@property (strong) NSNumber *pixelFormat;
@property (strong) CSSystemAudioOutput *audioOutputDevice;

@end

NS_ASSUME_NONNULL_END
