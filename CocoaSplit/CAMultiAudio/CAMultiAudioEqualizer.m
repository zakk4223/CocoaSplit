//
//  CAMultiAudioEqualizer.m
//  CocoaSplit
//
//  Created by Zakk on 7/25/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioEqualizer.h"

@implementation CAMultiAudioEqualizer

-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_GraphicEQ unitType:kAudioUnitType_Effect])
    {
        
    }
    
    return self;
}

@end
