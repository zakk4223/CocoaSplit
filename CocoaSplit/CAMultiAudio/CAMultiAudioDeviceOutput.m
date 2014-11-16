//
//  CAMultiAudioDeviceOutput.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioDeviceOutput.h"

@implementation CAMultiAudioDeviceOutput

-(instancetype)initWithDeviceID:(NSString *)uid
{
    if (self = [super initWithDeviceID:uid])
    {
        [self setOutputForDevice];
        
    }
    
    return self;
}

@end
