//
//  CAMultiAudioOutputTrack.h
//  CocoaSplit
//
//  Created by Zakk on 3/30/19.
//  Copyright © 2019 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSAacEncoder.h"
#import "CAMultiAudioNode.h"


NS_ASSUME_NONNULL_BEGIN

@interface CAMultiAudioOutputTrack : NSObject <NSCoding, NSCopying>

@property (strong) NSString *name;
@property (strong) NSString *uuid;
@property (strong) CSAacEncoder *encoder;
@property (strong) CAMultiAudioNode *encoderNode;
@property (strong) NSNumber *outputBus;

@end

NS_ASSUME_NONNULL_END
