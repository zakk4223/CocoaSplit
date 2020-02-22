//
//  CAMultiAudioOutputTrackConnection.m
//  CocoaSplit
//
//  Created by Zakk on 2/22/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import "CAMultiAudioOutputTrackConnection.h"

@implementation CAMultiAudioOutputTrackConnection



-(instancetype)initWithTrack:(CAMultiAudioOutputTrack *)track inBus:(UInt32)inBus
{
    if (self = [self init])
    {
        self.outputTrack = track;
        self.bus = inBus;
    }
    
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    CAMultiAudioOutputTrackConnection *newCopy = [[[self class] allocWithZone:zone] initWithTrack:self.outputTrack inBus:self.bus];
    return newCopy;
}
@end
