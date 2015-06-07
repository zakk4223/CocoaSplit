//
//  CAMultiAudioDownmixer.h
//  CocoaSplit
//
//  Created by Zakk on 6/3/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioMixingProtocol.h"

@interface CAMultiAudioDownmixer : CAMultiAudioNode <CAMultiAudioMixingProtocol>
{
    int _inputChannels;
}
-(instancetype)initWithInputChannels:(int)channels;

@end
