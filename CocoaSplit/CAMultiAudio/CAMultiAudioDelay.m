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
    if (self = [super initWithSubType:kAudioUnitSubType_Delay unitType:kAudioUnitType_Effect])
    {
        _delay = 0;
    }
    
    return self;
}




-(void)setDelay:(float)delay
{
    _delay = delay;
    
    AudioUnitSetParameter(self.audioUnit, kDelayParam_DelayTime, kAudioUnitScope_Global, 0, self.delay, 0);

}

-(float)delay
{
    return _delay;
}


-(void)willInitializeNode
{
    AudioUnitSetParameter(self.audioUnit, kDelayParam_Feedback, kAudioUnitScope_Global, 0, 0, 0);
    AudioUnitSetParameter(self.audioUnit, kDelayParam_WetDryMix, kAudioUnitScope_Global, 0, 100, 0);
    AudioUnitSetParameter(self.audioUnit, kDelayParam_LopassCutoff, kAudioUnitScope_Global, 0, 22050, 0);
    AudioUnitSetParameter(self.audioUnit, kDelayParam_Feedback, kAudioUnitScope_Global, 0, 0, 0);
    AudioUnitSetParameter(self.audioUnit, kDelayParam_DelayTime, kAudioUnitScope_Global, 0, self.delay, 0);
}
@end
