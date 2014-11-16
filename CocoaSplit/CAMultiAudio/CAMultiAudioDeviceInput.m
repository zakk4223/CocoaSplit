//
//  CAMultiAudioDeviceInput.m
//  CocoaSplit
//
//  Created by Zakk on 11/13/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioDeviceInput.h"

@implementation CAMultiAudioDeviceInput


-(instancetype)initWithDeviceID:(NSString *)uid
{
    if (self = [super initWithDeviceID:uid])
    {
        [self setInputForDevice];
        
    }
    
    return self;
}






@end
