//
//  CAMultiAudioDevice.h
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@interface CAMultiAudioDevice : CAMultiAudioNode


@property (strong) NSString *deviceUID;
@property (assign) AudioDeviceID deviceID;
@property (assign) bool hasInput;
@property (assign) bool hasOutput;



-(instancetype)initWithDeviceUID:(NSString *)uid;
-(instancetype)initWithDeviceID:(AudioDeviceID)devid;

-(void)setInputForDevice;
-(void)setOutputForDevice;
+(NSMutableArray *)allDevices;
+(AudioDeviceID)defaultOutputDeviceID;
+(NSString *)defaultOutputDeviceUID;



@end
