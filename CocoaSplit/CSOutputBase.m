//
//  CSOutputBase.m
//  CocoaSplit
//
//  Created by Zakk on 1/21/18.
//

#import <Foundation/Foundation.h>
#import "CSOutputBase.h"


@implementation CSOutputBase


-(instancetype) init
{
    if ( self = [super init])
    {
        _output_bytes = 0;
        _output_framecnt = 0;
    }
    
    return self;
}


-(NSUInteger)frameQueueSize
{
    return 0;
}

-(bool)queueFramedata:(CapturedFrameData *)frameData
{
    return YES;
}


-(void) initStatsValues
{
    return;
}

-(bool) stopProcess
{
    return YES;
}



@end

