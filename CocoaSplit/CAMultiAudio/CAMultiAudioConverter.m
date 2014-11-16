//
//  CAMultiAudioConverter.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioConverter.h"

@implementation CAMultiAudioConverter


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_AUConverter unitType:kAudioUnitType_FormatConverter])
    {
        
    }
    
    return self;
}


-(void)setDefaultOutputFormat
{
    //Our output is always Float32, Non-Interleaved
}
@end
