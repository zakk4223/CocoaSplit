//
//  CAMultiAudioSplitter.m
//  CocoaSplit
//
//  Created by Zakk on 3/2/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import "CAMultiAudioSplitter.h"

@implementation CAMultiAudioSplitter


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_MultiSplitter unitType:kAudioUnitType_FormatConverter])
    {
    }
    
    return self;
}

        -(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
    {
        
        /*
         bool ret = NO;
         if (&_inputFormat)
         {
         ret = [super setInputStreamFormat:&_inputFormat];
         } else {
         ret = [super setInputStreamFormat:format];
         }
         
         return ret;
         */
        return YES;
    }
        
        
        
    -(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format
    {
        //ignore if we have our own
        
        return YES;
        

    }


@end
