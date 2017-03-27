//
//  CSLayoutSequence.h
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"

@class CSSequenceItem;

@interface CSLayoutSequence : NSObject
{

    dispatch_queue_t _run_queue;
}


@property (strong) NSString *name;
@property (strong) NSMutableArray *sequenceItems;
@property (weak) SourceLayout *sourceLayout;
@property (strong) NSString *animationCode;

-(void)runSequenceForLayout:(SourceLayout *)layout;
-(void)runSequenceForLayout:(SourceLayout *)layout withCompletionBlock:(void (^)())completionBlock withItemCompletionBlock:(void (^)(CSSequenceItem *item))itemCompletionBlock;
@end
