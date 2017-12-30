//
//  CAMultiAudioSilence.m
//  CocoaSplit
//
//  Created by Zakk on 12/29/17.
//

#import "CAMultiAudioSilence.h"

@implementation CAMultiAudioSilence


-(instancetype)init
{
    if (self = [super initWithSubType:kAudioUnitSubType_ScheduledSoundPlayer unitType:kAudioUnitType_Generator])
    {
 
    }
    
    return self;
}


-(bool)createNode:(CAMultiAudioGraph *)forGraph
{
    bool ret = [super createNode:forGraph];
    
    AudioTimeStamp ts = {0};
    
    OSStatus err;
    
    
    
    
    ts.mFlags = kAudioTimeStampSampleTimeValid;
    ts.mSampleTime = -1;
    err = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ScheduleStartTimeStamp, kAudioUnitScope_Global, 0, &ts, sizeof(ts));

    return ret;
}


-(bool)setInputStreamFormat:(AudioStreamBasicDescription *)format
{
    return YES;
}

-(bool)setOutputStreamFormat:(AudioStreamBasicDescription *)format
{
 
    return YES;
}
@end
