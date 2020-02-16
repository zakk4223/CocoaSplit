//
//  CAMultiAudioDelay.m
//  CocoaSplit
//
//  Created by Zakk on 4/22/17.
//

#import "CAMultiAudioDelay.h"

@implementation CAMultiAudioDelay
@synthesize delay = _delay;

-(instancetype)init
{
    AVAudioUnitDelay *delayNode = [[AVAudioUnitDelay alloc] init];
    if (self = [self initWithAudioNode:delayNode])
    {
        delayNode.feedback = 0.0f;
        delayNode.wetDryMix = 100.0f;
        delayNode.lowPassCutoff = 22050.0f;
        delayNode.delayTime = 0.0f;
        _delay = 0;
    }
    
    return self;
}




-(void)setDelay:(float)delay
{
    _delay = delay;
    if (self.avAudioNode)
    {
        ((AVAudioUnitDelay *)self.avAudioNode).delayTime = delay;
    }

}

-(float)delay
{
    return _delay;
}


@end
