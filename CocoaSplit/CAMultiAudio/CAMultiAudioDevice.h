//
//  CAMultiAudioDevice.h
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioUnit.h"

@interface CAMultiAudioDevice : CAMultiAudioUnit


@property (strong) NSString *deviceUID;
@property (assign) AudioDeviceID deviceID;

-(instancetype)initWithDeviceID:(NSString *)uid;
-(void)setInputForDevice;
-(void)setOutputForDevice;


@end
