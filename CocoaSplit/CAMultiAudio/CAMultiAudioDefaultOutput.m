//
//  CAMultiAudioDefaultOutput.m
//  CocoaSplit
//
//  Created by Zakk on 11/14/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioDefaultOutput.h"

@implementation CAMultiAudioDefaultOutput


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_DefaultOutput unitType:kAudioUnitType_Output])
    {
        
    }
    
    return self;
}


@end
