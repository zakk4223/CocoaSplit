//
//  CAMultiAudioGenericOutput.m
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioGenericOutput.h"

@implementation CAMultiAudioGenericOutput
-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_GenericOutput unitType:kAudioUnitType_Output])
    {
        
    }
    
    return self;
}


@end
