//
//  CSSequenceItemLayout.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSSequenceItemLayout.h"
#import "CaptureController.h"

@implementation CSSequenceItemLayout


-(instancetype) initWithLayoutName:(NSString *)layoutName
{
    if (self = [self init])
    {
        self.layoutName = layoutName;
    }
    return self;
}

+(NSString *)label
{
    return @"Layout";
}



-(void)updateItemDescription
{
    NSString *actionString;

    
    switch (self.actionType) {
        case kCSLayoutSequenceMerge:
            actionString = @"Merge";
            break;
        case kCSLayoutSequenceSwitch:
            actionString = @"Switch to";
            break;
        default:
            actionString = @"???";
            break;
    }
    self.itemDescription = [NSString stringWithFormat:@"%@ layout named %@", actionString, self.layoutName];
}



-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock
{
    
    if (self.layoutName)
    {
        CaptureController *ccont = [CaptureController sharedCaptureController];
        SourceLayout *myLayout = [ccont findLayoutWithName:self.layoutName];
        
        if (myLayout)
        {
            if (self.actionType == kCSLayoutSequenceMerge)
            {
                [sequencer.sourceLayout mergeSourceLayout:myLayout withCompletionBlock:completionBlock];
            } else if (self.actionType == kCSLayoutSequenceSwitch) {
                [sequencer.sourceLayout replaceWithSourceLayout:myLayout withCompletionBlock:completionBlock];
            }
        }
    }
}
@end
