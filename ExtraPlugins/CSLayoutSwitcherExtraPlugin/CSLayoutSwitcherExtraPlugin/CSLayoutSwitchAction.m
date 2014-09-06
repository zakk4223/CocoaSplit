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
        self.layoutName = [aDecoder decodeObjectForKey:@"layoutName"];
        self.active = [aDecoder decodeBoolForKey:@"active"];
    }
    
    return self;
}


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.applicationString forKey:@"applicationString"];
    [aCoder encodeInt:self.eventType forKey:@"eventType"];
    [aCoder encodeObject:self.layoutName forKey:@"layoutName"];
    [aCoder encodeBool:self.active forKey:@"active"];
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
