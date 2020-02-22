//
//  CAMultiAudioOutputTrackConnection.h
//  CocoaSplit
//
//  Created by Zakk on 2/22/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudioOutputTrack.h"
NS_ASSUME_NONNULL_BEGIN

@interface CAMultiAudioOutputTrackConnection : NSObject <NSCopying>
@property (strong) CAMultiAudioOutputTrack *outputTrack;
@property (assign) UInt32 bus;

-(instancetype)initWithTrack:(CAMultiAudioOutputTrack *)track inBus:(UInt32)inBus;

@end

NS_ASSUME_NONNULL_END
