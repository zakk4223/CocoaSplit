//
//  CAMultiAudioMixer.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//

#import "CAMultiAudioNode.h"
#import "CAMultiAudioGraph.h"
#import "CAMultiAudioMixingProtocol.h"


@interface CAMultiAudioMixer : CAMultiAudioNode <CAMultiAudioMixingProtocol>
{
    UInt32 _nextElement;
    
}

@property (readonly) AVAudioNodeBus nextInputBus;


@end
