//
//  CSSequenceItemLayout.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemLayout.h"

@implementation CSSequenceItemLayout


-(instancetype) initWithLayout:(SourceLayout *)layout
{
    if (self = [self init])
    {
        self.layout = layout;
    }
    return self;
}


-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock
{
    NSLog(@"EXECUTING LAYOUT");
    
    if (self.layout)
    {
        if (self.actionType == kCSLayoutSequenceMerge)
        {
            [sequencer.sourceLayout mergeSourceLayout:self.layout withCompletionBlock:completionBlock];
        } else if (self.actionType == kCSLayoutSequenceSwitch) {
            [sequencer.sourceLayout replaceWithSourceLayout:self.layout withCompletionBlock:completionBlock];
        }
    }
}
@end
