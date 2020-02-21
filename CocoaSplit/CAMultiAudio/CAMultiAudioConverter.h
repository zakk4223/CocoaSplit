//
//  CAMultiAudioConverter.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"


//This class is mostly a sample rate converter for non-device PCM input


@interface CAMultiAudioConverter : CAMultiAudioNode


@property (assign) AudioStreamBasicDescription inputFormat;
@property (assign) AudioStreamBasicDescription *outputFormat;

@property (weak) CAMultiAudioNode *sourceNode;



@end
