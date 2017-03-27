//
//  CSLayoutSequence.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSequence.h"
#import "CSSequenceItem.h"

@implementation CSLayoutSequence


-(instancetype) init
{
    if (self = [super init])
    {
        self.sequenceItems = [NSMutableArray array];
    }
    
    return self;
}


-(void)runItemAtIndex:(NSInteger)idx withCompletionBlock:(void (^)())completionBlock withItemCompletionBlock:(void (^)(CSSequenceItem *item))itemCompletionBlock;
{
    if (idx >= 0 && idx < self.sequenceItems.count)
    {
        CSSequenceItem *item = [self.sequenceItems objectAtIndex:idx];
        [item executeWithSequence:self usingCompletionBlock:^{
            if (itemCompletionBlock)
            {
                itemCompletionBlock(item);
            }
            [self runItemAtIndex:idx+1 withCompletionBlock:completionBlock withItemCompletionBlock:itemCompletionBlock];
        }];
    } else if (completionBlock) {
        completionBlock();
    }
}


-(void)runSequenceForLayout:(SourceLayout *)layout
{
    [self runSequenceForLayout:layout withCompletionBlock:nil withItemCompletionBlock:^(CSSequenceItem *item) {
        NSLog(@"DONE WITH ITEM %@", item);
    }];
    
}


-(void)runSequenceForLayout:(SourceLayout *)layout withCompletionBlock:(void (^)())completionBlock withItemCompletionBlock:(void (^)(CSSequenceItem *item))itemCompletionBlock;
{
    self.sourceLayout = layout;
    
    if (self.animationCode)
    {
        [self.sourceLayout runAnimationString:self.animationCode withCompletionBlock:^{
            NSLog(@"Finished running animation");
        }];
    }
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self runItemAtIndex:0 withCompletionBlock:completionBlock withItemCompletionBlock:itemCompletionBlock];
    });*/
    
}

@end
