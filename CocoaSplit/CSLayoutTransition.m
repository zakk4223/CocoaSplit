//
//  CSLayoutTransition.m
//  CocoaSplit
//
//  Created by Zakk on 8/12/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutTransition.h"

@implementation CSLayoutTransition

-(instancetype) copyWithZone:(NSZone *)zone
{
    CSLayoutTransition *copy = [[CSLayoutTransition alloc] init];
    copy.transitionDuration = self.transitionDuration;
    copy.transitionName = self.transitionName;
    copy.transitionFilter = self.transitionFilter;
    copy.transitionFullScene = self.transitionFullScene;
    copy.transitionLayout = self.transitionLayout;
    copy.transitionLayout = self.transitionLayout;
    copy.transitionHoldTime = self.transitionHoldTime;
    copy.preTransition = [self.preTransition copy];
    copy.postTransition = [self.postTransition copy];
    copy.transitionDirection = self.transitionDirection;

    return copy;
}

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeFloat:self.transitionDuration forKey:@"transitionDuration"];
    [aCoder encodeObject:self.transitionName forKey:@"transitionName"];
    [aCoder encodeObject:self.transitionFilter forKey:@"transitionFilter"];
    [aCoder encodeBool:self.transitionFullScene forKey:@"transitionFullScene"];
    [aCoder encodeObject:self.transitionLayout forKey:@"transitionLayout"];
    [aCoder encodeFloat:self.transitionHoldTime forKey:@"transitionHoldTime"];
    [aCoder encodeObject:self.preTransition forKey:@"preTransition"];
    [aCoder encodeObject:self.postTransition forKey:@"postTransition"];
    [aCoder encodeObject:self.transitionDirection forKey:@"transitionDirection"];

}

-(instancetype) initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.transitionDuration = [aDecoder decodeFloatForKey:@"transitionDuration"];
        self.transitionName = [aDecoder decodeObjectForKey:@"transitionName"];
        self.transitionFilter = [aDecoder decodeObjectForKey:@"transitionFilter"];
        self.transitionFullScene = [aDecoder decodeBoolForKey:@"transitionFullScene"];
        self.transitionLayout = [aDecoder decodeObjectForKey:@"transitionLayout"];
        self.transitionHoldTime = [aDecoder decodeFloatForKey:@"transitionHoldTime"];
        self.preTransition = [aDecoder decodeObjectForKey:@"preTransition"];
        self.postTransition = [aDecoder decodeObjectForKey:@"postTransition"];
        self.transitionDirection = [aDecoder decodeObjectForKey:@"transitionDirection"];

    }
    return self;
    
    
}
@end
