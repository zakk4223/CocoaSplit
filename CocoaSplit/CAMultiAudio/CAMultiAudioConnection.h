//
//  CAMultiAudioConnection.h
//  CocoaSplit
//
//  Created by Zakk on 2/20/20.
//  Copyright © 2020 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudioNode.h"
NS_ASSUME_NONNULL_BEGIN

@interface CAMultiAudioConnection : NSObject

@property (readonly, weak) CAMultiAudioNode *node;
@property (readonly) UInt32 bus;

-(instancetype)initWithNode:(CAMultiAudioNode *)node bus:(UInt32)bus;


@end

NS_ASSUME_NONNULL_END
