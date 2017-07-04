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


-(NSString *)generateItemScript
{
    if (!self.layoutName)
    {
        return nil;
    }
    
    if (self.actionType == kCSLayoutSequenceMerge)
    {
        return [NSString stringWithFormat:@"mergeLayout('%@')", self.layoutName];
    } else if (self.actionType == kCSLayoutSequenceSwitch) {
        return [NSString stringWithFormat:@"switchToLayout('%@')", self.layoutName];
    } else if (self.actionType == kCSLayoutSequenceRemove) {
        return [NSString stringWithFormat:@"removeLayout('%@')", self.layoutName];
    }
    
    
    return nil;
}


@end
