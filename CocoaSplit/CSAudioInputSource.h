//
//  CSAudioInputSource.h
//  CocoaSplit
//
//  Created by Zakk on 7/5/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSInputSourceBase.h"
#import "CAMultiAudioEngine.h"

@interface CSAudioInputSource : CSInputSourceBase
{
    float _previousVolume;
    bool _previousEnabled;
}

@property (strong) NSString *audioUUID;
@property (assign) float audioVolume;
@property (assign) bool audioEnabled;
@property (strong) CAMultiAudioNode *audioNode;


-(instancetype) initWithAudioNode:(CAMultiAudioNode *)node;

@end

