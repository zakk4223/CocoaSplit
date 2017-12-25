//
//  CSLayoutSwitchAction.m
//  CSLayoutSwitcherExtraPlugin
//
//  Created by Zakk on 9/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CSLayoutSwitchAction.h"
@implementation CSLayoutSwitchAction



-(id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.applicationString = [aDecoder decodeObjectForKey:@"applicationString"];
        self.eventType = [aDecoder decodeIntForKey:@"eventType"];
        if ([aDecoder containsValueForKey:@"layoutName"])
        {
            self.targetName = [aDecoder decodeObjectForKey:@"layoutName"];

        } else {
            self.targetName = [aDecoder decodeObjectForKey:@"targetName"];

        }
        self.active = [aDecoder decodeBoolForKey:@"active"];
        if ([aDecoder containsValueForKey:@"actionType"])
        {
            self.actionType = [aDecoder decodeIntForKey:@"actionType"];
        } else {
            self.actionType = kLayoutSwitch;
        }

        
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.applicationString forKey:@"applicationString"];
    [aCoder encodeInt:self.eventType forKey:@"eventType"];
    [aCoder encodeObject:self.targetName forKey:@"targetName"];
    [aCoder encodeBool:self.active forKey:@"active"];
    [aCoder encodeInt:self.actionType forKey:@"actionType"];
}



-(NSString *)actionTypeString
{
    NSString *ret = nil;
    
    switch (self.actionType) {
        case kScriptStop:
            ret = @"Stop Script";
            break;
        case kScriptRun:
            ret = @"Run Script";
            break;
        case kLayoutMerge:
            ret = @"Merge Layout";
            break;
        case kLayoutRemove:
            ret = @"Remove Layout";
            break;
        case kLayoutSwitch:
            ret = @"Switch to Layout";
            break;
        default:
            ret = @"Unknown";
    }
    
    return ret;

}
-(NSString *)eventTypeString
{

    NSString *ret = nil;
    
    switch (self.eventType) {
        case kEventDeactivated:
            ret = @"Deactivated";
            break;
        case kEventActivated:
            ret = @"Activated";
            break;
        default:
            ret = @"Unknown";
    }

    return ret;
}


@end
