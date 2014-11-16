//
//  CAMultiAudioMixer.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioGraph.h"
#import "CAMultiAudioMixingProtocol.h"


@interface CAMultiAudioMixer : CAMultiAudioNode <CAMultiAudioMixingProtocol>
{
    UInt32 _nextElement;
    
}
@end
