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








-(bool)setInputStreamFormat:(AVAudioFormat *)format bus:(UInt32)bus
{
    return YES;
}

-(float)volume
{
    if (self.sourceNode)
    {
        return self.sourceNode.volume;
    }
    return 0.0;
}

-(bool)muted
{
    if (self.sourceNode)
    {
        return self.sourceNode.muted;
    }
    
    return NO;
}

-(void)setVolume:(float)volume
{
    if (self.sourceNode)
    {
        self.sourceNode.volume = volume;
    }
    
    //[self setVolumeOnConnectedNode];
    
}

-(void)setMuted:(bool)muted
{
    if (self.sourceNode)
    {
        self.sourceNode.muted = muted;
    }
}

-(NSString *)name
{
    if (self.sourceNode)
    {
        return self.sourceNode.name;
    }
    
    return @"NoName";
}



-(void)setEnabled:(bool)enabled
{
    if (self.sourceNode)
    {
        self.sourceNode.enabled = enabled;
    }
    
    super.enabled = enabled;

}


-(bool)enabled
{
    if (self.sourceNode)
    {
        return self.sourceNode.enabled;
    }
    return super.enabled;
}


+(NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    if ([key isEqualToString:@"name"])
    {
        return [NSSet setWithObjects:@"sourceNode.name", nil];
    }
    return [super keyPathsForValuesAffectingValueForKey:key];
    
}

@end
