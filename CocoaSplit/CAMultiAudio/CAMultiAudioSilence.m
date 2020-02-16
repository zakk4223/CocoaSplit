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
    AVAudioPlayerNode *pNode = [[AVAudioPlayerNode alloc] init];
    if (self = [self initWithAudioNode:pNode])
    {
 
    }
    
    return self;
}



@end
