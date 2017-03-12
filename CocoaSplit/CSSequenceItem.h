//
//  CSSequenceItem.h
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSLayoutSequence.h"

@interface CSSequenceItem : NSObject


-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock;



@end
