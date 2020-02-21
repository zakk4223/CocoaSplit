//
//  CAMultiAudioConnection.m
//  CocoaSplit
//
//  Created by Zakk on 2/20/20.

#import "CAMultiAudioConnection.h"

@implementation CAMultiAudioConnection


-(instancetype)initWithNode:(CAMultiAudioNode *)node bus:(UInt32)bus
{
    if (self = [self init])
    {
        _node = node;
        _bus = bus;
    }
    
    return self;
}


@end
